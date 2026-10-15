# Blood Connect UI and feature acceptance checklist

Status reflects repository evidence only. A visual criterion is `NOT VERIFIED`
until the app is launched on a device or emulator and inspected with screenshots.

| Area | Status | Evidence / remaining work |
|---|---|---|
| Splash | NOT VERIFIED | Existing animated implementation is present; no runtime screenshot captured. |
| Role selection | NOT VERIFIED | Existing role routing and account guard are present; visual runtime verification is pending. |
| Login | NOT VERIFIED | Existing validation and Firebase sign-in are present; runtime layout verification is pending. |
| Signup | NOT VERIFIED | Existing donor/receiver registration and validation are present; full localization is incomplete. |
| Donor dashboard | NOT VERIFIED | Premium hero/app-bar treatment updated; device layout and navigation still need runtime verification. |
| Receiver dashboard | NOT VERIFIED | Premium hero treatment updated; device layout and navigation still need runtime verification. |
| Donor profile | NOT VERIFIED | Theme-aware app bar and existing profile workflow preserved; runtime verification pending. |
| Receiver profile | NOT VERIFIED | Existing receiver profile coverage requires a dedicated visual pass. |
| Settings/support/legal | NOT VERIFIED | Theme-aware surfaces updated; runtime verification and full localization pending. |
| Blood Requests feed | NOT VERIFIED | Real backend feed, urgency/radius filters, and tracking navigation are implemented; no screenshot captured. |
| Request details/tracking | NOT VERIFIED | Existing participant authorization and assignment actions are present; visual/device verification pending. |
| History screens | NOT VERIFIED | Existing request, donation, and SOS history screens require runtime verification. |
| Donor/receiver maps | NOT VERIFIED | OpenStreetMap/flutter_map screens and attribution are implemented; device map verification pending. |
| Hospital/location picker | NOT VERIFIED | OSM search, tap/drag selection, current location, reverse geocoding, and cancel/confirm are implemented; provider/device verification pending. |
| Admin screens | NOT VERIFIED | Existing admin authorization and data workflows are preserved; no runtime screenshot captured. |
| English localization | PARTIALLY COMPLETED | Locale persistence exists and shared loading/error/access widgets plus chat now use resources; many screens still contain hardcoded English strings. |
| Urdu localization and RTL | PARTIALLY COMPLETED | English/Urdu resources and Flutter RTL delegates are wired; automated resource and RTL-direction tests pass, but complete translated copy and screen validation remain. |
| Location privacy | PASS in code | Donor discovery returns privacy-rounded coordinates and backend participant checks protect private request details. Runtime authorization tests remain pending. |
| Chat | PARTIALLY COMPLETED | Accepted request pairs now get participant-scoped conversation records, Firestore message rules, and a real-time chat screen; emulator authorization and live multi-user delivery are not yet verified. |
| Voice calling | BLOCKED | No calling SDK/provider account, token service, signaling, or call lifecycle exists in the repository. Provider selection and credentials are required before genuine calling can be implemented and tested. |
| Donation confirmation/points | PASS in code | Backend requires donor readiness and receiver/admin confirmation, uses stable donation IDs, and awards points transactionally once. |

## Hardcoded-string audit

The remaining user-facing literals are concentrated in these files and require a larger screen-by-screen localization pass: `lib/screens/settings/settings_screen.dart`, `lib/screens/requests/request_tracking_screen.dart`, `lib/screens/receiver/blood_request_form_screen.dart`, `lib/screens/receiver/sos_emergency_screen.dart`, `lib/screens/maps/nearby_donors_map_screen.dart`, `lib/screens/maps/hospital_location_screen.dart`, `lib/screens/auth/otp_verification_screen.dart`, `lib/screens/admin/web/admin_web_users.dart`, `lib/screens/admin/web/admin_web_requests.dart`, `lib/screens/admin/web/admin_web_donations.dart`, `lib/screens/admin/web/admin_web_notifications.dart`, `lib/screens/settings/about_screen.dart`, `lib/screens/settings/help_support_screen.dart`, `lib/screens/donor/rewards_screen.dart`, and shared widgets including `change_password_form.dart` and `report_misuse_button.dart`. Technical identifiers, dynamic backend error text, and legal document content require separate review before translation.
