import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/data/enum/auth_status.dart';
import 'package:suefery/data/service/service_pref.dart';
import 'package:suefery/locator.dart';
import 'package:suefery/presentation/auth/screen_customer_setup.dart';
import 'package:suefery/presentation/auth/screen_verification.dart';
import 'package:suefery/presentation/home/cubit_home.dart';
import 'package:suefery/presentation/tour/screen_customer_app_tour.dart';
import 'package:suefery/presentation/home/screen_home.dart';
import 'cubit_auth.dart';
import 'screen_login.dart';
import 'screen_sign_up.dart';

class AuthWrapper extends StatelessWidget{
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<CubitAuth, StateAuth>(
      listener: (context, state) {
        if (state.authState == AuthStatus.unauthenticated) {
                        if (state.errorMessage.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
        }
      },
      builder: (context, state) {
        final user = state.user;

        // 1. Loading Check
        if (state.authState == AuthStatus.inProgress || (state.isLoading && user == null)) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Awaiting Verification Check
        if (state.authState == AuthStatus.awaitingVerification) {
          // Ensure we have an email to show on the verification screen.
          return ScreenVerification(email: user?.email ?? 'your email');
        }

        // 3. Authenticated Check
        if (state.authState == AuthStatus.authenticated && user != null) {
          // If authenticated, but setup isn't done -> Go to Setup
          final prefs = sl<ServicePref>();
        if (state.authState == AuthStatus.authenticated && prefs.isFirstLogin == true) {
          // Use a post-frame callback to ensure the build is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ScreenCustomerAppTour(),
            ));
            // Mark the tour as seen
          context.read<CubitAuth>().markTourAsSeen();
          });
        }
          if (!user.isSetupComplete) {
            return const ScreenCustomerSetup();
          }
          // Otherwise -> Go Home
          return BlocBuilder(
            bloc: context.read<CubitHome>(),
            builder: (context,state) {
              return const ScreenHome();
            }
          );
        }

        // 4. Unauthenticated -> Show Login or Signup
        if (state.isLogin) {
          return const LoginScreen();
        }
        return const ScreenSignUp();
      }
    );
  }
}