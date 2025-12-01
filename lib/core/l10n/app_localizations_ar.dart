// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get sectionA => '___TITLES_AND_HEADINGS___';

  @override
  String get appTitle => 'سويفيري تطبيق متعدد الأدوار';

  @override
  String get appBarTitle => 'الشيف جيميناي';

  @override
  String get logInScreenTitle => 'تسجيل الدخول بسويفري';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get registerTitle => 'التسجيل';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get historyTitle => 'سجل الطلبات';

  @override
  String get verifyEmailTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String get welcomeTitle => '👋 مرحبًا بك في سويفرى!';

  @override
  String get welcomeLottieTitle => 'إليك نظرة سريعة على ما يمكنني القيام به:';

  @override
  String get recipeTitleFallback => 'وصفة';

  @override
  String get pendingOrderTermsTitle => 'الشروط والاحكام';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get sectionB => '___LABELS_AND_GENERAL_TEXTS___';

  @override
  String get customerTitle => 'سويفيري تطبيق العميل';

  @override
  String get riderTitle => 'سويفيري تطبيق الراكب (حصن اللوجستيات)';

  @override
  String get partnerTitle => 'سويفيري تطبيق الشريك';

  @override
  String get welcomeMessage => 'مرحبا!';

  @override
  String get welcomeCustomer => 'أهلاً بك أيها العميل! ابدأ طلبك الحواري (S1)';

  @override
  String get welcomeRider => 'لوحة تحكم الراكب';

  @override
  String get welcomePartner => 'لوحة تحكم الشريك';

  @override
  String get logInPrompt => 'الرجاء تسجيل الدخول';

  @override
  String currentLanguage(String currentLanguage) {
    return 'اللغة الحالية هي: $currentLanguage';
  }

  @override
  String orderConfirmedTitle(String orderNumber) {
    return 'تم تأكيد الطلب: #$orderNumber';
  }

  @override
  String quantityLabel(int quantity) {
    return 'الكمية: #$quantity';
  }

  @override
  String get recipeName => 'اسم الوصفة';

  @override
  String get promptHelp => 'هل تريد مساعدة؟';

  @override
  String get pendingOrderTermsBody =>
      '1. جميع المبيعات نهائية.\n 2. أوقات التسليم تقديرية.\n 3. الأسعار قابلة للتغيير دون إشعار.\n';

  @override
  String get verifyEmailBody =>
      'لقد أرسلنا رابط تحقق إلى بريدك الإلكتروني. يرجى التحقق من صندوق الوارد (ومجلد الرسائل غير المرغوب فيها) للمتابعة.';

  @override
  String get sectionC => '___BUTTONS_AND_ACTIONS___';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get signUpButton => 'التسجيل';

  @override
  String get googleSignin => 'تسجيل الدخول باستخدام جوجل';

  @override
  String get logoutTextButton => 'تسجيل الخروج';

  @override
  String get close => 'إغلاق';

  @override
  String get agree => 'موافق';

  @override
  String get disagree => 'غير موافق';

  @override
  String get switchRider => 'التحويل إلى عرض الراكب';

  @override
  String get switchCustomer => 'التحويل إلى عرض العميل';

  @override
  String get switchPartner => 'التحويل إلى عرض الشريك';

  @override
  String get loginTextButton => 'هل لديك حساب بالفعل؟ سجل الدخول';

  @override
  String get toSignup => 'للتسجيل';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get languageSwitch => 'تبديل اللغة (English)';

  @override
  String get verifyEmailResendButton => 'إعادة إرسال بريد التحقق';

  @override
  String get verifyEmailBackButton => 'العودة لتسجيل الدخول';

  @override
  String get checkStatusButton => 'تحقق من الحالة';

  @override
  String get buttonHistory => 'عرض سجل الطلبات';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get confirmAndPay => 'تأكيد و الدفع';

  @override
  String get orderTextButton => 'طلبات';

  @override
  String get pendingOrdersTextButton => 'طلبات قيد الانتظار';

  @override
  String get suggestionButton => 'مقترحات';

  @override
  String get sectionD => '___LABELS_STATUSES_AND_DATA___';

  @override
  String get darkMode => 'تفعيل وضع الليلي';

  @override
  String get tabAIOrder => 'أطلب';

  @override
  String get tabBrowse => 'فحص المتاجر';

  @override
  String get menuTooltip => 'القائمة';

  @override
  String get orderId => 'معرّف الطلب';

  @override
  String get orderTotal => 'المجموع';

  @override
  String get total => 'الإجمالى';

  @override
  String get orderStatus => 'الحالة';

  @override
  String get orderSummary => 'الملخص';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String get toBeConfirmed => 'قيد التأكيد';

  @override
  String get fastestDeliveryZone => 'منطقة التوصيل الأسرع';

  @override
  String get partnerStore => 'متجر شركاء';

  @override
  String get paymentFailed => 'فشل الدفع أو تم إلغاء الطلب.';

  @override
  String get paymentSuccessful => 'تم الدفع';

  @override
  String get paymentPending => 'قيد الانتظار';

  @override
  String get loadingHistory => 'جارٍ تحميل سجل الطلبات...';

  @override
  String get noHistory => 'لم يتم العثور على طلبات سابقة.';

  @override
  String get noOrders => 'لا يوجد طلبات';

  @override
  String get recipeNoIngredients => 'لا توجد مكونات مدرجة.';

  @override
  String get sectionE => '___HINTS_AND_PROMPTS___';

  @override
  String get emailHint => 'البريد الإلكتروني';

  @override
  String get passwordHint => 'كلمة المرور';

  @override
  String get confirmPasswordHint => 'تأكيد كلمة المرور';

  @override
  String get chatHint => 'اكتب رسالة...';

  @override
  String get promptEmail => 'الرجاء إدخال بريدك الإلكتروني';

  @override
  String get promptPassword => 'الرجاء إدخال كلمة المرور الخاصة بك';

  @override
  String get promptConfirmPassword => 'أعد تأكيد كلمة المرور';

  @override
  String get authHintChoice => 'اكتب \'تسجيل الدخول\' أو \'تسجيل\'';

  @override
  String get authHintEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get authHintPassword => 'أدخل كلمة المرور الخاصة بك';

  @override
  String get welcomeFirstTimePrompt =>
      'هل أنت مستعد للطلب؟ لحفظ سجل طلباتك ولتتمكن من الطلب، يرجى تسجيل الدخول أو إنشاء حساب أدناه.';

  @override
  String get welcomeReturningPrompt =>
      'مرحبًا بعودتك! يرجى تسجيل الدخول أو التسجيل لمتابعة جلستك.';

  @override
  String get promptSuggestRecipe => 'هل ترغب في اقتراح وصفة؟';

  @override
  String get postVideoAuthPrompt => 'الرجاء تسجيل الدخول لتسليم الفيديو';

  @override
  String get sectionF => '___ERRORS_AND_VALIDATION___';

  @override
  String errorFieldRequired(String field) {
    return '$field مطلوب';
  }

  @override
  String errorFieldInvalid(String field) {
    return '$field غير صالح';
  }

  @override
  String errorPasswordLength(int chars) {
    return 'يجب أن تكون كلمة المرور $chars أحرف أو أكثر';
  }

  @override
  String get errorPasswordMismatch => 'كلمات المرور غير متطابقة';

  @override
  String get verificationNeeded => 'البريد الإلكتروني لم يتم التحقق';

  @override
  String get unknownAuthState => 'حالة مصادقة غير معروفة.';

  @override
  String animationError(String error) {
    return 'لا يمكن تحميل الرسوم المتحركة: $error';
  }

  @override
  String errorAuthFailed(String errorDetails, Object currentLanguage) {
    return 'خطأ في التحقق: $currentLanguage';
  }
}
