import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/repositories/i_auth_repo.dart';
import 'log_repo.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb;


/// {@template authentication_repository}
/// Repository which manages user authentication.
/// {@endtemplate}
class AuthRepo implements IAuthRepo{
  // 💡 FIX: Ensure your .env file has a key defined, e.g., 'WEB_CLIENT_ID'
  // final String webClientId = dotenv.env['WEB_CLIENT_ID']!;
  // final String serverClientId = dotenv.env['SERVER_CLIENT_ID']!;
  final _log = LogRepo('AuthRepo');
  final initialAuthToken = const String.fromEnvironment('__initial_auth_token');
  final GoogleSignIn _googleSignIn;//(clientId: kIsWeb ? webClientId : null);
  final FirebaseAuth _firebaseAuth;

  /// Private constructor. Use the factory `AuthRepo.create()` to
  /// instantiate this class.
  AuthRepo._({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;
  /// Creates and initializes a new [AuthRepo] instance.
  ///
  /// If [useEmulator] is true, it will connect to the local
  /// Firebase Auth emulator on localhost:9099.
  ///
  /// Note: Emulators should only be used in debug builds.
  factory AuthRepo.create({bool useEmulator = false}) {
    final instance = FirebaseAuth.instance;
    final googleSignIn = GoogleSignIn.instance;
    final log = LogRepo('AuthRepo');
    // Use emulator only in debug mode and if requested
    if (kDebugMode && useEmulator) {
      try {
        log.i('AuthRepo: Connecting to Firebase Auth Emulator...');
        final emulatorHost =(!kIsWeb && defaultTargetPlatform == TargetPlatform.android)? '10.0.2.2': 'localhost';
        instance.useAuthEmulator(emulatorHost, 9099);
        log.i('AuthRepo: Connected to Auth Emulator on localhost:9099');
      } catch (e) {
        log.e('*** FAILED TO CONNECT TO AUTH EMULATOR: $e ***');
        log.e(
            '*** Make sure the emulator is running: firebase emulators:start ***');
      }
    }
    return AuthRepo._(
      firebaseAuth: instance,
      googleSignIn: googleSignIn,
    );
  }

  
  /// Whether or not the current environment is web
  /// Should only be overridden for testing purposes. Otherwise,
  /// defaults to [kIsWeb]
  @visibleForTesting
  bool isWeb = kIsWeb;
   
  // --- Interface Implementation ------------------------------------------------------------
  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> reloadUser() async {
    // reload() can throw if the user's token is invalid
    try {
      await _firebaseAuth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      _log.e('Failed to reload user: ${e.message}');
      // Re-throw the exception so the service can catch it
      rethrow;
    }
  }

  @override
  Future<UserCredential> logInWithGoogle() async {
    try {
      _log.i('logging in with google...');
      late final AuthCredential credential;
      if (isWeb) {
        _log.i('using web log in...');
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _firebaseAuth.signInWithPopup(
          googleProvider,
        );
        credential = userCredential.credential!;
      } else {
        final googleUser = await _googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
      }
      _log.i('Sign in with Google successful.');
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      _log.e('Google Sign-In Error: $e');
      rethrow;
    }
  }

  @override
  Future<UserCredential?> signUp({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> logOut() async {
    // Must sign out of both providers to ensure a clean slate
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) {
    return _firebaseAuth.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );
  }
 
  @override
  Future<void> sendEmailVerification() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user signed in to verify email.',
      );
    }
    if (user.emailVerified) {
      debugPrint('Email is already verified.');
      // You might want to throw an exception or just return
      // depending on your business logic
      return Future.value();
    }
    return user.sendEmailVerification();
  }
  
  @override
  Future<String> verifyResetCode(String code) {
    // This method returns the user's email if the code is valid
    return _firebaseAuth.verifyPasswordResetCode(code);
  }
  
  @override
  Future<void> deleteUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in to delete.');
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      // Re-throw the specific Firebase exception to be handled by the service/UI
      // Common codes: 'requires-recent-login'
      _log.e('Error deleting user: ${e.code}');
      rethrow;
    }
  }
  
  @override
  Future<void> reauthenticateWithCredential(AuthCredential credential) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in to re-authenticate.');
    }
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // Re-throw for the service/UI to handle
      // Common codes: 'user-mismatch', 'invalid-credential', 'wrong-password'
      _log.e('Error re-authenticating user: ${e.code}');
      rethrow;
    }
  }
}