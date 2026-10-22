# Donor/receiver dashboard and awareness campaigns

Implemented 22 October 2026. Production data and deployments were not changed.

## App changes

- `/donor` now opens the donor dashboard, rather than a nested request-feed scaffold.
- Donor home places availability first, followed by active commitments, direct invitations, dismissible awareness campaigns, nearby requests and compact contribution statistics.
- Receiver home uses matching theme-aware surfaces, a primary request action, a separate SOS card and request tracking. It never mounts the donor campaign widget.
- Blood Requests has For You, Invitations, My Responses and Active Donation tabs. Cards show blood group, urgency, hospital, remaining units, deadline, status and approximate distance when available. The existing tracking screen retains confirmation before acceptance and other mutations.
- Discovery distinguishes service failures from empty results; its supported radius choices extend from 5 to 1,000 km. Request details, SOS and nearby-donor failures use sanitized messages.
- Donor search continuation now resumes at the last processed donor even when a result limit is reached mid-page. Existing commitments are excluded from discovery.
- Direct invitations are paged from canonical invitation records, independently of notification deletion. Rules allow the invited donor and requester to read invitations, with writes remaining server-only. Invitation compatibility is evaluated donor-to-recipient.
- SOS fields have consistent spacing. Dark-mode stats use theme surfaces. Embedded loading lists no longer require an unbounded viewport.

## Admin workflow

Open **Awareness Banners → Create banner**. Provide English and Urdu heading, description and button text; optionally upload a JPG/PNG/WebP image under 3 MB or supply an HTTPS URL. Choose Requests, Profile or History as the button destination. Set priority (0–100), start/end date and time, preview either language, and save. The default draft is inactive; enable Active to show it within the schedule.

Only administrators can save campaigns or upload their images. The feed and analytics endpoints require an approved account in active donor mode, including for accounts with both capabilities. The feed returns up to five currently scheduled campaigns, highest priority first. Receiver dashboards do not fetch these campaigns. Admin lists the latest 100 campaigns.

Dismissals persist per account/device and campaign revision. Editing a campaign increments its revision. Views and clicks count each donor once per revision, not every render/tap. A view is attempted after at least half the card is onscreen on the current route. Analytics are best effort and may undercount offline. No third-party ad SDK, tracking SDK or automatic medical-benefit claims were added.

## Root cause of screenshot NOT_FOUND errors

A read-only Firebase CLI check of the configured project, `blood-bank-98037`, returned `status: success, result: []` for deployed Functions. The client and source use the default `us-central1` region. Friendly UI messages do not repair an absent deployment.

`WorkflowService` also accepts `--dart-define=FUNCTIONS_REGION=...` for an intentionally different deployment; emulator setup uses the same instance. The default needs no flag.

## Deployment preparation

Review the existing Firebase setup in README first (billing, secrets, Auth, Storage and operator configuration). Deploy rules and indexes together, then Functions, before distributing the updated app. Run on staging first; these commands are operator instructions, not evidence of a deployment:

```powershell
firebase deploy --project <staging-project> --only firestore:rules,firestore:indexes,storage
firebase deploy --project <staging-project> --only functions
firebase functions:list --project <staging-project>
```

New callable exports: `manageAwarenessBanner`, `donorAwarenessBanners`, `recordBannerEvent`, `donorInvitations`. New indexes cover active donor assignments and the invitations collection group. Do not enable campaign publishing in the app before the rules, indexes and callables are available.

## Verification

Automated checks include Flutter analysis and tests, backend policy/syntax checks, and Firestore/Auth/Storage emulator authorization/workflow tests. Widget tests cover 320-pixel layouts at 1.5× text scale in light/dark English/Urdu, banner actions/dismissal and sanitized technical errors.

Local Chrome walkthroughs use demo accounts and demo Firebase emulators only. Screenshots are written under ignored `audit-artifacts/dashboard/`; the script is `functions/test/dashboard-walkthrough.js`. It accepts `donor`, `receiver` or `admin` as an optional argument and expects a demo web preview at `127.0.0.1:7357`.

Native-device FCM, Agora, OTP, production deployment and signed Android release validation remain separate checks. The debug web-server command encountered a Flutter tooling `loadDwdsDirectory` error; a profile-mode static web preview compiled successfully instead. The demo preview must not be distributed as a production build.
