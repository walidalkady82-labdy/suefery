import 'dart:convert';
import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_paymob/flutter_paymob.dart';
import 'package:logging/logging.dart';

import 'package:suefery/core/l10n/app_localizations.dart';
import 'package:suefery/data/service/service_notification.dart';
import 'package:suefery/data/service/service_auth.dart';
import 'package:suefery/data/service/service_user.dart';
import 'package:suefery/locator.dart';
import 'package:suefery/presentation/auth/auth_checker.dart';
import 'package:suefery/presentation/auth/cubit_auth.dart';
import 'package:suefery/presentation/home/cubit_order.dart';
import 'package:suefery/presentation/settings/settings_cubit.dart';
import 'core/utils/themes.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  final log = Logger("firebaseMessagingBackgroundHandler");
  log.info("Handling a background message: ${message.messageId}");

  // Ensure Firebase is initialized for background processing
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  // --- MODIFICATION: Pass the data payload to the local notification ---
  final String payload = jsonEncode(message.data);

  await _flutterLocalNotificationsPlugin.show(0, message.notification?.title, message.notification?.body, platformChannelSpecifics, payload: payload);
}

Future<void> main() async {
  final log = Logger("main");
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  // Ensure Flutter engine is initialized before running the app
  log.info('initializing app...');
  WidgetsFlutterBinding.ensureInitialized();
  log.info('Loading app...');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(
    MultiBlocProvider(
      providers: [
        // GLOBAL CUBITS (Available to ALL screens/features)
        BlocProvider(
          create: (context) => CubitAuth(),
        ),
        BlocProvider(
          // SettingsCubit loads its own initial state from PrefService
          create: (context) => SettingsCubit()..loadSettings(),
        ),
        BlocProvider(
          create: (context) => CubitOrder(),
        ),
        // BlocProvider(
        //   // GeminiCubit depends on GeminiService
        //   create: (context) => HomeCubit(),
        // ),
        // BlocProvider(
        //   // GeminiCubit depends on GeminiService
        //   create: (context) => OrderHistoryCubit(),
        // ),
        // FEATURE CUBITS (Can be added here or on specific routes)
        // BlocProvider(create: (_) => BookingCubit()),
      ],
      child: const AppContainer(child:SUEFERYApp() ),
    )
  );
  log.info('App initialized...');
}

Future<void> _initEnvironmentVars() async {
  // DotEnv dotenv = DotEnv() is automatically called during import.
  // If you want to load multiple dotenv files or name your dotenv object differently, you can do the following and import the singleton into the relavant files:
  // DotEnv another_dotenv = DotEnv()
  final log = Logger("_initEnvironmentVars");
  try {
    log.info('loading .env file...');
    await dotenv.load(fileName: "assets/.env");
  }on Exception catch (e) {
    log.shout('Error loading .env file: $e');
  }
}

 Future<FirebaseApp> _initializeFirebase() async {
  final log = Logger("_initializeFirebase");
    final useEmulatorEnv = dotenv.getBool('USE_FIREBASE_EMULATOR', fallback: false);
    // 1. Get environment variables
    final  emulatorHost = kDebugMode && useEmulatorEnv && defaultTargetPlatform == TargetPlatform.android ?dotenv.get('local_device_ip') : "localhost";
    final firebaseConfigJson = const String.fromEnvironment('__firebase_config', defaultValue: '{}');
    //final appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');
    late final FirebaseApp app;
    
    // Parse config
    Map<String, dynamic> configMap;
    try {
      configMap = jsonDecode(firebaseConfigJson);
    } catch (e) {
      log.shout('ERROR: Failed to decode Firebase Config: $e');
      configMap = {};
    }

    // 2. Initialize Firebase App
    if (configMap.isNotEmpty) {
      //Use standard FirebaseOptions to initialize the app
      final options = FirebaseOptions(
        apiKey: configMap['apiKey'] as String,
        appId: configMap['appId'] as String,
        messagingSenderId: configMap['messagingSenderId'] as String,
        projectId: configMap['projectId'] as String,
        databaseURL: configMap['databaseURL'] as String?,
        storageBucket: configMap['storageBucket'] as String?,
       );
      app = await Firebase.initializeApp(options: options);
    } else {
      // If config is missing, initialize a default app (will likely fail on API calls)
      app = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }

    // --- INITIALIZE APP CHECK ---
    final appCheckWebKey = dotenv.get('webDebugToken');
    final androidDebugToken = dotenv.get('androidDebugToken');
    await FirebaseAppCheck.instance.activate(
      // Use Play Integrity for real Android builds.
      providerAndroid: kDebugMode ? AndroidDebugProvider(debugToken: androidDebugToken)  : AndroidPlayIntegrityProvider(),
      // Use App Attest for real iOS builds.
      providerApple : kDebugMode ? AppleDebugProvider()  : AppleAppAttestProvider(),
      // Use reCAPTCHA v3 for web. You must configure this in the Firebase console.
      // Replace 'YOUR_RECAPTCHA_V3_SITE_KEY' with the key from your Firebase project settings.
      providerWeb : ReCaptchaV3Provider(appCheckWebKey),
    );

       // await FirebaseStorage.instance.useEmulator(
      // host: 'localhost',
      // port: 9199,
      // port: 9199,
      // );
      
      if (kDebugMode && useEmulatorEnv) {
        FirebaseFunctions.instance.useFunctionsEmulator(emulatorHost, 5001);
      }
    return app;
  }

void initAnalytics(){
      if (!kIsWeb) {
        FlutterError.onError = (errorDetails) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
        // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
        };
      }
  }

void initRemoteConfigurations(){

}
/// A wrapper widget that handles the asynchronous initialization of Firebase
/// and authentication before rendering the main application.
Future<void> initPayment() async {
  final log = Logger("initPayment");
  // Securely load keys from environment variables
  final apiKey = dotenv.env['PAYMOB_API_KEY'];
  final integrationId = int.tryParse(dotenv.env['PAYMOB_INTEGRATION_ID'] ?? '');
  final walletIntegrationId = int.tryParse(dotenv.env['PAYMOB_WALLET_INTEGRATION_ID'] ?? '');
  final iFrameId = int.tryParse(dotenv.env['PAYMOB_IFRAME_ID'] ?? '');

  if (apiKey == null || integrationId == null || walletIntegrationId == null || iFrameId == null) {
    log.shout("FATAL: Paymob environment variables are not set in .env file.");
    // In a real app, you might want to prevent the app from running
    // or disable payment features if the keys are missing.
    return;
  }

  // Initialize Paymob
  await FlutterPaymob.instance.initialize(
    apiKey: apiKey,
    integrationID: integrationId,
    walletIntegrationId: walletIntegrationId,
    iFrameID: iFrameId,
  );
}

class AppContainer extends StatefulWidget {
  final Widget child;
  
  const AppContainer({super.key, required this.child});

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> {
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    // Start the initialization process when the widget is created
    _initialization = init();
  }
  
  Future<void> _initFirebaseMessaging() async {
    final log = Logger("_initFirebaseMessaging");
    
    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Set a timeout for permission request (safeguard)
      final settings = await messaging.requestPermission().timeout(
        const Duration(seconds: 3), 
        onTimeout: () {
          log.warning("Notification permission request timed out (Offline?)");
          // Return a dummy value or handle gracefully
          return const NotificationSettings(
            alert: AppleNotificationSetting.disabled,
          announcement: AppleNotificationSetting.disabled,
          badge: AppleNotificationSetting.disabled,
          carPlay: AppleNotificationSetting.disabled,
          criticalAlert: AppleNotificationSetting.disabled,
          sound: AppleNotificationSetting.disabled,
          lockScreen: AppleNotificationSetting.disabled,
          notificationCenter: AppleNotificationSetting.disabled,
          timeSensitive: AppleNotificationSetting.disabled,
          showPreviews: AppleShowPreviewSetting.never,
          authorizationStatus: AuthorizationStatus.notDetermined,
          providesAppNotificationSettings: AppleNotificationSetting .disabled, 
          ); 
        }
      );
      
      log.info('User granted permission: ${settings.authorizationStatus}');

      // 2. CRITICAL FIX: Add timeout to getToken()
      // This prevents the infinite hang when offline
      final fcmToken = await messaging.getToken().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          log.warning("Getting FCM token timed out. You are likely offline.");
          return null; // Return null so the app proceeds
        }
      );

      if (fcmToken != null) {
        log.info('FCM Token: $fcmToken');
        // Only try to update user if we actually have a token
        final userId = sl<ServiceAuth>().currentAppUser?.id;
        if (userId != null) {
          // Wrap this in try-catch too in case Firestore is unreachable
          try {
            await sl<ServiceUser>().updateUser(fcmToken: fcmToken);
          } catch (e) {
            log.warning("Could not update user token (Offline): $e");
          }
        }
      }
    } catch (e) {
      // 3. Catch ALL errors (network, firebase, etc) so the app DOES NOT CRASH
      log.warning("Skipping Firebase Messaging initialization: $e");
    }

    // 4. Listeners (These are safe to register even if offline)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log.info('Got a message whilst in the foreground!');
      if (message.notification != null) {
        log.info('Message also contained a notification: ${message.notification}');
      }
    });
  }

  Future<void> init() async {
    final log = Logger("initPayment");
    log.info('loading environment variables...');
    await _initEnvironmentVars();
    log.info('initializing Firebase...');
    final app = await _initializeFirebase();
    log.info('initializing Firebase Messaging...');
    await _initFirebaseMessaging();
    log.info('handling analytics...');
    initAnalytics();
    log.info('loading sevices...');
    await initLocator(app);
    log.info('ensuring services are ready...');
    await ensureServicesReady();
    log.info('initializing payment...');
    await initPayment();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // Display an error message if initialization fails
            return _ErrorView(
              message: 'Failed to load Firebase: ${snapshot.error}',
            );
          }
          // Firebase is ready, render the main application content
          return widget.child;
        }
        
        // While loading, display a splash screen or loading indicator
        return const _LoadingView();
      },
    );
  }
}

// loading view
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing SUEFERY...', style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
            ],
          ),
        ),
      ),
    );
  }
}

// error view
class _ErrorView extends StatelessWidget {
  final String message;
  
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The root widget of the SUEFERY application.
class SUEFERYApp extends StatelessWidget {
  const SUEFERYApp({super.key});
  @override
  Widget build(BuildContext context) {    
    return BlocProvider(
        create: (context) => CubitAuth(),        
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {            
            return MaterialApp(              
              scaffoldMessengerKey: sl<ServiceNotification>().scaffoldMessengerKey,
              onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,              
              theme: lightTheme, // Always use the defined light theme
              darkTheme: darkTheme, // Always use the defined dark theme
              themeMode: settingsState.themeMode, // Use the themeMode from the SettingsCubit
              locale: context.read<SettingsCubit>().state.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              localeResolutionCallback: (locale, supportedLocales) {
              // 1. If the device locale is null (rare), use English
              if (locale == null) return supportedLocales.first;
              // 2. Check if the device locale is supported
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
              // 3. FALLBACK: If device is French (unsupported), force English
              return supportedLocales.first; 
            },
              // Pass the orderId to your main screen wrapper
              home: AuthChecker(),
            );
          },
        ),
      );
  }
}
