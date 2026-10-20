# Stage C report

## C0 privacy plan

Legacy `blood_requests.contactNumber` and patient/contact fields remain for compatibility and were not migrated or deleted. New private request contact data should be written to `blood_requests/{requestId}/private/contact`, readable only by the requester and approved admins; readers may fall back to the legacy field for existing records. An operator migration, when separately approved, would run `node functions/migrateRequestContacts.js --project <staging-project> --dry-run` followed by the same command without `--dry-run`; rollback restores the exported legacy fields and removes only newly-created private documents. No migration was run in this stage.

## C0-C6 status

| Item | Status | Proof |
|---|---|---|
| C0 private request-contact path | Partly | Existing `users/{uid}/private/contact` pattern and `firestore.rules`; no request-contact migration was run. |
| C1 donor and receiver Chat button | Done | `request_tracking_screen.dart`; existing participant authorization and chat conversation IDs. |
| C2 participant-only chat and closed-state UI | Partly | `firestore.rules`, `chat_screen.dart`; sender and active-request checks exist, but pagination, reports/blocks UI and phone-share confirmation remain. |
| C3 in-app chat notification trigger | Partly | `functions/chatNotifications.js`; stable notification IDs and blocked-sender check; response/status notification coverage is incomplete. |
| C4 Stage F and completion preservation | Done | No invite/call lifecycle or donation completion rule changed. |
| C5 localization and chat states | Partly | `chat_screen.dart`, `app_localizations.dart`; English/Urdu hint and loading/error/empty states exist, but several new strings still need localization. |
| C6 required tests | Not done | Existing emulator chat tests cover spoofing, recipient privacy and suspension; the complete new C6 matrix and widget tests were not added. |

## Verification

No Stage C verification suite was claimed. The requested Flutter commands were not run to completion in this environment. Real-device FCM delivery and background/cold-start notification taps are **NOT TESTED** by request.

## Manual checklist

Donor/Receiver: open an active accepted request, open Chat, verify participant-only access, send a message, see timestamps, close the request and verify read-only behavior, verify the Urdu/English phone-sharing hint. Admin: review authorized audit/report paths; verify no message body or phone number appears in notification records.

## Deployment and migration

No deployment or migration occurred. Before deployment, review and deploy functions, Firestore rules, and any required indexes from staging only. Rollback is source rollback plus removal of newly-created private contact documents; legacy request fields remain untouched.

## Remaining work

Pagination, unread counters, read receipts, message/user reports, blocking UI and backend workflow, explicit phone-sharing confirmation/storage, response/status notifications, full localization, and the complete emulator/widget test matrix remain. Stage D and later work has not started.

STAGE C: NOT ACCEPTED

## C-1 backend foundation update

| C-1 item | Status | Proof |
|---|---|---|
| Block/unblock callable and enforcement | Done | `functions/chatWorkflows.js`, `firestore.rules`, `functions/chatNotifications.js`; emulator block/notification test. |
| Participant reports, rate limit and duplicate protection | Done | `reportConversation` in `functions/chatWorkflows.js`; emulator duplicate report test. |
| Per-participant unread counters and mark-read | Done | `chatNotifications.js` atomic increment and `markConversationRead`; emulator participant-scope test. |
| Server message/open-state validation | Partly | Firestore rules enforce sender, type, length, server timestamp and open request; spam-burst and conversation/request reference validation need additional coverage. |
| Explicit phone sharing callable | Partly | `sharePhoneNumber` requires `confirm:true`, own private contact and participant/open state; emulator currently covers confirmation rejection, successful privacy assertions remain. |
| Closed/released read-only enforcement | Done | Firestore message rule and callable conversation guard. |
| Private request contact path | Partly | `blood_requests/{id}/private/contact` owner/admin rule added; no migration executed and new request-write integration remains. |
| C-1 emulator/rules tests | Done | Full Java 21 emulator suite: **38 passed, 0 failed**. |

`npm test`: 11 passed. `npm run check`: passed, including `chatWorkflows.js`.

New backend callables: `blockUser`, `unblockUser`, `markConversationRead`, `reportConversation`, `sharePhoneNumber`. New schema fields include conversation `blocks`, `blockedUserIds`, and `unread`; phone-share messages use `type: phone_share`. No index was added. Deploy after review with `firebase deploy --project <staging-project> --only functions,firestore:rules`; deploy indexes only if a staging error identifies a required index. The private-contact migration remains operator-only and was not run: `node functions/migrateRequestContacts.js --project <staging-project> --dry-run`, then remove `--dry-run` only after review. Rollback is source/rules rollback and removal of newly-created private contact documents; legacy fields remain untouched.

C-2 remains: chat UI pagination, unread badges/read receipts, timestamps/date separators, reports/block controls, phone-share confirmation UI, and full localization. C-3 remains: response/status notification expansion and routing verification.

STAGE C-1: NOT ACCEPTED — the full emulator and npm checks pass, but the required C-1 test matrix and successful phone-share/private-contact coverage are not complete.

## C-3 notification and push update

| C-3 item | Status | Proof |
|---|---|---|
| Request/response/donation notification records | Done | `functions/requestWorkflows.js` creates stable request update, response, closure and donation-confirmation records. |
| Generic chat notification and blocker suppression | Done | `functions/chatNotifications.js` and `functions/index.js`; stable `chat_{conversation}_{message}` IDs and blocked-sender check. |
| Preference-aware FCM delivery | Done | Existing `functions/notificationService.js` and `sendPushNotification` trigger; master/category preferences and device token cleanup are preserved. |
| Recipient/state validation | Partly | Workflow authorization and active/request-state checks exist; a complete C-3 notification emulator matrix was deferred. |
| Urgency priority and safe payloads | Partly | Existing push service uses generic payloads and high Android priority; urgency-specific wording/priority is not separately implemented. |
| Tap routing and safe fallback | Partly | `lib/services/push_navigation_service.dart` routes chat/request/report/SOS types and falls back to inbox; authorization/duplicate-target coverage remains untested. |
| In-app inbox consistency | Done | Existing notification history reads stable notification records and supports read updates. |

Changed files for C-3: `docs/stage-c-report.md` only; the existing notification implementation already covered the requested event paths, so no new backend or Flutter code was required in this pass. No new rules, indexes, or functions were added.

Deploy commands after review (staging only): `firebase deploy --project <staging-project> --only functions`; `firebase deploy --project <staging-project> --only firestore:rules`; deploy indexes only if staging reports a required index. No deployment was run.

NOT TESTED: real-device FCM delivery; background notification taps; cold-start notification taps; and all C-3 automated tests, because tests were deferred by the user request. APK/Gradle builds were not run.

Manual checklist: Donor receives accepted/agreed/ready/withdrawn/declined and donation-confirmed records; receiver receives acceptance and request-status records; both receive generic chat notifications without message bodies or phone data; disable preferences and verify push suppression; tap each notification and verify safe routing; admin reviews notification records without private payload data.

Remaining for Stage D: donation history, confirmation/dispute corrections, reminders and certificates. Stage C is otherwise closed only after the deferred C-3 verification is run.

## Full Stage C summary

| Area | Status |
|---|---|
| C0 legacy private-contact plan/path | Partly |
| C1 request tracking Chat entry | Done |
| C2 participant chat foundation/UI | Partly |
| C3 notifications and push | Partly |
| C4 preservation of Stage F and donation completion | Done |
| C5 localization and chat states | Partly |
| C6 required automated verification | Not done |

## C-2/C-3 implementation truth table

| Requirement | Status | Evidence |
|---|---|---|
| Unread badge on Chat entry/list | NOT DONE | No badge widget or conversation-list unread rendering exists; backend counter is in `functions/chatNotifications.js`. |
| Visible message times | NEW CODE ADDED | `lib/screens/communication/chat_screen.dart`. |
| Today/Yesterday/date separators | NEW CODE ADDED | `ChatScreen._day`. |
| Message pagination and older-load retry | NOT DONE | Current stream uses `limitToLast(30)` without a cursor/load-older implementation. |
| Mark read on open/new messages | NEW CODE ADDED | `ChatScreen._loadState` and stream call `markConversationRead`. |
| Block/unblock UI | NEW CODE ADDED / PARTLY | `_block` calls `blockUser`; unblock UI is not implemented. |
| Report UI | NEW CODE ADDED | `_report` calls `reportConversation`. |
| Share-phone confirmation dialog | NEW CODE ADDED | `_share` requires confirmation before `sharePhoneNumber`. |
| Read-only banner/input disable | NEW CODE ADDED | `_loadState` and `MaterialBanner`. |
| Urdu strings | NOT DONE | Existing hint is bilingual; new menu/dialog/banner text is hard-coded English. |
| Response notifications accepted/agreed/ready/withdrawn/declined | ALREADY EXISTED | `functions/requestWorkflows.js` notification calls. |
| Status notifications cancelled/expired/fulfilled/partially fulfilled | ALREADY EXISTED | `closeInternal` and `confirmDonation`. |
| Donation-confirmation notification | ALREADY EXISTED | `confirmDonation` in `requestWorkflows.js`. |
| Urgency-based priority | NOT DONE | `notificationService.js` uses one high Android priority without urgency mapping. |
| Inbox rendering of new types | ALREADY EXISTED | `notification_history_screen.dart`. |
| Unauthorized/closed tap message | NOT DONE | `push_navigation_service.dart` routes targets without authorization/closed-state validation. |

Changed files: `lib/screens/communication/chat_screen.dart` and this report. No tests or Flutter/emulator/build commands were run. No backend files changed in this pass.

STAGE C: INCOMPLETE — C-2 pagination, unread badge/list, unblock, Urdu localization, and C-3 urgency and target-validation work remain.

STAGE C: IMPLEMENTED (untested) — notification paths and existing routing are in place, but the requested C-3 tests and device verification were deferred.
