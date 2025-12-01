// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get sectionA => '___TITLES_AND_HEADINGS___';

  @override
  String get appTitle => 'SUEFERY Multi-Role App';

  @override
  String get appBarTitle => 'Gemini Chef';

  @override
  String get logInScreenTitle => 'SUEFERY LOGIN';

  @override
  String get signInTitle => 'Sign In';

  @override
  String get registerTitle => 'Register';

  @override
  String get profileTitle => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get historyTitle => 'Order History';

  @override
  String get verifyEmailTitle => 'Verify Your Email';

  @override
  String get welcomeTitle => '👋 Welcome to SUEFEREY!';

  @override
  String get welcomeLottieTitle => 'Here\'s a quick look at what I can do:';

  @override
  String get recipeTitleFallback => 'Recipe';

  @override
  String get pendingOrderTermsTitle => 'Terms and Conditions';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get sectionB => '___LABELS_AND_GENERAL_TEXTS___';

  @override
  String get customerTitle => 'SUEFERY Customer App';

  @override
  String get riderTitle => 'SUEFERY Rider App (Logistics Moat)';

  @override
  String get partnerTitle => 'SUEFERY Partner App';

  @override
  String get welcomeMessage => 'Welcome!';

  @override
  String get welcomeCustomer =>
      'Welcome Customer! Start your Conversational Order (S1)';

  @override
  String get welcomeRider => 'Rider Dashboard';

  @override
  String get welcomePartner => 'Partner Dashboard';

  @override
  String get logInPrompt => 'Please Log In';

  @override
  String currentLanguage(String currentLanguage) {
    return 'Current Language is: $currentLanguage';
  }

  @override
  String orderConfirmedTitle(String orderNumber) {
    return 'Order Confirmed: #$orderNumber';
  }

  @override
  String quantityLabel(int quantity) {
    return 'Quantity: #$quantity';
  }

  @override
  String get recipeName => 'Recipe Name';

  @override
  String get promptHelp => 'Need help?';

  @override
  String get pendingOrderTermsBody =>
      '1. All sales are final.\n 2. Delivery times are estimates.\n 3. Prices are subject to change without notice.\n';

  @override
  String get verifyEmailBody =>
      'We\'ve sent a verification link to your email. Please check your inbox (and spam folder) to continue.';

  @override
  String get sectionC => '___BUTTONS_AND_ACTIONS___';

  @override
  String get loginButton => 'Log in';

  @override
  String get signUpButton => 'Sign up';

  @override
  String get googleSignin => 'Google SignIn';

  @override
  String get logoutTextButton => 'Log out';

  @override
  String get close => 'Close';

  @override
  String get agree => 'Agree';

  @override
  String get disagree => 'Disagree';

  @override
  String get switchRider => 'Switch to Rider View';

  @override
  String get switchCustomer => 'Switch to Customer View';

  @override
  String get switchPartner => 'Switch to Partner View';

  @override
  String get loginTextButton => 'Already have an account? Log in';

  @override
  String get toSignup => 'To Signup';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get languageSwitch => 'Switch Language (العربية)';

  @override
  String get verifyEmailResendButton => 'Resend Verification Email';

  @override
  String get verifyEmailBackButton => 'Back to Login';

  @override
  String get checkStatusButton => 'Check Status';

  @override
  String get buttonHistory => 'View Order History';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get confirmAndPay => 'Confirm and Pay';

  @override
  String get orderTextButton => 'Orders';

  @override
  String get pendingOrdersTextButton => 'Pending Orders';

  @override
  String get suggestionButton => 'Suggest Recipe';

  @override
  String get sectionD => '___LABELS_STATUSES_AND_DATA___';

  @override
  String get darkMode => 'Set Dark Mode';

  @override
  String get tabAIOrder => 'AI Orders';

  @override
  String get tabBrowse => 'Browse Stores';

  @override
  String get menuTooltip => 'Menu';

  @override
  String get orderId => 'Order ID';

  @override
  String get orderTotal => 'Total';

  @override
  String get total => 'Total';

  @override
  String get orderStatus => 'Status';

  @override
  String get orderSummary => 'Summary';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get toBeConfirmed => 'To be Confirmed';

  @override
  String get fastestDeliveryZone => 'Fastest Delivery Zone';

  @override
  String get partnerStore => 'Partner Stores';

  @override
  String get paymentFailed => 'Payment failed or was cancelled.';

  @override
  String get paymentSuccessful => 'Payment Successful';

  @override
  String get paymentPending => 'Payment Pending';

  @override
  String get loadingHistory => 'Loading Order History...';

  @override
  String get noHistory => 'No past orders found.';

  @override
  String get noOrders => 'No Orders';

  @override
  String get recipeNoIngredients => 'No ingredients listed.';

  @override
  String get sectionE => '___HINTS_AND_PROMPTS___';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get chatHint => 'Type a message...';

  @override
  String get promptEmail => 'Please enter your email';

  @override
  String get promptPassword => 'Please enter your password';

  @override
  String get promptConfirmPassword => 'Confirm your password';

  @override
  String get authHintChoice => 'Type \'Sign In\' or \'Register\'';

  @override
  String get authHintEmail => 'Enter your email';

  @override
  String get authHintPassword => 'Enter your password';

  @override
  String get welcomeFirstTimePrompt =>
      'Ready to order? To save your history and place orders, please sign in or register below.';

  @override
  String get welcomeReturningPrompt =>
      'Welcome back! Please sign in or register to continue your session.';

  @override
  String get promptSuggestRecipe => 'Would you like to suggest a recipe?';

  @override
  String get postVideoAuthPrompt => 'Please log in to post a video';

  @override
  String get sectionF => '___ERRORS_AND_VALIDATION___';

  @override
  String errorFieldRequired(String field) {
    return '$field is required';
  }

  @override
  String errorFieldInvalid(String field) {
    return '$field is Invalid';
  }

  @override
  String errorPasswordLength(int chars) {
    return 'Password must be at least $chars characters long';
  }

  @override
  String get errorPasswordMismatch => 'Passwords do not match';

  @override
  String get verificationNeeded => 'Email is not verified';

  @override
  String get unknownAuthState => 'Unknown Authentication State.';

  @override
  String animationError(String error) {
    return 'Could not load animation: $error';
  }

  @override
  String errorAuthFailed(String errorDetails, Object currentLanguage) {
    return 'Authorization failed : $errorDetails';
  }
}
