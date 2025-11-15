import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// A wrapper around the `logger` package to provide a standardized
/// and configurable logging service throughout the app.
///
/// This approach allows for:
/// 1.  **Centralized Configuration**: Change log levels and outputs for the
///     entire app from one place.
/// 2.  **Different Log Levels**: Use `verbose`, `debug`, `info`, `warning`,
///     `error`, and `wtf` (what a terrible failure).
/// 3.  **Environment-specific Logging**: Show detailed, colorful logs in debug
///     mode and only critical errors in production.
/// 4.  **Integration**: Easily add outputs to send logs to services like
///     Sentry, Firebase Crashlytics, or a custom backend.

class LoggerRepo {
  final Logger _logger;

  /// Creates a logging repository with a specific [className] tag.
  ///
  /// The `logger` instance is configured statically, so all instances of
  /// `LoggerRepo` will share the same output and level settings.
  LoggerRepo(String className)
      : _logger = Logger(
          // The printer formats the log message.
          printer: _getPrinter(className),
          // The output sends the log to its destination (e.g., console).
          output: _logOutput,
          // The filter controls which log levels are shown.
          filter: _logFilter,
        );

  // --- Static Configuration ---

  /// Configures the filter to show all logs in debug mode, but only
  /// warnings and above in release mode.
  static final _logFilter = ProductionFilter()
    ..level = kDebugMode ? Level.verbose : Level.warning;

  /// Configures the output to be the standard console.
  /// This could be replaced or augmented with a `FileOutput` or a
  /// custom output for a remote service.
  static final _logOutput = ConsoleOutput();

  /// Creates a `PrettyPrinter` for debug mode and a `SimplePrinter` for release.
  /// The class name is included in the log message.
  static PrettyPrinter _getPrinter(String className) {
    return PrettyPrinter(
      methodCount: 0, // Number of stack trace methods to show.
      errorMethodCount: 5, // Show stack trace for errors.
      lineLength: 80,
      colors: true, // Colorful log messages.
      printEmojis: true, // Add an emoji for each log level.
    );
    // The `messageFormatter` parameter is deprecated/removed.
    // The class name will be part of the message itself when logged.
    // e.g., _log.i('My log message'); -> becomes _log.i('[$className] My log message');
  }

  // --- Public Logging Methods ---

  /// Log a message at level [Level.verbose].
  void v(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.v('$message', error: error, stackTrace: stackTrace);

  /// Log a message at level [Level.debug].
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.d('$message', error: error, stackTrace: stackTrace);

  /// Log a message at level [Level.info].
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.i('$message', error: error, stackTrace: stackTrace);

  /// Log a message at level [Level.warning].
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.w('$message', error: error, stackTrace: stackTrace);

  /// Log a message at level [Level.error].
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e('$message', error: error, stackTrace: stackTrace);
}