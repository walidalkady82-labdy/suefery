

import 'package:suefery/core/l10n/app_localizations.dart';

mixin Validator {
  // Email validation
  String? validateEmail(AppLocalizations strings,String? value) {
    if (value == null || value.isEmpty) {
      return strings.emailRequiredErrorMessage;
    } else if (!RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$').hasMatch(value)) {
      return strings.emailInvalidErrorMessage;
    }
    return null;
  }

//   // Password validation
//   String? validatePassword(AppLocalizations strings,String? value) {
//     if (value == null || value.isEmpty) {
//       return "errorMessages.passwordRequired".tr();
//     } else if (value.length < 6) {
//       return "errorMessages.passwordInvalid".tr();
//     }
//     return null;
//   }

//   // Confirm password validation
//   String? validateConfirmPassword(AppLocalizations strings,String? value, String password) {
//     if (value == null || value.isEmpty) {
//       return "errorMessages.confirmPasswordRequired".tr();
//     } else if (value != password) {
//       return "errorMessages.passwordMismatch".tr();
//     }
//     return null;
//   }

//   // Name validation
//   String? validateName(AppLocalizations strings,String? value) {
//     if (value == null || value.isEmpty) {
//       return "errorMessages.Required".tr();
//     }
//     return null;
//   }

//   // Address validation
//   String? validateAddress(AppLocalizations strings,String? value) {
//     if (value == null || value.isEmpty) {
//       return "errorMessages.Required".tr();
//     }
//     return null;
//   }

//   String? validateDetailsIsNotEmpty(AppLocalizations strings,String? value) {
//     if (value == null) {
//       return "errorMessages.Required".tr();
//     }
//     return null;
//   }

//   String? validateDropdownSelection(AppLocalizations strings,dynamic value) {
//     if (value == null) {
//         return "errorMessages.Required".tr();
//     }
//     return null; // Return null if the selection is valid
// }
}