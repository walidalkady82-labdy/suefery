import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/service/service_auth.dart';
import '../../locator.dart';

class ServiceNotification with LogMixin{
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ServiceAuth _authService = sl<ServiceAuth>();

  /// 1. Initialize Notifications on App Start
  Future<void> initialize() async {
    // Request permission (Critical for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      logInfo('User granted permission');
      
      // Get the token
      String? token = await _fcm.getToken();
      if (token!.isNotEmpty) {
        logInfo("FCM Token: $token");
        // Sync token to Firestore User Profile so the backend knows who to message
        await _updateTokenInDatabase(token);
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logInfo('Got a message whilst in the foreground!');
        logInfo('Message data: ${message.data}');

        if (message.notification != null) {
          logInfo('Message also contained a notification: ${message.notification}');
          // TODO: Show a local snackbar or in-app update here
        }
      });
    }
  }

  /// 2. Sync Token to Firestore
  Future<void> _updateTokenInDatabase(String token) async {
    try {
      final user = _authService.currentAppUser;
      if (user != null) {
        // Only update if it's different or missing
        if (user.fcmToken != token) {
          await _authService.updateUser(user.id,fcmToken:  token);
        }
      }
    } catch (e) {
      logError("Error updating FCM token: $e");
    }
  }
}