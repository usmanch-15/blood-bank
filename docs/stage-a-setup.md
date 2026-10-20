# Stage A operator setup (commands were not deployed)

Use a staging Firebase project first. Preserve the real Firebase config already in this repository. Do not substitute a demo config in source. Demo IDs below are only for emulator testing.

## Local checks

From the repository root, in PowerShell:

```powershell
flutter pub get
flutter analyze
flutter test
npm.cmd --prefix functions test
npm.cmd --prefix functions run check
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --project demo-blood-bank --only auth,firestore,storage "npm.cmd --prefix functions run test:emulator"
flutter build apk --debug
```

Use an installed Java 21+ runtime for the emulator; adjust JAVA_HOME if Android Studio is elsewhere. The existing Flutter Android configuration uses Java 17. Functions target Node 22; this machine ran tests with Node 24.15.0, so repeat in Node 22 in CI before release. The full Flutter suite has a pre-existing contradictory phone-format expectation documented in the report.

## Firebase and Agora configuration

1. In Firebase Console, select the intended staging project and enable billing on Blaze for Cloud Functions. Verify Authentication email/password and the existing phone-verification provider, Firestore, Storage and Cloud Messaging. Preserve the hospital catalog and IDs. Keep existing Android app registration, google-services.json and lib/firebase_options.dart aligned with that project.
2. Verify Android SHA fingerprints for phone authentication, FCM device registration, notification OS permission and the existing notification preferences. Verify App Check registration before enabling enforcement; do not turn enforcement off to bypass errors. Optional runtime defines already supported: ENABLE_APP_CHECK, RECAPTCHA_SITE_KEY and ENABLE_CRASHLYTICS. For Android emulator-only app testing use USE_FIREBASE_EMULATORS=true and FIREBASE_EMULATOR_HOST=10.0.2.2; do not release that build.
3. In Agora Console, use an RTC project with token authentication. Put its App ID in the ignored `functions/.env.<project-id>` as `AGORA_APP_ID=<your-app-id>`. Never put its certificate in Flutter, source control or a command argument. Enter the certificate interactively with the secret command below.
4. Existing SOS SMS integration uses TWILIO_SID and TWILIO_PHONE parameters plus TWILIO_AUTH_TOKEN secret. Preserve its existing setup. Do not invent values for unavailable credentials. Deploy only the listed Stage A functions to avoid unrelated setup prompts.
5. Review Firestore rules before deploying. No new index is required: request discovery filters status and orders document ID; the existing users matching index covers latitude-band queries. Existing indexes and Storage rules remain unchanged.

Operator commands, **only after review** (replace `YOUR_STAGING_PROJECT_ID`):

```powershell
node functions/node_modules/firebase-tools/lib/bin/firebase.js login
node functions/node_modules/firebase-tools/lib/bin/firebase.js functions:secrets:set AGORA_APP_CERTIFICATE --project YOUR_STAGING_PROJECT_ID
node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy --only firestore:rules --project YOUR_STAGING_PROJECT_ID
node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy --only functions:createBloodRequest,functions:createSosAlert,functions:findDonors,functions:discoverRequests,functions:notifyRequest,functions:onBloodRequestCreated,functions:notifyNearbyDonorsOnSOS,functions:getDonorContact,functions:onChatMessageCreated,functions:createVoiceCallSession,functions:getVoiceCallToken,functions:updateVoiceCallSession --project YOUR_STAGING_PROJECT_ID
```

The existing `sendPushNotification` trigger must already be deployed; for a fresh environment include `functions:sendPushNotification` in the deployment list. The new message trigger creates one generic notification document; that existing trigger delivers it according to user preferences. Notifications never include chat content. Function-trigger retries do not duplicate the inbox record; network-level exactly-once FCM delivery is not guaranteed.

## Compatibility and rollback

Deploy backend/rules before distributing the new client. Old clients that omit radius now search 5 km; values above 1000 are capped. Old clients calling getDonorContact receive permission-denied: acceptance alone is no longer phone-sharing consent. Explicit sharing is Stage C. New/changed user coordinates must fit the Pakistan bounding box; unchanged legacy coordinates can remain during unrelated profile edits. New hospital writes and request creation must be in bounds. Existing out-of-bounds records are not deleted or rewritten.

No migration is needed. To roll back, restore the reviewed prior source/rules and rebuild/redeploy only those artifacts. Remove the new trigger if rolling back its feature:

```powershell
node functions/node_modules/firebase-tools/lib/bin/firebase.js functions:delete onChatMessageCreated --region us-central1 --project YOUR_STAGING_PROJECT_ID
```

That deletion command is documentation only. Existing chat, notifications, user records and request IDs need no deletion. Restoring the old contact callable would reintroduce automatic phone disclosure; retain its denial if rolling back unrelated changes.

## Device limitations

Foreground incoming pushes open a ringing screen. Background/terminated notifications open it after the user taps and authentication finishes. This is not native background VoIP/CallKit integration and cannot guarantee ringing while killed. Stage F still owns busy/missed timeout management, lifecycle cleanup, mute/speaker, pre-acceptance calls, invitations and the post-call readiness prompt. Do not advertise fully verified calling until two-device Agora/FCM testing is complete.
