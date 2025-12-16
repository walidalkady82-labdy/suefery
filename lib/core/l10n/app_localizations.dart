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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// General Agree button
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get agree;

  /// Lottie loading error
  ///
  /// In en, this message translates to:
  /// **'Could not load animation: {error}'**
  String animationError(String error);

  /// Main title in the AppBar
  ///
  /// In en, this message translates to:
  /// **'SUEFERY'**
  String get appBarTitle;

  /// The main title for the application.
  ///
  /// In en, this message translates to:
  /// **'SUEFERY'**
  String get appTitle;

  /// Chat hint for auth choice
  ///
  /// In en, this message translates to:
  /// **'Type \'Sign In\' or \'Register\''**
  String get authHintChoice;

  /// Chat hint for email entry
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authHintEmail;

  /// Chat hint for password entry
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authHintPassword;

  /// Button to view history
  ///
  /// In en, this message translates to:
  /// **'View Order History'**
  String get buttonHistory;

  /// Cancel order action
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// Change language button string
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// Default chat input hint
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatHint;

  /// Check email verification status button
  ///
  /// In en, this message translates to:
  /// **'Check Status'**
  String get checkStatusButton;

  /// General Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Payment confirmation action
  ///
  /// In en, this message translates to:
  /// **'Confirm and Pay'**
  String get confirmAndPay;

  /// Placeholder for password confirmation
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordHint;

  /// Label for confirm password
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// Displays current selected language
  ///
  /// In en, this message translates to:
  /// **'Current Language is: {currentLanguage}'**
  String currentLanguage(String currentLanguage);

  /// Title for Customer section
  ///
  /// In en, this message translates to:
  /// **'SUEFERY Customer App'**
  String get customerTitle;

  /// Toggle for dark mode
  ///
  /// In en, this message translates to:
  /// **'Set Dark Mode'**
  String get darkMode;

  /// General Disagree button
  ///
  /// In en, this message translates to:
  /// **'Disagree'**
  String get disagree;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'email'**
  String get email;

  /// Placeholder for email input
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// Error for invalid passwords or token expiration.
  ///
  /// In en, this message translates to:
  /// **'Authorization failed : {errorDetails}'**
  String errorAuthFailed(String errorDetails);

  /// Generic error when a field format is wrong
  ///
  /// In en, this message translates to:
  /// **'{field} is Invalid'**
  String errorFieldInvalid(String field);

  /// Generic error when a field is missing
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String errorFieldRequired(String field);

  /// Error message for password length
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {chars} characters long'**
  String errorPasswordLength(int chars);

  /// Error message for password mismatch
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errorPasswordMismatch;

  /// Label for fast delivery area
  ///
  /// In en, this message translates to:
  /// **'Fastest Delivery Zone'**
  String get fastestDeliveryZone;

  /// Label for first name
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// Google Sign-In button
  ///
  /// In en, this message translates to:
  /// **'Google SignIn'**
  String get googleSignin;

  /// Title for Order History screen
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get historyTitle;

  /// Label for language selection option.
  ///
  /// In en, this message translates to:
  /// **'Switch Language (العربية)'**
  String get languageSwitch;

  /// Label for last name
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// Loading state text
  ///
  /// In en, this message translates to:
  /// **'Loading Order History...'**
  String get loadingHistory;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// Prompt displayed on login screen
  ///
  /// In en, this message translates to:
  /// **'Please Log In'**
  String get logInPrompt;

  /// Login screen header
  ///
  /// In en, this message translates to:
  /// **'SUEFERY LOGIN'**
  String get logInScreenTitle;

  /// Text button to switch to login
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get loginTextButton;

  /// Log out button text
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutTextButton;

  /// Tooltip for menu icon
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// Empty history state
  ///
  /// In en, this message translates to:
  /// **'No past orders found.'**
  String get noHistory;

  /// No orders available message
  ///
  /// In en, this message translates to:
  /// **'No Orders'**
  String get noOrders;

  /// Order confirmation title
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed: #{orderNumber}'**
  String orderConfirmedTitle(String orderNumber);

  /// Label for order identifier
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// Label for order state
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderStatus;

  /// Label for order summary
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get orderSummary;

  /// Button label for Orders
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orderTextButton;

  /// Label for order total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderTotal;

  /// Label for partner stores
  ///
  /// In en, this message translates to:
  /// **'Partner Stores'**
  String get partnerStore;

  /// Title for Partner section
  ///
  /// In en, this message translates to:
  /// **'SUEFERY Partner App'**
  String get partnerTitle;

  /// password word
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Placeholder for password input
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// Payment failure message
  ///
  /// In en, this message translates to:
  /// **'Payment failed or was cancelled.'**
  String get paymentFailed;

  /// Payment pending message
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get paymentPending;

  /// Payment success message
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccessful;

  /// Button label for Pending Orders
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrdersTextButton;

  /// T&C Body text
  ///
  /// In en, this message translates to:
  /// **'1. All sales are final.\n 2. Delivery times are estimates.\n 3. Prices are subject to change without notice.\n'**
  String get pendingOrderTermsBody;

  /// T&C Header
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get pendingOrderTermsTitle;

  /// Label for phone number
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// Auth prompt for video posting
  ///
  /// In en, this message translates to:
  /// **'Please log in to post a video'**
  String get postVideoAuthPrompt;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Chat hint for password confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get promptConfirmPassword;

  /// Prompt for email input
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get promptEmail;

  /// General help prompt
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get promptHelp;

  /// Prompt for password input
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get promptPassword;

  /// AI prompt for suggestions
  ///
  /// In en, this message translates to:
  /// **'Would you like to suggest a recipe?'**
  String get promptSuggestRecipe;

  /// Displays item quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity: #{quantity}'**
  String quantityLabel(int quantity);

  /// Label for recipe name
  ///
  /// In en, this message translates to:
  /// **'Recipe Name'**
  String get recipeName;

  /// Fallback for empty ingredients
  ///
  /// In en, this message translates to:
  /// **'No ingredients listed.'**
  String get recipeNoIngredients;

  /// Fallback title for recipe bubble
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get recipeTitleFallback;

  /// Title for Register form bubble
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// Title for Rider section
  ///
  /// In en, this message translates to:
  /// **'SUEFERY Rider App (Logistics Moat)'**
  String get riderTitle;

  /// Header for language selection
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Title for Sign In form bubble
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// Standard sign-up button
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpButton;

  /// Disclaimer for sign up
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Terms of Service and Privacy Policy.'**
  String get signUpDisclaimer;

  /// Status: Delivered
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// Button to suggest a recipe
  ///
  /// In en, this message translates to:
  /// **'Suggest Recipe'**
  String get suggestionButton;

  /// Button to switch to Customer interface
  ///
  /// In en, this message translates to:
  /// **'Switch to Customer View'**
  String get switchCustomer;

  /// Button to switch to Partner interface
  ///
  /// In en, this message translates to:
  /// **'Switch to Partner View'**
  String get switchPartner;

  /// Button to switch to Rider interface
  ///
  /// In en, this message translates to:
  /// **'Switch to Rider View'**
  String get switchRider;

  /// Tab for Gemini AI ordering
  ///
  /// In en, this message translates to:
  /// **'AI Orders'**
  String get tabAIOrder;

  /// Tab for browsing
  ///
  /// In en, this message translates to:
  /// **'Browse Stores'**
  String get tabBrowse;

  /// Status: To be confirmed
  ///
  /// In en, this message translates to:
  /// **'To be Confirmed'**
  String get toBeConfirmed;

  /// Link to navigate to Sign Up screen
  ///
  /// In en, this message translates to:
  /// **'To Signup'**
  String get toSignup;

  /// General total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Label for total price
  ///
  /// In en, this message translates to:
  /// **'Total Price {price} EGP'**
  String totalPrice(double price);

  /// Error for unhandled auth state
  ///
  /// In en, this message translates to:
  /// **'Unknown Authentication State.'**
  String get unknownAuthState;

  /// User email not verified warning
  ///
  /// In en, this message translates to:
  /// **'Email is not verified'**
  String get verificationNeeded;

  /// Button to go back to login
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get verifyEmailBackButton;

  /// Body text for email verification
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to your email. Please check your inbox (and spam folder) to continue.'**
  String get verifyEmailBody;

  /// Button to resend email
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get verifyEmailResendButton;

  /// Title for email verification screen
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// Greeting for the Customer
  ///
  /// In en, this message translates to:
  /// **'Welcome Customer! Start your Conversational Order (S1)'**
  String get welcomeCustomer;

  /// Prompt for new anonymous user
  ///
  /// In en, this message translates to:
  /// **'Ready to order? To save your history and place orders, please sign in or register below.'**
  String get welcomeFirstTimePrompt;

  /// Title for Lottie presentation
  ///
  /// In en, this message translates to:
  /// **'Here\'s a quick look at what I can do:'**
  String get welcomeLottieTitle;

  /// Simple welcome
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeMessage;

  /// Greeting for the Partner
  ///
  /// In en, this message translates to:
  /// **'Partner Dashboard'**
  String get welcomePartner;

  /// Prompt for returning anonymous user
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in or register to continue your session.'**
  String get welcomeReturningPrompt;

  /// Greeting for the Rider
  ///
  /// In en, this message translates to:
  /// **'Rider Dashboard'**
  String get welcomeRider;

  /// First message in anonymous welcome flow
  ///
  /// In en, this message translates to:
  /// **'👋 Welcome to SUEFEREY!'**
  String get welcomeTitle;

  /// Title for Setup
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setupTitle;

  /// Label for address
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// Label for city
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// Label for state
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateLabel;

  /// Label for zip code
  ///
  /// In en, this message translates to:
  /// **'Zip Code'**
  String get zipLabel;

  /// Button to complete setup
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// Label for confirm
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get confirm;

  /// Label for Add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Label for Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Label for Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Label for Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Label for Setup
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setup;

  /// Label for Order Progress
  ///
  /// In en, this message translates to:
  /// **'Order Progress'**
  String get orderProgress;

  /// Label for Item Name
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// Label for Item Price
  ///
  /// In en, this message translates to:
  /// **'Item Price'**
  String get itemPrice;

  /// Label for Quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Label for Unit
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// Label for Total Price
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get price;

  /// Label for Brand
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// Label for Notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  ///
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get deleteConfirmationMessage;

  /// Prompt for order deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete order {orderNumber}?'**
  String deleteOrderPrompt(String orderNumber);

  /// Message for order deletion
  ///
  /// In en, this message translates to:
  /// **'Order {orderNumber} has been deleted.'**
  String orderDeletedMessage(String orderNumber);
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
