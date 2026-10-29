# Complete QA and security audit

Date: 24 October 2026. Scope: existing local working tree, synthetic Firebase emulator fixtures and local builds. No production or live Firebase resource was changed.

## Reported live-rules state (owner supplied)

The owner reports that Firestore and Storage rules have already been deployed. This audit did not redeploy or alter them. The repository alias `q` targets `blood-bank-98037` (`.firebaserc`), but no read-only release metadata or signed deployment record was available in the workspace, so the live project identity, deployed ruleset version, and live rules contents remain **unverified**. The local reference files currently hash to:

- `firestore.rules`: `CE29FF9A739E21B08E1A4E3E03B4C33EAAFC81DA51757C9D397C21D95022C773`
- `storage.rules`: `059AA92F0D83835BFAB8B68E028D726409A6981FD419CAB078FACC686C4592B`
- `firestore.indexes.json`: `2D088B15D624A0E17E555D3CB1A3157993FC647451909C2BFD977B087B5E90CC`

These hashes are only local evidence; they do not prove what is deployed. The Firebase debug logs in this repository are emulator logs for `demo-blood-bank`, not production deployment evidence.

## Executive result

Status: **PASS WITH LIMITATIONS** for the tested local scope. The protected request, chat, SOS, Storage and role workflows passed the available emulator and authenticated HTTP tests. Production readiness is not established: no staging project has been approved or tested, no Functions are deployed, provider credentials are unverified, and live rules/indexes were not compared.

## Baseline and inventory

The application contains Flutter authentication, donor/receiver dashboards, request creation and tracking, donor discovery with `flutter_map`/OpenStreetMap and `latlong2`, SOS, chat, voice-call screens, FCM notification history, donation history, hospitals, profile/settings, awareness banners and an admin web workspace. State is Provider based. Firebase services include Auth, Firestore, Storage, Cloud Functions, FCM, App Check and Crashlytics. Existing changes were preserved; the working tree was already dirty before this audit.

Cloud Functions cover request matching/lifecycle, donor invitations, SOS/review/escalation, chat, voice, notifications, awareness banners, verification, donation history/disputes, admin actions/analytics and account deletion. The local Functions inventory reports 54 exports and no missing literal/dynamic callable names checked by the preflight script.

## Tests actually run

| Area | Command | Result | Evidence / limitation |
|---|---|---:|---|
| Backend syntax | `npm.cmd --prefix functions run check` | Passed, exit 0 | Node `--check` for exported modules and preflight script |
| Backend policy/unit | `npm.cmd --prefix functions test` | 13 passed, 0 failed | Re-run 24 Oct 2026; policy, hospital and banner tests |
| Flutter static analysis | `flutter analyze --no-pub` | Passed, no issues | Local SDK |
| Flutter tests | `flutter test --no-pub` | 52 passed, 0 failed | Widget, policy, localization, UI/state tests |
| Auth/Firestore/Storage emulator | `firebase emulators:exec --only firestore,auth,storage --project demo-bloodbank 'npm.cmd --prefix functions run test:emulator'` | 60 passed, 0 failed, 0 skipped, exit 0 | Synthetic fixtures; rules emulator does not prove production indexes |
| Authenticated HTTP workflow | `firebase emulators:exec --only firestore,auth,storage,functions --project demo-blood-bank 'npm.cmd --prefix functions run test:http'` | 1 passed, 0 failed, exit 0 | Real emulator Auth JWTs and callable lifecycle; external providers not exercised |
| Flutter web build | `flutter build web --profile --no-pub --dart-define=USE_FIREBASE_EMULATORS=true --no-wasm-dry-run` | Passed, exit 0 | Emulator configuration; not deployed |
| Dependency audit | `npm.cmd --prefix functions audit --omit=dev --audit-level=high` | Blocked, exit 1 | Re-run failed because npm registry audit endpoint was unavailable. Earlier local audit reported high `body-parser` 2.3.0 transitively through `firebase-functions` 7.4.0. No blind `npm audit fix` or unverified override was applied. |

Not run: physical Android/iOS device, real FCM delivery, Agora media, Twilio SMS, App Check attestation, staging acceptance, production verification, destructive load testing and live index validation.

## Confirmed fixes verified by regression tests

- Canonical request privacy: participant donors cannot directly read private request documents; owner/admin access remains available through authorized paths.
- Chat and phone sharing: new writes require active assignment, approved participants, valid deadline, non-rejected request and block checks. Withdrawal, expiry and suspension tests pass; historical messages remain readable by participants.
- Emergency rejection: linked SOS/request state is synchronized transactionally, assignments are released and rejected requests cannot be rediscovered or accepted.
- Legacy assignment compatibility: singular and array donor identifiers are normalized in memory without rewriting stored records.
- Admin analytics: real request statuses and `targetDonationId` dispute records are counted; regression HTTP test covers open, resolved and unrelated reports.
- SMS error handling: provider error text and identifiers are not returned/logged. Real provider behavior remains unverified.
- Deployment packaging: local environment/secret patterns are excluded by `firebase.json`; no secret values are tracked or printed.

## Security coverage matrix

| Feature | Unit/policy | Emulator/rules | HTTP/E2E | External/live status |
|---|---|---|---|---|
| Auth/status/roles | Covered | Covered | Partly covered | Provider/session refresh unverified |
| Profiles/private contact | Covered | Covered | Partly covered | Live rules unverified |
| Blood requests/matching | Covered | Covered | Lifecycle covered | Production indexes unverified |
| Donor invitations/pagination | Covered | Covered | Partial | Staging scale unverified |
| SOS/review/release | Covered | Covered | Covered | Push/SMS delivery unverified |
| Chat/block/withdrawal | Covered | Covered | Partial | Native realtime/device behavior unverified |
| Voice authorization | Covered | Covered | Mocked/config only | Agora provider unverified |
| Notifications | Policy covered | Data authorization covered | Creation partly covered | FCM delivery unverified |
| Storage certificates/profile/evidence/banners | Covered | Covered | Not external | Live bucket/rule parity unverified |
| Admin analytics/reports | Partial | Admin authorization covered | Analytics covered | Data volume/pagination needs staging |
| OpenStreetMap/hospitals | Utility/UI coverage | N/A | Not full E2E | Network/device permissions unverified |
| App Check | Configuration path only | N/A | Not tested | Enforcement not enabled/verified |

## Remaining issues and risks

1. **High operational blocker:** repository configuration points to `blood-bank-98037`, but no separate staging project is configured. Treat it as production until the owner confirms otherwise. Do not run deployment commands against it casually.
2. **High unresolved dependency risk:** `body-parser` 2.3.0 is reported through `firebase-functions` by npm audit. The audit endpoint was unavailable on a subsequent run. Upgrade requires compatibility review and rerunning all suites.
3. **Medium:** Firestore emulator accepts queries without proving production composite-index deployment. Deploy/verify indexes only in an approved staging project.
4. **Medium:** verification evidence can be replaced by its owner while a verification request is open; product policy must decide whether that is allowed.
5. **Medium:** pre-accept voice ringing exists, but answering/token issuance requires a current assignment. Product flow needs explicit staging validation.
6. **Medium:** response-rate/timing analytics retain placeholder values; do not present them as complete metrics.
7. **Medium:** real App Check, FCM, Agora, Twilio, device permissions and native lifecycle are unverified.
8. **Compatibility:** old clients that directly read participant request documents fail closed after restrictive rules. Deploy compatible Functions/client before rules.
9. **Deployed-rules verification blocker:** the owner-reported deployment cannot be tied to a ruleset/version from local evidence. Do not call `blood-bank-98037` staging; obtain an authenticated, read-only Firebase Console/CLI release record before production claims.

Potential attacks considered but not confirmed: forged callable payloads, cross-user private reads, role/status self-escalation, unauthorized Storage uploads, duplicate acceptance, replayed SOS/review actions, blocked/withdrawn chat writes, unrelated call tokens, notification recipient spoofing, malformed IDs/timestamps/coordinates and query injection. Synthetic tests covered the authorization cases where the emulator supports them; no production attack testing was performed.

## Safe next action

Create a separate staging Firebase project, generate staging Flutter configuration, configure billing/APIs/IAM/secrets with owner approval, deploy indexes, wait for readiness, deploy Functions, test with synthetic accounts, then publish restrictive rules. Keep production deployment and billing changes separate and approval-gated. Resolve the dependency advisory before release acceptance.

## Staging acceptance checklist

Use a new Firebase project and a separate Flutter `firebase_options.dart`; do not reuse the `q` alias. Verify indexes are enabled before scale tests, deploy Functions and the compatible client before restrictive rules, and create synthetic approved/rejected/suspended donor, receiver and admin accounts. Exercise request creation/acceptance/withdrawal, private projections, chat/block/expiry, SOS review/release, notifications, Storage evidence/profile uploads, voice authorization, and admin analytics. Separately verify App Check attestation, FCM delivery, Agora tokens/media, Twilio behavior and Storage provider access. Record project ID, ruleset IDs, function regions, index readiness and test logs.
