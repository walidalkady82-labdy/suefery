import 'package:firebase_auth/firebase_auth.dart' show User, FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/presentation/auth/cubit_auth.dart';

class ViewEmailVerification extends StatefulWidget {
  const ViewEmailVerification({super.key});

  @override
  State<ViewEmailVerification> createState() => _ViewEmailVerificationState();
}

class _ViewEmailVerificationState extends State<ViewEmailVerification> {
  bool _isEmailVerified = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
        _isEmailVerified = user.emailVerified;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);

    // Hide if verified
    if (_currentUser == null || _isEmailVerified) {
      return const SizedBox.shrink();
    }

    return BlocListener<CubitAuth, StateAuth>(
      listener: (context, state) {
        _checkStatus();
        if (state.errorMessage.isNotEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage), backgroundColor: Colors.red),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end, // Align bubble bottom with avatar
          children: [
            // 1. The "System" Avatar
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              radius: 18,
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),

            // 2. The Chat Bubble
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  // Chat bubble shape: Rounded with a tail on bottom-left
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(2), // The "Tail"
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message Title
                    Text(
                      strings.verifyEmailTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Message Body
                    Text(
                      strings.verifyEmailBody,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    
                    // Action Chips (Buttons inside bubble)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Action 1: Resend
                        ActionChip(
                          avatar: const Icon(Icons.send, size: 16),
                          label: Text(strings.verifyEmailResendButton),
                          backgroundColor: theme.scaffoldBackgroundColor,
                          labelStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                          onPressed: () {
                            context.read<CubitAuth>().sendEmailVerification();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Verification email sent!")),
                            );
                          },
                        ),
                        
                        // Action 2: Check Status
                        ActionChip(
                          avatar: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                          label: Text(strings.verifyEmailResendButton),
                          backgroundColor: theme.primaryColor,
                          labelStyle: const TextStyle(color: Colors.white),
                          onPressed: () async {
                             await context.read<CubitAuth>().checkVerificationStatus();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}