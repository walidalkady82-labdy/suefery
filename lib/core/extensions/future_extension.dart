import 'dart:async';
import 'dart:math';

import 'package:suefery/core/extensions/circuit_breaker_controller.dart';

//--------------------------Constants------------------------------------------------

///Defaul timeout for futures.
const kDefaultTimeout = Duration(seconds: 15);
///Defaul timeout for longer futures.
const kLongTimeout = Duration(minutes: 1);
///Fail fast so user can retry credentials.
const kLoginAuthTimeout = Duration(seconds: 10);  
///If it takes longer, the user assumes it's broken. Cancel previous requests if the user keeps typing.
const kSearchQueriesTimeout = Duration(seconds: 5);
/// Use Future.wait to fetch unrelated data parallelly.
const kDashboardDataTimeout = Duration(seconds: 15); 
///60+ seconds to upload a file.
const kFileUploadTimeout = Duration(minutes: 1); 

//------------------------------Extensions--------------------------------------------

extension FutureExtension<T> on Future<T> {
  /// ***Summery:***
  /// 
  /// Wraps the future with a timeout.
  ///
  /// ***Parameters:***
  /// 
  /// [duration]: Timeout duration.
  ///
  Future<T> withTimeout({Duration? duration}) {
    return timeout(
      duration ?? kDefaultTimeout,
      onTimeout: () {
        throw TimeoutException('Future timed out after ${duration ?? kDefaultTimeout}');
      },
    );
  }

}

extension RetryExtension<T> on Future<T> Function() {
  
  /// ***Summery:***
  ///
  /// Retries the operation with timeout, exponential backoff, and jitter.
  ///
  /// ***Parameters:***
  /// 
  /// [maxRetries]: Max attempts after the first failure.
  /// 
  /// [timeout]: Max time allowed per attempt.
  /// 
  /// [initialDelay]: The baseline wait time before the first retry.
  /// 
  /// [backoffFactor]: Multiplier for the delay (e.g., 2.0 = 1s, 2s, 4s).
  /// 
  /// [jitter]: max random duration added to the delay to prevent synchronized retries.
  /// 
  /// [retryIf]: Optional filter to retry only on specific exceptions.
  /// 
  Future<T> withTimeoutR({
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 10),
    Duration initialDelay = const Duration(seconds: 1),
    double backoffFactor = 2.0,
    Duration jitter = const Duration(milliseconds: 500),
    bool Function(Object error)? retryIf
  }) async {
    int attempts = 0;
    final random = Random();

    while (true) {
      attempts++;
      try {
        return await this().timeout(timeout);
      } catch (e) {
        if (attempts > maxRetries || (retryIf != null && !retryIf(e))) {
          rethrow;
        }

        // 1. Calculate Exponential Backoff
        // delay = initial * (factor ^ (attempts - 1))
        final backoffMult = pow(backoffFactor, attempts - 1);
        final baseDelay = initialDelay * backoffMult;

        // 2. Calculate Random Jitter
        // Pick a random millisecond value between 0 and jitter.inMilliseconds
        final jitterMs = jitter.inMilliseconds > 0 
            ? random.nextInt(jitter.inMilliseconds) 
            : 0;
        
        final totalDelay = baseDelay + Duration(milliseconds: jitterMs);

        // Debug Log
        // print('Attempt $attempts failed. Retrying in ${totalDelay.inMilliseconds}ms...');

        await Future.delayed(totalDelay);
      }
    }
  }

  /// ***Summery:***
  ///
  /// Retries the operation with timeout, exponential backoff, jitter ***and circuit breaker***.
  ///
  ///
  /// ***Parameters:***
  /// 
  /// [breaker]: CircuitBreakerController to hold the state.
  /// 
  /// [maxRetries]: Max attempts after the first failure.
  /// 
  /// [timeout]: Max time allowed per attempt.
  /// 
  /// [initialDelay]: The baseline wait time before the first retry.
  /// 
  /// [backoffFactor]: Multiplier for the delay (e.g., 2.0 = 1s, 2s, 4s).
  /// 
  /// [jitter]: max random duration added to the delay to prevent synchronized retries.
  /// 
  /// [retryIf]: Optional filter to retry only on specific exceptions.
  /// 
  /// ***Example Usage:***
  /// 
  /// ```dart
  /// class UserRepository {
  ///   // 1. Keep the state alive here (e.g., as a class property)
  ///   final _circuitControl = CircuitBreakerController(
  ///     failureThreshold: 2, 
  ///     resetTimeout: Duration(seconds: 10),
  ///   );
  ///   Future<String> getUserProfile() async {
  ///     // 2. Use the extension, passing the controller
  ///     return await _fetchProfileFromApi.withCircuitBreakerAndRetry(
  ///       breaker: _circuitControl,
  ///       maxRetries: 3,
  ///     );
  ///   }
  ///   // The actual raw network call
  ///   Future<String> _fetchProfileFromApi() async {
  ///     print("  -> Calling Network...");
  ///     throw Exception("Server 500");
  ///   }
  /// }
  /// // --- Simulation ---
  /// void main() async {
  ///   final repo = UserRepository();
  ///   print("--- User Click 1 ---");
  ///   try { await repo.getUserProfile(); } catch(e) { print(e); }
  ///   print("\n--- User Click 2 ---");
  ///   try { await repo.getUserProfile(); } catch(e) { print(e); }
  ///   // Now the breaker should be TRIPPED. 
  ///   // The next call won't even print "Calling Network..." 
  ///   print("\n--- User Click 3 (Should Fail Fast) ---");
  ///   try { await repo.getUserProfile(); } catch(e) { print(e); }
  /// }
  /// ```
  Future<T> withTimeoutRC({
    required CircuitBreakerController breaker, // Pass the controller here
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 10),
    Duration initialDelay = const Duration(seconds: 1),
    double backoffFactor = 2.0,
    Duration jitter = const Duration(milliseconds: 500),
    bool Function(Object error)? retryIf
  }) async {
    
    // 1. FAIL FAST: Check Circuit Breaker before doing anything
    if (breaker.isOpen) {
      throw Exception("Circuit Open: Blocked. Try again in ${breaker.remainingWait.inSeconds}s");
    }

    int attempts = 0;
    final random = Random();

    while (true) {
      attempts++;
      try {
        // 2. Attempt Operation
        final result = await this().timeout(timeout);
        
        // 3. SUCCESS: Reset the breaker
        breaker.reset();
        return result;
        
      } catch (e) {
        // 4. FAILURE processing
        if (attempts > maxRetries || (retryIf != null && !retryIf(e))) {
          // We ran out of retries. This counts as ONE major failure for the breaker.
          breaker.recordFailure();
          rethrow;
        }

        // Calculate Delay (Backoff + Jitter)
        final backoffMult = pow(backoffFactor, attempts - 1);
        final baseDelay = initialDelay * backoffMult;
        final jitterMs = jitter.inMilliseconds > 0 ? random.nextInt(jitter.inMilliseconds) : 0;
        
        await Future.delayed(baseDelay + Duration(milliseconds: jitterMs));
      }
    }
  }

}
