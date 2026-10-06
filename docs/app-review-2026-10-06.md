# App review — 6 October 2026

## Scope and outcome

Reviewed screen implementations/navigation, controllers, models, services, Firebase rules/functions, Android configuration, CI, and tests. The core donor/receiver/admin foundation is present. The most important work is completing request and SOS lifecycles, restricting access to personal data, and making discovery consistent.

This is a source review with local automated checks, not a full rendered-screen/device certification. App functionality and production data were not changed. Existing working-tree changes were preserved.

| Verification in this review | Result |
| --- | --- |
| Flutter analysis, no dependency resolution | Passed; no issues |
| Existing Flutter tests | All 24 passed |
| Backend syntax checks | Passed |
| Backend policy tests | All 5 passed |
| Rules/emulator and callable HTTP tests | Source reviewed; not executed |
| Browser/device walkthrough, OTP, push/SMS, certificate download | Not executed |
| Android/Web build | Not executed |
| Dependency security audit | Saved reports inspected; no fresh registry audit |

Flutter checks needed approved access to the SDK cache and then completed successfully. Passing tests do not cover every issue below.

## Priority 1: confirmed issues and incomplete core flows

### 1. Excessive access to personal data

Every approved account can read all user, blood-request, donation, and SOS documents. User documents include email and optionally address. Requests contain patient identity, age, gender, reason, contact numbers, and coordinates. SOS stores exact coordinates. Separating donor phone numbers into private documents does not protect those other fields.

Separate minimal discovery data from private profile/request information. Restrict sensitive details to relevant participants and administrators; restrict donation history similarly. Explain request/SOS location disclosure explicitly and align privacy text with actual behavior.

Evidence: `firestore.rules:28`, `:65`, `:90`, `:104`; `lib/screens/receiver/blood_request_form_screen.dart:150`; `functions/secureWorkflows.js:39`.

### 2. Multiple requested units, but only one donation supported

The form/rules permit multiple units, but acceptance stores one `acceptedDonorId`. Confirmation creates one donation at `donations/{requestId}` and marks the entire request fulfilled. A five-unit request therefore closes after one confirmation with no remaining-unit accounting.

Either explicitly constrain the current version to one donation per request or support multiple commitments, recorded contributions, remaining quantity, and partial fulfillment. Preserve idempotent rewards per confirmed contribution and test concurrent donors.

Evidence: `firestore.rules:70`; `functions/secureWorkflows.js:17`, `:57`.

### 3. SOS has no complete response/resolution journey

The server returns an SOS ID, but the receiver controller discards it and the screen closes after success. The donor SOS detail shows urgency, location, and directions without response/contact/arrangement actions. Administrators can resolve SOS records, but receivers have no active-SOS tracking and resolution screen.

Add an active emergency screen with saved ID, processing state, donor responses, hospital/contact details, no-response feedback, and owner cancellation/resolution. Link SOS to a donation request or implement a complete independent response workflow. Remove the client donor-search dependency before calling the server: that lookup can fail or delay an SOS even though the server performs matching itself.

Evidence: `lib/controllers/receiver_controller.dart`; `lib/screens/receiver/sos_emergency_screen.dart`; `lib/screens/notification/sos_alert_detail_screen.dart`; `lib/screens/admin/web/admin_web_requests.dart`.

### 4. Expiration and accepted-request recovery are missing

The app stores `requiredBy`, but server acceptance/confirmation do not enforce it. There is no normal donor withdrawal/reassignment flow. A donor can accept multiple requests before completing one; the interval rule then prevents completing the others, without a normal recovery action. Either participant can confirm a donation alone.

Define expiry, withdrawal, no-show, reopening/reassignment, and dispute behavior. Notify affected participants on cancellation. Decide whether completion requires receiver acknowledgement or another trusted confirmation before issuing points/certificates. Current self-confirmation is an implemented policy, not evidence of a physical donation.

Evidence: `functions/secureWorkflows.js:17`, `:57`; `lib/controllers/donor_controller.dart`; `lib/screens/receiver/receiver_dashboard_screen.dart`.

### 5. Discovery differs between list/map, and assignments can disappear

Find Donors downloads all approved donors and filters blood compatibility, interval, and text locally. It does not filter availability, location consent, distance, or self. The map applies availability, consent, geographic radius, and eligibility. The list can consequently offer a call action that the backend rejects for an unavailable donor.

The donor dashboard fetches the newest 100 pending/accepted requests globally before filtering. An older assigned request can disappear behind newer unrelated requests.

Use a shared discovery policy; distinguish an intentional directory from nearby matching; exclude self and label availability/distance. Query assigned requests separately and give them a dedicated section.

Evidence: `lib/screens/receiver/donor_matching_screen.dart:93`, `:144`; `lib/services/geo_location_service.dart`; `lib/screens/donor/donor_dashboard_screen.dart:345`.

### 6. Hospital address and matching coordinates can disagree

The request form defaults coordinates to the user's current GPS position. Hospital name/address are separate text fields; changing the hospital does not update those coordinates. Matching can use the requester's home instead of the hospital.

Add a hospital/location picker with a map pin, manual fallback, and explicit meeting-location confirmation. Keep current location as a clearly labelled shortcut.

Evidence: `lib/screens/receiver/blood_request_form_screen.dart:79`, `:143`.

## Screen-by-screen review

“Present” means implemented in source, not end-to-end verified in this review.

| Screens/area | Present | Recommended changes |
| --- | --- | --- |
| Splash, login, signup, role selection | Session restoration, password reset, account-status checks, donor/receiver modes | Add onboarding and profile completeness. Keep immediate signup access as the existing policy; show verification status and optional email resend without silently introducing approval gates. Test interrupted signup/restoration. |
| Phone OTP | Manual/automatic linking and donor phone change | Expose verified phone change through shared Settings for receivers too; add resend cooldown and expiry feedback. Test platform-specific behavior. |
| Donor dashboard | Availability and matching requests | Separate assignments from opportunities; withdrawal/scheduling; prevent the 100-record window from hiding work. |
| Donor profile | Editing, verified phone change, approximate location updates | Show completeness/location freshness; keep private address separate. CNIC is unverified input; remove it unless there is a defined need and handling policy. |
| Eligibility status | Recorded-donation interval and next date | Explain that this is based on recorded in-app dates. Consider external donation reporting and a reviewed screening/deferral flow; do not label an interval check as full medical clearance. |
| Blood request detail | Live status, accept/decline/confirm, contact and reporting | Assignment progress, meeting details, withdrawal, cancellation updates, completion acknowledgement. |
| Donation history | Records and “Load older donations” | Cursor pagination instead of refetching an increasing limit; date filters and detail links. |
| Rewards/certificates | Server points, tiers, generated PDF links | Older certificates beyond the latest 100 records. QR contains an ID but has no verifier screen/endpoint; keep these acknowledgements or implement trusted issuance/verification if authenticity is required. |
| Receiver dashboard | Requests, cancellation, donor discovery | Dedicated request tracking/detail with accepted donor, timeline, remaining quantity and history filters. |
| Request form | Patient/hospital/contact/date/quantity validation | Hospital pin selection, draft/edit support for open requests, expiry, stronger server field validation; minimize patient details collected. |
| Find Donors/map | Compatibility, radius/distance, calling, notification and route estimate | Consistent filters and actionable errors. Map eligibility toggle cannot broaden results because its service already removes ineligible donors. Preserve assigned-donor access. |
| SOS/SOS detail | Countdown, submission, server matching, directions; admin resolution | Active SOS tracking, donor response, owner resolution, contact, expiry and fulfillment linkage. |
| Notifications | Inbox, read state and push navigation | Older history/filters; route accepted/fulfilled/cancelled “general” messages to the relevant request. Explain unavailable/deleted destinations. |
| Settings | Theme, preferences, password/email change, export/deletion | Shared verified-phone flow; inline recent-login prompt and failed-cleanup recovery. Export omits requests/SOS/reports/CNIC and some profile fields, and caps notifications; clarify its scope or make it complete. |
| Help/About/legal | FAQs, configurable support, feedback, sharing and legal text | Configure support for release; separate ratings from abuse reports (ratings currently enter `misuse_reports`). Add reporter status and receiver-side donor reporting. Align privacy/help claims with code. |
| Admin login/dashboard | Role guard, overview | Use aggregate counts; current dashboard reads complete collections. Replace obsolete pending-approval emphasis with actionable work. |
| Admin users | Details, editing, status changes, deletion | Pagination, action reasons/audit trail, failed-deletion recovery visibility. Current mutation paths do not provide a complete administrative audit trail. |
| Admin requests/SOS | Details, cancellation/deletion, SOS resolution | Reassignment, expiry, timeline, participant notifications; deliberate cleanup/retention of linked records when deleting a request. |
| Admin donations/analytics | Records, totals and breakdowns | Date/area filters, response/fulfillment metrics, unresolved demand. Analytics currently downloads whole collections. |
| Admin reports/broadcasts | Moderation status/notes and targeted announcements | Reporter outcomes, separate feedback, delivery/failure visibility and safe retries. Server send counts are not device-delivery confirmation. |

## Cross-cutting engineering improvements

- **Theme/accessibility:** Find Donors and OTP use fixed light backgrounds and some donor cards use white surfaces. Use theme colors throughout. Test dark mode, large text, narrow layouts, keyboard and screen readers. These are source-visible risks, not measured contrast/overflow failures.
- **Notification reliability:** One `private/device` token is stored per account. Another device replaces it; logout deletes the shared document. Use per-device registrations. SOS/broadcast handlers create random notification IDs without event-level deduplication; make reprocessing safe.
- **Contact authorization:** `getDonorContact` is rate-limited and audited, but requires no request relationship. Decide whether general receiver directory lookup is intended; otherwise restrict disclosure to legitimate requests/assignments with clear donor consent.
- **Abuse controls:** Ordinary requests and reports lack an SOS-style server rate limit. Validate remaining unconstrained fields such as urgency/date/text sizes and add duplicate/spam controls. Client App Check activation exists, but callable declarations do not enforce it; configure and test enforcement deliberately.
- **Offline/account state:** Session initialization signs out on any error, including transient server failure. Provide recoverable access-check feedback. Controllers persist under root providers; test account switching and failed reloads for stale previous-account data. Define supported offline behavior.
- **Regression coverage:** Add rules/workflow tests for privacy, multiple units, assignment withdrawal, expiration, SOS responses and multi-device tokens. Then test complete donor/receiver/admin journeys. CI runs rules tests without Functions and does not run the separate callable HTTP/browser scripts.

## Optional expansion

Chat, appointment calendars, donor reputation, blood drives, full Urdu/localization, hospital accounts and reward redemption are future scope, not prerequisites for fixing the core flow.

The current product coordinates donors and receivers, not physical blood stock. If inventory management is intended, it requires separate scope: components/batches, collection/expiry, screening status, reservations, issue/return and staff permissions.

## Documentation and release checks

Older README/verification notes do not fully describe current code:

- Release builds now require private signing configuration rather than silently using debug signing.
- Verified phone change exists in donor profile; donation history has a load-older action.
- Callable HTTP and browser audit scripts exist, although they were not executed here.
- The saved production dependency audit reports zero findings while older reports list vulnerabilities. Neither is a fresh audit; rerun before release.
- In-app maps use Flutter Map/OpenStreetMap and OSRM, so blanket Google Maps API-key instructions do not describe the implementation.

Still verify staging deployment/indexes, OTP, push/SMS, support email, observability, signed release build and rollback, plus real device/browser journeys. Their external configuration was not established in this review.

## Implementation order

1. Data access separation and security regression tests.
2. Quantity-aware fulfillment, assignment recovery and completion policy.
3. Active SOS/request tracking, consistent discovery and hospital selection.
4. Notification/account/history/export/admin improvements.
5. Visual/accessibility QA, staging/device journeys and corrected documentation.
6. Optional expansion after the core journey is reliable.
