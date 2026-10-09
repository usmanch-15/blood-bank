# Smart Blood Bank

Smart Blood Bank is a Flutter and Firebase final-year project for coordinating blood donors, receivers, emergency requests, and administrator review.

## Implemented and ready in the repository

- Email/password authentication, account restoration, approved-account checks, password recovery, and donor/receiver capability switching.
- Secure user profiles with private contact/CNIC storage, opt-in approximate location sharing, availability, and account deletion workflows.
- Server-controlled blood requests with hospital coordinates, requested/donated/remaining units, deadlines, donor assignment, withdrawal, reassignment, completion, cancellation, and expiry handling.
- Server-side donor discovery with blood-group compatibility, eligibility, availability, consent, distance filtering, and self-exclusion.
- Hospital location selection with a required map pin and manual coordinate fallback.
- Active request tracking, assignment events, donor contact authorization, SOS linking, and SOS owner/participant authorization.
- Donation history, reward points, eligibility intervals, and donation acknowledgements generated from confirmed records.
- Paginated request, donation, notification, report, reward, and audit views. Admin analytics uses Firestore aggregation queries rather than downloading whole collections.
- Per-device notification token registration, refresh handling, invalid-token cleanup, notification preferences, and notification history.
- Admin user/request/report/notification management, audited workflow actions, audit browsing, and paginated exports.
- Firestore security rules, indexes, backend policy tests, emulator security tests, and callable workflow tests.

The application targets Android and web in this repository. There is no iOS project, so iOS support is not claimed.

## Not deployed or fully verified

### Requires Firebase Blaze and Functions deployment

Cloud Functions are present but are not deployed from this repository. Blaze is required for Cloud Build, Artifact Registry, callable workflows, scheduled request expiry, eligibility reminders, notification triggers, SOS matching triggers, and server-side admin workflows.

### Requires Firebase Console configuration

- Enable Email/Password and Phone Authentication.
- Configure authorized domains and web reCAPTCHA for browser phone authentication.
- Register App Check providers and inspect metrics before enabling enforcement.
- Configure FCM/APNs credentials and notification settings.
- Configure restricted map/routing keys and any required billing.
- Configure a managed support mailbox with `--dart-define=SUPPORT_EMAIL=...`.
- Configure a private release keystore before distribution.

### Requires real-device or browser testing

OTP delivery, Android automatic verification, web phone confirmation, push delivery and tap navigation, token refresh across multiple devices, App Check attestation, maps/location permissions, signed Android builds, accessibility, dark mode, and narrow-screen layouts require external testing.

## Local setup

Use the committed lockfiles. The project uses Flutter, Node 22 for Functions, and JDK 17 for Android builds. JDK 21 is suitable for Firebase emulator tooling.

```powershell
flutter pub get
npm.cmd ci --prefix functions
flutter analyze
flutter test
npm.cmd --prefix functions run check
npm.cmd --prefix functions test
```

Run the emulator security suite through the Firebase emulator runner:

```powershell
functions\node_modules\.bin\firebase.cmd emulators:exec --project demo-blood-bank --only firestore,auth,storage "npm.cmd --prefix functions run test:emulator"
```

Start the local demo environment:

```powershell
functions\node_modules\.bin\firebase.cmd emulators:start --project demo-blood-bank --only auth,firestore,functions,storage
flutter run -d chrome --web-port 5195 --dart-define=USE_FIREBASE_EMULATORS=true
```

For an Android emulator, also pass `--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2`. Release builds reject emulator mode.

## Controlled Firebase rollout

Use a staging project first. Review `firestore.rules`, `firestore.indexes.json`, `storage.rules`, and `functions/migrateProfiles.js`. Keep Admin SDK credentials outside source control. Back up Firestore, run the profile migration as a reviewed operation, deploy rules/indexes, deploy Functions on Blaze, and verify rollback procedures before production use.

The project intentionally does not include chat, blood drives, localization, hospital accounts, inventory management, or a clinical blood-stock system. The app coordinates donors and receivers; it does not replace clinical screening or emergency services.

## Android build

```powershell
flutter config --jdk-dir="<installed JDK 17 directory>"
flutter doctor -v
flutter build apk --debug
flutter build apk --release
```

When `android/key.properties` is absent, the release APK uses Android's debug signing key for local testing only. This build is not production-ready and must not be distributed as an official release. To create a distributable APK, configure `android/key.properties` and a private release keystore; release builds automatically use that signing configuration when present. Keep both files private and out of source control.

See `docs/app-review-2026-10-06.md` for the detailed production-readiness review and remaining external checks.
