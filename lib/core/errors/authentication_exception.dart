

import 'package:logging/logging.dart';

enum AuthenticationExceptionCode{
  //------custom exceptions-------------
  
  //register
  generalError('general-error','An unknown exception occurred.'),
  noCredentials('no-credentials', 'registriation unsuccessfull , no credentials available!'),
    
  //login
  notRegisteredDb('not-registeredDb', 'you are not logged in , please register first!'),
  
  //JoinOrganization
  emailNotMatch('email-not-match', 'Email does not match invitation email!'),
  emailNotFound('email-not-found', 'Email address cannot be found!'),
  
  /// Create an authentication message
  /// from a firebase authentication exception code.
  /// https://pub.dev/documentation/firebase_auth/latest/firebase_auth/FirebaseAuth/createUserWithEmailAndPassword.html
  
  //firebase register
  invalidEmail('invalid-email', 'Email is not valid or badly formatted.'),
  userDisabled('user-disabled', 'unsuccessfull , organization name is missing!'),
  emailAlreadyInUse('email-already-in-use', 'An account already exists for that email!'),
  operationNotAllowed('operation-not-allowed', 'Operation is not allowed.  Please contact support!'),
  weakPassword('weak-password', 'Please enter a stronger password!'),
    
  //firebase login Email/password
  userNotFound('user-not-found', 'No user found for that email!'),
  wrongPassword('wrong-password', 'Incorrect password, please try again!'),
  
  //firebase login Google
  accountExistsWithDifferentCredential('account-exists-with-different-credential', 'account-exists-with-different-credential!'),
  invalidCredential('invalid-credential', 'The credential received is malformed or has expired!'),
  invalidVerificationCode('invalid-verification-code', 'The credential verification code received is invalid!'),
  invalidVerificationId('invalid-verification-id', 'The credential verification ID received is invalid!'),
  
  //firebase login ResetPassword
  invalidActionCode('invalid-action-code', 'The code is invalid or has expired!'),

  //firebase delete account
  requiresRecentLogin('requires-recent-login', 'requires-recent-login!'), 
  ;

  const AuthenticationExceptionCode(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => '$code: $message';
}

extension AuthenticationExceptionCodeExtension on AuthenticationExceptionCode {
  String get toLocal {
    switch (this) {
      case AuthenticationExceptionCode.generalError:
        return AuthenticationExceptionCode.generalError.code;
      case AuthenticationExceptionCode.noCredentials:
        return AuthenticationExceptionCode.noCredentials.code;
      case AuthenticationExceptionCode.notRegisteredDb:
        return AuthenticationExceptionCode.notRegisteredDb.code;
      case AuthenticationExceptionCode.emailNotMatch:
        return AuthenticationExceptionCode.emailNotMatch.code;
      case AuthenticationExceptionCode.emailNotFound:
        return AuthenticationExceptionCode.emailNotFound.code;
        
      case AuthenticationExceptionCode.invalidEmail:
        return AuthenticationExceptionCode.invalidEmail.code;
      case AuthenticationExceptionCode.userDisabled:
        return AuthenticationExceptionCode.userDisabled.code;
      case AuthenticationExceptionCode.emailAlreadyInUse:
        return AuthenticationExceptionCode.emailAlreadyInUse.code;
      case AuthenticationExceptionCode.operationNotAllowed:
        return AuthenticationExceptionCode.operationNotAllowed.code;
      case AuthenticationExceptionCode.weakPassword:
        return AuthenticationExceptionCode.weakPassword.code;
      case AuthenticationExceptionCode.userNotFound:
        return AuthenticationExceptionCode.userNotFound.code;
      case AuthenticationExceptionCode.wrongPassword:
        return AuthenticationExceptionCode.wrongPassword.code;
      case AuthenticationExceptionCode.accountExistsWithDifferentCredential:
        return AuthenticationExceptionCode.accountExistsWithDifferentCredential.code;
      case AuthenticationExceptionCode.invalidCredential:
        return AuthenticationExceptionCode.invalidCredential.code;
      case AuthenticationExceptionCode.invalidVerificationCode:
        return AuthenticationExceptionCode.invalidVerificationCode.code;
      case AuthenticationExceptionCode.invalidVerificationId:
        return AuthenticationExceptionCode.invalidVerificationId.code;
      case AuthenticationExceptionCode.invalidActionCode:
        return AuthenticationExceptionCode.invalidActionCode.code;
      case AuthenticationExceptionCode.requiresRecentLogin:
        return AuthenticationExceptionCode.requiresRecentLogin.code;
    }
  }
}

class AuthenticationFailure implements Exception{

  AuthenticationFailure(this.message,[this.code=AuthenticationExceptionCode.generalError]);

  //AuthenticationFailure.fromCode(this.code,[this.message]);
  //   message == null?log.shout(code.message):log.shout(message);
  //   switch (code) {
  //     case AuthenticationExceptionCode.generalError:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.generalError,
  //         message??AuthenticationExceptionCode.generalError.message
  //         );
  //     case AuthenticationExceptionCode.nocredentials:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.nocredentials,
  //         message??AuthenticationExceptionCode.nocredentials.message
  //         );
  //     case AuthenticationExceptionCode.alreadyCreatedOrganization:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.alreadyCreatedOrganization,
  //         message??AuthenticationExceptionCode.alreadyCreatedOrganization.message
  //         );
  //     case AuthenticationExceptionCode.organizationCreationFailed:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.organizationCreationFailed,
  //         message??AuthenticationExceptionCode.organizationCreationFailed.message
  //         );
  //     case AuthenticationExceptionCode.organizationNameMissing:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.organizationNameMissing,
  //         message??AuthenticationExceptionCode.organizationNameMissing.message
  //         );
  //     case AuthenticationExceptionCode.wrongUserRole:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.wrongUserRole,
  //         message??AuthenticationExceptionCode.wrongUserRole.message
  //         );      
  //     case AuthenticationExceptionCode.notRegisteredDb:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.notRegisteredDb,
  //         message??AuthenticationExceptionCode.notRegisteredDb.message
  //         );
  //     case AuthenticationExceptionCode.emailNotMatch:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.emailNotMatch,
  //         message??AuthenticationExceptionCode.emailNotMatch.message
  //         );
  //     case AuthenticationExceptionCode.emailNotFound:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.emailNotFound,
  //         message??AuthenticationExceptionCode.emailNotFound.message
  //         );
  //     case AuthenticationExceptionCode.invitationCode:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.invitationCode,
  //         message??AuthenticationExceptionCode.invitationCode.message
  //         );
  //     case AuthenticationExceptionCode.invitationData:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.invitationData,
  //         message??AuthenticationExceptionCode.invitationData.message
  //         );
  //     case AuthenticationExceptionCode.invitationExpired:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.invitationExpired,
  //         message??AuthenticationExceptionCode.invitationExpired.message
  //         );
  //     case AuthenticationExceptionCode.organizationNotFound:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.organizationNotFound,
  //         message??AuthenticationExceptionCode.organizationNotFound.message
  //         );
  //     case AuthenticationExceptionCode.userCreationFailed:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.userCreationFailed,
  //         message??AuthenticationExceptionCode.userCreationFailed.message
  //         );
  //     case AuthenticationExceptionCode.invalidEmail:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.invalidEmail,
  //         message??AuthenticationExceptionCode.invalidEmail.message
  //         );
  //     case AuthenticationExceptionCode.userDisabled:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.userDisabled,
  //         message??AuthenticationExceptionCode.userDisabled.message
  //         );
  //     case AuthenticationExceptionCode.emailAlreadyInUse:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.emailAlreadyInUse,
  //         message??AuthenticationExceptionCode.emailAlreadyInUse.message
  //         );
  //     case AuthenticationExceptionCode.operationNotAllowed:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.operationNotAllowed,
  //         message??AuthenticationExceptionCode.operationNotAllowed.message
  //         );
  //     case AuthenticationExceptionCode.weakPassword:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.weakPassword,
  //         message??AuthenticationExceptionCode.weakPassword.message
  //         );
  //     case AuthenticationExceptionCode.userNotFound:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.userNotFound,
  //         message??AuthenticationExceptionCode.userNotFound.message
  //         );
  //     case AuthenticationExceptionCode.wrongPassword:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.wrongPassword,
  //         message??AuthenticationExceptionCode.wrongPassword.message
  //         );
  //     case AuthenticationExceptionCode.accountExistsWithDifferentCredential:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.accountExistsWithDifferentCredential,
  //         message??AuthenticationExceptionCode.accountExistsWithDifferentCredential.message
  //         );
  //     case AuthenticationExceptionCode.invalidCredential:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.invalidCredential,
  //         message??AuthenticationExceptionCode.invalidCredential.message
  //         );
  //     case AuthenticationExceptionCode.invalidVerificationCode:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.invalidVerificationCode,
  //         message??AuthenticationExceptionCode.invalidVerificationCode.message
  //         );
  //     case AuthenticationExceptionCode.invalidVerificationId:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.invalidVerificationId,
  //         message??AuthenticationExceptionCode.invalidVerificationId.message
  //         );
  //     case AuthenticationExceptionCode.invalidActionCode:
  //       return AuthenticationFailure(
  //         code:AuthenticationExceptionCode.invalidActionCode,
  //         message??AuthenticationExceptionCode.invalidActionCode.message
  //         );
  //     default:
  //         return AuthenticationFailure(
  //           code:AuthenticationExceptionCode.generalError,
  //           message??AuthenticationExceptionCode.generalError.message
  //           );
  //   }
  // }
  @override
  String toString() {
    return 'AuthenticationFailure: $message';
  }
  final String message;
  final AuthenticationExceptionCode? code;
}

class GeneralAuthenticationFailure extends AuthenticationFailure {
  GeneralAuthenticationFailure([String? message])
      : super(message??AuthenticationExceptionCode.generalError.message,AuthenticationExceptionCode.generalError);
}

class NoCredentialsFailure extends AuthenticationFailure {
  NoCredentialsFailure([String? message]):
    super(message??AuthenticationExceptionCode.noCredentials.message,AuthenticationExceptionCode.noCredentials);
}

class UserNotFoundFailure extends AuthenticationFailure {
  UserNotFoundFailure([String? message])
      : super(message??AuthenticationExceptionCode.userNotFound.message,AuthenticationExceptionCode.userNotFound);
}

class EmailNotFoundFailure extends AuthenticationFailure {
  EmailNotFoundFailure([String? message])
      : super(message??AuthenticationExceptionCode.emailNotFound.message,AuthenticationExceptionCode.emailNotFound);
}

class EmailMissmatchFailure extends AuthenticationFailure {
  EmailMissmatchFailure([String? message])
      : super(message??AuthenticationExceptionCode.emailNotMatch.message,AuthenticationExceptionCode.emailNotMatch);
}

class RegisterFirebaseFailure extends AuthenticationFailure{
  RegisterFirebaseFailure(super.message,[super.code]);
  factory RegisterFirebaseFailure.fromCode(String code) {
      final log = Logger('RegisterFirebaseFailure');
      switch (code) {
        case 'no-credentials':
          log.shout(AuthenticationExceptionCode.noCredentials.message);
          return RegisterFirebaseFailure(AuthenticationExceptionCode.noCredentials.message,AuthenticationExceptionCode.noCredentials);
        case 'invalid-email':
          log.shout(AuthenticationExceptionCode.invalidEmail.message);
          return RegisterFirebaseFailure(AuthenticationExceptionCode.invalidEmail.message,AuthenticationExceptionCode.invalidEmail);
        case 'user-disabled':
          log.shout(AuthenticationExceptionCode.userDisabled.message);
          return RegisterFirebaseFailure(AuthenticationExceptionCode.userDisabled.message,AuthenticationExceptionCode.userDisabled);
        case 'email-already-in-use':
          log.shout(AuthenticationExceptionCode.emailAlreadyInUse.message);
          return RegisterFirebaseFailure(AuthenticationExceptionCode.emailAlreadyInUse.message,AuthenticationExceptionCode.emailAlreadyInUse);
        case 'operation-not-allowed':
          log.shout(AuthenticationExceptionCode.operationNotAllowed.message);
          return RegisterFirebaseFailure(AuthenticationExceptionCode.operationNotAllowed.message,AuthenticationExceptionCode.operationNotAllowed);
        case 'weak-password':
          log.shout(AuthenticationExceptionCode.weakPassword.message);
          return RegisterFirebaseFailure(AuthenticationExceptionCode.weakPassword.message,AuthenticationExceptionCode.weakPassword);
        default:
          log.shout(AuthenticationExceptionCode.generalError.message);
          return RegisterFirebaseFailure(AuthenticationExceptionCode.generalError.message,AuthenticationExceptionCode.generalError);
        }
  }
}

class LoginGoogleFirebaseFailure extends AuthenticationFailure{
  LoginGoogleFirebaseFailure(super.message,[super.code]);
  
  factory LoginGoogleFirebaseFailure.fromCode(String code) {
    final log = Logger('LoginGoogleFirebaseFailure');
      switch (code) {
        case 'no-credentials':
          log.shout(AuthenticationExceptionCode.noCredentials.message);
          return LoginGoogleFirebaseFailure(AuthenticationExceptionCode.noCredentials.message,AuthenticationExceptionCode.noCredentials);              
        case 'account-exists-with-different-credential':
          log.shout(AuthenticationExceptionCode.accountExistsWithDifferentCredential.message);
          return LoginGoogleFirebaseFailure(AuthenticationExceptionCode.accountExistsWithDifferentCredential.message,AuthenticationExceptionCode.accountExistsWithDifferentCredential);    
        case 'invalid-credential':
          log.shout(AuthenticationExceptionCode.invalidCredential.message);
            return LoginGoogleFirebaseFailure(AuthenticationExceptionCode.invalidCredential.message,AuthenticationExceptionCode.invalidCredential);     
        case 'operation-not-allowed':
        log.shout(AuthenticationExceptionCode.operationNotAllowed.message);
            return LoginGoogleFirebaseFailure(AuthenticationExceptionCode.operationNotAllowed.message,AuthenticationExceptionCode.operationNotAllowed);  
        case 'invalid-verification-code':
        log.shout(AuthenticationExceptionCode.invalidVerificationCode.message);
            return LoginGoogleFirebaseFailure(AuthenticationExceptionCode.invalidVerificationCode.message,AuthenticationExceptionCode.invalidVerificationCode);  
        case 'invalid-verification-id':
          log.shout(AuthenticationExceptionCode.invalidVerificationId.message);
            return LoginGoogleFirebaseFailure(AuthenticationExceptionCode.invalidVerificationId.message,AuthenticationExceptionCode.invalidVerificationId);  
        default:
          log.shout(AuthenticationExceptionCode.generalError.message);
          return LoginGoogleFirebaseFailure(AuthenticationExceptionCode.generalError.message,AuthenticationExceptionCode.generalError);
        }
  }
}

class LoginEmailPassFirebaseFailure extends AuthenticationFailure{
  LoginEmailPassFirebaseFailure(super.message,[super.code]);
  static final log = Logger('LoginEmailPassFirebaseFailure');
  factory LoginEmailPassFirebaseFailure.fromCode(String code) {
      switch (code) {
        case 'no-credentials':
          log.shout(AuthenticationExceptionCode.noCredentials.message);
          return LoginEmailPassFirebaseFailure(AuthenticationExceptionCode.noCredentials.message,AuthenticationExceptionCode.noCredentials);              
        case 'invalid-email':
          log.shout(AuthenticationExceptionCode.invalidEmail.message);
          return LoginEmailPassFirebaseFailure(AuthenticationExceptionCode.invalidEmail.message,AuthenticationExceptionCode.invalidEmail);    
        case 'user-disabled':
          log.shout(AuthenticationExceptionCode.userDisabled.message);
            return LoginEmailPassFirebaseFailure(AuthenticationExceptionCode.userDisabled.message,AuthenticationExceptionCode.userDisabled);     
        case 'user-not-found':
        log.shout(AuthenticationExceptionCode.userNotFound.message);
            return LoginEmailPassFirebaseFailure(AuthenticationExceptionCode.userNotFound.message,AuthenticationExceptionCode.userNotFound);  
        case 'wrong-password':
        log.shout(AuthenticationExceptionCode.wrongPassword.message);
            return LoginEmailPassFirebaseFailure(AuthenticationExceptionCode.wrongPassword.message,AuthenticationExceptionCode.wrongPassword);   
        case 'invalid-credential':
          log.shout(AuthenticationExceptionCode.invalidCredential.message);
          return LoginEmailPassFirebaseFailure(AuthenticationExceptionCode.invalidCredential.message,AuthenticationExceptionCode.invalidCredential);         
        default:
          log.shout(AuthenticationExceptionCode.generalError.message);
          return LoginEmailPassFirebaseFailure(AuthenticationExceptionCode.generalError.message,AuthenticationExceptionCode.generalError);
        }
  }
}

class LogoutFailure extends AuthenticationFailure {
  LogoutFailure(super.message);
}

class ResetPassFirebaseFailure extends AuthenticationFailure{
  ResetPassFirebaseFailure(super.message,[super.code]);
  
  factory ResetPassFirebaseFailure.fromCode(String code) {
      final log = Logger('ResetPassFirebaseFailure');
      switch (code) {
        case 'user-not-found':
          log.shout(AuthenticationExceptionCode.userNotFound.message);
          return ResetPassFirebaseFailure(AuthenticationExceptionCode.userNotFound.message,AuthenticationExceptionCode.userNotFound);              
        case 'invalid-action-code':
          log.shout(AuthenticationExceptionCode.invalidActionCode.message);
          return ResetPassFirebaseFailure(AuthenticationExceptionCode.invalidActionCode.message,AuthenticationExceptionCode.invalidActionCode);    
        case 'weak-password':
          log.shout(AuthenticationExceptionCode.weakPassword.message);
            return ResetPassFirebaseFailure(AuthenticationExceptionCode.weakPassword.message,AuthenticationExceptionCode.weakPassword);        
        default:
          log.shout(AuthenticationExceptionCode.generalError.message);
          return ResetPassFirebaseFailure(AuthenticationExceptionCode.generalError.message,AuthenticationExceptionCode.generalError);
        }
  }
}

class DeleteAccountFirebaseFailure extends AuthenticationFailure {
  DeleteAccountFirebaseFailure(super.message,[super.code]);
  
  factory DeleteAccountFirebaseFailure.fromCode(String code) {
    final log = Logger('DeleteAccountFirebaseFailure');
      switch (code) {
        case 'requires-recent-login':
          log.shout(AuthenticationExceptionCode.requiresRecentLogin.message);
          return DeleteAccountFirebaseFailure(AuthenticationExceptionCode.requiresRecentLogin.message,AuthenticationExceptionCode.requiresRecentLogin);              
                
        default:
          log.shout(AuthenticationExceptionCode.generalError.message);
          return DeleteAccountFirebaseFailure(AuthenticationExceptionCode.generalError.message,AuthenticationExceptionCode.generalError);
        }
  }
}

//TODO: implement other exceptions


// class RegisterUserFailure extends AuthenticationFailure{
  
//   RegisterUserFailure(super.message,{super.code});
// }

// class AuthenticationFailure1 implements Exception{

//   AuthenticationFailure([
//     this.message = 'An unknown exception occurred.'
//   ]){
//     log.shout(message);
//   }
//   final String message;
// }

// class RegisterUserFailure1 implements Exception{

//   const RegisterUserFailure1([
//     this.code = 'general-error',
//     this.message = 'An unknown exception occurred.'
//   ]);
//   factory RegisterUserFailure1.fromCode(String code,{String? message}) {
//     switch (code) {
//       case 'no-credentials':
//         log.shout('registriation unsuccessfull , no credentials available!');
//         return const RegisterUserFailure1(
//           'no-credentials',
//           'registriation unsuccessfull , no credentials available!',
//         );
//       case 'already-created-organization':
//         log.shout('registriation unsuccessfull , you already have joined an organization!');
//         return const RegisterUserFailure1(
//           'already-created-organization',
//           'registriation unsuccessfull , you already have joined an organization!',
//         );
//       case 'organization-creation-failed':
//         log.shout('registriation unsuccessfull , organization could not be created!');
//         return const RegisterUserFailure1(
//           'organization-creation-failed',
//           'registriation unsuccessfull , organization could not be created!',
//         );
//       case 'organization-name-missing':
//         log.shout('registriation unsuccessfull , organization name is missing!');
//         return const RegisterUserFailure1(
//           'organization-name-missing',
//           'registriation unsuccessfull , organization name is missing!',
//         );
//         case 'wrong-user-role':
//         log.shout('registriation unsuccessfull , problem in user role!');
//         return const RegisterUserFailure1(
//           'wrong-user-role',
//           'registriation unsuccessfull , problem in user role!',
//         );
//         ///---- firebase exceptions-----------
//         /// Create an authentication message
//         /// from a firebase authentication exception code.
//         /// https://pub.dev/documentation/firebase_auth/latest/firebase_auth/FirebaseAuth/createUserWithEmailAndPassword.html
//         case 'invalid-email':
//         log.shout('Email is not valid or badly formatted.');
//         return const RegisterUserFailure1(
//           'invalid-email',
//           'Email is not valid or badly formatted.',
//         );
//         case 'user-disabled':
//         log.shout('This user has been disabled. Please contact support for help.');
//           return const RegisterUserFailure1(
//             'user-disabled',
//             'This user has been disabled. Please contact support for help.',
//           );
//         case 'email-already-in-use':
//         log.shout('An account already exists for that email.');
//           return const RegisterUserFailure1(
//             'email-already-in-use',
//             'An account already exists for that email.',
//           );
//         case 'operation-not-allowed':
//         log.shout('Operation is not allowed.  Please contact support.');
//           return const RegisterUserFailure1(
//             'operation-not-allowed',
//             'Operation is not allowed.  Please contact support.',
//           );
//         case 'weak-password':
//         log.shout('Please enter a stronger password.');
//           return const RegisterUserFailure1(
//             'weak-password',
//             'Please enter a stronger password.',
//           );
//         ///----------------------------------------------------------  
//         default:
//           log.shout(message??'An unknown exception occurred.');
//           return RegisterUserFailure1(
//             'general-error',
//             message??'An unknown exception occurred.'
//           );
//     }
//   }
//   final String code;
//   final String message;
// }

// class LoginUserFailure implements Exception{

//   const LoginUserFailure([
//     this.code = 'general-error',
//     this.message = 'An unknown exception occurred.'
//   ]);
//   factory LoginUserFailure.fromCode(String code,{String? message}) {
//     switch (code) {
//       case 'no-credentials':
//         log.shout('you are not logged in , log in first!');
//         return const LoginUserFailure(
//           'no-credentials',
//           'you are not logged in , log in first!',
//         );
//       case 'not-registeredDb':
//         log.shout('you are not logged in , please register first!');
//         return const LoginUserFailure(
//           'not-registeredDb',
//           'you are not logged in , please register first!',
//         );
//       ///---- firebase exceptions-----------
//       ///Email password login
//       case 'invalid-email':
//       log.shout('Email is not valid or badly formatted.');
//         return const LoginUserFailure(
//           'invalid-email',
//           'Email is not valid or badly formatted.',
//         );
//       case 'user-disabled':
//       log.shout('This user has been disabled. Please contact support for help.');
//         return const LoginUserFailure(
//           'user-disabled',
//           'This user has been disabled. Please contact support for help.',
//         );
//       case 'user-not-found':
//       log.shout('Email is not found, please create an account.');
//         return const LoginUserFailure(
//           'user-not-found',
//           'Email is not found, please create an account.',
//         );
//       case 'wrong-password':
//       log.shout('Incorrect password, please try again.');
//         return const LoginUserFailure(
//           'wrong-password',
//           'Incorrect password, please try again.',
//         );
//       ///Google login
//       case 'account-exists-with-different-credential':
//       log.shout('Account exists with different credentials.');
//         return const LoginUserFailure(
//           'account-exists-with-different-credential',
//           'Account exists with different credentials.',
//         );
//       case 'invalid-credential':
//       log.shout('The credential received is malformed or has expired.');
//         return const LoginUserFailure(
//           'invalid-credential',
//           'The credential received is malformed or has expired.',
//         );
//       case 'operation-not-allowed':
//       log.shout('Operation is not allowed.  Please contact support.');
//         return const LoginUserFailure(
//           'operation-not-allowed',
//           'Operation is not allowed.  Please contact support.',
//         );
//       case 'invalid-verification-code':
//       log.shout('The credential verification code received is invalid.');
//         return const LoginUserFailure(
//           'invalid-verification-code',
//           'The credential verification code received is invalid.',
//         );
//       case 'invalid-verification-id':
//       log.shout('The credential verification ID received is invalid.');
//         return const LoginUserFailure(
//           'invalid-verification-id',
//           'The credential verification ID received is invalid.',
//         );
//       ///  ------------------------------------------------------
//       default:
//         log.shout(message??'An unknown exception occurred.');
//         return LoginUserFailure(
//           'general-error',
//           message??'An unknown exception occurred.'
//         );
//     }
//   }
//   final String code;
//   final String message;
// }

// class JoinOrganizationFailure implements Exception{

//   const JoinOrganizationFailure([
//     this.code = 'general-error',
//     this.message = 'An unknown exception occurred.'
//   ]);
//   factory JoinOrganizationFailure.fromCode(String code,{String? message}) {
//     switch (code) {
//       case 'no-credentials':
//         log.shout('you are not logged in , log in first!');
//         return const JoinOrganizationFailure(
//           'no-credentials',
//           'you are not logged in , log in first!',
//         );
//       case 'email-not-match':
//         log.shout('Email does not match invitation email!');
//         return const JoinOrganizationFailure(
//           'email-not-match',
//           'Email does not match invitation email!',
//         );
//       case 'email-not-found':
//         log.shout('Email address cannot be found!');
//         return const JoinOrganizationFailure(
//           'email-not-found',
//           'Email address cannot be found!',
//         );
//       case 'invitation-code':
//         log.shout('Invitaion code error!');
//         return const JoinOrganizationFailure(
//           'invitation-code',
//           'Invitaion code error!',
//         );
//       case 'invitation-data':
//         log.shout('Invitaion data error!');
//         return const JoinOrganizationFailure(
//           'invitation-data',
//           'Invitaion data error!',
//         );
//       case 'invitation-expired':
//         log.shout('Invitaion expired!');
//         return const JoinOrganizationFailure(
//           'invitation-expired',
//           'Invitaion expired!',
//         );
//       case 'organization-not-found':
//         log.shout('Invitation organization not found!');
//         return const JoinOrganizationFailure(
//           'organization-not-found',
//           'Invitation organization not found!',
//         );
//       case 'user-creation-failed':
//         log.shout('Could not join user to organization!');
//         return const JoinOrganizationFailure(
//           'user-creation-failed',
//           'Could not join user to organization!',
//         );
//       default:
//         log.shout(message??'An unknown exception occurred.');
//         return JoinOrganizationFailure(
//           'general-error',
//           message??'An unknown exception occurred.'
//         );
//     }
//   }
//   final String code;
//   final String message;
// }

// /// Thrown during the logout process if a failure occurs.
// class LogOutFailure implements Exception {}

// class ResetPasswordFailure implements Exception {
//   /// {@macro log_in_with_email_and_password_failure}
//   const ResetPasswordFailure([
//     this.message = 'An unknown exception occurred.',
//   ]);

//   /// Create an authentication message
//   /// from a firebase authentication exception code.
//   factory ResetPasswordFailure.fromCode(String code) {
//     switch (code) {
//       case 'user-not-found':
//         return const ResetPasswordFailure(
//           'No user found for that email.',
//         );
//       case 'invalid-action-code':
//         return const ResetPasswordFailure(
//           'The code is invalid or has expired.',
//         );
//       case 'weak-password':
//         return const ResetPasswordFailure(
//           'Email is not found, please create an account.',
//         );
//       default:
//         return ResetPasswordFailure(
//           code
//         );
//     }
//   }

//   /// The associated error message.
//   final String message;
// }

// /// Thrown during the deleting acconut process if a failure occurs.
// class DeleteAccountFailure implements Exception{

//   const DeleteAccountFailure([
//     this.code = 'general-error',
//     this.message = 'An unknown exception occurred.'
//   ]);
//   factory DeleteAccountFailure.fromCode(String code,{String? message}) {
//     switch (code) {
//       default:
//         log.shout(message??'An unknown exception occurred.');
//         return DeleteAccountFailure(
//           'general-error',
//           message??'An unknown exception occurred.'
//         );
//     }
//   }
//   final String code;
//   final String message;
// }