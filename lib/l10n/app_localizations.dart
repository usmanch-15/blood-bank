import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);
  static const delegate = _AppLocalizationsDelegate();
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  bool get _ur => locale.languageCode == 'ur';
  String _t(String en, String ur) => _ur ? ur : en;
  String get retry => _t('Retry', 'دوبارہ کوشش کریں');
  String get chatUnavailable =>
      _t('Chat is unavailable right now.', 'چیٹ دستیاب نہیں ہے');
  String get noMessages => _t(
    'No messages yet. Start a private conversation.',
    'ابھی کوئی پیغام نہیں۔ نجی گفتگو شروع کریں۔',
  );
  String get messageHint => _t('Message', 'پیغام');
  String get accountAccess => _t('Account access', 'اکاؤنٹ تک رسائی');
  String get backToLogin => _t('Back to login', 'لاگ ان پر واپس');
  String get activeAccountRequired => _t(
    'Sign in with an active account to access this page.',
    'اس صفحے تک رسائی کے لیے فعال اکاؤنٹ سے سائن ان کریں۔',
  );
  String get discardChanges =>
      _t('Discard unsaved changes?', 'محفوظ نہ کی گئی تبدیلیاں ختم کریں؟');
  String get keepEditing => _t('Keep editing', 'ترمیم جاری رکھیں');
  String get discard => _t('Discard', 'ختم کریں');
  String get tryAgain => _t('Try Again', 'دوبارہ کوشش کریں');
  String get refresh => _t('Refresh', 'تازہ کریں');
  String get loadMore => _t('Load more', 'مزید لوڈ کریں');
  String get somethingWentWrong => _t(
    'Something went wrong. Please try again.',
    'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔',
  );
  String get operationFailed => _t(
    'Operation failed. Please try again.',
    'عمل مکمل نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
  );
  String get verifyChangePhone =>
      _t('Verify / Change Phone', 'فون کی تصدیق / تبدیلی');
  String get phoneNotVerified =>
      _t('Your phone is not verified.', 'آپ کے فون کی تصدیق نہیں ہوئی۔');
  String verifiedPhone(String phone) =>
      _t('Verified phone: $phone', 'تصدیق شدہ فون: $phone');
  String get mobileNumber => _t('Mobile number', 'موبائل نمبر');
  String get sendVerificationCode =>
      _t('Send verification code', 'تصدیقی کوڈ بھیجیں');
  String get changeEmail => _t('Change Email', 'ای میل تبدیل کریں');
  String currentEmail(String email) =>
      _t('Current email: $email', 'موجودہ ای میل: $email');
  String get newEmailAddress => _t('New Email Address', 'نیا ای میل پتہ');
  String get enterNewEmail =>
      _t('Enter your new email address', 'نیا ای میل پتہ درج کریں');
  String get enterValidEmail =>
      _t('Enter a valid email address', 'درست ای میل پتہ درج کریں');
  String get emailAlreadyCurrent => _t(
    'This is already your current email',
    'یہ پہلے ہی آپ کا موجودہ ای میل ہے',
  );
  String get enterCurrentPassword => _t(
    'Enter your current password to confirm',
    'تصدیق کے لیے موجودہ پاس ورڈ درج کریں',
  );
  String get emailChangeSecurityNote => _t(
    "For your security, we'll send a confirmation link to your new email. Your login email won't change until you click that link.",
    'آپ کی حفاظت کے لیے نئے ای میل پر تصدیقی لنک بھیجا جائے گا۔ لنک کھولنے تک لاگ ان ای میل تبدیل نہیں ہوگی۔',
  );
  String get sendConfirmationLink =>
      _t('Send Confirmation Link', 'تصدیقی لنک بھیجیں');
  String get confirmationLinkSent =>
      _t('Confirmation link sent!', 'تصدیقی لنک بھیج دیا گیا!');
  String emailChangeConfirmation(String email) => _t(
    "We've sent a link to $email. Click it to finish changing your email. Until then, keep logging in with your current email.",
    'ہم نے $email پر لنک بھیج دیا ہے۔ ای میل تبدیل کرنے کے لیے لنک کھولیں۔ تب تک موجودہ ای میل سے لاگ ان کریں۔',
  );
  String get done => _t('Done', 'مکمل');
  String get passwordIncorrect => _t('Incorrect password.', 'پاس ورڈ غلط ہے۔');
  String get emailAlreadyUsed => _t(
    'That email is already used by another account.',
    'یہ ای میل پہلے ہی کسی اور اکاؤنٹ میں استعمال ہے۔',
  );
  String get reauthenticateRequired => _t(
    'Please log out and log back in, then try again.',
    'براہ کرم لاگ آؤٹ کر کے دوبارہ لاگ ان کریں، پھر کوشش کریں۔',
  );
  String get notifications => _t('Notifications', 'اطلاعات');
  String get unableToOpenNotification =>
      _t('Unable to open notification.', 'اطلاع کھولی نہیں جا سکی۔');
  String get chooseContinue => _t(
    'Choose an option to continue.',
    'جاری رکھنے کے لیے ایک آپشن منتخب کریں۔',
  );
  String get howCanHelp =>
      _t('How can we help\nyou today?', 'آج ہم آپ کی\nکیسے مدد کر سکتے ہیں؟');
  String get donorDashboard => _t('Donor Dashboard', 'عطیہ دہندہ ڈیش بورڈ');
  String get notificationsTooltip => _t('Notifications', 'اطلاعات');
  String get retryAction => _t('Retry', 'دوبارہ کوشش کریں');
  String get sosAlert => _t('SOS alert', 'ایس او ایس اطلاع');
  String get rateApp =>
      _t('Rate Smart Blood Bank', 'اسمارٹ بلڈ بینک کی درجہ بندی کریں');
  String get rateExperience => _t(
    'How would you rate your experience?',
    'آپ اپنے تجربے کو کیسے درجہ دیں گے؟',
  );
  String get submit => _t('Submit', 'جمع کریں');
  String get about => _t('About', 'تعارف');
  String version(String value) => _t('Version $value', 'ورژن $value');
  String get cancelAction => _t('Cancel', 'منسوخ کریں');
  String get welcomeBack => _t('Welcome Back', 'خوش آمدید');
  String get everyLoginCouldSave =>
      _t('Every login could save a life', 'ہر لاگ ان ایک زندگی بچا سکتا ہے');
  String get accountType => _t('Account type', 'اکاؤنٹ کی قسم');
  String get donor => _t('Donor', 'عطیہ دہندہ');
  String get receiver => _t('Receiver', 'خون وصول کنندہ');
  String get resetPassword => _t('Reset Password', 'پاس ورڈ ری سیٹ کریں');
  String get resetPasswordHint => _t(
    "Enter your email and we'll send a reset link.",
    'اپنی ای میل درج کریں، ہم ری سیٹ لنک بھیجیں گے۔',
  );
  String get emailHint => _t('your@email.com', 'your@email.com');
  String get resetLinkSent => _t(
    'Reset link sent! Check your inbox.',
    'ری سیٹ لنک بھیج دیا گیا! اپنا ان باکس چیک کریں۔',
  );
  String get sendLink => _t('Send Link', 'لنک بھیجیں');
  String get createRequestBeforeNotify => _t(
    'Create a blood request first to notify donors.',
    'عطیہ دہندگان کو اطلاع دینے سے پہلے خون کی درخواست بنائیں۔',
  );
  String get findNearbyDonors =>
      _t('Find Nearby Donors', 'قریبی عطیہ دہندگان تلاش کریں');
  String get notifyDonor => _t('Notify donor', 'عطیہ دہندہ کو اطلاع دیں');
  String get mapViewLabel => _t('Map view', 'نقشہ دیکھیں');
  String get listViewLabel => _t('List view', 'فہرست دیکھیں');
  String get searchDonorName =>
      _t('Search donor name', 'عطیہ دہندہ کا نام تلاش کریں');
  String get anyBloodGroup => _t('Any blood group', 'کوئی بھی خون کا گروپ');
  String compatibleWith(String group) =>
      _t('Compatible with $group', '$group کے لیے موزوں');
  String donorCountWithin(int count, int radius) => _t(
    '$count donors within $radius km',
    '$radius کلومیٹر کے اندر $count عطیہ دہندگان',
  );
  String get noCompatibleDonors => _t(
    'No available compatible donors in this radius. Try expanding it.',
    'اس دائرے میں کوئی دستیاب موزوں عطیہ دہندہ نہیں۔ دائرہ بڑھا کر دیکھیں۔',
  );
  String get trackRequest => _t('Track request', 'درخواست کو ٹریک کریں');
  String get notifyMatchingDonors =>
      _t('Notify matching donors', 'موزوں عطیہ دہندگان کو اطلاع دیں');
  String get queuing => _t('Queuing…', 'قطار میں شامل ہو رہا ہے…');
  String get askForSupport => _t('Ask for support', 'مدد طلب کریں');
  String get supportRequest => _t('Support request', 'مدد کی درخواست');
  String get subject => _t('Subject', 'موضوع');
  String get describeIssue => _t('Describe the issue', 'مسئلہ بیان کریں');
  String get helpSupport => _t('Help & Support', 'مدد اور معاونت');
  String get contactUs => _t('Contact Us', 'ہم سے رابطہ کریں');
  String get confirmActionPrompt =>
      _t('Please confirm this action.', 'براہ کرم اس کارروائی کی تصدیق کریں۔');
  String get back => _t('Back', 'واپس');
  String get confirm => _t('Confirm', 'تصدیق کریں');
  String get requestTracking => _t('Request Tracking', 'درخواست کی پیروی');
  String get callRequester => _t('Call requester', 'درخواست کنندہ کو کال کریں');
  String get callInApp => _t('Call in app', 'ایپ میں کال کریں');
  String get endCall => _t('End call', 'کال ختم کریں');
  String get answerCall => _t('Answer', 'جواب دیں');
  String get rejectCall => _t('Reject', 'مسترد کریں');
  String get callConnecting => _t('Connecting…', 'رابطہ قائم ہو رہا ہے…');
  String get callEnded => _t('Call ended', 'کال ختم ہو گئی');
  String get directionsMeetingPoint =>
      _t('Directions to meeting point', 'ملاقات کے مقام تک راستہ');
  String get donorAgreed =>
      _t('Yes, I agree to donate', 'ہاں، میں خون عطیہ کرنے پر متفق ہوں');
  String get donorDidNotAgree =>
      _t('No, I did not agree', 'نہیں، میں متفق نہیں ہوا');
  String get agreementPrompt => _t(
    'Did you agree to donate blood to this receiver?',
    'کیا آپ اس درخواست کنندہ کو خون دینے پر متفق ہیں؟',
  );
  String get donationAgreementPending => _t(
    'Donation agreement is pending.',
    'خون عطیہ کرنے کی رضامندی زیرِ التوا ہے۔',
  );
  String get acceptRespond => _t('Accept / Respond', 'قبول / جواب دیں');
  String get donatedRequestConfirmation => _t(
    'I donated — request confirmation',
    'میں نے خون عطیہ کیا — تصدیق کی درخواست کریں',
  );
  String get withdraw => _t('Withdraw', 'دستبردار ہوں');
  String get noDonorsResponded => _t(
    'No donors have responded yet.',
    'ابھی تک کسی عطیہ دہندہ نے جواب نہیں دیا۔',
  );
  String get contact => _t('Contact', 'رابطہ');
  String get chat => _t('Chat', 'چیٹ');
  String get bloodReceived => _t('Blood received', 'خون موصول ہو گیا');
  String get releaseReassign =>
      _t('Release / Reassign', 'جاری کریں / دوبارہ تفویض کریں');
  String get findAdditionalDonors =>
      _t('Find additional donors', 'مزید عطیہ دہندگان تلاش کریں');
  String get cancelRequest => _t('Cancel request', 'درخواست منسوخ کریں');
  String get resolveSos => _t('Resolve SOS', 'ایس او ایس حل کریں');
  String get timelineUnavailable =>
      _t('Timeline unavailable.', 'ٹائم لائن دستیاب نہیں۔');
  String get settingsTooltip => _t('Settings', 'ترتیبات');
  String get createBloodRequest =>
      _t('Create Blood Request', 'خون کی درخواست بنائیں');
  String get allRequestsHistory =>
      _t('All requests & history', 'تمام درخواستیں اور تاریخ');
  String get activeSosHistory =>
      _t('Active SOS & history', 'فعال ایس او ایس اور تاریخ');
  String get notLoggedIn => _t('Not logged in', 'لاگ ان نہیں ہے');
  String get noRequestsYet => _t('No requests yet', 'ابھی کوئی درخواست نہیں');
  String get cancelThisRequest =>
      _t('Cancel this request?', 'یہ درخواست منسوخ کریں؟');
  String get keepRequest => _t('Keep request', 'درخواست برقرار رکھیں');
  String get trackRequestDonors =>
      _t('Track request / donors', 'درخواست / عطیہ دہندگان کو ٹریک کریں');
  String get chooseLocation => _t('Choose location', 'مقام منتخب کریں');
  String get searchHospitalAddress =>
      _t('Search hospital or address', 'ہسپتال یا پتہ تلاش کریں');
  String get useCurrentLocation =>
      _t('Use current location', 'موجودہ مقام استعمال کریں');
  String get confirmLocation => _t('Confirm Location', 'مقام کی تصدیق کریں');
  String get selectHospitalPoint => _t(
    'Select and confirm the hospital meeting point.',
    'ہسپتال کا ملاقات کا مقام منتخب اور تصدیق کریں۔',
  );
  String get requiredDateMissing =>
      _t('Please select required by date', 'براہ کرم مطلوبہ تاریخ منتخب کریں');
  String get invalidAgeUnits =>
      _t('Enter valid age and units', 'درست عمر اور یونٹس درج کریں');
  String get requestSubmitted =>
      _t('Request submitted successfully!', 'درخواست کامیابی سے جمع ہو گئی!');
  String get requiredByDate => _t('Required By Date', 'مطلوبہ تاریخ');
  String get noRecords => _t('No records yet.', 'ابھی کوئی ریکارڈ نہیں۔');
  String get unableToLoadRecords => _t(
    'Unable to load records. Check your connection and retry.',
    'ریکارڈ لوڈ نہیں ہو سکے۔ کنکشن چیک کریں۔',
  );
  String get verifyEmail => _t('Verify Your Email', 'ای میل کی تصدیق کریں');
  String get verifyEmailMessage => _t(
    'Please verify your email before signing in.',
    'لاگ ان سے پہلے اپنی ای میل کی تصدیق کریں۔',
  );
  String get accountRejected =>
      _t('Account Rejected', 'اکاؤنٹ مسترد کر دیا گیا');
  String get accountRejectedMessage => _t(
    'Your account request was rejected. Contact support.',
    'آپ کی اکاؤنٹ درخواست مسترد کر دی گئی ہے۔ سپورٹ سے رابطہ کریں۔',
  );
  String get understood => _t('Understood', 'سمجھ گیا');
  String get donationHistory => _t('Donation History', 'عطیات کی تاریخ');
  String get pleaseSignIn => _t('Please sign in.', 'براہ کرم سائن ان کریں۔');
  String get requestUnavailable =>
      _t('Request unavailable', 'درخواست دستیاب نہیں');
  String get openRequestList => _t(
    'Open this request from your request list.',
    'یہ درخواست فہرست سے کھولیں۔',
  );
  String get login => _t('Login', 'لاگ ان');
  String get password => _t('Password', 'پاس ورڈ');
  String get adminEmail => _t('Admin Email', 'ایڈمن ای میل');
  String get forgotPassword => _t('Forgot Password?', 'پاس ورڈ بھول گئے؟');
  String get emailRequired => _t('Email is required', 'ای میل درج کریں');
  String get validEmailRequired =>
      _t('Enter a valid email', 'درست ای میل درج کریں');
  String get passwordRequired => _t('Password is required', 'پاس ورڈ درج کریں');
  String get passwordMinLength => _t(
    'Password must be at least 6 characters',
    'پاس ورڈ کم از کم 6 حروف کا ہو',
  );
  String get bloodRequests => _t('Blood Requests', 'خون کی درخواستیں');
  String get viewRequest => _t('View request', 'درخواست دیکھیں');
  String get radius => _t('Radius', 'دائرہ');
  String get noCompatibleRequests => _t(
    'No compatible active requests in this radius.',
    'اس دائرے میں کوئی موزوں فعال درخواست نہیں۔',
  );
  String get selectedLocation => _t('Selected location', 'منتخب مقام');
  String get registrationSuccessful =>
      _t('Registration Successful!', 'رجسٹریشن کامیاب');
  String get accountReady => _t(
    'Your account is ready. You can sign in now.',
    'آپ کا اکاؤنٹ تیار ہے۔ اب سائن ان کر سکتے ہیں۔',
  );
  String get within => _t('Within', 'حد کے اندر');
  String get urgency => _t('Urgency', 'اہمیت');
  String get critical => _t('Critical', 'انتہائی اہم');
  String get urgent => _t('Urgent', 'فوری');
  String get normal => _t('Normal', 'عام');
  String get mapView => _t('Map view', 'نقشہ دیکھیں');
  String get pleaseSignInShort => pleaseSignIn;
  String get noMatches => _t(
    'No matching requests found right now.',
    'اس وقت کوئی موزوں درخواست نہیں ملی۔',
  );
  String get updatePassword => _t('Update Password', 'پاس ورڈ اپ ڈیٹ کریں');
  String get showPassword => _t('Show password', 'پاس ورڈ دکھائیں');
  String get hidePassword => _t('Hide password', 'پاس ورڈ چھپائیں');
  String get reportMisuse => _t('Report Misuse', 'غلط استعمال کی رپورٹ');
  String get issuePrompt => _t("What's the issue?", 'مسئلہ کیا ہے؟');
  String get detailsOptional =>
      _t('Additional details (optional)', 'اضافی تفصیل (اختیاری)');
  String get cancel => _t('Cancel', 'منسوخ کریں');
  String get submitReport => _t('Submit Report', 'رپورٹ جمع کریں');
  String get verifyPhone => _t('Verify Phone Number', 'فون نمبر کی تصدیق کریں');
  String get verificationCode => _t('Verification code', 'تصدیقی کوڈ');
  String get verify => _t('Verify', 'تصدیق کریں');
  String get bloodGroupNeeded => _t('Blood group needed', 'مطلوبہ خون کا گروپ');
  String get hospitalMeetingPoint =>
      _t('Hospital / meeting point', 'ہسپتال / ملاقات کا مقام');
  String get contactNumber => _t('Contact number', 'رابطہ نمبر');
  String get sosEmergency => _t('SOS Emergency', 'ہنگامی SOS');
  String get retryLabel => retry;
  String get settings => _t('Settings', 'ترتیبات');
  String get changePassword => _t('Change Password', 'پاس ورڈ تبدیل کریں');
  String get currentPassword => _t('Current Password', 'موجودہ پاس ورڈ');
  String get newPassword => _t('New Password', 'نیا پاس ورڈ');
  String get confirmNewPassword =>
      _t('Confirm New Password', 'نیا پاس ورڈ دوبارہ درج کریں');
  String get passwordsDoNotMatch =>
      _t('Passwords do not match', 'پاس ورڈ مماثل نہیں ہیں');
  String get report => _t('Report', 'رپورٹ');
  String get reportSubmitted => _t(
    'Report submitted. Thank you for helping keep the community safe.',
    'رپورٹ جمع ہو گئی۔ کمیونٹی کو محفوظ رکھنے میں مدد کا شکریہ۔',
  );
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
