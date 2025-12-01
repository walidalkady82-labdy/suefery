import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/presentation/home/screen_home.dart';
import '../../data/enum/auth_status.dart';
import 'cubit_auth.dart';
import 'auth_wrapper.dart';

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Listens to the authentication state from the AuthCubit
    return BlocBuilder<CubitAuth, StateAuth>(
      builder: (context, state) {
        // 1. Initial Loading/Waiting state
        if (state.authState == AuthStatus.inProgress) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
            
          );
        }
        // 2. User is Logged In
        if (state.authState == AuthStatus.authenticated && state.user != null) {
          return ScreenHome();
        }
        // 3. User is Logged Out
          return const AuthWrapper(); // Navigates between Login and Sign Up
      },
    );
  }
}