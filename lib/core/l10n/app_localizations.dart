import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The main title for the application.
  ///
  /// In en, this message translates to:
  /// **'SUEFERY Multi-Role App'**
  String get appTitle;

  /// The title for the Customer-facing application or section.
  ///
  /// In en, this message translates to:
  /// **'SUEFERY Customer App'**
  String get customerTitle;

  /// The title for the Rider-facing application or section.
  ///
  /// In en, this message translates to:
  /// **'SUEFERY Rider App (Logistics Moat)'**
  String get riderTitle;

  /// The title for the Partner-facing application or section.
  ///
  /// In en, this message translates to:
  /// **'SUEFERY Partner App'**
  String get partnerTitle;

  /// A greeting for the Customer.
  ///
  /// In en, this message translates to:
  /// **'Welcome Customer! Start your Conversational Order (S1)'**
  String get welcomeCustomer;

  /// A greeting for the Rider.
  ///
  /// In en, this message translates to:
  /// **'Rider Dashboard'**
  String get welcomeRider;

  /// A greeting for the Partner.
  ///
  /// In en, this message translates to:
  /// **'Partner Dashboard'**
  String get welcomePartner;

  /// Label for a button/option to switch view to the Rider interface.
  ///
  /// In en, this message translates to:
  /// **'Switch to Rider View'**
  String get switchRider;

  /// Label for a button/option to switch view to the Customer interface.
  ///
  /// In en, this message translates to:
  /// **'Switch to Customer View'**
  String get switchCustomer;

  /// Label for a button/option to switch view to the Partner interface.
  ///
  /// In en, this message translates to:
  /// **'Switch to Partner View'**
  String get switchPartner;

  /// Label for a language selection option, specifically mentioning Arabic.
  ///
  /// In en, this message translates to:
  /// **'Switch Language (العربية)'**
  String get languageSwitch;

  /// The call-to-action or prompt displayed on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Please Log In'**
  String get logInPrompt;

  /// scueferey screen title
  ///
  /// In en, this message translates to:
  /// **'SUEFERY LOGIN'**
  String get logInScreenTitle;

  /// The text for the login button
  ///
  /// In en, this message translates to:
  /// **'\'Log in'**
  String get loginButton;

  /// The text for the login message text
  ///
  /// In en, this message translates to:
  /// **'\'Already have an account?Log in'**
  String get loginTextButton;

  /// The text for the logout text
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutTextButton;

  /// The text for the standard sign-up button.
  ///
  /// In en, this message translates to:
  /// **'sign up'**
  String get signUpButton;

  /// Label for the Google Sign-In option.
  ///
  /// In en, this message translates to:
  /// **'google SignIn'**
  String get googleSignin;

  /// Label/link for navigating to the Sign Up screen.
  ///
  /// In en, this message translates to:
  /// **'To Signup'**
  String get toSignup;

  /// Placeholder text for the email input field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// Placeholder text for the password input field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// Placeholder text for the password confirmation input field.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordHint;

  /// Title for the Order History screen or section.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get historyTitle;

  /// Text for the button to navigate to the order history.
  ///
  /// In en, this message translates to:
  /// **'View Order History'**
  String get buttonHistory;

  /// Label/text for viewing the detailed order history.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// Label for the unique identifier of an order.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderTotal;

  /// Label for the current state of an order.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderStatus;

  /// Label for a brief overview of an order.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get orderSummary;

  /// The specific status text indicating an order has been completed.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// Message displayed while the application is fetching past orders.
  ///
  /// In en, this message translates to:
  /// **'Loading Order History...'**
  String get loadingHistory;

  /// Message displayed when the user has no previous orders.
  ///
  /// In en, this message translates to:
  /// **'No past orders found.'**
  String get noHistory;

  /// Error message when the email field is left empty.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequiredErrorMessage;

  /// Error message when the entered email format is incorrect.
  ///
  /// In en, this message translates to:
  /// **'Email is Invalid'**
  String get emailInvalidErrorMessage;

  /// Error message when the password field is left empty.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequiredErrorMessage;

  /// Orders tab using Gemini
  ///
  /// In en, this message translates to:
  /// **'AI Orders'**
  String get tabAIOrder;

  /// Browse stores
  ///
  /// In en, this message translates to:
  /// **'Browse Stores'**
  String get tabBrowse;

  /// Browse partners stores
  ///
  /// In en, this message translates to:
  /// **'Partner Stores'**
  String get partnerStore;

  ///
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Fastest Delivery Zone
  ///
  /// In en, this message translates to:
  /// **'Fastest Delivery Zone'**
  String get fastestDeliveryZone;

  /// A message to the user to ask him to verif the email
  ///
  /// In en, this message translates to:
  /// **'Email is not verified'**
  String get verificationNeeded;

  /// Check email verification status button
  ///
  /// In en, this message translates to:
  /// **'Check Status'**
  String get checkStatusButton;

  /// Application welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeMessage;

  /// suggest recipe button text
  ///
  /// In en, this message translates to:
  /// **'Suggest Recipe'**
  String get suggestionButton;

  /// Name of the recipe
  ///
  /// In en, this message translates to:
  /// **'Recipe Name'**
  String get recipeName;

  /// Order history title
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get orderHistoryTitle;

  /// No orders available message
  ///
  /// In en, this message translates to:
  /// **'No Orders'**
  String get noOrders;

  /// settings Title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Chnage language button string
  ///
  /// In en, this message translates to:
  /// **'change Language'**
  String get changeLanguage;

  /// Select language
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Current Selected language
  ///
  /// In en, this message translates to:
  /// **'Current Language is: {currentLanguage}'**
  String currentLanguage(String currentLanguage);

  /// Set dark mode
  ///
  /// In en, this message translates to:
  /// **'Set dark mode'**
  String get darkMode;

  /// profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// pending Orders button text
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrdersTextButton;

  /// Orders text button
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orderTextButton;

  /// Main title in the AppBar
  ///
  /// In en, this message translates to:
  /// **'Gemini Chef'**
  String get appBarTitle;

  /// The first message in the anonymous welcome flow
  ///
  /// In en, this message translates to:
  /// **'👋 Welcome to Chef AI!'**
  String get welcomeTitle;

  /// The title for the Lottie presentation bubble
  ///
  /// In en, this message translates to:
  /// **'Here\'s a quick look at what I can do:'**
  String get welcomeLottieTitle;

  /// The final prompt in the anonymous flow asking the user to sign up
  ///
  /// In en, this message translates to:
  /// **'Ready to order? To save your history and place orders, please sign in or register below.'**
  String get welcomeFirstTimePrompt;

  /// The message shown to a returning anonymous user
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in or register to continue your session.'**
  String get welcomeReturningPrompt;

  /// Error message if the Lottie file fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load animation: {error}'**
  String animationError(String error);

  /// The title for the Sign In form bubble
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// The title for the Register form bubble
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// Title for the email verification screen
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// Body text for the email verification screen
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to your email. Please check your inbox (and spam folder) to continue.'**
  String get verifyEmailBody;

  /// Button text to resend the verification email
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get verifyEmailResendButton;

  /// Button text to go back to the login flow
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get verifyEmailBackButton;

  /// Fallback title for a recipe bubble
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get recipeTitleFallback;

  /// Fallback text when a recipe has no ingredients
  ///
  /// In en, this message translates to:
  /// **'No ingredients listed.'**
  String get recipeNoIngredients;

  /// Error message for an unhandled auth state
  ///
  /// In en, this message translates to:
  /// **'Unknown Authentication State.'**
  String get unknownAuthState;

  /// Tooltip for the main menu icon button
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// Default hint text for the chat input bar when authenticated
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatHint;

  /// Hint text when asking the user to choose between sign in or register
  ///
  /// In en, this message translates to:
  /// **'Type \'Sign In\' or \'Register\''**
  String get authHintChoice;

  /// Hint text when asking the user for their email
  ///
  /// In en, this message translates to:
  /// **'Enter your email...'**
  String get authHintEmail;

  /// Hint text when asking the user for their password
  ///
  /// In en, this message translates to:
  /// **'Enter your password...'**
  String get authHintPassword;

  /// Hint text when asking the user to confirm their password
  ///
  /// In en, this message translates to:
  /// **'Confirm your password...'**
  String get authHintConfirmPassword;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'cancel this order'**
  String get cancelOrder;

  /// No description provided for @confirmAndPay.
  ///
  /// In en, this message translates to:
  /// **'Confirm and Pay'**
  String get confirmAndPay;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
