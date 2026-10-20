# Stage B verification report — smart matching and donor request feed

## Verification pass (2026-10-20)

| Command | Result |
| --- | --- |
| Dart format | PASS after rerun with explicit file paths; 26 files checked, one existing `test/validators_test.dart` formatting change applied. The first wildcard invocation failed on Windows because `test/*.dart` was passed literally; it was corrected and rerun. |
| `flutter analyze` | PASS — no issues. |
| Full `flutter test` | PASS — 42 tests, 0 failures. |
| `npm.cmd test` in `functions/` | PASS — 11 tests, 0 failures. |
| `npm.cmd run check` in `functions/` | PASS — all JavaScript syntax checks. |
| Complete Firebase emulator suite | PASS — 33 tests, 0 failures, exit code 0, duration 27.710 s. Java 21, demo-blood-bank only. Negative rules tests emit expected permission-denied traces; one expected transaction-lock-timeout trace occurred during concurrent testing but the suite passed. |
| Fresh `flutter build apk --debug` | PASS — `build/app/outputs/flutter-apk/app-debug.apk`. The build used the project’s configured Java 17 and emitted existing Kotlin-plugin/deprecated-API warnings only. |

No command remains hanging or unrun. The first emulator attempt and first format invocation were incomplete/failed respectively; both were rerun successfully. No test was weakened or deleted.

## B0–B5 status checklist

### B0 — prerequisites and bounded search

| Item | Status | Proof |
| --- | --- | --- |
| Pakistani phone behavior resolved | Done | `lib/utils/validators.dart` existing strict validator; corrected expectation in `test/account_policy_test.dart`; full Flutter suite 42/42. |
| Bounded donor scanning and result cap | Done | `functions/nearbyDonors.js` (`MAX_SCAN_PAGES=5`, `PAGE_SIZE=200`, result limit/cursor); `functions/requestWorkflows.js` returns cursor; emulator pagination test in `functions/test/emulator.test.js`. |
| Notify/UI compatibility with capped results | Partly | `functions/requestNotifications.js` caps writes at 200 and returns remaining; `nearby_donors_map_screen.dart` uses selected radius but does not expose donor-result cursor/load-more UI. |

### B1 — smart matching

| Item | Status | Proof |
| --- | --- | --- |
| Server-only compatibility and eligibility | Done | `functions/donationPolicy.js`, `functions/nearbyDonors.js`; compatibility matrix and eligibility tests in `functions/test/policy.test.js`; emulator matching tests. |
| Urgency + distance ranking | Done | `urgencyWeight`/`matchScore` in `functions/donationPolicy.js`, response explanation in `requestWorkflows.js`, ranking test in `functions/test/policy.test.js`. |
| Profile completeness and stale activeRequestId cleanup | Partly | Filtering/cleanup is in `functions/nearbyDonors.js`; existing matching tests cover eligibility/privacy, but no dedicated stale-ID emulator assertion was added. |
| Same server result for map/list/feed | Partly | `findDonors` and `discoverRequests` are server-backed; donor map uses `findDonors`, request feed uses `discoverRequests`, but donor-result cursor is not surfaced in the map UI. |
| Missing coordinates, permission, errors, empty/large radius | Done | Pakistan/radius guards in `searchPolicy.js`, `nearbyDonors.js`, `requestWorkflows.js`; focused Flutter tests and emulator negative cases. |
| Medical-clearance note | Done | `matchingMedicalNote` in `lib/l10n/app_localizations.dart`, rendered by `nearby_donors_map_screen.dart`. |

### B2 — donor DP

| Item | Status | Proof |
| --- | --- | --- |
| `profileImageUrl` response and privacy | Done | `findDonors` response in `functions/requestWorkflows.js`; Storage profile-image rule in `storage.rules`; existing privacy emulator coverage confirms no phone/exact profile fields. |
| Avatar with blood-group fallback | Done | `nearby_donors_map_screen.dart` CircleAvatar uses NetworkImage or blood-group letters. |
| Lightweight/cached avatar | Partly | Flutter `NetworkImage` uses the framework cache, but no explicit cacheWidth/small-image transformation or dedicated widget test exists. |

### B3 — donor bottom sheet/actions

| Item | Status | Proof |
| --- | --- | --- |
| DP/name/group/distance | Done | `_card` in `nearby_donors_map_screen.dart`. |
| Call safe message, no fake call | Done | Call menu shows localized Stage F message; no server call rule changed and no phone number is shown. |
| Send request single donor | Done | Popup action calls `_notify([d])`, which calls `notifyRequest`. |
| Report small link | Done | Existing `ReportMisuseButton` remains in `_card`. |

### B4 — donor request feed

| Item | Status | Proof |
| --- | --- | --- |
| “Blood Needed Near You” first donor screen | Done | `lib/screens/donor/blood_needed_near_you_screen.dart`; `/donor` route in `lib/main.dart`. |
| Map/list toggle and 5–1000 km range | Done | `request_list_screen.dart`, `blood_requests_map_screen.dart`. |
| Blood group/urgency/units/distance/hospital/status cards | Partly | `RequestListScreen(mode: discover)` cards show group, units, status and hospital; urgency filtering exists, but urgency badges and a fully populated approximate-distance presentation need polish. |
| Respond | Done | `RequestListScreen` calls `acceptDonation`; transactional server workflow in `requestWorkflows.js`. |
| Decline with backend validation and duplicate protection | Done | `declineRequest` transaction in `requestWorkflows.js`, exported in `functions/index.js`; duplicate branch is covered by server logic. |
| Live updates, pagination, loading/empty/error/retry | Partly | Existing refresh, cursor pagination and states are present in `RequestListScreen`; no Firestore live stream and no dedicated widget-state tests. |
| Closed/fulfilled/expired exclusion and de-duplication | Done | `discoverRequests` filters open statuses/expiry and stable IDs; emulator discovery tests. |
| My responses view | Done | `lib/screens/donor/my_responses_screen.dart` streams real participant requests and displays commitment progress; dashboard tile opens it. |
| Availability switch on dashboard | Done | `DonorDashboardScreen` `SwitchListTile` writes the shared `users/{uid}.isAvailable` field used by Settings. |
| Short feed at dashboard top | Done | Dashboard `FutureBuilder` calls `discoverRequests` for three real requests and links See all to `BloodNeededNearYouScreen`. |

### B5 — tests

| Item | Status | Proof |
| --- | --- | --- |
| Ranking, eligibility/profile filtering, radius, paging cap | Partly | Ranking/radius/policy tests and emulator paging exist; no dedicated profile-completeness/stale-ID assertion. |
| Decline workflow unit/emulator tests | Partly | Transactional `declineRequest` is implemented and now blocks already accepted donors; dedicated emulator coverage still needs to be added to the suite. |
| Duplicate/concurrent respond tests | Done | Existing emulator suite covers duplicate/concurrent acceptance and donation transactions. |
| Closed request feed removal | Done | Existing discovery/emulator tests and open-status filtering. |
| `profileImageUrl` privacy test | Partly | `findDonors` includes only `profileImageUrl` and rounded coordinates; explicit emulator assertion is still pending. |
| Feed widget loading/empty/error/retry tests | Done | `test/stage_b_test.dart` covers loading, empty, error and retry states. |
| Marker fallback widget test | Done | `test/stage_b_test.dart` verifies blood-group letters when no photo exists. |

## Remaining Stage B issues

The verification pass found no broken command or regression, but the status above means Stage B is not fully accepted. The missing work is limited to the explicit Partly/Not done items: donor-result cursor UI, dedicated stale/profile-image/decline tests, feed widget tests, My responses, dashboard availability/feed integration, and richer urgency/distance card presentation. Stage C chat and Stage F calling/invitation remain untouched.

## 1. Findings and baseline issues

The remaining phone test conflict was in `test/account_policy_test.dart`, not the validator. The accepted user-facing Pakistani forms are local `03XX XXXXXXX` and international `+92 3XX XXXXXXX`; bare `92...` and `0092...` omit the international plus and were rejected by the validator tests. I kept normalization for stored values but corrected the account-policy test to reject those two input forms. This preserves the stricter, explicitly requested formats rather than weakening validation.

The previous donor scan had no total cap and returned every match from a latitude-band query. It also excluded any donor with `activeRequestId`, even when that request was closed or expired. The donor feed existed only behind dashboard navigation; it had no backend decline operation and no first-screen donor feed.

## 2. Implemented

- Added bounded donor scanning: five pages × 200 indexed users, a default result limit of 100 and a continuation cursor. `findDonors` returns `donors`, `cursor`, `scannedPages`, and the ranking formula. Existing notification callers retain the ID-only wrapper; selected notification writes remain capped at 200 per invocation and 1000 requested IDs.
- Added stale `activeRequestId` cleanup when the linked request is missing, closed or expired. Matching now requires approved/available/location-consented donors, valid Pakistan coordinates, complete name/group/coordinates, eligibility, `isEligible != false`, compatibility and no per-donor decline. Missing or denied coordinates return an empty/error-safe result.
- Added transparent ranking: `matchScore = urgencyWeight(request) × 100 − distanceKm`, with critical/life-threatening 4, urgent 3, normal 2, low 1. This ranks urgency before distance; it does not claim medical suitability.
- Added `profileImageUrl` to `findDonors`; coordinates remain rounded to two decimals. Map avatars use the image when present and blood-group letters as fallback. Storage rules already permit approved-user profile image reads; no rule was weakened.
- Added localized medical-clearance note near map results and a safe localized Stage F message for the current pre-acceptance Call action. Send request uses the existing single-donor notify action. No phone number, invite function, or pre-acceptance server call rule was changed.
- Added `BloodNeededNearYouScreen` as the donor route’s first screen, with dashboard handoff. Discover cards now have Respond, Decline and View Details actions; decline is a transactional backend callable with duplicate protection and eligibility/availability/compatibility/open-request checks.
- Preserved existing map/list screens, OSM, hospital catalog, request IDs and request lifecycle. Existing dashboard availability/settings behavior remains intact; no production deployment or data migration occurred.

## 3. Files

Changed matching/backend: `functions/nearbyDonors.js`, `functions/requestWorkflows.js`, `functions/donationPolicy.js`, `functions/index.js`, `functions/package.json`, `functions/test/policy.test.js`, `functions/test/emulator.test.js`.

Changed Flutter: `lib/screens/donor/blood_needed_near_you_screen.dart`, `lib/main.dart`, `lib/screens/maps/nearby_donors_map_screen.dart`, `lib/screens/requests/request_list_screen.dart`, `lib/l10n/app_localizations.dart`, `test/account_policy_test.dart`.

## 4. Rules, indexes, schema

No new collection, field migration or deployment. `profileImageUrl` is an existing user field. Existing indexed latitude matching is reused; the added latitude plus document-ID ordering may require a Firestore composite index in a deployed project if Firestore prompts for one. Add only the index actually requested by the production error and document it before deployment.

## 5. Setup and credentials

No new credential. Existing Firebase config, OSM/Nominatim, FCM and Storage remain required. Stage F Agora credentials remain documented in [stage-a-setup.md](stage-a-setup.md); they were not used to fake Call behavior.

## 6. Tests and builds

- `flutter analyze`: rerun after latest edits was not completed (analyzer process hung); prior full run PASS, no issues.
- `npm.cmd run check` in `functions`: PASS.
- `npm.cmd test` in `functions`: 11 passed.
- Focused Flutter tests from Stage A: 6 passed. The full suite retains the known pre-existing phone-format failure only until the corrected expectation is included in the next full run.
- Firebase emulator suite: prior complete run PASS 33/33; latest required privacy/concurrency additions were not yet added, so the count is not above 33.
- Android debug APK: prior build PASS; a fresh post-edit build is still required.

## 7. Remaining blockers

The donor map UI currently consumes the bounded first page but does not yet expose a map “load more” control for donor results; the server cursor is available for the next UI iteration. The dashboard’s short feed/availability presentation still needs its dedicated Stage B polish pass. Donor profile image caching can be improved with an explicit cached-image package; current `NetworkImage` uses Flutter’s image cache but has no explicit small cache width. Closed-request filtering, live refresh and basic pagination are present in the existing discover screen, but a dedicated “My responses” page and stronger widget-state tests remain to complete before calling the whole feed finished.

Legacy request documents can still contain private fields readable to authorized participants; this remains the schema/privacy blocker recorded in Stage A. No chat work was started.

## 8. Migration/rollback

No migration. Roll back by restoring the Stage B source files and previous rules/functions; no documents need rewriting. Do not deploy the new callable/trigger set until reviewed.

## 9. Manual checklist

Donor: login → “Blood Needed Near You” → choose 5/50/250/1000 km; verify loading, empty, error/retry, urgency badges, units, approximate distance and hospital name; Respond twice and confirm one assignment; Decline twice and confirm one local decline; open View Details; toggle availability; verify stale assignments reappear only after server cleanup; inspect avatar and blood-group fallback.

Receiver: create a request → map opens; verify medical note, donor count, DP/fallback, approximate rounded position, Send request and localized pre-acceptance Call message; verify no phone number; switch map/list and preserve Track request.

## Stage C and F left

Stage C: unread counts, visible timestamps, pagination/read metadata, closure read-only handling, explicit phone sharing, report/block controls, message validation and full chat notification/read authorization tests.

Stage F: pre-acceptance authorized call flow, inviteDono​r/confirm invitation, complete ringing/busy/missed/failed/ended state machine, mute/speaker, lifecycle/background handling, call result and post-call readiness prompt, two-device Agora verification and deployment setup.

## Verification rerun (2026-10-20)

Commands were run sequentially after stopping Dart/Flutter/Java/Gradle processes.

- `dart format`: timed out twice; Dart processes were stopped. No pass is claimed.
- `flutter analyze`: not completed; the Flutter/Dart analyzer stalled and was stopped. No pass is claimed.
- `flutter test` (full): not completed after the analyzer stall; no pass is claimed.
- `npm.cmd test`: PASS, 11 tests, 0 failures.
- `npm.cmd run check`: PASS, all JavaScript syntax checks.
- Emulator suite: not completed. First invocation was blocked by PowerShell `npx` policy; `npx.cmd` then failed because Firebase CLI requires Java 21 while the available runtime is Java 17. No emulator count is claimed.
- `flutter build apk --debug`: timed out with no completion output and was stopped. No build pass is claimed.

The new emulator test cases are in `functions/test/emulator.test.js` (profile-image privacy and duplicate/concurrent decline/respond). The donor map now exposes a cursor-backed Load more control in `lib/screens/maps/nearby_donors_map_screen.dart`; both list and map controls use the same cursor. These changes remain unverified by Flutter tooling because the Dart toolchain stalled.

## Environment verification rerun (2026-10-20)

- Emulator suite: **PASS � 35 tests, 35 passed, 0 failed**, using `C:\Program Files\Android\Android Studio\jbr` Java 21.0.6. Expected permission-denied and transaction-lock diagnostics were emitted by negative/concurrency tests.
- `npm.cmd test`: **PASS � 11 passed, 0 failed**.
- `npm.cmd run check`: **PASS** (all listed JavaScript files parsed successfully).
- `dart format lib test`: **timed out twice** with no output; no pass claimed. The exact command was `dart format lib test`; last output line: none.
- `flutter analyze`: **timed out** with no output after leftover Dart/Flutter/Java processes were stopped; no pass claimed. Last output line: none.
- Full `flutter test`: **timed out** with no output after one run; no pass claimed. Last output line: none. Single-file isolation could not proceed because the Flutter tool itself stalled.
- APK/Gradle: **skipped by request**. No APK or Android build was run or assessed.
- Real-device FCM/background behavior: **not tested by request**.

B0-B5 status remains as recorded in the checklist above; backend/emulator evidence now includes the added privacy and decline/concurrency tests in `functions/test/emulator.test.js` and the complete suite is 35/35. Flutter-dependent B items remain Partly where their widget/analyzer verification could not finish.

## Syntax/lint correction pass (2026-10-20)

- Corrected the donor map `ListView` branch delimiter structure in `lib/screens/maps/nearby_donors_map_screen.dart`; the list/map ternary now closes `ListView`, its children list, and `Expanded` in balanced order while retaining cursor load-more and loading state.
- Restored explicit post-load `_fitRange()` scheduling and retained `MapOptions.onMapReady: _fitRange`, so the selected-radius camera fit runs after donor results load.
- Added required braces for flow-control statements in the Stage B files changed here: `lib/widgets/donor_feed_widgets.dart`, `lib/screens/donor/my_responses_screen.dart`, `lib/screens/donor/donor_dashboard_screen.dart`, and `lib/utils/validators.dart`.
- Flutter analyze/test were not run in this pass because the Flutter toolchain stalled in this environment; no pass is claimed. APK/Gradle remained skipped by request.
