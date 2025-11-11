import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../repositories/repo_log.dart';

class RemoteConfigService {
  final _log = RepoLog('RemoteConfigService');
  final FirebaseRemoteConfig _remoteConfig;

  // --- Default values ---
  // These are used if the app can't fetch from the server.
  static final Map<String, dynamic> _defaults = {
    'delivery_fee': 10.0,
    'min_order_amount': 50.0,
    'is_gemini_enabled': true,
    'gemini_use_mocks': kDebugMode, // Use kDebugMode as the default
  };

  RemoteConfigService(this._remoteConfig);

  /// Initializes the service, sets defaults, and fetches new values.
  /// This should be called from the service locator.
  static Future<RemoteConfigService> create() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    // 1. Set configuration for fetching (especially in debug mode)
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      // Use a low minimum interval for easy debugging
      minimumFetchInterval: kDebugMode 
          ? const Duration(seconds: 10) 
          : const Duration(hours: 1),
    ));

    // 2. Set the default values
    await remoteConfig.setDefaults(_defaults);

    // 3. Fetch and activate the new values
    try {
      await remoteConfig.fetchAndActivate();
      RepoLog('RemoteConfigService').i('Fetched & activated new config.');
    } catch (e) {
      RepoLog('RemoteConfigService').w('Failed to fetch remote config: $e');
      // If it fails, the app will just use the default values.
    }

    return RemoteConfigService(remoteConfig);
  }

  // --- Business Rule Getters ---
  
  /// The standard delivery fee for an order.
  double get deliveryFee => _remoteConfig.getDouble('delivery_fee');

  /// The minimum EGP amount for an order to be placed.
  double get minOrderAmount => _remoteConfig.getDouble('min_order_amount');

  /// An "emergency stop" for the AI feature.
  bool get isGeminiEnabled => _remoteConfig.getBool('is_gemini_enabled');
  
  /// A cloud-controlled switch to enable mock mode.
  /// This overrides the kDebugMode default.
  bool get geminiUseMocks => _remoteConfig.getBool('gemini_use_mocks');

  /// A cloud-controlled switch to enable mock mode.
  /// This overrides the kDebugMode default.
  bool get firebaseUseEmulator => _remoteConfig.getBool('firebase_use_emulator');
}