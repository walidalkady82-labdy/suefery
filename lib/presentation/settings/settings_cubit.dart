import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/utils/themes.dart';
import 'package:suefery/data/services/logging_service.dart';
import 'package:suefery/data/services/pref_service.dart';
import 'package:suefery/locator.dart';

part 'settings_state.dart';

Future<void> setTheme(bool isDark) async {
}

class SettingsCubit extends Cubit<SettingsState> {
  final PrefService _prefService = sl<PrefService>();
  final _log = LoggerRepo('SettingsCubit');

  SettingsCubit() : super(SettingsState.initial());

  /// Loads the user's saved settings from preferences.
  void loadSettings() {
    _log.i('Loading user settings...');
    final isDark = _prefService.isDarkTheme;
    final theme = _prefService.theme;
    final langCode = _prefService.language;

    emit(state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      appTheme: theme == 'sunsetOrange' ? AppTheme.sunsetOrange: AppTheme.oceanBlue,
      locale: Locale(langCode),
    ));
  }

  /// Sets a new locale and persists it.
  void setLocale(Locale newLocale) {
    if (state.locale == newLocale) return;

    emit(state.copyWith(locale: newLocale));
    _prefService.setlanguage(newLocale.languageCode);
    emit(state.copyWith(locale: newLocale));
  }

  /// Changes the application theme and persists the choice.
  void changeTheme(AppTheme theme) {
    if (state.appTheme == theme) return;

    _log.i('Changing theme to ${theme.name}');
    _prefService.setTheme(theme.name);
    emit(state.copyWith(appTheme: theme));
  }

  /// Toggles dark mode and persists the choice.
  void toggleDarkMode(bool isDark) {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _prefService.setThemeDark(isDark);
    emit(state.copyWith(themeMode: newMode));
  }
}