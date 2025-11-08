part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final AppTheme appTheme;
  final Locale locale;

  const SettingsState({
    required this.themeMode,
    required this.appTheme,
    required this.locale,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      themeMode: ThemeMode.light,
      appTheme: AppTheme.oceanBlue,
      locale: Locale('en'),
    );
  }

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppTheme? appTheme,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      appTheme: appTheme ?? this.appTheme,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object> get props => [themeMode, appTheme, locale];
}

/// An enum representing the available application themes.
enum AppTheme {
  /// The Ocean Blue theme.
  oceanBlue,

  /// The Sunset Orange theme.
  sunsetOrange,
}

/// Extension to convert theme to readable format
extension AppThemeExtension on AppTheme {
  String get name {
    switch (this) {
      case AppTheme.oceanBlue:
        return 'Ocean Blue';
      case AppTheme.sunsetOrange:
        return 'Sunset Orange';
    }
  }

  ThemeData get themeData {
    switch (this) {
      case AppTheme.oceanBlue:
        return oceanBlueTheme;
      case AppTheme.sunsetOrange:
        return sunsetOrangeTheme;
    }
  }
}