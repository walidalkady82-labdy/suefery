import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:suefery/data/repository/i_repo_auth.dart';
import 'package:suefery/data/repository/i_repo_firestore.dart';
import 'package:suefery/data/service/service_firebase_ai.dart';
import 'package:suefery/data/service/service_keep_alive.dart';
import 'package:suefery/data/service/service_location.dart';
import 'package:suefery/data/service/service_suggestion.dart';
import 'package:suefery/data/service/service_user.dart';
import 'package:suefery/data/repository/repo_firestore.dart';
import 'package:suefery/data/service/service_notification.dart';
import 'package:suefery/data/repository/i_repo_pref.dart';
import 'data/service/service_auth.dart';
import 'data/service/service_chat.dart';
import 'data/service/service_order.dart';
import 'data/service/service_pref.dart';
import 'data/service/service_remote_config.dart';
import 'data/repository/repo_auth.dart';
import 'data/repository/repo_prefs.dart';

final sl = GetIt.instance; // sl = Service Locator
/// Initializes all services and repositories for the app.
/// This function must be called in main.dart before runApp().
Future<void> initLocator(FirebaseApp firebaseApp) async {

  final configService = await ServiceRemoteConfig.create();
  final prefsRepo = await RepoPref.create();
  // --- CONFIGURATION ---
  // Determine if we should use emulators (adjust this logic as needed)
  //const bool useEmulators = kDebugMode; 

  // --- REPOSITORIES (The "Workers") ---

  // PrefsRepo (Async setup)
  // We register a factory that returns the Future<PrefsRepository>

  final useEmulatorEnv = dotenv.getBool('USE_FIREBASE_EMULATOR', fallback: false);

  sl.registerSingleton<IRepoPref>(prefsRepo);

  // AuthRepo (Async setup for emulator)
  sl.registerSingletonAsync<IRepoAuth>(() async {
    return await RepoAuth.create(useEmulator: useEmulatorEnv);
  });

  // FirestoreRepo (Async setup for emulator)
  sl.registerSingleton<IRepoFirestore>(
    RepoFirestore.create(useEmulator: useEmulatorEnv)
  );

  // --- SERVICES (The "Managers") ---
  
  // Remote Config Service (Async) ---
  sl.registerSingleton<ServiceRemoteConfig>(configService);

  // Auth Service
  sl.registerLazySingleton<ServiceAuth>(() => ServiceAuth(
        sl<IRepoAuth>(),
        sl<IRepoFirestore>(),
        sl<ServicePref>(),
        sl<ServiceKeepAlive>(),
      ));

  // Prefs Service
  sl.registerLazySingleton<ServicePref>(() => ServicePref(
        sl<IRepoPref>(), // GetIt finds the registered IPrefsRepository
      ));
      
  // User Service
  sl.registerLazySingleton<ServiceUser>(() => ServiceUser(
        sl<ServiceAuth>(), // GetIt finds the registered IFirestoreRepository
        sl<IRepoFirestore>(), // GetIt finds the registered IFirestoreRepository
      ));

  // Register Firebase Functions with the correct region
  sl.registerLazySingleton(() => FirebaseFunctions.instanceFor(app: firebaseApp, region: 'us-central1'));

  sl.registerLazySingleton<ServiceFirebaseAi>(() => ServiceFirebaseAi(
       sl<FirebaseFunctions>() 
      ));    
  //Order Service
  sl.registerLazySingleton<ServiceOrder>(() => ServiceOrder(
        sl<IRepoFirestore>(), // GetIt finds the registered IFirestoreRepository
        sl<ServiceRemoteConfig>(), // GetIt finds the registered RemoteConfigService
      ));

    // Chat Service
  sl.registerLazySingleton<ServiceChat>(() => ServiceChat(
       sl<IRepoFirestore>() ,
       sl<ServiceFirebaseAi>()
      ));

  sl.registerLazySingleton<ServiceSuggestion>(() => ServiceSuggestion());

  sl.registerLazySingleton<ServiceNotification>(() => ServiceNotification());

  sl.registerLazySingleton<ServiceLocation>(() => ServiceLocation());

  // Keep Alive Service
  sl.registerLazySingleton<ServiceKeepAlive>(() => ServiceKeepAlive(
    sl<IRepoFirestore>() 
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