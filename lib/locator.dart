
// This is the global instance of GetIt
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:suefery/data/repositories/i_auth_repo.dart';
import 'package:suefery/data/repositories/i_firestore_repository.dart';
import 'package:suefery/data/repositories/i_gemini_repo.dart';
import 'package:suefery/data/services/order_service.dart';
import 'package:suefery/data/services/user_service.dart';
import 'package:suefery/domain/repositories/firestore_repos.dart';
import 'package:suefery/domain/repositories/gemini_repo.dart';

import 'data/repositories/i_pref_repo.dart';
import 'data/services/auth_service.dart';
import 'data/services/chat_service.dart';
import 'data/services/logging_service.dart';
import 'data/services/pref_service.dart';
import 'domain/repositories/auth_repo.dart';
import 'domain/repositories/prefs_repos.dart';

final sl = GetIt.instance; // sl = Service Locator
final _log = LoggerRepo('Locator');
/// Initializes all services and repositories for the app.
/// This function must be called in main.dart before runApp().
Future<void> initLocator(FirebaseApp firebaseApp) async {
  
  // --- CONFIGURATION ---
  // Determine if we should use emulators (adjust this logic as needed)
  const bool useEmulators = kDebugMode; 

  // --- REPOSITORIES (The "Workers") ---

  // PrefsRepo (Async setup)
  // We register a factory that returns the Future<PrefsRepository>
  final prefsRepo = await PrefRepo.create();

  sl.registerSingleton<IPrefRepo>(prefsRepo);

  // AuthRepo (Sync setup, but with emulator config)
  sl.registerLazySingleton<IAuthRepo>(() => AuthRepo.create(
        useEmulator: useEmulators,
      ));

  // FirestoreRepo (Sync setup, with emulator config)
  sl.registerLazySingleton<IFirestoreRepo>(
      () => FirestoreRepo.create(
        useEmulator:  useEmulators
      ));
  sl.registerLazySingleton<IGeminiRepo>(
      () => GeminiRepo());
  // --- SERVICES (The "Managers") ---

  // Auth Service
  sl.registerLazySingleton<AuthService>(() => AuthService(
        sl<IAuthRepo>(), // GetIt finds the registered IAuthRepository
        sl<PrefService>(), // GetIt finds the registered IPrefsRepository
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
      ));
  // Chat Service
  sl.registerLazySingleton<ChatService>(() => ChatService(
        sl<IGeminiRepo>(),sl<IFirestoreRepo>() , useMocks: kDebugMode
      ));
}