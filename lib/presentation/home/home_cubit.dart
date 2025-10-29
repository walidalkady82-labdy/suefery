
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeState {
  final bool isLoading;
  final String errorMessage;
  final String email;
  final String password;
  final String confirmPassword;
  final bool obscureText;
  final bool isLogin;
  
  const HomeState({
    this.isLoading = false,
    this.errorMessage = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.obscureText = true,
    this.isLogin = true,
    });
  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? email,
    String? password,
    String? confirmPassword,
    bool? obscureText,
    bool? isLogin,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,      
      errorMessage: errorMessage ?? this.errorMessage, 
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      obscureText: obscureText ?? this.obscureText,
      isLogin: isLogin ?? this.isLogin,
    );
  }

}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());
  
  Future<void> submitOrder(String prompt) async {
    emit(state.copyWith(
      isLoading: true,
    ));
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    // S1 Logic: Mock successful conversion
    final Map<String, dynamic> mockOrder = {
      'partner': 'University Mini-Mart',
      'items': [
        {'name': 'Water', 'qty': 2, 'price': 10},
        {'name': 'Chips', 'qty': 1, 'price': 15},
      ],
      'total': 35.0,
      'notes': prompt,
    };
  }

  @visibleForTesting
  Future<void> submitOrderMock(String prompt) async {
    emit(state.copyWith(
      isLoading: true,
    ));
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    // S1 Logic: Mock successful conversion
    final Map<String, dynamic> mockOrder = {
      'partner': 'University Mini-Mart',
      'items': [
        {'name': 'Water', 'qty': 2, 'price': 10},
        {'name': 'Chips', 'qty': 1, 'price': 15},
      ],
      'total': 35.0,
      'notes': prompt,
    };
    emit(state.copyWith(
      isLoading: true,
    ));
  }
}