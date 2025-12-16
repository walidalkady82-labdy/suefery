import 'dart:async';
import 'package:suefery/core/extensions/future_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:suefery/core/utils/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:suefery/data/service/service_auth.dart';
import 'package:suefery/data/service/service_user.dart';

import 'package:suefery/data/enum/notification_channel.dart';
import 'package:suefery/data/enum/notification_reciever.dart';
import 'dart:io';

import '../../locator.dart';


class ServiceNotification with LogMixin {
  // --- NEW: StreamController to broadcast navigation events ---
  final StreamController<Map<String, dynamic>> _onNotificationTappedController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onNotificationTapped => _onNotificationTappedController.stream;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ServiceAuth _authService = sl<ServiceAuth>();
  final ServiceUser _userService = sl<ServiceUser>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _generalNotificationDetails =
      AndroidNotificationDetails(
    'general_channel', // id
    'General Notifications', // name
    channelDescription: 'This channel is used for general application notifications.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const AndroidNotificationDetails _quoteNotificationDetails =
      AndroidNotificationDetails(
    'quote_channel', // id
    'Quote Notifications', // name
    channelDescription: 'This channel is used for sending motivational quotes.',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
    playSound: true,
    enableVibration: true,
  );

  // --- NEW: Example of a notification style for big pictures ---
  static Future<AndroidNotificationDetails> _createBigPictureNotificationDetails(
    String largeIconPath,
    String bigPicturePath,
  ) async {
    return AndroidNotificationDetails(
      'big_picture_channel',
      'Big Picture Notifications',
      channelDescription: 'Channel for notifications with large images.',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: BigPictureStyleInformation(FilePathAndroidBitmap(bigPicturePath)),
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  /// 1. Initialize Notifications on App Start  
  Future<void> initialize() async {
    FirebaseMessaging.instance.onTokenRefresh
      .listen((fcmToken) async {
        // This callback is fired at each app startup and whenever a new
        // token is generated.
        if (fcmToken.isNotEmpty) {
        logInfo("FCM Token: $fcmToken");
        // Sync token to Firestore User Profile so the backend knows who to message
        await _userService.updateUser(fcmToken : fcmToken);
      }
      })
      .onError((err) {
        // Error getting token.
      });
     // Initialize flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Use your app icon
    
    // TODO: Add iOS initialization settings if needed for specific actions
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(); 

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // --- MODIFICATION: Handle notification tap ---
        if (notificationResponse.payload != null && notificationResponse.payload!.isNotEmpty) {
          _handleNotificationTap(jsonDecode(notificationResponse.payload!));
        }
      },
    );

    // Request permission (Critical for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    logInfo('User granted permission: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      logInfo('User granted permission');
      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logInfo('Got a message whilst in the foreground!');
        logInfo('Message data: ${message.data}');
        if (message.notification != null && message.data.isNotEmpty) {
          logInfo('Message also contained a notification: ${message.notification}');
          showLocalNotification(
            title: message.data['title'] ?? message.notification!.title ?? '',
            body: message.data['body'] ?? message.notification!.body ?? '',
            data: message.data,
            reciever: NotificationReciever.channel,
          ); 
        }
      });
    } else {
      logWarning('User declined or has not accepted permission');
    }
  }
  
  // --- NEW: Central handler for tap events ---
  void _handleNotificationTap(Map<String, dynamic> data) {
    logInfo('Notification tapped with data: $data');
    _onNotificationTappedController.add(data);
  }

void showSnackbar(String message, {Duration duration = const Duration(seconds: 4), Color? backgroundColor}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: backgroundColor,
    );
    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
}

Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    NotificationChannel channel = NotificationChannel.general,
    String? imageUrl,
    NotificationReciever reciever = NotificationReciever.channel,
  }) async {
    try {
      final user = await _userService.getUser().withTimeout();
      String? token = await _fcm.getToken().withTimeout();
      if (user != null) {
          // Only update if it's different or missing
          if (user.fcmToken != token && token != null) {
            await _authService.updateUser(user.id,fcmToken:  token).withTimeout();
          }else{
            logWarning("could not get user fcm token!");
          }
      }else{
        logWarning("could not get user!");

      }
      final String payload = jsonEncode(data ?? {}); // Encode the entire data map
      AndroidNotificationDetails androidDetails;

      // --- REFACTORED: Select notification details based on the channel ---
      if (channel == NotificationChannel.bigPicture && imageUrl != null) {
        // For big picture, we need to download the image first
        final String largeIconPath = await _downloadAndSaveFile(imageUrl, 'largeIcon');
        final String bigPicturePath = await _downloadAndSaveFile(imageUrl, 'bigPicture');
        androidDetails = await _createBigPictureNotificationDetails(largeIconPath, bigPicturePath);
      } else if (channel == NotificationChannel.quoteReady) {
        androidDetails = _quoteNotificationDetails;
      } else {
        androidDetails = _generalNotificationDetails;
      }

      NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
      await _flutterLocalNotificationsPlugin.show(
                0, // Notification ID
                title,
                body,
                notificationDetails,
                payload: payload,
              );
    } on Exception catch (e) {
      logError("Error updating FCM token: $e");
    }
  }

  // Helper to download an image and save it locally for the notification
  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = Directory.systemTemp;
    final String filePath = '${directory.path}/$fileName.png';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
}
