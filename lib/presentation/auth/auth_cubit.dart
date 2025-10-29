import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/data/models/app_user.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/logging_service.dart';

final _log = LoggerReprository('LoginState');

abstract class AuthState {
  const AuthState();
}

class AuthInProgress extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;
  const Authenticated(this.user);
}

class Unauthenticated extends AuthState {
  final AuthFormState formState;
  const Unauthenticated({this.formState = const AuthFormState()});
}

class AuthFormState {
  final bool isLoading;
  final String errorMessage;
  final String email;
  final String password;
  final String confirmPassword;
  final AutovalidateMode autovalidateMode;
  final bool obscureText;
  final bool isLogin;
  
  const AuthFormState({
    this.isLoading = false,
    this.errorMessage = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.autovalidateMode = AutovalidateMode.disabled,
    this.obscureText = true,
    this.isLogin = true,
    });
  AuthFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? email,
    String? password,
    String? confirmPassword,
    AutovalidateMode? autovalidateMode,
    bool? obscureText,
    bool? isLogin,
  }) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,      
      errorMessage: errorMessage ?? this.errorMessage, 
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      autovalidateMode: autovalidateMode ?? this.autovalidateMode,
      obscureText: obscureText ?? this.obscureText,
      isLogin: isLogin ?? this.isLogin,
    );
  }

}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(AuthService authService) 
      : _authService = authService,
        super(AuthInProgress()) {
          _authSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
        }
  final AuthService _authService;
   late final StreamSubscription<AppUser?> _authSubscription;

  void _onAuthStateChanged(AppUser? user) {
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(const Unauthenticated());
    }
  }

  // Helper to safely access the form state
  AuthFormState _getFormState() {
    final currentState = state;
    if (currentState is Unauthenticated) {
      return currentState.formState;
    }
    // This should ideally not happen if UI is built correctly,
    // but it's a safe fallback.
    return const AuthFormState();
  }

  // Helper to emit a new Unauthenticated state with updated form data
  void _emitFormState(AuthFormState newFormState) {
    if (state is Unauthenticated) {
      emit(Unauthenticated(formState: newFormState));
    }
  }

  void updateLoadingState(bool loadingState){
    _emitFormState(_getFormState().copyWith(isLoading: loadingState));
  }

  void updateEmail(String? email) {
    _emitFormState(_getFormState().copyWith(email: email));
  }

  void updatePassword(String? password) {
    _emitFormState(_getFormState().copyWith(password: password));
  }

  void updateConfirmPassword(String? confirmPassword) {
    _emitFormState(_getFormState().copyWith(confirmPassword: confirmPassword));
  }

  void updateAutovalidateMode(AutovalidateMode? autovalidateMode) {
    _emitFormState(_getFormState().copyWith(autovalidateMode: autovalidateMode));
  }

  void toggleObscureText() {
    final currentFormState = _getFormState();
    _emitFormState(currentFormState.copyWith(obscureText: !currentFormState.obscureText));
  }

  void reset() {
    _emitFormState(const AuthFormState());
  }

  void togglePage() {
    final currentFormState = _getFormState();
    _emitFormState(currentFormState.copyWith(isLogin: !currentFormState.isLogin));
  }

  Future<void> signIn() async {
    final formState = _getFormState();
    _emitFormState(formState.copyWith(isLoading: true, errorMessage: ''));

    try {
      await _authService.signInWithEmailAndPassword(
        email: formState.email.trim(),
        password: formState.password,
      );
      // On success, the auth stream will emit Authenticated state.
    } catch (e) {
      final errorMessage = 'Login Failed: ${e.toString().split(':').last.trim()}';
      _log.e(errorMessage);
      _emitFormState(_getFormState().copyWith(errorMessage: errorMessage, isLoading: false));
      
      // Optional: Reset error after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (state is Unauthenticated && (state as Unauthenticated).formState.errorMessage == errorMessage) {
          _emitFormState(_getFormState().copyWith(errorMessage: ''));
        }
      });
    } finally {
      // Ensure loading is always turned off if the state is still Unauthenticated
      if (state is Unauthenticated) {
        _emitFormState(_getFormState().copyWith(isLoading: false));
      }
    }
  }
  
  Future<void> signInWithGoogle() async {
    _emitFormState(_getFormState().copyWith(isLoading: true, errorMessage: ''));
    try {
      await _authService.signInWithGoogle();
      // On success, the auth stream will emit Authenticated state.
    } catch (e) {
      final errorMessage = 'Google Login Failed: ${e.toString().split(':').last.trim()}';
      _log.e(errorMessage);
      _emitFormState(_getFormState().copyWith(isLoading: false, errorMessage: errorMessage));
    } finally {
      if (state is Unauthenticated) {
        _emitFormState(_getFormState().copyWith(isLoading: false));
      }
    }
  }

  //TODO check errors message to integrate with strings
  Future<void> signUp() async{
    final formState = _getFormState();
    if (formState.password != formState.confirmPassword) {
      _emitFormState(formState.copyWith(errorMessage: 'Passwords do not match.'));
      return; 
    }
    if (formState.password.length < 6) {
      _emitFormState(formState.copyWith(errorMessage: 'Password must be at least 6 characters.'));
      return;
    }

    _emitFormState(formState.copyWith(isLoading: true, errorMessage: ''));
    try {
      await _authService.signUpWithEmailAndPassword(
        email: formState.email.trim(),
        password: formState.password,
      );
      // On success, the auth state stream will handle navigation.
    } catch (e) {
      final errorMessage = 'Sign Up Failed: ${e.toString().split(':').last.trim()}';
      _log.e(errorMessage);
      _emitFormState(_getFormState().copyWith(errorMessage: errorMessage));
    } finally {
      if (state is Unauthenticated) {
        _emitFormState(_getFormState().copyWith(isLoading: false));
      }
    }
}
}