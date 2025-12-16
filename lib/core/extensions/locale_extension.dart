import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart'; // Adjust import based on your project structure

extension LocalizationExtension on BuildContext {
  AppLocalizations get loc {
    final localizations = AppLocalizations.of(this);
    return localizations;
  }

  // OPTIONAL: A safer method that returns null instead of throwing
  AppLocalizations? get locSafe => AppLocalizations.of(this);
}