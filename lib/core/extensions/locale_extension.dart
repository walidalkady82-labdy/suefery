import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart'; // Adjust import based on your project structure

extension LocalizationExtension on BuildContext {
  AppLocalizations get loc {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      // Fallback behavior: 
      // In development: Throw error to alert you immediately.
      // In production: You might want to return a dummy object or restart the app.
      throw Exception('Localization not found in this context. Ensure MaterialApp has supportedLocales set.');
    }
    return localizations;
  }

  // OPTIONAL: A safer method that returns null instead of throwing
  AppLocalizations? get locSafe => AppLocalizations.of(this);
}