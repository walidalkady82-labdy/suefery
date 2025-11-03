// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SUEFERY Multi-Role App';

  @override
  String get customerTitle => 'SUEFERY Customer App';

  @override
  String get riderTitle => 'SUEFERY Rider App (Logistics Moat)';

  @override
  String get partnerTitle => 'SUEFERY Partner App';

  @override
  String get welcomeCustomer =>
      'Welcome Customer! Start your Conversational Order (S1)';

  @override
  String get welcomeRider => 'Rider Dashboard';

  @override
  String get welcomePartner => 'Partner Dashboard';

  @override
  String get switchRider => 'Switch to Rider View';

  @override
  String get switchCustomer => 'Switch to Customer View';

  @override
  String get switchPartner => 'Switch to Partner View';

  @override
  String get languageSwitch => 'Switch Language (العربية)';

  @override
  String get logInPrompt => 'Please Log In';

  @override
  String get loginTextButton => '\'Already have an account? Log in';

  @override
  String get signUpButton => 'sign up';

  @override
  String get googleSignin => 'google SignIn';

  @override
  String get toSignup => 'To Signup';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get historyTitle => 'Order History';

  @override
  String get buttonHistory => 'View Order History';

  @override
  String get orderId => 'Order ID';

  @override
  String get orderTotal => 'Total';

  @override
  String get orderStatus => 'Status';

  @override
  String get orderSummary => 'Summary';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get loadingHistory => 'Loading Order History...';

  @override
  String get noHistory => 'No past orders found.';

  @override
  String get emailRequiredErrorMessage => 'Email is required';

  @override
  String get emailInvalidErrorMessage => 'Email is Invalid';

  @override
  String get passwordRequiredErrorMessage => 'Password is required';

  @override
  String get tabAIOrder => 'AI Orders';

  @override
  String get tabBrowse => 'Browse Stores';

  @override
  String get partnerStore => 'Partner Stores';

  @override
  String get total => 'Total';

  @override
  String get fastestDeliveryZone => 'Fastest Delivery Zone';

  @override
  String get verificationNeeded => 'Email is not verified';

  @override
  String get checkStatusButton => 'Check Status';

  @override
  String get welcomeMessage => 'Welcome!';

  @override
  String get suggestionButton => 'Suggest Recipe';

  @override
  String get recipeName => 'Recipe Name';

  @override
  String get orderHistoryTitle => 'Order history';

  @override
  String get noOrders => 'No Orders';
}
