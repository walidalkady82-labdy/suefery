import 'package:flutter/widgets.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';

/// Comprehensive Enum representing every key in your ARB file.
/// Use this in Cubits/Blocs to keep logic decoupled from BuildContext.
enum AppStringKey {
  // --- Section A: Titles & Headings ---
  appTitle,
  appBarTitle,
  logInScreenTitle,
  signInTitle,
  registerTitle,
  profileTitle,
  settingsTitle,
  historyTitle,
  verifyEmailTitle,
  welcomeTitle,
  welcomeLottieTitle,
  recipeTitleFallback,
  pendingOrderTermsTitle,
  selectLanguage,

  // --- Section B: Labels & General Texts ---
  customerTitle,
  riderTitle,
  partnerTitle,
  welcomeMessage,
  welcomeCustomer,
  welcomeRider,
  welcomePartner,
  logInPrompt,
  
  // Methods (Require Args)
  currentLanguage,      // args[0]: language
  orderConfirmedTitle,  // args[0]: orderNumber
  quantityLabel,        // args[0]: quantity (int)

  recipeName,
  promptHelp,
  pendingOrderTermsBody,
  verifyEmailBody,

  // --- Section C: Buttons & Actions ---
  loginButton,
  signUpButton,
  googleSignin,
  logoutTextButton,
  close,
  agree,
  disagree,
  switchRider,
  switchCustomer,
  switchPartner,
  loginTextButton,
  toSignup,
  changeLanguage,
  languageSwitch,
  verifyEmailResendButton,
  verifyEmailBackButton,
  checkStatusButton,
  buttonHistory,
  cancelOrder,
  confirmAndPay,
  orderTextButton,
  pendingOrdersTextButton,
  suggestionButton,

  // --- Section D: Statuses & Data ---
  darkMode,
  tabAIOrder,
  tabBrowse,
  menuTooltip,
  orderId,
  orderTotal,
  total,
  orderStatus,
  orderSummary,
  statusDelivered,
  toBeConfirmed,
  fastestDeliveryZone,
  partnerStore,
  paymentFailed,
  paymentSuccessful,
  paymentPending,
  loadingHistory,
  noHistory,
  noOrders,
  recipeNoIngredients,

  // --- Section E: Hints & Prompts ---
  emailHint,
  passwordHint,
  confirmPasswordHint,
  chatHint,
  promptEmail,
  promptPassword,
  promptConfirmPassword,
  authHintChoice,
  authHintEmail,
  authHintPassword,
  welcomeFirstTimePrompt,
  welcomeReturningPrompt,
  promptSuggestRecipe,
  postVideoAuthPrompt,

  // --- Section F: Errors & Validation ---
  
  // Methods (Require Args)
  errorFieldRequired,   // args[0]: fieldName
  errorFieldInvalid,    // args[0]: fieldName
  errorPasswordLength,  // args[0]: length (int)
  
  errorPasswordMismatch,
  verificationNeeded,
  unknownAuthState,
  
  // Methods (Require Args)
  animationError,       // args[0]: error text
  errorAuthFailed,      // args[0]: details, args[1]: language/obj
}

/// Extension to convert the Enum directly into localized text using Context.
extension AppStringKeyX on AppStringKey {
  String resolve(BuildContext context, {List<String>? args}) {
    final strings = context.l10n; 

    switch (this) {
      // --- Section A ---
      case AppStringKey.appTitle: return strings.appTitle;
      case AppStringKey.appBarTitle: return strings.appBarTitle;
      case AppStringKey.logInScreenTitle: return strings.logInScreenTitle;
      case AppStringKey.signInTitle: return strings.signInTitle;
      case AppStringKey.registerTitle: return strings.registerTitle;
      case AppStringKey.profileTitle: return strings.profileTitle;
      case AppStringKey.settingsTitle: return strings.settingsTitle;
      case AppStringKey.historyTitle: return strings.historyTitle;
      case AppStringKey.verifyEmailTitle: return strings.verifyEmailTitle;
      case AppStringKey.welcomeTitle: return strings.welcomeTitle;
      case AppStringKey.welcomeLottieTitle: return strings.welcomeLottieTitle;
      case AppStringKey.recipeTitleFallback: return strings.recipeTitleFallback;
      case AppStringKey.pendingOrderTermsTitle: return strings.pendingOrderTermsTitle;
      case AppStringKey.selectLanguage: return strings.selectLanguage;

      // --- Section B ---
      case AppStringKey.customerTitle: return strings.customerTitle;
      case AppStringKey.riderTitle: return strings.riderTitle;
      case AppStringKey.partnerTitle: return strings.partnerTitle;
      case AppStringKey.welcomeMessage: return strings.welcomeMessage;
      case AppStringKey.welcomeCustomer: return strings.welcomeCustomer;
      case AppStringKey.welcomeRider: return strings.welcomeRider;
      case AppStringKey.welcomePartner: return strings.welcomePartner;
      case AppStringKey.logInPrompt: return strings.logInPrompt;

      case AppStringKey.currentLanguage:
        return strings.currentLanguage(_getArg(args, 0, ''));

      case AppStringKey.orderConfirmedTitle:
        return strings.orderConfirmedTitle(_getArg(args, 0, '#'));

      case AppStringKey.quantityLabel:
        return strings.quantityLabel(_getIntArg(args, 0, 0));

      case AppStringKey.recipeName: return strings.recipeName;
      case AppStringKey.promptHelp: return strings.promptHelp;
      case AppStringKey.pendingOrderTermsBody: return strings.pendingOrderTermsBody;
      case AppStringKey.verifyEmailBody: return strings.verifyEmailBody;

      // --- Section C ---
      case AppStringKey.loginButton: return strings.loginButton;
      case AppStringKey.signUpButton: return strings.signUpButton;
      case AppStringKey.googleSignin: return strings.googleSignin;
      case AppStringKey.logoutTextButton: return strings.logoutTextButton;
      case AppStringKey.close: return strings.close;
      case AppStringKey.agree: return strings.agree;
      case AppStringKey.disagree: return strings.disagree;
      case AppStringKey.switchRider: return strings.switchRider;
      case AppStringKey.switchCustomer: return strings.switchCustomer;
      case AppStringKey.switchPartner: return strings.switchPartner;
      case AppStringKey.loginTextButton: return strings.loginTextButton;
      case AppStringKey.toSignup: return strings.toSignup;
      case AppStringKey.changeLanguage: return strings.changeLanguage;
      case AppStringKey.languageSwitch: return strings.languageSwitch;
      case AppStringKey.verifyEmailResendButton: return strings.verifyEmailResendButton;
      case AppStringKey.verifyEmailBackButton: return strings.verifyEmailBackButton;
      case AppStringKey.checkStatusButton: return strings.checkStatusButton;
      case AppStringKey.buttonHistory: return strings.buttonHistory;
      case AppStringKey.cancelOrder: return strings.cancelOrder;
      case AppStringKey.confirmAndPay: return strings.confirmAndPay;
      case AppStringKey.orderTextButton: return strings.orderTextButton;
      case AppStringKey.pendingOrdersTextButton: return strings.pendingOrdersTextButton;
      case AppStringKey.suggestionButton: return strings.suggestionButton;

      // --- Section D ---
      case AppStringKey.darkMode: return strings.darkMode;
      case AppStringKey.tabAIOrder: return strings.tabAIOrder;
      case AppStringKey.tabBrowse: return strings.tabBrowse;
      case AppStringKey.menuTooltip: return strings.menuTooltip;
      case AppStringKey.orderId: return strings.orderId;
      case AppStringKey.orderTotal: return strings.orderTotal;
      case AppStringKey.total: return strings.total;
      case AppStringKey.orderStatus: return strings.orderStatus;
      case AppStringKey.orderSummary: return strings.orderSummary;
      case AppStringKey.statusDelivered: return strings.statusDelivered;
      case AppStringKey.toBeConfirmed: return strings.toBeConfirmed;
      case AppStringKey.fastestDeliveryZone: return strings.fastestDeliveryZone;
      case AppStringKey.partnerStore: return strings.partnerStore;
      case AppStringKey.paymentFailed: return strings.paymentFailed;
      case AppStringKey.paymentSuccessful: return strings.paymentSuccessful;
      case AppStringKey.paymentPending: return strings.paymentPending;
      case AppStringKey.loadingHistory: return strings.loadingHistory;
      case AppStringKey.noHistory: return strings.noHistory;
      case AppStringKey.noOrders: return strings.noOrders;
      case AppStringKey.recipeNoIngredients: return strings.recipeNoIngredients;

      // --- Section E ---
      case AppStringKey.emailHint: return strings.emailHint;
      case AppStringKey.passwordHint: return strings.passwordHint;
      case AppStringKey.confirmPasswordHint: return strings.confirmPasswordHint;
      case AppStringKey.chatHint: return strings.chatHint;
      case AppStringKey.promptEmail: return strings.promptEmail;
      case AppStringKey.promptPassword: return strings.promptPassword;
      case AppStringKey.promptConfirmPassword: return strings.promptConfirmPassword;
      case AppStringKey.authHintChoice: return strings.authHintChoice;
      case AppStringKey.authHintEmail: return strings.authHintEmail;
      case AppStringKey.authHintPassword: return strings.authHintPassword;
      case AppStringKey.welcomeFirstTimePrompt: return strings.welcomeFirstTimePrompt;
      case AppStringKey.welcomeReturningPrompt: return strings.welcomeReturningPrompt;
      case AppStringKey.promptSuggestRecipe: return strings.promptSuggestRecipe;
      case AppStringKey.postVideoAuthPrompt: return strings.postVideoAuthPrompt;

      // --- Section F ---
      case AppStringKey.errorFieldRequired:
        return strings.errorFieldRequired(_getArg(args, 0, 'Field'));

      case AppStringKey.errorFieldInvalid:
        return strings.errorFieldInvalid(_getArg(args, 0, 'Field'));

      case AppStringKey.errorPasswordLength:
        return strings.errorPasswordLength(_getIntArg(args, 0, 6));

      case AppStringKey.errorPasswordMismatch: return strings.errorPasswordMismatch;
      case AppStringKey.verificationNeeded: return strings.verificationNeeded;
      case AppStringKey.unknownAuthState: return strings.unknownAuthState;

      case AppStringKey.animationError:
        return strings.animationError(_getArg(args, 0, 'Error'));

      case AppStringKey.errorAuthFailed:
        return strings.errorAuthFailed(
          _getArg(args, 0, 'Error'),
        );
    }
  }

  // Helper to safely get string arguments
  String _getArg(List<String>? args, int index, String fallback) {
    if (args != null && args.length > index) {
      return args[index];
    }
    return fallback;
  }

  // Helper to safely get integer arguments
  int _getIntArg(List<String>? args, int index, int fallback) {
    if (args != null && args.length > index) {
      return int.tryParse(args[index]) ?? fallback;
    }
    return fallback;
  }
}