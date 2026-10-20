import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);
  static const delegate = _AppLocalizationsDelegate();
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  bool get _ur => locale.languageCode == 'ur';
  String _t(String en, String ur) => _ur ? ur : en;
  String get locationInsidePakistan => _t(
    'Select a location inside Pakistan.',
    'Ù¾Ø§Ú©Ø³ØªØ§Ù† Ú©Û’ Ø§Ù†Ø¯Ø± Ù…Ù‚Ø§Ù… Ù…Ù†ØªØ®Ø¨ Ú©Ø±ÛŒÚºÛ”',
  );
  String get microphoneRequired => _t(
    'Microphone permission is required. Enable it in app settings and retry.',
    'Ù…Ø§Ø¦ÛŒÚ©Ø±ÙˆÙÙˆÙ† Ú©ÛŒ Ø§Ø¬Ø§Ø²Øª Ø¶Ø±ÙˆØ±ÛŒ ÛÛ’Û” Ø§ÛŒÙ¾ Ú©ÛŒ ØªØ±ØªÛŒØ¨Ø§Øª Ù…ÛŒÚº Ø§Ø¬Ø§Ø²Øª Ø¯Û’ Ú©Ø± Ø¯ÙˆØ¨Ø§Ø±Û Ú©ÙˆØ´Ø´ Ú©Ø±ÛŒÚºÛ”',
  );
  String get callRinging => _t('Incoming call', 'Ø¢Ù†Û’ ÙˆØ§Ù„ÛŒ Ú©Ø§Ù„');
  String donorsQueued(int count, int remaining) => _t(
    '$count donor inboxes queued. $remaining remaining; tap notify again to continue. Delivery is not guaranteed.',
    '$count Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Ú¯Ø§Ù† Ú©Ùˆ Ø§Ø·Ù„Ø§Ø¹ Ø¨Ú¾ÛŒØ¬Ù†Û’ Ú©ÛŒ Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ø¯ÛŒ Ú¯Ø¦ÛŒÛ” $remaining Ø¨Ø§Ù‚ÛŒ ÛÛŒÚºØ› Ø¬Ø§Ø±ÛŒ Ø±Ú©Ú¾Ù†Û’ Ú©Û’ Ù„ÛŒÛ’ Ø¯ÙˆØ¨Ø§Ø±Û Ø¯Ø¨Ø§Ø¦ÛŒÚºÛ” ØªØ±Ø³ÛŒÙ„ Ú©ÛŒ Ø¶Ù…Ø§Ù†Øª Ù†ÛÛŒÚºÛ”',
  );
  String donorApproximateDistance(String km) =>
      _t('Approximately $km km â€¢ Available', 'ØªÙ‚Ø±ÛŒØ¨Ø§Ù‹ $km Ú©Ù„ÙˆÙ…ÛŒÙ¹Ø± â€¢ Ø¯Ø³ØªÛŒØ§Ø¨');
  String get retry => _t('Retry', 'Ø¯ÙˆØ¨Ø§Ø±Û Ú©ÙˆØ´Ø´ Ú©Ø±ÛŒÚº');
  String get matchingMedicalNote => _t(
    'Compatible blood is not medical clearance. Qualified healthcare staff confirm final eligibility.',
    'Qualified healthcare staff confirm final eligibility.',
  );
  String get callUnavailableUntilAcceptance => _t(
    'In-app calling before donor acceptance will be available in Stage F.',
    'In-app calling before donor acceptance will be available in Stage F.',
  );
  String get sendRequest => _t('Send request', 'Send request');
  String get chatUnavailable =>
      _t('Chat is unavailable right now.', 'Ú†ÛŒÙ¹ Ø¯Ø³ØªÛŒØ§Ø¨ Ù†ÛÛŒÚº ÛÛ’');
  String get noMessages => _t(
    'No messages yet. Start a private conversation.',
    'Ø§Ø¨Ú¾ÛŒ Ú©ÙˆØ¦ÛŒ Ù¾ÛŒØºØ§Ù… Ù†ÛÛŒÚºÛ” Ù†Ø¬ÛŒ Ú¯ÙØªÚ¯Ùˆ Ø´Ø±ÙˆØ¹ Ú©Ø±ÛŒÚºÛ”',
  );
  String get messageHint => _t('Message', 'Ù¾ÛŒØºØ§Ù…');
  String get accountAccess => _t('Account access', 'Ø§Ú©Ø§Ø¤Ù†Ù¹ ØªÚ© Ø±Ø³Ø§Ø¦ÛŒ');
  String get backToLogin => _t('Back to login', 'Ù„Ø§Ú¯ Ø§Ù† Ù¾Ø± ÙˆØ§Ù¾Ø³');
  String get activeAccountRequired => _t(
    'Sign in with an active account to access this page.',
    'Ø§Ø³ ØµÙØ­Û’ ØªÚ© Ø±Ø³Ø§Ø¦ÛŒ Ú©Û’ Ù„ÛŒÛ’ ÙØ¹Ø§Ù„ Ø§Ú©Ø§Ø¤Ù†Ù¹ Ø³Û’ Ø³Ø§Ø¦Ù† Ø§Ù† Ú©Ø±ÛŒÚºÛ”',
  );
  String get discardChanges =>
      _t('Discard unsaved changes?', 'Ù…Ø­ÙÙˆØ¸ Ù†Û Ú©ÛŒ Ú¯Ø¦ÛŒ ØªØ¨Ø¯ÛŒÙ„ÛŒØ§Úº Ø®ØªÙ… Ú©Ø±ÛŒÚºØŸ');
  String get keepEditing => _t('Keep editing', 'ØªØ±Ù…ÛŒÙ… Ø¬Ø§Ø±ÛŒ Ø±Ú©Ú¾ÛŒÚº');
  String get discard => _t('Discard', 'Ø®ØªÙ… Ú©Ø±ÛŒÚº');
  String get tryAgain => _t('Try Again', 'Ø¯ÙˆØ¨Ø§Ø±Û Ú©ÙˆØ´Ø´ Ú©Ø±ÛŒÚº');
  String get refresh => _t('Refresh', 'ØªØ§Ø²Û Ú©Ø±ÛŒÚº');
  String get loadMore => _t('Load more', 'Ù…Ø²ÛŒØ¯ Ù„ÙˆÚˆ Ú©Ø±ÛŒÚº');
  String get somethingWentWrong => _t(
    'Something went wrong. Please try again.',
    'Ú©Ú†Ú¾ ØºÙ„Ø· ÛÙˆ Ú¯ÛŒØ§Û” Ø¯ÙˆØ¨Ø§Ø±Û Ú©ÙˆØ´Ø´ Ú©Ø±ÛŒÚºÛ”',
  );
  String get offlineMessage => _t('You are offline. Reconnect and retry.', 'Ø¢Ù¾ Ø¢Ù Ù„Ø§Ø¦Ù† ÛÛŒÚºÛ” Ø¯ÙˆØ¨Ø§Ø±Û Ù…Ù†Ø³Ù„Ú© ÛÙˆ Ú©Ø± Ú©ÙˆØ´Ø´ Ú©Ø±ÛŒÚºÛ”');
  String get permissionSettingsHint => _t('Enable this permission in system settings, then try again.', 'ÛŒÛ Ø§Ø¬Ø§Ø²Øª Ø³Ø³Ù¹Ù… Ú©ÛŒ ØªØ±ØªÛŒØ¨Ø§Øª Ù…ÛŒÚº ÙØ¹Ø§Ù„ Ú©Ø±ÛŒÚºØŒ Ù¾Ú¾Ø± Ø¯ÙˆØ¨Ø§Ø±Û Ú©ÙˆØ´Ø´ Ú©Ø±ÛŒÚºÛ”');
  String get openSettings => _t('Open settings', 'ØªØ±ØªÛŒØ¨Ø§Øª Ú©Ú¾ÙˆÙ„ÛŒÚº');
  String get noResponses => _t('No responses yet.', 'Ø§Ø¨Ú¾ÛŒ Ú©ÙˆØ¦ÛŒ Ø¬ÙˆØ§Ø¨ Ù†ÛÛŒÚºÛ”');
  String get responsesLoadFailed => _t('Unable to load responses.', 'Ø¬ÙˆØ§Ø¨Ø§Øª Ù„ÙˆÚˆ Ù†ÛÛŒÚº ÛÙˆ Ø³Ú©Û’Û”');
  String get operationFailed => _t(
    'Operation failed. Please try again.',
    'Ø¹Ù…Ù„ Ù…Ú©Ù…Ù„ Ù†ÛÛŒÚº ÛÙˆ Ø³Ú©Ø§Û” Ø¯ÙˆØ¨Ø§Ø±Û Ú©ÙˆØ´Ø´ Ú©Ø±ÛŒÚºÛ”',
  );
  String get verifyChangePhone =>
      _t('Verify / Change Phone', 'ÙÙˆÙ† Ú©ÛŒ ØªØµØ¯ÛŒÙ‚ / ØªØ¨Ø¯ÛŒÙ„ÛŒ');
  String get phoneNotVerified =>
      _t('Your phone is not verified.', 'Ø¢Ù¾ Ú©Û’ ÙÙˆÙ† Ú©ÛŒ ØªØµØ¯ÛŒÙ‚ Ù†ÛÛŒÚº ÛÙˆØ¦ÛŒÛ”');
  String verifiedPhone(String phone) =>
      _t('Verified phone: $phone', 'ØªØµØ¯ÛŒÙ‚ Ø´Ø¯Û ÙÙˆÙ†: $phone');
  String get mobileNumber => _t('Mobile number', 'Ù…ÙˆØ¨Ø§Ø¦Ù„ Ù†Ù…Ø¨Ø±');
  String get sendVerificationCode =>
      _t('Send verification code', 'ØªØµØ¯ÛŒÙ‚ÛŒ Ú©ÙˆÚˆ Ø¨Ú¾ÛŒØ¬ÛŒÚº');
  String get changeEmail => _t('Change Email', 'Ø§ÛŒ Ù…ÛŒÙ„ ØªØ¨Ø¯ÛŒÙ„ Ú©Ø±ÛŒÚº');
  String currentEmail(String email) =>
      _t('Current email: $email', 'Ù…ÙˆØ¬ÙˆØ¯Û Ø§ÛŒ Ù…ÛŒÙ„: $email');
  String get newEmailAddress => _t('New Email Address', 'Ù†ÛŒØ§ Ø§ÛŒ Ù…ÛŒÙ„ Ù¾ØªÛ');
  String get enterNewEmail =>
      _t('Enter your new email address', 'Ù†ÛŒØ§ Ø§ÛŒ Ù…ÛŒÙ„ Ù¾ØªÛ Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº');
  String get enterValidEmail =>
      _t('Enter a valid email address', 'Ø¯Ø±Ø³Øª Ø§ÛŒ Ù…ÛŒÙ„ Ù¾ØªÛ Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº');
  String get emailAlreadyCurrent => _t(
    'This is already your current email',
    'ÛŒÛ Ù¾ÛÙ„Û’ ÛÛŒ Ø¢Ù¾ Ú©Ø§ Ù…ÙˆØ¬ÙˆØ¯Û Ø§ÛŒ Ù…ÛŒÙ„ ÛÛ’',
  );
  String get enterCurrentPassword => _t(
    'Enter your current password to confirm',
    'ØªØµØ¯ÛŒÙ‚ Ú©Û’ Ù„ÛŒÛ’ Ù…ÙˆØ¬ÙˆØ¯Û Ù¾Ø§Ø³ ÙˆØ±Úˆ Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº',
  );
  String get emailChangeSecurityNote => _t(
    "For your security, we'll send a confirmation link to your new email. Your login email won't change until you click that link.",
    'Ø¢Ù¾ Ú©ÛŒ Ø­ÙØ§Ø¸Øª Ú©Û’ Ù„ÛŒÛ’ Ù†Ø¦Û’ Ø§ÛŒ Ù…ÛŒÙ„ Ù¾Ø± ØªØµØ¯ÛŒÙ‚ÛŒ Ù„Ù†Ú© Ø¨Ú¾ÛŒØ¬Ø§ Ø¬Ø§Ø¦Û’ Ú¯Ø§Û” Ù„Ù†Ú© Ú©Ú¾ÙˆÙ„Ù†Û’ ØªÚ© Ù„Ø§Ú¯ Ø§Ù† Ø§ÛŒ Ù…ÛŒÙ„ ØªØ¨Ø¯ÛŒÙ„ Ù†ÛÛŒÚº ÛÙˆÚ¯ÛŒÛ”',
  );
  String get sendConfirmationLink =>
      _t('Send Confirmation Link', 'ØªØµØ¯ÛŒÙ‚ÛŒ Ù„Ù†Ú© Ø¨Ú¾ÛŒØ¬ÛŒÚº');
  String get confirmationLinkSent =>
      _t('Confirmation link sent!', 'ØªØµØ¯ÛŒÙ‚ÛŒ Ù„Ù†Ú© Ø¨Ú¾ÛŒØ¬ Ø¯ÛŒØ§ Ú¯ÛŒØ§!');
  String emailChangeConfirmation(String email) => _t(
    "We've sent a link to $email. Click it to finish changing your email. Until then, keep logging in with your current email.",
    'ÛÙ… Ù†Û’ $email Ù¾Ø± Ù„Ù†Ú© Ø¨Ú¾ÛŒØ¬ Ø¯ÛŒØ§ ÛÛ’Û” Ø§ÛŒ Ù…ÛŒÙ„ ØªØ¨Ø¯ÛŒÙ„ Ú©Ø±Ù†Û’ Ú©Û’ Ù„ÛŒÛ’ Ù„Ù†Ú© Ú©Ú¾ÙˆÙ„ÛŒÚºÛ” ØªØ¨ ØªÚ© Ù…ÙˆØ¬ÙˆØ¯Û Ø§ÛŒ Ù…ÛŒÙ„ Ø³Û’ Ù„Ø§Ú¯ Ø§Ù† Ú©Ø±ÛŒÚºÛ”',
  );
  String get done => _t('Done', 'Ù…Ú©Ù…Ù„');
  String get passwordIncorrect => _t('Incorrect password.', 'Ù¾Ø§Ø³ ÙˆØ±Úˆ ØºÙ„Ø· ÛÛ’Û”');
  String get emailAlreadyUsed => _t(
    'That email is already used by another account.',
    'ÛŒÛ Ø§ÛŒ Ù…ÛŒÙ„ Ù¾ÛÙ„Û’ ÛÛŒ Ú©Ø³ÛŒ Ø§ÙˆØ± Ø§Ú©Ø§Ø¤Ù†Ù¹ Ù…ÛŒÚº Ø§Ø³ØªØ¹Ù…Ø§Ù„ ÛÛ’Û”',
  );
  String get reauthenticateRequired => _t(
    'Please log out and log back in, then try again.',
    'Ø¨Ø±Ø§Û Ú©Ø±Ù… Ù„Ø§Ú¯ Ø¢Ø¤Ù¹ Ú©Ø± Ú©Û’ Ø¯ÙˆØ¨Ø§Ø±Û Ù„Ø§Ú¯ Ø§Ù† Ú©Ø±ÛŒÚºØŒ Ù¾Ú¾Ø± Ú©ÙˆØ´Ø´ Ú©Ø±ÛŒÚºÛ”',
  );
  String get notifications => _t('Notifications', 'Ø§Ø·Ù„Ø§Ø¹Ø§Øª');
  String get unableToOpenNotification =>
      _t('Unable to open notification.', 'Ø§Ø·Ù„Ø§Ø¹ Ú©Ú¾ÙˆÙ„ÛŒ Ù†ÛÛŒÚº Ø¬Ø§ Ø³Ú©ÛŒÛ”');
  String get chooseContinue => _t(
    'Choose an option to continue.',
    'Ø¬Ø§Ø±ÛŒ Ø±Ú©Ú¾Ù†Û’ Ú©Û’ Ù„ÛŒÛ’ Ø§ÛŒÚ© Ø¢Ù¾Ø´Ù† Ù…Ù†ØªØ®Ø¨ Ú©Ø±ÛŒÚºÛ”',
  );
  String get howCanHelp =>
      _t('How can we help\nyou today?', 'Ø¢Ø¬ ÛÙ… Ø¢Ù¾ Ú©ÛŒ\nÚ©ÛŒØ³Û’ Ù…Ø¯Ø¯ Ú©Ø± Ø³Ú©ØªÛ’ ÛÛŒÚºØŸ');
  String get donorDashboard => _t('Donor Dashboard', 'Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Û ÚˆÛŒØ´ Ø¨ÙˆØ±Úˆ');
  String get notificationsTooltip => _t('Notifications', 'Ø§Ø·Ù„Ø§Ø¹Ø§Øª');
  String get retryAction => _t('Retry', 'Ø¯ÙˆØ¨Ø§Ø±Û Ú©ÙˆØ´Ø´ Ú©Ø±ÛŒÚº');
  String get sosAlert => _t('SOS alert', 'Ø§ÛŒØ³ Ø§Ùˆ Ø§ÛŒØ³ Ø§Ø·Ù„Ø§Ø¹');
  String get rateApp =>
      _t('Rate Smart Blood Bank', 'Ø§Ø³Ù…Ø§Ø±Ù¹ Ø¨Ù„Úˆ Ø¨ÛŒÙ†Ú© Ú©ÛŒ Ø¯Ø±Ø¬Û Ø¨Ù†Ø¯ÛŒ Ú©Ø±ÛŒÚº');
  String get rateExperience => _t(
    'How would you rate your experience?',
    'Ø¢Ù¾ Ø§Ù¾Ù†Û’ ØªØ¬Ø±Ø¨Û’ Ú©Ùˆ Ú©ÛŒØ³Û’ Ø¯Ø±Ø¬Û Ø¯ÛŒÚº Ú¯Û’ØŸ',
  );
  String get submit => _t('Submit', 'Ø¬Ù…Ø¹ Ú©Ø±ÛŒÚº');
  String get about => _t('About', 'ØªØ¹Ø§Ø±Ù');
  String version(String value) => _t('Version $value', 'ÙˆØ±Ú˜Ù† $value');
  String get cancelAction => _t('Cancel', 'Ù…Ù†Ø³ÙˆØ® Ú©Ø±ÛŒÚº');
  String get welcomeBack => _t('Welcome Back', 'Ø®ÙˆØ´ Ø¢Ù…Ø¯ÛŒØ¯');
  String get everyLoginCouldSave =>
      _t('Every login could save a life', 'ÛØ± Ù„Ø§Ú¯ Ø§Ù† Ø§ÛŒÚ© Ø²Ù†Ø¯Ú¯ÛŒ Ø¨Ú†Ø§ Ø³Ú©ØªØ§ ÛÛ’');
  String get accountType => _t('Account type', 'Ø§Ú©Ø§Ø¤Ù†Ù¹ Ú©ÛŒ Ù‚Ø³Ù…');
  String get donor => _t('Donor', 'Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Û');
  String get receiver => _t('Receiver', 'Ø®ÙˆÙ† ÙˆØµÙˆÙ„ Ú©Ù†Ù†Ø¯Û');
  String get resetPassword => _t('Reset Password', 'Ù¾Ø§Ø³ ÙˆØ±Úˆ Ø±ÛŒ Ø³ÛŒÙ¹ Ú©Ø±ÛŒÚº');
  String get resetPasswordHint => _t(
    "Enter your email and we'll send a reset link.",
    'Ø§Ù¾Ù†ÛŒ Ø§ÛŒ Ù…ÛŒÙ„ Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚºØŒ ÛÙ… Ø±ÛŒ Ø³ÛŒÙ¹ Ù„Ù†Ú© Ø¨Ú¾ÛŒØ¬ÛŒÚº Ú¯Û’Û”',
  );
  String get emailHint => _t('your@email.com', 'your@email.com');
  String get resetLinkSent => _t(
    'Reset link sent! Check your inbox.',
    'Ø±ÛŒ Ø³ÛŒÙ¹ Ù„Ù†Ú© Ø¨Ú¾ÛŒØ¬ Ø¯ÛŒØ§ Ú¯ÛŒØ§! Ø§Ù¾Ù†Ø§ Ø§Ù† Ø¨Ø§Ú©Ø³ Ú†ÛŒÚ© Ú©Ø±ÛŒÚºÛ”',
  );
  String get sendLink => _t('Send Link', 'Ù„Ù†Ú© Ø¨Ú¾ÛŒØ¬ÛŒÚº');
  String get createRequestBeforeNotify => _t(
    'Create a blood request first to notify donors.',
    'Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Ú¯Ø§Ù† Ú©Ùˆ Ø§Ø·Ù„Ø§Ø¹ Ø¯ÛŒÙ†Û’ Ø³Û’ Ù¾ÛÙ„Û’ Ø®ÙˆÙ† Ú©ÛŒ Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ø¨Ù†Ø§Ø¦ÛŒÚºÛ”',
  );
  String get findNearbyDonors =>
      _t('Find Nearby Donors', 'Ù‚Ø±ÛŒØ¨ÛŒ Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Ú¯Ø§Ù† ØªÙ„Ø§Ø´ Ú©Ø±ÛŒÚº');
  String get notifyDonor => _t('Notify donor', 'Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Û Ú©Ùˆ Ø§Ø·Ù„Ø§Ø¹ Ø¯ÛŒÚº');
  String get mapViewLabel => _t('Map view', 'Ù†Ù‚Ø´Û Ø¯ÛŒÚ©Ú¾ÛŒÚº');
  String get listViewLabel => _t('List view', 'ÙÛØ±Ø³Øª Ø¯ÛŒÚ©Ú¾ÛŒÚº');
  String get searchDonorName =>
      _t('Search donor name', 'Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Û Ú©Ø§ Ù†Ø§Ù… ØªÙ„Ø§Ø´ Ú©Ø±ÛŒÚº');
  String get anyBloodGroup => _t('Any blood group', 'Ú©ÙˆØ¦ÛŒ Ø¨Ú¾ÛŒ Ø®ÙˆÙ† Ú©Ø§ Ú¯Ø±ÙˆÙ¾');
  String compatibleWith(String group) =>
      _t('Compatible with $group', '$group Ú©Û’ Ù„ÛŒÛ’ Ù…ÙˆØ²ÙˆÚº');
  String donorCountWithin(int count, int radius) => _t(
    '$count donors within $radius km',
    '$radius Ú©Ù„ÙˆÙ…ÛŒÙ¹Ø± Ú©Û’ Ø§Ù†Ø¯Ø± $count Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Ú¯Ø§Ù†',
  );
  String get noCompatibleDonors => _t(
    'No available compatible donors in this radius. Try expanding it.',
    'Ø§Ø³ Ø¯Ø§Ø¦Ø±Û’ Ù…ÛŒÚº Ú©ÙˆØ¦ÛŒ Ø¯Ø³ØªÛŒØ§Ø¨ Ù…ÙˆØ²ÙˆÚº Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Û Ù†ÛÛŒÚºÛ” Ø¯Ø§Ø¦Ø±Û Ø¨Ú‘Ú¾Ø§ Ú©Ø± Ø¯ÛŒÚ©Ú¾ÛŒÚºÛ”',
  );
  String get trackRequest => _t('Track request', 'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ú©Ùˆ Ù¹Ø±ÛŒÚ© Ú©Ø±ÛŒÚº');
  String get notifyMatchingDonors =>
      _t('Notify matching donors', 'Ù…ÙˆØ²ÙˆÚº Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Ú¯Ø§Ù† Ú©Ùˆ Ø§Ø·Ù„Ø§Ø¹ Ø¯ÛŒÚº');
  String get queuing => _t('Queuingâ€¦', 'Ù‚Ø·Ø§Ø± Ù…ÛŒÚº Ø´Ø§Ù…Ù„ ÛÙˆ Ø±ÛØ§ ÛÛ’â€¦');
  String get askForSupport => _t('Ask for support', 'Ù…Ø¯Ø¯ Ø·Ù„Ø¨ Ú©Ø±ÛŒÚº');
  String get supportRequest => _t('Support request', 'Ù…Ø¯Ø¯ Ú©ÛŒ Ø¯Ø±Ø®ÙˆØ§Ø³Øª');
  String get subject => _t('Subject', 'Ù…ÙˆØ¶ÙˆØ¹');
  String get describeIssue => _t('Describe the issue', 'Ù…Ø³Ø¦Ù„Û Ø¨ÛŒØ§Ù† Ú©Ø±ÛŒÚº');
  String get helpSupport => _t('Help & Support', 'Ù…Ø¯Ø¯ Ø§ÙˆØ± Ù…Ø¹Ø§ÙˆÙ†Øª');
  String get contactUs => _t('Contact Us', 'ÛÙ… Ø³Û’ Ø±Ø§Ø¨Ø·Û Ú©Ø±ÛŒÚº');
  String get confirmActionPrompt =>
      _t('Please confirm this action.', 'Ø¨Ø±Ø§Û Ú©Ø±Ù… Ø§Ø³ Ú©Ø§Ø±Ø±ÙˆØ§Ø¦ÛŒ Ú©ÛŒ ØªØµØ¯ÛŒÙ‚ Ú©Ø±ÛŒÚºÛ”');
  String get back => _t('Back', 'ÙˆØ§Ù¾Ø³');
  String get confirm => _t('Confirm', 'ØªØµØ¯ÛŒÙ‚ Ú©Ø±ÛŒÚº');
  String get requestTracking => _t('Request Tracking', 'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ú©ÛŒ Ù¾ÛŒØ±ÙˆÛŒ');
  String get callRequester => _t('Call requester', 'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ú©Ù†Ù†Ø¯Û Ú©Ùˆ Ú©Ø§Ù„ Ú©Ø±ÛŒÚº');
  String get callInApp => _t('Call in app', 'Ø§ÛŒÙ¾ Ù…ÛŒÚº Ú©Ø§Ù„ Ú©Ø±ÛŒÚº');
  String get endCall => _t('End call', 'Ú©Ø§Ù„ Ø®ØªÙ… Ú©Ø±ÛŒÚº');
  String get answerCall => _t('Answer', 'Ø¬ÙˆØ§Ø¨ Ø¯ÛŒÚº');
  String get rejectCall => _t('Reject', 'Ù…Ø³ØªØ±Ø¯ Ú©Ø±ÛŒÚº');
  String get callConnecting => _t('Connectingâ€¦', 'Ø±Ø§Ø¨Ø·Û Ù‚Ø§Ø¦Ù… ÛÙˆ Ø±ÛØ§ ÛÛ’â€¦');
  String donorReadyQuestion(String name) => _t(
    'Is $name ready to donate blood?',
    'Ú©ÛŒØ§ $name Ø®ÙˆÙ† Ø¹Ø·ÛŒÛ Ú©Ø±Ù†Û’ Ú©Û’ Ù„ÛŒÛ’ ØªÛŒØ§Ø± ÛÛ’ØŸ',
  );
  String get donorReadyYes => _t('Yes', 'ÛØ§Úº');
  String get donorReadyNo => _t('No', 'Ù†ÛÛŒÚº');
  String get profileVerifiedLabel => _t('Profile verified', 'Ù¾Ø±ÙˆÙØ§Ø¦Ù„ Ú©ÛŒ ØªØµØ¯ÛŒÙ‚ Ø´Ø¯Û');
  String get dashboard => _t('Dashboard', 'ÚˆÛŒØ´ Ø¨ÙˆØ±Úˆ');
  String get analyticsTitle => _t('Analytics overview', 'ØªØ¬Ø²ÛŒØ§ØªÛŒ Ø¬Ø§Ø¦Ø²Û');
  String get bloodGroupFilter => _t('Blood group', 'Ø®ÙˆÙ† Ú©Ø§ Ú¯Ø±ÙˆÙ¾');
  String get analyticsApproximate => _t('Approximate: result cap reached', 'ØªÙ‚Ø±ÛŒØ¨ÛŒ: Ù†ØªØ§Ø¦Ø¬ Ú©ÛŒ Ø­Ø¯ Ù¾ÙˆØ±ÛŒ ÛÙˆ Ú¯Ø¦ÛŒ');
  String get totalDonors => _t('Total donors', 'Ú©Ù„ Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Ú¯Ø§Ù†');
  String get activeDonors => _t('Active donors', 'ÙØ¹Ø§Ù„ Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Ú¯Ø§Ù†');
  String get verifiedDonors => _t('Verified donors', 'ØªØµØ¯ÛŒÙ‚ Ø´Ø¯Û Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Ú¯Ø§Ù†');
  String get openRequests => _t('Open requests', 'Ú©Ú¾Ù„ÛŒ Ø¯Ø±Ø®ÙˆØ§Ø³ØªÛŒÚº');
  String get fulfilledRequests => _t('Fulfilled requests', 'Ù…Ú©Ù…Ù„ Ø¯Ø±Ø®ÙˆØ§Ø³ØªÛŒÚº');
  String get pendingVerifications => _t('Pending verifications', 'Ø²ÛŒØ± Ø§Ù„ØªÙˆØ§ ØªØµØ¯ÛŒÙ‚Ø§Øª');
  String get requestStatusSummary => _t('Request status', 'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ú©ÛŒ Ø­Ø§Ù„Øª');
  String get lastUpdated => _t('Last updated', 'Ø¢Ø®Ø±ÛŒ ØªØ§Ø²Û Ú©Ø§Ø±ÛŒ');
  String get bloodNeededNearYou => _t('Blood Needed Near You', 'Ø¢Ù¾ Ú©Û’ Ù‚Ø±ÛŒØ¨ Ø®ÙˆÙ† Ú©ÛŒ Ø¶Ø±ÙˆØ±Øª');
  String get goToDashboard => _t('Go to dashboard', 'ÚˆÛŒØ´ Ø¨ÙˆØ±Úˆ Ù¾Ø± Ø¬Ø§Ø¦ÛŒÚº');
  String get invitationSent => _t('Invitation sent.', 'Ø¯Ø¹ÙˆØª Ø¨Ú¾ÛŒØ¬ Ø¯ÛŒ Ú¯Ø¦ÛŒÛ”');
  String invitationFailed(String error) => _t('Could not send invitation: $error', 'Ø¯Ø¹ÙˆØª Ù†ÛÛŒÚº Ø¨Ú¾ÛŒØ¬ÛŒ Ø¬Ø§ Ø³Ú©ÛŒ: $error');
  String get invitedStatus => _t('Invited', 'Ø¯Ø¹ÙˆØª Ø¯ÛŒ Ú¯Ø¦ÛŒ');
  String get muteCall => _t('Mute microphone', 'Ù…Ø§Ø¦ÛŒÚ©Ø±ÙˆÙÙˆÙ† Ø®Ø§Ù…ÙˆØ´ Ú©Ø±ÛŒÚº');
  String get unmuteCall => _t('Unmute microphone', 'Ù…Ø§Ø¦ÛŒÚ©Ø±ÙˆÙÙˆÙ† Ú©Ú¾ÙˆÙ„ÛŒÚº');
  String get speakerOn => _t('Turn speaker on', 'Ø§Ø³Ù¾ÛŒÚ©Ø± Ø¢Ù† Ú©Ø±ÛŒÚº');
  String get speakerOff => _t('Turn speaker off', 'Ø§Ø³Ù¾ÛŒÚ©Ø± Ø¨Ù†Ø¯ Ú©Ø±ÛŒÚº');
  String get callConnectionLost => _t('Call connection lost. Try again.', 'Ú©Ø§Ù„ Ú©Ø§ Ø±Ø§Ø¨Ø·Û Ù…Ù†Ù‚Ø·Ø¹ ÛÙˆ Ú¯ÛŒØ§Û” Ø¯ÙˆØ¨Ø§Ø±Û Ú©ÙˆØ´Ø´ Ú©Ø±ÛŒÚºÛ”');
  String get confirmedStatus => _t('Confirmed', 'ØªØµØ¯ÛŒÙ‚ Ø´Ø¯Û');
  String get declinedStatus => _t('Declined', 'Ù…Ø³ØªØ±Ø¯');
  String get callEnded => _t('Call ended', 'Ú©Ø§Ù„ Ø®ØªÙ… ÛÙˆ Ú¯Ø¦ÛŒ');
  String get directionsMeetingPoint =>
      _t('Directions to meeting point', 'Ù…Ù„Ø§Ù‚Ø§Øª Ú©Û’ Ù…Ù‚Ø§Ù… ØªÚ© Ø±Ø§Ø³ØªÛ');
  String get donorAgreed =>
      _t('Yes, I agree to donate', 'ÛØ§ÚºØŒ Ù…ÛŒÚº Ø®ÙˆÙ† Ø¹Ø·ÛŒÛ Ú©Ø±Ù†Û’ Ù¾Ø± Ù…ØªÙÙ‚ ÛÙˆÚº');
  String get donorDidNotAgree =>
      _t('No, I did not agree', 'Ù†ÛÛŒÚºØŒ Ù…ÛŒÚº Ù…ØªÙÙ‚ Ù†ÛÛŒÚº ÛÙˆØ§');
  String get agreementPrompt => _t(
    'Did you agree to donate blood to this receiver?',
    'Ú©ÛŒØ§ Ø¢Ù¾ Ø§Ø³ Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ú©Ù†Ù†Ø¯Û Ú©Ùˆ Ø®ÙˆÙ† Ø¯ÛŒÙ†Û’ Ù¾Ø± Ù…ØªÙÙ‚ ÛÛŒÚºØŸ',
  );
  String get donationAgreementPending => _t(
    'Donation agreement is pending.',
    'Ø®ÙˆÙ† Ø¹Ø·ÛŒÛ Ú©Ø±Ù†Û’ Ú©ÛŒ Ø±Ø¶Ø§Ù…Ù†Ø¯ÛŒ Ø²ÛŒØ±Ù Ø§Ù„ØªÙˆØ§ ÛÛ’Û”',
  );
  String get acceptRespond => _t('Accept / Respond', 'Ù‚Ø¨ÙˆÙ„ / Ø¬ÙˆØ§Ø¨ Ø¯ÛŒÚº');
  String get donatedRequestConfirmation => _t(
    'I donated â€” request confirmation',
    'Ù…ÛŒÚº Ù†Û’ Ø®ÙˆÙ† Ø¹Ø·ÛŒÛ Ú©ÛŒØ§ â€” ØªØµØ¯ÛŒÙ‚ Ú©ÛŒ Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ú©Ø±ÛŒÚº',
  );
  String get withdraw => _t('Withdraw', 'Ø¯Ø³ØªØ¨Ø±Ø¯Ø§Ø± ÛÙˆÚº');
  String get noDonorsResponded => _t(
    'No donors have responded yet.',
    'Ø§Ø¨Ú¾ÛŒ ØªÚ© Ú©Ø³ÛŒ Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Û Ù†Û’ Ø¬ÙˆØ§Ø¨ Ù†ÛÛŒÚº Ø¯ÛŒØ§Û”',
  );
  String get contact => _t('Contact', 'Ø±Ø§Ø¨Ø·Û');
  String get chat => _t('Chat', 'Ú†ÛŒÙ¹');
  String get bloodReceived => _t('Blood received', 'Ø®ÙˆÙ† Ù…ÙˆØµÙˆÙ„ ÛÙˆ Ú¯ÛŒØ§');
  String get releaseReassign =>
      _t('Release / Reassign', 'Ø¬Ø§Ø±ÛŒ Ú©Ø±ÛŒÚº / Ø¯ÙˆØ¨Ø§Ø±Û ØªÙÙˆÛŒØ¶ Ú©Ø±ÛŒÚº');
  String get findAdditionalDonors =>
      _t('Find additional donors', 'Ù…Ø²ÛŒØ¯ Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Ú¯Ø§Ù† ØªÙ„Ø§Ø´ Ú©Ø±ÛŒÚº');
  String get cancelRequest => _t('Cancel request', 'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ù…Ù†Ø³ÙˆØ® Ú©Ø±ÛŒÚº');
  String get resolveSos => _t('Resolve SOS', 'Ø§ÛŒØ³ Ø§Ùˆ Ø§ÛŒØ³ Ø­Ù„ Ú©Ø±ÛŒÚº');
  String get timelineUnavailable =>
      _t('Timeline unavailable.', 'Ù¹Ø§Ø¦Ù… Ù„Ø§Ø¦Ù† Ø¯Ø³ØªÛŒØ§Ø¨ Ù†ÛÛŒÚºÛ”');
  String get settingsTooltip => _t('Settings', 'ØªØ±ØªÛŒØ¨Ø§Øª');
  String get createBloodRequest =>
      _t('Create Blood Request', 'Ø®ÙˆÙ† Ú©ÛŒ Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ø¨Ù†Ø§Ø¦ÛŒÚº');
  String get allRequestsHistory =>
      _t('All requests & history', 'ØªÙ…Ø§Ù… Ø¯Ø±Ø®ÙˆØ§Ø³ØªÛŒÚº Ø§ÙˆØ± ØªØ§Ø±ÛŒØ®');
  String get activeSosHistory =>
      _t('Active SOS & history', 'ÙØ¹Ø§Ù„ Ø§ÛŒØ³ Ø§Ùˆ Ø§ÛŒØ³ Ø§ÙˆØ± ØªØ§Ø±ÛŒØ®');
  String get notLoggedIn => _t('Not logged in', 'Ù„Ø§Ú¯ Ø§Ù† Ù†ÛÛŒÚº ÛÛ’');
  String get noRequestsYet => _t('No requests yet', 'Ø§Ø¨Ú¾ÛŒ Ú©ÙˆØ¦ÛŒ Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ù†ÛÛŒÚº');
  String get cancelThisRequest =>
      _t('Cancel this request?', 'ÛŒÛ Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ù…Ù†Ø³ÙˆØ® Ú©Ø±ÛŒÚºØŸ');
  String get keepRequest => _t('Keep request', 'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ø¨Ø±Ù‚Ø±Ø§Ø± Ø±Ú©Ú¾ÛŒÚº');
  String get trackRequestDonors =>
      _t('Track request / donors', 'Ø¯Ø±Ø®ÙˆØ§Ø³Øª / Ø¹Ø·ÛŒÛ Ø¯ÛÙ†Ø¯Ú¯Ø§Ù† Ú©Ùˆ Ù¹Ø±ÛŒÚ© Ú©Ø±ÛŒÚº');
  String get chooseLocation => _t('Choose location', 'Ù…Ù‚Ø§Ù… Ù…Ù†ØªØ®Ø¨ Ú©Ø±ÛŒÚº');
  String get searchHospitalAddress =>
      _t('Search hospital or address', 'ÛØ³Ù¾ØªØ§Ù„ ÛŒØ§ Ù¾ØªÛ ØªÙ„Ø§Ø´ Ú©Ø±ÛŒÚº');
  String get useCurrentLocation =>
      _t('Use current location', 'Ù…ÙˆØ¬ÙˆØ¯Û Ù…Ù‚Ø§Ù… Ø§Ø³ØªØ¹Ù…Ø§Ù„ Ú©Ø±ÛŒÚº');
  String get confirmLocation => _t('Confirm Location', 'Ù…Ù‚Ø§Ù… Ú©ÛŒ ØªØµØ¯ÛŒÙ‚ Ú©Ø±ÛŒÚº');
  String get selectHospitalPoint => _t(
    'Select and confirm the hospital meeting point.',
    'ÛØ³Ù¾ØªØ§Ù„ Ú©Ø§ Ù…Ù„Ø§Ù‚Ø§Øª Ú©Ø§ Ù…Ù‚Ø§Ù… Ù…Ù†ØªØ®Ø¨ Ø§ÙˆØ± ØªØµØ¯ÛŒÙ‚ Ú©Ø±ÛŒÚºÛ”',
  );
  String get requiredDateMissing =>
      _t('Please select required by date', 'Ø¨Ø±Ø§Û Ú©Ø±Ù… Ù…Ø·Ù„ÙˆØ¨Û ØªØ§Ø±ÛŒØ® Ù…Ù†ØªØ®Ø¨ Ú©Ø±ÛŒÚº');
  String get invalidAgeUnits =>
      _t('Enter valid age and units', 'Ø¯Ø±Ø³Øª Ø¹Ù…Ø± Ø§ÙˆØ± ÛŒÙˆÙ†Ù¹Ø³ Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº');
  String get requestSubmitted =>
      _t('Request submitted successfully!', 'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ú©Ø§Ù…ÛŒØ§Ø¨ÛŒ Ø³Û’ Ø¬Ù…Ø¹ ÛÙˆ Ú¯Ø¦ÛŒ!');
  String get requiredByDate => _t('Required By Date', 'Ù…Ø·Ù„ÙˆØ¨Û ØªØ§Ø±ÛŒØ®');
  String get noRecords => _t('No records yet.', 'Ø§Ø¨Ú¾ÛŒ Ú©ÙˆØ¦ÛŒ Ø±ÛŒÚ©Ø§Ø±Úˆ Ù†ÛÛŒÚºÛ”');
  String get unableToLoadRecords => _t(
    'Unable to load records. Check your connection and retry.',
    'Ø±ÛŒÚ©Ø§Ø±Úˆ Ù„ÙˆÚˆ Ù†ÛÛŒÚº ÛÙˆ Ø³Ú©Û’Û” Ú©Ù†Ú©Ø´Ù† Ú†ÛŒÚ© Ú©Ø±ÛŒÚºÛ”',
  );
  String get verifyEmail => _t('Verify Your Email', 'Ø§ÛŒ Ù…ÛŒÙ„ Ú©ÛŒ ØªØµØ¯ÛŒÙ‚ Ú©Ø±ÛŒÚº');
  String get verifyEmailMessage => _t(
    'Please verify your email before signing in.',
    'Ù„Ø§Ú¯ Ø§Ù† Ø³Û’ Ù¾ÛÙ„Û’ Ø§Ù¾Ù†ÛŒ Ø§ÛŒ Ù…ÛŒÙ„ Ú©ÛŒ ØªØµØ¯ÛŒÙ‚ Ú©Ø±ÛŒÚºÛ”',
  );
  String get accountRejected =>
      _t('Account Rejected', 'Ø§Ú©Ø§Ø¤Ù†Ù¹ Ù…Ø³ØªØ±Ø¯ Ú©Ø± Ø¯ÛŒØ§ Ú¯ÛŒØ§');
  String get accountRejectedMessage => _t(
    'Your account request was rejected. Contact support.',
    'Ø¢Ù¾ Ú©ÛŒ Ø§Ú©Ø§Ø¤Ù†Ù¹ Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ù…Ø³ØªØ±Ø¯ Ú©Ø± Ø¯ÛŒ Ú¯Ø¦ÛŒ ÛÛ’Û” Ø³Ù¾ÙˆØ±Ù¹ Ø³Û’ Ø±Ø§Ø¨Ø·Û Ú©Ø±ÛŒÚºÛ”',
  );
  String get understood => _t('Understood', 'Ø³Ù…Ø¬Ú¾ Ú¯ÛŒØ§');
  String get donationHistory => _t('Donation History', 'Ø¹Ø·ÛŒØ§Øª Ú©ÛŒ ØªØ§Ø±ÛŒØ®');
  String get pleaseSignIn => _t('Please sign in.', 'Ø¨Ø±Ø§Û Ú©Ø±Ù… Ø³Ø§Ø¦Ù† Ø§Ù† Ú©Ø±ÛŒÚºÛ”');
  String get requestUnavailable =>
      _t('Request unavailable', 'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ø¯Ø³ØªÛŒØ§Ø¨ Ù†ÛÛŒÚº');
  String get openRequestList => _t(
    'Open this request from your request list.',
    'ÛŒÛ Ø¯Ø±Ø®ÙˆØ§Ø³Øª ÙÛØ±Ø³Øª Ø³Û’ Ú©Ú¾ÙˆÙ„ÛŒÚºÛ”',
  );
  String get login => _t('Login', 'Ù„Ø§Ú¯ Ø§Ù†');
  String get password => _t('Password', 'Ù¾Ø§Ø³ ÙˆØ±Úˆ');
  String get adminEmail => _t('Admin Email', 'Ø§ÛŒÚˆÙ…Ù† Ø§ÛŒ Ù…ÛŒÙ„');
  String get forgotPassword => _t('Forgot Password?', 'Ù¾Ø§Ø³ ÙˆØ±Úˆ Ø¨Ú¾ÙˆÙ„ Ú¯Ø¦Û’ØŸ');
  String get emailRequired => _t('Email is required', 'Ø§ÛŒ Ù…ÛŒÙ„ Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº');
  String get validEmailRequired =>
      _t('Enter a valid email', 'Ø¯Ø±Ø³Øª Ø§ÛŒ Ù…ÛŒÙ„ Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº');
  String get passwordRequired => _t('Password is required', 'Ù¾Ø§Ø³ ÙˆØ±Úˆ Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº');
  String get passwordMinLength => _t(
    'Password must be at least 6 characters',
    'Ù¾Ø§Ø³ ÙˆØ±Úˆ Ú©Ù… Ø§Ø² Ú©Ù… 6 Ø­Ø±ÙˆÙ Ú©Ø§ ÛÙˆ',
  );
  String get bloodRequests => _t('Blood Requests', 'Ø®ÙˆÙ† Ú©ÛŒ Ø¯Ø±Ø®ÙˆØ§Ø³ØªÛŒÚº');
  String get viewRequest => _t('View request', 'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ø¯ÛŒÚ©Ú¾ÛŒÚº');
  String get radius => _t('Radius', 'Ø¯Ø§Ø¦Ø±Û');
  String get noCompatibleRequests => _t(
    'No compatible active requests in this radius.',
    'Ø§Ø³ Ø¯Ø§Ø¦Ø±Û’ Ù…ÛŒÚº Ú©ÙˆØ¦ÛŒ Ù…ÙˆØ²ÙˆÚº ÙØ¹Ø§Ù„ Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ù†ÛÛŒÚºÛ”',
  );
  String get selectedLocation => _t('Selected location', 'Ù…Ù†ØªØ®Ø¨ Ù…Ù‚Ø§Ù…');
  String get registrationSuccessful =>
      _t('Registration Successful!', 'Ø±Ø¬Ø³Ù¹Ø±ÛŒØ´Ù† Ú©Ø§Ù…ÛŒØ§Ø¨');
  String get accountReady => _t(
    'Your account is ready. You can sign in now.',
    'Ø¢Ù¾ Ú©Ø§ Ø§Ú©Ø§Ø¤Ù†Ù¹ ØªÛŒØ§Ø± ÛÛ’Û” Ø§Ø¨ Ø³Ø§Ø¦Ù† Ø§Ù† Ú©Ø± Ø³Ú©ØªÛ’ ÛÛŒÚºÛ”',
  );
  String get within => _t('Within', 'Ø­Ø¯ Ú©Û’ Ø§Ù†Ø¯Ø±');
  String get urgency => _t('Urgency', 'Ø§ÛÙ…ÛŒØª');
  String get critical => _t('Critical', 'Ø§Ù†ØªÛØ§Ø¦ÛŒ Ø§ÛÙ…');
  String get urgent => _t('Urgent', 'ÙÙˆØ±ÛŒ');
  String get normal => _t('Normal', 'Ø¹Ø§Ù…');
  String get mapView => _t('Map view', 'Ù†Ù‚Ø´Û Ø¯ÛŒÚ©Ú¾ÛŒÚº');
  String get pleaseSignInShort => pleaseSignIn;
  String get noMatches => _t(
    'No matching requests found right now.',
    'Ø§Ø³ ÙˆÙ‚Øª Ú©ÙˆØ¦ÛŒ Ù…ÙˆØ²ÙˆÚº Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ù†ÛÛŒÚº Ù…Ù„ÛŒÛ”',
  );
  String get updatePassword => _t('Update Password', 'Ù¾Ø§Ø³ ÙˆØ±Úˆ Ø§Ù¾ ÚˆÛŒÙ¹ Ú©Ø±ÛŒÚº');
  String get showPassword => _t('Show password', 'Ù¾Ø§Ø³ ÙˆØ±Úˆ Ø¯Ú©Ú¾Ø§Ø¦ÛŒÚº');
  String get hidePassword => _t('Hide password', 'Ù¾Ø§Ø³ ÙˆØ±Úˆ Ú†Ú¾Ù¾Ø§Ø¦ÛŒÚº');
  String get reportMisuse => _t('Report Misuse', 'ØºÙ„Ø· Ø§Ø³ØªØ¹Ù…Ø§Ù„ Ú©ÛŒ Ø±Ù¾ÙˆØ±Ù¹');
  String get issuePrompt => _t("What's the issue?", 'Ù…Ø³Ø¦Ù„Û Ú©ÛŒØ§ ÛÛ’ØŸ');
  String get detailsOptional =>
      _t('Additional details (optional)', 'Ø§Ø¶Ø§ÙÛŒ ØªÙØµÛŒÙ„ (Ø§Ø®ØªÛŒØ§Ø±ÛŒ)');
  String get cancel => _t('Cancel', 'Ù…Ù†Ø³ÙˆØ® Ú©Ø±ÛŒÚº');
  String get submitReport => _t('Submit Report', 'Ø±Ù¾ÙˆØ±Ù¹ Ø¬Ù…Ø¹ Ú©Ø±ÛŒÚº');
  String get verifyPhone => _t('Verify Phone Number', 'ÙÙˆÙ† Ù†Ù…Ø¨Ø± Ú©ÛŒ ØªØµØ¯ÛŒÙ‚ Ú©Ø±ÛŒÚº');
  String get verificationCode => _t('Verification code', 'ØªØµØ¯ÛŒÙ‚ÛŒ Ú©ÙˆÚˆ');
  String get verify => _t('Verify', 'ØªØµØ¯ÛŒÙ‚ Ú©Ø±ÛŒÚº');
  String get bloodGroupNeeded => _t('Blood group needed', 'Ù…Ø·Ù„ÙˆØ¨Û Ø®ÙˆÙ† Ú©Ø§ Ú¯Ø±ÙˆÙ¾');
  String get hospitalMeetingPoint =>
      _t('Hospital / meeting point', 'ÛØ³Ù¾ØªØ§Ù„ / Ù…Ù„Ø§Ù‚Ø§Øª Ú©Ø§ Ù…Ù‚Ø§Ù…');
  String get contactNumber => _t('Contact number', 'Ø±Ø§Ø¨Ø·Û Ù†Ù…Ø¨Ø±');
  String get sosEmergency => _t('SOS Emergency', 'ÛÙ†Ú¯Ø§Ù…ÛŒ SOS');
  String get retryLabel => retry;
  String get settings => _t('Settings', 'ØªØ±ØªÛŒØ¨Ø§Øª');
  String get changePassword => _t('Change Password', 'Ù¾Ø§Ø³ ÙˆØ±Úˆ ØªØ¨Ø¯ÛŒÙ„ Ú©Ø±ÛŒÚº');
  String get currentPassword => _t('Current Password', 'Ù…ÙˆØ¬ÙˆØ¯Û Ù¾Ø§Ø³ ÙˆØ±Úˆ');
  String get newPassword => _t('New Password', 'Ù†ÛŒØ§ Ù¾Ø§Ø³ ÙˆØ±Úˆ');
  String get confirmNewPassword =>
      _t('Confirm New Password', 'Ù†ÛŒØ§ Ù¾Ø§Ø³ ÙˆØ±Úˆ Ø¯ÙˆØ¨Ø§Ø±Û Ø¯Ø±Ø¬ Ú©Ø±ÛŒÚº');
  String get passwordsDoNotMatch =>
      _t('Passwords do not match', 'Ù¾Ø§Ø³ ÙˆØ±Úˆ Ù…Ù…Ø§Ø«Ù„ Ù†ÛÛŒÚº ÛÛŒÚº');
  String get report => _t('Report', 'Ø±Ù¾ÙˆØ±Ù¹');
  String get reportSubmitted => _t(
    'Report submitted. Thank you for helping keep the community safe.',
    'Ø±Ù¾ÙˆØ±Ù¹ Ø¬Ù…Ø¹ ÛÙˆ Ú¯Ø¦ÛŒÛ” Ú©Ù…ÛŒÙˆÙ†Ù¹ÛŒ Ú©Ùˆ Ù…Ø­ÙÙˆØ¸ Ø±Ú©Ú¾Ù†Û’ Ù…ÛŒÚº Ù…Ø¯Ø¯ Ú©Ø§ Ø´Ú©Ø±ÛŒÛÛ”',
  );
  String get medicalEligibilityDisclaimer => _t('Qualified medical staff decide actual eligibility.', '\u0627\u06c1\u0644 \u0637\u0628\u06cc \u0639\u0645Ù„ÛŒ \u0627ÛÙ„ÛŒØª \u06a9Ø§ \u062dØªÙ…ÛŒ \u0641ÛŒØµÙ„Û \u06a9Ø±ØªÛ’ \u06c1ÛŒÚº');
  String get acknowledgeDonation => _t('Acknowledge', '\u062a\u0635\u062f\u06cc\u0642 \u06a9\u0631\u06cc\u06ba');
  String get disputeDonation => _t('Dispute donation', '\u0639\u0637\u06cc\u06c1 \u06a9\u06d2 \u0628\u0627Ø±\u06d2 \u0645\u06cc\u06ba \u0627\u062eØªÙ„Ø§Ù');
  String get reason => _t('Reason', '\u0648\u062c\u06c1');
  String get submitAction => _t('Submit', '\u062c\u0645Ø¹ \u06a9Ø±\u06cc\u06ba');
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
