
// This is the global instance of GetIt
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:suefery/data/repositories/i_auth_repo.dart';
import 'package:suefery/data/repositories/i_firestore_repository.dart';
import 'package:suefery/data/repositories/i_gemini_repo.dart';
import 'package:suefery/data/services/gemini_service.dart';
import 'package:suefery/data/services/order_service.dart';
import 'package:suefery/data/services/user_service.dart';
import 'package:suefery/domain/repositories/firestore_repos.dart';
import 'package:suefery/domain/repositories/gemini_repo.dart';

import 'data/repositories/i_pref_repo.dart';
import 'data/services/auth_service.dart';
import 'data/services/chat_service.dart';
import 'data/services/pref_service.dart';
import 'data/services/remote_config_service.dart';
import 'domain/repositories/auth_repo.dart';
import 'domain/repositories/prefs_repos.dart';

final sl = GetIt.instance; // sl = Service Locator
/// Initializes all services and repositories for the app.
/// This function must be called in main.dart before runApp().
Future<void> initLocator(FirebaseApp firebaseApp) async {

  final configService = await RemoteConfigService.create();
  final prefsRepo = await PrefRepo.create();
  // --- CONFIGURATION ---
  // Determine if we should use emulators (adjust this logic as needed)
  //const bool useEmulators = kDebugMode; 

  // --- REPOSITORIES (The "Workers") ---

  // PrefsRepo (Async setup)
  // We register a factory that returns the Future<PrefsRepository>

  final useEmulatorEnv = dotenv.getBool('USE_FIREBASE_EMULATOR', fallback: false);
  final useGeminiMocks = dotenv.getBool('gemini_use_mocks', fallback: false);

  sl.registerSingleton<IPrefRepo>(prefsRepo);

  // AuthRepo (Async setup for emulator)
  sl.registerSingletonAsync<IAuthRepo>(() async {
    return await AuthRepo.create(useEmulator: useEmulatorEnv);
  });

  // FirestoreRepo (Async setup for emulator)
  sl.registerSingleton<IFirestoreRepo>(
    FirestoreRepo.create(useEmulator: useEmulatorEnv)
  );

  sl.registerLazySingleton<IGeminiRepo>(
      () => GeminiRepo());
  // --- SERVICES (The "Managers") ---
  
  // Remote Config Service (Async) ---
  sl.registerSingleton<RemoteConfigService>(configService);

  // Auth Service
  sl.registerLazySingleton<AuthService>(() => AuthService(
        sl<IAuthRepo>(),
        sl<PrefService>(),
      ));

  // Prefs Service
  sl.registerLazySingleton<PrefService>(() => PrefService(
        sl<IPrefRepo>(), // GetIt finds the registered IPrefsRepository
      ));
      
  // User Service
  sl.registerLazySingleton<UserService>(() => UserService(
        sl<IFirestoreRepo>(), // GetIt finds the registered IFirestoreRepository
      ));
      
  // Order Service
  sl.registerLazySingleton<OrderService>(() => OrderService(
        sl<IFirestoreRepo>(), // GetIt finds the registered IFirestoreRepository
        sl<RemoteConfigService>(), // GetIt finds the registered RemoteConfigService
      ));
  // Chat Service
  sl.registerLazySingleton<ChatService>(() => ChatService(
       sl<IFirestoreRepo>() 
      ));
    // Chat Service
  sl.registerLazySingleton<GeminiService>(() => GeminiService(
       sl<IGeminiRepo >() , useGeminiMocks
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