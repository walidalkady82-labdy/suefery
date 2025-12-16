import 'package:firebase_auth/firebase_auth.dart';
import 'package:suefery/core/errors/failures.dart';
import 'package:suefery/core/utils/either.dart';

/// The abstract interface for the Authentication Repository.
/// This contract defines all methods related to interacting with the
/// authentication provider (e.g., Firebase).
abstract class IRepoAuth {
  /// Emits the current Firebase user when the auth state changes.
  /// Emits `null` if the user signs out.
  Stream<User?> get authStateChanges;

  /// Gets the currently signed-in Firebase user, if any.
  User? get currentUser;

  /// Attempts to reload the current user's data from Firebase.
  Future<Either<Failure, void>> reloadUser({int? timeOut});

  /// Initiates the Google Sign-In flow.
  /// Returns a [UserCredential] on success.
  Future<Either<Failure, UserCredential>> logInWithGoogle({int? timeOut});

  /// Creates a new user with the given email and password.
  /// Returns a [UserCredential] on success.
  Future<Either<Failure, UserCredential>> signUp({
    required String email,
    required String password,
    int? timeOut,
  });

  /// Signs in an existing user with email and password.
  /// Returns a [UserCredential] on success.
  Future<Either<Failure, UserCredential>> logInWithEmailAndPassword({
    required String email,
    required String password,
    int? timeOut,
  });

  /// Signs out the current user.
  Future<Either<Failure, void>> logOut({int? timeOut});

  /// Sends a password reset email to the given address.
  Future<Either<Failure, void>> sendPasswordResetEmail(String email, {int? timeOut});

  /// Completes the password reset flow using the code and new password.
  Future<Either<Failure, void>> confirmPasswordReset({
    required String code,
    required String newPassword,
    int? timeOut,
  });

  /// Sends a verification email to the current user.
  Future<Either<Failure, void>> sendEmailVerification({int? timeOut});

  /// Verifies a password reset code.
  /// Returns the email associated with the code if valid.
  Future<Either<Failure, String>> verifyResetCode(String code, {int? timeOut});

  /// Deletes the currently signed-in user's account.
  /// This is a destructive and irreversible action.
  Future<void> deleteUser({int? timeOut});

  /// Re-authenticates the current user with the given credential.
  Future<Either<Failure, void>> reauthenticateWithCredential(
      AuthCredential credential,
      {int? timeOut});


}