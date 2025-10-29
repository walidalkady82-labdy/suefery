import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_cubit.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

class AuthPageWrapper extends StatelessWidget{
  const AuthPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      // We only want to rebuild this when the Unauthenticated state changes
      buildWhen: (previous, current) => current is Unauthenticated,
      builder: (context, state) {
      // This should always be Unauthenticated because of buildWhen, but it's a safe cast.
      final formState = (state as Unauthenticated).formState;

      if (formState.isLogin) {
        return const LoginScreen();
      } else {
        return const SignUpScreen(); // Assuming you have a SignUpScreen
      }
    });
  }
}