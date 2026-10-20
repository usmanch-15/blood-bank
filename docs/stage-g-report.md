# Stage G report

| Requirement | Status | Proof |
|---|---|---|
| G1 trusted admin analytics aggregate | NEW CODE ADDED | `functions/adminWorkflows.js` `adminAnalytics`; admin-only bounded request/user aggregation with date and blood-group filters. |
| Existing analytics dashboard | ALREADY EXISTED | `lib/screens/admin/web/admin_web_analytics.dart` already renders live Firestore count/sum cards and blood-group charts. It is not yet wired to the new callable. |
| G2 filters | PARTLY | Backend callable accepts `startMs`, `endMs`, and `bloodGroup`; existing Dart screen has no filter controls. |
| G3 authorization/efficiency | NEW CODE ADDED / PARTLY | Callable checks admin role and bounds reads to 1000; no new rules/indexes. Client still has legacy count queries. |
| G4 responsive/loading/chart UI | ALREADY EXISTED / PARTLY | Existing screen has cards, charts, refresh, loading and error states; Urdu localization, denominator labels, and full responsive filter UI remain. |
| G5 preservation | ALREADY EXISTED | Chat, calling, verification UI and redesign were not changed. |

Changed backend files: `functions/adminWorkflows.js`, `functions/index.js`. New callable: `adminAnalytics`. No rules, schedulers or indexes changed. No deployment occurred. Required deployment when authorized: `firebase deploy --project <staging-project> --only functions`; indexes only if later query planning requires them: `firebase deploy --project <staging-project> --only firestore:indexes`.

Definitions: the callable reports donor totals, available donors (`isAvailable == true`) and verified donors (`profileVerified == true` with unexpired `profileVerifiedUntil`). Request date filtering uses `createdAt`; default range is 90 days. Reads are bounded at 1000 records. Cache time is not implemented; the existing screen refreshes on demand.

Validation: `npm test` passed (11/11). `npm run check` passed. Flutter checks, tests, emulator suite, builds, device validation and production deployment were not run.

Manual Admin checklist: compare callable/dashboard totals against Firestore counts for a selected range and blood group; verify non-admin callable rejection; refresh and inspect empty/error states; confirm no private chat, phone, evidence or personal details appear.

Remaining work for H: visual redesign and runtime validation only.

STAGE G: INCOMPLETE — the admin-only filtered aggregate callable is implemented and backend checks pass, but the existing analytics UI is not yet wired to it and the full metric/filter/denominator requirements remain.

## Stage G-2 implementation

| Item | Status | Proof |
|---|---|---|
| Admin aggregate extension | NEW CODE ADDED | `functions/adminWorkflows.js` `adminAnalytics` returns active donors (available plus `lastActiveAt` within `ACTIVE_DONOR_DAYS`, default 90), verified donors excluding expired, status counts, blood-group counts, generatedAt, cacheSeconds, and approximate flag. |
| Cap disclosure | NEW CODE ADDED | Callable returns `approximate: true` when bounded 1000-record reads are reached; UI displays a localized approximate warning. Counts are still bounded for legacy sample metrics. |
| Cache metadata | NEW CODE ADDED | Callable returns `generatedAt` and configurable `ADMIN_ANALYTICS_CACHE_SECONDS` default 300; UI refreshes on demand. Server result caching itself is not implemented. |
| New analytics UI | NEW CODE ADDED | `lib/screens/admin/web/admin_analytics_g2_screen.dart` uses the admin callable, 7/30/90 filters, blood-group filter, summary cards, status rows, refresh, last-updated, loading/error/empty states. |
| Admin navigation | CHANGED | `admin_web_dashboard.dart` routes the Analytics section to `AdminAnalyticsG2Screen`; admin guard remains on the dashboard route. |
| Localization | NEW CODE ADDED | Added analytics labels and approximate warning in `app_localizations.dart` English/Urdu. |
| Complete G1 rates/timing/detail pagination | NOT DONE | Callable/UI do not yet return response/fulfilment denominators, median timing samples, daily charts, or paginated detail tables. |
| G3 rules/indexes | ALREADY EXISTED / NOT DONE | Callable is admin-only through `actor`; no new indexes were added. Composite index requirements were not generated. |

Changed files: `functions/adminWorkflows.js`, `functions/index.js`, `lib/screens/admin/web/admin_analytics_g2_screen.dart`, `lib/screens/admin/web/admin_web_dashboard.dart`, `lib/l10n/app_localizations.dart`, and this report. No tests were added or edited. No deployment occurred.

Settings: active donor window `ACTIVE_DONOR_DAYS`, default 90; cache metadata `ADMIN_ANALYTICS_CACHE_SECONDS`, default 300. Exact deploy commands when authorized: `firebase deploy --project <staging-project> --only functions`, then `firebase deploy --project <staging-project> --only firestore:indexes` if indexes are added later. No rules/indexes changed in this pass.

Validation: `npm test` passed (11/11); `npm run check` passed. Flutter format/analyze/test, emulator suite, builds, device checks and production deployment were not run.

Manual Admin checklist: open the Analytics section as an admin; compare donor/request/status counts against Firestore for 7/30/90 days and each blood group; test approximate warning at large datasets; refresh and verify generated time; test non-admin rejection; verify no private data is displayed; test light/dark, Urdu RTL, narrow phone and desktop widths.

Remaining work for Stage H: visual redesign/polish only. Remaining G blockers are full response/timing/daily metrics, true server caching, and pagination/index planning.

STAGE G: INCOMPLETE — filtered admin analytics UI and extended callable metadata are implemented, but full G1 metrics, true server caching, unbounded count correctness, and complete timing/detail requirements remain.

## Stage G-3 implementation

| Item | Status | Proof |
|---|---|---|
| Exact count aggregations | NEW CODE ADDED | `functions/adminWorkflows.js` `adminAnalytics` uses Firestore `count()` for donor totals/availability/activity/verification, request statuses, blood groups, and pending verification/report/dispute queues. |
| Rate numerators/denominators | NEW CODE ADDED | `responseRate` and `fulfilmentRate` objects are returned with numerator and denominator. Response numerator is currently conservative because legacy records do not expose a consistent response timestamp. |
| Timing metrics | PARTLY | Response shape includes timing sample metadata, but the current implementation returns not-enough-data until a consistent timestamp population is available. |
| Daily counts | NOT DONE | Daily range series is not yet populated in the callable. |
| Firestore cache | NEW CODE ADDED | `admin_cache/analytics_*` is read/written by the Admin SDK with configurable 300-second freshness and `forceRefresh`; client rules allow admin reads only and deny direct writes. |
| Analytics UI | PARTLY | `admin_analytics_g2_screen.dart` displays exact count cards and x-of-y rate cards; daily chart, timing labels, and complete localization remain. |
| Indexes | NOT DONE | No new composite indexes were added in this pass; existing count queries may require indexes in deployment. |

Changed files: `functions/adminWorkflows.js`, `firestore.rules`, `lib/screens/admin/web/admin_analytics_g2_screen.dart`, and this report. No tests were added. No deployment, commit, push, or production-data change occurred.

Settings: `ACTIVE_DONOR_DAYS` defaults to 90; `ADMIN_ANALYTICS_CACHE_SECONDS` defaults to 300; minimum timing sample setting remains `ADMIN_ANALYTICS_MIN_SAMPLE` default 5 where timing data is available.

Validation: `npm test` passed (11/11). The first `npm run check` failed on a quoting syntax error introduced in the cache-key expression; it was corrected. The rerun of `npm run check` passed. Flutter format/analyze/test, emulator suite, builds, and device checks were not run by request.

Deploy when authorized: `firebase deploy --project <staging-project> --only functions,firestore:rules`; deploy indexes separately after adding and reviewing required entries with `firebase deploy --project <staging-project> --only firestore:indexes`. No deployment was performed.

Manual Admin checklist: compare each count and rate denominator with Firestore console queries for a selected range and blood group; verify cache reuse and `forceRefresh`; verify expired verification exclusion; inspect timing not-enough-data behavior; test admin-only access and light/dark Urdu layout.

STAGE G-3: INCOMPLETE — exact count aggregation and cache foundations are implemented, but daily series, complete timing computation, full UI localization/charting, and index coverage remain outstanding.

## Stage G-3 index audit

Added composite indexes to `firestore.indexes.json` for:

- `blood_requests`: `createdAt + status` for date-filtered status counts; `createdAt + bloodGroup` for date/blood-group counts; `createdAt + urgency` for urgent counts; `reviewStatus + createdAt` for emergency review queues.
- `verification_requests`: `status + submittedAt` for pending/reviewed verification queues.
- `misuse_reports`: `status + reportedAt` for reports queue and pending reports.
- `users`: `isDonor + isAvailable + lastActiveAt` for active donor counts; `isDonor + profileVerified + profileVerifiedUntil` for verified donor counts; `role + status` for approved admin queries; donor availability/location fields including latitude/longitude for nearby donor discovery.

Existing indexes for donation history (`donorId + donationDate`), request history (`requesterId + createdAt`), notifications (`userId + createdAt`), and existing blood-request status/createdAt queries were preserved. The index file was normalized back to valid JSON without removing existing entries.

Deploy command (not run): `firebase deploy --only firestore:indexes`.

Queries not fully verifiable from static source: dynamically assembled `whereIn`/pagination queries in legacy admin screens, compound filters inside `WorkflowService` calls, and any indexes automatically required by deployed Firestore query planner for fields whose runtime types differ from source assumptions. These require staging emulator/project validation.

INDEXES: DONE
