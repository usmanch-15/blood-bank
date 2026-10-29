# Dashboard verification — 23 October 2026

Continued from existing commit `2526914`; the working tree was clean at inspection. No previous implementation was discarded. No commit, push, deployment, production data write or release APK was performed.

## Verified fixes in this continuation

- `functions/nearbyDonors.js`: reject malformed, non-string and out-of-band continuation cursors. Stable-data pagination regression covers 205 donors without gaps or duplicates.
- `functions/awarenessWorkflows.js`, `lib/models/awareness_banner.dart`, `lib/widgets/donor_awareness.dart`: include campaign schedule in feed, expire loaded campaigns locally, refresh campaigns every 30 seconds, preserve dismissals during refresh and local-storage failure. Start/deactivation changes can take up to the next successful refresh; expiry relies on device time.
- `lib/screens/donor/donor_dashboard_screen.dart`: nearby request previews now precede awareness banners, after active donation and invitations.
- `lib/screens/requests/request_list_screen.dart`: refresh lists after returning from tracking/actions; Critical includes life-threatening requests.
- `test/dashboard_ui_test.dart`, `functions/test/emulator.test.js`: schedule boundaries, malformed donor cursors, multi-page donors and canonical invitation pagination regressions.
- `functions/test/dashboard-walkthrough.js`: use dashboard navigation and accessible tab selectors for the updated layout.

## Executed checks

| Check | Actual result |
| --- | --- |
| Flutter tests, final rerun | 50 passed |
| Flutter/Dart analysis, final rerun | No issues |
| Backend policy tests | 13 passed |
| Backend configured syntax check | Passed |
| Auth/Firestore/Storage emulator suite | 48 passed, 0 failed |
| Profile web build with demo emulator define | Passed |
| Git diff whitespace check | Passed |
| Local Chrome, demo emulators | Donor and receiver dark dashboards loaded without page errors; all four request tabs showed seeded records; donor banner displayed below requests and dismissed successfully |
| Callable literal-name/export audit | 30 client names, none missing; dynamic references reviewed |
| Physical Android/iOS tests, native push/OTP/Agora | Not run |
| Production deployment/release APK | Not run, explicitly prohibited |

Widget coverage includes narrow 320px request/banner cards at 1.5x text, English/Urdu RTL, light/dark themes, dismissal and action callbacks. This does not establish that every full screen works at maximum OS text scaling or every tablet size. Source review covers all four hub tabs and tracking confirmations; end-to-end native acceptance/withdrawal remains manual.

The first browser attempts failed because old banner/text selectors no longer matched the layout/Flutter semantics; using dashboard navigation and accessible tab roles passed on rerun. These were test-harness failures, not counted as passing runs.

Security tests cover admin-only campaign mutation/upload, scheduled donor feed access, receiver rejection, event deduplication and request/invitation privacy. Receiver dashboard does not mount awareness; donor mounting checks active role and the server also checks donor mode/capability. Banner media is not confidential: Firebase download URLs may be shared, so donor-only presentation must not be interpreted as secret image storage.

## Deployment blocker and prerequisites

Read-only `functions:list --project blood-bank-98037 --json` returned success with an empty result. The configured project has no deployed Functions; this explains unavailable callable endpoints. All source exports were loaded by the local Functions emulator. UI error sanitization cannot repair absent deployed services.

Before any approved staging/production deployment: confirm intended project and billing/API setup, Auth providers, Storage bucket, Firebase service permissions, and `us-central1` client/server region (or matching `FUNCTIONS_REGION`). Review Firestore rules/indexes, Storage rules and all Functions together. Configure `AGORA_APP_ID` / `AGORA_APP_CERTIFICATE` and `TWILIO_SID` / `TWILIO_PHONE` / `TWILIO_AUTH_TOKEN` as required by retained voice/SMS features. Verify indexes reach ready state, callable inventory is nonempty, and staging workflows succeed before distributing an app build. No deployment was attempted.

Pagination resumes after the last scanned donor, including mid-page stops. Results are distance-sorted per returned page, not globally across all donors. Concurrent location/availability changes can change subsequent pages. An exactly full final page may require one empty continuation to establish exhaustion. My Responses is based on current request participation; it is not a complete declined/withdrawn history.

## Exact manual device checks still required

1. Use staging/demo accounts: approved donor, receiver, dual-mode user and admin. Run on a small Android phone and tablet; repeat in light/dark, English/Urdu, and OS text sizes 100%, 150%, 200%. Inspect scrolling, RTL direction, clipped labels, safe areas and keyboard overlap on both dashboards, request tabs and SOS.
2. Donor home: toggle availability, reopen Settings and relaunch to verify persistence. Confirm active donation and invitations appear before nearby requests, and awareness appears below their previews. Open every card and return.
3. Open Requests. Visit For You, Invitations, My Responses, Active Donation. Open details, cancel an acceptance confirmation (no state change), then accept a different invitation. Return and verify invitation/discovery updates and active assignment appears. Withdraw using the existing confirmation and verify active list refresh. Use separate donors for conflicting commitments.
4. For You: test compatible/no matching requests, radius expansion, Critical including life-threatening, offline/retry, and multiple pages without duplicate IDs. Nearby donors: paginate beyond 200 seeded donors and change filters; ensure cursor resets. Never seed production for this check.
5. Admin: create an inactive bilingual campaign, preview both languages, upload JPG/PNG/WebP below 3 MB, reject oversize/unsupported uploads, set a near-future start/end, then activate. Donor: wait for refresh, dismiss, navigate away/back and relaunch; dismissal remains for the same revision. Update revision and verify it can appear again. Leave it onscreen through expiry. Check views/clicks count once per donor/revision.
6. Switch the same dual-mode account to receiver: no awareness widget; feed returns no campaigns and event recording rejects receiver mode. Confirm receiver request/SOS/history actions work. Ordinary users must fail direct banner writes and Storage uploads; private request/contact data must stay restricted.
7. On a real device with staging configuration, verify push invitations, notification deep links, OTP, location denied/granted, native maps, call/chat actions and return navigation. These are not covered by the profile web build.

Local test logs are ignored artifacts (`verification-flutter-final.log`, `verification-emulators.log`); browser screenshots are under `audit-artifacts/dashboard/`.
