import 'package:suefery/core/utils/logger.dart';

class CircuitBreakerController with LogMixin{
  final int failureThreshold;
  final Duration resetTimeout;

  int _failures = 0;
  DateTime? _lastFailureTime;
  
  CircuitBreakerController({
    this.failureThreshold = 3,
    this.resetTimeout = const Duration(seconds: 30),
  });

  bool get isOpen {
    if (_failures < failureThreshold) return false; // Circuit is Closed (Good)
    
    // If open, check if the timeout has expired (Half-Open logic)
    if (DateTime.now().difference(_lastFailureTime!) > resetTimeout) {
      return false; // Let one request through to test connection
    }
    return true; // Still open, block request
  }

  void recordFailure() {
    _failures++;
    if (_failures >= failureThreshold) {
      _lastFailureTime = DateTime.now();
      logWarning("⚠️ Circuit Tripped! Blocking requests for ${resetTimeout.inSeconds}s.");
    }
  }

  void reset() {
    if (_failures > 0) logInfo("✅ Circuit recovered.");
    _failures = 0;
    _lastFailureTime = null;
  }
  
  /// Helper to calculate remaining wait time
  Duration get remainingWait => 
      _lastFailureTime != null 
      ? resetTimeout - DateTime.now().difference(_lastFailureTime!) 
      : Duration.zero;
}