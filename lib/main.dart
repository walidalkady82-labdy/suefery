import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:suefery/core/l10n/app_localizations.dart';
import 'package:suefery/locator.dart';
import 'package:suefery/presentation/auth/auth_cubit.dart';
import 'firebase_options.dart';
import 'presentation/auth/auth_checker.dart';
import 'data/services/firebase_service.txt';
import 'data/services/logging_service.dart';
import 'presentation/home/home_cubit.dart';

final _log = LoggerRepo('main');
Future<void> main() async {
  // Ensure Flutter engine is initialized before running the app
  _log.i('initializing app...');
  WidgetsFlutterBinding.ensureInitialized();
  _log.i('loading environment variables...');
  await _initEnvironmentVars();
  _log.i('initializing Firebase...');
  final app = await _initializeFirebase();
  _log.i('handling analytics...');
  handleAnalytics();
  _log.i('loading sevices...');
  await initLocator(app);
  _log.i('Loading app...');
  runApp(
    MultiBlocProvider(
      providers: [
        // GLOBAL CUBITS (Available to ALL screens/features)
        BlocProvider(
          // AuthCubit depends on AuthService
          create: (context) => AuthCubit(),
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
    await dotenv.load(fileName: ".env");
  } catch (e) {
    _log.i('Error loading .env file: $e');
  }
}

 Future<FirebaseApp> _initializeFirebase() async {
    // 1. Get environment variables
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

       // await FirebaseStorage.instance.useEmulator(
      // host: 'localhost',
      // port: 9199,
      // );
    return app;
  }

void handleAnalytics(){
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
/// A wrapper widget that handles the asynchronous initialization of Firebase
/// and authentication before rendering the main application.
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
    _initialization = FirebaseService.instance.initialize();
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
    // Using a Builder here to get a context that is a descendant of MaterialApp.
    // This ensures that AppLocalizations is available.
    return Builder(
      builder: (context) {
        return MaterialApp(
          // Now this will work because the context is from the Builder.
          // However, it's better to use a widget that needs the title,
          // like the home screen's AppBar, to set the title.
          // For simplicity, we can set it here if needed.
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
          theme: ThemeData(
            primaryColor: const Color(0xFF00796B), // Teal 700 (SUEFERY Primary)
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.teal,
            ).copyWith(
              secondary: const Color(0xFFFFA000), // Amber 700 (Accent)
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor : Color(0xFF00796B),
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthChecker(),
          
        );
      }
    );
  }
}
