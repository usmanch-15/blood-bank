# Reliability verification — 2026-10-04

Scope: the Smart Blood Bank request supplied in `Pasted text.txt`, against the existing repository. No separate audit document was available, so claims were checked against source and executable tests. No deployment, production migration, commit or push was performed.

## Verified changes

| Area | Change and evidence |
| --- | --- |
| Authentication | Login/splash share approved-account policy; capability flags and availability are initialized; mode switching cannot grant admin. Policy and emulator tests pass. |
| Session notifications | Login/restoration initialize private device tokens; token refresh subscription is retained; logout clears token. Physical delivery unverified. |
| Donor/profile | Availability persists; profile validates names/phone; direct phone edits are blocked; phone linking refreshes Auth claims. Location requires consent, permission failure offers settings, published coordinates are approximate. |
| Matching | Indexed latitude-band paging with spherical distance/compatibility/eligibility filters; SOS uses 15 km then 30 km only when necessary. Radius/filter emulator case passes. |
| Request lifecycle | Acceptance is separate from confirmation. Confirmation requires assignment, active parties and compatible groups. Fixed server reward is atomic/idempotent. Cancellation allows only owner status transition, not ownership/fulfillment edits. |
| Security | Client donation/reward forgery and arbitrary notification creation blocked; private contact/token data; rate-limited contact access; cleanup callable authenticates caller and recent login. Emulator negative cases pass. |
| Rewards/certificates | Screen reads server totals; confirmed donations expose certificate generation/download. PDF uses byte upload for mobile/Web. End-to-end generation/upload/download remains a manual check. Unsupported bonus claims were removed. |
| UI | Shared field theme colors, profile fallback, form validation, Unicode hospital names, Pakistani phone normalization, discard guards, password visibility/loading/error states and keyboard-aware password sheet. Small-viewport widget tests pass; full visual/device QA blocked. |
| Configuration | Invalid animation asset declaration and unused camera permission removed; Android intent queries/channel added; optional App Check/Crashlytics configuration documented. |
| CI | Analyze/tests no longer continue on error; emulator checks added; artifact is explicitly a debug demo APK. |

Existing code already had a persisted theme controller, notification-tap navigation, a 90-day client eligibility helper and the correct `misuse_reports` collection in the reporting service. Those were not missing implementations. Existing private-contact support was extended instead of claiming all phone data was previously public. The old README's pending-signup policy and broad platform/feature claims were inaccurate.

## Automated results

| Check | Result | Scope |
| --- | --- | --- |
| Flutter analysis | PASS | No issues found. |
| Flutter tests | PASS | 24 tests: policy/status/modes, validators, date/model behavior, dark/light fields and keyboard/password form. |
| Backend syntax check | PASS | index.js, secureWorkflows.js, nearbyDonors.js. |
| Backend policy tests | PASS | 4 tests. |
| Firebase emulator suite | PASS | 10 cases using isolated Auth, Firestore and Storage. |
| Flutter Web compilation | PASS | Final debug JavaScript build exited 0 with `--no-wasm-dry-run --dart-define=USE_FIREBASE_EMULATORS=true`. Earlier optional WASM dry-run warnings are not a WASM certification. |
| Android debug build | BLOCKED | Command failed: local Java 25.0.3 is incompatible with Gradle 8.13. Requires JDK 17 configuration and rerun. |
| Dependency security audit | FAIL | Remaining production advisories: 7 moderate, 2 high, 0 critical. See dependency-audit.json. Major upgrade/remediation remains before production. |
| Full browser UI flow/screenshots | BLOCKED | No browser surface was available to the computer-use tool. No rendered-screen claim or screenshots fabricated. |
| Device OTP/push/maps/signing | BLOCKED | Requires device, provider credentials/configuration, permission tests and release signing. |

Emulator cases cover signup schema/mode/availability/privilege boundaries; inactive/unauthenticated access; cancellation and ownership forgery; notification/donation forgery; verified phone claims and consent; geographic matching; cancelled/incompatible requests; unrelated donors; concurrent/duplicate confirmations, forged points and 90-day interval; deletion auth and data/file cleanup.

These tests directly invoke callable handler bodies. They do not exercise Flutter through the callable HTTP endpoint or prove outbound notification delivery. Flutter tests are unit/widget tests, not full app integration tests. Local command logs are ignored development artifacts: flutter-tests.log, emulator-tests.log, android-build.log, web-build-final.log. CI has not been run remotely.

## Remaining limits / external steps

1. Install/configure JDK 17 (`flutter config --jdk-dir=...`), run `flutter doctor -v`, then `flutter build apk --debug`. Configure real private signing before release; current release signing remains debug.
2. Review migration, deploy indexes/rules/functions and client together in an explicitly selected staging project. No production data was changed. Follow README rollout instructions and back up first.
3. Remediate dependency advisories with a tested major Firebase Admin/tooling upgrade. Development-tool dependencies also have audit findings; the saved audit focuses on production packages.
4. Register phone Auth fingerprints/test numbers; verify real OTP linking. Direct profile phone editing remains disabled until verified-change UX is deliberately implemented.
5. Validate channel permissions, refresh/login/logout tokens and foreground/background/tap push on Android. Configure optional Twilio and verify consent before SMS tests.
6. Register App Check providers/debug tokens, monitor metrics, then explicitly enable enforcement. Verify Crashlytics opt-in with a staging release test crash.
7. Supply restricted Maps keys and a genuine SUPPORT_EMAIL. Web FCM, iOS and desktop remain unverified.
8. Deletion is multi-service, can partially fail, and needs operator retry while the account remains disabled. Backups/delivered messages are outside immediate cleanup.
9. History screens cap recent records at 100. Latitude-band querying can still cost many reads in dense regions. Location rounding means radius boundaries are approximate. Full offline mode is not implemented.
10. Review all screens visually in light/dark/system modes and on a physical keyboard/permission flow. Widget tests cover selected fields, not the entire application.

## Short FYP demonstration checklist

Use the demo emulators or an authorized disposable staging account; do not use real patient data.

1. Signup donor and receiver accounts. Check defaults, login, logout, restored session, suspended-user rejection and donor/receiver switching. Ordinary users must not select admin.
2. Edit donor name/blood group, check invalid inputs, discard changes, reload saved values. Toggle availability and restart. Verify missing/broken avatar fallback.
3. Enable location sharing, allow GPS, then deny permission and permanently deny it; test the Settings action. Turn sharing off and verify the donor disappears from matching.
4. Create a compatible request with a Unicode hospital name. Check invalid quantity/phone/email. Cancel one request and confirm it cannot be accepted.
5. Exercise SOS with donors inside 15 km, only inside 30 km and none nearby. Verify consent/unavailable/ineligible donors are excluded. Distinguish queued notifications from delivered push.
6. Have the matching donor accept, then confirm. Check one donation and +50 points; retry and concurrent calls must not duplicate rewards. A second donation inside 90 days must fail.
7. Open Rewards, generate the confirmed donation certificate, download it, reload and verify it remains available. No points are awarded by certificate generation.
8. Exercise settings, password mismatch/visibility/error/loading, theme persistence, narrow viewport, keyboard and network failure/retry.
9. Reauthenticate and delete the disposable account. Verify related records/private token/upload cleanup and loss of session access.
10. Separately demonstrate Android OTP, real push/navigation, Maps and signed build only after their external checks actually pass.

An end-to-end UI demonstration remains BLOCKED until the browser/device steps are performed. Automated passing cases do not certify emergency response or clinical donation eligibility.
