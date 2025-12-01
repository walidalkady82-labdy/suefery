import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:suefery/core/extensions/future_extension.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/enum/auth_status.dart';
import 'package:suefery/data/enum/user_alive_status.dart';
import 'package:suefery/data/enum/user_role.dart';
import 'package:suefery/data/model/model_user.dart';
import 'package:suefery/data/repository/i_repo_auth.dart';
import 'package:suefery/data/repository/i_repo_firestore.dart';
import '../../core/errors/authentication_exception.dart';

import 'service_pref.dart';

/// Manages all authentication-related business logic.
///
/// This service coordinates the [IRepoAuth] (for data access)
/// and the [ServicePref] (for session persistence) to perform
/// sign-in, sign-out, and session management tasks.
class ServiceAuth with LogMixin{
  final IRepoAuth _authRepository;
  final ServicePref _prefRepo;
  final IRepoFirestore _firestoreRepo;
  Timer? _keepAliveTimer; // NEW: Timer for S3 Keep-Alive
  final String _collectionPath = 'users';
  ModelUser? _currentAppUser;

  /// {@macro authentication_service}
  ///
  /// Requires an [IRepoAuth] and [ServicePref] for its
  /// dependencies (this is called Dependency Injection).
  ServiceAuth(this._authRepository,this._firestoreRepo, this._prefRepo);
  User? get currentFirebaseUser {
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser == null) return null;
    return firebaseUser;
  }
  /// Gets the current [ModelUser] by mapping the repository's [User].
  /// Returns `null` if no user is signed in.
  ModelUser? get currentAppUser => _currentAppUser;

  /// Exposes a stream of [AppUser?]
  ///
  /// This maps the repository's Firebase [User?] stream to your
  /// app's internal [AppUser?] model.
  Stream<AuthStatus> onAuthStatusChanged() {
    return _authRepository.authStateChanges.asyncMap((User? user) async {
      try {
        logInfo('onAuthStatusChanged checking user status...');
        if (user != null) {
          // User is authenticated, try to fetch their full profile from Firestore.
          logWarning('onAuthStatusChanged: User authenticated, getting user data from database');
          _currentAppUser = await getUser(user.uid);

          // --- SELF-HEALING & RECOVERY ---
          if (_currentAppUser == null) {
            logWarning('onAuthStatusChanged: User authenticated but no Firestore record. Recovering...');
            await _fetchCurrentUser().withDefaultTimeout();
            // After recovery, we MUST re-fetch the user data to proceed.
            logInfo('onAuthStatusChanged: Recovery complete.');
            _currentAppUser = await getUser(user.uid);
            if (!user.emailVerified) {
              logWarning('onAuthStatusChanged: User email is not verified.');
              return AuthStatus.awaitingVerification;
            }
          }

          // If user is still null after recovery attempt, something is wrong. Log out.
          if (_currentAppUser == null) {
            logError('onAuthStatusChanged: CRITICAL - Failed to fetch or recover user. deleting auth data.');
            await user.delete();
            await logOut();
            return AuthStatus.unauthenticated;
          }

          // --- EMAIL VERIFICATION CHECK (APPLIES TO ALL LOGGED-IN USERS) ---
          if (!user.emailVerified) {
            logWarning('onAuthStatusChanged: User email is not verified.');
            // IMPORTANT: Keep the user object populated even when awaiting verification.
            _currentAppUser = await getUser(user.uid);
            return AuthStatus.awaitingVerification;
          }

          logInfo('onAuthStatusChanged: User is authenticated and verified.');
          startKeepAlive(user.uid);
          return AuthStatus.authenticated;
        } else {
          // User is logged out, clear the cached user model.
          _currentAppUser = null;
          stopKeepAlive();
          return AuthStatus.unauthenticated;
        }
      } on TimeoutException catch (e) {
        logError('onAuthStatusChanged: Timeout: $e');
        return AuthStatus.unauthenticated;
      }
      on FirebaseAuthException catch (e) {
        logError('onAuthStatusChanged: FirebaseAuthException: $e');
        return AuthStatus.unauthenticated;
      }
       catch (e) {
        logError('Error in onAuthStatusChanged: $e');
        return AuthStatus.unauthenticated;
      }
    });
  }
  Stream<ModelUser?> get authStateChanges {
    return _authRepository.authStateChanges.map((firebaseUser) {
      if (firebaseUser == null) return null;
      // You could also fetch user data from Firestore here
      return ModelUser.fromFirebaseUser(firebaseUser);
    });
  }
      /// --- SELF-HEALING FETCH ---
  Future<void> _fetchCurrentUser() async {
    try {
      final uid = currentFirebaseUser?.uid;
      //final firebaseUser = _authService.currentUser;

      if (uid != null) {
        final userModel = await getUser(uid);
        
        if (userModel != null) {
          // Happy Path: User profile exists
          // emit(state.copyWith(authState: AuthStatus.authenticated, user: user, isLoading: false));
        } else {
          // --- EDGE CASE RECOVERY ---
          // Auth exists, but Firestore Doc is missing.
          // We recreate a "Skeleton" profile so the user isn't stuck.
          
          final recoveredUser = ModelUser(
            id: uid,
            email: currentFirebaseUser?.email ?? '',
            firstName: '', // Lost in crash, user can update in Profile later
            lastName: '',
            phone: currentFirebaseUser?.phoneNumber ?? '',
            role: UserRole.partner,
            userAliveStatus : UserAliveStatus .inactive,
            creationTimestamp: DateTime.now(),
          );

          // Save the skeleton to Firestore immediately
          await createUser(recoveredUser);

          // Update app state so AuthWrapper sees it
          // emit(state.copyWith(authState: AuthStatus.authenticated, user: recoveredUser, isLoading: false));
          
          logWarning("Recovered orphan account for user: $uid");
        }
      }
    } catch (e) {
      logError("Error fetching user: $e");
      // emit(state.copyWith(isLoading: false, errorMessage: "Failed to load profile. Please check connection."));
    }
  }
   // --- NEW: S3 (Keep-Alive) HELPER METHODS ---
  void startKeepAlive(String partnerId) {
    _keepAliveTimer?.cancel(); // Cancel any existing timer
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _updateKeepAlive(partnerId);
    });
    // Send one ping immediately on login
    _updateKeepAlive(partnerId);
  }

  void stopKeepAlive() {
    _keepAliveTimer?.cancel();
  }

  /// NEW: Pings Firestore to update 'last_seen' and 'status'
  Future<void> _updateKeepAlive(String userId) async {
    try {
      // Use an "upsert" operation (update or create) to prevent "not-found" errors.
      // This sets the document with the provided data, merging it with existing
      // data if the document already exists. If it doesn't exist, it's created.
      await _firestoreRepo.updateDocument(
        _collectionPath,
        userId,
        {
          'userAliveStatus': UserAliveStatus.active.name,
          'last_seen': DateTime.now().toIso8601String(),
        },
      );
      logInfo('Keep-Alive Ping: User $userId is online.');
    } catch (e) {
      logError('Failed to update keep-alive: $e');
    }
  }
  
  // --- END S3 HELPER METHODS ---

  /// Handles the business logic for Google Sign-In.
  Future<ModelUser?> signInWithGoogle() async {
    try {
      final userCredential = await _authRepository.logInWithGoogle();
      final user = userCredential.user;

      if (user != null) {
        final bool isNewUser =
            userCredential.additionalUserInfo?.isNewUser ?? false;
        await _prefRepo.setIsFirstLogin(isNewUser);
        await _handleSuccessfulLogin(user);
        return ModelUser.fromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      logError("Google Sign-In Error: $e");
      rethrow;
    }
  }

  /// Handles the business logic for Email/Pass Sign-Up.
  Future<ModelUser?> signUpWithEmailAndPassword({
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
        final partnerMap = {
          'id': user.uid,
          'uid': user.uid,
          'email': email,
          'storeId': user.uid,
          'userAliveStatus': UserAliveStatus.inactive.name,
          'role': UserRole.partner.name, 
          'createdAt': DateTime.now().toIso8601String(),
        };
        await _firestoreRepo.setDocument(_collectionPath, user.uid, partnerMap);
        // Cache the newly created user model.
        _currentAppUser = ModelUser.fromMap(partnerMap);

        await _handleSuccessfulLogin(user);
        await sendEmailVerification();
        return ModelUser.fromFirebaseUser(user);
      }
      return null;
    } 
    on FirebaseAuthException catch (e) {
      logError("Registration Error: $e");
      throw AuthenticationFailure(e.message ?? 'Sign-in failed');
    }
    catch (e) {
      logError("Registration Error: $e");
      rethrow;
    }
  }

  /// Handles the business logic for Email/Pass Sign-In.
  Future<ModelUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      logInfo("signInWithEmailAndPassword called for user: $email");
      // Await the UserCredential first, then get the user. This is cleaner and safer.
      final userCredential = await _authRepository.logInWithEmailAndPassword(
        email: email,
        password: password,
      ); 
      
      logInfo("UserCredential received successfully.");
      final user = userCredential.user;
      
      if (user == null) return null; // Guard against a null user.

      logInfo("Handling successful login for user: ${user.email}");
      await _handleSuccessfulLogin(user);
      return ModelUser.fromFirebaseUser(user);
    } on TimeoutException {
      logError("Login Error: Timeout. The request took too long.");
      // Re-throwing a custom, more specific exception for the UI layer.
      throw LoginEmailPassFirebaseFailure('Login timed out. Please check your network connection and try again.');
    } on FirebaseAuthException catch (e) {
      logError("Login Error: ${e.code} , ${e.message}");
      // This error often means the user signed up with a different provider (e.g., Google).
      if (e.code == 'invalid-credential') {
        throw LoginEmailPassFirebaseFailure(
          'This account might have been created using a different sign-in method. Please try signing in with Google.',
        );
      }
      throw LoginEmailPassFirebaseFailure.fromCode(e.code);
    } catch (e) {
      logError("Login Error: $e");
      rethrow;
    }
  }

  /// Centralized logic to run after any successful login.
  /// Saves token and login state to preferences.
  Future<void> _handleSuccessfulLogin(User user) async {
    logInfo("Entering _handleSuccessfulLogin for user: ${user.email}");
    final token = await user.getIdToken();
    if (token != null) {
      await _prefRepo.setUserAuthToken(token);
    }
    // For email/pass sign-in, they are never a "new" user in this context.
    logInfo("setting isFirstLogin to false for user: ${user.email}");
    await _prefRepo.setIsFirstLogin(false);
    await _prefRepo.setUserLoggedInTime(DateTime.now());
    await _prefRepo.setUserIsLoggedin(true);
    
    logInfo("Exiting _handleSuccessfulLogin for user: ${user.email}");
  }

  /// Checks if the user's session is still valid on app start.
  Future<bool> isUserLoggedIn() async {
    final bool isUserLoggedin = _prefRepo.isUserLoggedin;
    final bool hasAuthUser = _authRepository.currentUser != null;

    if (!isUserLoggedin || !hasAuthUser) {
      logInfo('User is not logged in');
      return false;
    }

    try {
      logInfo('Trying to refresh user session...');
      await _authRepository.reloadUser();
      logInfo('User reload is successful');
      return true; // Successfully re-authenticated.
    } catch (e) {
      // Re-authentication failed (e.g., token expired, user disabled)
      logInfo('User reload failed, session is invalid: $e');
      await _clearUserSession(); // Session is invalid, clear it
      return false;
    }
  }

  /// Signs the user out and clears their session data from preferences.
  Future<bool> logOut() async {
    try {
      // Check if the current user signed in with Google.
      // The IRepoAuth.logOut() should handle both Firebase and Google sign out.
      // The repository implementation should ensure it uses the correct, initialized
      // GoogleSignIn instance.
      await _authRepository.logOut();
      logInfo('User logged out from authentication provider.');
    } catch (e) {
      logError('Error during sign out: $e');
      // Even if provider logout fails, proceed to clear local session data.
    }
    await _clearUserSession();
    return !_prefRepo.isUserLoggedin; // Return true if logged out successfully
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
      logError('Error resetting pass: $e');
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
      logError('Error confirming pass reset: $e');
      rethrow;
    }
  }

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    try {
      await _authRepository.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      logError("Registration Error: $e");
      throw AuthenticationFailure(e.message ?? 'send verification email failed');
    }
  }

   /// Deletes the current user's account and clears their local session.
  Future<void> deleteUser() async {
    try {
      final userId = _authRepository.currentUser?.uid;
      if (userId == null) {
        throw Exception('No user ID available for deletion.');
      }
      logInfo('Attempting to delete user account...');
      await _authRepository.deleteUser();
      logInfo('User account deleted successfully from provider.');
      // After successful deletion, clear all local data
      _firestoreRepo.remove(_collectionPath, userId);
      await _clearUserSession();
    } on FirebaseAuthException catch (e) {
      logError('Error deleting user: ${e.code} - ${e.message}');
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
      logInfo('User re-authenticated successfully.');
    } catch (e) {
      logError('Error during password re-authentication: $e');
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
      logInfo('User re-authenticated successfully with Google.'); 
    } catch (e) {
      logError('Error during Google re-authentication: $e');
      rethrow;
    }
  }
  
  Future<void> reloadUser() async {
    try {
      logInfo('Reloading user...');
      await _authRepository.reloadUser();
    }catch (e) {
      logError('Error during reloading user: $e');
      rethrow;
    }
  }

  //firestore functions
    /// Gets a stream of a single user, converting it to an [ModelUser] model.
  Stream<ModelUser?> getUserStream(String userId) {
    return _firestoreRepo
        .getDocumentStream(_collectionPath, userId)
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      // Business Logic: Handles data conversion
      return ModelUser.fromMap(snapshot.data()!);
    });
  }

  Stream<UserAliveStatus> getPartnerStatusStream(String userId) {
    return _firestoreRepo
        .getDocumentStream(_collectionPath, userId) 
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        // Returns the status from Firestore, defaulting to offline if missing
        return UserAliveStatusExtension.fromString(data['userAliveStatus'] ?? 'inactive');
      }
      return UserAliveStatus.inactive;
    });
  }

  /// Fetches a single user by their ID.
  Future<ModelUser?> getUser(String userId) async {
    try {
      final snapshot =
          await _firestoreRepo.getDocumentSnapShot(_collectionPath, userId);
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return ModelUser.fromMap(snapshot.data()!);
    } catch (e) {
      logError('Error fetching user data: $e');
      return null;
    }
  }

  /// Creates a new user in the database from an [ModelUser] object.
  Future<void> createUser(ModelUser user) async{
    // Business Logic: Ensures a new user is created with their ID
    // and handles data conversion.
    final docId = await  _firestoreRepo.generateId(_collectionPath,id: user.id);
    return _firestoreRepo.updateDocument(
      _collectionPath,
      docId, // Use update/set to enforce the ID
      user.toMap(),
    );
  }

  /// Updates specific fields for a user.
  Future<void> updateUser(String userId, {
    
    String? name, 
    String? firstName, 
    String? lastName, 
    String? phone, 
    UserRole? role, 
    String? storeId, 
    UserAliveStatus? userAliveStatus, 
    DateTime? creationTimestamp,
    String? email , 
    String? fcmToken,
    String? storeName,
    String? address,
    String? city,
    String? bio,
    String? website,
    List<String>? tags,
    String? specificPersonaGoal,
    String? geohash,
    double? lat,
    double? lng

    }) {

    final dataToUpdate = <String, dynamic>{};

    if (name != null) dataToUpdate['name'] = name;
    if (email != null) dataToUpdate['email'] = email;
    if (fcmToken != null) dataToUpdate['fcmToken'] = fcmToken;
    if (storeName != null) dataToUpdate['storeName'] = storeName;
    if (address != null) dataToUpdate['address'] = address;
    if (city != null) dataToUpdate['city'] = city;
    if (bio != null) dataToUpdate['bio'] = bio;
    if (website != null) dataToUpdate['website'] = website;
    if (tags != null) dataToUpdate['tags'] = tags;
    if (specificPersonaGoal != null) dataToUpdate['specificPersonaGoal'] = specificPersonaGoal;
    if (geohash != null) dataToUpdate['geohash'] = geohash;
    if (lat != null) dataToUpdate['lat'] = lat;
    if (lng != null) dataToUpdate['lng'] = lng;
    if (firstName != null) dataToUpdate['firstName'] = firstName;
    if (lastName != null) dataToUpdate['lastName'] = lastName;
    if (phone != null) dataToUpdate['phone'] = phone;
    if (role != null) dataToUpdate['role'] = role.name;
    if (storeId != null) dataToUpdate['storeId'] = storeId;
    if (userAliveStatus != null) dataToUpdate['userAliveStatus'] = userAliveStatus.name;
    if (creationTimestamp != null) dataToUpdate['creationTimestamp'] = creationTimestamp.toIso8601String();

    
    
    return _firestoreRepo.updateDocument(_collectionPath, userId, dataToUpdate);
  }

  Future<void> completeSetup({
    required String storeName,
    String? bio,
    String? website,
    required String address,
    required String city,
    required List<String> tags,
    required double lat,
    required double lng,
  }) async {
    updateUser(
      currentAppUser!.id,
      storeName: storeName,
      address: address,
      city: city,
      tags: tags,
      lat: lat,
      lng: lng,
    );
  }

}