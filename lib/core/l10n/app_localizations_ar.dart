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
  String get logInScreenTitle => 'تسجيل الدخول بسويفري';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get loginTextButton => 'هل لديك حساب بالفعل؟ سجل الدخول';

  @override
  String get logoutTextButton => 'تسجيل الخروج';

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

  @override
  String get tabAIOrder => 'أطلب';

  @override
  String get tabBrowse => 'فحص المتاجر';

  @override
  String get partnerStore => 'متجر  شركاء';

  @override
  String get total => 'الإجمالى';

  @override
  String get fastestDeliveryZone => 'منطقة التوصيل الأسرع';

  @override
  String get verificationNeeded => 'البريد الإلكتروني لم يتم التحقق';

  @override
  String get checkStatusButton => 'تحقق من الحالة';

  @override
  String get welcomeMessage => 'مرحبا!';

  @override
  String get suggestionButton => 'مقترحات';

  @override
  String get recipeName => 'اسم الوصف';

  @override
  String get orderHistoryTitle => 'سجل الطلبات';

  @override
  String get noOrders => 'لا يوجد طلبات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String currentLanguage(String currentLanguage) {
    return 'اللغة الحالية هي: $currentLanguage';
  }

  @override
  String get darkMode => 'تفعيل وضع الليلي';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get pendingOrdersTextButton => 'طلبات قيد الانتظار';

  @override
  String get orderTextButton => 'طلبات';

  @override
  String get appBarTitle => 'الشيف جيميناي';

  @override
  String get welcomeTitle => '👋 مرحبًا بك في مساعد الشيف!';

  @override
  String get welcomeLottieTitle => 'إليك نظرة سريعة على ما يمكنني القيام به:';

  @override
  String get welcomeFirstTimePrompt =>
      'هل أنت مستعد للطلب؟ لحفظ سجل طلباتك ولتتمكن من الطلب، يرجى تسجيل الدخول أو إنشاء حساب أدناه.';

  @override
  String get welcomeReturningPrompt =>
      'مرحبًا بعودتك! يرجى تسجيل الدخول أو التسجيل لمتابعة جلستك.';

  @override
  String animationError(String error) {
    return 'لا يمكن تحميل الرسوم المتحركة: $error';
  }

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get registerTitle => 'التسجيل';

  @override
  String get verifyEmailTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String get verifyEmailBody =>
      'لقد أرسلنا رابط تحقق إلى بريدك الإلكتروني. يرجى التحقق من صندوق الوارد (ومجلد الرسائل غير المرغوب فيها) للمتابعة.';

  @override
  String get verifyEmailResendButton => 'إعادة إرسال بريد التحقق';

  @override
  String get verifyEmailBackButton => 'العودة لتسجيل الدخول';

  @override
  String get recipeTitleFallback => 'وصفة';

  @override
  String get recipeNoIngredients => 'لا توجد مكونات مدرجة.';

  @override
  String get unknownAuthState => 'حالة مصادقة غير معروفة.';

  @override
  String get menuTooltip => 'القائمة';

  @override
  String get chatHint => 'اكتب رسالة...';

  @override
  String get authHintChoice => 'اكتب \'تسجيل الدخول\' أو \'تسجيل\'';

  @override
  String get authHintEmail => 'أدخل بريدك الإلكتروني...';

  @override
  String get authHintPassword => 'أدخل كلمة المرور الخاصة بك...';

  @override
  String get authHintConfirmPassword => 'أعد تأكيد كلمة المرور...';
}
