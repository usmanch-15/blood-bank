/// ✅ NEW — Legal content (Terms of Service + Privacy Policy)
///
/// Kept as plain constants (not fetched from a server) so the app works
/// offline and there's nothing extra to host/maintain. If you'd rather
/// edit these without shipping a new app build, move this text to a
/// Firestore doc (e.g. `app_config/legal`) and stream it instead —
/// the LegalDocumentScreen widget doesn't care where the text comes from.
///
/// ⚠️ This is written to accurately describe what the app *actually does*
/// (based on the real code — phoneNumber storage, location sharing, SOS,
/// audit logs, Cloud Functions, Twilio SMS fallback). It is NOT a
/// substitute for review by an actual lawyer before a public launch,
/// especially the medical-disclaimer and liability sections — blood
/// donation apps sit close to health data, which some jurisdictions
/// regulate more strictly than ordinary apps.
library;

class LegalContent {
  static const String lastUpdated = 'August 2026';

  // ═══════════════════════════ TERMS OF SERVICE ═══════════════════════════
  static const String termsOfService = '''
Last updated: $lastUpdated

Welcome to Smart Blood Bank. By creating an account or using this app, you agree to the terms below. Please read them carefully.

1. WHAT THIS APP IS

Smart Blood Bank is a platform that connects voluntary blood donors with people who need blood, and helps blood banks/admins coordinate requests. We do not collect, store, or transport blood ourselves — we only help people find and contact each other.

2. NOT A MEDICAL SERVICE

This app is not a substitute for professional medical advice, diagnosis, or treatment. We do not verify the medical eligibility, health status, or blood test results of any donor. Before donating or receiving blood, always confirm eligibility, safety, and compatibility with a qualified medical professional or an accredited blood bank/hospital. In a medical emergency, contact emergency services directly — do not rely solely on this app.

3. ACCOUNT ELIGIBILITY & APPROVAL

New accounts are reviewed before activation ("pending" status). We may approve, reject, or later suspend any account at our discretion — for example, if we receive credible reports of misuse, fraud, or abusive behavior through the in-app reporting feature.

4. YOUR RESPONSIBILITIES

You agree to:
  • Provide accurate information (name, blood group, contact details) — inaccurate blood group information can put someone's health at risk.
  • Use donor/receiver contact details only for legitimate donation-related communication.
  • Not use the app to harass, scam, solicit payment for blood (where prohibited by local law), or misrepresent your identity or medical status.
  • Report suspicious requests or behavior using the in-app "Report" feature rather than confronting other users directly.

5. LOCATION & EMERGENCY (SOS) FEATURES

If you enable location sharing, your approximate location is used to match you with nearby donors/requests. SOS alerts notify nearby eligible donors of urgent blood needs. Response to an SOS alert is voluntary — we cannot guarantee any donor will respond, or how quickly.

6. ACCOUNT SUSPENSION & TERMINATION

We may suspend or disable accounts that violate these terms, are reported for misuse, or that we reasonably believe pose a risk to other users. You may request account deletion at any time from Settings.

7. LIMITATION OF LIABILITY

To the fullest extent permitted by law, Smart Blood Bank and its developers are not liable for any harm, loss, or damages arising from: the accuracy of donor/receiver information, the outcome of any donation or medical procedure, missed or delayed SOS responses, or any interaction between users arranged through the app. The app is provided "as is" without warranties of any kind.

8. CHANGES TO THESE TERMS

We may update these terms from time to time. Continued use of the app after changes means you accept the updated terms.

9. CONTACT

Questions about these terms? Reach out via Settings → Help & Support → Contact Us.
''';

  // ═══════════════════════════ PRIVACY POLICY ═══════════════════════════
  static const String privacyPolicy = '''
Last updated: $lastUpdated

This policy explains what data Smart Blood Bank collects, why, and who can see it.

1. INFORMATION WE COLLECT

  • Account info: name, email address, blood group, role (donor/receiver), and account status.
  • Phone number: stored separately from your main profile, in a restricted location only you and admins can read directly (see Section 3).
  • Location: only if you enable location sharing — used to match you with nearby donors or blood requests. You can turn this off anytime in Settings, which also clears any stored coordinates.
  • Donation history: records of confirmed donations, used to calculate eligibility (a minimum gap between donations) and reward points.
  • Device push token: used to deliver notifications (SOS alerts, reward updates, admin announcements). You can disable notification categories individually in Settings.
  • Reports: if you or someone else submits a misuse report, the report content and the accounts involved are stored for admin review.

2. HOW WE USE YOUR INFORMATION

  • To match compatible donors with blood requests.
  • To send SOS alerts, donation confirmations, and reward updates.
  • To let admins review pending accounts and investigate misuse reports.
  • As a fallback, if a push notification can't be delivered for an urgent SOS request, we may send an SMS through a third-party provider (Twilio) using your phone number.

3. WHO CAN SEE YOUR PHONE NUMBER

Your phone number is not visible on your public profile and cannot be read directly by other users. It is only shared in two situations:
  • You (the account owner) or an admin can view/edit it directly.
  • When a receiver taps "Call Donor," the app requests your number through a controlled server-side function, which checks that you are an approved donor and logs the request (who looked up whose number, and when) for accountability. Your number is not otherwise exposed in any list, search, or export.

4. THIRD-PARTY SERVICES

We use Google Firebase (authentication, database, storage, push notifications, cloud functions) to run the app, and Twilio for emergency SMS fallback. These providers process data on our behalf under their own security and privacy commitments; we do not sell your data to advertisers or other third parties.

5. DATA RETENTION & DELETION

If you delete your account (Settings → Delete Account), your account is immediately disabled and hidden from other users. Some records (e.g. completed donation history, audit logs) may be retained for a period for accountability, fraud-prevention, and legal-compliance purposes, even after account deletion.

6. YOUR CHOICES

You can, at any time from Settings: edit your profile, turn location sharing on/off, turn notification categories on/off, mark yourself unavailable to donate, change your password, or delete your account.

7. CHILDREN'S PRIVACY

This app is not intended for use by anyone below the legal age for blood donation in their jurisdiction.

8. CHANGES TO THIS POLICY

We may update this policy as the app evolves. Material changes will be reflected here with an updated "Last updated" date.

9. CONTACT

Privacy questions? Reach out via Settings → Help & Support → Contact Us.
''';
}