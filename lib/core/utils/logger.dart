import 'package:logging/logging.dart';

/// A mixin that provides standardized logging capabilities using the 'logging' package.
///
/// Usage:
/// ```dart
/// class AuthCubit extends Cubit<AuthState> with LogMixin {
///   void login() {
///     logInfo('Logging in...');
///   }
/// }
/// ```
mixin LogMixin {
  /// The tag used for logging. Defaults to the Class Name.
  String get logTag => runtimeType.toString();

  /// Lazy initialization of the Logger.
  late final Logger _logger = Logger(logTag);

  /// ℹ️ Info: General app flow events.
  void logInfo(String message) {
    _logger.info(message);
  }

  /// ⚠️ Warning: Unexpected events that aren't crashes.
  void logWarning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.warning(message, error, stackTrace);
  }

  /// 🚨 Error: Failures, exceptions, and blockers.
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.severe(message, error, stackTrace);
  }

  /// 🐛 Debug: Detailed debug info (only shown in development).
  void logDebug(String message) {
    _logger.fine(message);
  }
}