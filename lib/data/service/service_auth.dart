import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:suefery/core/errors/database_exception.dart';
import 'package:suefery/core/extensions/future_extension.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/enum/auth_status.dart';
import 'package:suefery/data/enum/user_alive_status.dart';
import 'package:suefery/data/enum/user_role.dart';
import 'package:suefery/data/model/model_user.dart';
import 'package:suefery/data/repository/i_repo_auth.dart';
import 'package:suefery/data/repository/i_repo_firestore.dart';
import '../../core/errors/authentication_exception.dart';

import 'package:suefery/data/service/service_keep_alive.dart';
import 'package:suefery/data/service/service_pref.dart';


/// ***Summery***
/// 
/// Manages all authentication-related business logic.
///
/// This service coordinates the [IRepoAuth] (for data access)
/// and the [ServicePref] (for session persistence) to perform
/// sign-in, sign-out, and session management tasks.
/// 
class ServiceAuth with LogMixin{

  final IRepoAuth _authRepository;
  final ServicePref _prefRepo;
  final IRepoFirestore _firestoreRepo;
  final ServiceKeepAlive _keepAliveService;
  final String _collectionPath = 'users';
  ModelUser? _currentAppUser;

  ServiceAuth(this._authRepository,this._firestoreRepo, this._prefRepo,this._keepAliveService);

  User? get currentFirebaseUser => _authRepository.currentUser;
  
  /// ***Summery***
  /// 
  /// Gets the current [ModelUser] by mapping the repository's [User].
  /// 
  /// Returns `null` if no user is signed in.
  /// 
  ModelUser? get currentAppUser => _currentAppUser;

  /// ***Summery***
  /// 
  /// Exposes a stream of [AuthStatus]
  ///
  /// This maps the repository's Firebase [User] stream to your
  /// app's internal [ModelUser] model.
  /// 
  Stream<AuthStatus> onAuthStatusChanged() {
    return _authRepository.authStateChanges.asyncMap((User? user) async {
      try {
        logInfo('onAuthStatusChanged checking user status...');
        if (user != null) {
          // User is authenticated, try to fetch their full profile from Firestore.
          logWarning('onAuthStatusChanged: User authenticated, getting user data from database');
          _currentAppUser = await (() => getUser(user.uid)).withTimeoutR(
            timeout: const Duration(seconds: 5),
            retryIf: (e) => e is TimeoutException || (e is FirebaseException && e.code == 'unavailable'),
          );

          // --- SELF-HEALING & RECOVERY ---
          if (_currentAppUser == null) {
            logWarning('onAuthStatusChanged: User authenticated but no Firestore record. Recovering...');
            await _recoverOrphanUser().withTimeout();
            // After recovery, we MUST re-fetch the user data to proceed.
            logInfo('onAuthStatusChanged: Recovery complete.');
            _currentAppUser = await (() => getUser(user.uid)).withTimeoutR(
              timeout: const Duration(seconds: 5),
              retryIf: (e) => e is TimeoutException || (e is FirebaseException && e.code == 'unavailable'),
            );
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
          //_keepAliveService.startKeepAlive(user.uid);
          return AuthStatus.authenticated;
        } else {
          // User is logged out, clear the cached user model.
          _currentAppUser = null;
          //_keepAliveService.stopKeepAlive();
          return AuthStatus.unauthenticated;
        }
      }on TimeoutException {
        return AuthStatus.unauthenticated; // Keep stream alive, but report unauth
      } catch (e) {
        logError('Auth Status Error: $e');
        return AuthStatus.unauthenticated;
      }
    });
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

  /// Fetches a single user by their ID.
  Future<ModelUser?> getUser(String userId) async {
    try {
      final snapshot =
          await _firestoreRepo.getDocumentSnapShot(_collectionPath, userId).withTimeout();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return ModelUser.fromMap(snapshot.data()!);
    } catch (e) {
      throw DatabaseException.fromError(e);
    }
  }


  // Stream<ModelUser?> get authStateChanges {
  //   return _authRepository.authStateChanges.map((firebaseUser) {
  //     if (firebaseUser == null) return null;
  //     // You could also fetch user data from Firestore here
  //     return ModelUser.fromFirebaseUser(firebaseUser);
  //   });
  // }
      /// --- SELF-HEALING FETCH ---
  Future<void> _recoverOrphanUser() async {
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
   
  /// Handles the business logic for Google Sign-In.
  Future<ModelUser?> signInWithGoogle() async {
    try {
      final userCredential = await (() => _authRepository.logInWithGoogle()).withTimeoutR(
        timeout: const Duration(seconds: 10),
        retryIf: (e) => e is TimeoutException,
      );
      final user = userCredential?.user;

      if (user != null) {
        final bool isNewUser = userCredential?.additionalUserInfo?.isNewUser ?? false;
        await _prefRepo.setIsFirstLogin(isNewUser);
        await _handleSuccessfulLogin(user);
        return ModelUser.fromFirebaseUser(user);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } on TimeoutException {
      throw const AuthException(type: AuthErrorType.timeOut, message: 'Google Sign-in timed out.');
    } catch (e) {
      throw AuthException(type: AuthErrorType.general, message: e.toString());
    }
  }

  /// Creates a new user with the provided [email] and [password].
  ///
  /// Throws a [SignUpWithEmailAndPasswordFailure] if an exception occurs.
  Future<ModelUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await (() => _authRepository.signUp(
        email: email,
        password: password,
      )).withTimeoutR(
        timeout: const Duration(seconds: 10),
        retryIf: (e) => e is TimeoutException,
      );
      final user = userCredential?.user;

      if (user != null) {
        final partnerMap = {
          'id': user.uid,
          'uid': user.uid,
          'email': email,
          'storeId': user.uid,
          'userAliveStatus': UserAliveStatus.inactive.name,
          'role': UserRole.partner.name, 
          'createdAt': DateTime.now().toIso8601String(),
        };
        await _firestoreRepo.setDocument(_collectionPath, user.uid, partnerMap).withTimeout();
        // Cache the newly created user model.
        _currentAppUser = ModelUser.fromMap(partnerMap);

        await _handleSuccessfulLogin(user);
        await sendEmailVerification();
        return ModelUser.fromFirebaseUser(user);
      }
      return null;
    }on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } on TimeoutException {
      throw const AuthException(type: AuthErrorType.timeOut, message: 'Registration timed out.');
    } on DatabaseException {
      rethrow; // Pass DB errors up
    } catch (e) {
      throw AuthException(type: AuthErrorType.general, message: 'Registration failed: $e');
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
      final userCredential = await (() => _authRepository.logInWithEmailAndPassword(
        email: email,
        password: password,
      )).withTimeoutR(
        timeout: const Duration(seconds: 10),
        retryIf: (e) => e is TimeoutException,
      );
      
      logInfo("UserCredential received successfully.");
      final user = userCredential?.user;
      
      if (user == null) return null; // Guard against a null user.

      logInfo("Handling successful login for user: ${user.email}");
      await _handleSuccessfulLogin(user);
      return ModelUser.fromFirebaseUser(user);
    }on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } on TimeoutException {
      throw const AuthException(type: AuthErrorType.timeOut, message: 'Login timed out.');
    } catch (e) {
      throw AuthException(type: AuthErrorType.general, message: e.toString());
    }
  }

  /// Centralized logic to run after any successful login.
  /// Saves token and login state to preferences.
  Future<void> _handleSuccessfulLogin(User user) async {
    try {
      logInfo("Entering _handleSuccessfulLogin for user: ${user.email}");
      final token = await user.getIdToken();
      if (token != null) {
        await _prefRepo.setUserAuthToken(token).withTimeout();
      }
      // For email/pass sign-in, they are never a "new" user in this context.
      logInfo("setting isFirstLogin to false for user: ${user.email}");
      await _prefRepo.setIsFirstLogin(false).withTimeout();
      await _prefRepo.setUserLoggedInTime(DateTime.now()).withTimeout();
      await _prefRepo.setUserIsLoggedin(true).withTimeout();
      
      logInfo("Exiting _handleSuccessfulLogin for user: ${user.email}");
    }catch (e) {
          logError('Failed to save session data: $e');
    }
  }

  /// Checks if the user's session is still valid on app start.
  Future<bool> isUserLoggedIn() async {
    if (!_prefRepo.isUserLoggedin || _authRepository.currentUser == null) return false;
    try {
      await _authRepository.reloadUser().timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      await _clearUserSession();
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
      await _authRepository.logOut().withTimeout();
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
    await _prefRepo.setUserLoggedOffTime(DateTime.now()).withTimeout();
    await _prefRepo.setUserIsLoggedin(false).withTimeout();
    await _prefRepo.setUserAuthToken(null).withTimeout();
  }

  /// Sends a password reset email.
  Future<void> resetPass(String email) async {
    try {
      if (email.isNotEmpty) {
        await _authRepository.sendPasswordResetEmail(email).withTimeout();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException(type: AuthErrorType.general, message: 'Reset pass failed: $e');
    }
  }

  /// Updates the user's password using a reset code.
  Future<void> updatePass(
      {required String code, required String newPassword}) async {
    try {
      await _authRepository.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      ).withTimeout();
    } catch (e) {
      logError('Error confirming pass reset: $e');
      rethrow;
    }
  }

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    try {
      await _authRepository.sendEmailVerification().withTimeout();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException(type: AuthErrorType.general, message: 'Email verification failed: $e');
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
      await _authRepository.deleteUser().withTimeout();
      logInfo('User account deleted successfully from provider.');
      // After successful deletion, clear all local data
      _firestoreRepo.remove(_collectionPath, userId).withTimeout();
      await _clearUserSession();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException(type: AuthErrorType.general, message: 'Delete account failed: $e');
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
      await _authRepository.reauthenticateWithCredential(credential).withTimeout();
      logInfo('User re-authenticated successfully.');
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException(type: AuthErrorType.general, message: 'Re-authentication failed: $e');
    }
  }

  /// Re-authenticates the current user using their Google account.
  Future<void> reauthenticateWithGoogle() async {
    try {
      // 1. Ask the repository for a Google Auth Credential.
      // This moves the `GoogleSignIn` logic into the repository layer.
      final credential = await _authRepository.logInWithGoogle();
      // 2. Pass the credential to the repository's re-authentication method.
      if(credential != null) {
        await _authRepository.reauthenticateWithCredential(credential.credential!).withTimeout();
        logInfo('User re-authenticated successfully with Google.');
      }else{
        logInfo('No credential available for re-authentication.');
        throw Exception('No credential available for re-authentication.');
      }
       
    } catch (e) {
      logError('Error during Google re-authentication: $e');
      rethrow;
    }
  }
  
  Future<void> reloadUser() async {
    try {
      logInfo('Reloading user...');
      await _authRepository.reloadUser().withTimeout();
    }catch (e) {
      logError('Error during reloading user: $e');
      rethrow;
    }
  }

  /// Creates a new user in the database from an [ModelUser] object.
  Future<void> createUser(ModelUser user) async{
    // Business Logic: Ensures a new user is created with their ID
    // and handles data conversion.
    try {
      final docId = await  _firestoreRepo.generateId(_collectionPath,id: user.id);
      return _firestoreRepo.updateDocument(
        _collectionPath,
        docId, // Use update/set to enforce the ID
        user.toMap(),
      ).withTimeout();
    } catch (e) {
          throw DatabaseException.fromError(e);
    }
    
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

    }) async {

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

    
    try {
      await _firestoreRepo.updateDocument(_collectionPath, userId, dataToUpdate)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw DatabaseException.fromError(e);
    }
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