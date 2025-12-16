import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/enum/auth_status.dart';
import 'package:suefery/data/enum/user_alive_status.dart';
import 'package:suefery/data/enum/user_role.dart';
import 'package:suefery/data/model/model_user.dart';
import 'package:suefery/data/service/service_auth.dart';
import 'package:suefery/locator.dart';



class StateAuth {
  final bool isLoading;
  final String errorMessage;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final String phone;
  final AutovalidateMode autovalidateMode;
  final bool obscureText;
  final bool isLogin;
  final AuthStatus authState;
  final ModelUser? user;
  
  const StateAuth({
    this.isLoading = false,
    this.errorMessage = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.phone = '',
    this.autovalidateMode = AutovalidateMode.disabled,
    this.obscureText = true,
    this.isLogin = true,
    this.authState = AuthStatus.inProgress,
    this.user,
    });
  StateAuth copyWith({
    bool? isLoading,
    String? errorMessage,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? confirmPassword,
    String? phone,
    AutovalidateMode? autovalidateMode,
    bool? obscureText,
    bool? isLogin,
    AuthStatus? authState,
    ModelUser? user,
  }) {
    return StateAuth(
      isLoading: isLoading ?? this.isLoading,      
      errorMessage: errorMessage ?? this.errorMessage, 
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      phone: phone ?? this.phone,
      autovalidateMode: autovalidateMode ?? this.autovalidateMode,
      obscureText: obscureText ?? this.obscureText,
      isLogin: isLogin ?? this.isLogin,
      authState: authState ?? this.authState,
      user: user ?? this.user,
    );
  }

}

class CubitAuth extends Cubit<StateAuth> with LogMixin {

  final ServiceAuth _authService = sl<ServiceAuth>();
  late StreamSubscription<AuthStatus> _authStatusSubscription;

  late final StreamSubscription<ModelUser?> authSubscription;
  User? get currentFirebaseUser => _authService.currentFirebaseUser;
  ModelUser? get currentDbUser => _authService.currentAppUser;

  CubitAuth() : super(StateAuth()) {
    _authStatusSubscription =
        _authService.onAuthStatusChanged().listen((authStatus) async {
      if (authStatus == AuthStatus.authenticated) {
        logInfo('onAuthStatusChanged: user is authenticated, checking user role');
        await _checkUserRole();
      } else {
        emit(state.copyWith(authState: authStatus, user: null));
      }
    });
  }

  Future<void> _checkUserRole() async {
    logInfo('Checking user role...');
    emit(state.copyWith(
      isLoading: true,
      errorMessage: '',
    ));
    logInfo('Current Firebase User: ${currentFirebaseUser?.uid}');
    if (currentFirebaseUser == null) {
      logInfo('user is null');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'User not found. Please contact support.',
        ),
      );
      return;
    }

    try {
      if (currentDbUser != null) {
        if (currentDbUser?.role == UserRole.partner) {
          emit(
            state.copyWith(
              isLoading: false,
              authState: AuthStatus.authenticated,
              user: currentDbUser,
            )
          );
        } else {
          // Not a partner, log them out
          await _authService.logOut();
          emit(
            state.copyWith(
            isLoading: false,
            errorMessage: 'This app is for partners only.', authState: AuthStatus.unauthenticated
          ));
        }
      } else {
        // User document doesn't exist, log them out
          emit(state.copyWith(
                        isLoading: false,
                        errorMessage: 'User not found. Please contact support.', authState: AuthStatus.unauthenticated
                    ));
      }
    } catch (e) {
      emit(state.copyWith(
            isLoading: false,
            errorMessage:
        e.toString()
      ));
    }
  }

  // void _onAuthStateChanged(UserModel? user) {
  //   if (user != null) {
  //     emit(state.copyWith(authState: AuthStatus.authenticated, user: user));
  //   } else {
  //     emit(state.copyWith(authState: AuthStatus.authenticated, user: null));
  //   }
  //}

  void updateLoadingState(bool loadingState){
    emit(state.copyWith(isLoading: loadingState));
  }

  void updateFirsttName(String? firstName) {
    emit(state.copyWith(firstName: firstName));
  }

  void updateLastName(String? lastName) {
    emit(state.copyWith(lastName: lastName));
  }

  void updateEmail(String? email) {
    emit(state.copyWith(email: email));
  }

  void updatePhone(String? phone) {
    emit(state.copyWith(phone: phone));
  }

  void updatePassword(String? password) {
    emit(state.copyWith(password: password));
  }

  void updateConfirmPassword(String? confirmPassword) {
    emit(state.copyWith(confirmPassword: confirmPassword));
  }

  void updateAutovalidateMode(AutovalidateMode? autovalidateMode) {
    emit(state.copyWith(autovalidateMode: autovalidateMode));
  }

  void toggleObscureText() {
    final currentFormState = state;
    emit(currentFormState.copyWith(obscureText: !currentFormState.obscureText));
  }

  void reset() {
    emit(const StateAuth());
  }

  void togglePage() {
    final currentFormState = state;
    emit(currentFormState.copyWith(isLogin: !currentFormState.isLogin));
  }

  Future<void> signIn() async {
    final formState = state;
    emit(formState.copyWith(isLoading: true, errorMessage: ''));

    try {
      await _authService.signInWithEmailAndPassword(
        email: formState.email.trim(),
        password: formState.password,
      );
      // On success, the auth stream will emit Authenticated state.
    } catch (e) {
      final errorMessage = e.toString();
      logError('Login Failed: $errorMessage');
      emit(state.copyWith(errorMessage: errorMessage, isLoading: false));
      
      // Optional: Reset error after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (state.authState== AuthStatus.unauthenticated && state.errorMessage == errorMessage) {
          emit(state.copyWith(errorMessage: ''));
        }
      });
    } finally {
      // Ensure loading is always turned off if the state is still Unauthenticated
      if (state.authState== AuthStatus.unauthenticated) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }
  
  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      await _authService.signInWithGoogle();
      // On success, the auth stream will emit Authenticated state.
    } catch (e) {
      final errorMessage = e.toString();
      logError('Google Login Failed: $errorMessage');
      emit(state.copyWith(isLoading: false, errorMessage: errorMessage));
      // Optional: Reset error after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (state.authState== AuthStatus.unauthenticated && state.errorMessage == errorMessage) {
          emit(state.copyWith(errorMessage: ''));
        }
      });
    } finally {
      if (state.authState == AuthStatus.unauthenticated) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  Future<void> signUp() async{
    final formState = state;
    if (formState.password != formState.confirmPassword) {
      emit(formState.copyWith(errorMessage: 'Passwords do not match.'));
      return; 
    }
    if (formState.password.length < 6) {
      emit(formState.copyWith(errorMessage: 'Password must be at least 6 characters.'));
      return;
    }

    emit(formState.copyWith(isLoading: true, errorMessage: ''));
    try {
      await _authService.signUpWithEmailAndPassword(
        email: formState.email.trim(),
        password: formState.password,
      );
      // On success, the auth state stream will handle navigation.
    } catch (e) {
      final errorMessage = e.toString();
      logError('Sign Up Failed: $errorMessage');
      emit(state.copyWith(errorMessage: errorMessage));
      // Optional: Reset error after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (state.authState== AuthStatus.unauthenticated && state.errorMessage == errorMessage) {
          emit(state.copyWith(errorMessage: ''));
        }
      });
    } finally {
      if (state.authState== AuthStatus.unauthenticated) {
        emit(state.copyWith(isLoading: false));
      }
    }
}

  Future<void> signOut() async {
    try {
      await _authService.logOut();
    } catch (e) {
      final errorMessage = 'Sign Out Failed: ${e.toString().split(':').last.trim()}';
      emit(state.copyWith(isLoading: true, errorMessage: ''));
      logError(errorMessage);
    }
  }

  Future<void> checkVerificationStatus() async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      await _authService.reloadUser();
      
      // Manually check the verification status after reloading.
      final firebaseUser = _authService.currentFirebaseUser;
      if (firebaseUser != null && firebaseUser.emailVerified) {
        logInfo('Verification status check: Email is now verified. Emitting authenticated.');
        // The user is now verified, emit the authenticated state to trigger navigation.
        emit(state.copyWith(authState: AuthStatus.authenticated, isLoading: false));
      } else {
        logInfo('Verification status check: Email is still not verified.');
      }
    } catch (e) {
      final errorMessage = 'Failed to check status: ${e.toString()}';
      logError(errorMessage);
      emit(state.copyWith(errorMessage: errorMessage, isLoading: false));
    }finally{
      // The isLoading flag is now handled within the try/catch block.
    }

  }

  Future<void> sendEmailVerification() async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      await _authService.sendEmailVerification();
      // Listener will catch the verified state and transition to AuthAuthenticated
    } catch (e) {
      final errorMessage = 'Verification Email Failed: ${e.toString().split(':').last.trim()}';
      emit(state.copyWith(errorMessage: errorMessage));
      logError(errorMessage);
    }finally{
            Future.delayed(const Duration(seconds: 5), () {
          emit(state.copyWith(isLoading: false,errorMessage: ''));
      });
    }
  }
  
  Future<void> logOut() async {
    try {
      await _authService.logOut();
    }catch (e){
      final errorMessage = 'Verification Email Failed: ${e.toString().split(':').last.trim()}';
      emit(state.copyWith(isLoading: false, errorMessage: errorMessage));
      logError(errorMessage);
    }
  }

  Future<void> deleteUser() async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      await _authService.deleteUser();
      // The auth stream will automatically emit unauthenticated state upon success.
    } catch (e) {
      final errorMessage = 'Failed to delete account: ${e.toString()}';
      logError(errorMessage);
      emit(state.copyWith(isLoading: false, errorMessage: errorMessage));
    } finally {
      // Ensure loading is always turned off if the state is still Unauthenticated
    }
  }

  Future<void> completeCustomerSetup({
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
  }) async {
    if (state.user == null) return;

    emit(state.copyWith(isLoading: true));
    try {
      await _authService.updateUser(state.user!.id,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        address: address,
        userAliveStatus: UserAliveStatus.active,
      );
      // The auth stream will pick up the user update and navigate.
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: "Setup failed: $e"));
    }
  }
  
  Future<void> markTourAsSeen() async {
    //await _authService.markTourAsSeen();
  }

  void resetErrorMessage(){
    Future.delayed(const Duration(seconds: 5), () {
        emit(state.copyWith(errorMessage: ''));
      });
  }
  @override
  Future<void> close() {
    _authStatusSubscription.cancel();
    // TODO: Stop the keep-alive timer on Cubit close
    //_authService.stopKeepAlive();
    return super.close();
  }

}