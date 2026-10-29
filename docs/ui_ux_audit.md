# UI/UX audit — 23 October 2026

## Scope and evidence

Continues the existing uncommitted dashboard work; does not replace it. Reviewed shared theme/widgets and screen implementations for donor, receiver, request hub/tracking, SOS, auth, profile, discovery/maps, notifications, settings and admin. This is a prioritized source audit plus targeted rendered checks, not certification that every screen/state has been exercised.

Reference checklists: [Flutter accessibility](https://docs.flutter.dev/ui/accessibility) and [UI design/styling](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling). Applied large-text, contrast, touch-target, readable hierarchy and assistive-label considerations. No accessibility compliance claim. Historical audits remain historical; this document and `production_readiness_audit.md` describe the current continuation.

## Why the UI still looked unfinished

The problem was conflicting local design systems, not just padding. Auth used almost-black surfaces, glowing gradients, tiny gesture targets and dark hints; dashboards inherited warm red-tinted surfaces; admin used fixed white tables with inherited dark-theme controls. Fixed-height custom buttons ignored text growth. Cards repeated equally strong borders, tints and headings, while wide layouts stretched the same single column. Some error messages exposed technical details and an offline Retry button did nothing. These undermine readability and confidence during urgent tasks.

## Findings and implementation

| ID / severity | Exact location | Evidence and impact | Fix / verification |
| --- | --- | --- | --- |
| UI-01 Medium | `lib/constants/app_theme.dart`, `AppTheme`; `lib/widgets/dashboard_components.dart`, `DashboardPanel` | Theme seed tinted every surface; shared buttons used inconsistent radii/elevation and cards repeated 22px radii. Urgency competed with ordinary content. | Added neutral `AppSurfaces.scheme`, shared 12/16px radii, flat primary/secondary controls, neutral navigation surfaces. Compiles; card tests cover both themes. |
| UI-02 Medium | `lib/screens/auth/login_screen.dart`, `build`, `_buildField`, `_buildLoginButton` | Hardcoded dark scaffold, glow blobs, low-contrast hints, fixed-height gradient button, text-only gesture actions and unbounded desktop form. | Rebuilt presentation around existing sign-in/approval/reset/signup behavior: 480px max width, theme-aware fields, persistent field labels, real icon/text buttons, localized primary text, scroll/keyboard handling. Login remains real Firebase auth. |
| UI-03 Medium | `lib/widgets/custom_button.dart`, `build` | Fixed heights 40/50/58 and an unwrapped Row label could overflow with long text; secondary button always white. | Minimum 48px height, flexible wrapped label, growing container, theme-aware secondary surfaces. New 320px/200% text test exercises all four variants and actual tap. |
| UI-04 Medium | `lib/screens/auth/signup_screen.dart`, `build`, `_buildField`, `_buildSignUpButton` | Very dark hint/icon colors, unrestricted desktop width, 54px fixed submit height. | Improved contrast, bounded horizontal form width, minimum growing submit height and suffix constraints. Partial: screen retains legacy dark decorative styling, English labels and gesture-based toggles; full theme/RTL migration remains. |
| UI-05 Medium | `lib/screens/admin/web/admin_web_dashboard.dart`, `build`; `admin_web_review_screens.dart`, review dialogs; `admin_awareness_banners.dart`, `_edit` and editor `build` | White console workspace inherited dark mobile field/dialog styling; long review note dialogs were not scrollable; pushed banner editor lost scoped theme and stretched full desktop width. | Explicit light console theme boundary, captured theme on editor route, 900px editor reading width; scrollable review dialogs and sanitized load errors. Full admin dark mode is not implemented. |
| UI-06 Medium | donor/receiver `build`; `dashboard_components.dart`, `dashboardInsets` | Wide dashboards stretched cards edge-to-edge, weakening scan hierarchy. | Shared centered 720px reading column with 16px narrow-screen gutters. Active donation/invitations and nearby previews remain before banners. |
| UI-07 Medium | `lib/utils/eligibility_checker.dart`, `daysUntilEligible`, `getEligibilityMessage` | `inHours` truncated the final sub-hour to zero; fallback claimed eligibility before interval completion. | Millisecond-based ceiling and qualified interval wording. Regression checks last 30 minutes. Server 90-day boundary retained. |
| UI-08 Medium | `lib/widgets/premium_states.dart`, `OfflineBanner` | Retry had `onPressed: () {}`; misleading affordance. | Informational accessible live-region banner replaces fake action; per-screen real retries remain. |
| UI-09 Medium | `notification_history_screen.dart`, notification catch; `blood_requests_map_screen.dart`, `_load`; admin review `_load` | Raw exceptions were user-visible. | Sanitized messages while preserving retry/notification navigation. Other legacy profile/admin raw-error cases remain. |
| UI-10 Low | `dashboard_components.dart`, `OpportunityCard` | Blood groups can reorder inside RTL text. | Explicit LTR direction for blood group badge; English/Urdu cards pass at 200% text. |
| UI-11 Medium, remaining | `donor_profile_screen.dart`, profile header; `role_selection_screen.dart`, role cards; `splash_screen.dart`, build | Legacy gradients/large hero treatments and separate typography still differ from new system. | Migrate incrementally; do not remove profile editing, role switching or splash routing. Shared controls already benefit from current theme fixes. |
| UI-12 Medium, remaining | `admin_web_requests.dart`, `AdminEmergencyRequests`; `admin_web_users.dart`, tables | Legacy tables/streams differ from paged newer review screens; full narrow/large-text table behavior not exercised. | Use existing paged-record/query patterns, visible search scope and responsive action menus; retain all records through continuation. |
| UI-13 Medium, remaining | `signup_screen.dart`, `eligibility_status_screen.dart`, admin section labels | Several labels remain English even with Urdu locale; whole-screen RTL has not been certified. | Move remaining strings to localization catalog, verify TalkBack and 200% text on devices. |

## Visual system

Neutral white/charcoal surfaces; dark-red primary action, restrained red blood/urgent cues, explicit text statuses rather than color alone. Keep existing spacing scale (4/8/12/16/20/24/32), 12px control and 16px panel corners, 48px minimum shared touch targets, mostly zero elevation, bounded reading width. Retain Material semantics and system text scaling. No new dependency, architecture, identifier or map provider was introduced.

## Validation and limits

52 Flutter tests passed, including request/banner cards in English/Urdu, light/dark, 320px width and 200% text, shared long-label buttons, and eligibility boundary. Analysis and profile web build passed. Browser results and backend checks are recorded in `production_readiness_audit.md`. Screenshots in ignored `audit-artifacts/dashboard/` are local demo artifacts, not production evidence. No physical-device/TalkBack/keyboard-browser audit or full-screen contrast certification was performed.

Manual acceptance sequence is in `remaining_work.md`; earlier detailed dashboard steps remain in `verification-2026-10-23.md`.

## Privacy continuation boundary

The next pass preserved the visual system and routed donor dashboard/activity/legacy responses/chat/tracking through safe server projections. Active and My Responses tabs now use the paged callable; their empty-state copy is bilingual. Owner/admin request streams remain authorized. Shared Functions configuration now also covers legacy donor/admin/settings/voice actions. This is a workflow/privacy correction, not a claim that all remaining legacy screens or Urdu labels were redesigned.

The complete 52-test Flutter suite and analysis passed after these edits. Physical Android, full-screen Urdu/TalkBack and native-provider checks remain deferred. UI-11/12/13 remain genuine backlog items; App Check and development advisories are tracked in the production audit. Updated security/deployment evidence is in `production_readiness_audit.md` and `firebase-staging-deployment.md`.
