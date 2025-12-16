import 'package:firebase_auth/firebase_auth.dart';
import 'package:suefery/core/errors/exceptions.dart';
//import 'package:firebase_storage/firebase_storage.dart';

/// Categorizes the type of storage error for UI logic
enum StorageErrorType {
  general,
  objectNotFound,
  bucketNotFound,
  projectNotFound,
  quotaExceeded,
  unauthenticated,
  unauthorized,
  retryLimitExceeded,
  invalidChecksum,
  canceled,
  unknown,
}

/// A unified exception class for all Firebase Storage failures.
class StorageException implements AppException {
  final StorageErrorType type;
  @override
  final String message;
  final String? originalCode; // The raw code from Firebase (for logging)
  @override
  final dynamic originalError; // The original exception object
  @override
  final StackTrace? stackTrace;

  const StorageException({
    required this.type,
    required this.message,
    this.originalCode,
    this.originalError,
    this.stackTrace,
  });

  /// Factory to convert Firebase Storage Exceptions into your app's domain exceptions
  factory StorageException.fromFirebase(FirebaseException e, [StackTrace? s]) {
    StorageErrorType type;
    String message;

    switch (e.code) {
      case 'object-not-found':
        type = StorageErrorType.objectNotFound;
        message = 'The file does not exist at the specified path.';
        break;
      case 'bucket-not-found':
        type = StorageErrorType.bucketNotFound;
        message = 'The storage bucket could not be found.';
        break;
      case 'project-not-found':
        type = StorageErrorType.projectNotFound;
        message = 'The Firebase project could not be found.';
        break;
      case 'quota-exceeded':
        type = StorageErrorType.quotaExceeded;
        message = 'Storage quota has been exceeded. Please upgrade your plan.';
        break;
      case 'unauthenticated':
        type = StorageErrorType.unauthenticated;
        message = 'You must be authenticated to perform this action.';
        break;
      case 'unauthorized':
        type = StorageErrorType.unauthorized;
        message = 'You do not have permission to perform this action.';
        break;
      case 'retry-limit-exceeded':
        type = StorageErrorType.retryLimitExceeded;
        message = 'The operation timed out. Please try again.';
        break;
      case 'invalid-checksum':
        type = StorageErrorType.invalidChecksum;
        message = 'File corrupted during upload. Please try again.';
        break;
      case 'canceled':
        type = StorageErrorType.canceled;
        message = 'The operation was canceled.';
        break;
      default:
        type = StorageErrorType.unknown;
        message = e.message ?? 'An unknown storage error occurred.';
    }

    return StorageException(
      type: type,
      message: message,
      originalCode: e.code,
      originalError: e,
      stackTrace: s ?? e.stackTrace,
    );
  }

  @override
  String toString() => 'StorageException(type: ${type.name}, message: $message)';
}

/*
class UploadImageFailure implements Exception{

  UploadImageFailure([
    this.message = 'An unknown exception occurred.'
  ]){
    //log.e(message);
  }
  final String message;
}
*/
