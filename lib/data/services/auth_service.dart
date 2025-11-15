import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/authentication_exception.dart';
import '../models/user_model.dart';
import '../repositories/i_repo_auth.dart';
import 'logging_service.dart';
import 'pref_service.dart';

/// Manages all authentication-related business logic.
///
/// This service coordinates the [IRepoAuth] (for data access)
/// and the [PrefService] (for session persistence) to perform
/// sign-in, sign-out, and session management tasks.
class AuthService {
  final IRepoAuth _authRepository;
  final PrefService _prefRepo;
  final _log = LoggerRepo('AuthService'); // Assuming LoggerRepo exists

  /// {@macro authentication_service}
  ///
  /// Requires an [IRepoAuth] and [PrefService] for its
  /// dependencies (this is called Dependency Injection).
  AuthService(this._authRepository, this._prefRepo);

  /// Gets the current [UserModel] by mapping the repository's [User].
  /// Returns `null` if no user is signed in.
  UserModel? get currentAppUser {
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser == null) return null;
    return UserModel.fromFirebaseUser(firebaseUser);
  }

  /// Exposes a stream of [AppUser?]
  ///
  /// This maps the repository's Firebase [User?] stream to your
  /// app's internal [AppUser?] model.
  Stream<UserModel?> get authStateChanges {
    return _authRepository.authStateChanges.map((firebaseUser) {
      if (firebaseUser == null) return null;
      // You could also fetch user data from Firestore here
      return UserModel.fromFirebaseUser(firebaseUser);
    });
  }
    // Refactor ActionCodeSettings into a reusable getter
  // ActionCodeSettings get _defaultActionCodeSettings {
  //   final userEmail = currentAppUser?.email;
  //   return ActionCodeSettings(
  //     url: "http://www.suefery.com/verify?email=$userEmail",
  //     iOSBundleId: "com.walidKSoft.suefery",
  //     androidPackageName: "com.walidKSoft.suefery",
  //   );
  // }
  
  
  // Future<void> _handleAuth(String? initialAuthToken) async {
  //   try {
  //     initialAuthToken ??= "";
  //     if (initialAuthToken.isNotEmpty) {
  //       // Use custom token provided by the canvas environment
  //       final userCredential = await _auth.signInWithCustomToken(initialAuthToken);
  //       _currentUserId = userCredential.user!.uid;
  //       _log.i('Signed in with Custom Token. UID: $_currentUserId');
  //     } else {
  //       // Fallback to anonymous sign-in if no token is provided
  //       final userCredential = await _auth.signInAnonymously();
  //       _currentUserId = userCredential.user!.uid;
  //       _log.i('Signed in Anonymously. UID: $_currentUserId');
  //     }
  //   } catch (e) {
  //     _log.e('ERROR: Firebase Auth failed: $e');
  //     // Use a random ID if sign-in completely fails (to maintain operation)
  //     _currentUserId = 'anonymous-${DateTime.now().millisecondsSinceEpoch}';
  //   }
  // }
  /// Reloads the user's data from the provider.
  Future<void> reloadUser() => _authRepository.reloadUser();

  /// Handles the business logic for Google Sign-In.
  Future<UserModel?> signInWithGoogle() async {
    try {
      final userCredential = await _authRepository.logInWithGoogle();
      final user = userCredential.user;

      if (user != null) {
        final bool isNewUser =
            userCredential.additionalUserInfo?.isNewUser ?? false;
        await _prefRepo.setIsFirstLogin(isNewUser);
        await _handleSuccessfulLogin(user);
        return UserModel.fromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      _log.e("Google Sign-In Error: $e");
      rethrow;
    }
  }

  /// Handles the business logic for Email/Pass Sign-Up.
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _authRepository.signUp(
        email: email,
        password: password,
      );
      final user = userCredential?.user;

      if (user != null) {
        await _prefRepo.setIsFirstLogin(true);
        await _handleSuccessfulLogin(user);
        return UserModel.fromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      _log.e("Registration Error: $e");
      rethrow;
    }
  }

  /// Handles the business logic for Email/Pass Sign-In.
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _log.i("signInWithEmailAndPassword called for user: $email");
      // Await the UserCredential first, then get the user. This is cleaner and safer.
      final userCredential = await _authRepository.logInWithEmailAndPassword(
        email: email,
        password: password,
      ); 
      
      _log.i("UserCredential received successfully.");
      final user = userCredential.user;
      
      if (user == null) return null; // Guard against a null user.

      _log.i("Handling successful login for user: ${user.email}");
      await _handleSuccessfulLogin(user);
      return UserModel.fromFirebaseUser(user);
    } on TimeoutException {
      _log.e("Login Error: Timeout. The request took too long.");
      // Re-throwing a custom, more specific exception for the UI layer.
      throw LoginEmailPassFirebaseFailure('Login timed out. Please check your network connection and try again.');
    } on FirebaseAuthException catch (e) {
      _log.e("Login Error: ${e.code} , ${e.message}");
      // --- FIX: Handle 'invalid-credential' specifically ---
      // This error often means the user signed up with a different provider (e.g., Google).
      if (e.code == 'invalid-credential') {
        throw LoginEmailPassFirebaseFailure(
          'This account might have been created using a different sign-in method. Please try signing in with Google.',
        );
      }
      throw LoginEmailPassFirebaseFailure.fromCode(e.code);
    } catch (e) {
      _log.e("Login Error: $e");
      rethrow;
    }
  }

  /// Centralized logic to run after any successful login.
  /// Saves token and login state to preferences.
  Future<void> _handleSuccessfulLogin(User user) async {
    _log.i("Entering _handleSuccessfulLogin for user: ${user.email}");
    final token = await user.getIdToken();
    if (token != null) {
      await _prefRepo.setUserAuthToken(token);
    }
    // For email/pass sign-in, they are never a "new" user in this context.
    await _prefRepo.setIsFirstLogin(false);
    await _prefRepo.setUserLoggedInTime(DateTime.now());
    await _prefRepo.setUserIsLoggedin(true);
    _log.i("Exiting _handleSuccessfulLogin for user: ${user.email}");
  }

  /// Checks if the user's session is still valid on app start.
  Future<bool> isUserLoggedIn() async {
    final bool isUserLoggedin = await _prefRepo.isUserLoggedin;
    final bool hasAuthUser = _authRepository.currentUser != null;

    if (!isUserLoggedin || !hasAuthUser) {
      _log.i('User is not logged in');
      return false;
    }

    try {
      _log.i('Trying to refresh user session...');
      await _authRepository.reloadUser();
      _log.i('User reload is successful');
      return true; // Successfully re-authenticated.
    } catch (e) {
      // Re-authentication failed (e.g., token expired, user disabled)
      _log.i('User reload failed, session is invalid: $e');
      await _clearUserSession(); // Session is invalid, clear it
      return false;
    }
  }

  /// Signs the user out and clears their session data from preferences.
  Future<bool> logOut() async {
    try {
      await _authRepository.logOut();
    } catch (e) {
      _log.e('Error during sign out: $e');
      // Still proceed to clear local session
    }
    await _clearUserSession();
    final bool isLoggedin = await _prefRepo.isUserLoggedin;
    return !isLoggedin; // Return true if logged out successfully
  }

  /// Centralized logic to clear user data from prefs.
  Future<void> _clearUserSession() async {
    await _prefRepo.setUserLoggedOffTime(DateTime.now());
    await _prefRepo.setUserIsLoggedin(false);
    await _prefRepo.setUserAuthToken(null);
  }

  /// Sends a password reset email.
  Future<void> resetPass(String email) async {
    try {
      if (email.isNotEmpty) {
        await _authRepository.sendPasswordResetEmail(email);
      }
    } on Exception catch (e) {
      _log.e('Error resetting pass: $e');
      rethrow;
    }
  }

  /// Updates the user's password using a reset code.
  Future<void> updatePass(
      {required String code, required String newPassword}) async {
    try {
      await _authRepository.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } catch (e) {
      _log.e('Error confirming pass reset: $e');
      rethrow;
    }
  }

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    try {
      await _authRepository.sendEmailVerification();
    } catch (e) {
      _log.e('Error sending verification email: $e');
      rethrow;
    }
  }

   /// Deletes the current user's account and clears their local session.
  Future<void> deleteUser() async {
    try {
      _log.i('Attempting to delete user account...');
      await _authRepository.deleteUser();
      _log.i('User account deleted successfully from provider.');
      // After successful deletion, clear all local data
      await _clearUserSession();
    } on FirebaseAuthException catch (e) {
      _log.e('Error deleting user: ${e.code} - ${e.message}');
      // A common error is 'requires-recent-login', which you can
      // handle in your UI by prompting the user to re-authenticate.
      rethrow;
    }
  }

  /// Re-authenticates the current user by prompting for their password.
  /// Use this before performing sensitive operations.
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _authRepository.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user or user email available for re-authentication.');
      }

      // Create the credential object
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Pass the credential to the repository
      await _authRepository.reauthenticateWithCredential(credential);
      _log.i('User re-authenticated successfully.');
    } catch (e) {
      _log.e('Error during password re-authentication: $e');
      rethrow;
    }
  }

  /// Re-authenticates the current user using their Google account.
  Future<void> reauthenticateWithGoogle() async {
    try {
      // 1. Ask the repository for a Google Auth Credential.
      // This moves the `GoogleSignIn` logic into the repository layer.
      final credential = await _authRepository.logInWithGoogle();
      // 2. Pass the credential to the repository's re-authentication method.
      await _authRepository.reauthenticateWithCredential(credential.credential!);
      _log.i('User re-authenticated successfully with Google.'); 
    } catch (e) {
      _log.e('Error during Google re-authentication: $e');
      rethrow;
    }
  }
}