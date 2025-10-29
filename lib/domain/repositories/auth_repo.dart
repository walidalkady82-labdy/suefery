import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/errors/authentication_exception.dart';
import 'log_repo.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb;


/// {@template authentication_repository}
/// Repository which manages user authentication.
/// {@endtemplate}
class AuthRepo {
  /// {@macro authentication_repository}
  AuthRepo() ;
  final _log = LogRepo('AuthRepo');
  // 💡 FIX: Ensure your .env file has a key defined, e.g., 'WEB_CLIENT_ID'
  // final String webClientId = dotenv.env['WEB_CLIENT_ID']!;
  // final String serverClientId = dotenv.env['SERVER_CLIENT_ID']!;
  final googleSignIn = GoogleSignIn.instance;//(clientId: kIsWeb ? webClientId : null);
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  /// Whether or not the current environment is web
  /// Should only be overridden for testing purposes. Otherwise,
  /// defaults to [kIsWeb]
  @visibleForTesting
  bool isWeb = kIsWeb;
  
  // Refactor ActionCodeSettings into a reusable getter
  ActionCodeSettings get _defaultActionCodeSettings {
    final userEmail = firebaseAuth.currentUser?.email;
    return ActionCodeSettings(
      url: "http://www.suefery.com/verify?email=$userEmail",
      iOSBundleId: "com.walidKSoft.suefery",
      androidPackageName: "com.walidKSoft.suefery",
    );
  }

  Future<void> initEmulator() async {
    _log.i('Initializing Auth emulator...');
    const emulatorPortAuth = 9099;
    final emulatorHost =(!kIsWeb && defaultTargetPlatform == TargetPlatform.android)? '10.0.2.2': 'localhost';
    if (defaultTargetPlatform != TargetPlatform.android && kDebugMode) {
      await firebaseAuth.useAuthEmulator(emulatorHost, emulatorPortAuth);
    }
    _log.i('Done...');
  }
  
  /// Creates a new user with the provided [email] and [password].
  ///
  /// **CRITICAL:** Sends the email verification immediately after user creation.
  ///
  /// Throws a [SignUpWithEmailAndPasswordFailure] if an exception occurs.
  Future<UserCredential?> signUp({
    required String email, 
    required String password
    }) async {
    try {
      final cred = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.sendEmailVerification(_defaultActionCodeSettings);
      _log.i('User created and verification email sent.');
      return cred;
    } on FirebaseAuthException catch (e) {
      throw RegisterFirebaseFailure.fromCode(e.code);
    } catch (_) {
      throw RegisterFirebaseFailure('error in create user with email pass');
    }
  }

  /// Starts the Sign In with Google Flow.
  ///
  /// Throws a [LogInWithGoogleFailure] if an exception occurs.
  Future<UserCredential?> logInWithGoogle() async {
    try {
      _log.i('logging in with google...');
      late final AuthCredential credential;
      if (isWeb) {
        _log.i('using web log in...');
        final googleProvider = GoogleAuthProvider();
        final userCredential = await firebaseAuth.signInWithPopup(
          googleProvider,
        );
        credential = userCredential.credential!;
      } else {
        final googleUser = await googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
      }
      _log.i('Sign in with Google successful.');
      return await firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw LoginGoogleFirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw LoginGoogleFirebaseFailure('$e');
    }
  }
 
  /// Signs in with the provided [email] and [password].
  ///
  /// Throws a [LogInWithEmailAndPasswordFailure] if an exception occurs.
  Future<UserCredential> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _log.i('logging in with email pass credencials...');
      final usrCred = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    _log.i('Successfully signed in.');
    return usrCred;
    } on FirebaseAuthException catch (e) {
      throw LoginEmailPassFirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw LoginEmailPassFirebaseFailure('$e');
    }
  }

  /// Resends the verification email to the current user.
  Future<void> verify() async{
    final user = firebaseAuth.currentUser;
    await user?.sendEmailVerification(_defaultActionCodeSettings);
    _log.i('Verification email sent to ${user?.email}');
  }

  /// Signs out the current user which will emit
  /// [User.empty] from the [user] Stream.
  ///
  /// Throws a [LogOutFailure] if an exception occurs.
  Future<void> logOut() async {
    try {
      await Future.wait([
        firebaseAuth.signOut(),
        googleSignIn.signOut(),
      ]).then((value){
        _log.i('signed out');
    });
    } catch (e) {
      throw LogoutFailure('$e');
    }
  }

  /// Sends a password reset email to the provided [email].
  Future<void> sendPasswordResetEmail(String email) async {
  try {
    // Note: The actionCodeSettings here are for password reset, not verification.
    await firebaseAuth.sendPasswordResetEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        url: 'https:/suefery.firebaseapp.com/resetPassword',
      ),
    );
    _log.i('Password reset email sent!');
  } on FirebaseAuthException catch (e) {
      throw ResetPassFirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw ResetPassFirebaseFailure('$e');
    }
}

  /// Checks if the reset code is valid.
  Future<void> verifyResetCode(String code) async {
    try {
      await firebaseAuth.verifyPasswordResetCode(code);
      _log.e('Code verified, you can now reset the password.');
    } on FirebaseAuthException catch (e) {
      throw ResetPassFirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw ResetPassFirebaseFailure('$e');
    }
  }

  /// Confirms the password reset with the code and new password.
  Future<void> confirmPasswordReset({required String code,required String newPassword}) async {
    try {
      await firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      _log.i('Password reset successfully!');
    } on FirebaseAuthException catch (e) {
      throw ResetPassFirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw ResetPassFirebaseFailure('$e');
    }
  }

  /// Deletes the currently signed-in user account.
  Future<void> deleteUserAccount() async {
  try {
    _log.i('deleting user account...');
    await firebaseAuth.currentUser!.delete();
    _log.i('user account is deleted!');
  } on FirebaseAuthException catch (e) {
    _log.e(e);
    if (e.code == "requires-recent-login") {
      await _reauthenticateAndDelete();
    } else {
      throw DeleteAccountFirebaseFailure.fromCode('$e');
    }
  } catch (e) {
      throw DeleteAccountFirebaseFailure('$e');
    }
}

  Future<void> _reauthenticateAndDelete() async {
  try {
    _log.i('reauthenticating user!');
    final providerData = firebaseAuth.currentUser?.providerData.first;
    if (AppleAuthProvider().providerId == providerData!.providerId) {
      await firebaseAuth.currentUser!
          .reauthenticateWithProvider(AppleAuthProvider());
    } else if (GoogleAuthProvider().providerId == providerData.providerId) {
      await firebaseAuth.currentUser!
          .reauthenticateWithProvider(GoogleAuthProvider());
    }
    await firebaseAuth.currentUser?.delete();
    _log.i('Done...');
  } on FirebaseAuthException catch (e) {
    throw DeleteAccountFirebaseFailure.fromCode('firebase_auth_exception'); // Generic code since we don't know the exact reauth error
  } catch (e) {
    throw DeleteAccountFirebaseFailure('$e');
  }
}
}