import 'package:flutter/material.dart';
import 'package:suefery/data/services/pref_service.dart';
import 'package:suefery/locator.dart';

/// A simple ValueNotifier to manage the app's current locale.
/// This allows the MaterialApp to reactively update its locale.
class LocaleNotifier extends ValueNotifier<Locale> {
  final PrefService _prefService = sl<PrefService>();

  LocaleNotifier(super.value);

  /// Sets a new locale and notifies listeners.
  void setLocale(Locale newLocale) {
    if (value == newLocale) return; // Don't do anything if the locale is the same
    value = newLocale;
    _prefService.language;  //('selected_language', newLocale.languageCode)
  }
  
}
