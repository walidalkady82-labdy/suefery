import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit_auth.dart';

Widget renderButton() {
  return Builder(builder: (context) {
    final theme = Theme.of(context);
    return ElevatedButton(
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
    );
  });
}
