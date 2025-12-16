import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'web_wrapper.dart' as web;

import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/data/enum/auth_status.dart';
import 'package:suefery/presentation/settings/settings_cubit.dart';
import 'cubit_auth.dart';


class LoginScreen1 extends StatelessWidget {
  const LoginScreen1({super.key});
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final authCubit = context.read<CubitAuth>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.loginTextButton),
        backgroundColor: const Color(0xFF00308F),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.delivery_dining, size: 80, color: Color(0xFFE5002D)),
              const SizedBox(height: 10),
              Text(strings.logInPrompt, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00308F))),
              const SizedBox(height: 20),
              BlocBuilder<CubitAuth, StateAuth>(
                builder: (context, state) {
                  if (state.authState == AuthStatus.unauthenticated) {
                    return Column(
                    children: [
                      // Sign in with Google (W1 Low-Friction for Customers)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: state.isLoading ? null : authCubit.signInWithGoogle,
                          icon: Image.asset('assets/images/google-icon-logo.png',
                            height: 20,
                          ),
                          label: Text(strings.googleSignin, style: const TextStyle(fontSize: 18, color: Color(0xFF00308F))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: Color(0xFFE5002D)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Divider(height: 40, thickness: 1, color: Colors.grey),
                      // Email/Password Form
                      TextField(
                        onChanged: authCubit.updateEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: strings.emailHint,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          prefixIcon: const Icon(Icons.email),
                          errorText: state.email.isEmpty && state.autovalidateMode != AutovalidateMode.disabled ? 'Email cannot be empty' : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: authCubit.updatePassword,
                        obscureText: state.obscureText,
                        decoration: InputDecoration(
                          labelText: strings.passwordHint,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(state.obscureText ? Icons.visibility_off : Icons.visibility),
                            onPressed: authCubit.toggleObscureText,
                          ),
                          errorText: state.password.isEmpty && state.autovalidateMode != AutovalidateMode.disabled ? 'Password cannot be empty' : null,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (state.errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Text(state.errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.isLoading ? null : authCubit.signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5002D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : Text(strings.loginTextButton, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Toggle to Sign Up
                      TextButton(
                        onPressed: authCubit.togglePage,
                        child: Text(strings.toSignup, style: const TextStyle(color: Color(0xFF00308F))),
                      ),

                    ],
                  );
                  }
                  // Show a loader while checking auth status or authenticating
                  return const Center(child: CircularProgressIndicator());
                }
              )

            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final authCubit = context.read<CubitAuth>();
    final settingsCubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      // Using theme background color
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.logInScreenTitle),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: BlocBuilder<CubitAuth, StateAuth>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (GoogleSignIn.instance.supportsAuthenticate())
                      // Google Sign-In Button
                      ElevatedButton(
                        onPressed: () => context.read<CubitAuth>().signInWithGoogle(),
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          backgroundColor: theme.colorScheme.surface,
                        ),
                        child: Image.asset(
                          'assets/images/google-icon-logo.png',
                          height: 24,
                        ),
                      )
                      else ...<Widget>[
                      if (kIsWeb)
                        web.renderButton()
                      // #enddocregion ExplicitSignIn
                      else
                        const Text(
                          'This platform does not have a known authentication method',
                        ),
                      // #docregion ExplicitSignIn
                    ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Logo Icon
                  Icon(
                    Icons.delivery_dining, 
                    size: 80, 
                    color: theme.primaryColor
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    strings.logInPrompt, // "Welcome Back" or similar
                    style: textTheme.headlineLarge?.copyWith(
                      color: theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Email Input
                  TextFormField(
                    initialValue: state.email,
                    decoration: InputDecoration(
                      labelText: strings.promptEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: authCubit.updateEmail,
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Input
                  TextFormField(
                    initialValue: state.password,
                    decoration: InputDecoration(
                      labelText: strings.promptPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          state.obscureText 
                          ? Icons.visibility_off 
                          : Icons.visibility
                        ),
                        onPressed: authCubit.toggleObscureText,
                      ),
                    ),
                    obscureText: state.obscureText,
                    onChanged: authCubit.updatePassword,
                  ),
                  const SizedBox(height: 24),
                  
                  // Login Button
                  ElevatedButton(
                    onPressed: authCubit.signIn,
                    child: Text(strings.loginButton),
                  ),
                  const SizedBox(height: 16),
                  
                  // Toggle to Sign Up
                  TextButton(
                    onPressed: authCubit.togglePage,
                    child: Text(strings.toSignup),
                  ),
                  const SizedBox(height: 24),
                  // Language toggle button
                  TextButton(
                    onPressed: () {
                      final currentLocale = Localizations.localeOf(context);
                      if (currentLocale.languageCode == 'en') {
                        settingsCubit.setLocale(const Locale('ar'));
                      } else {
                        settingsCubit.setLocale(const Locale('en'));
                      }
                    },
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'en' ? 'العربية' : 'English',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}