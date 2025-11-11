
// This is the global instance of GetIt
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:suefery/data/repositories/i_repo_auth.dart';
import 'package:suefery/data/repositories/i_repo_firebase_ai.dart';
import 'package:suefery/data/repositories/i_repo_firestore.dart';
import 'package:suefery/data/repositories/repo_firebase_ai.dart';
import 'package:suefery/data/services/firebase_ai_service.dart';
import 'package:suefery/data/services/order_service.dart';
import 'package:suefery/data/services/user_service.dart';
import 'package:suefery/data/repositories/repo_firestore.dart';

import 'data/repositories/i_repo_pref.dart';
import 'data/services/auth_service.dart';
import 'data/services/chat_service.dart';
import 'data/services/pref_service.dart';
import 'data/services/remote_config_service.dart';
import 'data/repositories/repo_auth.dart';
import 'data/repositories/repo_prefs.dart';

final sl = GetIt.instance; // sl = Service Locator
/// Initializes all services and repositories for the app.
/// This function must be called in main.dart before runApp().
Future<void> initLocator(FirebaseApp firebaseApp) async {

  final configService = await RemoteConfigService.create();
  final prefsRepo = await RepoPref.create();
  // --- CONFIGURATION ---
  // Determine if we should use emulators (adjust this logic as needed)
  //const bool useEmulators = kDebugMode; 

  // --- REPOSITORIES (The "Workers") ---

  // PrefsRepo (Async setup)
  // We register a factory that returns the Future<PrefsRepository>

  final useEmulatorEnv = dotenv.getBool('USE_FIREBASE_EMULATOR', fallback: false);
  final useGeminiMocks = dotenv.getBool('gemini_use_mocks', fallback: false);

  sl.registerSingleton<IRepoPref>(prefsRepo);

  // AuthRepo (Async setup for emulator)
  sl.registerSingletonAsync<IRepoAuth>(() async {
    return await RepoAuth.create(useEmulator: useEmulatorEnv);
  });

  // FirestoreRepo (Async setup for emulator)
  sl.registerSingleton<IRepoFirestore>(
    RepoFirestore.create(useEmulator: useEmulatorEnv)
  );

  // No longer needed, as AI logic is now in a Cloud Function.
  // sl.registerLazySingleton<IRepoFirebaseAi>(
  //     () => RepoFirebaseAi.create());
  // --- SERVICES (The "Managers") ---
  
  // Remote Config Service (Async) ---
  sl.registerSingleton<RemoteConfigService>(configService);

  // Auth Service
  sl.registerLazySingleton<AuthService>(() => AuthService(
        sl<IRepoAuth>(),
        sl<PrefService>(),
      ));

  // Prefs Service
  sl.registerLazySingleton<PrefService>(() => PrefService(
        sl<IRepoPref>(), // GetIt finds the registered IPrefsRepository
      ));
      
  // User Service
  sl.registerLazySingleton<UserService>(() => UserService(
        sl<IRepoFirestore>(), // GetIt finds the registered IFirestoreRepository
      ));

  // Register Firebase Functions with the correct region
  sl.registerLazySingleton(() => FirebaseFunctions.instanceFor(app: firebaseApp, region: 'us-central1'));

  sl.registerLazySingleton<FirebaseAiService>(() => FirebaseAiService(
       sl<FirebaseFunctions>() , useGeminiMocks
      ));    
  // Order Service
  sl.registerLazySingleton<OrderService>(() => OrderService(
        sl<IRepoFirestore>(), // GetIt finds the registered IFirestoreRepository
        sl<RemoteConfigService>(), // GetIt finds the registered RemoteConfigService
      ));

    // Chat Service
  sl.registerLazySingleton<ChatService>(() => ChatService(
       sl<IRepoFirestore>() ,
       sl<FirebaseAiService>()
      ));
}

/// Awaits for all asynchronous singletons to be ready.
/// This should be called after `initLocator` and before the app runs.
Future<void> ensureServicesReady() async {
  // This will ensure that any async singletons, like our repositories,
  // are fully initialized before they are used.
  // GetIt will automatically wait for all `registerSingletonAsync` dependencies.
  await sl.allReady();
}