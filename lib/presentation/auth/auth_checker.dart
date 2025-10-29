import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/presentation/auth/auth_cubit.dart';

import 'auth_wrapper.dart';
import '../home/home_screen.dart';

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Listens to the authentication state from the AuthCubit
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // 1. Initial Loading/Waiting state
        if (state is AuthInProgress) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // 2. User is Logged In
        if (state is Authenticated) {
          return const HomeScreen();
        }
        // 3. User is Logged Out
          return const AuthPageWrapper(); // Navigates between Login and Sign Up
      },
    );
  }
}