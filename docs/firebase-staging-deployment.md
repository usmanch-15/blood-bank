# Firebase staging runbook — 23 October 2026

Status: local implementation only. No deployment, billing change, production migration, live-rule change, commit or push was performed. All commands in the deployment section require explicit approval first.

## Read-only findings

`functions/scripts/deployment-preflight.js --project blood-bank-98037 --live` returned:

- Cloud Billing `billingEnabled: false`.
- Functions v1 and v2 inventories both empty, neither paginated.
- Fresh `firebase-readiness-live.log`: Cloud Run, Cloud Build, Artifact Registry, Eventarc, Cloud Scheduler, Secret Manager and Firebase Storage APIs DISABLED. Cloud Functions, Pub/Sub, Firestore, Identity Toolkit, FCM and Cloud Storage APIs ENABLED.
- Latest Cloud Functions service-state lookup succeeded: ENABLED (supersedes the earlier HTTP 500). Live preflight exits 2 for blocked/unknown prerequisites; exit 0 for local inventory is not deployment approval.
- Both secret-version metadata requests returned 403. This does **not** prove either secret is absent. No secret payload was read or printed.
- `.firebaserc` contains only alias `q` for this project; no staging project is configured.

The current billing state prevents Functions deployment. These are present-day blockers, not evidence of the historical reason no deployment occurred. Deployment history and IAM adequacy were not established.

Firebase requires Blaze for deployment, although local emulation does not. Charges can include invocation/compute, network, build, artifacts, Firestore/Storage, Scheduler and Secret Manager; Agora and Twilio have separate provider charges. Budget alerts are not spending caps. Do not enable billing automatically. Official references: [Functions getting started](https://firebase.google.com/docs/functions/get-started?platform=flutter), [Functions costs and deployment](https://firebase.google.com/docs/functions), [scheduled Functions](https://firebase.google.com/docs/functions/schedule-functions), [secret configuration](https://firebase.google.com/docs/functions/config-env?hl=en).

## Source contracts and feature impact

Local inventory loads 54 exports, with no missing names among scanned literal Flutter calls and the explicitly reviewed dynamic request calls. Backend default region and Flutter default `FUNCTIONS_REGION` are `us-central1`. Do not set a different Flutter region without matching backend deployment. All client instances now use `WorkflowService.functions`; legacy donor/admin/settings/voice calls previously bypassed this shared region/emulator configuration.

| Dependency group | Functions / affected features | Readiness |
| --- | --- | --- |
| Requests and donor discovery | createBloodRequest, getRequest, participantRequests, discoverRequests, findDonors, acceptDonation, declineRequest, updateAssignment, confirmDonation, closeRequest, donorInvitations, getDonorContact | Local implementation and workflow/rules tests; actual HTTP lifecycle also exercised. Requires deployment and indexes. |
| SOS | createSosAlert, getSos, resolveSos; emergency review/escalation triggers | Local tests; missing endpoints prevent creation/tracking/review. Scheduled production execution unverified. |
| Campaigns | manageAwarenessBanner, donorAwarenessBanners, recordBannerEvent | Local tests; requires Storage bucket/rules and scheduled feed data. |
| Administration/account/history | adminAction, adminRequestAction, adminAnalytics, adminDeleteUser, deleteAccount, exportPage, submitReport, verification/dispute/history exports | Names exported; policy/emulator coverage varies. Not all payload/provider combinations have an HTTP test. |
| Chat/notifications | blockUser, unblockUser, markConversationRead, reportConversation, sharePhoneNumber, notifyRequest and document triggers | Local contracts present; native delivery and production trigger behavior not verified. |
| Voice | createVoiceCallSession, getVoiceCallToken, updateVoiceCallSession | Additionally blocked on verified AGORA_APP_ID and AGORA_APP_CERTIFICATE, provider account/credentials and staging voice smoke tests. |
| SMS fallback | notifyNearbyDonorsOnSOS | Additionally blocked on verified TWILIO_SID, TWILIO_PHONE and TWILIO_AUTH_TOKEN, provider permissions/credits. SMS is disabled by default parameter values. |

Four exports bind secrets: the three voice callables bind `AGORA_APP_CERTIFICATE`; `notifyNearbyDonorsOnSOS` binds `TWILIO_AUTH_TOKEN`. The remaining 50 do not have secret bindings, but are still blocked from live deployment by billing/API/IAM prerequisites. Source-ready is not provider-ready or production-verified. Authentication/owner Firestore readers may still work without Functions; the dependent features above cannot be restored by UI changes alone. HTTP NOT_FOUND in the supplied screenshots is consistent with the verified empty inventory, but does not independently prove which historical configuration produced each screenshot.

## Privacy cutover and compatibility

`blood_requests/{id}` is the private canonical record, readable only by active owner/admin. There is deliberately no destructive field migration or public Firestore mirror. Donor discovery/activity/detail are authenticated, allowlisted callable responses. This protects unknown legacy fields without guessing a finite deletion list.

Before: any accepted participant could bypass callable redaction and directly read patientName, patientAge, patientGender, reason, notes, contactNumber, requesterPhone, requesterName, reviewNote, clarificationReply, all assignments and any future/legacy private field. After approved rollout: direct donor document/query/event reads and all client canonical writes are denied. Owner/admin reads and server-authorized workflows remain. Participant detail contains its own assignment only; exact meeting location is intentionally shared with accepted participants, while discovery uses approximate location. Requester UID is retained for authorized communication, not a phone/name disclosure.

Regression fixtures exercise current multi-donor and legacy `acceptedDonorId` records, unknown private fields, role/capability changes, owner/admin access, unauthorized reads/writes, list pagination and unchanged canonical document contents. No backfill is required for those supported schemas. Production schema completeness has **not** been established; staging should include representative authorized/sanitized historical fixtures. Arbitrary corrupt records or assignments without any queryable participation identifier need separate diagnosis, not silent rewriting.

Rollout order: stage Functions and indexes; wait for indexes; build updated client; apply staging rules; verify all roles and old-client denial; approve production rollout separately. Old clients that query participant documents directly will fail after rules cutover. Require client update/maintenance communication. Existing downloaded/offline caches cannot be retroactively undisclosed. Do not roll back by restoring permissive participant reads; roll back clients/backend only to a privacy-compatible version or fail closed.

## Safe local commands (PowerShell, repository root, Node 22)

```powershell
node --version
npm.cmd --prefix functions run check
npm.cmd --prefix functions test
node functions/scripts/deployment-preflight.js
# Optional read-only live metadata; requires existing Firebase login:
node functions/scripts/deployment-preflight.js --project blood-bank-98037 --live
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
$env:XDG_CONFIG_HOME = "$PWD\.firebase-config"
& .\functions\node_modules\.bin\firebase.cmd emulators:exec --project demo-bloodbank --only firestore,auth,storage 'npm.cmd --prefix functions run test:emulator'
flutter analyze
flutter test
flutter build web --profile --dart-define=USE_FIREBASE_EMULATORS=true --no-wasm-dry-run
```

The rules suite uses `demo-bloodbank`; HTTP/browser fixtures use `demo-blood-bank`. Do not mix the two:

```powershell
# Terminal 1; keep running:
& .\functions\node_modules\.bin\firebase.cmd emulators:start --project demo-blood-bank --only firestore,auth,storage,functions
# Terminal 2:
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'
npm.cmd --prefix functions run test:http
```

## Approval-required staging procedure

1. Obtain explicit approval for a named **staging** Firebase project and its billing budget. Owner configures Blaze, required APIs, appropriate deployment/runtime/service-agent IAM, Auth providers/authorized domains, Firestore location and Storage bucket. Never reuse production user data or provider credentials in emulator fixtures.
2. Confirm Node 22, installed lockfile dependencies, project-specific Firebase app configuration and staging Auth accounts. Preserve production package identifiers/config files; use a separately generated staging options file/build configuration. Validate indexes and bucket existence. App Check providers/metrics must be prepared before any separately approved enforcement.
3. Set staging secrets interactively and parameters in the staging environment. Never put secret values in command arguments, source, logs or chat. Full deployment includes provider Functions and therefore requires both secrets even if SMS parameters are disabled.
4. Only after approval, replace the placeholder below. These commands change staging resources; they have **not** been executed:

```powershell
$stagingProject = 'REPLACE-WITH-APPROVED-STAGING-PROJECT'
if ($stagingProject -eq 'REPLACE-WITH-APPROVED-STAGING-PROJECT' -or $stagingProject -eq 'blood-bank-98037') { throw 'Use an explicitly approved staging project.' }
& .\functions\node_modules\.bin\firebase.cmd functions:secrets:set AGORA_APP_CERTIFICATE --project $stagingProject
& .\functions\node_modules\.bin\firebase.cmd functions:secrets:set TWILIO_AUTH_TOKEN --project $stagingProject
# Configure AGORA_APP_ID, TWILIO_SID, TWILIO_PHONE for staging before deployment.
& .\functions\node_modules\.bin\firebase.cmd deploy --project $stagingProject --only 'functions,firestore:indexes'
# Wait for indexes to finish; prepare updated staging client before rules cutover.
& .\functions\node_modules\.bin\firebase.cmd deploy --project $stagingProject --only 'firestore:rules,storage'
& .\functions\node_modules\.bin\firebase.cmd functions:list --project $stagingProject
node functions/scripts/deployment-preflight.js --project $stagingProject --live
```

5. Browser staging acceptance: owner/admin full record, accepted donor redacted detail/activity/chat, stranger denied direct get/query/private/contact/events/write; test legacy assignment, expired/cancelled/withdrawn states, more than 30 rows, all request tabs, banners, SOS retries and role switching. Inspect authenticated callable logs without patient/contact/token logging. Verify background schedules/triggers and provider credentials separately. No physical Android verification is part of this task.
6. Review evidence/costs/error rates and obtain separate production deployment approval. Do not run a production migration, relax security, or enable App Check enforcement as an incidental deployment step.

## Firebase-only continuation: deployment requirements (latest)

The fresh read-only snapshot is `firebase-readiness-live.log`, exit **2** (blocked), with zero deployed v1/v2 Functions. This proves current blockers, not the historical reason nobody deployed. No billing account ID, secret payload or production document was inspected.

Required for this actual code:

- All 54 exports use Node 22 and explicit `us-central1`. V2 callable/Firestore functions need Cloud Functions, Cloud Run, Cloud Build, Artifact Registry, Eventarc and Pub/Sub services. Firestore, Firebase Authentication and FCM are used at runtime.
- Three scheduled exports also require Cloud Scheduler. Storage uploads/certificates/banners require both Cloud Storage and Firebase Storage provisioning/rules. Secret Manager is required by four secret-bound exports even when provider parameters disable SMS.
- Full deployment requires `AGORA_APP_CERTIFICATE` for `createVoiceCallSession`, `getVoiceCallToken`, `updateVoiceCallSession`, and `TWILIO_AUTH_TOKEN` for `notifyNearbyDonorsOnSOS`. Configure non-secret `AGORA_APP_ID`, `TWILIO_SID`, `TWILIO_PHONE` in `functions/.env.<approved-staging-project>`. Never put certificate/token values there. `.secret.local` is ignored by Git and deployment packaging; emulator environment/test files are excluded from deployment packaging.
- Billing: project owner must approve and link a billing account/Blaze plan. Billing Account User plus Project Billing Manager (or equivalent authorized administrator) are needed for linking. No estimate can be guaranteed without traffic/provider assumptions. Scheduler currently lists $0.10/job/month with three free jobs per Google account; compute/build/artifact/storage/database/network/secrets and third-party voice/SMS can add charges. Set budgets/alerts; alerts do not cap spending.
- Permissions: have an administrator verify the deployer's Cloud Functions Developer/Admin permissions and Service Account User on the selected runtime/build service accounts, permission to enable services, set Function invocation IAM, deploy Firestore indexes/rules and Storage rules. Runtime needs its actual Firestore/Auth/FCM/Storage access and per-secret Secret Accessor. Verify Google-managed Functions/Eventarc/build service-agent roles instead of granting arbitrary broad roles to end users. Secret metadata 403 may be caused by disabled API or IAM; it does not establish existence or validity of either secret. Provider account ownership/credentials must be supplied by the project owner securely.
- App Check enforcement remains unchanged. Provider registration and metrics are a separate approval-gated rollout, not an incidental setting change.

Official deployment/IAM references checked for this pass: [Firebase prerequisites](https://firebase.google.com/docs/functions/get-started), [Functions IAM](https://docs.cloud.google.com/functions/docs/reference/iam/roles), [service agents/build access](https://docs.cloud.google.com/functions/docs/concepts/iam), [secret configuration](https://firebase.google.com/docs/functions/config-env), [Scheduler cost/API](https://firebase.google.com/docs/functions/schedule-functions).

### Approval-required staging API and secret setup

These are **instructions only**; no command below was executed. A project administrator must first provide the approved staging project, billing account authorization and appropriate IAM. `gcloud` installation/login and administrator privileges are prerequisites, not verified here.

```powershell
$stagingProject = 'REPLACE-WITH-APPROVED-STAGING-PROJECT'
if ($stagingProject -eq 'REPLACE-WITH-APPROVED-STAGING-PROJECT' -or $stagingProject -eq 'blood-bank-98037') { throw 'Select approved staging first.' }
# After explicit billing approval: owner links billing/Blaze in Firebase Console.
# After explicit staging configuration approval:
gcloud services enable cloudfunctions.googleapis.com run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com eventarc.googleapis.com pubsub.googleapis.com cloudscheduler.googleapis.com secretmanager.googleapis.com firestore.googleapis.com identitytoolkit.googleapis.com fcm.googleapis.com storage.googleapis.com firebasestorage.googleapis.com --project=$stagingProject
if ($LASTEXITCODE -ne 0) { throw 'API setup failed.' }
# Interactive prompts: paste secrets only into the local CLI prompt, never here or in arguments.
& .\functions\node_modules\.bin\firebase.cmd functions:secrets:set AGORA_APP_CERTIFICATE --project $stagingProject
if ($LASTEXITCODE -ne 0) { throw 'Agora secret setup failed.' }
& .\functions\node_modules\.bin\firebase.cmd functions:secrets:set TWILIO_AUTH_TOKEN --project $stagingProject
if ($LASTEXITCODE -ne 0) { throw 'Twilio secret setup failed.' }
node functions/scripts/deployment-preflight.js --project $stagingProject --live
if ($LASTEXITCODE -ne 0) { throw 'Prerequisites remain blocked or unknown.' }
```

Preflight metadata success still does not prove effective deployer/runtime IAM, actual provider validity, deployed indexes, App Check, or user journeys. Do not use CLI deployment as a dry-run: it can enable APIs and mutate IAM/resources.

Use the approval-required deployment procedure above after these prerequisites. Deploy Functions/indexes first, wait for index readiness, use the updated staging client/configuration, then restrictive Firestore and Storage rules. Verify accepted donor redaction, receiver/admin full access, new-message revocation, reviewed/rejected SOS and legacy fixtures. An old client directly reading canonical participant documents will fail closed. Do not weaken rules for compatibility, migrate production records, or publish the emulator build. Separate production approval is required after staging evidence.

## Manual deployment file package

See firebase-manual-deployment.md for exact local file contents and SHA-256 fingerprints. It contains all three deployable rules/index files and the two local CLI configuration files. The follow-up adds the pending-donation-dispute index required by adminAnalytics; deploy indexes and wait for readiness before the updated Functions to avoid transient index failures. Firestore/Storage rules are unchanged in this follow-up. No live rule comparison was performed, so an unchanged local file is not proof that the remote release already matches.

Storage rules use Firestore lookups. When prompted by Firebase Console/CLI, the deployer must explicitly authorize the cross-service permissions; do not weaken the lookup or replace it with authentication-only access. Official reference: https://firebase.google.com/docs/storage/security/rules-conditions

Avoid rerunning firebase init: the existing firebase.json already points to the correct files. Do not paste firestore.indexes.json into a Rules editor. Use explicit --project on each terminal command, review any index-deletion prompt and do not use --force.
