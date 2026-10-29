# Remaining work — 23 October 2026

Latest Firebase-only continuation and results are at the end; earlier verification inventories/counts are historical.

Authoritative current findings: `ui_ux_audit.md` and `production_readiness_audit.md`. Previous dated reports remain historical. Current changes are local/uncommitted, not deployed.

## Priority backlog

| Priority | Task | Dependency / acceptance evidence |
| --- | --- | --- |
| High rollout gate | PRIV-01 locally fixed: stage private canonical rules and donor-safe callables together | 60 emulator tests pass in the latest continuation; no destructive migration/backfill. Old clients must update. Production security not fixed until separately approved deployment and verification. |
| High | INT-02: deploy reviewed backend after approval | Billing disabled, empty v1/v2 inventory and required APIs disabled verified read-only. Secrets/IAM/provider readiness unresolved. Follow firebase-staging-deployment.md. |
| High rollout gate | WF-05 locally fixed: rejected review closes linked request/SOS and releases assignments transactionally | Staging must verify real trigger delivery; already dispatched push/SMS cannot be recalled. |
| Medium rollout gate | CHAT-01 locally fixed: live assignment, deadline, active peers and block checks | Rules and callable regression tests added; history remains readable. Deploy both layers together only after staging approval. |
| Medium | COMPAT-01 residual: inspect sanitized production-schema fixtures in staging | Legacy array-only/empty commitments normalized in memory; explicit withdrawal wins. Commitment-only records without queryable IDs still require a separately reviewed backfill plan. |
| Medium provider gate | LOG-01 locally sanitized | SMS logging uses numeric error code/generic category, no UID or provider text. Real provider failure/delivery still not tested. |
| Medium | Full signup/profile/role/splash visual-system and localization migration | Preserve every validator, field/action and navigation path; light/dark English/Urdu screenshots, 200% text and screen-reader testing. Current signup improvements are partial. |
| Medium | Admin paged SOS/tables, search/filter scope and optional dark theme | Preserve all records via cursors; narrow table/action tests; current admin workspace deliberately uses coherent light theme. |
| Medium | App Check staged rollout | Provider registration and attestation metrics first; separate live-enforcement approval. |
| Medium | Native lifecycle verification | Node 22 CI (local runtime parity verified), Android debug signing-path fix, staging device FCM/OTP/Agora/location/permission flows. |
| Medium | Development dependency advisories | 12 High / 3 Moderate remain in full npm audit; production dependency audit is clean. Review compatible CLI upgrades separately. |
| Medium | Complete donor response history and search-precision policy | Sanitized response records; avoid restoring sensitive document access. Define distance precision and per-page ordering clearly. |
| Low | Account-deletion cleanup for submission guards/rate limits | Emulator cleanup regression and retention policy. |
| Low | Remaining technical-error text and duplicate legacy widgets | Migrate callers to existing shared feedback/state widgets with recoverable actions. |

No remaining Critical application vulnerability was confirmed by this review. The Critical dependency advisory was patched locally; this does not certify absence of other vulnerabilities.

## Exact manual acceptance steps

1. Use demo/staging only. Prepare approved donor, receiver, dual-role and admin accounts, a pending normal request, direct invitation, active assignment, expired request, rejected emergency review, empty-result location and bilingual scheduled campaign.
2. On a small Android phone and tablet: repeat light/dark, English/Urdu and OS font scales 100/150/200%. Login, register, reset password, open donor/receiver homes, profile/settings, requests, maps, notifications, SOS and admin review. Look for clipping, incorrect RTL, invisible field hints, keyboard obstruction and unreachable controls. Use TalkBack to identify controls and focus order.
3. Donor: toggle availability, reopen Settings/relaunch, confirm persistence. Active donation and invitations must precede nearby requests; banners come after request previews. Dismiss and relaunch; same revision stays hidden. Switch dual account to receiver; no donor campaign appears.
4. Request hub: visit all four tabs; open details and cancel confirmation, then accept. Return and verify refreshed state and capacity. Try repeated accept, another active assignment, expired/cancelled/full requests, then agree/ready/receiver-confirm and duplicate confirm. Verify only one donation/reward and correct 90-day next date.
5. Receiver: submit a request, simulate lost response and retry same screen; one ID remains. Submit equivalent requests concurrently with different IDs; only one succeeds. SOS: start/cancel countdown, then submit/retry; same submission ID returns same linked request. Opening a new SOS screen is a new intent; assess whether product policy should forbid simultaneous distinct SOS intents.
6. Maps: deny/grant permission, select hospital versus manual meeting point, verify selected pin/details and required validation. Test no matches, offline/retry, radius change, multiple pages and long hospital names. Keep OSM attribution visible.
7. Admin at 390px and 1280px: navigate every section, review emergency with keyboard open and long note, cancel/confirm mutations, exercise filters/search and next-page behavior. Campaign: create inactive EN/UR draft, upload supported image, set start/end, preview, activate, observe expiry and revision-specific analytics. Verify non-admin upload/write rejection.
8. Native staging: grant/deny notification permission, sign out/in across users, rotate token, open foreground/background invitation links, test OTP and voice/chat. Confirm no previous user's notification data appears. These are not covered by a browser build.

## Changed files in this senior-review pass

- Design system: `lib/constants/app_surfaces.dart` (new neutral tokens), `app_theme.dart` (controls/navigation), `lib/widgets/dashboard_components.dart` (panel scale, width, RTL badge), `custom_button.dart` (growing accessible buttons), `premium_states.dart` (honest offline state).
- Journeys: auth `login_screen.dart` (presentation rebuilt, auth preserved), `signup_screen.dart` (contrast/width/height); donor and receiver dashboard files (bounded layout); `sos_emergency_screen.dart` (stable submission); admin `admin_web_dashboard.dart` (theme boundary), `admin_web_review_screens.dart` (scrollable dialogs/errors); maps `blood_requests_map_screen.dart` and notification `notification_history_screen.dart` (sanitized errors).
- Correctness: `lib/services/notification_service.dart` (configured callable instance), `lib/utils/eligibility_checker.dart` (sub-hour boundary), `functions/requestWorkflows.js` (normalized urgency, transactional duplicate guard, SOS idempotency), `functions/package-lock.json` (two patched transitive packages).
- Regressions: `test/dashboard_ui_test.dart`, `test/widget_test.dart`, `functions/test/emulator.test.js`; `functions/test/http-workflow.test.js` supplies the required SOS contact fixture; `functions/test/dashboard-walkthrough.js` validates typed email before login.
- Admin editor: `lib/screens/admin/web/admin_awareness_banners.dart` preserves console theme across navigation and bounds desktop reading width.
- Documentation: this file plus `ui_ux_audit.md` and `production_readiness_audit.md`.

Pre-existing changes preserved: awareness workflow/model/widget, nearby-donor cursor validation, request-list refresh/filter, browser walkthrough and dated verification report. Some dashboard/test files contain both passes; do not discard the earlier work when reviewing this diff.

## Privacy/deployment continuation: files changed and next gates

| File | Change in this continuation |
| --- | --- |
| `firestore.rules` | Canonical request/event owner/admin reads; deny participant raw access. |
| `firestore.indexes.json` | Participant/legacy active-query composite indexes. |
| `functions/firebaseAdmin.js` | Export modular Filter for authenticated OR queries. |
| `functions/requestWorkflows.js` | Explicit private/public boundary, own-assignment detail, timestamp serialization and auth-scoped paged participantRequests. |
| `functions/index.js` | Export participantRequests callable. |
| `functions/scripts/deployment-preflight.js` (new) | Read-only local contract and optional live billing/API/Function/secret-metadata inventory; never fetch secret values. |
| `functions/test/emulator.test.js` | Rules access, unauthorized writes, redaction, legacy preservation and pagination regressions. |
| `functions/test/http-workflow.test.js` | Authenticated participant list/detail HTTP contract assertions. |
| `lib/screens/donor/donor_dashboard_screen.dart` | Safe active-request callable polling and continuation through filtered empty pages. |
| `lib/screens/donor/my_responses_screen.dart` | Legacy route delegates to sanitized paged request list. |
| `lib/screens/requests/request_list_screen.dart` | Active/responses callable modes, cursor navigation, correct bilingual empty-state copy. |
| `lib/screens/requests/request_tracking_screen.dart` | Donor-safe refresh polling; preserve private owner/admin stream. |
| `lib/screens/communication/chat_screen.dart` | Read request status through authorized projection instead of denied private root. |
| `lib/controllers/donor_controller.dart` | Shared configured Functions instance for acceptance/completion. |
| `lib/controllers/admin_controller.dart` | Shared configured instance for account deletion. |
| `lib/screens/admin/web/admin_web_users.dart` | Shared configured instance for admin account action. |
| `lib/services/settings_service.dart` | Shared configured instance for account deletion. |
| `lib/services/voice_call_service.dart` | Shared configured instance for voice calls. |
| `docs/production_readiness_audit.md`, `docs/remaining_work.md`, `docs/ui_ux_audit.md` | Current evidence, status boundaries and remaining work. |
| `docs/firebase-staging-deployment.md` (new) | Exact safe commands, feature prerequisites, private-record cutover and approval-required staging procedure. |

- [x] Private canonical rules and donor projections implemented; existing data preserved in fixture tests.
- [x] 55 security/workflow emulator tests, 13 policy tests, 52 Flutter tests, analysis and 1 authenticated HTTP lifecycle passed.
- [x] Empty deployed inventories, disabled billing and required API states verified read-only; secret availability remains unknown (403).
- [ ] Explicitly approve a staging project, billing/API setup and deployment; complete the [staging runbook](firebase-staging-deployment.md). No production deployment or data migration has occurred.
- [ ] Confirm historical staging fixtures/index readiness and updated-client compatibility before production rules approval. Preserve fail-closed behavior for old clients.
- [ ] Resolve Medium UI/App Check/admin pagination/dev dependency/history work listed above. These are reviewed outstanding items, not completed work.
- [ ] Device testing remains deferred by user instruction. Do not execute the earlier physical acceptance sequence yet.

## Final verification closeout — 23 October 2026

Verification and documentation are complete for this pass. Only `docs/production_readiness_audit.md` and this document were edited; all prior implementation changes remain. No production writes, deployment, billing/enforcement changes, commit or push occurred. Earlier pending HTTP/build observations are superseded by fresh successful completed runs:

| Check | Result / exit | Evidence |
| --- | --- | --- |
| Node 22 policy tests | 13 passed / 0 | Final tool output |
| Local Functions preflight | 54 exports, no missing checked names / 0 | Final tool output |
| Auth/Firestore/Storage suite | 55 passed, 0 failed / 0 | `final-privacy-emulators.log` |
| Real authenticated callable HTTP lifecycle | 1 passed, 0 failed / 0 | `final-privacy-http.log` |
| Flutter analysis | No issues / 0 | `final-privacy-analysis.log` |
| Complete Flutter suite | 52 passed, 0 failed / 0 | `final-privacy-flutter.log` |
| Emulator-configured profile web build | Passed / 0 | `final-privacy-web.log` |
| Current full-browser/device/provider/production verification | Not run | Still required; do not infer from compilation or earlier UI screenshots |

Exact commands, authorization matrix and source-verified unresolved findings are in the final section of `production_readiness_audit.md`. The former My Responses status-display suspicion was disproved; responseStatus is already used by the card. None of the final executed checks failed, but tests are not exhaustive and do not erase the open findings.

Next action is a narrowly scoped fix/regression pass for CHAT-01 and WF-05 plus legacy fixture verification, **before** staging sign-off. No automatic continuation, deployment or physical-device work is authorized by this closeout. After those checks, use the approval-gated staging runbook: Functions/indexes → await indexes → updated staging client → restrictive rules → role/legacy/revocation acceptance → separate production approval. Old apps using participant document reads fail closed and require update; already cached private data cannot be retroactively undisclosed.

Reproducible local commands (PowerShell, repository root, installed Node 22; emulator commands write demo fixtures/logs only):

```powershell
$node22 = 'C:\Users\premier\AppData\Local\npm-cache\_npx\52027bd8fc0022aa\node_modules\node\bin\node.exe'
& $node22 --version
& $node22 functions/scripts/deployment-preflight.js
& $node22 --test functions/test/policy.test.js functions/test/hospital-policy.test.js functions/test/banner-policy.test.js
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$(Split-Path $node22);$env:JAVA_HOME\bin;$env:Path"
$env:XDG_CONFIG_HOME = "$PWD\.firebase-config"
& $node22 functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore,auth,storage --project demo-bloodbank 'npm.cmd --prefix functions run test:emulator'
if ($LASTEXITCODE -ne 0) { throw 'Security tests failed; stop here.' }
& $node22 functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore,auth,storage,functions --project demo-blood-bank 'npm.cmd --prefix functions run test:http'
if ($LASTEXITCODE -ne 0) { throw 'HTTP workflow failed; stop here.' }
flutter analyze
flutter test
flutter build web --profile --no-pub --dart-define=USE_FIREBASE_EMULATORS=true --no-wasm-dry-run
```

This build targets emulators and must not be published as production. Deployment/billing/live-rule commands remain separately approval-required in `firebase-staging-deployment.md`.

### Complete existing working-tree inventory

40 tracked modified files (includes earlier work, not 40 new edits in this verification):

```text
firestore.indexes.json
firestore.rules
functions/awarenessWorkflows.js
functions/firebaseAdmin.js
functions/index.js
functions/nearbyDonors.js
functions/package-lock.json
functions/requestWorkflows.js
functions/test/dashboard-walkthrough.js
functions/test/emulator.test.js
functions/test/http-workflow.test.js
lib/constants/app_theme.dart
lib/controllers/admin_controller.dart
lib/controllers/donor_controller.dart
lib/models/awareness_banner.dart
lib/screens/admin/web/admin_awareness_banners.dart
lib/screens/admin/web/admin_web_dashboard.dart
lib/screens/admin/web/admin_web_review_screens.dart
lib/screens/admin/web/admin_web_users.dart
lib/screens/auth/login_screen.dart
lib/screens/auth/signup_screen.dart
lib/screens/communication/chat_screen.dart
lib/screens/donor/donor_dashboard_screen.dart
lib/screens/donor/my_responses_screen.dart
lib/screens/maps/blood_requests_map_screen.dart
lib/screens/notification/notification_history_screen.dart
lib/screens/receiver/receiver_dashboard_screen.dart
lib/screens/receiver/sos_emergency_screen.dart
lib/screens/requests/request_list_screen.dart
lib/screens/requests/request_tracking_screen.dart
lib/services/notification_service.dart
lib/services/settings_service.dart
lib/services/voice_call_service.dart
lib/utils/eligibility_checker.dart
lib/widgets/custom_button.dart
lib/widgets/dashboard_components.dart
lib/widgets/donor_awareness.dart
lib/widgets/premium_states.dart
test/dashboard_ui_test.dart
test/widget_test.dart
```

Seven untracked files, also preserved:

```text
docs/firebase-staging-deployment.md
docs/production_readiness_audit.md
docs/remaining_work.md
docs/ui_ux_audit.md
docs/verification-2026-10-23.md
functions/scripts/deployment-preflight.js
lib/constants/app_surfaces.dart
```

## Latest Firebase-only completion � 23 October 2026

Current implementation/evidence supersedes the older 55-test/read-only snapshot above. Detailed 21-file change list and finding evidence are in the final section of `production_readiness_audit.md`; rollout commands/IAM are in `firebase-staging-deployment.md`.

- **Implemented and automated-tested locally:** canonical participant privacy preserved; chat write/phone-share revocation, legacy assignment/deadline compatibility, linked emergency rejection/release, rejected-request guards, admin status/review counts, explicit us-central1 and missing index declarations.
- **Implemented/source-checked:** SMS error sanitization, deployment exclusions for local secrets/test artifacts, blocked preflight exit semantics. Real SMS/provider error behavior remains unverified.
- **Fresh passing results:** backend syntax exit 0; 13 policy tests exit 0; final **60 Auth/Firestore/Storage emulator tests** exit 0; one authenticated multi-step HTTP workflow exit 0; Flutter analysis clean exit 0; **52 Flutter tests** exit 0; local preflight 54 exports/no missing checked names exit 0.
- **Honest failure history:** first emulator run 58 passed/1 failed, exposing absent blockedUserIds denying valid chat. Fixed; retry 59 passed; expanded final suite 60 passed. Original failing log retained.
- **Blocked, expected exit 2:** fresh live metadata preflight. Billing disabled; no Functions; Run/Build/Artifact Registry/Eventarc/Scheduler/Secret Manager/Firebase Storage disabled; secret metadata 403. Cloud Functions API now verified ENABLED, superseding earlier unknown status.
- **Not performed:** production/staging deployment, data migration, live security/billing/API changes, provider media/delivery, physical device checks, new web build, commit/push. The earlier successful web build is historical, not rerun evidence.

Priority checklist:

1. **High approval/account gate:** choose an isolated staging project; owner approves Blaze/billing and supplies authorized IAM/provider setup. No Functions are deployed yet. Metadata alone cannot prove historical reason or effective permissions.
2. **High rollout gate:** deploy compatible Functions/indexes/client/restrictive rules in the runbook order, verify real indexes and accepted donor/stranger/owner/admin/suspended behavior. Old direct-read clients need update; never weaken canonical privacy for old versions.
3. **Medium staging validation:** representative sanitized historical records, missing linked SOS handling, commitment-only records without queryable participant IDs, real FCM/OTP/Agora/Twilio, trigger retries and in-flight messages. Stored production records have not been sampled or changed.
4. **Medium unresolved functionality:** pre-accept voice path requires assignment before answer/token; admin response-rate numerator and dispute aggregation remain incomplete. Do not present these as production-verified features. App Check rollout needs provider metrics and separate enforcement approval.
5. Preserve earlier unrelated UI, pagination, localization and development dependency follow-ups. No additional UI work was started in this pass.

Safe next commands from repository root, with Node 22 installed:

```powershell
$node22 = 'C:\Users\premier\AppData\Local\npm-cache\_npx\52027bd8fc0022aa\node_modules\node\bin\node.exe'
$env:Path = "$(Split-Path $node22);$env:Path"
& $node22 --version
npm.cmd --prefix functions run check
if ($LASTEXITCODE -ne 0) { throw 'Syntax check failed.' }
npm.cmd --prefix functions test
if ($LASTEXITCODE -ne 0) { throw 'Policy tests failed.' }
& $node22 functions/scripts/deployment-preflight.js
if ($LASTEXITCODE -ne 0) { throw 'Local contract inventory failed.' }
# Read-only; current expected exit is 2 because prerequisites remain blocked:
& $node22 functions/scripts/deployment-preflight.js --project blood-bank-98037 --live
```

To reproduce emulator/HTTP checks, use the earlier local commands with demo-bloodbank for the rules suite and demo-blood-bank for HTTP. All `deploy`, API enablement, billing and secret-write commands in the staging runbook require explicit approval first. Do not deploy from this blocked preflight result.

## Manual deployment package follow-up

Complete rule/index/config files and fingerprints are in firebase-manual-deployment.md. Rules were unchanged; indexes now contain 35 entries. Admin donation-dispute aggregation is locally fixed using the actual targetDonationId field, with a matching index and cache version update; no migration needed. Response-rate/timing analytics and pre-accept voice behavior remain unresolved. Fresh rules tests: 60 passed, exit 0; policy tests: 13 passed, exit 0; syntax/source preflight: exit 0. Fresh authenticated HTTP lifecycle plus admin dispute-count regression: 1 test passed, 0 failed, exit 0 (manual-firebase-http.log).

Publish only after compatible Functions and updated client are ready. Prefer indexes first and wait for readiness, then Functions/client, then rules. Existing staging runbook and approval requirements remain applicable. No live actions were performed.
