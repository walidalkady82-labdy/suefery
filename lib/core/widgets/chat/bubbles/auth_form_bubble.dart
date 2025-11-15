import 'package:flutter/material.dart';
// Note: You will need to add your l10n import here if you
// want to use the strings for validation messages.
import 'package:suefery/core/l10n/l10n_extension.dart';

import '../../../../data/enums/auth_form_type.dart';
import '../../../l10n/app_localizations.dart'; 

class AuthFormBubble extends StatefulWidget {
  const AuthFormBubble({
    super.key,
    required this.formType,
     this.onSignIn,
     this.onRegister,
    
    // --- NEW: All UI strings are now parameters ---
    required this.title,
    required this.emailHint,
    required this.passwordHint,
    this.confirmPasswordHint, // Nullable, only for register
    required this.buttonText,
    this.switchFormText,
  });

  final AuthFormType formType;
  final Future<bool> Function(String email, String password)? onSignIn;
  final Future<bool> Function(String email, String password)? onRegister;

  // --- NEW: String fields ---
  final String title;
  final String emailHint;
  final String passwordHint;
  final String? confirmPasswordHint;
  final String buttonText;
  final String? switchFormText;

  @override
  State<AuthFormBubble> createState() => _AuthFormBubbleState();
}

class _AuthFormBubbleState extends State<AuthFormBubble> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }
    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool success = false;

    try {
      if (widget.formType == AuthFormType.signIn) {
        success = await widget.onSignIn!(email, password);
      } else {
        success = await widget.onRegister!(email, password);
      }
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('${widget.formType.name} failed. Check credentials.'))
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Network Error: Please try again.'))
         );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Validation Helpers (using l10n) ---
  String? _validateEmail(String? value, AppLocalizations strings) {
    if (value == null || value.isEmpty) {
      return strings.emailRequiredErrorMessage; // <-- Use key
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return strings.emailInvalidErrorMessage; // <-- Use key
    }
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations strings) {
    if (value == null || value.isEmpty) {
      return strings.passwordRequiredErrorMessage; // <-- Use key
    }
    if (widget.formType == AuthFormType.register && value.length < 6) {
      return 'Password must be at least 6 characters.'; // TODO: Add to l10n
    }
    return null;
  }
  
  String? _validateConfirmPassword(String? value, AppLocalizations strings) {
    if (widget.formType == AuthFormType.register) {
      if (value != _passwordController.text) {
        return 'Passwords do not match.'; // TODO: Add to l10n
      }
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final strings = context.l10n; // Get strings for validation

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge), // <-- Use param
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: widget.emailHint), // <-- Use param
                keyboardType: TextInputType.emailAddress,
                validator: (value) => _validateEmail(value, strings), // Pass strings
              ),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: widget.passwordHint), // <-- Use param
                obscureText: true,
                validator: (value) => _validatePassword(value, strings), // Pass strings
              ),
              
              if (widget.formType == AuthFormType.register)
                TextFormField(
                  decoration: InputDecoration(labelText: widget.confirmPasswordHint), // <-- Use param
                  obscureText: true,
                  validator: (value) => _validateConfirmPassword(value, strings),
                ),
              
              const SizedBox(height: 20),

              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(widget.buttonText), // <-- Use param
                ),
              
              if (widget.switchFormText != null)
                 TextButton(
                  onPressed: () { /* This is handled by ChatView's logic */ }, 
                  child: Text(widget.switchFormText!), // <-- Use param
                ),
            ],
          ),
        ),
      ),
    );
  }
}