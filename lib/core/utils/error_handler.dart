import 'dart:async';
import 'dart:io';

import 'package:suefery/core/errors/authentication_exception.dart';
import 'package:suefery/core/errors/database_exception.dart';
import 'package:suefery/core/errors/exceptions.dart';
import 'package:suefery/core/errors/failures.dart';
import 'package:suefery/core/errors/storage_exception.dart';
import 'package:suefery/core/utils/either.dart';

/// A reusable helper function to wrap repository calls.
///
/// It executes a given [action] and handles the conversion of thrown [Exception]s
/// into a [Failure] object. This centralizes error handling logic and removes
/// repetitive try/catch blocks from repository implementations.
///
/// The [action] is a function that returns a Future of the expected successful result.
///
/// Returns a `Future<Either<Failure, T>>`, where `T` is the success type.
/// - `Left<Failure>`: If any exception is caught.
/// - `Right<T>`: If the action completes successfully.
Future<Either<Failure, T>> handleErrors<T>(Future<T> Function() action) async {
  try {
    final result = await action();
    return Right(result);
  } on AuthException catch (e) {
    return Left(Failure(
      type: FailureType.authentication,
      message: e.message,
      originalError: e,
    ));
  } on DatabaseException catch (e) {
    return Left(Failure(
      type: FailureType.database,
      message: e.message,
      originalError: e,
    ));
  } on StorageException catch (e) {
    return Left(Failure(
      type: FailureType.storage,
      message: e.message,
      originalError: e,
    ));
  } on SocketException catch (e) {
    return Left(Failure(
      type: FailureType.network,
      message: 'No internet connection. Please check your network settings.',
      originalError: e,
    ));
  } on TimeoutException catch (e) {
     return Left(Failure(
      type: FailureType.network,
      message: 'The connection timed out. Please try again.',
      originalError: e,
    ));
  }
  // Catching any other AppException that might have been missed.
  on AppException catch (e) {
     return Left(Failure(
      type: FailureType.server,
      message: e.message,
      originalError: e,
    ));
  }
  // Generic catch-all for truly unexpected errors.
  catch (e) {
    return Left(Failure(
      type: FailureType.unexpected,
      message: 'An unexpected error occurred. Please try again.',
      originalError: e,
    ));
  }
}
