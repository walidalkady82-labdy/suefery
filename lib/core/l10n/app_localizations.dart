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

  /// The main title for the complete multi-role application.
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

  /// The text for the standard login button.
  ///
  /// In en, this message translates to:
  /// **'login'**
  String get loginButton;

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
