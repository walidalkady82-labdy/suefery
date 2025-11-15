import 'package:flutter/material.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';

class VerificationView extends StatelessWidget {
  final VoidCallback onResend;
  final VoidCallback onCancel;

  const VerificationView({
    super.key,
    required this.onResend,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_email_read,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              strings.verifyEmailTitle,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              strings.verifyEmailBody,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onResend,
              child: Text(strings.verifyEmailResendButton),
            ),
            TextButton(
              onPressed: onCancel,
              child: Text(strings.verifyEmailBackButton),
            ),
          ],
        ),
      ),
    );
  }
}