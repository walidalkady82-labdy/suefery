import 'package:suefery/core/errors/exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Categorizes the type of authentication error for UI logic
enum AuthErrorType {
  // Custom
  general,
  noCredentials,
  notRegistered,
  
  // Firebase - Register
  invalidEmail,
  emailAlreadyInUse,
  weakPassword,
  operationNotAllowed,
  
  // Firebase - Login
  userNotFound,
  wrongPassword,
  userDisabled,
  tooManyRequests, // Good for handling rate limiting
  invalidCredential,
  
  // Firebase - Reset Password
  invalidActionCode,
  networkRequestFailed,
  timeOut
}

/// ***Summery***
/// 
/// A unified exception class for all Authentication failures.
/// 
/// Usage:
/// 
/// ```dart
/// try {
///   await auth.signIn(...);
/// } on FirebaseAuthException catch (e) {
///   throw AuthException.fromFirebase(e);
/// }
/// ```
class AuthException implements AppException {
  final AuthErrorType type;
  @override
  final String message;
  final String? originalCode; // The raw code from Firebase (for logging)
  @override
  final dynamic originalError; // The original exception object (for Crashlytics)
  @override
  final StackTrace? stackTrace;

  const AuthException({
    required this.type,
    required this.message,
    this.originalCode,
    this.originalError,
    this.stackTrace,
  });

  /// Factory to convert Firebase Auth Exceptions into your app's domain exceptions
  factory AuthException.fromFirebase(FirebaseAuthException e, [StackTrace? s]) {
    AuthErrorType type;
    String message;

    switch (e.code) {
      // --- Register ---
      case 'invalid-email':
        type = AuthErrorType.invalidEmail;
        message = 'The email address is not valid.';
        break;
      case 'email-already-in-use':
        type = AuthErrorType.emailAlreadyInUse;
        message = 'An account already exists for that email.';
        break;
      case 'weak-password':
        type = AuthErrorType.weakPassword;
        message = 'The password is too weak. Please use a stronger one.';
        break;
      case 'operation-not-allowed':
        type = AuthErrorType.operationNotAllowed;
        message = 'This sign-in method is currently disabled.';
        break;

      // --- Login ---
      case 'user-not-found':
        type = AuthErrorType.userNotFound;
        message = 'No user found for this email. Please register first.';
        break;
      case 'wrong-password':
        type = AuthErrorType.wrongPassword;
        message = 'Incorrect password. Please try again.';
        break;
      case 'user-disabled':
        type = AuthErrorType.userDisabled;
        message = 'This user account has been disabled.';
        break;
      case 'too-many-requests':
        type = AuthErrorType.tooManyRequests;
        message = 'Too many attempts. Please try again later.';
        break;
      case 'invalid-credential':
        type = AuthErrorType.invalidCredential;
        message = 'Invalid credentials provided.';
        break;

      // --- Reset Password ---
      case 'invalid-action-code':
        type = AuthErrorType.invalidActionCode;
        message = 'The password reset link is invalid or expired.';
        break;
      case 'network-request-failed':
        type = AuthErrorType.networkRequestFailed;
        message = 'Connection failed. Please check your internet.';
        break;
      default:
        type = AuthErrorType.general;
        message = e.message ?? 'An unknown authentication error occurred.';
    }

    return AuthException(
      type: type,
      message: message,
      originalCode: e.code,
      originalError: e,
      stackTrace: s ?? e.stackTrace,
    );
  }

  /// Factory for custom app-specific auth errors
  factory AuthException.custom(AuthErrorType type, [String? customMessage]) {
    String message;
    switch (type) {
      case AuthErrorType.noCredentials:
        message = 'Registration unsuccessful: No credentials available.';
        break;
      case AuthErrorType.notRegistered:
        message = 'You are not logged in. Please register first.';
        break;
      default:
        message = customMessage ?? 'An authentication error occurred.';
    }
    
    return AuthException(
      type: type,
      message: message,
    );
  }

  @override
  String toString() => 'AuthException(type: ${type.name}, message: $message)';
}