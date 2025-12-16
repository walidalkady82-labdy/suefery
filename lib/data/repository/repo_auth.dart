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


/// {@template authentication_repository}
/// Repository which manages user authentication.
/// {@endtemplate}
class RepoAuth with LogMixin implements IRepoAuth {

  final initialAuthToken = const String.fromEnvironment('__initial_auth_token');
  final GoogleSignIn _googleSignIn;//(clientId: kIsWeb ? webClientId : null);
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
  ///
  /// If [useEmulator] is true, it will connect to the local
  /// Firebase Auth emulator on localhost:9099.
  ///
  /// Note: Emulators should only be used in debug builds.
  static Future<RepoAuth> create({bool useEmulator = false}) async {
    final firebaseAuthInstance = FirebaseAuth.instance;
    final googleSignInInstance = GoogleSignIn.instance;
    try{
      await googleSignInInstance.initialize(
        serverClientId: dotenv.env['googleSignInwebClientId'],
        clientId: kIsWeb ?  dotenv.env['googleSignInwebClientId'] : null,
      );
      unawaited(
        googleSignInInstance.initialize(
          clientId: kIsWeb ?  dotenv.env['googleSignInwebClientId'] : null, 
          serverClientId: dotenv.env['googleSignInwebClientId']).then((
          _,
        ) {
          googleSignInInstance.authenticationEvents
              .listen(
                (event) {
                  final GoogleSignInAccount? user =
                    switch (event) {
                    GoogleSignInAuthenticationEventSignIn() => event.user,
                    GoogleSignInAuthenticationEventSignOut() => null,
                  };
                  if (user == null) {
                    _staticLogger.info('User signed out');
                  } else {
                    _staticLogger.info('${user.email} User signed in');
                  }
                }
              )
              .onError(
                (Object e) {
                  final message = e is GoogleSignInException
              ? e.description : 'Unknown error: $e';
                  _staticLogger.severe(message);
                }
              );

          /// This example always uses the stream-based approach to determining
          /// which UI state to show, rather than using the future returned here,
          /// if any, to conditionally skip directly to the signed-in state.
          googleSignInInstance.attemptLightweightAuthentication();
        }),
      );
    }catch (e) {
      _staticLogger.severe("Lightweight auth failed: $e");
    }
    
    // #enddocregion Setup
    // Use emulator only in debug mode and if requested
    if (kDebugMode && useEmulator) {
      try {
        _staticLogger.info('AuthRepo: Connecting to Firebase Auth Emulator...');
        final emulatorHost =(!kIsWeb && defaultTargetPlatform == TargetPlatform.android)? dotenv.get('local_device_ip') : 'localhost';
        await firebaseAuthInstance.useAuthEmulator(emulatorHost, 9099);
        _staticLogger.info('AuthRepo: Connected to Auth Emulator on localhost:9099');
      } catch (e) {
        _staticLogger.severe('*** FAILED TO CONNECT TO AUTH EMULATOR: $e ***');
        _staticLogger.severe('*** Make sure the emulator is running: firebase emulators:start ***');
      }
    }
    // 2. Create Instance
    final repo = RepoAuth._(
      firebaseAuth: firebaseAuthInstance,
      googleSignIn: googleSignInInstance,
    );

    // 3. Initialize Google Sign-In & Listeners (Must be done on the instance)

    return repo;
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
  Future<void> reloadUser({int? timeOut}) async {
    // reload() can throw if the user's token is invalid
    try {
      timeOut == null ?
      await _firebaseAuth.currentUser?.reload()
      :
      await _firebaseAuth.currentUser?.reload().withTimeout()
      ;
    } on FirebaseAuthException catch (e) {
      logError('Failed to reload user: ${e.message}');
      // Re-throw the exception so the service can catch it
      rethrow;
    }
  }

  @override
  Future<UserCredential?> logInWithGoogle({int? timeOut}) async {
    try {
      logInfo('logging in with google...');
      // Obtain auth details
      late final GoogleSignInAccount? googleUser;
      googleUser = await _googleSignIn.authenticate();
      // Obtain auth details
      final googleAuth = googleUser.authentication;

      // Create credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: null,
      );
      logInfo('Sign in with Google successful.');
      return await _firebaseAuth.signInWithCredential(credential).withTimeout();
    } catch (e) {
      logError('Google Sign-In Error: $e');
      rethrow;
    }
  }

  @override
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    int? timeOut
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    ).withTimeout();
  }

  @override
  Future<UserCredential?> logInWithEmailAndPassword({

    required String email,
    required String password,
    int? timeOut
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    ).withTimeout(duration: Duration(seconds: 30));

  }

  @override
  Future<void> logOut({int? timeOut}) async {
    // Must sign out of both providers to ensure a clean slate
    await _googleSignIn.signOut().withTimeout();
    await _firebaseAuth.signOut().withTimeout();
  }

  @override
  Future<void> sendPasswordResetEmail(String email,{int? timeOut}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email).withTimeout();
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
    int? timeOut
  }) {
    return _firebaseAuth.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    ).withTimeout();
  }
 
  @override
  Future<void> sendEmailVerification({int? timeOut}) {
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
    return user.sendEmailVerification().withTimeout();
  }
  
  @override
  Future<String> verifyResetCode(String code,{int? timeOut}) {
    // This method returns the user's email if the code is valid
    return _firebaseAuth.verifyPasswordResetCode(code).withTimeout();
  }
  
  @override
  Future<void> deleteUser({int? timeOut}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in to delete.');
    }

    try {
      await user.delete().withTimeout();
    } on FirebaseAuthException catch (e) {
      // Re-throw the specific Firebase exception to be handled by the service/UI
      // Common codes: 'requires-recent-login'
      logError('Error deleting user: ${e.code}');
      rethrow;
    }
  }
  
  @override
  Future<void> reauthenticateWithCredential(AuthCredential credential,{int? timeOut}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in to re-authenticate.');
    }
    try {
      await user.reauthenticateWithCredential(credential).withTimeout();
    } on FirebaseAuthException catch (e) {
      // Re-throw for the service/UI to handle
      // Common codes: 'user-mismatch', 'invalid-credential', 'wrong-password'
      logError('Error re-authenticating user: ${e.code}');
      rethrow;
    }
  }
}