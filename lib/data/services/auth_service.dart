import 'package:firebase_auth/firebase_auth.dart';
import 'package:suefery/data/models/app_user.dart';
import 'package:suefery/domain/repositories/auth_repo.dart';
import '../enums/auth_status.dart';
import 'logging_service.dart';
import 'preferences_service.dart';


class AuthService  {
  /// {@macro authentication_service}
  /// 
  AuthService(this.prefs,{this.withEmulator = false}) ;
    
  late final AuthRepo _firebaseAuth = withEmulator?(AuthRepo()..initEmulator()):AuthRepo();
  final _log = LoggerReprository('AuthenticationService');
  final bool withEmulator;
  final PrefsService prefs;
  
  User? get currentAuthUser {
    return _firebaseAuth.firebaseAuth.currentUser;
  }

  AuthStatus get userAuthStatus {
    if(_firebaseAuth.firebaseAuth.currentUser !=null || _firebaseAuth.firebaseAuth.currentUser !=null){
      return AuthStatus.authenticated;
    }else{
      return AuthStatus.unauthenticated;
    }
  }
  /// Exposes the real-time stream of the user's authentication state.
  /// This is the standard method used in Flutter Firebase apps.
  Stream<AppUser?> get authStateChanges {
    return FirebaseAuth.instance.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return AppUser(
        id: firebaseUser.uid, 
        name: firebaseUser.displayName??"", 
        email:firebaseUser.email??"", 
        specificPersonaGoal: ''
        );
    });
  }

  Future<void> reloadeUser() async {
    await _firebaseAuth.firebaseAuth.currentUser?.reload();
  }

  Future<User?> signInWithGoogle() async {
    try {
      UserCredential? userCredential;
      userCredential = await _firebaseAuth.logInWithGoogle();
      if(userCredential?.user != null) {
        if (userCredential?.user != null) {
          final token = await userCredential!.user?.getIdToken(); // Get Firebase ID token
          if (token !=null) {
            await prefs.setUserAuthToken(token);  //await prefs.writeSecure(key: 'authToken', value: token);
          }
          await prefs.setUserLoggedInTime(DateTime.now());
          await prefs.setUserIsLoggedin(true);
        }
        final bool isNewUser = userCredential?.additionalUserInfo?.isNewUser ?? false;
        await prefs.setIsFirstLogin(isNewUser);
        await _handleSuccessfulLogin(await userCredential?.user?.getIdToken());
        return userCredential!.user;
      } else {
        return null;
      }
    } catch (e) {
      _log.e("Login Error: $e");
      rethrow;
    }
  }

  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signUp(
        email: email,
        password: password,
      );
      if (userCredential?.user != null) {
        await prefs.setIsFirstLogin(true);
        await _handleSuccessfulLogin(await userCredential?.user?.getIdToken());
        return userCredential?.user;
      }
      return null;
    } catch (e) {
      _log.e("Registration Error: $e");
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.logInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // For email/pass sign-in, they are never a "new" user in this context.
        await prefs.setIsFirstLogin(false);
        await _handleSuccessfulLogin(await userCredential.user?.getIdToken());
        return userCredential.user;
      } else {
        return null;
      }
    } catch (e) {
      _log.e("Login Error: $e");
      rethrow;
    }
  }
  
  Future<void> _handleSuccessfulLogin(String? token) async {
    if (token != null) {
      await prefs.setUserAuthToken(token);
    }
    await prefs.setUserLoggedInTime(DateTime.now());
    await prefs.setUserIsLoggedin(true);
  }

  Future<bool> isUserLoggedIn() async {                  // Check login status at startup
   // Check login status at startup
    final token = prefs.userAuthToken ;// await prefs.read('authToken');
    final bool isUserLoggedin = await prefs.isUserLoggedin;
    final bool hasAuthUser = currentAuthUser != null;
    if (!isUserLoggedin || !hasAuthUser) {
      // No token, no login.
      _log.i('User is not logged in');
      return false;
    }
    try {
      // Attempt to re-authenticate.
      _log.i('trying to log in...');
      await _firebaseAuth.firebaseAuth.currentUser?.reload();
      _log.i('User reload is successfull');
      return true; // Successfully re-authenticated.
    } catch (e) {
      // Re-authentication failed.
      _log.i('User reload failed, $e');
      prefs.setUserIsLoggedin(false); // Reset the state of user loggedin
      prefs.setUserAuthToken(null); //await prefs.deleteSecure('authToken');
      return false;
    }
  }

  Future<bool> logOut()async {
    final token = prefs.userAuthToken;//await prefs.readSecure('authToken');
    await prefs.setUserLoggedOffTime(DateTime.now());
    await prefs.setUserIsLoggedin(false);
    await _firebaseAuth.logOut();
    return prefs.isUserLoggedin ; 
  }

  Future<void> resetPass(String email) async{
    try {
      if(email.isNotEmpty){
        await _firebaseAuth.sendPasswordResetEmail(email);
      }
    } on Exception catch (e) {
      _log.e('Error reseting pass: $e');
      rethrow;
    }
  }

  Future<void> updatePass({required String code,required String newPassword}) async{
    try {
    await _firebaseAuth.verifyResetCode(code);
    await _firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    }
    catch (e) {
            _log.e('Error creating user by admin: $e');
            rethrow;
    }  
  }
  
  //TODO check

  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final User? currentUser = FirebaseAuth.instance.currentUser;


  //   /// Handles Firebase initialization and initial sign-in logic.
  // void _initializeFirebase() async {
  //   // 1. Initialize Firebase App (using __firebase_config)
  //   // In a real app: 
  //   // try {
  //   //   await Firebase.initializeApp(options: firebaseConfig);
  //   // } catch (e) {
  //   //   print("Firebase Init Error: $e");
  //   // }
    
  //   // 2. Handle Authentication using the provided custom token (if available)
  //   if (__initial_auth_token.isNotEmpty && __initial_auth_token != 'real-token-if-present') {
  //     // In a real app: 
  //     // await _auth.signInWithCustomToken(__initial_auth_token);
  //     _log.i('AuthService: Signed in using environment custom token.');
  //   } else {
  //     // In a real app, you might fall back to anonymous sign-in or a login screen
  //     // await _auth.signInAnonymously();
  //     _log.i('AuthService: Ready. Awaiting auth state changes.');
  //   }
  // }

  // /// Exposes the real-time stream of the user's authentication state.
  // /// This is the standard method used in Flutter Firebase apps.
  // Stream<User?> get authStateChanges {
  //   // In a real app: return FirebaseAuth.instance.authStateChanges().map((firebaseUser) {
  //   //   if (firebaseUser == null) return null;
  //   //   return User(firebaseUser.uid, firebaseUser.email);
  //   // });
    
  //   // Placeholder stream to demonstrate the BLoC listening flow:
  //   return Stream.fromFutures([
  //     Future.value(null), // Initial unauthenticated state
  //     Future.delayed(const Duration(seconds: 2), () => User('prod-user-123', 'user@prodapp.com')),
  //     Future.delayed(const Duration(seconds: 5), () => null), // Simulate sign out
  //   ]);
  // }

  // /// Dispatches a sign out command to Firebase.
  // Future<void> signOut() async {
  //   // In a real app: await FirebaseAuth.instance.signOut();
  //   _log.i('AuthService: Dispatched Firebase sign-out.');
  // }
}


