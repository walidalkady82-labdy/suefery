import 'package:flutter/material.dart';
import '../../data/enum/app_string_keys.dart';

mixin FormValidationMixin {
  /// Validates that a field is not empty.
  String? validateRequired(BuildContext context, String? value, String localizedFieldName) {
    if (value == null || value.trim().isEmpty) {
      return AppStringKey.errorFieldRequired.resolve(context, args: [localizedFieldName]);
    }
    return null;
  }

  String? validateEmail(BuildContext context, String? value) {
    // 1. Get the localized word for "Email" (e.g. "البريد الإلكتروني")
    final fieldName = AppStringKey.emailHint.resolve(context);
    
    final requiredError = validateRequired(context, value, fieldName);
    if (requiredError != null) return requiredError;

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value!)) {
      return AppStringKey.errorFieldInvalid.resolve(context, args: [fieldName]);
    }
    return null;
  }

  String? validatePassword(BuildContext context, String? value, {int minLength = 6}) {
    // 1. Get the localized word for "Password"
    final fieldName = AppStringKey.passwordHint.resolve(context);

    final requiredError = validateRequired(context, value, fieldName);
    if (requiredError != null) return requiredError;

    if (value!.length < minLength) {
      return AppStringKey.errorPasswordLength.resolve(context, args: [minLength.toString()]);
    }
    return null;
  }

  String? validateConfirmPassword(BuildContext context, String? value, String originalPassword) {
    if (value != originalPassword) {
      return AppStringKey.errorPasswordMismatch.resolve(context);
    }
    return null;
  }
}