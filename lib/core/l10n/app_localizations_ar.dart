// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سويفيري تطبيق متعدد الأدوار';

  @override
  String get customerTitle => 'سويفيري تطبيق العميل';

  @override
  String get riderTitle => 'سويفيري تطبيق الراكب (حصن اللوجستيات)';

  @override
  String get partnerTitle => 'سويفيري تطبيق الشريك';

  @override
  String get welcomeCustomer => 'أهلاً بك أيها العميل! ابدأ طلبك الحواري (S1)';

  @override
  String get welcomeRider => 'لوحة تحكم الراكب';

  @override
  String get welcomePartner => 'لوحة تحكم الشريك';

  @override
  String get switchRider => 'التحويل إلى عرض الراكب';

  @override
  String get switchCustomer => 'التحويل إلى عرض العميل';

  @override
  String get switchPartner => 'التحويل إلى عرض الشريك';

  @override
  String get languageSwitch => 'تبديل اللغة (English)';

  @override
  String get logInPrompt => 'الرجاء تسجيل الدخول';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get signUpButton => 'التسجيل';

  @override
  String get googleSignin => 'تسجيل الدخول باستخدام جوجل';

  @override
  String get toSignup => 'للتسجيل';

  @override
  String get emailHint => 'البريد الإلكتروني';

  @override
  String get passwordHint => 'كلمة المرور';

  @override
  String get confirmPasswordHint => 'تأكيد كلمة المرور';

  @override
  String get historyTitle => 'سجل الطلبات';

  @override
  String get buttonHistory => 'عرض سجل الطلبات';

  @override
  String get orderId => 'معرّف الطلب';

  @override
  String get orderTotal => 'المجموع';

  @override
  String get orderStatus => 'الحالة';

  @override
  String get orderSummary => 'الملخص';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String get loadingHistory => 'جارٍ تحميل سجل الطلبات...';

  @override
  String get noHistory => 'لم يتم العثور على طلبات سابقة.';

  @override
  String get emailRequiredErrorMessage => 'البريد الإلكتروني مطلوب';

  @override
  String get emailInvalidErrorMessage => 'البريد الإلكتروني غير صالح';

  @override
  String get passwordRequiredErrorMessage => 'كلمة المرور مطلوبة';
}
