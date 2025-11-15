import 'package:flutter/material.dart';

import '../repositories/repo_log.dart';
import '../enums/pref_key.dart';
import '../repositories/i_repo_pref.dart';

/// Manages all business logic related to reading and writing user preferences.
///
/// This service handles data-type conversions (e.g., DateTime <-> String)
/// and provides default values for the application.
class PrefService {
  final IRepoPref _prefsRepo;
  
  final log = RepoLog('PrefsService');

  // The repository is injected via the constructor.
  PrefService(this._prefsRepo);

  // --- Notification ---
  Future<bool> get isEnableNotifcations async =>
      await _prefsRepo.getBool(PreferencesKey.enableNotifications.name);

  Future<void> setEnableNotifcations(bool value) async {
    await _prefsRepo.setBool(PreferencesKey.enableNotifications.name, value);
  }

  // --- User data ---
  String get currentUserId =>
       _prefsRepo.getString(PreferencesKey.currentUserId.name) ?? '';

  Future<void> setCurrentUserId(String value) async {
    await _prefsRepo.setString(PreferencesKey.currentUserId.name, value);
  }

  String get userAuthToken => _prefsRepo.getString(PreferencesKey.authToken.name) ?? '';

  Future<void> setUserAuthToken(String? value) async {
    // Business Logic: Handle setting a null token by removing the key
    if (value != null) {
      await _prefsRepo.setString(PreferencesKey.authToken.name, value);
    } else {
      await _prefsRepo.remove(PreferencesKey.authToken.name);
    }
  }

  // --- User session ---
  bool get isFirstLogin =>
       _prefsRepo.getBool(PreferencesKey.isFirstLogin.name,
          defaultValue: true); // Business Logic: Default value is true

  Future<void> setIsFirstLogin(bool value) async {
    await _prefsRepo.setBool(PreferencesKey.isFirstLogin.name, value);
  }

  // --- New Logic for Onboarding ---
  bool get hasSeenWelcomeChat => _prefsRepo.getBool(PreferencesKey.hasSeenWelcomeChat.name);

  Future<void> setHasSeenWelcomeChat(bool value) async {
    await _prefsRepo.setBool(PreferencesKey.hasSeenWelcomeChat.name, value);
  }

  bool get isUserLoggedin  =>
      _prefsRepo.getBool(PreferencesKey.userIsLoggedin.name);

  Future<void> setUserIsLoggedin(bool value) async {
    await _prefsRepo.setBool(PreferencesKey.userIsLoggedin.name, value);
  }

  DateTime? get userLoggedInTime {
    // Business Logic: Convert String to DateTime
    final timeString =
        _prefsRepo.getString(PreferencesKey.userLoginTime.name);
    return timeString != null ? DateTime.tryParse(timeString) : null;
  }

  Future<void> setUserLoggedInTime(DateTime value) async {
    // Business Logic: Convert DateTime to String
    await _prefsRepo.setString(
        PreferencesKey.userLoginTime.name, value.toIso8601String());
  }

  Future<DateTime?> get userLoggedOffTime async {
    final timeString =
        _prefsRepo.getString(PreferencesKey.userLoggedOffTime.name);
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
  Future<void> setThemeDark(bool isDark) async {
    await _prefsRepo.setBool(PreferencesKey.themeMode.name, isDark);
  }

  bool get isDarkTheme => _prefsRepo.getBool(PreferencesKey.themeMode.name);

  Future<void> setTheme(String theme) async {
    await _prefsRepo.setString(PreferencesKey.themeName.name, theme);
  }

  String get theme => _prefsRepo.getString(PreferencesKey.themeName.name) ?? "oceanBlueTheme";


  // --- Language ---
  Future<void> setlanguage(String language) async {
    await _prefsRepo.setString(PreferencesKey.language.name, language);
  }

  String get language =>
      // Business Logic: Provide a default language code
      _prefsRepo.getString(PreferencesKey.language.name) ??
      LanguageCodes.enUS;
}


class LanguageCodes{
  static const String arEG = 'ar-EG';
  static const String enUS = 'en-US';
}