import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:suefery/core/extensions/future_extension.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:suefery/core/utils/logger.dart';
import 'i_repo_auth.dart';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb;


import 'package:suefery/core/errors/exceptions.dart';
import 'package:suefery/core/errors/failures.dart';
import 'package:suefery/core/utils/either.dart';
import 'package:suefery/core/utils/error_handler.dart';

/// {@template authentication_repository}
/// Repository which manages user authentication.
/// {@endtemplate}
class RepoAuth with LogMixin implements IRepoAuth {
  final initialAuthToken = const String.fromEnvironment('__initial_auth_token');
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;
  final List<String> scopes = <String>[
    'https://www.googleapis.com/auth/contacts.readonly',
  ];
  static final _staticLogger = Logger('RepoAuth');

  /// Private constructor. Use the factory `AuthRepo.create()` to
  /// instantiate this class.
  RepoAuth._({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  /// Creates and initializes a new [RepoAuth] instance.
  static Future<RepoAuth> create({bool useEmulator = false}) async {
    // ... (rest of the create method remains the same)
  }

  @visibleForTesting
  bool isWeb = kIsWeb;

  // --- Interface Implementation ------------------------------------------------------------
  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<Either<Failure, void>> reloadUser({int? timeOut}) {
    return handleErrors(() async {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        // Or throw a specific exception
        throw Exception('No user to reload.');
      }
      return timeOut == null
          ? user.reload()
          : user.reload().withTimeout();
    });
  }

  @override
  Future<Either<Failure, UserCredential>> logInWithGoogle({int? timeOut}) {
    return handleErrors(() async {
      logInfo('logging in with google...');
      final googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        throw AuthException.custom(
            AuthErrorType.general, 'Google sign-in cancelled by user.');
      }
      final googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      logInfo('Sign in with Google successful.');
      return _firebaseAuth.signInWithCredential(credential).withTimeout();
    });
  }

  @override
  Future<Either<Failure, UserCredential>> signUp(
      {required String email, required String password, int? timeOut}) {
    return handleErrors(() => _firebaseAuth
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
        )
        .withTimeout());
  }

  @override
  Future<Either<Failure, UserCredential>> logInWithEmailAndPassword({
    required String email,
    required String password,
    int? timeOut,
  }) {
    return handleErrors(
      () => _firebaseAuth
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          )
          .withTimeout(duration: const Duration(seconds: 30)),
    );
  }

  @override
  Future<Either<Failure, void>> logOut({int? timeOut}) {
    return handleErrors(() async {
      await _googleSignIn.signOut().withTimeout();
      await _firebaseAuth.signOut().withTimeout();
    });
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email, {int? timeOut}) {
    return handleErrors(
        () => _firebaseAuth.sendPasswordResetEmail(email: email).withTimeout());
  }

  @override
  Future<Either<Failure, void>> confirmPasswordReset(
      {required String code, required String newPassword, int? timeOut}) {
    return handleErrors(() => _firebaseAuth
        .confirmPasswordReset(
          code: code,
          newPassword: newPassword,
        )
        .withTimeout());
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification({int? timeOut}) {
    return handleErrors(() {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.custom(
            AuthErrorType.notRegistered, 'No user signed in to verify email.');
      }
      if (user.emailVerified) {
        // This is not an error, so we just complete successfully.
        return Future.value();
      }
      return user.sendEmailVerification().withTimeout();
    });
  }

  @override
  Future<Either<Failure, String>> verifyResetCode(String code, {int? timeOut}) {
    return handleErrors(
        () => _firebaseAuth.verifyPasswordResetCode(code).withTimeout());
  }

  @override
  Future<Either<Failure, void>> deleteUser({int? timeOut}) {
    return handleErrors(() {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in to delete.');
      }
      return user.delete().withTimeout();
    });
  }

  @override
  Future<Either<Failure, void>> reauthenticateWithCredential(
      AuthCredential credential,
      {int? timeOut}) {
    return handleErrors(() {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in to re-authenticate.');
      }
      return user.reauthenticateWithCredential(credential).withTimeout();
    });
  }
}