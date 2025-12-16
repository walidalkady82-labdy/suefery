import 'package:suefery/core/errors/exceptions.dart';

/// Categorizes the type of database/business-logic error
enum DatabaseErrorType {
  general,
  
  // User/Role
  userCreationFailed,
  noUserData,
  noUserRole,
  wrongUserRole,
  
  // Workplace/Collections
  noWorkplace,
  workplaceNotFound,
  workplaceCreationFailed,
  alreadyJoinedWorkplace,
  collectionPathNotFound,
  
  // Invitations
  invitationCodeInvalid,
  invitationDataInvalid,
  invitationExpired,
  
  // Permission/Data
  permissionDenied,
  notFound,
}

/// A unified exception class for all Database/Firestore failures.
/// 
/// Instead of creating 20 different classes, use this single class with the [DatabaseErrorType] enum.
class DatabaseException implements AppException {
  final DatabaseErrorType type;
  @override
  final String message;
  @override
  final dynamic originalError;
  @override
  final StackTrace? stackTrace;

  const DatabaseException({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  /// Factory to convert raw errors (like from Firestore) into DatabaseException
  factory DatabaseException.fromError(dynamic e, [StackTrace? s]) {
    // If it's already one of our exceptions, pass it through
    if (e is DatabaseException) return e;

    // Handle string errors (common in older code)
    if (e is String) {
      return DatabaseException(
        type: DatabaseErrorType.general,
        message: e,
        stackTrace: s,
      );
    }
    
    // Check for Firebase Firestore specific errors
    // (You can add specific checks here if you import cloud_firestore)
    if (e.toString().contains('permission-denied')) {
       return DatabaseException(
        type: DatabaseErrorType.permissionDenied, 
        message: 'You do not have permission to perform this action.',
        originalError: e,
        stackTrace: s
      );
    }

    return DatabaseException(
      type: DatabaseErrorType.general,
      message: e.toString(), // Fallback
      originalError: e,
      stackTrace: s,
    );
  }

  /// Use this factory when throwing specific business logic errors manually
  factory DatabaseException.type(DatabaseErrorType type, [String? customMessage]) {
    String defaultMessage;
    
    switch (type) {
      case DatabaseErrorType.userCreationFailed:
        defaultMessage = 'Could not create user profile.';
        break;
      case DatabaseErrorType.noUserData:
        defaultMessage = 'User data not found. Please register first.';
        break;
      case DatabaseErrorType.noUserRole:
        defaultMessage = 'User role is not set.';
        break;
      case DatabaseErrorType.wrongUserRole:
        defaultMessage = 'You do not have the correct role for this action.';
        break;
      case DatabaseErrorType.workplaceNotFound:
        defaultMessage = 'Workplace not found.';
        break;
      case DatabaseErrorType.alreadyJoinedWorkplace:
        defaultMessage = 'You have already joined a workplace.';
        break;
      case DatabaseErrorType.invitationExpired:
        defaultMessage = 'This invitation code has expired.';
        break;
      case DatabaseErrorType.invitationCodeInvalid:
        defaultMessage = 'Invalid invitation code.';
        break;
      default:
        defaultMessage = 'A database error occurred.';
    }

    return DatabaseException(
      type: type,
      message: customMessage ?? defaultMessage,
    );
  }

  @override
  String toString() => 'DatabaseException(type: ${type.name}, message: $message)';
}