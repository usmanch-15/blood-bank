# Blood Connect — Smart Blood Bank

Blood Connect is a Flutter + Firebase application that helps receivers find compatible, available donors and lets donors manage responses, requests, donations, notifications, and account settings. It is a coordination tool; qualified healthcare staff must confirm medical eligibility and emergency services remain the correct response for emergencies.

## App capabilities

- Email/password sign-in, password reset, account restoration, approved-account checks, and donor/receiver capability switching.
- Donor profiles with availability, opt-in approximate location sharing, profile photos, verification status, private contact data, account deletion, and English/Urdu localization.
- Blood requests with hospital selection, OSM map pinning, urgency, blood group, units, deadlines, review states, cancellation, expiry, and live tracking.
- Server-side donor matching using compatibility, recorded eligibility, availability, consent, radius, urgency, and distance ranking. Returned locations are privacy-rounded.
- Donor request discovery with map/list views, cursor paging, response actions, My Responses, and request status updates.
- Donor map cards with cached avatars, blood-group fallback markers, approximate distance, safe call/invitation actions, and per-request not-ready handling.
- Donation commitments and history, acknowledgement/dispute workflows, rewards, certificates, reminders, and admin review queues.
- Participant chat with pagination, unread counters, block/report controls, read-only closed-request states, and explicit phone sharing through typed system messages.
- Authenticated Agora voice-call flow with server-issued tokens, busy-call checks, invitations, readiness prompts, and FCM notification routing.
- FCM notification inbox, device-token refresh, user preferences, request/response/chat notifications, and notification tap routing.
- Admin dashboard with users, requests, verification, emergency review, reports, broadcasts, analytics, audit logs, and paginated exports.
- Firestore/Storage security rules, composite indexes, callable authorization, rate limits, and emulator security/workflow coverage.

The repository targets Android and web. There is no iOS project, so iOS support is not claimed.

## Architecture and services

- Flutter client with Provider controllers and named routes.
- Firebase Auth, Firestore, Storage, Cloud Functions, Cloud Messaging, Crashlytics, and App Check integration.
- OpenStreetMap through `flutter_map` and `latlong2`; no Google Maps API key is required.
- Agora is used for in-app voice calls. The Agora certificate is server-only.
- Optional Twilio SMS fallback is server-side and disabled until explicitly configured.

## Local development

Use the committed lockfiles. Functions target Node.js 22. Android uses Java 17; Java 21 is suitable for Firebase emulator tooling.

```powershell
flutter pub get
npm.cmd ci --prefix functions
flutter analyze
flutter test
npm.cmd --prefix functions run check
npm.cmd --prefix functions test
```

Run the complete local emulator suite with the demo project ID:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase.cmd emulators:exec --only firestore,functions,auth,storage --project demo-bloodbank "cd functions && npm run test:emulator"
```

For an Android emulator, use `--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2`. Emulator mode must never be used for release builds.

## Firebase rollout

Use a staging Firebase project first. Review and deploy `firestore.rules`, `storage.rules`, and `firestore.indexes.json` together, then deploy Functions on a Blaze project:

```powershell
firebase deploy --project <staging-project> --only firestore:rules,firestore:indexes,storage
firebase deploy --project <staging-project> --only functions
```

Required console/operator configuration includes:

- Email/Password and Phone Authentication, authorized domains, reCAPTCHA, Android SHA fingerprints, and FCM credentials.
- App Check registration and metrics review before enforcement.
- `AGORA_APP_ID` plus the Firebase secret `AGORA_APP_CERTIFICATE`.
- Optional Twilio values and `TWILIO_AUTH_TOKEN` only if SMS fallback is enabled.
- A managed support mailbox through `--dart-define=SUPPORT_EMAIL=...`.
- Backups, migration review, indexes, rollback procedures, and admin account setup.

Never place service-account keys, Firebase CLI config, `.env` files, Agora certificates, Twilio tokens, keystores, or `android/key.properties` in Git.

## Android release

Current app version: `1.0.0+2`.

Release signing requires the private files `android/upload-keystore.jks` and `android/key.properties`. `android/app/build.gradle.kts` fails the build when `key.properties` is missing and never falls back to the debug key.

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:GRADLE_USER_HOME = "C:\Users\premier\.gradle"
cd android
.\gradlew.bat signingReport
cd ..
flutter build appbundle --release
```

Back up the keystore and properties file in encrypted private storage. Losing the keystore prevents future updates to the same Play application.

## Current limitations and release checks

- Production Firebase deployment and console settings require operator verification.
- Real-device FCM, Agora audio, token renewal, busy calls, background/terminated incoming calls, location/microphone/notification permissions, and accessibility still require device validation.
- Admin abuse-flag visibility depends on the available backend account/report schema.
- Stage H visual polish is incomplete across some screens and requires responsive light/dark/Urdu review.
- The app does not provide hospital inventory, clinical blood-stock management, medical clearance, or emergency dispatch.

See the stage reports in `docs/` and `docs/app-review-2026-10-06.md` for implementation evidence, deployment notes, rollback guidance, and manual checklists.
