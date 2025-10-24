import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Required for date formatting

/// The core class to handle string translation.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);
  static final supportedLocales = [
        Locale('en', ''), // English
        Locale('ar', ''), // arabic
  ];
  // Helper method to easily access the localization instance
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // --- Localization Data (Hardcoded Strings for AR and EN) ---
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'SUEFERY Multi-Role App',
      'customer_title': 'SUEFERY Customer App',
      'rider_title': 'SUEFERY Rider App (Logistics Moat)',
      'partner_title': 'SUEFERY Partner App',
      'welcome_customer': 'Welcome Customer! Start your Conversational Order (S1)',
      'welcome_rider': 'Rider Dashboard: Optimized Route to Next Order!',
      'welcome_partner': 'Partner Dashboard: New Order Received!',
      'switch_rider': 'Switch to Rider View',
      'switch_customer': 'Switch to Customer View',
      'switch_partner': 'Switch to Partner View',
      'language_switch': 'Switch Language (العربية)',
      'log_in_prompt': 'Please Log In',
      
      // NEW STRINGS FOR HISTORY SCREEN
      'history_title': 'Order History',
      'button_history': 'View Order History',
      'order_id': 'Order ID',
      'order_total': 'Total',
      'order_status': 'Status',
      'order_summary': 'Summary',
      'status_delivered': 'Delivered',
      'loading_history': 'Loading Order History...',
      'no_history': 'No past orders found.',
    },
    'ar': {
      'app_title': 'تطبيق سوإيفري متعدد الأدوار',
      'customer_title': 'تطبيق سوإيفري للعملاء',
      'rider_title': 'تطبيق سوإيفري للطيار (لوجستيات فائقة)',
      'partner_title': 'تطبيق سوإيفري للشركاء',
      'welcome_customer': 'مرحباً بالعميل! ابدأ طلبك الصوتي (S1)',
      'welcome_rider': 'لوحة تحكم الطيار: الطريق الأمثل للطلب التالي!',
      'welcome_partner': 'لوحة تحكم الشريك: تم استلام طلب جديد!',
      'switch_rider': 'التبديل إلى عرض الطيار',
      'switch_customer': 'التبديل إلى عرض العميل',
      'switch_partner': 'التبديل إلى عرض الشريك',
      'language_switch': 'تغيير اللغة (English)',
      'log_in_prompt': 'الرجاء تسجيل الدخول',
      
      // NEW STRINGS FOR HISTORY SCREEN
      'history_title': 'سجل الطلبات',
      'button_history': 'عرض سجل الطلبات',
      'order_id': 'رقم الطلب',
      'order_total': 'الإجمالي',
      'order_status': 'الحالة',
      'order_summary': 'الملخص',
      'status_delivered': 'تم التوصيل',
      'loading_history': 'جاري تحميل سجل الطلبات...',
      'no_history': 'لم يتم العثور على طلبات سابقة.',
    },
  };
  String get appTitle=> translate('app_title');
  String get customerTitle=> translate('customer_title');
  String get riderTitle=> translate('rider_title');
  String get partnerTitle=> translate('partner_title');
  String get welcomeCustomer=> translate('welcome_customer');
  String get welcomeRider=> translate('welcome_rider');
  String get welcomePartner=> translate('welcome_partner');
  String get switchRider=> translate('switch_rider');
  String get switchCustomer=> translate('switch_customer');
  String get switchPartner=> translate('switch_partner');
  String get languageSwitch=> translate('language_switch');
  String get logInPrompt=> translate('log_in_prompt');
  String get historyTitle=> translate('history_title');
  String get buttonHistory=> translate('button_history');
  String get orderId=> translate('order_id');
  String get orderTotal=> translate('order_total');
  String get orderStatus=> translate('order_status');
  String get orderSummary=> translate('order_summary');
  String get statusDelivered=> translate('status_delivered');
  String get loadingHistory=> translate('loading_history');
  String get noHistory=> translate('no_history');
  
  /// Translates a given key based on the current locale.
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  /// Formats the date based on the current locale.
  String formatDate(DateTime date) {
    return DateFormat.yMMMd(locale.languageCode).format(date);
  }
}

/// Custom delegate class required by the MaterialApp to load AppLocalizations.
class CustomLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const CustomLocalizationsDelegate();

  // Defines all supported language locales
  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Return a new instance of the AppLocalizations class
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(CustomLocalizationsDelegate old) => false;
}
