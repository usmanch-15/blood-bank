import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);
  static const delegate = _AppLocalizationsDelegate();
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  bool get _ur => locale.languageCode == 'ur';
  String get retry => _ur ? 'دوبارہ کوشش کریں' : 'Retry';
  String get chatUnavailable =>
      _ur ? 'چیٹ دستیاب نہیں ہے' : 'Chat is unavailable right now.';
  String get noMessages =>
      _ur
          ? 'ابھی کوئی پیغام نہیں'
          : 'No messages yet. Start a private conversation.';
  String get messageHint => _ur ? 'پیغام' : 'Message';
  String get accountAccess => _ur ? 'اکاؤنٹ تک رسائی' : 'Account access';
  String get backToLogin => _ur ? 'لاگ ان پر واپس' : 'Back to login';
  String get activeAccountRequired =>
      _ur
          ? 'فعال اکاؤنٹ سے سائن ان کریں'
          : 'Sign in with an active account to access this page.';
  String get discardChanges =>
      _ur ? 'محفوظ نہ کی گئی تبدیلیاں ختم کریں؟' : 'Discard unsaved changes?';
  String get keepEditing => _ur ? 'ترمیم جاری رکھیں' : 'Keep editing';
  String get discard => _ur ? 'ختم کریں' : 'Discard';
  String get tryAgain => _ur ? 'دوبارہ کوشش کریں' : 'Try Again';
  String get refresh => _ur ? 'تازہ کریں' : 'Refresh';
  String get loadMore => _ur ? 'مزید لوڈ کریں' : 'Load more';
  String get somethingWentWrong =>
      _ur
          ? 'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔'
          : 'Something went wrong. Please try again.';
  String get noRecords => _ur ? 'ابھی کوئی ریکارڈ نہیں۔' : 'No records yet.';
  String get unableToLoadRecords =>
      _ur
          ? 'ریکارڈ لوڈ نہیں ہو سکے۔'
          : 'Unable to load records. Check your connection and retry.';
  String get verifyEmail => _ur ? 'ای میل کی تصدیق کریں' : 'Verify Your Email';
  String get verifyEmailMessage =>
      _ur
          ? 'لاگ ان سے پہلے اپنی ای میل کی تصدیق کریں۔'
          : 'Please verify your email before signing in.';
  String get accountRejected =>
      _ur ? 'اکاؤنٹ مسترد کر دیا گیا' : 'Account Rejected';
  String get accountRejectedMessage =>
      _ur
          ? 'آپ کی اکاؤنٹ درخواست مسترد کر دی گئی ہے۔'
          : 'Your account request was rejected. Contact support.';
  String get understood => _ur ? 'سمجھ گیا' : 'Understood';
  String get donationHistory => _ur ? 'عطیات کی تاریخ' : 'Donation History';
  String get pleaseSignIn => _ur ? 'براہ کرم سائن ان کریں۔' : 'Please sign in.';
  String get requestUnavailable =>
      _ur ? 'درخواست دستیاب نہیں' : 'Request unavailable';
  String get openRequestList =>
      _ur
          ? 'یہ درخواست فہرست سے کھولیں۔'
          : 'Open this request from your request list.';
  String get login => _ur ? 'لاگ ان' : 'Login';
  String get password => _ur ? 'پاس ورڈ' : 'Password';
  String get adminEmail => _ur ? 'ایڈمن ای میل' : 'Admin Email';
  String get forgotPassword => _ur ? 'پاس ورڈ بھول گئے؟' : 'Forgot Password?';
  String get emailRequired => _ur ? 'ای میل درج کریں' : 'Email is required';
  String get validEmailRequired =>
      _ur ? 'درست ای میل درج کریں' : 'Enter a valid email';
  String get passwordRequired =>
      _ur ? 'پاس ورڈ درج کریں' : 'Password is required';
  String get passwordMinLength =>
      _ur
          ? 'پاس ورڈ کم از کم 6 حروف کا ہو'
          : 'Password must be at least 6 characters';
  String get bloodRequests => _ur ? 'خون کی درخواستیں' : 'Blood Requests';
  String get viewRequest => _ur ? 'درخواست دیکھیں' : 'View request';
  String get radius => _ur ? 'دائرہ' : 'Radius';
  String get noCompatibleRequests =>
      _ur
          ? 'اس دائرے میں کوئی موزوں فعال درخواست نہیں۔'
          : 'No compatible active requests in this radius.';
  String get selectedLocation => _ur ? 'منتخب مقام' : 'Selected location';
  String get registrationSuccessful =>
      _ur ? 'رجسٹریشن کامیاب' : 'Registration Successful!';
  String get accountReady =>
      _ur
          ? 'آپ کا اکاؤنٹ تیار ہے۔ اب سائن ان کر سکتے ہیں۔'
          : 'Your account is ready. You can sign in now.';
  String get within => _ur ? 'حد کے اندر' : 'Within';
  String get urgency => _ur ? 'اہمیت' : 'Urgency';
  String get critical => _ur ? 'انتہائی اہم' : 'Critical';
  String get urgent => _ur ? 'فوری' : 'Urgent';
  String get normal => _ur ? 'عام' : 'Normal';
  String get mapView => _ur ? 'نقشہ دیکھیں' : 'Map view';
  String get pleaseSignInShort =>
      _ur ? 'براہ کرم سائن ان کریں۔' : 'Please sign in.';
  String get noMatches =>
      _ur
          ? 'اس وقت کوئی موزوں درخواست نہیں ملی۔'
          : 'No matching requests found right now.';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'ur'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
