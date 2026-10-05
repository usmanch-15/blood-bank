# Smart Blood Bank

Flutter/Firebase Final Year Project, COMSATS University Islamabad, Vehari Campus.
Muhammad Usman (SP23-BCS-046), Muhammad Hassan (SP23-BCS-038). Supervisor: Sir Najeeb Ullah Khan.

This is the existing donor/receiver application and admin interface, using Provider, Firebase Authentication, Firestore, Storage and Cloud Functions. No production deployment or data migration was performed during this reliability pass.

## Implemented scope

- Email/password authentication, recovery, shared account-status checks and restored sessions.
- Donor/receiver switching with additive capability flags; admin remains privileged.
- Profile validation, persisted availability, opt-in approximate location, phone credential linking.
- Blood requests, cancellation, donor acceptance and assigned-donor confirmation.
- Atomic server awards: 50 points once per request, with a 90-day donation interval.
- Indexed geographic matching by compatibility, availability, consent and eligibility. SOS searches 15 km and expands to 30 km only if no match exists at 15 km.
- Donation history, rewards and PDF certificates from confirmed records. These client-rendered acknowledgements are not signed medical credentials.
- Notification inbox, Android FCM handling, settings and authenticated account cleanup.
- Existing admin management screens; no public admin signup.

Android is the main device target. Web compiles, but a complete browser walkthrough was not available in this environment. Web push is skipped pending VAPID/service-worker setup. iOS and desktop are not certified. OTP, maps, push/SMS and download behavior need external/device verification.

Chat, ratings, CNIC verification, blood drives, full localization, hospital integration and expanded admin features remain future work. CNIC is optional unverified input. No completion percentage is claimed.

## Local setup and checks

Use committed lockfiles. Local Flutter checks used 3.47.5. Backend runtime is Node 22; use JDK 17 for Android and JDK 21 for Firebase emulator tooling.

```powershell
flutter pub get
npm.cmd ci --prefix functions
flutter analyze
flutter test
npm.cmd --prefix functions run check
npm.cmd --prefix functions test
functions\node_modules\.bin\firebase.cmd emulators:exec --project demo-blood-bank --only firestore,auth,storage "npm.cmd --prefix functions run test:emulator"
```

Tests use isolated Auth, Firestore and Storage emulators. Callable handler bodies run directly with test auth contexts; these tests do not verify callable HTTP transport, scheduled triggers or actual FCM delivery.

Start the full local demo environment in one terminal:

```powershell
functions\node_modules\.bin\firebase.cmd emulators:start --project demo-blood-bank --only auth,firestore,functions,storage
```

Then run a debug client:

```powershell
flutter run -d chrome --web-port 5195 --dart-define=USE_FIREBASE_EMULATORS=true
# Android emulator: also pass --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

Emulator mode sets demo Firebase options and connects to Auth 9099, Firestore 8080, Functions 5001 and Storage 9199. Release builds reject emulator mode. Do not omit the flag when intending local data. Physical devices need a reachable development-machine host/firewall configuration.

## Firebase setup and controlled rollout

Use a reviewed development project first. Verify lib/firebase_options.dart, Android google-services.json and application ID com.usmanch.bloodbank. Enable Email/Password Authentication, Firestore, Storage and Functions. Phone authentication requires registered Android fingerprints and provider configuration. Keep Admin SDK credentials outside source control. Never use permissive test rules in a deployed project.

A project owner must authorize rollout; none of these deployment steps were executed:

1. Back up Firestore and schedule a controlled schema/client cutover in staging.
2. Review functions/migrateProfiles.js. Explicitly set GOOGLE_CLOUD_PROJECT and operator Application Default Credentials. Run `node functions/migrateProfiles.js` for a dry run. Only after reviewing the target and backup, run with `--apply`. It moves public contact/token fields to private documents, adds capability/availability defaults, and clears coordinates without consent. It does not change statuses or admin roles.
3. Deploy firestore.indexes.json in staging and wait for indexes to finish. Geographic capability/availability/status/consent/latitude, donor history, requests and notifications need the supplied indexes.
4. Deploy reviewed firestore.rules, storage.rules and functions with the matching client. Always specify the intended Firebase project explicitly. Test migration and rollback before production.
5. Resolve remaining dependency advisories in dependency-audit.json through a tested major upgrade before production. Compatible patches were applied; a forced major upgrade was not performed.

Callables include acceptDonation, confirmDonation, deleteAccount, adminDeleteUser, getDonorContact and notifyRequest. Trigger functions handle notifications, SOS, broadcasts and eligibility reminders. Confirmation validates active users, assignment, compatibility and interval in a transaction. Retries do not award points twice.

### Account policy and first admin

Signup creates status approved, zero rewards and no previous donation. Pending approval is not the signup policy. Verification email sending is best effort; email verification is currently not a login gate. Login and restored sessions require approved status and a recognized role. Rules also reject inactive accounts.

A trusted Firebase project owner must verify the intended administrator's identity and Auth UID, create an ordinary account, and update only that exact users/{uid} document to role admin and status approved using the console or a controlled Admin SDK operation. Restrict IAM and protect operator accounts with MFA. Never expose credentials or add a client promotion endpoint. Sign out/in and verify ordinary users cannot self-promote. Admins cannot switch into donor/receiver modes.

### Privacy and cleanup

Display/matching data is in users/{uid}; phone/CNIC in private/contact and tokens in private/device. Signup can record an unverified phone; later changes require linked Auth phone credentials. The profile editor prevents direct phone editing. Contact access uses an authorized, rate-limited callable and audit entry.

Shared coordinates are rounded to two decimals. Distance checks use those approximate coordinates, so boundary results can differ from true GPS distances. The latitude-band index pages in batches of 200, then applies spherical distance filtering. Dense bands can still require many reads. Existing history/list screens display up to 100 recent records; full history pagination remains a limitation.

Self-deletion requires authentication within five minutes. Cleanup disables the account first, removes related records/private data/tokens/known uploads, reopens assigned open requests and removes Auth/profile data. It is not a cross-service transaction: a failure can leave a disabled account requiring an administrator to retry cleanup. Provider backups and delivered messages are outside this cleanup; no instant universal-erasure claim is made.

### External integrations

- App Check: register Android Play Integrity or Web reCAPTCHA v3, enable ENABLE_APP_CHECK, and supply RECAPTCHA_SITE_KEY for Web. Register debug tokens only in development. Inspect metrics before enabling server enforcement; the client flag does not enforce server policy. https://firebase.google.com/docs/app-check/flutter/default-providers
- Crashlytics: Android release collection requires ENABLE_CRASHLYTICS=true, correct Firebase configuration and a verified test crash. Debug/emulator collection is disabled. https://firebase.google.com/docs/crashlytics/flutter/get-started
- Push: verify Android notification permission, blood_requests channel, token refresh, foreground/background delivery and tap navigation on a device. Queuing is not proof of delivery.
- Optional SMS: configure genuine TWILIO_SID, TWILIO_PHONE and Secret Manager TWILIO_AUTH_TOKEN. Linked verified phone and notification preferences are required. No SMS was sent in this pass.
- Maps: configure restricted platform API keys and billing as applicable. Do not embed server secrets in Flutter.
- Support: supply a real managed mailbox with --dart-define=SUPPORT_EMAIL=...; no fabricated address is provided.

## Android build

```powershell
flutter config --jdk-dir="<installed JDK 17 directory>"
flutter doctor -v
flutter build apk --debug
```

The local attempt failed with Java 25.0.3 and Gradle 8.13 incompatibility; no APK was validated. CI specifies JDK 17 and uploads a debug demo APK. Existing release configuration uses debug signing: configure a private release keystore before distribution. Java compatibility: https://docs.gradle.org/current/userguide/compatibility.html

See [verification and demo checklist](docs/verification.md) for actual results and blockers. Educational use only; this application does not replace clinical screening or emergency services.
