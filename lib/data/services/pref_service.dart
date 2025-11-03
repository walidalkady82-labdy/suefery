import '../../domain/repositories/log_repo.dart';
import '../enums/pref_key.dart';
import '../repositories/i_pref_repo.dart';

/// Manages all business logic related to reading and writing user preferences.
///
/// This service handles data-type conversions (e.g., DateTime <-> String)
/// and provides default values for the application.
class PrefService {
  final IPrefRepo _prefsRepo;
  
  final log = LogRepo('PrefsService');

  // The repository is injected via the constructor.
  PrefService(this._prefsRepo);

  // --- Notification ---
  Future<bool> get isEnableNotifcations async =>
      await _prefsRepo.getBool(PreferencesKey.enableNotifications.name);

  Future<void> setEnableNotifcations(bool value) async {
    await _prefsRepo.setBool(PreferencesKey.enableNotifications.name, value);
  }

  // --- User data ---
  Future<String> get currentUserId async =>
      await _prefsRepo.getString(PreferencesKey.currentUserId.name) ?? '';

  Future<void> setCurrentUserId(String value) async {
    await _prefsRepo.setString(PreferencesKey.currentUserId.name, value);
  }

  Future<String> get userAuthToken async =>
      await _prefsRepo.getString(PreferencesKey.authToken.name) ?? '';

  Future<void> setUserAuthToken(String? value) async {
    // Business Logic: Handle setting a null token by removing the key
    if (value != null) {
      await _prefsRepo.setString(PreferencesKey.authToken.name, value);
    } else {
      await _prefsRepo.remove(PreferencesKey.authToken.name);
    }
  }

  // --- User session ---
  Future<bool> get isFirstLogin async =>
      await _prefsRepo.getBool(PreferencesKey.isFirstLogin.name,
          defaultValue: true); // Business Logic: Default value is true

  Future<void> setIsFirstLogin(bool value) async {
    await _prefsRepo.setBool(PreferencesKey.isFirstLogin.name, value);
  }

  Future<bool> get isUserLoggedin async =>
      await _prefsRepo.getBool(PreferencesKey.userIsLoggedin.name);

  Future<void> setUserIsLoggedin(bool value) async {
    await _prefsRepo.setBool(PreferencesKey.userIsLoggedin.name, value);
  }

  Future<DateTime?> get userLoggedInTime async {
    // Business Logic: Convert String to DateTime
    final timeString =
        await _prefsRepo.getString(PreferencesKey.userLoginTime.name);
    return timeString != null ? DateTime.tryParse(timeString) : null;
  }

  Future<void> setUserLoggedInTime(DateTime value) async {
    // Business Logic: Convert DateTime to String
    await _prefsRepo.setString(
        PreferencesKey.userLoginTime.name, value.toIso8601String());
  }

  Future<DateTime?> get userLoggedOffTime async {
    final timeString =
        await _prefsRepo.getString(PreferencesKey.userLoggedOffTime.name);
    return timeString != null ? DateTime.tryParse(timeString) : null;
  }

  Future<void> setUserLoggedOffTime(DateTime? value) async {
    // Business Logic: Handle null by removing the key
    if (value != null) {
      await _prefsRepo.setString(
          PreferencesKey.userLoggedOffTime.name, value.toIso8601String());
    } else {
      await _prefsRepo.remove(PreferencesKey.userLoggedOffTime.name);
    }
  }

  // --- Interface ---
  Future<void> setTheme(bool isDark) async {
    await _prefsRepo.setBool(PreferencesKey.themeMode.name, isDark);
  }

  Future<bool> get isDarkTheme async =>
      await _prefsRepo.getBool(PreferencesKey.themeMode.name);

  // --- Language ---
  Future<void> setlanguage(String language) async {
    await _prefsRepo.setString(PreferencesKey.language.name, language);
  }

  Future<String> get language async =>
      // Business Logic: Provide a default language code
      await _prefsRepo.getString(PreferencesKey.language.name) ??
      LanguageCodes.enUS;
}


class LanguageCodes{
  static const String arEG = 'ar-EG';
  static const String enUS = 'en-US';
}