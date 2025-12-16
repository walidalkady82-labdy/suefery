// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get agree => 'موافق';

  @override
  String animationError(String error) {
    return 'لا يمكن تحميل الرسوم المتحركة: $error';
  }

  @override
  String get appBarTitle => 'سويفيري';

  @override
  String get appTitle => 'سويفيري';

  @override
  String get authHintChoice => 'اكتب \'تسجيل الدخول\' أو \'تسجيل\'';

  @override
  String get authHintEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get authHintPassword => 'أدخل كلمة المرور الخاصة بك';

  @override
  String get buttonHistory => 'عرض سجل الطلبات';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get chatHint => 'اكتب رسالة...';

  @override
  String get checkStatusButton => 'تحقق من الحالة';

  @override
  String get close => 'إغلاق';

  @override
  String get confirmAndPay => 'تأكيد و الدفع';

  @override
  String get confirmPasswordHint => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String currentLanguage(String currentLanguage) {
    return 'اللغة الحالية هي: $currentLanguage';
  }

  @override
  String get customerTitle => 'سويفيري تطبيق العميل';

  @override
  String get darkMode => 'تفعيل وضع الليلي';

  @override
  String get disagree => 'غير موافق';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'البريد الإلكتروني';

  @override
  String errorAuthFailed(String errorDetails) {
    return 'خطأ في التحقق: $errorDetails';
  }

  @override
  String errorFieldInvalid(String field) {
    return '$field غير صالح';
  }

  @override
  String errorFieldRequired(String field) {
    return '$field مطلوب';
  }

  @override
  String errorPasswordLength(int chars) {
    return 'يجب أن تكون كلمة المرور $chars أحرف أو أكثر';
  }

  @override
  String get errorPasswordMismatch => 'كلمات المرور غير متطابقة';

  @override
  String get fastestDeliveryZone => 'منطقة التوصيل الأسرع';

  @override
  String get firstNameLabel => 'الاسم الأول';

  @override
  String get googleSignin => 'تسجيل الدخول باستخدام جوجل';

  @override
  String get historyTitle => 'سجل الطلبات';

  @override
  String get languageSwitch => 'تبديل اللغة (English)';

  @override
  String get lastNameLabel => 'الاسم الأخير';

  @override
  String get loadingHistory => 'جارٍ تحميل سجل الطلبات...';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get logInPrompt => 'الرجاء تسجيل الدخول';

  @override
  String get logInScreenTitle => 'تسجيل الدخول بسويفري';

  @override
  String get loginTextButton => 'هل لديك حساب بالفعل؟ سجل الدخول';

  @override
  String get logoutTextButton => 'تسجيل الخروج';

  @override
  String get menuTooltip => 'القائمة';

  @override
  String get noHistory => 'لم يتم العثور على طلبات سابقة.';

  @override
  String get noOrders => 'لا يوجد طلبات';

  @override
  String orderConfirmedTitle(String orderNumber) {
    return 'تم تأكيد الطلب: #$orderNumber';
  }

  @override
  String get orderId => 'معرّف الطلب';

  @override
  String get orderStatus => 'الحالة';

  @override
  String get orderSummary => 'الملخص';

  @override
  String get orderTextButton => 'طلبات';

  @override
  String get orderTotal => 'المجموع';

  @override
  String get partnerStore => 'متجر شركاء';

  @override
  String get partnerTitle => 'سويفيري تطبيق الشريك';

  @override
  String get password => 'كلمة السر';

  @override
  String get passwordHint => 'كلمة المرور';

  @override
  String get paymentFailed => 'فشل الدفع أو تم إلغاء الطلب.';

  @override
  String get paymentPending => 'قيد الانتظار';

  @override
  String get paymentSuccessful => 'تم الدفع';

  @override
  String get pendingOrdersTextButton => 'طلبات قيد الانتظار';

  @override
  String get pendingOrderTermsBody =>
      '1. جميع المبيعات نهائية.\n 2. أوقات التسليم تقديرية.\n 3. الأسعار قابلة للتغيير دون إشعار.\n';

  @override
  String get pendingOrderTermsTitle => 'الشروط والاحكام';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get postVideoAuthPrompt => 'الرجاء تسجيل الدخول لتسليم الفيديو';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get promptConfirmPassword => 'أعد تأكيد كلمة المرور';

  @override
  String get promptEmail => 'الرجاء إدخال بريدك الإلكتروني';

  @override
  String get promptHelp => 'هل تريد مساعدة؟';

  @override
  String get promptPassword => 'الرجاء إدخال كلمة المرور الخاصة بك';

  @override
  String get promptSuggestRecipe => 'هل ترغب في اقتراح وصفة؟';

  @override
  String quantityLabel(int quantity) {
    return 'الكمية: #$quantity';
  }

  @override
  String get recipeName => 'اسم الوصفة';

  @override
  String get recipeNoIngredients => 'لا توجد مكونات مدرجة.';

  @override
  String get recipeTitleFallback => 'وصفة';

  @override
  String get registerTitle => 'التسجيل';

  @override
  String get riderTitle => 'سويفيري تطبيق الراكب (حصن اللوجستيات)';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get signUpButton => 'التسجيل';

  @override
  String get signUpDisclaimer =>
      'من خلال التسجيل، فإنك توافق على شروط الخدمة وسياسة الخصوصية الخاصة بنا.';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String get suggestionButton => 'مقترحات';

  @override
  String get switchCustomer => 'التحويل إلى عرض العميل';

  @override
  String get switchPartner => 'التحويل إلى عرض الشريك';

  @override
  String get switchRider => 'التحويل إلى عرض الراكب';

  @override
  String get tabAIOrder => 'أطلب';

  @override
  String get tabBrowse => 'فحص المتاجر';

  @override
  String get toBeConfirmed => 'قيد التأكيد';

  @override
  String get toSignup => 'للتسجيل';

  @override
  String get total => 'الإجمالى';

  @override
  String totalPrice(double price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.compactCurrency(locale: localeName, decimalDigits: 2);
    final String priceString = priceNumberFormat.format(price);

    return 'المجموع $priceString EGP';
  }

  @override
  String get unknownAuthState => 'حالة مصادقة غير معروفة.';

  @override
  String get verificationNeeded => 'البريد الإلكتروني لم يتم التحقق';

  @override
  String get verifyEmailBackButton => 'العودة لتسجيل الدخول';

  @override
  String get verifyEmailBody =>
      'لقد أرسلنا رابط تحقق إلى بريدك الإلكتروني. يرجى التحقق من صندوق الوارد (ومجلد الرسائل غير المرغوب فيها) للمتابعة.';

  @override
  String get verifyEmailResendButton => 'إعادة إرسال بريد التحقق';

  @override
  String get verifyEmailTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String get welcomeCustomer => 'أهلاً بك أيها العميل! ابدأ طلبك الحواري (S1)';

  @override
  String get welcomeFirstTimePrompt =>
      'هل أنت مستعد للطلب؟ لحفظ سجل طلباتك ولتتمكن من الطلب، يرجى تسجيل الدخول أو إنشاء حساب أدناه.';

  @override
  String get welcomeLottieTitle => 'إليك نظرة سريعة على ما يمكنني القيام به:';

  @override
  String get welcomeMessage => 'مرحبا!';

  @override
  String get welcomePartner => 'لوحة تحكم الشريك';

  @override
  String get welcomeReturningPrompt =>
      'مرحبًا بعودتك! يرجى تسجيل الدخول أو التسجيل لمتابعة جلستك.';

  @override
  String get welcomeRider => 'لوحة تحكم الراكب';

  @override
  String get welcomeTitle => '👋 مرحبًا بك في سويفرى!';

  @override
  String get setupTitle => 'الإعدادات';

  @override
  String get addressLabel => 'العنوان';

  @override
  String get cityLabel => 'المدينة';

  @override
  String get stateLabel => 'الولاية';

  @override
  String get zipLabel => 'الرمز البريدي';

  @override
  String get completeSetup => 'أكمل الإعدادات';

  @override
  String get confirm => 'تأكيد';

  @override
  String get add => 'إضافة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get save => 'حفظ';

  @override
  String get setup => 'الإعدادات';

  @override
  String get orderProgress => 'تقدم الطلب';

  @override
  String get itemName => 'اسم الصنف';

  @override
  String get itemPrice => 'السعر';

  @override
  String get quantity => 'الكمية';

  @override
  String get unit => 'الوحدة';

  @override
  String get price => 'السعر';

  @override
  String get brand => 'العلامة التجارية';

  @override
  String get notes => 'ملاحظات';

  @override
  String get deleteConfirmationMessage =>
      'هل أنت متأكد أنك تريد حذف هذا العنصر؟';

  @override
  String deleteOrderPrompt(String orderNumber) {
    return 'هل أنت متأكد أنك تريد حذف الطلب $orderNumber؟';
  }

  @override
  String orderDeletedMessage(String orderNumber) {
    return 'تم حذف الطلب $orderNumber.';
  }
}
