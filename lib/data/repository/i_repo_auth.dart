import 'package:firebase_auth/firebase_auth.dart';

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
  Future<void> reloadUser();

  /// Initiates the Google Sign-In flow.
  /// Returns a [UserCredential] on success.
  Future<UserCredential> logInWithGoogle();

  /// Creates a new user with the given email and password.
  /// Returns a [UserCredential] on success.
  Future<UserCredential?> signUp({
    required String email,
    required String password,
  });

  /// Signs in an existing user with email and password.
  /// Returns a [UserCredential] on success.
  Future<UserCredential> logInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs out the current user.
  Future<void> logOut();

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordResetEmail(String email);

  /// Completes the password reset flow using the code and new password.
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  });

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification();

  /// Verifies a password reset code.
  /// Returns the email associated with the code if valid.
  Future<String> verifyResetCode(String code);

  /// Deletes the currently signed-in user's account.
  /// This is a destructive and irreversible action.
  ///
  /// Throws a [FirebaseAuthException] if the user needs to
  /// re-authenticate recently.
  Future<void> deleteUser();

  /// Re-authenticates the current user with the given credential.
  ///
  /// This is required for sensitive operations like deleting an
  /// account or changing a password.
  Future<void> reauthenticateWithCredential(AuthCredential credential);


}