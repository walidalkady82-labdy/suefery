
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/data/enum/auth_status.dart';
import 'package:suefery/presentation/auth/cubit_auth.dart';

class SignUpScreen1 extends StatelessWidget {

  const SignUpScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final authCubit = context.read<CubitAuth>();
    return BlocListener<CubitAuth, StateAuth>(
      listener: (context, state) {
        // The listener handles state changes that cause side-effects,
        // like showing an error message.
        
        if (state.authState== AuthStatus.unauthenticated) {
          if (state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.signUpButton),
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
                Text(strings.signUpButton, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFE5002D))),
                const SizedBox(height: 30),
                
                Text(
                  strings.signUpDisclaimer,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                
                BlocBuilder<CubitAuth, StateAuth>(
                  // This builder now only rebuilds when the form state changes.
                  buildWhen: (previous, current) =>
                      previous.authState ==AuthStatus.unauthenticated && current.authState ==AuthStatus.unauthenticated && previous.authState != current.authState,
                  builder: (context, state) {
                    // Because of the buildWhen, we can be confident the state.authState== AuthStatus.unauthenticated.
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
                          errorText: state.email.isEmpty && state.autovalidateMode != AutovalidateMode.disabled ? strings.errorFieldRequired(strings.email) : null,
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
                          errorText: state.password.isEmpty && state.autovalidateMode != AutovalidateMode.disabled ? strings.errorFieldRequired(strings.password) : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: authCubit.updateConfirmPassword,
                        obscureText: state.obscureText,
                        decoration: InputDecoration(
                          labelText: strings.confirmPasswordHint, 
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          prefixIcon: const Icon(Icons.lock_outline),
                          errorText: state.confirmPassword != state.password && state.autovalidateMode != AutovalidateMode.disabled ? strings.errorPasswordMismatch : null,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton( // The onPressed should not pass parameters if the method doesn't expect them.
                          onPressed: state.isLoading ? null : authCubit.signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00308F),
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
                              : Text(strings.signUpButton, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Toggle to Login
                      TextButton(
                        onPressed: authCubit.togglePage,
                        child: Text(
                          strings.loginTextButton, 
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

class ScreenSignUp extends StatelessWidget {
  const ScreenSignUp({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final authCubit = context.read<CubitAuth>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.signUpButton),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: BlocBuilder<CubitAuth, StateAuth>(
            builder: (context, state) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    strings.registerTitle,
                    style: textTheme.headlineMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // --- Personal Info ---
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: state.firstName,
                          decoration: InputDecoration(
                            labelText: strings.firstNameLabel, 
                            prefixIcon: Icon(Icons.person),
                          ),
                          onChanged: authCubit.updateFirsttName,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: state.lastName,
                          decoration: InputDecoration(
                            labelText: strings.lastNameLabel,
                            prefixIcon: Icon(Icons.person)
                          ),
                          onChanged: authCubit.updateLastName,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: state.phone,
                    decoration: InputDecoration(
                      labelText: strings.phoneLabel, //"Phone Number",
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: authCubit.updatePhone,
                  ),
                  const SizedBox(height: 12),

                  // --- Credentials ---
                  TextFormField(
                    initialValue: state.email,
                    decoration: InputDecoration(
                      labelText: strings.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: authCubit.updateEmail,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: state.password,
                    decoration: InputDecoration(
                      labelText: strings.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(state.obscureText ? Icons.visibility_off : Icons.visibility),
                        onPressed: authCubit.toggleObscureText,
                      ),
                    ),
                    obscureText: state.obscureText,
                    onChanged: authCubit.updatePassword,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: state.confirmPassword,
                    decoration: InputDecoration(
                      labelText: strings.confirmPasswordLabel, //"Confirm Password", // Add to ARB if missing
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: state.obscureText,
                    onChanged: authCubit.updateConfirmPassword,
                  ),
                  const SizedBox(height: 32),

                  // --- Action Buttons ---
                  ElevatedButton(
                    onPressed: state.isLoading ? null : () {
                      if (state.password != state.confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Passwords do not match")),
                        );
                        return;
                      }
                      authCubit.signUp();
                    },
                    child: state.isLoading
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.white)
                          )
                        : Text(strings.signUpButton),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: authCubit.togglePage,
                    child: Text(strings.loginTextButton),
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