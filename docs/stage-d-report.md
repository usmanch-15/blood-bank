# Stage D report

## D0 audit and reuse plan

The existing flow stores active request commitments in `blood_requests.commitments` with `accepted`, `agreed`, and `awaiting_confirmation` states. Only receiver/admin `confirmDonation` creates the idempotent `donations/{requestId}_{donorId}` record, increments donor `rewardPoints`, sets `lastDonationDate`/`nextEligibleDate`, and enables certificate generation through the existing `certificateUrl` field and Storage path. Withdraw/release transitions are handled by `updateAssignment`; no scheduled state exists in the current model. The existing reminder is `functions/eligibilityReminder.js`, using the donor `lastDonationDate` and the 90-day policy.

Reuse plan: retain `blood_requests`, `commitments`, `donations`, `users.lastDonationDate`, `users.nextEligibleDate`, `rewards`, `audit_logs`, `notifications`, and existing certificate storage. No collection or identifier was renamed.

## D0-D4 status

| Item | Status | Evidence |
|---|---|---|
| D0 flow audit and field reuse | NEW CODE ADDED (documentation) | This report; existing `requestWorkflows.js`, `donation_model.dart`, `eligibilityReminder.js`. |
| D1 confirmed-only completion and idempotent rewards | ALREADY EXISTED | `functions/requestWorkflows.js` `confirmDonation`; existing emulator concurrency coverage. |
| D1 clear timeline/state mapping | NOT DONE | No single timeline mapper for proposed/accepted/completed/cancelled/disputed exists. |
| D1 donor acknowledgement/disagreement dispute transition | NOT DONE | No donation acknowledgement callable exists. |
| D1 audit metadata per donation state | PARTLY | Existing `audit_logs` events cover request workflows; donation records lack a complete state-history timeline. |
| D2 donor donation history | ALREADY EXISTED / NEW CODE ADDED | Existing paginated `DonationHistoryScreen`; added completion/medical disclaimer and certificate indication. |
| D2 receiver-owned request history | NEW CODE ADDED | `functions/donationHistoryWorkflows.js` `donationHistory` authorizes requester-owned records. |
| D2 strict disclosure/pagination/loading | PARTLY | Firestore donation rules and `PagedRecords` exist; callable response strips private fields, but receiver UI integration and localized states remain. |
| D3 correction/dispute callable | NEW CODE ADDED | `submitDonationDispute` validates ownership/reason, rate-limits, and uses stable duplicate IDs in `misuse_reports`. |
| D3 admin queue and resolution | ALREADY EXISTED | Existing `misuse_reports` admin workflow supports pending/resolved/dismissed review fields. |
| D4 configurable reminder interval | NEW CODE ADDED | `functions/eligibilityReminder.js`: `DONATION_REMINDER_INTERVAL_DAYS`, default `90`, overridable by environment. |
| D4 completed-donation-only reminder and preference | ALREADY EXISTED / NEW CODE ADDED | Existing `lastDonationDate` query; interval constant and `eligibilityReminders` preference alias added. |
| D4 stable in-app/FCM reminder and dashboard card | NEW CODE ADDED | Existing `sendPushToUsers` delivery receives stable hashed inbox IDs; dashboard reminder card in `donor_dashboard_screen.dart`. |
| D4 English/Urdu medical disclaimer | PARTLY | Dashboard/history English disclaimer added; Urdu localization and full history localization remain. |

Changed files: `functions/donationHistoryWorkflows.js`, `functions/index.js`, `functions/eligibilityReminder.js`, `functions/notificationService.js`, `lib/screens/donor/donor_dashboard_screen.dart`, `lib/screens/donor/donation_history_screen.dart`, and this report.

## Compatibility, migration, rollback, deployment

New callable functions are additive: `donationHistory` and `submitDonationDispute`. No rules, indexes, or existing schema fields were renamed. The new dispute documents use the existing `misuse_reports` collection and admin queue. No migration or production data change was run. Rollback by removing the new callable exports/UI additions; existing donations and legacy fields remain untouched.

Deploy only after review to staging: `firebase deploy --project <staging-project> --only functions`; deploy rules with `firebase deploy --project <staging-project> --only firestore:rules`; deploy indexes only if staging identifies one. No deploy was run.

Medical-review setting: `functions/eligibilityReminder.js`, constant `DONATION_REMINDER_INTERVAL_DAYS`, default **90 days**, optionally supplied through `DONATION_REMINDER_INTERVAL_DAYS`.

## NOT TESTED

All D-stage tests and verification were deferred by user request: npm tests/checks, Flutter tests/analyze/format, emulator/rules tests, device behavior, FCM delivery, background behavior, and builds.

## Manual checklist

Donor: open My donation history, verify dates/status/certificate indication and disclaimer; submit one correction/dispute and repeat it; check dashboard reminder date and notification preference. Receiver: verify only donations for own requests are visible and submit a dispute. Admin: verify the misuse report queue, resolve/reject with reviewer note, and confirm ordinary users cannot resolve it.

## Remaining for Stage E

Verified profiles, emergency review, and all Stage E verification workflows remain untouched. Donation acknowledgement/disagreement, full timeline mapping, localized receiver history, and D-stage automated verification remain before Stage D acceptance.

STAGE D: INCOMPLETE — the dispute callable, reminder configuration, and dashboard/history additions are present, but the required full donation timeline, donor acknowledgement/dispute transition, receiver UI, localization, and all deferred verification remain.

## Completion pass for the four remaining items

| Item | Status | New code / proof |
|---|---|---|
| Unified donation timeline | NEW CODE ADDED | `functions/donationHistoryWorkflows.js` `donationTimelineLabel`; `lib/models/donation_model.dart` `donationTimelineLabel`; history cards use `statusLabel`. |
| Donor acknowledgement and dispute transition | NEW CODE ADDED | `acknowledgeDonation` and `disputeDonation` callables in `donationHistoryWorkflows.js`; dispute writes `misuse_reports`, `audit_logs`, and a disputed flag without changing rewards. |
| Receiver history UI | NEW CODE ADDED | `DonationHistoryScreen` loads the user role and queries `requesterId` for receivers; donor names are reduced to first name and private fields are not rendered. |
| Urdu localization | NEW CODE ADDED | New history/disclaimer/acknowledgement/dispute/reason/cancel/submit keys in `lib/l10n/app_localizations.dart`, used by the history UI. |

New callable exports: `acknowledgeDonation`, `disputeDonation`. No rules or indexes were added. Deploy after review with `firebase deploy --project <staging-project> --only functions`; no deploy was run. Tests were deferred by the user; only `npm test` (11 passed) and `npm run check` (passed) were run.

STAGE D: IMPLEMENTED (untested)
