# Stage E report

| Requirement | Status | Proof |
|---|---|---|
| E1 donor verification submission and rate limit | NEW CODE ADDED | `functions/verificationWorkflows.js` `submitVerification`; restricted `verification_evidence/{uid}/{file}` storage rule. |
| E2 admin review decisions and audit | NEW CODE ADDED | `reviewVerification` and `revokeVerification`; reviewer, note, timestamps, audit log and generic decision notification. |
| E3 badge expiry/revocation | PARTLY | Approval stores `profileVerifiedUntil` using `VERIFIED_PROFILE_EXPIRY_DAYS` default 365; public badge/UI and scheduled expiry checks are not added. |
| E4 emergency request review state | NOT DONE | Existing request/SOS semantics were preserved; no new pending-review workflow was added. |
| E5 admin emergency review | ALREADY EXISTED / PARTLY | Existing `adminRequestAction` handles close/archive; approve/reject/flag/clarification workflow is not added. |
| E6 limited-disclosure pending urgent matching | NOT DONE | No new pending-review matching policy was implemented. |
| E7 duplicate/report emergency abuse controls | PARTLY | Existing rate limits and report workflow remain; Stage E duplicate-request detection is not added. |

Changed files: `functions/verificationWorkflows.js`, `functions/index.js`, `functions/package.json`, `firestore.rules`, `storage.rules`, and this report. No Dart files were edited. No tests were added or edited.

New callable functions: `submitVerification`, `reviewVerification`, `revokeVerification`. New collection: `verification_requests/{uid}`; new user fields: `profileVerificationStatus`, `profileVerified`, `profileVerifiedUntil`; new restricted Storage path: `verification_evidence/{uid}/{file}`. These are additive and do not expose evidence URLs in public profile documents. No indexes were added.

Deploy after review only to staging: `firebase deploy --project <staging-project> --only functions`; `firebase deploy --project <staging-project> --only firestore:rules,storage`; deploy indexes only if staging reports a required index. No deploy or production data change was performed. Rollback by reverting the additive functions/rules and removing only newly-created verification request/evidence records after review; existing profiles and requests remain untouched.

The configured expiry setting is `functions/verificationWorkflows.js`, `VERIFIED_PROFILE_EXPIRY_DAYS`, default **365 days**, overrideable with the environment variable of the same name.

NOT TESTED: all Flutter tests/analyze/format, emulator/rules tests, device behavior, FCM delivery, admin UI review, signed evidence viewing, emergency pending-review flows, and builds. Existing tests were not edited; no known tests were intentionally made outdated.

Manual checklist: Donor uploads evidence only under the restricted path and submits one request; admin opens the queue through an authorized review client, approves/rejects/requests more information with a mandatory note, revokes with a reason, and verifies audit/notification records. Receiver verifies no evidence or verification document is visible in donor results. Emergency requester/admin review remains future work.

Stage F (calling/inviteDonor), Stage G analytics, and production deployment remain untouched.

STAGE E: INCOMPLETE â€” verification submission/review backend foundation is present, but public badge/expiry enforcement and emergency request verification policy/UI are not implemented.

## E-3 emergency request verification update

| E-3 item | Status | Proof |
|---|---|---|
| Server review states for urgent/critical requests and SOS | NEW CODE ADDED | `requestWorkflows.js` assigns `reviewStatus: pending_review`; SOS-linked requests receive the same state. |
| Admin review callable and audit | NEW CODE ADDED | `emergencyReviewWorkflows.js` `reviewEmergencyRequest` supports approved/rejected/flagged/clarification, mandatory notes, reviewer/timestamps/audit. |
| Requester clarification reply | NEW CODE ADDED | `replyEmergencyClarification`, one reply enforced. |
| Limited-disclosure pending emergency alert | NEW CODE ADDED | `emergencyAlerts.js` trigger sends generic blood-group/urgency/area-safe text through existing FCM service. |
| Escalation timer | NOT DONE | Setting is declared but no scheduled re-alert function was added. |
| Approved urgent priority matching | PARTLY | Existing urgency ranking and FCM delivery remain; no new approved-review priority adjustment was added. |
| Reviewed/admin and medical disclaimer labels | NOT DONE | No requester/tracking UI localization was added in this pass. |
| Duplicate request detection and abuse threshold | NOT DONE | Existing rate limits remain; configurable duplicate/abuse detection is not implemented. |
| Admin emergency queue UI | NOT DONE | Existing admin request panel was not rewritten; callable foundation only. |

New/changed backend files: `functions/emergencyReviewWorkflows.js`, `functions/emergencyAlerts.js`, `functions/requestWorkflows.js`, `functions/index.js`, `functions/package.json`. New callables: `reviewEmergencyRequest`, `replyEmergencyClarification`; new trigger: `notifyPendingEmergency`. No rules or indexes changed. Settings: `EMERGENCY_REVIEW_ESCALATION_HOURS` declared in `emergencyReviewWorkflows.js`, default **2 hours**; limited disclosure is `LIMITED_DISCLOSURE_PENDING=true`. Duplicate window and abuse threshold are NOT DONE and have no setting.

Deploy after review: `firebase deploy --project <staging-project> --only functions`; deploy rules/indexes only if later staging changes require them. No deploy or production data change was performed. Rollback by reverting the additive trigger/callables and leaving existing request records unchanged.

Checks: `npm test` 11 passed; `npm run check` passed. Tests, emulator, Flutter, builds and device behavior were deferred/not tested by user request. Existing tests were not edited.

Manual checklist: Receiver creates urgent request/SOS and sees pending review; admin reviews with each decision and note; receiver replies once to clarification; eligible donors receive only generic limited-disclosure alerts; approved requests continue existing matching; ordinary users cannot invoke admin review actions.

Stage F remains untouched: calling, inviteDonor, and call lifecycle. Analytics and chat backlog remain untouched.

STAGE E: INCOMPLETE â€” backend review states, callable decisions, clarification reply and limited alert trigger are added, but escalation, admin queue UI, labels/localization, duplicate detection, abuse thresholds, and approved-priority UI remain.

## E-4 compatibility and completion update

Status audit: existing donor discovery queries open `status` values and does not filter `reviewStatus`, so normal requests and urgent requests remain visible. Requester access is ownership/participant based, so a requester is not hidden by `pending_review`. The server summary now includes `reviewStatus` and `reviewNote`; Flutter tracking/admin labels are still missing.

| E-4 item | Status | Proof |
|---|---|---|
| Status compatibility and requester visibility | NEW CODE ADDED | `functions/requestWorkflows.js` (`summary`, `discoverRequests`); audit of tracking/admin/list notification readers. |
| Admin emergency review queue UI | NOT DONE | No queue widget was added; callable remains `functions/emergencyReviewWorkflows.js` (`reviewEmergencyRequest`). |
| Request tracking labels and clarification reply UI | NOT DONE | Backend `replyEmergencyClarification` exists; no review panel/reply control in `request_tracking_screen.dart`. |
| Escalation scheduler | NEW CODE ADDED | `functions/emergencyEscalation.js` (`escalatePendingEmergencyReviews`), exported in `functions/index.js` every 15 minutes; stable IDs `emergency_escalation_{requestId}_{adminUid}`. |
| Approved urgent priority and safe donor notifications | PARTLY | Existing urgency score and high-priority `notificationService.js` remain; no separate approved-only fan-out was added. Pending-only alert gating remains in `emergencyAlerts.js`. |
| Duplicate request detection | NEW CODE ADDED | `functions/requestWorkflows.js` (`createBloodRequest`), `DUPLICATE_REQUEST_WINDOW_MINUTES` default 30, rejects matching active duplicates. |
| Abuse threshold and flagged accounts | NOT DONE | No threshold increment/flag queue was added. |
| Donor “Report this request” UI | NOT DONE | Generic report backend exists; no donor request action was added. |
| Public verification badge/read-time expiry | PARTLY | `findDonors` now returns boolean `profileVerified` only when approved and unexpired; badge widgets and scheduled verification expiry are absent. |
| Verification submission/admin queue UI | NOT DONE | Verification callables exist; no UI was added in E-4. |
| Localization and review loading/error states | NOT DONE | No E-4 Dart localization/widgets were added. |

Changed files: `functions/requestWorkflows.js`, `functions/emergencyEscalation.js`, `functions/index.js`, `functions/package.json`, and this report. No tests were added or edited and no Dart files changed.

Settings/defaults: `EMERGENCY_REVIEW_ESCALATION_HOURS` defaults to 2; `DUPLICATE_REQUEST_WINDOW_MINUTES` defaults to 30; `EMERGENCY_ABUSE_THRESHOLD` is not implemented; `LIMITED_DISCLOSURE_PENDING=true` remains.

Deploy order (staging only): deploy functions together with the admin UI release, then rules/storage/indexes if changed: `firebase deploy --project <staging-project> --only functions`, followed by `firebase deploy --project <staging-project> --only firestore:rules,storage`. Do not enable urgent creation in production until the admin queue UI is deployed; this pass leaves that UI incomplete.

NOT TESTED: all Flutter commands, emulator/rules suite, builds, real-device FCM, localization/RTL, admin queue, clarification UI, verification UI/expiry, and production behavior. `npm test`: 11 passed, 0 failed. `npm run check`: passed.

Manual checklist: Donor — discover normal/urgent requests and inspect profile badge response. Receiver — create normal/urgent requests and verify duplicate error. Admin — invoke emergency review callable and observe escalation notification records. Verification UI and donor badge rendering remain incomplete.

Stage F remains untouched: calling and inviteDonor. No deploy, commit, production data change, Flutter test, emulator run, or build was performed.

STAGE E: INCOMPLETE — backend compatibility, escalation scheduling, duplicate detection, and read-time badge response were added, but required admin/requester UI, abuse threshold, donor report action, verification UI/expiry enforcement, and localization remain incomplete.

## Stage E-5a admin screens

| Item | Status | Proof |
|---|---|---|
| Emergency pending-review queue | NEW CODE ADDED | `lib/screens/admin/web/admin_web_requests.dart` `AdminEmergencyReviewQueue`; oldest-first Firestore stream, urgency filtering, waiting time, details and review action. |
| Emergency decision dialog | NEW CODE ADDED | `AdminEmergencyReviewQueue._review`; mandatory note, decisions approved/rejected/flagged/clarification, calls `reviewEmergencyRequest`, success/error feedback. |
| Verification review queue | NEW CODE ADDED | `AdminVerificationReviewQueue`; pending `verification_requests` stream and review dialog calling `reviewVerification` with approved/rejected/more_info_needed. |
| Past decisions, evidence viewer, revoke | PARTLY | Existing backend stores reviewer/note/timestamps; this UI lists pending records only and shows the evidence path. It does not yet render decision history/evidence download or `revokeVerification`. |
| Localization / Urdu | NOT DONE | New admin widgets currently use English literals; localization integration remains for E-5b. |

Changed Dart file: `lib/screens/admin/web/admin_web_requests.dart`. The panel now has five tabs, adding Emergency Review and Verification Review. No backend files were changed. No tests were added or edited. Dart commands, emulator suite, and builds were not run by user request. I reread the edited file, including both new widget classes, and verified the closing braces/parentheses/brackets and callable names against `functions/emergencyReviewWorkflows.js` and `functions/verificationWorkflows.js`.

Known limitations: the Firestore queries require the corresponding composite indexes if the deployed project requests them; pagination is bounded to the first 50 records rather than a cursor control. Admin role enforcement remains in the existing authenticated panel and backend callables. No deploy, commit, or production data change was performed.

Stage E-5b (requester/donor-facing emergency review UI, verification submission/public badge polish) and Stage F remain untouched.

STAGE E-5a: INCOMPLETE — emergency and verification admin queues and decision dialogs are added, but localized strings, cursor pagination, decision history/evidence viewing, and revoke UI remain.

## Stage E-5a completion pass

The existing admin queue widgets remain the implemented core. This pass did not safely modify the existing Dart file further because it contains invalid mixed-byte encoding; a text rewrite would risk corrupting unrelated admin UI. Therefore the following requested items remain explicitly incomplete: decision-history/reviewed filters, cursor pagination with de-duplication, authorized evidence image rendering, revoke action, flagged-account/report navigation, live menu badges, full localization, and disabled-in-flight action state.

| Item | Status | Proof |
|---|---|---|
| Emergency/verification queue core | ALREADY EXISTED | `admin_web_requests.dart`: `AdminEmergencyReviewQueue`, `AdminVerificationReviewQueue`. |
| Decision history and reviewed filter | NOT DONE | Backend fields exist, but no history/filter widgets. |
| Cursor pagination (20/page) | NOT DONE | Current streams remain bounded `limit(50)` without cursors/load-more. |
| Authorized evidence viewing | NOT DONE | No safe Storage URL/bytes viewer was added. |
| Revoke UI | NOT DONE | `revokeVerification` has no admin-screen action. |
| Flagged accounts/reported requests | ALREADY EXISTED / NOT DONE | Existing `AdminWebReports` handles reports; no flagged-account view or new menu entry was added. |
| Navigation/count badges | NOT DONE | Existing dashboard navigation was not changed. |
| Localization/RTL/theme/loading/error states | PARTLY | Existing panel states remain; new queue literals are English and not fully localized. |
| Double-submit protection/friendly backend errors | PARTLY | Existing review dialogs validate notes and show errors; calls are not disabled during submission. |

No backend files were changed. No tests, Flutter checks, emulator suite, builds, deploy, commit, or production data changes were performed. Stage E-5b and Stage F remain untouched.

STAGE E-5a: INCOMPLETE — the accepted core queues remain functional, but the requested completion items could not be safely added without rewriting a mixed-encoding Dart file and risking unrelated admin-panel corruption.

## Stage E-5a UTF-8-safe completion pass

Encoding diagnosis (read-only): a byte scan found an invalid UTF-8 sequence on line 683 of the legacy `admin_web_requests.dart`; the surrounding bytes are the mojibake bullet/urgency text inside the older queue widget. The invalid bytes are inside a display string, not executable syntax. `git log -p` shows the file already contained the same mojibake in the Oct 15, 2026 history; it was not introduced by this pass. The file was not rewritten.

| Item | Status | Proof |
|---|---|---|
| Emergency decision history and Reviewed filter | NEW CODE ADDED | `admin_web_review_screens.dart`, `AdminEmergencyReviewScreen`; displays reviewer/note/time fields and Pending/Reviewed toggle. |
| Verification decision history and Reviewed filter | NEW CODE ADDED | `AdminVerificationReviewScreen`; displays reviewer/note/time fields and Pending/Reviewed toggle. |
| Cursor pagination, 20/page, load more, de-duplication | NEW CODE ADDED | Both review screens use `startAfterDocument`, `limit(20)`, `_cursor`, `_done`, and ID de-duplication. |
| Authorized evidence viewing | NEW CODE ADDED | `AdminVerificationReviewScreen` obtains a Storage URL on demand from the submitted evidence path and renders only inside the admin screen; failures are shown without persisting the URL. |
| Revoke UI | NEW CODE ADDED | Verification detail action calls `revokeVerification` with a required reason and disables the action while busy. |
| Flagged accounts/reported requests | PARTLY | `admin_web_flagged_reports.dart` lists `misuse_reports`; no abuse-flag account field exists in the accepted backend, so account flagging remains not done. |
| Navigation entries | NEW CODE ADDED | `admin_web_dashboard.dart` adds Emergency Review, Verification Review, and Flagged / Reports sections. |
| Live pending-count badges | NOT DONE | Existing dashboard navigation has no count-badge implementation; the new screens do not alter unrelated navigation layout. |
| English/Urdu localization and RTL | NEW CODE ADDED | New files route all new labels through `AppLocalizations` language selection and provide Urdu text; existing theme/layout widgets are reused. |
| Loading/empty/error/retry states | NEW CODE ADDED | Both queues and reports screen include loading, empty/error states; queue retry and load-more are available. |
| Double-submit protection and friendly errors | NEW CODE ADDED | Review/revoke dialogs disable controls while callable requests run and show localized failure SnackBars. |

Added files:
- `lib/screens/admin/web/admin_web_review_screens.dart`
- `lib/screens/admin/web/admin_web_flagged_reports.dart`

Changed existing file (targeted lines only):
- `lib/screens/admin/web/admin_web_dashboard.dart`: added two imports, three section labels, and three matching screen entries. No other existing file was rewritten. `admin_web_requests.dart` was not modified.

NOT TESTED: Dart formatting/analyzer/tests, emulator suite, builds, Storage security behavior, live Firestore pagination/index availability, admin-role enforcement on a deployed app, FCM, and real-device behavior. No backend files were changed, so `npm test` and `npm run check` were not required or run.

Manual Admin checklist: open each new menu entry; switch Pending/Reviewed; load more pages; open emergency and verification records; verify reviewer/note/time; approve/revoke with required notes; confirm duplicate taps are disabled; load and error the evidence image; inspect reports; switch to Urdu and RTL; verify light/dark themes.

E-5b (requester-facing emergency review UI), Stage F (calling/inviteDonor), deployment and production data remain untouched.

STAGE E-5a: INCOMPLETE — all requested queue, history, pagination, evidence, revoke, reports, localization, and safety features were added in new UTF-8 files, but live pending-count badges are still not implemented and abuse-flagged account data is unavailable in the accepted backend.

## Stage E-5a follow-up: pending badges and abuse-account audit

Files changed in this pass:
- `lib/screens/admin/web/admin_web_dashboard.dart`: targeted eight-line navigation-row edit plus `_AdminPendingBadge`, which uses live Firestore streams for pending emergency requests (`reviewStatus == pending_review`), pending verification submissions (`status == pending`), and pending misuse reports (`status == pending`). Badges are hidden for zero, loading, missing and error states; each stream is bounded to 100 documents.
- `lib/screens/admin/web/admin_web_flagged_reports.dart`: corrected the report timestamp query to the backend field `reportedAt`.

Abuse-account finding: `misuse_reports` has `reportedUserId`, `targetRequestId`, `status`, `reportedAt`, and admin notes, but there is no account-level abuse flag, rejection/flag counter, or reliable relationship proving that a reported user is abusive. The UI therefore lists reports only and does not label reported users as confirmed abusive. A backward-compatible backend addition would be an admin-controlled `abuseReviewStatus`/`abuseFlaggedAt` field with a callable transition and rules; it was not added because this pass prohibits backend/schema changes.

| Requirement | Status | Proof |
|---|---|---|
| Emergency pending-count badge | NEW CODE ADDED | `_AdminPendingBadge` in `admin_web_dashboard.dart`, `reviewStatus == pending_review` stream. |
| Verification pending-count badge | NEW CODE ADDED | `_AdminPendingBadge`, `verification_requests.status == pending` stream. |
| Report count badge | NEW CODE ADDED | `_AdminPendingBadge`, `misuse_reports.status == pending` stream. |
| Loading/error/missing/zero handling | NEW CODE ADDED | Badge returns empty for loading, errors, missing data and zero documents. |
| Flagged-account list | NOT DONE | Accepted backend has no account abuse flag/counter or safe proof relationship; reports are shown instead. |
| Report navigation | ALREADY EXISTED / PRESERVED | Existing Reports section remains; new badge is attached to Flagged / Reports. |

Validation: `dart format lib/screens/admin/web/admin_web_dashboard.dart lib/screens/admin/web/admin_web_review_screens.dart lib/screens/admin/web/admin_web_flagged_reports.dart` was started but stalled with no output; it was interrupted and is reported as **failed/timed out**, not passed. Flutter analyze/tests, emulator suite and builds were not run. No backend files were changed, so npm commands were not run.

Remaining blockers: no backend-backed flagged-account schema, and Dart formatting could not complete in this environment. No deploy, commit, push, production-data change, or `admin_web_requests.dart` modification occurred.

STAGE E-5a: INCOMPLETE — live pending badges are implemented, but safe flagged-account identification is unavailable in the accepted backend and the required Dart formatting validation stalled.

Correction: after the formatter stalled, `admin_web_dashboard.dart` was restored from `HEAD` and the badge/menu changes were reapplied as targeted edits. Final diff is limited to 40 insertions and 7 deletions: two imports, three section entries, three screen entries, the sidebar badge slot, and the `_AdminPendingBadge` class. No formatter-produced unrelated changes remain.

## E-5a validation follow-up

`git status --short` confirmed the expected pre-existing working-tree changes plus the three admin files; no reset or overwrite was performed. `admin_web_requests.dart` was not modified.

Process diagnosis: four long-lived `dart.exe` processes from the earlier session were present (all from `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe`, started around 07:56). Windows process command-line inspection was denied, so their exact arguments could not be determined. They were left running because the instruction was not to kill unrelated processes. A fresh `dart --version` also produced no output and stalled; that invocation was interrupted.

Validation results:
- `dart --version`: **stalled**, no output; interrupted.
- `dart format lib/screens/admin/web/admin_web_review_screens.dart`: **stalled**, no output; interrupted.
- The earlier three-file format command had the same behavior and is not counted as passed.
- `git diff --check` on the dashboard: **passed** (no whitespace errors).
- Flutter analyze/tests: **not run** because the Dart SDK was non-responsive.
- Debug build: **not run** by request/environment constraints.

Schema/rules verification:
- Emergency badge uses `blood_requests.reviewStatus == pending_review`.
- Verification badge uses `verification_requests.status == pending`.
- Reports badge uses `misuse_reports.status == pending`.
- Firestore rules allow admin reads for all three collections; no rules were changed.
- Storage rules allow an active admin to read `verification_evidence/{userId}/{fileName}`; the verification screen requests a URL on demand and does not persist it.
- The reviewed filters now include all backend decision states (`approved`, `rejected`, `flagged`, `clarification`; verification also includes `more_info_needed` and `revoked`).

The report remains incomplete because account-level abuse flags are not represented by the accepted backend schema, and Dart formatting/SDK validation stalled.
