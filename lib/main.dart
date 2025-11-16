import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_paymob/flutter_paymob.dart';
import 'package:suefery/core/l10n/app_localizations.dart';
import 'package:suefery/locator.dart';
import 'package:suefery/presentation/settings/settings_cubit.dart';
import 'package:suefery/presentation/home/auth_cubit.dart';
import 'firebase_options.dart';
import 'data/services/logging_service.dart';
import 'presentation/home/home_cubit.dart';
import 'presentation/home/home_screen.dart';

final _log = LoggerRepo('main');
Future<void> main() async {
  // Ensure Flutter engine is initialized before running the app
  _log.i('initializing app...');
  WidgetsFlutterBinding.ensureInitialized();
  _log.i('Loading app...');
  runApp(
    MultiBlocProvider(
      providers: [
        // GLOBAL CUBITS (Available to ALL screens/features)
        BlocProvider(
          create: (context) => AuthCubit(),
        ),
        BlocProvider(
          // SettingsCubit loads its own initial state from PrefService
          create: (context) => SettingsCubit()..loadSettings(),
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
  _log.i('App initialized...');
}

Future<void> _initEnvironmentVars() async {
  // DotEnv dotenv = DotEnv() is automatically called during import.
  // If you want to load multiple dotenv files or name your dotenv object differently, you can do the following and import the singleton into the relavant files:
  // DotEnv another_dotenv = DotEnv()
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    _log.i('Error loading .env file: $e');
  }
}

 Future<FirebaseApp> _initializeFirebase() async {
    final useEmulatorEnv = dotenv.getBool('USE_FIREBASE_EMULATOR', fallback: false);
    // 1. Get environment variables
    final  emulatorHost = "localhost";//dotenv.get('local_device_ip');
    final firebaseConfigJson = const String.fromEnvironment('__firebase_config', defaultValue: '{}');
    //final appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');
    late final FirebaseApp app;
    
    // Parse config
    Map<String, dynamic> configMap;
    try {
      configMap = jsonDecode(firebaseConfigJson);
    } catch (e) {
      _log.e('ERROR: Failed to decode Firebase Config: $e');
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
    final appCheckWebKey = dotenv.get('app_check_site_key');
    await FirebaseAppCheck.instance.activate(
      // Use Play Integrity for real Android builds.
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      // Use App Attest for real iOS builds.
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      // Use reCAPTCHA v3 for web. You must configure this in the Firebase console.
      // Replace 'YOUR_RECAPTCHA_V3_SITE_KEY' with the key from your Firebase project settings.

      webProvider: ReCaptchaV3Provider(appCheckWebKey),
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
  // Securely load keys from environment variables
  final apiKey = dotenv.env['PAYMOB_API_KEY'];
  final integrationId = int.tryParse(dotenv.env['PAYMOB_INTEGRATION_ID'] ?? '');
  final walletIntegrationId = int.tryParse(dotenv.env['PAYMOB_WALLET_INTEGRATION_ID'] ?? '');
  final iFrameId = int.tryParse(dotenv.env['PAYMOB_IFRAME_ID'] ?? '');

  if (apiKey == null || integrationId == null || walletIntegrationId == null || iFrameId == null) {
    _log.e("FATAL: Paymob environment variables are not set in .env file.");
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
  
  Future<void> init() async {
    _log.i('loading environment variables...');
    await _initEnvironmentVars();
    _log.i('initializing Firebase...');
    final app = await _initializeFirebase();
    _log.i('handling analytics...');
    initAnalytics();
    _log.i('loading sevices...');
    await initLocator(app);
    _log.i('ensuring services are ready...');
    await ensureServicesReady();
    _log.i('initializing payment...');
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

// Simple loading view
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

// Simple error view
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
            create: (context) => HomeCubit(),
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, homeState) {
                return MaterialApp(
                  onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,          
                  theme: context.read<SettingsCubit>().state.appTheme.themeData,
                  darkTheme: ThemeData(
                    brightness: Brightness.dark,
                    primaryColor: const Color(0xFF00796B),
                    colorScheme: ColorScheme.fromSwatch(
                      primarySwatch: Colors.teal,
                      brightness: Brightness.dark,
                    ).copyWith(
                      secondary: const Color(0xFFFFA000),
                    ),
                    useMaterial3: true,
                  ),
                  themeMode: context.read<SettingsCubit>().state.themeMode, // Use the themeMode from the SettingsCubit
                  locale: context.read<SettingsCubit>().state.locale, // Use the locale from the SettingsCubit
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: HomeScreen(),
                );
              },
            ),
    );
  }
}
