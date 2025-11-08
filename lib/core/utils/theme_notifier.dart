

import 'package:flutter/material.dart';
import 'package:suefery/data/services/pref_service.dart';
import 'package:suefery/locator.dart';

/// A simple ValueNotifier to manage the app's current theme mode.
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  final PrefService _prefService = sl<PrefService>();

  ThemeNotifier(super.value);

  bool get isDarkMode => value == ThemeMode.dark;

  /// Toggles between light and dark mode and persists the choice.
  void toggleTheme(bool isDark) {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (value == newMode) return; // Don't do anything if the theme is the same
    value = newMode;
    _prefService.setThemeDark(isDark);
  }
}
