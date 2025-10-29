import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Global access point for Firebase services and environment variables.
class FirebaseService {
  late final FirebaseApp _app;
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  String _currentUserId = '';
  String _appId = 'default-app-id';

  FirebaseService._privateConstructor();
  static final FirebaseService instance = FirebaseService._privateConstructor();
  final bool useEmulator = true;

  String get userId => _currentUserId;
  FirebaseFirestore get firestore => _firestore;

  /// Retrieves the correct path for the user's private collection.
  String get userOrdersCollectionPath {
    return 'artifacts/$_appId/users/$_currentUserId/orders';
  }

  /// Manually parse the global config strings and initialize Firebase/Auth.
  Future<void> initialize() async {
    // 1. Get environment variables
    final firebaseConfigJson = const String.fromEnvironment('__firebase_config', defaultValue: '{}');
    final initialAuthToken = const String.fromEnvironment('__initial_auth_token');
    _appId = const String.fromEnvironment('__app_id', defaultValue: 'default-app-id');
    
    // Parse config
    Map<String, dynamic> configMap;
    try {
      configMap = jsonDecode(firebaseConfigJson);
    } catch (e) {
      print('ERROR: Failed to decode Firebase Config: $e');
      configMap = {};
    }

    // 2. Initialize Firebase App
    if (configMap.isNotEmpty) {
      // Use standard FirebaseOptions to initialize the app
      final options = FirebaseOptions(
        apiKey: configMap['apiKey'] as String,
        appId: configMap['appId'] as String,
        messagingSenderId: configMap['messagingSenderId'] as String,
        projectId: configMap['projectId'] as String,
        databaseURL: configMap['databaseURL'] as String?,
        storageBucket: configMap['storageBucket'] as String?,
      );
      _app = await Firebase.initializeApp(options: options);
    } else {
      // If config is missing, initialize a default app (will likely fail on API calls)
      _app = await Firebase.initializeApp();
    }
    _auth = FirebaseAuth.instanceFor(app: _app);
    _firestore = FirebaseFirestore.instanceFor(app: _app);
    if (useEmulator) {
      await _auth.useAuthEmulator('localhost' ,9099);
      _firestore.settings = const Settings(
      host: 'localhost:8080',
      sslEnabled: false,
      persistenceEnabled: false,
      );
      // await FirebaseStorage.instance.useEmulator(
      // host: 'localhost',
      // port: 9199,
      // );
    }
    // Enable offline persistence for better performance, especially on mobile
    if (!kIsWeb) {
      _firestore.settings = const Settings(persistenceEnabled: true);
    }

    // 3. Handle Authentication
    await _handleAuth(initialAuthToken);
  }

  Future<void> _handleAuth(String? initialAuthToken) async {
    try {
      initialAuthToken ??= "";
      if (initialAuthToken.isNotEmpty) {
        // Use custom token provided by the canvas environment
        final userCredential = await _auth.signInWithCustomToken(initialAuthToken!);
        _currentUserId = userCredential.user!.uid;
        debugPrint('Firebase: Signed in with Custom Token. UID: $_currentUserId');
      } else {
        // Fallback to anonymous sign-in if no token is provided
        final userCredential = await _auth.signInAnonymously();
        _currentUserId = userCredential.user!.uid;
        debugPrint('Firebase: Signed in Anonymously. UID: $_currentUserId');
      }
    } catch (e) {
      debugPrint('ERROR: Firebase Auth failed: $e');
      // Use a random ID if sign-in completely fails (to maintain operation)
      _currentUserId = 'anonymous-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
