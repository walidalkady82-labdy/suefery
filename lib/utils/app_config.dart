/// A centralized place for application-wide constants and configurations.
class AppConfig {
  /// Default timeout for network requests (e.g., API calls, database operations).
  ///
  /// Using a consistent timeout helps prevent the app from hanging on slow networks.
  static const Duration defaultNetworkTimeout = Duration(seconds: 20);

  /// A shorter timeout for operations that should be very fast.
  static const Duration shortNetworkTimeout = Duration(seconds: 8);
}
