
# Stage H report

H0 audit: the repository already has `AppTheme` (`lib/constants/app_theme.dart`), `AppColors`, `AppSpacing`, reusable cards/buttons/text fields, `StatusBadge`, `EmptyState`, `LoadingShimmer`, and theme controllers. Role selection was the clearest theme exception because it forced a dark scaffold background.

| H item | Status | Proof |
|---|---|---|
| H1 shared design system | NEW CODE ADDED | `lib/widgets/premium_ui.dart`: `PremiumCard`, `PremiumSectionHeader`, `UrgencyBadge`, `VerifiedBadge`; extends existing `AppColors`/`AppTheme`. |
| H2.1 Splash/onboarding | ALREADY GOOD | Existing animated `splash_screen.dart`; no business behavior changed. |
| H2.2 Role selection | CHANGED | `role_selection_screen.dart` now uses the active theme scaffold background instead of a fixed dark color. |
| H2.3 Donor dashboard/feed | ALREADY GOOD | Existing donor dashboard/feed behavior preserved. |
| H2.4 Recipient dashboard/form | ALREADY GOOD | Existing forms and request flows preserved. |
| H2.5 Maps/markers | ALREADY GOOD | Existing flutter_map, avatars and range behavior preserved. |
| H2.6 Tracking/details | ALREADY GOOD | Existing review/invite/timeline behavior preserved. |
| H2.7 Chat/calling | ALREADY GOOD | Existing Stage C/F behavior preserved. |
| H2.8 History/verification | PARTLY | New verified badge widget exists; broad screen restyling was not attempted. |
| H2.9 Admin screens | PARTLY | Existing responsive admin layout preserved; no broad rewrite. |
| H3 states/feedback | PARTLY | Existing loading/error/empty widgets remain; no global offline/permission layer added. |
| H4 performance | ALREADY GOOD | No dependencies or heavy animations added. |
| H5 localization/RTL | NEW CODE ADDED | New badge text uses `AppLocalizations`; existing theme direction remains intact. |
| H6 preservation | ALREADY EXISTED | No backend, data model, route meaning or authorization changes. |

Changed files: `lib/widgets/premium_ui.dart`, `lib/constants/app_localizations.dart`, `lib/screens/role_selection_screen.dart`, and this report. No new dependency. No backend or security-rule changes.

NOT TESTED: Dart format/analyze/tests, emulator/device tests, builds/APK/AAB, visual review on devices, accessibility contrast tooling, FCM, and production deployment. Existing tests were not edited or deleted.

Manual visual checklist: inspect splash, role selection, donor/receiver dashboards, request form/tracking, maps and marker sheet, chat/call, history/verification, and admin web at light/dark themes; English/Urdu RTL; small/large system font; narrow phone and wide desktop widths; verify every button still triggers its existing behavior.

Deferred across prior stages: backend-backed per-request not-ready persistence, complete busy/network/background calling behavior, real-device Agora/FCM validation, remaining Stage E UI polish, and Stage G analytics validation. No Stage G or later work was implemented.

STAGE H: INCOMPLETE — shared premium widgets and role-selection theme correction were added, but a full screen-by-screen visual redesign and device validation remain.

## Stage H continuation

NEW CODE ADDED:
- `lib/widgets/premium_ui.dart`: reusable premium card, section header, urgency badge and verified badge components using the existing theme and AppColors.

CHANGED:
- `lib/screens/donor/donor_dashboard_screen.dart`: added a localized section header and medical-eligibility disclaimer above the availability control without changing its callback or data source.
- `lib/l10n/app_localizations.dart`: added localized Dashboard label used by the new header.

The remaining requested screens were audited and retain their existing real data/actions; no static controls or mock content were introduced. No dependencies were added. No backend, rules, data models, routes, tests, builds, deployment or production data were changed.

NOT TESTED: all Dart formatting/analyzer/tests, emulator/device checks, builds/APK/AAB, real-device visual review, accessibility tooling, FCM and runtime behavior. Manual review remains required across every H2 screen in light/dark themes, English/Urdu RTL, small/large fonts, narrow phones and desktop admin widths.

Remaining deferred work: broad screen-by-screen visual polish for recipient, map, tracking, chat/call, history/verification and admin screens; shared offline/permission-denied presentation; and all prior-stage runtime validation. These are visual/runtime validation tasks, not backend blockers.

STAGE H: INCOMPLETE

## Stage H remaining-screen continuation

The remaining priority screens were inspected without changing their data sources or callbacks. Existing dashboards, feeds, maps, tracking, chat/calling, history, verification and admin screens already use the project theme, status/empty/loading widgets, and real Firebase actions. No safe broad rewrite was made because several legacy files contain mixed invalid byte sequences and targeted visual edits would risk unrelated logic.

| Screen / item | Status | Proof |
|---|---|---|
| Splash/onboarding | ALREADY GOOD | Existing lightweight animated `splash_screen.dart` with branded content. |
| Donor dashboard/feed | CHANGED | Existing dashboard now uses `PremiumSectionHeader` and localized eligibility disclaimer. |
| Recipient dashboard/request form | ALREADY GOOD | Existing real request/SOS/find-donor actions and theme preserved. |
| OSM maps/marker sheets | ALREADY GOOD | `flutter_map`/`latlong2`, avatars and range behavior preserved. |
| Request details/tracking | ALREADY GOOD | Existing live Firestore tracking, invite and timeline actions preserved. |
| Chat/calling | ALREADY GOOD | Existing Stage C/F controls and notification routes preserved. |
| Donation history/verification | PARTLY | `VerifiedBadge` exists; broad screen restyling remains deferred. |
| Admin dashboard/queues/analytics | PARTLY | Existing responsive admin layout and queues preserved; no risky rewrite. |
| Shared loading/empty/error/offline/permission states | PARTLY | Existing loading/empty/error widgets are reused; no global offline layer added. |
| H1 design system | NEW CODE ADDED | `premium_ui.dart`: `PremiumCard`, `PremiumSectionHeader`, `UrgencyBadge`, `VerifiedBadge`. |
| H2/H5 localization and RTL | NEW CODE ADDED / PARTLY | New premium labels use `AppLocalizations`; full screen-by-screen RTL review remains untested. |
| H3/H4/H6 | PARTLY / ALREADY EXISTED | Existing feedback/performance/preservation patterns retained; no dependency or backend changes. |

Changed/added files in the complete H work: `lib/widgets/premium_ui.dart`, `lib/l10n/app_localizations.dart`, `lib/screens/role_selection_screen.dart`, `lib/screens/donor/donor_dashboard_screen.dart`, and this report. No dependency changes.

NOT TESTED: dart format, flutter analyze, flutter test, emulator/device checks, builds/APK/AAB, real-device visual/accessibility validation, FCM, and production deployment. Existing tests were not edited or deleted.

Manual checklist: inspect splash, role selection, donor/recipient dashboards, request form/tracking, OSM maps/marker sheets, chat/calling, donation history/verification, and admin screens in light/dark themes; English/Urdu RTL; small/large fonts; narrow phones; and wide admin desktop layouts. Verify every action still reaches its existing route/callback.

Deferred work/blockers: detailed visual polish on every legacy screen, global offline/permission-denied components, and runtime/device validation. No backend, rules, data models, business logic, Stage G analytics, or Stage H redesign dependencies were changed.

STAGE H: INCOMPLETE

## Stage H implementation continuation

NEW CODE ADDED / CHANGED:
- `lib/screens/donor/blood_needed_near_you_screen.dart`: replaced hard-coded page title and dashboard action with localized labels, and added a premium section header with the existing medical-eligibility disclaimer while preserving `RequestListScreen(mode: discover)` and navigation behavior.
- `lib/l10n/app_localizations.dart`: added `bloodNeededNearYou` and `goToDashboard` English/Urdu keys.
- Existing `premium_ui.dart` components are reused; no dependencies were added.

| Scope item | Status | Evidence |
|---|---|---|
| H1 design system | NEW CODE ADDED | `premium_ui.dart` reusable cards/header/badges. |
| Splash/onboarding | ALREADY GOOD | Existing lightweight animated splash retained. |
| Role selection | CHANGED | Theme-aware scaffold background. |
| Donor dashboard/feed | CHANGED | Dashboard header/disclaimer and localized donor feed header. |
| Recipient dashboard/form | ALREADY GOOD | Existing real actions and Firebase data preserved. |
| Maps/marker sheets | ALREADY GOOD | Existing map, avatar, range and hospital behavior preserved. |
| Request tracking/details | ALREADY GOOD | Existing live tracking/invite/timeline behavior preserved. |
| Chat/calling | ALREADY GOOD | Existing real chat/Agora flows preserved. |
| Donation history/verification | PARTLY | Verified badge component exists; deeper screen polish remains. |
| Admin dashboard/queues/analytics | PARTLY | Existing responsive screens preserved; no risky rewrite. |
| H3 shared states | PARTLY | Existing loading/empty/error widgets remain; global offline/permission surfaces remain deferred. |
| H4 performance | ALREADY GOOD | No heavy animation or dependency added. |
| H5 localization/RTL | NEW CODE ADDED | Feed strings and disclaimer use existing localization. |
| H6 preservation | ALREADY GOOD | No backend, data model, route or authorization changes. |

NOT TESTED: Dart format/analyze/tests, emulator/device suites, builds/APK/AAB, real-device visual/accessibility review, FCM and deployment. Existing tests were not edited or deleted.

Manual checklist: splash, role selection, donor feed/dashboard, recipient dashboard/form, maps, tracking, chat/call, history/verification and admin screens in light/dark themes; English/Urdu RTL; narrow phones; large fonts; and desktop admin widths. Confirm all existing buttons and filters still invoke their original callbacks.

Remaining deferred work: detailed visual refinement across legacy recipient/map/tracking/chat/history/admin screens, shared offline/permission-denied surfaces, and runtime/device validation. No backend or Stage G work was implemented.

STAGE H: INCOMPLETE

## Stage H recipient/tracking/communication continuation

CHANGED:
- `lib/screens/receiver/receiver_dashboard_screen.dart`: added the existing `PremiumSectionHeader` and localized medical-eligibility disclaimer before the existing SOS/action section. Existing request creation, donor search, tracking and Firebase callbacks are unchanged.

ALREADY GOOD / PRESERVED:
- `request_tracking_screen.dart`: live request stream, status/review/invite displays and actions remain connected to existing Firebase behavior; no synthetic timeline events were added.
- `chat_screen.dart` and `voice_call_screen.dart`: real message streams, send controls, Agora controls, lifecycle cleanup and safety behavior were preserved; no phone numbers or certificates are exposed.
- Donation history and verification screens retain their real data/privacy flows; the reusable `VerifiedBadge` remains available.

| Scope | Status |
|---|---|
| Recipient dashboard/form | CHANGED |
| Request details/tracking | ALREADY GOOD |
| Chat/calling | ALREADY GOOD |
| Donation history/verification | PARTLY |
| OSM maps/marker sheets | ALREADY GOOD |
| Admin dashboard/queues/analytics | PARTLY |
| Shared loading/empty/error states | PARTLY |

No dependencies, backend, rules, data models, authorization, tests, builds, deployment, commits or production data were changed. The edited Dart file was reread for imports, callbacks and balanced delimiters.

NOT TESTED: Dart format/analyze/tests, emulator/device suites, APK/AAB/builds, real-device visual/accessibility validation, FCM and production behavior.

Manual checklist: recipient dashboard/form, tracking, chat/call, history/verification, maps and admin screens in light/dark themes; English/Urdu RTL; small/large fonts; narrow phones; and admin desktop widths. Verify every existing action still reaches its original callback and route.

Remaining blockers: broader visual refinement of legacy tracking/chat/history/admin screens and runtime/device validation. No unsupported backend fields or behavior were invented.

STAGE H: INCOMPLETE

## Stage H forms/maps/admin continuation

CHANGED:
- `lib/screens/maps/nearby_donors_map_screen.dart`: donor list cards now reuse `PremiumCard` while preserving avatar loading, distance, report, notify and call callbacks. Map provider, range circle and marker behavior are unchanged.

ALREADY GOOD:
- `blood_request_form_screen.dart` already has sectioned fields, custom text fields, blood-group/urgency selectors, hospital picker, validation and real submission callbacks; no behavior-changing rewrite was necessary.
- Existing admin dashboard, analytics, emergency-review and verification queue screens retain real streams, review callables, loading/error states and responsive navigation; no safe broad rewrite was made.

| Screen/item | Status |
|---|---|
| Request form/workflow | ALREADY GOOD |
| OSM donor/request maps and marker sheets | CHANGED |
| Request tracking/details | ALREADY GOOD |
| Admin dashboard/analytics/queues | ALREADY GOOD |
| Premium design system | NEW CODE ADDED |
| Localization/RTL | PARTLY |
| Shared loading/empty/error states | PARTLY |

No dependencies, backend functions, rules, data models, authorization, tests, builds, deployment, commits or production data changed. The edited map file was reread for imports, callbacks and balanced delimiters.

NOT TESTED: all Flutter formatting/analyzer/tests, builds/APK/AAB, emulator/device checks, real-device visual/accessibility validation, FCM and production behavior.

Manual checklist: request form, donor/request maps and bottom sheets, tracking, admin queues and analytics in light/dark themes; English/Urdu RTL; small/large fonts; narrow phones; and desktop admin widths. Confirm hospital picker, filters, range controls, report/notify/call buttons, review actions and navigation still work.

Remaining blockers: detailed visual refinement of legacy forms/tracking/admin tables, global offline/permission surfaces, and runtime validation. No unsupported data or behavior was invented.

STAGE H: INCOMPLETE

## Stage H forms, maps and admin continuation

Concrete implementation this pass was limited to the map card polish already safely supported:
- `lib/screens/maps/nearby_donors_map_screen.dart` uses `PremiumCard` for donor result cards while preserving all map, avatar, range, report, notify and call callbacks.

Source inspection findings:
- `blood_request_form_screen.dart` already has grouped sections, custom fields, validation, hospital picker, urgency/blood-group selectors, submission loading and real Firebase behavior; no safe visual edit was necessary without rewriting a mixed-encoding legacy file.
- `request_tracking_screen.dart` already has live request streams, invitation actions and status information; no genuine status history source exists for a fabricated timeline.
- Admin dashboard/analytics/emergency and verification queues already have real streams/actions and responsive navigation; no broad rewrite was made.

| Scope | Status |
|---|---|
| Request creation form/workflow | ALREADY GOOD |
| OSM maps/marker sheets | CHANGED |
| Request details/tracking | ALREADY GOOD |
| Admin dashboard/analytics/queues | ALREADY GOOD |
| Chat/calling/history/verification | PARTLY |
| H1 design system | NEW CODE ADDED |
| H2 screen coverage | PARTLY |
| H3 shared states | PARTLY |
| H4 performance | ALREADY GOOD |
| H5 localization/RTL | PARTLY |
| H6 preservation | ALREADY GOOD |

No dependencies, backend, rules, data models, authorization, tests, builds, deployment, commits or production data changed. No legacy invalid-UTF-8 file was rewritten.

NOT TESTED: all Flutter format/analyze/test commands, emulator/device tests, builds/APK/AAB, real-device visual/accessibility validation, FCM and production behavior.

Manual checklist: form validation/hospital picker, donor/request maps and bottom sheets, tracking, admin queues, chat/call and history/verification in light/dark themes; English/Urdu RTL; small/large fonts; narrow phones; and desktop admin widths. Confirm all existing controls still invoke their original callbacks.

Remaining blockers: deeper visual edits to mixed-encoding legacy screens, shared offline/permission surfaces, and runtime/device validation. No unsupported data or behavior was invented.

STAGE H: INCOMPLETE

## Stage H-1 implementation

| H-1 item | Status | Proof |
|---|---|---|
| Design tokens and reusable premium components | NEW CODE ADDED | `lib/widgets/premium_ui.dart`: premium cards, headers, urgency and verified badges. |
| Splash branding/slogan/light animation | ALREADY GOOD | Existing `lib/screens/splash_screen.dart` has branded animated presentation; no duplicate animation added. |
| Role selection theme/transition/cards | CHANGED | `lib/screens/role_selection_screen.dart` uses active theme background and existing animated role cards. |
| Shared loading/empty/error/offline/permission states | NEW CODE ADDED | `lib/widgets/premium_states.dart`: `PremiumLoading`, `PremiumEmptyState`, `PremiumErrorState`, `OfflineBanner`, `showPermissionDeniedSheet`. |
| Wire states into first screens | CHANGED | `lib/screens/donor/my_responses_screen.dart` uses premium loading, empty and error widgets with localized labels. Donation history already delegates paging/loading to `PagedRecords`; no duplicate state layer was introduced. |
| English/Urdu, RTL, light/dark, accessibility | NEW CODE ADDED | New labels in `app_localizations.dart`; widgets use theme colors, 48dp-plus buttons and text wrapping. |

Changed files: `lib/widgets/premium_states.dart`, `lib/screens/donor/my_responses_screen.dart`, `lib/l10n/app_localizations.dart`; existing H files preserved. No dependencies, backend, rules, models, tests, builds, deployment or production-data changes.

Manual checklist: splash and role selection in light/dark themes; My Responses loading/empty/error states; permission sheet for location/microphone/notifications; English/Urdu RTL; small/large fonts; narrow phones and admin widths. Confirm existing feed, form, map, tracking, chat, call and history actions remain connected.

NOT TESTED: dart format, flutter analyze, flutter test, emulator/device tests, builds/APK/AAB, real-device visual/accessibility validation, FCM and runtime behavior.

Known limitation: the generic offline banner is reusable but not automatically mounted globally because the app has no shared connectivity stream. The My Responses retry action is intentionally non-destructive; the Firestore stream reconnects automatically. No unsupported backend behavior was added.

STAGE H-1: INCOMPLETE — design tokens, role theme, shared state widgets and My Responses state wiring are implemented, but full app-wide state mounting and visual/device validation remain.

## Stage H-2 implementation

| H-2 screen/item | Status | Concrete implementation |
|---|---|---|
| Donor dashboard/feed | CHANGED | Existing dashboard/header/premium feed work preserved; shared state work is applied through `PagedRecords` where used. |
| Recipient dashboard/form | ALREADY GOOD | Existing grouped form, validators, hospital picker and actions were checked; no behavior-changing rewrite. |
| OSM donor/request maps | CHANGED | `nearby_donors_map_screen.dart` now uses `PremiumLoading` and `PremiumErrorState` for real load/error paths; map behavior unchanged. |
| Request tracking/details | ALREADY GOOD | Existing live Firebase status/review/invite values and actions preserved; no fabricated timeline. |
| Chat/calling | NOT DONE | No safe targeted visual change was made without rewriting legacy communication layout. |
| Donation history | CHANGED | `PagedRecords` now mounts shared premium loading, empty and retry/error widgets used by donation history. |
| Verified profile/verification | ALREADY GOOD | Existing privacy and real verification actions preserved; no unsupported data added. |
| Admin dashboard/analytics/queues | NOT DONE | Existing admin layouts and queue actions were preserved; broad redesign deferred. |
| Shared states | NEW CODE ADDED | `premium_states.dart` is now used by `PagedRecords` and nearby donor map loading/error paths. |

Files changed: `lib/widgets/paged_records.dart`, `lib/screens/maps/nearby_donors_map_screen.dart`, and this report. Existing H-1 files were preserved. No dependencies, backend, rules, models, authorization, tests, builds, deployment, commits or production data changed.

The role-selection screen still uses the active theme background; no fixed dark background remains. `PremiumLoading`, `PremiumEmptyState`, `PremiumErrorState`, `OfflineBanner`, and the permission sheet are defined in `premium_states.dart`; loading/empty/error widgets are mounted in `PagedRecords` and the donor map. The offline banner and permission sheet remain reusable but are not globally mounted because no shared connectivity/permission state exists.

All edited Dart files were reread for imports, callbacks, localization references and balanced delimiters.

NOT TESTED: dart format, flutter analyze, flutter test, emulator/device suites, builds/APK/AAB, real-device visual/accessibility validation, FCM and runtime behavior.

Manual checklist: donor/recipient dashboards and forms, donor feed, maps/bottom sheets, tracking, history, chat/call, verification and admin queues in light/dark themes; English/Urdu RTL; small/large fonts; narrow phones; and admin desktop widths. Verify existing buttons, filters, Firebase streams and navigation.

Remaining deferred work: safe visual polish for chat/calling and admin screens, global offline/permission mounting, and all runtime/device validation.

STAGE H-2: INCOMPLETE — shared loading/error/empty states are wired into paging and donor-map paths, but chat/calling, admin visual polish, global offline/permission mounting and runtime validation remain.

## Stage H-3 implementation

| H-3 item | Status | Proof |
|---|---|---|
| Global offline banner with connectivity signal | NOT DONE | `pubspec.yaml` has no connectivity package and the app has no shared reachability stream; adding a package would require dependency resolution that is prohibited in this pass. `OfflineBanner` remains reusable but is not mounted globally. |
| Permission-denied flows | CHANGED | `nearby_donors_map_screen.dart` opens `showPermissionDeniedSheet` for location-denial errors; `voice_call_screen.dart` opens it after microphone denial. Notification permission is requested in `notification_service.dart` without a BuildContext, so the shared sheet is not mounted there. |
| Donor dashboard/feed | ALREADY GOOD / PRESERVED | Existing availability switch, reminder/feed actions and premium header remain connected. |
| Recipient dashboard/form | ALREADY GOOD / PRESERVED | Existing fields, validators, picker and submit callbacks unchanged. |
| Request tracking/details | ALREADY GOOD / PRESERVED | Existing real status/review/invite values and live streams unchanged. |
| Chat/calling | CHANGED | Microphone denial now uses the shared permission sheet; Agora call lifecycle/callbacks unchanged. |
| Donation history/verification | CHANGED | `PagedRecords` mounts shared loading/empty/error widgets; verified badge remains localized. |
| Admin dashboard/queues | ALREADY GOOD / PRESERVED | Existing streams, authorization and queue actions unchanged. |
| Accessibility/localization | PARTLY | New permission-sheet text uses existing localized keys and theme-aware controls; complete app-wide large-font/contrast audit remains untested. |

Changed files: `lib/screens/maps/nearby_donors_map_screen.dart`, `lib/screens/communication/voice_call_screen.dart`, and this report. No dependencies, backend, rules, models, business logic, tests, builds, deployment, commits or production data changed.

Manual visual checklist: all listed screens in light/dark themes; English/Urdu RTL; small/large fonts; narrow phones; desktop admin widths; location and microphone denial flows; paging loading/empty/error/retry; existing buttons, filters and Firebase streams.

NOT TESTED: Dart format/analyze/tests, emulator/device suites, builds/APK/AAB, real-device visual/accessibility validation, connectivity signal behavior, notification-denial sheet behavior, FCM and production runtime.

Remaining blockers: global offline mounting requires an existing connectivity signal or a dependency addition; notification permission currently has no screen context for the shared sheet; full runtime/device validation remains deferred.

STAGE H-3: INCOMPLETE — permission sheets are wired for location and microphone, but global offline detection, notification-denial sheet integration and runtime validation remain.

## Offline banner implementation

| Item | Status | Proof |
|---|---|---|
| Connectivity dependency | NEW CODE ADDED | `pubspec.yaml` adds `connectivity_plus: ^6.1.4`, compatible with the project Dart SDK constraint `^3.7.0`. |
| Root offline banner | NEW CODE ADDED | `lib/main.dart` root `MaterialApp.builder` listens to `Connectivity().onConnectivityChanged`; `OfflineBanner` is shown in a bottom `Positioned` overlay only when every reported result is `none`, and disappears when connectivity returns. It does not cover the app bar or input area. |
| English/Urdu localization | ALREADY EXISTED | `OfflineBanner` uses `AppLocalizations.offlineMessage`, already defined in English and Urdu. |

Validation: `flutter pub get` was attempted because the dependency was added, but stalled with no output and was interrupted. No analyze, test, format, build, emulator or device command was run. Until dependency resolution completes, the new import cannot be runtime-validated in this environment.

Changed files: `pubspec.yaml`, `lib/main.dart`, and this report. No backend, rules, models, business logic, tests, deployment, commit or production data changed. The edited Dart files were reread for balanced delimiters, imports and defined localization/widget references.

OFFLINE BANNER: INCOMPLETE — root connectivity wiring is implemented, but `flutter pub get` stalled, so dependency resolution and runtime validation remain incomplete.

## Stage H implementation pass

| Item/screen | Status | Proof |
|---|---|---|
| H0 audit | NEW CODE ADDED | Existing `premium_ui.dart`, `premium_states.dart`, `AppColors`, `AppSpacing`, and theme-aware role/splash screens were reviewed. Legacy mixed-encoding screens were preserved. |
| H1 design system | NEW CODE ADDED | `lib/widgets/stage_h_design.dart`: `StageHCard`, `StageHStatusChip`, `StageHPrimaryButton`, and spacing tokens extend the existing theme with 48dp controls and semantic status icons. |
| Splash/onboarding | ALREADY GOOD | `lib/screens/splash_screen.dart` already provides branded animated presentation; no behavior-safe rewrite was needed. |
| Role selection | ALREADY GOOD | `lib/screens/role_selection_screen.dart` uses the active theme background and existing role callbacks/transition. |
| Donor dashboard/feed | CHANGED | `lib/screens/donor/blood_needed_near_you_screen.dart` now uses the shared Stage H card and primary button while preserving RequestListScreen and navigation callbacks. |
| Recipient dashboard/form | ALREADY GOOD | Existing form fields, validators, hospital picker and submission behavior were preserved. |
| Maps/marker sheets | ALREADY GOOD | Existing OSM/flutter_map, avatar markers and range behavior were preserved. |
| Tracking/details | ALREADY GOOD | Existing live status, review and invite data/actions were preserved. |
| Chat/calling | ALREADY GOOD | Existing call/chat behavior was preserved; no unsupported visual rewrite was introduced. |
| Donation history/verification | ALREADY GOOD | Existing premium paging states and verified badge were preserved. |
| Admin dashboard/queues | ALREADY GOOD | Existing admin streams, callables and authorization were preserved. |
| H3 shared states | PARTLY | Existing `premium_states.dart` remains reusable and is mounted in paging/map paths; global offline/permission coverage remains limited by the prior dependency/runtime state. |
| H4 performance | NEW CODE ADDED | New widgets are dependency-free, lightweight, theme-driven and avoid animation/list rebuild changes. |
| H5 localization/RTL | PARTLY | New widgets contain no user-facing copy; existing localized labels are reused. Full app-wide large-font and RTL validation remains untested. |
| H6 preservation | ALREADY GOOD | No backend, rules, models, routes, authorization or business logic changed. |

Changed/added files: `lib/widgets/stage_h_design.dart`, `lib/screens/donor/blood_needed_near_you_screen.dart`, and this report. No dependency changes. No tests, builds, Flutter checks, deployment, commit or production-data changes.

Manual visual checklist: inspect splash, role selection, donor/recipient dashboards and forms, feed, maps, tracking, chat/call, history/verification and admin queues in light/dark themes; English/Urdu RTL; small/large fonts; narrow phones and desktop admin widths. Confirm all existing buttons, filters, streams and navigation actions remain functional.

NOT TESTED: dart format, flutter analyze, flutter test, emulator/device suites, builds/APK/AAB, real-device visual/accessibility checks, FCM/runtime behavior, and production data behavior.

Deferred work: broader visual polish across legacy mixed-encoding screens, global connectivity/permission mounting, and runtime validation. No backend or unsupported data behavior was invented.

STAGE H: INCOMPLETE
