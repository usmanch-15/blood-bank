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

## Stage 1 Cloudflare request-workflow pilot

The Worker in `workers/blood-connect-api` uses Firebase ID-token authentication and the Firestore REST API. Firestore remains the source of truth; no D1 database is used. Stage 1 routes `createBloodRequest`, `acceptDonation`, `declineRequest`, `updateAssignment`, `closeRequest`, `getRequest`, `discoverRequests`, `findDonors`, and `notifyRequest` when its app flag is enabled. Stage 2 adds `markConversationRead`, `blockUser`, `unblockUser`, `reportConversation`, `sharePhoneNumber`, and the post-send `notifyChatMessage` call. Stage 3A routes SOS creation/read/resolution and donation confirmation/history/acknowledgement/disputes when its separate flag is enabled. Other callables continue using Firebase Functions.

Configure `FIREBASE_PROJECT_ID` and the allowed app origins in `workers/blood-connect-api/wrangler.toml`. From that directory, add the service-account JSON as a Worker secret and deploy:

```powershell
npm.cmd ci
npm.cmd test
npx wrangler secret put FIREBASE_SERVICE_ACCOUNT
npx wrangler deploy
npx wrangler tail
```

The service account must belong to the configured Firebase project and have permission to read/write Firestore and send Firebase Cloud Messaging messages. Never commit the service-account JSON. The Wrangler cron trigger runs Worker request expiry every 15 minutes. This source configuration does not prove that the trigger is active: verify it in the deployed Worker's settings. Request matching keeps the existing 90-day donation interval.

Run the app against the Worker with the deployed base URL supplied at build time:

```powershell
flutter run --dart-define=CLOUDFLARE_STAGE1_ENABLED=true --dart-define=CLOUDFLARE_API_URL=https://blood-connect-api.<your-subdomain>.workers.dev
```

For a local web-to-Worker smoke test, use three PowerShell terminals. This uses only demo Firebase emulators and the local Worker:

```powershell
# Terminal 1, repository root
firebase.cmd emulators:start --project demo-bloodbank --only auth,firestore
```

```powershell
# Terminal 2, workers/blood-connect-api
$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080"
npx wrangler dev --local --ip 0.0.0.0
```

```powershell
# Terminal 3, repository root
flutter run -d chrome --web-port=5000 `
  --dart-define=USE_FIREBASE_EMULATORS=true `
  --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1 `
  --dart-define=CLOUDFLARE_STAGE1_ENABLED=true `
  --dart-define=CLOUDFLARE_API_URL=http://127.0.0.1:8787
```

The local Worker settings in `.dev.vars` must remain `ENVIRONMENT=local`, `FIREBASE_PROJECT_ID=demo-bloodbank`, and `AUTH_EMULATOR_MODE=unsigned`; never use unsigned emulator-token mode in a deployed Worker. The local Worker process also needs `FIRESTORE_EMULATOR_HOST` set as shown above.

Rollback immediately by omitting the flag or setting `--dart-define=CLOUDFLARE_STAGE1_ENABLED=false`; the app then uses the existing Firebase callable functions. The flag defaults to `false`. Worker unit tests do not replace a staging Firestore/Functions emulator run or device testing. Before enabling the flag for users, verify request creation and hospital details, matching push notifications, accept/decline, owner cancellation, donor privacy projections, and request expiry. Firebase Functions source no longer exports its request-expiry scheduler; apply the Functions source change when retiring any already-deployed expiry function, otherwise both schedulers may run temporarily. Expiry is idempotent, but the deployed schedule state must be checked.

### Stage 2 chat and notification pilot

The Stage 2 switch is independent and defaults to `false`. In this mode the app continues using Firebase callable chat workflows and the existing Firestore notification trigger. When enabled, the Worker performs the chat callables and receives `notifyChatMessage` after a successful chat-message write. Worker-created notifications set `pushSentDirectly` before delivery, so `sendPushNotification` does not send them a second time. Keep the Firebase trigger deployed as the fallback for notifications not created by the Worker.

Run the Worker unit suite, the Functions notification-trigger unit tests, and the Worker Firestore-emulator integration tests in PowerShell:

```powershell
npm.cmd --prefix workers/blood-connect-api test
npm.cmd --prefix functions test
firebase.cmd emulators:exec --only firestore --project demo-bloodbank "npm.cmd --prefix workers/blood-connect-api run test:emulator"
```

Run the app with Stage 2 routing enabled:

```powershell
flutter run --dart-define=CLOUDFLARE_STAGE2_ENABLED=true --dart-define=CLOUDFLARE_API_URL=https://blood-connect-api.<your-subdomain>.workers.dev
```

To roll back Stage 2 immediately, omit `CLOUDFLARE_STAGE2_ENABLED` or set it to `false`. The Firebase callable workflows and chat notification trigger remain active. The Worker honors `FIRESTORE_EMULATOR_HOST` only when `FIREBASE_PROJECT_ID` starts with `demo-`; production projects always use Google Firestore REST and OAuth.

### Stage 3A SOS and donation pilot

Stage 3A adds `createSosAlert`, `getSos`, `resolveSos`, inline SOS donor matching, `confirmDonation`, `donationHistory`, `acknowledgeDonation`, `disputeDonation`, `submitDonationDispute`, and the existing-denial behavior of `getDonorContact`. SOS matching tries radii of 5, 10, 25, then 50 km. Worker-created SOS and linked request documents carry `source: cloudflare`, so the Firebase SOS and emergency-alert triggers skip them. The app flag `CLOUDFLARE_STAGE3_ENABLED` defaults to `false`; Stage 1 and Stage 2 flags are independent, and Firebase callables remain the fallback when Stage 3A is disabled.

The donation record now stores `status: completed` and `completedAt` when the receiver confirms a donation. These fields are required by the existing acknowledgement and history-label workflows; the Firebase fallback writes the same fields.

Run Worker unit and Firestore-emulator tests from the repository root in PowerShell. The emulator requires Java 21:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
npm.cmd --prefix workers/blood-connect-api test
firebase.cmd emulators:exec --only firestore --project demo-bloodbank "npm.cmd --prefix workers/blood-connect-api run test:emulator"
```

Enable the Stage 3A routing only for a staging build after verifying the emulator and real Firebase staging project:

```powershell
flutter run --dart-define=CLOUDFLARE_STAGE3_ENABLED=true --dart-define=CLOUDFLARE_API_URL=https://blood-connect-api.<your-subdomain>.workers.dev
```

Roll back by omitting `CLOUDFLARE_STAGE3_ENABLED` or setting it to `false`. The real FCM service, Firebase staging project, and physical-device flow must be tested separately; emulator tests do not establish their behavior.

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
