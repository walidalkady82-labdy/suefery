import 'dart:async';

import '../utils/app_config.dart';

extension FutureTimeout<T> on Future<T> {
  /// Applies a default timeout to a [Future].
  ///
  /// Throws a [TimeoutException] if the future does not complete within
  /// the specified [duration], which defaults to [AppConfig.defaultNetworkTimeout].
  Future<T> withDefaultTimeout({Duration? duration}) {
    return timeout(duration ?? AppConfig.defaultNetworkTimeout);
  }
}