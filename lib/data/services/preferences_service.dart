import 'package:flutter/foundation.dart';
import 'package:suefery/domain/repositories/prefs_repos.dart';
import '../../domain/repositories/log_repo.dart';

class PrefsService {
  // Private constructor for the singleton pattern
  PrefsService._(this.prefsRepo);

  // The single, static instance of the service
  static PrefsService? _instance;

  // The repository for accessing SharedPreferences
  final PrefsRepo prefsRepo;
  final _log = LogRepo('PrefsService');

  // Static method to initialize the service and get the instance
  static Future<PrefsService> init() async {
    final _log = LogRepo('PrefsService');
    if (_instance == null) {
      final repo = PrefsRepo();
      // No async init needed for SharedPreferences wrapper, it's handled internally.
      _instance = PrefsService._(repo);
      _log.i('PrefsService initialized.');
    }
    return _instance!;
  }
  
  // Notification
  Future<bool> get isEnableNotifcations async => await prefsRepo.getBool(PreferencesKey.enableNotifications.name);
  Future<void> setEnableNotifcations(bool value) async{
    await prefsRepo.saveBool(PreferencesKey.enableNotifications.name, value);
  }
  //----- User data---------
  Future<String> get currentUserId async => await prefsRepo.getString(PreferencesKey.currentUserId.name) ?? '';
  Future<void> setCurrentUserId(String value) async{
    await prefsRepo.saveString(PreferencesKey.currentUserId.name, value);
  }
  
  Future<String> get userAuthToken async => await prefsRepo.getString(PreferencesKey.authToken.name) ?? '';
  Future<void> setUserAuthToken(String? value) async{
    if (value != null) {
      await prefsRepo.saveString(PreferencesKey.authToken.name, value);
    }
  }
  //----- User session---------
  Future<bool> get isFirstLogin async => await prefsRepo.getBool(PreferencesKey.isFirstLogin.name, defaultValue: true);
  Future<void> setIsFirstLogin(bool value) async{
    await prefsRepo.saveBool(PreferencesKey.isFirstLogin.name, value);
  }
  Future<bool> get isUserLoggedin async => await prefsRepo.getBool(PreferencesKey.userIsLoggedin.name);
  Future<void> setUserIsLoggedin(bool value) async{
    await prefsRepo.saveBool(PreferencesKey.userIsLoggedin.name, value);
  }
  Future<DateTime?> get userLoggedInTime async {
    final timeString = await prefsRepo.getString(PreferencesKey.userLoginTime.name);
    return timeString != null ? DateTime.tryParse(timeString) : null;
  }
  Future<void> setUserLoggedInTime(DateTime value) async{
    await prefsRepo.saveString(PreferencesKey.userLoginTime.name, value.toIso8601String());
  }
  Future<DateTime?> get userLoggedOffTime async {
    final timeString = await prefsRepo.getString(PreferencesKey.userLoggedOffTime.name);
    return timeString != null ? DateTime.tryParse(timeString) : null;
  }
  Future<void> setUserLoggedOffTime(DateTime? value) async{
    if (value != null) {
      await prefsRepo.saveString(PreferencesKey.userLoggedOffTime.name, value.toIso8601String());
    }
  }

  //-----Interface
  Future<void> setTheme(bool isDark) async{
    await prefsRepo.saveBool(PreferencesKey.themeMode.name, isDark);
  }
  
  Future<bool> get isDarkTheme async => await prefsRepo.getBool(PreferencesKey.themeMode.name);
  //language
  Future<void> setlanguage(String language) async{
    await prefsRepo.saveString(PreferencesKey.language.name, language);
  }
  Future<String> get language async => await prefsRepo.getString(PreferencesKey.language.name) ?? LanguageCodes.enUS;
}

enum PreferencesKey {
  enableNotifications,
  currentUserId,
  authToken,
  isFirstLogin,
  userIsLoggedin,
  userLoginTime,
  userLoggedOffTime,
  themeMode,
  language,
}

class LanguageCodes{
  static const String arEG = 'ar-EG';
  static const String enUS = 'en-US';
}