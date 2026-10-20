
## Stage F implementation pass

| Item | Status | Proof |
|---|---|---|
| F1 owner pre-acceptance call authorization | NEW CODE ADDED | `functions/voiceWorkflows.js` `createVoiceCallSession` now permits the request owner to call an active, compatible, eligible donor within 1000 km before acceptance; accepted-participant rules remain unchanged. |
| F2 Agora call states/controls | PARTLY | Existing `VoiceCallScreen` and `AgoraVoiceController` provide ringing/connecting/connected/ended, microphone permission, answer/reject/end; timeout, lifecycle/network recovery and mute/speaker controls remain incomplete. |
| F3 Is donor ready dialog | NOT DONE | No new post-call readiness transition was added. |
| F4 inviteDonor and donor Confirm | NEW CODE ADDED | `functions/voiceWorkflows.js` `inviteDonor` creates an idempotent request invite and notification; exported in `functions/index.js`. Existing `acceptDonation` remains the donor confirmation path. Receiver tracking UI for invite status is not added. |
| F5 phone safety | ALREADY EXISTED | Existing call backend returns tokens only; no phone number is exposed. |
| F6 localization/UI | PARTLY | Existing call localization is reused; new invite notification text is generic English backend text. |
| F7 preservation | ALREADY EXISTED | Stage G, Stage E UI, analytics and redesign were not touched. |

Changed backend files: `functions/voiceWorkflows.js`, `functions/index.js`. New callable: `inviteDonor`. No rules or indexes changed. Deploy command when authorized: `firebase deploy --project <staging-project> --only functions`; configure `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` as Firebase params/secrets, enable microphone permissions, and use a Blaze-capable Firebase project. No credentials were placed in Flutter code or logs.

Validation: `npm test` passed (11 tests, 0 failures). `npm run check` passed. Flutter formatting/analyze/tests, emulator suite, builds, real-device audio, FCM delivery, background/terminated call behavior were not run per request.

Manual checklist: Receiver starts a call to an available matching donor before acceptance; donor receives the generic invite and can accept through existing `acceptDonation`; verify duplicate invite is idempotent; verify rejected/closed/pending-review-rejected requests fail; verify Agora token setup and microphone permission on two devices. Post-call readiness and full lifecycle controls remain future work.

STAGE F: INCOMPLETE — pre-acceptance authorization and inviteDonor backend support are implemented, but readiness flow, complete call controls/lifecycle, localized invite UI, and end-to-end device validation remain.

## Stage F continuation

Connected the donor-map Call action to the existing `VoiceCallScreen` and authorized `createVoiceCallSession` flow in `lib/screens/maps/nearby_donors_map_screen.dart`; removed the previous Stage B unavailable-call message for this path. No phone number is shown.

Remaining Stage F work is still incomplete: the post-call “Is donor ready?” transition, full mute/speaker/lifecycle/network/timeout states, incoming invite UI and invite status on tracking, and complete English/Urdu localization are not implemented. Existing Agora scaffolding remains safe when credentials are missing.

STAGE F: INCOMPLETE — call entry and backend invitation/pre-acceptance authorization are connected, but readiness flow, complete call controls/lifecycle, invite UI/status, and device validation remain.

## Stage F readiness continuation

NEW CODE ADDED:
- `lib/screens/communication/voice_call_screen.dart`: returns `true` only when the call screen ended while `_state == connected`; otherwise returns false/null.
- `lib/screens/maps/nearby_donors_map_screen.dart`: `_callAndAskReady` awaits the call result and shows the localized readiness dialog only after a genuine connected result. A No answer adds the donor UID to a per-request in-memory not-ready set, removing that donor from the current map/list and preventing another invite during the screen session.
- `lib/l10n/app_localizations.dart`: added `donorReadyQuestion`, `donorReadyYes`, and `donorReadyNo` English/Urdu keys.

The not-ready marker is intentionally local to the current request screen because the accepted backend has no callable/field for per-request donor readiness. Persisting it server-side would require a new backend schema and rules change, which is outside this pass.

No Flutter checks, tests, emulator suite, or build were run per request. No backend files were changed in this continuation.

STAGE F: INCOMPLETE — the connected-call readiness dialog and local not-ready filtering are implemented, but server-side persistence of not-ready status, complete call controls/lifecycle, invite UI/status, and device validation remain.

## Stage F controls and invitation continuation

NEW CODE ADDED:
- `lib/services/voice_call_service.dart`: `AgoraVoiceController.setMuted` and `setSpeaker` delegate to the active Agora engine.
- `lib/screens/communication/voice_call_screen.dart`: mute/speaker controls, 45-second incoming-ring timeout, lifecycle observer cleanup, cancellation on dispose, and explicit failed/connected state mapping. The existing result remains true only after a connected state.
- `lib/screens/maps/nearby_donors_map_screen.dart`: a connected readiness Yes now calls `inviteDonor`; duplicate taps are naturally guarded by the existing call flow, and localized success/error feedback is shown. No keeps the donor hidden for the current request session.
- `lib/l10n/app_localizations.dart`: invitation success/failure strings in English and Urdu.

Backend invite validation remains the previously implemented callable; no backend files were changed in this continuation. The accepted backend still lacks a persisted per-request not-ready field, so that state remains session-local.

Known limitations: network-loss recovery, OS-level background/terminated ringing UI, a dedicated busy state, and donor-side invite Confirm/Decline/request-tracking status UI are not yet implemented. Agora credentials still require Firebase `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` configuration; the certificate is never placed in Flutter code. No deployment occurred.

No tests, Flutter checks, emulator suite, or builds were run per request. Dart files edited were reread for imports and balanced delimiters.

STAGE F: INCOMPLETE — call controls, ring timeout, lifecycle cleanup, readiness invitation and localization were added, but network/background handling, donor invitation UI/status, persisted not-ready state and device validation remain.

## Stage F finalization continuation

NEW CODE ADDED:
- `lib/services/push_navigation_service.dart`: `donor_invite` notifications now route to authorized request tracking.
- `lib/screens/requests/request_tracking_screen.dart`: donor invitation documents under `blood_requests/{requestId}/invites/{uid}` are read and rendered with Confirm/Decline actions. Confirm calls existing `acceptDonation`; Decline calls existing `declineRequest`; controls use the screen busy guard.

ALREADY EXISTED:
- Agora mute/speaker/end controls, 45-second ring timeout, lifecycle cleanup, connected-call result, readiness dialog and `inviteDonor` call from the map.
- Backend invite idempotency and generic notification payload.

NOT DONE:
- Persisted not-ready state: no accepted per-request field/callable exists; current behavior remains session-local.
- Busy-state detection, robust network reconnection, and full background/terminated ringing UI remain unavailable in the current architecture.
- Receiver invite status is only indirectly visible through the donor invite document; no dedicated receiver status panel was added.

No backend files were changed in this continuation, so npm commands were not required. No tests, Flutter checks, emulator suites, builds, device tests, deployment, commit, or production data changes were performed. Agora setup remains `AGORA_APP_ID` plus Firebase secret `AGORA_APP_CERTIFICATE`, with microphone permissions and a Blaze-capable Firebase project. Background/terminated delivery remains limited to the existing FCM notification/tap path; no CallKit/full-screen guarantee is made.

Manual two-phone checklist: receiver opens donor map and calls a matching donor; both answer and verify mute/speaker/end; after a genuinely connected call choose Yes and verify the donor receives a generic invite; donor taps the notification, opens tracking, Confirm calls `acceptDonation`, Decline calls `declineRequest`; verify duplicate taps are disabled and no call/invite completes a donation.

STAGE F: INCOMPLETE — invitation Confirm/Decline routing is added, but persisted not-ready state, reliable busy/network handling, dedicated receiver invite status and real-device validation remain.

## Stage F invitation/status verification pass

Concrete fixes:
- `functions/voiceWorkflows.js` `inviteDonor` now rejects requests whose `reviewStatus` is present and not `approved`, preventing invitations from bypassing emergency review.
- `functions/requestWorkflows.js` `acceptDonation` and `declineRequest` now persist invite status (`confirmed`/`declined`) under `blood_requests/{requestId}/invites/{donorId}` using the existing transaction paths.
- `lib/screens/requests/request_tracking_screen.dart` shows live receiver-side invitation statuses from the subcollection.
- `lib/l10n/app_localizations.dart` adds localized Invited, Confirmed and Declined labels.

Validation: `npm test` passed (11/11); `npm run check` passed. Flutter checks/builds/emulator/device tests were not run by restriction.

Persisted fields used: invite `status`, `donorId`, `requesterId`, `createdAt`, `updatedAt`; no new collection or rules were added. Existing Firestore rules permit participant/admin reads of the parent request but do not explicitly grant subcollection reads to the requester; if deployed rules reject this subcollection query, a narrowly scoped rules addition is required before the receiver status panel can work. No deployment occurred.

STAGE F: INCOMPLETE — invitation review-state enforcement and live status display were added, but subcollection read-rule verification, reliable busy/network handling, persisted not-ready state, background/terminated limitations and device validation remain.

## Stage F verification pass

### STEP 0 findings

| Item | Status | Evidence |
|---|---|---|
| Call controls/lifecycle | PARTLY | `voice_call_screen.dart` and `voice_call_service.dart` provide mute, speaker, end, permission, timeout and cleanup; network-loss recovery and busy detection are unavailable. |
| Post-call readiness | PARTLY | `nearby_donors_map_screen.dart` gates readiness on a connected result and invokes `inviteDonor`; No remains session-local because no accepted persistence callable/field exists. |
| Invitation workflow | PARTLY | `voiceWorkflows.js`, `request_tracking_screen.dart` and `push_navigation_service.dart` provide authorization, idempotency, notification routing, Confirm and Decline; background delivery remains platform-limited. |
| Per-request not-ready persistence | MISSING | No safe existing request field or callable supports donor-specific readiness refusal. |
| Background/terminated calls | PARTLY | FCM tap routing exists, but reliable terminated ringing/full-screen recovery is not implemented. |
| Localization/phone safety | PARTLY | Tokens contain no phone data; call-control tooltips were localized in this pass, while platform limitations remain. |

### Changes in this pass

- `lib/screens/communication/voice_call_screen.dart`: maps Agora disconnected/reconnecting states to a visible connection-lost state and uses localized microphone/speaker tooltips and connection error text.
- `lib/l10n/app_localizations.dart`: added English/Urdu call-control and connection-loss strings.
- No backend, rules, data models, tests or production data changed.

### Validation

No tests, Flutter commands, emulator/device checks, builds, deployment, commit or production-data changes were performed in this pass. Edited Dart files were reread for balanced delimiters, imports and localization references.

### Remaining Stage F limitations

Per-request not-ready persistence requires a new backend callable and field; busy-state detection and robust network recovery require validated Agora/device behavior; terminated/background ringing remains subject to Android FCM and platform configuration. Agora requires `AGORA_APP_ID`, Firebase secret `AGORA_APP_CERTIFICATE`, microphone permission, and a Blaze-capable Firebase project. No credentials were placed in Flutter code or logs.

STAGE F: INCOMPLETE — call-state localization and disconnect handling were improved, but persisted not-ready state, reliable busy/network recovery, platform-level background ringing, and device validation remain unavailable.

Validation update: `npm test` passed (11/11). `npm run check` passed. `npm run test:emulator` was attempted but failed immediately because the required Firebase emulator environment variables were not set; it was not run through `emulators:exec`. No Flutter checks or build were run.

## Stage F2 continuation

### Implemented

- `functions/voiceWorkflows.js`: added `markDonorNotReady` with requester ownership, open/expiry checks, donor candidacy validation, idempotent subcollection write, and short per-request rate limit. Added active-call detection for ringing/accepted sessions, returning a busy error before creating a new session.
- `functions/index.js`: exported `markDonorNotReady`.
- `firestore.rules`: added owner/admin read-only access to `blood_requests/{requestId}/notReadyDonors/{donorId}`; all client writes remain denied and donors cannot read the state.
- `lib/screens/maps/nearby_donors_map_screen.dart`: loads persisted not-ready donor IDs for the current request and calls the callable when No is selected. Other requests and global donor search remain unaffected.
- `lib/services/voice_call_service.dart` and `lib/screens/communication/voice_call_screen.dart`: added Agora token-expiry callback, backend token refresh and engine token renewal; connection-loss states show an error and clean-up continues through the existing end path.

### Validation

- `npm test`: passed, 11/11.
- `npm run check`: passed.
- `flutter analyze`: stalled with no output and was interrupted; no pass claimed.
- `flutter test`: stalled with no output and was interrupted; no pass claimed. The known phone-format test was therefore not completed in this run.
- `flutter build apk --debug`: stalled with no output and was interrupted; no build result claimed.
- Firebase emulator tests were not run through `firebase emulators:exec` in this continuation; no emulator count is claimed.

### Open risks and rollback

The not-ready callable and rules are additive and can be rolled back by removing the export, callable implementation, rules match, and Flutter callable/read path. Busy detection depends on timely call-session status/expiry data. Agora token renewal requires valid backend credentials and SDK callback delivery. A full-screen terminated-call experience still requires native Android full-screen intent or a CallKit-style package; adding one would trade dependency size and platform complexity for stronger ringing UX. No package was added.

### Needs two real Android phones

FCM delivery, Agora audio, incoming-call UI from background and terminated state, token renewal during a long call, and busy-state behavior require two-device validation. Required setup remains `AGORA_APP_ID`, Firebase secret `AGORA_APP_CERTIFICATE`, microphone permission, FCM configuration, and a Blaze-capable Firebase project.

STAGE F: PARTLY — per-request not-ready persistence, owner-only rules, busy-call rejection and token renewal are implemented, but Flutter analyze/test/build stalled, emulator/rules tests were not completed, and real-device/background validation remains outstanding.

## Stage F3 verification

Added verification tests in `functions/test/emulator.test.js`:
- `not-ready state is owner-only, idempotent, and never exposes contact data` covers owner success, idempotency, donor read denial, direct-write denial, and contact-field absence.
- `busy donor call is rejected and free donor call remains subject to provider configuration` covers active ringing-call busy rejection.

`npm test` remains 11/11 because its configured script runs only policy/hospital tests; the new emulator tests are separate. `npm run check` passed.

Flutter diagnosis: `flutter --version` was attempted first and stalled with no output, then was interrupted. Per the requested procedure, Flutter commands were not retried. Run these on a working Flutter installation: `flutter --version`, `flutter doctor -v`, `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --debug`. No Flutter result is claimed.

Java 21 was available at `C:\Program Files\Android\Android Studio\jbr` and verified as OpenJDK 21.0.6. `firebase.cmd emulators:exec --only auth,firestore,functions --project demo-blood-bank "npm.cmd run test:emulator"` could not start because Firebase CLI was denied access to `C:\Users\premier\.config\configstore\firebase-tools.json` (EPERM). Emulator test count is therefore not available.

Flutter widget tests requested for tap-sheet actions, readiness gating, persisted not-ready filtering, busy suppression, and token renewal were not added in this verification pass because Flutter could not start and the repository's existing Flutter test harness was not runnable. This remains an open verification item.

NOT RUN: Flutter doctor/pub get/analyze/test/build after the initial Flutter stall; emulator suite after Firebase CLI EPERM; real-device FCM, Agora, terminated-call, token-renewal and busy-state checks.

Rollback: remove the two added emulator tests only; no production code was changed in this verification pass beyond the already-present F2 implementation.

STAGE F: PARTLY — backend verification tests were added and npm checks pass, but Flutter is not runnable in this environment, emulator execution is blocked by Firebase CLI config permissions, and requested Flutter widget tests and real-device checks remain unverified.

## F3 command rerun results

- Java 21: passed (`Android Studio\jbr`, OpenJDK 21.0.6).
- `flutter pub get`: stalled with no output and was interrupted.
- `flutter analyze`: stalled with no output and was interrupted.
- `flutter test` and `flutter build apk --debug`: not started after the Flutter tool stalled during setup; no results claimed.
- `npm test`: passed, 11/11.
- `npm run check`: passed.
- `firebase emulators:exec --only firestore,functions,auth --project demo-blood-bank "cd functions && npm run test:emulator"`: blocked before emulator startup by Firebase CLI EPERM reading `C:\Users\premier\.config\configstore\firebase-tools.json`; no emulator count claimed.

## Build-error cleanup verification

Targeted fix: `lib/screens/receiver/receiver_dashboard_screen.dart` now hides the duplicate `UrgencyBadge` export from `premium_ui.dart`, resolving ambiguity with the canonical `status_badge.dart` implementation. `admin_web_requests.dart` is present and was not rewritten. No backend behavior or production configuration changed.

Verification: `npm test` passed 11/11; `npm run check` passed. `flutter pub get` stalled with no output and was interrupted, so `flutter analyze` and `flutter test` could not be completed; no APK build was attempted. Firebase emulator tests were not run in this pass.
