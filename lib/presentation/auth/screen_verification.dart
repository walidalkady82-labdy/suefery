import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';

import 'cubit_auth.dart';

class ScreenVerification extends StatelessWidget {
  final String email;
  const ScreenVerification({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final authCubit = context.read<CubitAuth>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.appTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                strings.verificationNeeded,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text('A link has been sent to $email.'),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => authCubit.checkVerificationStatus(),
                icon: const Icon(Icons.refresh),
                label: Text(strings.checkStatusButton),
              ),
              TextButton(
                onPressed: () => authCubit.sendEmailVerification(),
                child: const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 