import 'package:flutter/widgets.dart';
import 'package:suefery/core/l10n/app_localizations.dart';

extension L10n on BuildContext {
  /// A convenient way to access the AppLocalizations for the current context.
  /// Usage: `context.l10n.appTitle`
  AppLocalizations get l10n => AppLocalizations.of(this);
}
