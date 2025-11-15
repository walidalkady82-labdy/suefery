import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/data/models/user_model.dart';
import 'package:suefery/locator.dart';
import '../../data/enums/auth_status.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/logging_service.dart';

final _log = LoggerRepo('LoginState');

class AuthState {
  final bool isLoading;
  final String errorMessage;
  final String email;
  final String password;
  final String confirmPassword;
  final AutovalidateMode autovalidateMode;
  final bool obscureText;
  final bool isLogin;
  final AuthStatus authState;
  final UserModel? user;
  
  const AuthState({
    this.isLoading = false,
    this.errorMessage = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.autovalidateMode = AutovalidateMode.disabled,
    this.obscureText = true,
    this.isLogin = true,
    this.authState = AuthStatus.inProgress,
    this.user,
    });
  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? email,
    String? password,
    String? confirmPassword,
    AutovalidateMode? autovalidateMode,
    bool? obscureText,
    bool? isLogin,
    AuthStatus? authState,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,      
      errorMessage: errorMessage ?? this.errorMessage, 
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      autovalidateMode: autovalidateMode ?? this.autovalidateMode,
      obscureText: obscureText ?? this.obscureText,
      isLogin: isLogin ?? this.isLogin,
      authState: authState ?? this.authState,
      user: user ?? this.user,
    );
  }

}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState()) {
          authSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
        }
  final AuthService _authService = sl<AuthService>();
  late final StreamSubscription<UserModel?> authSubscription;

  UserModel? get currentUser => _authService.currentAppUser;

  void _onAuthStateChanged(UserModel? user) {
    if (user != null) {
      emit(state.copyWith(authState: AuthStatus.authenticated, user: user));
    } else {
      emit(state.copyWith(authState: AuthStatus.authenticated, user: null));
    }
  }

  void updateLoadingState(bool loadingState){
    emit(state.copyWith(isLoading: loadingState));
  }

  void updateEmail(String? email) {
    emit(state.copyWith(email: email));
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
    emit(const AuthState());
  }

  void togglePage() {
    final currentFormState = state;
    emit(currentFormState.copyWith(isLogin: !currentFormState.isLogin));
  }

  Future<void> signIn(String email, String password) async {
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
      _log.e('Login Failed: $errorMessage');
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
      _log.e('Google Login Failed: $errorMessage');
      emit(state.copyWith(isLoading: false, errorMessage: errorMessage));
    } finally {
      if (state.authState == AuthStatus.unauthenticated) {
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
      _log.e(errorMessage);
    }
  }

  Future<void> checkVerificationStatus() async {
    final formState = state;
    emit(formState.copyWith(isLoading: true, errorMessage: ''));
    try {
      await _authService.reloadUser();
      // Listener will catch the verified state and transition to AuthAuthenticated
    } catch (e) {
      final errorMessage = 'Sign Out Failed: ${e.toString().split(':').last.trim()}';
      emit(formState.copyWith(isLoading: false, errorMessage: errorMessage));
      _log.e(errorMessage);
    }
  }

  Future<void> sendEmailVerification() async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      await _authService.sendEmailVerification();
      // Listener will catch the verified state and transition to AuthAuthenticated
    } catch (e) {
      final errorMessage = 'Verification Email Failed: ${e.toString().split(':').last.trim()}';
      emit(state.copyWith(isLoading: false, errorMessage: errorMessage));
      _log.e(errorMessage);
    }
  }
  
  Future<void> logOut() async {
    try {
      await _authService.logOut();
    }catch (e){
      final errorMessage = 'Verification Email Failed: ${e.toString().split(':').last.trim()}';
      emit(state.copyWith(isLoading: false, errorMessage: errorMessage));
      _log.e(errorMessage);
    }
  }
  //TODO check errors message to integrate with strings
  Future<void> signUp(String email, String password) async{
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
      _log.e('Sign Up Failed: $errorMessage');
      emit(state.copyWith(errorMessage: errorMessage));
    } finally {
      if (state.authState== AuthStatus.unauthenticated) {
        emit(state.copyWith(isLoading: false));
      }
    }
}
}