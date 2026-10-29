# Production readiness audit — 23 October 2026

## Status and method

Latest status: the Firebase readiness continuation at the end supersedes earlier findings and test counts. This continuation implements backend/rules fixes; earlier read-only verification sections are historical. Work remains local and uncommitted.

Implemented and locally tested changes are not deployed or production verified. No production writes, billing/enforcement changes, release, commit or push. Initial working tree contained the preceding continuation's changes; those remain intact. Review used actual source, current tests, npm audit and local demo Firebase emulators.

[OWASP MASVS](https://mas.owasp.org/MASVS/) and [MASTG](https://mas.owasp.org/MASTG/) were used as storage/auth/network/platform/code/privacy review checklists, not as a compliance claim. Source review cannot establish runtime attestation, production rules, transport behavior or device storage protection.

## Findings

| ID / severity | File and function | Evidence / why it matters | Recommended fix and status |
| --- | --- | --- | --- |
| SEC-01 Critical advisory, fixed locally | `functions/package-lock.json`, `node_modules/proxy-addr` | Fresh production npm audit flagged installed 2.0.7 Critical. Dependency advisory is not proof this app is exploitable. | Compatible update to 2.0.8. Final production audit: zero advisories. Backend tests rerun. Not deployed. |
| SEC-02 High advisory, fixed locally | same lockfile, `node_modules/follow-redirects` | Fresh production npm audit flagged 1.16.0 High. | Updated to 1.16.1; zero production advisories after update. No forced/major dependency upgrade. |
| WF-01 High, fixed locally | `functions/requestWorkflows.js:104`, `createBloodRequest` | `requestData` normalized urgency but emergency review tested raw input; ` Critical ` could be stored as critical without pending review. | Review normalized `data.urgency`. Emulator regression verifies stored critical and pending_review. |
| WF-02 High, fixed locally | `functions/requestWorkflows.js`, `createBloodRequest` transaction | Duplicate query executed outside transaction, allowing two distinct IDs concurrently. | Per-receiver server-only guard document plus duplicate query inside transaction. Parallel requests test permits exactly one and verifies idempotent same-ID retry. Guard reads denied by catch-all rules. |
| WF-03 High, fixed for current-screen retries | `functions/requestWorkflows.js`, `createSosAlert`; `sos_emergency_screen.dart`, `_submissionId`, `_send` | Each retry previously created two fresh documents even after a successful response was lost. | Stable client submission ID; transactional existing-owner check returns same linked request. Concurrent retry and wrong-owner tests pass. Old clients without an ID retain prior behavior; a newly opened screen creates a new intent. |
| INT-01 Medium, fixed locally | `lib/services/notification_service.dart`, `sendToUsers` | Direct `FirebaseFunctions.instance` ignored configured region/emulator instance. | Uses `WorkflowService.call`. Source contract and analysis checked; native push not device-tested. |
| PRIV-01 High, fixed locally; rollout pending | `firestore.rules`, blood_requests and events; `requestWorkflows.js`, getRequest/participantRequests | Accepted participants could directly read every private canonical field. Callable redaction did not protect direct Firestore access. | Canonical records now owner/admin-only; donor readers use authenticated allowlisted projections. Legacy/unknown fields remain preserved and private. Unauthorized read/write, owner/admin, legacy and pagination regressions pass. No physical data migration needed. See privacy cutover below. |
| INT-02 High deployment blocker, verified | `.firebaserc`, Functions inventory and Cloud Billing read-only APIs | Project blood-bank-98037: v1/v2 Functions empty; billingEnabled false; build/run/artifact/eventarc/scheduler/secretmanager services disabled. | Blaze/API/IAM/staging configuration and explicit deployment approval required. Historical reason for no deployment unknown. Secret metadata 403 is unresolved, not evidence of missing secrets. |
| SEC-03 Medium, remaining | `lib/services/firebase_runtime.dart`, `configureFirebaseRuntime`; `functions/index.js`, onCall registrations | App Check activation opt-in via ENABLE_APP_CHECK; callable wrappers do not request enforceAppCheck. Live console enforcement not inspected. | Register apps/providers, observe staging attestation, then separately approve enforcement rollout. Do not enable blindly or claim production protection. |
| PERF-01 Medium, remaining | `lib/screens/admin/web/admin_web_requests.dart`, `AdminEmergencyRequests.build` | SOS ordered snapshot has no limit/cursor; can grow with collection size. Other newer tables have bounded pages. | Add paged query with filters and visible continuation; do not silently cap records. |
| PERF-02 Medium, remaining | `functions/nearbyDonors.js`, `nearbyDonorsPaged`; `requestWorkflows.js`, `findDonors` | Bounded scan and continuation avoid gaps in stable-data regression, but distance sorting is per page; exact numeric distance accompanies rounded coordinates. | Document approximate map precision; consider distance bucketing and indexed search at scale. No claim of globally nearest ordering or strong location anonymity. |
| SEC-04 Medium, remaining | `functions/package-lock.json`, development tool dependency tree | Full npm audit after production patches: 15 advisories (12 High, 3 Moderate), while omit-dev audit is zero. | Review Firebase CLI/toolchain upgrades separately in CI; do not force upgrades during emergency-flow fixes. |
| OPS-01 Medium, local runtime parity resolved; staging pending | `functions/package.json`, Node 22 | Policy and final emulator suite rerun using Node 22.23.4; Functions emulator reports node@22 from host. | Keep Node 22 in CI/deployment. Production runtime remains unverified. |
| OPS-02 Medium, remaining | `android/app/build.gradle.kts`, top-level signing check | Release-key presence is checked during configuration, so even debug builds can require private release signing configuration. | Scope signing validation to release tasks; verify Gradle debug/release paths in Android environment. No Android build attempted. |
| WF-04 Medium, remaining | `request_list_screen.dart`, responses query; `requestWorkflows.js`, `updateAssignment` | My Responses uses the private participantRequests callable over current/legacy participation identifiers; withdrawal removes participation. It is not complete response history. | Add sanitized donor response-history records/callable without reopening private request access. |
| PRIV-02 Low, remaining | `storage.rules`, awareness/profile media; banner image URL usage | Active users may read awareness images; download URLs may be shared. Donor-only presentation is not confidential asset access. | Treat campaign images as public informational content; never upload sensitive patient data. |
| MAINT-01 Low, remaining | `requestWorkflows.js`, `request_submission_guards`; `secureWorkflows.js`, `deleteAccount` | New guard stores only updatedAt under UID; deletion cleanup does not yet remove guard, and several older prefixed rate-limit records also survive. | Extend retention/account cleanup; guard contents contain no medical/contact data. |

## Controls reviewed without claiming full coverage

- Protected role/status fields, owner-only profiles/private contact, active-account guards and admin callables are enforced in source. Registration intentionally starts approved donor/receiver profiles; separate verification review is not the same as account approval. If manual approval is desired, that is a product-policy change.
- Acceptance/capacity/assignment/completion use transactions; emulator suite checks one active assignment, compatibility, duplicate confirmation, withdrawal and authorization. Server exact 90-day policy remains; client final-hour rounding is corrected.
- Request/discovery payloads and invite access are bounded/validated. Canonical invitation and 205-donor pagination regressions are retained. Do not infer stable pagination under concurrent edits or globally nearest ordering.
- Storage banner writes require active admin and bounded MIME/size; scheduled donor feed/event checks and revision deduplication pass. Media MIME is metadata, not content scanning.
- Notification service requests native permission, saves owner-scoped device tokens, handles rotation and sign-out. Web push is intentionally skipped. Native delivery, consent, deep links and background behavior are unverified here.
- OpenStreetMap/flutter_map retained. Location permissions, offline tiles and real-device positioning remain manual.
- TODO/FIXME/placeholder scan did not establish feature completeness. Found and removed a real no-op offline Retry action. Legacy raw profile/admin errors, English-only labels, decorative screens and release configuration remain listed in UI/backlog docs.

## Actual validation

The table immediately below records the preceding UI pass. The privacy/deployment continuation results at the end of this document supersede its emulator count and runtime/deployment observations.

| Check | Result |
| --- | --- |
| Complete Flutter suite | 52 passed, 0 failed |
| English/Urdu light/dark request/banner cards | Passed at 320px / 200% text |
| Shared custom-button long-label regression | Passed at 200% text, all variants |
| Backend policy suite | 13 passed |
| Configured backend syntax checks | Passed |
| Final Flutter analysis | No issues |
| Actual callable HTTP lifecycle with emulator Auth JWTs | 1 passed on rerun; initial SOS fixture omitted required contactNumber and failed 400 vs expected 200 |
| Final Auth/Firestore/Storage emulator suite | 51 passed, 0 failed |
| Profile web build, demo emulator define | Passed; not a production release |
| Production npm audit | 0 advisories after two compatible patches |
| Full npm audit | 15 remaining development-tree advisories; audit exits nonzero |
| Android/iOS device, TalkBack, OTP, native FCM/Agora, production smoke | Not run |

Intermediate analyzer errors from edits were corrected before final verification. Historical counts of 49/43 or earlier 50-test runs are not the final result. Local logs use ignored `senior-*.log`; npm audit artifacts are in ignored `audit-artifacts/senior-review/`. They are not production telemetry.

Local Chrome donor verification passed: actual login, seeded dashboard, awareness dismissal and all four request tabs. Receiver login/dashboard also passed without page errors on rerun. Admin desktop/editor loaded without page errors, including the final rebuilt theme/width recheck. Final Flutter suite rerun after that editor correction: 52 passed; final analysis: no issues; final web rebuild: passed. An earlier parallel browser attempt timed out; independent donor rerun passed. One receiver attempt failed login; the harness now verifies typed email before proceeding and the rerun passed. The HTTP fixture correction supplied the existing required contact field; backend validation was not relaxed.

## Deployment prerequisites

Explicit approval still required. Read-only checks confirmed billing disabled and required APIs disabled; approve a staging project and billing plan first; deploy reviewed indexes/rules/Functions in staging first, await index readiness and verify region. Configure retained Agora and Twilio parameters/secrets, Auth providers, Storage bucket, App Check providers and release signing. No credentials are printed or embedded by these changes. Current emulator build must not be distributed as production.

## Privacy/deployment continuation — current evidence

See [staging runbook](firebase-staging-deployment.md) for exact source contracts, exposed field inventory, compatibility strategy, live read-only metadata, costs and approval-required commands.

- **PRIV-01 implemented locally:** canonical request and event reads now require active owner/admin; canonical writes remain server-only. `getRequest` uses an explicit donor allowlist and only the caller's assignment. Switching donor capability off cannot elevate access. New `participantRequests` authenticates identity from the token, queries current and legacy identifiers, validates cursor/mode and returns bounded sanitized pages. It never trusts a supplied donor UID.
- **Client compatibility implemented:** donor dashboard, legacy My Responses route, request hub and chat use callables instead of direct participant reads. Tracking polls donor-safe detail every 30 seconds; owner/admin listeners remain. Dashboard follows empty filtered pages so an expired legacy page cannot conceal a later active request. HTTP timestamps are serialized for Flutter decoding.
- **Migration tested without data loss:** accepted multi-donor and legacy single-donor fixtures retain all original fields, including unknown private fields; before/after canonical document deep equality passes. No field deletion/backfill is needed because the whole canonical document is private. Old clients must update before cutover; cached data cannot be retroactively removed. Production records were not migrated or inspected for exhaustive schema coverage.
- **INT-03 Medium fixed locally:** donor/admin controllers, admin user action, settings deletion and voice service used default `FirebaseFunctions.instance`. They now share `WorkflowService.functions`, keeping region and emulator routing consistent. All instances in Flutter source were reviewed; default region remains us-central1.
- **Node/runtime:** Node 22.23.4 policy runner and emulator CLI used; Functions emulator confirmed node@22 from host. Source inventory: 54 exports, zero missing scanned/reviewed callable names. Not every provider-specific response has a live HTTP test.

| Current check | Actual result |
| --- | --- |
| Flutter analysis after final client edits | No issues |
| Complete Flutter suite after final client edits | 52 passed, 0 failed |
| Backend policy suite, Node 22 | 13 passed, 0 failed |
| Backend syntax script and export/name preflight | Passed; 54 exports, zero missing referenced names |
| Auth/Firestore/Storage emulator suite | 55 passed, 0 failed; includes four new privacy/legacy/pagination regressions |
| Real Auth JWT callable HTTP lifecycle | 1 passed, 0 failed; includes participantRequests and redacted getRequest |
| Final emulator-configured profile web build | Passed, exit 0 (67.6s compile); not a production build |
| Browser walkthrough after privacy changes | Not completed in this continuation; earlier UI-pass walkthrough is historical, not validation of this new cutover |
| npm production audit | 0 advisories |
| npm complete audit | 15 advisories: 12 High, 3 Moderate in development tree; nonzero audit exit remains |
| Production deployment/security validation | Not run; no deployment authorized |
| Physical Android/native verification | Not run, explicitly deferred |

An intermediate Node 22 emulator invocation ran from the wrong working directory and failed; corrected `npm --prefix functions run test:emulator` completed 55/55. An intermediate analysis found four newly unused imports after shared-instance replacement; removed and final analysis clean. These failed intermediate checks are not counted as passing tests. Local ignored `privacy-*.log` files contain the execution results, not production evidence.

Two asynchronous final-build attempts lost their process handles without a completion result; a monitored rerun completed successfully. Final browser rerun was not completed after those session interruptions. Staging browser acceptance remains required; no real-device check was attempted.

### Remaining priorities reviewed, not silently marked complete

High: approved staging and eventual production rollout of the privacy fix; backend absent with billing/APIs blocked. Medium: App Check opt-in without callable enforcement (`firebase_runtime.dart`, `index.js`), legacy admin SOS unbounded snapshot (`admin_web_requests.dart`, AdminEmergencyRequests), English-only/RTL gaps and legacy profile/role/splash styling (UI audit), incomplete withdrawn-response history, Node 22 CI/native lifecycle, development advisories. Low: account-deletion guard cleanup and legacy feedback components. No new Critical vulnerability was confirmed. Passing local tests is not production security certification.

## Final verification — 23 October 2026

The complete tracked diff (40 files), seven untracked files and the four current audit/runbook documents were inspected. Earlier UI, pagination and dependency changes remain intact. No new code, rule or migration edit was made. The inventory is in `remaining_work.md`. The large login-screen presentation diff and legacy My Responses replacement are existing intentional changes; neither changes server authorization. The two lockfile patches are restricted to follow-redirects and proxy-addr. No unexplained deployment/configuration mutation was found in these diffs.

### Authorization conclusions and coverage

| Case | Canonical request read | Direct canonical write | Evidence |
| --- | --- | --- | --- |
| Approved request owner | Allowed | Denied | Rules 96–97; owner read/write emulator assertions |
| Approved admin | Allowed | Denied | Same rules; explicit admin fixture assertions; mutations use admin-authorized callables |
| Approved accepted donor, not owner | Denied | Denied | Direct get/query/write regression; callable returns only own assignment |
| Unrelated donor/receiver, not owner/admin | Denied | Denied | Requester-ID equality in rules; unrelated donor regression; no separate exhaustive unrelated-receiver matrix |
| Withdrawn/released donor | Denied | Denied | Canonical rules and withdrawal test; chat is a separate unresolved issue below |
| Suspended/rejected account, including owner/admin | Denied | Denied | `active()` requires approved; suspended donor regression and active-account policy test. Rejected owner/admin combinations are source-verified, not separately emulator-tested |
| Unauthenticated | Denied | Denied | `active()`/`admin()` require auth; unauthenticated canonical-read and HTTP mutation assertions |

Protected profile keys cannot be used to promote a donor/receiver to admin or rewrite approval, reward or donation history fields. Request-private contact/events are owner/admin-scoped. Owner/admin writes to the request `private/contact` subdocument are intentionally allowed; these are not canonical request writes. Catch-all rules do not grant alternate access. Admin SDK authorization must still be enforced by each callable because Admin SDK bypasses rules.

`getRequest`, `participantRequests`, discovery and invitations were checked together with assignment mutations, tracking, chat, notification routing, owner exports and retained legacy repositories. Public summaries omit patient/contact fields; accepted donor detail returns only that donor's allowlisted commitment, not peer assignments. Numeric timestamps are decoded by the client; pagination consumes `{items,cursor}` and discovery `{donors,cursor,...}` as appropriate. All client Functions instances use the shared region configuration, default us-central1. `getDonorContact` always denies automatic disclosure. `sharePhoneNumber` deliberately shares the caller's own phone after explicit confirmation; it is not an API for fetching another user's private contact. Canonical privacy protection does not revoke messages/contact details previously shared by consent or downloaded to caches.

The real HTTP test verifies authenticated acceptance, participant listing, redacted detail/timestamp shape, agreement/readiness, owner confirmation, duplicate confirmation, unauthenticated confirmation rejection, non-admin deletion rejection and SOS creation. It is one lifecycle test, not end-to-end coverage of every role, chat state, native notification or provider integration. Discovery/invitation pagination and owner/admin reads have separate emulator coverage. No current full-browser/device/production sign-off is claimed.

### Verified-source issues and unverified boundaries still open

| ID / severity / status | Exact source and evidence | Required next verification/fix |
| --- | --- | --- |
| CHAT-01 Medium, unresolved; source-verified | `functions/chatWorkflows.js:6` checks conversation membership and open request, but not current assignment or blocked sender. `firestore.rules:120` checks conversation membership/block and request status, not current assignment/deadline. `requestWorkflows.js`, updateAssignment, removes request participation without removing conversation membership. A withdrawn donor can still satisfy message-write conditions while the request stays open; phone-share callable also lacks a block check. `chatNotifications.js` has stricter current-assignment checks, so suppressing push does not prevent message persistence. | Add current-assignment/deadline/block enforcement for new messages and phone sharing while preserving permitted history access; add withdrawal/release/blocked/expired regressions. Existing tests do not exercise this full revocation path. This predates the privacy diff and was not changed here. |
| WF-05 High, unresolved; source-verified, not reproduced end-to-end | `functions/emergencyReviewWorkflows.js:reviewEmergencyRequest` writes `reviewStatus: rejected` without closing the request. `requestWorkflows.js:acceptDonation` checks open status/eligibility but not reviewStatus; discovery and notifyRequest also do not exclude rejected review. The pending-review limited-disclosure policy does not establish that rejected requests should remain actionable. | Define and enforce rejected-review behavior server-side; test a rejected emergency through discovery, acceptance and notifications before release. This existing gap is not a canonical-private-field leak and was not patched in this verification pass. |
| COMPAT-01 Medium, unresolved production coverage | `requestWorkflows.js:24`, assignments/participants, and participantRequests: legacy single acceptedDonorId without commitments is covered. Records containing only acceptedDonorIds, or acceptedDonorId plus an empty commitments object, do not necessarily resolve an active assignment. Commitment-only records without a queryable participation identifier cannot be found by the OR query. | Inspect authorized sanitized historical fixtures in staging and test any additional schemas before cutover. Stored data stays intact, but full workflow compatibility for these variants is not proven. Do not silently rewrite production records. |
| LOG-01 Medium, unresolved exposure risk | `functions/smsFallback.js:57` logs provider `err.message` and returns it to its internal trigger caller. Provider error text can contain contact metadata. No sensitive provider failure was reproduced or secret value inspected. | Log bounded error codes instead of provider messages; test sanitization before enabling SMS. Do not describe all logging as sanitized. |
| VERIFY-01 Medium, unverified | Production rules/index state, real provider secrets/IAM, native delivery and full-role browser cutover have not been tested. `donationHistory` returns stored donation fields with a small denylist; unknown historical donation schemas were not inspected. | Approved staging fixtures, explicit authorization matrix and provider checks; do not extrapolate canonical-request tests to every legacy collection. |

My Responses **does** display responseStatus (`dashboard_components.dart:123`); an interim suspicion was disproved by reading the shared widget and is not a defect. Missing withdrawn history remains the separately documented WF-04. The four current documents distinguish local implementation, automation, earlier browser evidence, deferred devices and absent production verification; the older dated verification document is historical.

### Fresh completed checks and exact evidence

| Check / exact command (repository root) | Exit | Actual result | Evidence |
| --- | --- | --- | --- |
| Node 22 `node --test functions/test/policy.test.js functions/test/hospital-policy.test.js functions/test/banner-policy.test.js` | 0 | 13 passed, 0 failed | Final verification tool output; no file written for this read-only command |
| Node 22 `node functions/scripts/deployment-preflight.js` | 0 | 54 exports; no missing scanned/reviewed Flutter callable names | Final verification tool output; local-only inventory |
| `node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore,auth,storage --project demo-bloodbank "npm.cmd --prefix functions run test:emulator"` | 0 | 55 passed, 0 failed, 0 skipped | `final-privacy-emulators.log`, summary at line 2275 and explicit script exit 0 |
| `node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore,auth,storage,functions --project demo-blood-bank "npm.cmd --prefix functions run test:http"` | 0 | 1 passed, 0 failed, 0 skipped | `final-privacy-http.log`, summary at line 682 and explicit script exit 0 |
| `flutter analyze` | 0 | No issues | `final-privacy-analysis.log` |
| `flutter test` | 0 | 52 passed, 0 failed | `final-privacy-flutter.log` |
| `flutter build web --profile --no-pub --dart-define=USE_FIREBASE_EMULATORS=true --no-wasm-dry-run` | 0 | Built build/web; 12.8s compile | `final-privacy-web.log` |

Flutter commands were executed using `C:/src/flutter/bin/cache/dart-sdk/bin/dart.exe C:/src/flutter/bin/cache/flutter_tools.snapshot` followed by the listed arguments. Node commands used the existing Node 22.23.4 executable at `C:/Users/premier/AppData/Local/npm-cache/_npx/52027bd8fc0022aa/node_modules/node/bin/node.exe`; its directory and Android Studio JBR bin were prepended to PATH. JAVA_HOME pointed to Android Studio JBR, XDG_CONFIG_HOME to the repository `.firebase-config`. No packages were installed for these reruns. Each wrapper captured LASTEXITCODE and stopped on failure. Emulators shut down after successful completion; their shutdown SIGINT is not a failed test.

No final check failed or remained running. Browser/native/provider/production checks remain **not run**, not passed. Dependency advisories were read from existing `audit-artifacts/senior-review/privacy-dependencies-production.json` (0) and `privacy-dependencies-all.json` (15: 12 High/3 Moderate); no fresh network advisory query was performed in this final pass.

### Deployment and cutover gate

Billing/API/secret observations remain the earlier same-day read-only snapshot in `privacy-deployment-preflight.log`: billing disabled; v1/v2 inventories empty; Run/Build/Artifact Registry/Eventarc/Scheduler/Secret Manager disabled; Cloud Functions service lookup 500; secret metadata 403. They were not refreshed live in this final pass. Four exports bind provider secrets; no secret values were read. Preflight reports individual API errors but can still exit 0, so its exit code is not deployment approval or proof of readiness.

Safest order: resolve the authorization gaps above and expand historical fixtures locally; obtain approval for a named staging project/billing/API setup; deploy Functions and indexes to staging; wait for indexes; prepare the updated staging client; apply restrictive staging Firestore/Storage rules; exercise owner/admin/accepted/rejected/suspended/anonymous and revoked-chat paths; obtain separate production approval. Old clients querying canonical participant documents will receive permission-denied after rules cutover. Do not loosen rules to support them. No destructive data backfill is required for the tested schemas, and no production migration/deployment was performed. Production security is **not** declared fixed.

## Firebase readiness continuation � latest verified state (23 October 2026)

This section supersedes the earlier read-only closeout and its unresolved CHAT-01/WF-05/COMPAT-01/LOG-01 descriptions. Earlier logs remain historical. This pass changed only Firebase/backend/config/tests and these audit documents. Existing Flutter/UI changes were preserved. Nothing was deployed, migrated, enabled, committed or pushed.

### Implemented findings and evidence

| Finding | Exact implementation | Current status / limit |
| --- | --- | --- |
| CHAT-01 Medium | `firestore.rules:liveChat`, `chatWorkflows.js:sharePhoneNumber`, `requestPolicy.js:liveConversation`, `chatNotifications.js:notifyChatMessage` | New messages/phone sharing require an active assignment, active peers, unexpired/non-rejected request and unblocked sender. Phone sharing rechecks inside a transaction. Missing blockedUserIds defaults safely instead of denying new conversations. Withdrawal blocks writes while history/mark-read/report remain available. Timestamp and numeric legacy deadlines supported. Emulator regressions passed. Historical shared phone messages remain intentionally readable to conversation members; revocation does not erase previously shared data. |
| WF-05 High | `emergencyReviewWorkflows.js:reviewEmergencyRequest`, `requestWorkflows.js:assertOpen/discoverRequests/getRequest`, `requestNotifications.js:notifyRequest`, `index.js:notifyNearbyDonorsOnSOS`, `voiceWorkflows.js` | Admin rejection synchronizes linked SOS/root, cancels open request, releases commitments and clears donor activeRequestId atomically. Repeat review is safe; unknown canonical fields remain. Guard also rejects old records still marked pending with rejected review. SOS trigger rereads state and checks again transactionally before dispatch. Local regression and authenticated HTTP checks passed. In-flight external push/SMS cannot be recalled; production trigger delivery is unverified. |
| COMPAT-01 Medium, partially closed | `requestPolicy.js:assignments`, request/voice/chat callers | Merge missing singular/array legacy identifiers in memory even when commitments is empty; explicit withdrawn/released entries win. Legacy data unchanged by reads. Tests cover redacted detail/activity and voice answer authorization. Commitment-only records with no queryable participant identifier and corrupt/missing linked records still require separately authorized staging/schema review. No production backfill performed. |
| LOG-01 Medium | `smsFallback.js:sendSmsFallback` | Removed UID/provider error text from success/failure logs and provider-error response. Uses integer code or generic category. Syntax/source verified; actual Twilio error/delivery not exercised. Other unrelated historical logs were not certified globally safe. |
| INT-03 Medium | `adminWorkflows.js:adminAnalytics` | Count real pending/accepted statuses, derive open count, use reviewStatus for pending reviews, and independent total for denominators (avoid double-counting urgency/status categories). Authenticated HTTP regression verifies values. Response-rate numerator remains a legacy placeholder; donation-dispute aggregation/schema and full analytics completeness remain follow-up work. |
| INT-04 Medium | `firestore.indexes.json` | Added equality-before-date indexes for status/urgency/blood-group analytics and combined group filters; requester donation history and voice busy-session indexes. Existing private participant/invitation/discovery indexes preserved. Emulator execution does not prove deployed index readiness; wait for staging index builds and run real queries. |
| INT-05 Medium | `functions/index.js`, `scripts/deployment-preflight.js`, `firebase.json`, `.gitignore` | Explicit us-central1 matches Flutter default and HTTP test URLs. Preflight reports blocked/unknown metadata as exit 2; now checks both Storage APIs. Ignore emulator secret/environment/test files in upload; .secret.local excluded from Git. No project/app identifiers changed. |
| Voice candidate compatibility | `voiceWorkflows.js:createVoiceCallSession/markDonorNotReady/updateVoiceCallSession` | Correct donor-to-recipient compatibility argument direction; normalized legacy assignments for answers/tokens; rejected reviews denied. Actual provider media untested. Existing pre-accept ringing path still cannot answer/token until an assignment exists; clarify that product workflow before provider launch. |

Canonical `blood_requests` documents/events remain private to active owner/admin; all client canonical writes stay denied. Accepted donor callables return allowlisted request fields and own assignment, not other donors' assignments/private contact fields. Owner/admin functionality and generic donor discovery remain in the regression suite. Invitation lookup delegates to safe request projection and now excludes rejected actionable requests. No destructive migration or schema split is required for tested records. Old participant document-reader clients fail closed after restrictive rules; require updated client and communicate cutover. Existing offline caches cannot be retroactively undisclosed.

### Exact completed checks

Node v22.23.4; Flutter invoked through installed SDK's Dart executable and flutter_tools.snapshot (same analyze/test commands). Logs below are local, ignored artifacts at repository root.

| Command | Exit | Result / evidence |
| --- | --- | --- |
| `npm.cmd --prefix functions run check` | 0 | Backend syntax including new policy/preflight/SMS files; `firebase-readiness-syntax.log` |
| `npm.cmd --prefix functions test` | 0 | 13 passed, 0 failed; `firebase-readiness-policy.log` |
| `node functions/scripts/deployment-preflight.js` | 0 | 54 exports; no missing checked literal/dynamic client names; `firebase-readiness-local.log`. Static inventory is not exhaustive payload/provider certification. |
| `firebase emulators:exec --only firestore,auth,storage --project demo-bloodbank 'npm.cmd --prefix functions run test:emulator'` | 1 first run; 0 retries | Initial 58/59 exposed missing blockedUserIds bug (`firebase-readiness-emulators.log`). Fixed; retry 59/59. Final expanded suite **60 passed, 0 failed, 0 skipped**, `firebase-readiness-emulators-final.log`. |
| `firebase emulators:exec --only firestore,auth,storage,functions --project demo-blood-bank 'npm.cmd --prefix functions run test:http'` | 0 | 1 multi-step authenticated HTTP test passed, 0 failed: real Auth JWTs, participant detail/list, donation lifecycle/idempotency, forbidden admin action, SOS/admin analytics/rejection. `firebase-readiness-http.log`. |
| `flutter analyze --no-pub` | 0 | No issues; `firebase-readiness-analysis.log` |
| `flutter test --no-pub` | 0 | **52 passed**, no failures; `firebase-readiness-flutter.log` |
| `node functions/scripts/deployment-preflight.js --project blood-bank-98037 --live` | 2 | Expected blocked readiness: `firebase-readiness-live.log`, metadata GET only. No resource changes. |
| Web build / physical device / real FCM, Agora, Twilio / production acceptance | Not run in this continuation | Prior web build remains historical evidence only; no new UI work or deployment was done. |

The final rules/voice legacy refinements were checked by the final 60-test emulator suite. The HTTP lifecycle does not cover external voice/media or SMS. No current test command is still running.

### Deployment status and unresolved gates

Fresh metadata: billing disabled; zero v1/v2 deployed Functions. Cloud Functions, Pub/Sub, Firestore, Identity Toolkit, FCM and Cloud Storage APIs enabled. Run, Build, Artifact Registry, Eventarc, Scheduler, Secret Manager and Firebase Storage APIs disabled. Both secret-version metadata checks returned 403; secret existence/validity and effective IAM are unknown. No secret payloads accessed.

All 54 exports load locally. The 50 without secret bindings are candidates for **approved staging** after billing/API/IAM/database/index/client setup, not certified production ready. Three Agora callables and the SOS notification trigger additionally require provider secrets/configuration. Missing Functions currently block callable-dependent discovery, acceptance/tracking projections, invitations, SOS, chat actions, notification/admin workflows even if Auth and some owner Firestore reads work. Full readiness requires actual provider, App Check and staging verification; no blanket claim that every feature is complete.

Remaining Medium functional checks: pre-accept voice workflow; complete analytics (response numerator/dispute counts); in-flight notification/review race and provider delivery; legacy records without participant identifiers; index builds/query execution; App Check rollout. Existing UI/native/dependency audit items remain unchanged and are outside this Firebase-only pass. No new Critical issue was confirmed. Billing/deployment are High operational gates, not evidence of a deployed security fix.

Use `firebase-staging-deployment.md` for official references, exact PowerShell API/secret/deployment commands and required IAM. Safe order: approve named staging/billing ? configure APIs/IAM/Auth/Storage/secrets ? local checks ? deploy Functions and indexes ? wait for indexes ? updated staging client ? restrictive rules ? role/legacy/revocation/provider acceptance ? separate production approval. Never restore permissive participant reads as rollback.

### Files changed in this continuation (21, excluding earlier unrelated edits)

- `.gitignore`, `firebase.json`: exclude local secrets/emulator/test artifacts.
- `firestore.rules`: live chat authorization and missing-field/legacy deadline handling; preserve private canonical rules.
- `firestore.indexes.json`: missing analytics, receiver donation-history and call-session indexes.
- `functions/requestPolicy.js` (new): shared actionable request and legacy assignment normalization.
- `functions/requestWorkflows.js`: use policy in acceptance, discovery and participant projections.
- `functions/chatWorkflows.js`: transactional phone authorization and readable historical actions.
- `functions/chatNotifications.js`: same current participant policy for push notification eligibility.
- `functions/emergencyReviewWorkflows.js`: linked transactional rejection, release and bounded review input.
- `functions/requestNotifications.js`: deny already-rejected requests.
- `functions/voiceWorkflows.js`: rejected/legacy assignment and compatibility direction fixes.
- `functions/smsFallback.js`: sanitized provider logging/error response.
- `functions/adminWorkflows.js`: actual status/review counts and distinct denominator.
- `functions/index.js`: explicit region and fresh SOS state checks.
- `functions/package.json`: syntax-check new policy/preflight/SMS files.
- `functions/scripts/deployment-preflight.js`: blocked exit status and Storage API metadata.
- `functions/test/emulator.test.js`, `functions/test/http-workflow.test.js`: regression scenarios.
- `docs/production_readiness_audit.md`, `docs/remaining_work.md`, `docs/firebase-staging-deployment.md`: current evidence, blockers and approval-gated rollout instructions.

## Manual deployment package follow-up (23 October 2026)

Prepared `docs/firebase-manual-deployment.md` with complete, unabridged contents and SHA-256 fingerprints for firestore.rules, firestore.indexes.json, storage.rules, firebase.json and .firebaserc. Firestore/Storage rules were reviewed and preserved unchanged in this follow-up; no security weakening. There are 35 unique composite indexes and no field overrides. Project alias q maps to blood-bank-98037; there is no default/staging alias. Flutter also targets blood-bank-98037 and bucket blood-bank-98037.firebasestorage.app. Always specify --project explicitly.

Safe local backend fix: adminAnalytics previously counted donation disputes using reportType, which neither dispute writer sets. It now counts pending records with a nonempty targetDonationId, supporting existing records without migration. Added status/targetDonationId index and regression fixtures for an open legacy dispute, a resolved dispute and an unrelated chat report. Versioned the analytics cache key so stale cached counts do not survive the code update. Response-rate numerator, timing analytics and pre-accept voice workflow remain separate unresolved issues.

Fresh checks: backend syntax exit 0; 13 policy tests passed exit 0; source preflight 54 exports/no missing checked calls exit 0; 60 Auth/Firestore/Storage tests passed, zero failed/skipped, exit 0. Logs: manual-firebase-syntax.log, manual-firebase-policy.log, manual-firebase-preflight.log, manual-firebase-emulators.log. Fresh authenticated HTTP lifecycle plus admin dispute-count regression: 1 test passed, 0 failed, exit 0 (manual-firebase-http.log).

No Flutter source changed; Flutter analysis/tests/web build were not rerun in this follow-up. No production records/rules were read or modified; deployed rule equality is unknown. Previous billing/API/secret metadata remains the last read-only snapshot, not a new live check. No deploy, billing/API/IAM changes, commit or push.

Console: Firestore > Rules takes firestore.rules; Storage > Rules takes storage.rules for the selected bucket. Index JSON is a CLI file, not a rules-editor payload: create equivalent entries individually in Firestore > Indexes, or use firebase deploy --only firestore:indexes. firebase.json and .firebaserc are local CLI configuration, not Console-paste files. Storage's Firestore lookups may require the Console/CLI cross-service permission prompt, explicitly approved by the deployer. Review existing remote rules/indexes before replacement/deletion prompts; do not assume local equality or use --force.

Safest manual release sequence: staging approval/setup, indexes, await readiness, compatible Functions, updated staging client, restrictive rules, role/legacy/revocation/provider acceptance, separate production decision. Old direct-read donor clients fail closed. Owner/admin full records and donor allowlisted callable views stay distinct. Historical conversation/phone shares and offline caches are not erased by new access rules. Self-registration still creates approved donor/receiver profiles by existing product policy; admin role and protected profile fields cannot be self-assigned.
