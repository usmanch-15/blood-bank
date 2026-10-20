# Stage A — audit, implementation and verification

## Baseline (2026-10-20, before edits)

- Working tree was clean (Git invoked with a per-command safe.directory override).
- `flutter analyze`: PASS, no issues.
- `flutter test`: 39 passed, 1 failed: `Pakistani phone formats normalize consistently` in `test/account_policy_test.dart`. Existing validator behavior; not a Stage A regression.
- `npm.cmd test` in functions: PASS, 8 tests.
- Sandboxed Flutter commands produced no output; SDK-cache access required elevated execution.

## Audit and file-level plan

The active app is `lib/main.dart`, using Provider controllers, Firebase Auth and guarded named routes. Login and splash share AccountPolicy; normal accounts currently bypass role selection. Role selection persists mode through AuthService. Suspended/rejected access remains guarded. Request creation uses the authenticated createBloodRequest callable, preserves hospitalId and exact catalog validation, and currently navigates to tracking despite its comment promising a map.

OSM screens: `screens/maps/hospital_location_screen.dart` (catalog, Nominatim, reverse geocoding, GPS and pin selection), `nearby_donors_map_screen.dart` (matching), `blood_requests_map_screen.dart` (discovery). Receiver form, receiver dashboard and donor matching wrapper depend on these. OSRM remains in `services/osrm_routing_service.dart`. No map provider replacement is planned.

Backend policy is in donationPolicy.js: compatibility, haversine distance and 90-day interval. requestWorkflows.js handles pending → accepted → agreed → awaiting_confirmation → completed commitments; requests become partially_fulfilled/fulfilled only after receiver/admin confirmation. Withdraw/release/decline, cancellation and expiry are transactional. Preserve these paths.

Firestore: users with private/contact and device subcollections; hospitals; blood_requests/events; conversations/messages; callSessions; donations; notifications; sosRequests; rewards; audit_logs; rate_limits; reports/misuse_reports/feedback; broadcasts. Rules generally deny client workflow writes. Storage restricts profile image uploads to owners and certificates to donation owners. Participant Firestore request reads still disclose the entire request document (including legacy contact fields); full privacy separation requires a later reviewed schema migration. Chat exists, lacks closure/block/read handling, and has no message trigger. Agora exists but lacks runtime microphone permission and incoming push routing. Admin screens use live data and authenticated admin workflows.

Stage A files: requestWorkflows/index/nearbyDonors for bounded matching and range; new chat trigger module; geo service and map/list screens for consistent radius; AccountPolicy and form navigation; tracking screen for removing dialer; call/push services for microphone and incoming handling; localization; rules and coordinate helpers; tests and README.

## Rules compatibility, migration and rollback (recorded before rules edits)

New or changed saved user coordinates must be within the requested Pakistan bounding box (23.5–37.1, 60.8–77.9). Unchanged legacy coordinates remain allowed during other profile updates. Hospital writes and backend request creation enforce the same box. No existing documents, IDs or fields are rewritten, and no new collection is needed. No migration required. Rollback: restore the previous rules and Stage A source files, rebuild the client and redeploy the previous backend only after operator review. Nothing is deployed by this task.

## Implemented

1. Discovery now queries open statuses, scans pages of 100 (at most 400 reads per invocation), continues past sparse pages and returns a continuation cursor. List and map both expose continuation, including an empty bounded page. The existing cursor remains a document ID, so no schema/index migration is required. Results are distance-sorted within each returned page; global urgency ranking remains Stage B.
2. Removed both tracking-screen dialer actions and disabled the getDonorContact callable for old clients. In-app voice remains available under participant authorization; acceptance alone cannot disclose a donor phone through that callable.
3. Notification matching uses the selected radius (5–1000 km), verifies ownership/open state and rate-limits to 20 attempts/hour. Each invocation creates at most 200 stable donor inbox records and returns a remaining count. Repeated actions continue without duplicating inbox IDs. Existing automatic first-nonempty 5/10/25/50 km matching is preserved; explicit receiver searches can extend to 1000 km. The notification handler was extracted from index.js into requestNotifications.js so the real behavior is emulator-tested.
4. Map and request-list radius choices support 5–1000 km; default 5. Receiver map has all eight quick choices, a meter-based circle and camera fitting. It queries the selected radius rather than downloading a 2000 km result set first. Request-map discovery has a Load more action. Search label already correctly said “Search donor name”; retained it.
5. Runtime microphone permission is requested before creating an outgoing session and before joining an incoming session. Denial shows English/Urdu guidance. Local Agora channel join no longer claims the remote peer connected.
6. Incoming-call notifications route to the existing ringing screen, with duplicate visible-call suppression, authenticated session readiness, and server token/participant checks. Foreground pushes open it; background/terminated notifications require tapping. Server rejects inactive accounts, released donors, closed requests and caller self-answer. Full call lifecycle is Stage F.
7. New onChatMessageCreated trigger checks the two participants and their active assignment/request, notifies only the other participant, and deduplicates concurrent/retried events using the message ID. Payload and notification text omit message content. Tapping opens the existing authorized chat. Preferences and devices use the existing notification delivery service.
8. Removed the Dart compatibility map; dropdowns use the existing blood-group list while eligibility matching stays on the server. Added all 64 compatibility pair assertions.
9. Corrected README’s false chat/localization statement.
10. Shared AccountPolicy now sends normal login/restored sessions to /role-select; admin routing and access guards stay intact. A dual-capability receiver now retains the owner tracking view instead of being mistaken for an assigned donor. Request form’s only behavior change is navigation to NearbyDonorsMapScreen with saved request ID, group and units. Dart formatting also normalized existing form indentation.
11. New/changed saved coordinates are bounded on the server/rules and in the picker/profile/settings paths. GPS/location errors in the settings toggle are handled rather than escaping the callback. Existing OSM tiles, Nominatim search, catalog IDs, hospital selection and reverse geocoding remain connected. Storage rules and Firebase config were not changed.

## Verification

| Check | Baseline | Stage A |
| --- | --- | --- |
| flutter analyze | Pass, no issues | Pass, no issues |
| flutter test | 39 pass, 1 pre-existing failure | 41 pass, same 1 failure |
| npm test | 8 pass | 10 pass |
| npm run check | Not baseline-required | Passed; extended to include new modules |
| Firebase Auth/Firestore/Storage emulator suite | Not baseline-required | 33 pass, 0 fail (final run) |
| Android debug APK | Not baseline-required | Pass; final incremental build completed in 63.6 seconds |

The baseline phone failure conflicts with the validator tests, which deliberately reject bare `92` and `0092` prefixes while the account-policy test expects them accepted. Neither validator behavior nor the failing assertion was masked or changed. The initial emulator launch failed under Java 17; using installed Android Studio Java 21 resolved it. Emulator tests used only demo-blood-bank, with production access explicitly guarded. Permission-denied output during negative rules tests is expected.

Emulator coverage includes dual-role owner tracking, sparse discovery beyond 400 records, 250 km notification range, duplicate notifications, spoofed chat sender, suspended recipient, caller self-answer, outsider calls, coordinate bounds/legacy edits, donor matching privacy, admin authorization, concurrency and donation lifecycle. Final emulator run: 33 passed in 32.4 seconds; local output saved to ignored `docs/stage-a-emulator-results.log`. Actual FCM delivery, Agora audio, interactive OSM tile/camera behavior and physical-device permissions were not exercised by these automated tests. HTTP/browser suites and release build were not run.

## Configuration and operational changes

New deployed function: onChatMessageCreated. Changed callable behavior: discoverRequests, findDonors, notifyRequest, getDonorContact, createBloodRequest/createSosAlert coordinate validation, and voice session endpoints. Trigger dependencies on nearbyDonors also adopt Pakistan bounds. No new collection, field migration or index. Rules only tighten saved coordinate bounds; Storage rules unchanged. permission_handler and its locked platform dependencies were added. Generated Kotlin build sessions are ignored.

See [exact setup and operator commands](stage-a-setup.md). Needed external services/config: Firebase Auth/Firestore/Storage/FCM/Functions on Blaze; existing Firebase app config, hospital catalog, Android SHA fingerprints and release signing setup; AGORA_APP_ID and server-only AGORA_APP_CERTIFICATE; existing TWILIO_SID/TWILIO_PHONE/TWILIO_AUTH_TOKEN for optional SMS. Optional App Check/Crashlytics runtime flags are documented there. Credentials and service readiness were not inferred from source or tested against production.

## Remaining work and blockers

- No commit, push, deployment, production data edit or migration was performed. Changes are local and must be reviewed and deployed before behavior changes in an installed production app.
- The existing participant read rule exposes whole legacy blood_requests documents, including contact fields. Removing UI dialers and disabling donor contact lookup does not fix that broader schema limitation. Private-field separation needs a reviewed schema/rules migration before a production privacy claim.
- Existing chat permits free text and retains participant access after request closure; explicit phone sharing, read-only closure, blocks/reports/unread handling remain Stage C. No new collections were introduced here.
- Existing nearbyDonors pages an indexed latitude band but does not cap total scan/result size. Nationwide/high-density performance and donor result pagination remain Stage B; notifyRequest limits writes, not the total matching scan. UI notification submissions allow at most 1000 selected IDs; larger result sets need the Stage B paging design.
- Saved coordinates use the requested rectangular Pakistan bounds, not a national boundary polygon. Existing out-of-bounds records are preserved and excluded from matching.
- Recorded eligibility flag handling, profile completeness, urgency ranking, stale activeRequestId cleanup, donor avatars/feed and decline actions remain Stage B.
- No credentials are needed to review these changes, but real FCM/Agora testing needs configured services and two authenticated Android devices. Voice state cleanup, timeout/busy, background lifecycle, mute/speaker, invitation and pre-acceptance calls are still Stage F; Stage A is not a claim of production-ready voice.
- Stages B–H were not implemented. The baseline phone test failure remains unresolved.

## Manual staging checklist (not executed)

- Donor: login and restore → role selection; choose Donor; discover at 5/50/250/1000 km; paginate empty sparse pages; compare map/list. Toggle location sharing with GPS denied and with an out-of-bounds location; verify a localized error and no saved change. Check unavailable/suspended accounts are excluded. Receive an incoming-call push and deny/allow microphone permission.
- Receiver: submit using a catalog hospital and an OSM-selected hospital; verify saved hospital ID/details, automatic map, default 5 km, circle/camera fitting, all presets, donor-name search, Track request and list toggle. Notify a compatible donor more than 50 km away; repeat and confirm one inbox record. Verify no phone-dialer actions. Exercise empty/offline/error retry paths in both themes and Urdu/English.
- Both participants: send a message; only the other account receives generic notification text; tap opens authorized conversation. Test foreground/background/cold-start incoming calls and microphone denial. Outsider/suspended/released participants must fail authorization. Verify calls never complete donations.
- Admin: login/restore still opens admin dashboard; ordinary users cannot enter admin routes; existing hospital catalog and review/report workflows remain usable. Verify newly saved hospital coordinates must be in bounds.
- Donation regression: donor accepts, agrees and marks ready; only the existing receiver/admin confirmation completes/credits the donation. Concurrent retries must not add units or rewards twice.

## Exact file manifest

Modified:

- `README.md`
- `android/.gitignore`
- `firestore.rules`
- `functions/index.js`
- `functions/nearbyDonors.js`
- `functions/package.json`
- `functions/requestWorkflows.js`
- `functions/test/emulator.test.js`
- `functions/test/policy.test.js`
- `functions/voiceWorkflows.js`
- `lib/controllers/donor_controller.dart`
- `lib/l10n/app_localizations.dart`
- `lib/screens/communication/voice_call_screen.dart`
- `lib/screens/donor/donor_profile_screen.dart`
- `lib/screens/maps/blood_requests_map_screen.dart`
- `lib/screens/maps/hospital_location_screen.dart`
- `lib/screens/maps/nearby_donors_map_screen.dart`
- `lib/screens/receiver/blood_request_form_screen.dart`
- `lib/screens/requests/request_list_screen.dart`
- `lib/screens/requests/request_tracking_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/services/geo_location_service.dart`
- `lib/services/push_navigation_service.dart`
- `lib/services/settings_service.dart`
- `lib/services/voice_call_service.dart`
- `lib/utils/account_policy.dart`
- `lib/utils/location_helper.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/account_policy_test.dart`

Added:

- `docs/stage-a-report.md`
- `docs/stage-a-setup.md`
- `functions/chatNotifications.js`
- `functions/requestNotifications.js`
- `functions/searchPolicy.js`
- `test/stage_a_test.dart`

Final focused Flutter tests: 6 passed (microphone denial, location boundaries, localization and light/dark theme). Final backend syntax checks passed for all listed modules. Android artifact: `build/app/outputs/flutter-apk/app-debug.apk`. The first native build completed in 564.1 seconds; the final incremental rebuild includes the last Flutter edits. Build warnings concern existing plugins using Kotlin Gradle Plugin and deprecated native APIs; they did not fail the build. No release build or device installation was performed.
