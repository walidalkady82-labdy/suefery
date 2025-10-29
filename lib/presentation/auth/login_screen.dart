import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/localizations/app_localizations.txt';
import 'package:suefery/presentation/auth/auth_cubit.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final authCubit = context.read<AuthCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(strings!.loginButton),
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
              const Text('SUEFERY Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00308F))),
              const SizedBox(height: 30),
              Text(
                'Test roles: customer/rider/partner@suefery.com. Pass: "password123".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  // We only build the form if the user is unauthenticated.
                  if (state is! Unauthenticated) {
                    // Show a loader or an empty container if state is not Unauthenticated
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Extract the form state
                  final formState = state.formState;
                  return Column(
                    children: [
                      // Sign in with Google (W1 Low-Friction for Customers)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: formState.isLoading ? null : authCubit.signInWithGoogle,
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                            height: 20,
                          ),
                          label: Text(strings.googleSignIn, style: const TextStyle(fontSize: 18, color: Color(0xFF00308F))),
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
                      const SizedBox(height: 30),
                      if (formState.errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Text(formState.errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: formState.isLoading ? null : authCubit.signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5002D),
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
                              : Text(strings.loginButton, style: const TextStyle(fontSize: 18)),
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
              )

            ],
          ),
        ),
      ),
    );
  }
}