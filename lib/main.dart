import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:suefery/presentation/auth/auth_cubit.dart';
import 'package:suefery/firebase_options.dart';
import 'package:suefery/data/services/gemini_service.dart';
import 'app_container.dart';
import 'data/services/auth_service.dart';
import 'data/services/preferences_service.dart';
// import 'presentation/history/order_history_cubit.txt';
// import 'presentation/history/customer_order_history.txt';
import 'data/services/firebase_service.dart';
import 'data/services/logging_service.dart';

import 'presentation/home/home_cubit.dart';

final _log = LoggerReprository('main');
Future<void> main() async {
  // Ensure Flutter engine is initialized before running the app
  _log.i('initializing app...');
  WidgetsFlutterBinding.ensureInitialized();
  _log.i('loading environment variables...');
  await _initEnvironmentVars();
  _log.i('loading firebaseApp...');
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    _log.e("Firebase Init Error: $e");
  }
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
  _log.i('loading sevices...');
  final PrefsService prefsService = await PrefsService.init();
  final AuthService authService = AuthService(prefsService);
  final GeminiService geminiService = GeminiService();
  final firebaseService = FirebaseService.instance;
  _log.i('initializing app...');
  runApp(
    MultiBlocProvider(
      providers: [
        // GLOBAL CUBITS (Available to ALL screens/features)
        BlocProvider(
          // AuthCubit depends on AuthService
          create: (context) => AuthCubit(authService),
        ),
        BlocProvider(
          // GeminiCubit depends on GeminiService
          create: (context) => HomeCubit(
            firebaseService,
            geminiService,
            ""
            ),
        ),
        // BlocProvider(
        //   // GeminiCubit depends on GeminiService
        //   create: (context) => OrderHistoryCubit(),
        // ),
        // FEATURE CUBITS (Can be added here or on specific routes)
        // BlocProvider(create: (_) => BookingCubit()),
      ],
      child: const AppContainer(child:SUEFERYApp() ),
    ),
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
