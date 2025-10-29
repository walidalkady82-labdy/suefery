

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/presentation/auth/auth_cubit.dart';

import '../../core/localizations/app_localizations.txt';

class SignUpScreen extends StatelessWidget {

  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final authCubit = context.read<AuthCubit>();
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // The listener handles state changes that cause side-effects,
        // like showing an error message.
        if (state is Unauthenticated) {
          if (state.formState.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.formState.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings!.signUpButton),
          backgroundColor: const Color(0xFFE5002D),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.person_add, size: 80, color: Color(0xFF00308F)),
                const SizedBox(height: 10),
                const Text('Create SUEFERY Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFE5002D))),
                const SizedBox(height: 30),
                
                Text(
                  'New accounts default to Customer role. Rider/Partner accounts require manual vetting after sign-up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                
                BlocBuilder<AuthCubit, AuthState>(
                  // This builder now only rebuilds when the form state changes.
                  buildWhen: (previous, current) =>
                      previous is Unauthenticated && current is Unauthenticated && previous.formState != current.formState,
                  builder: (context, state) {
                    // Because of the buildWhen, we can be confident the state is Unauthenticated.
                    final formState = (state as Unauthenticated).formState;

                    return Column(
                      children: [
                      // Email/Password Form
                      TextField(
                        onChanged: authCubit.updateEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: strings.emailHint,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          prefixIcon: const Icon(Icons.email),
                          errorText: formState.email.isEmpty && formState.autovalidateMode != AutovalidateMode.disabled ? 'Email cannot be empty' : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: authCubit.updatePassword,
                        obscureText: formState.obscureText,
                        decoration: InputDecoration(
                          labelText: strings.passwordHint,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(formState.obscureText ? Icons.visibility_off : Icons.visibility),
                            onPressed: authCubit.toggleObscureText,
                          ),
                          errorText: formState.password.isEmpty && formState.autovalidateMode != AutovalidateMode.disabled ? 'Password cannot be empty' : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: authCubit.updateConfirmPassword,
                        obscureText: formState.obscureText,
                        decoration: InputDecoration(
                          labelText: strings.confirmPasswordHint, 
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          prefixIcon: const Icon(Icons.lock_outline),
                          errorText: formState.confirmPassword != formState.password && formState.autovalidateMode != AutovalidateMode.disabled ? 'Passwords do not match' : null,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: formState.isLoading ? null : authCubit.signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00308F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: formState.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : Text(strings.signUpButton, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Toggle to Login
                      TextButton(
                        onPressed: authCubit.togglePage,
                        child: Text(
                          strings.translate('toLogin') ?? 'Already have an account? Log in', 
                          style: const TextStyle(color: Color(0xFFE5002D))
                        ),
                      )
                      ],
                    );
                  }
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}