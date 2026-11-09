# Firebase configuration and implementation status

Primary baseline: Cloud-Enabled Lab 3 sections 5-6 and Preparation Guide v5.
Required services: Authentication, Cloudinary for private PDF upload, Cloud Messaging, Analytics,
Crashlytics, and Remote Config. Use the student's own Firebase project.

| File | Purpose / current status |
| --- | --- |
| `storage.rules` | Legacy Firebase Storage rules; Cloudinary is the selected report provider |
| `remote-config-defaults.json` | `learning_enabled` and `report_export_enabled`, both Boolean defaults published true Nov 9; device fetch unverified |
| `firestore.rules` | Owner profiles/meals/lessonProgress and FCM devices rules; Nov 9 deployment and production readback match the local source |
| `firestore.indexes.json` | Empty index definition; add indexes needed by actual queries |

Client configuration targets `vetalife-24f03`. The VetaLife Android app is
registered as `vn.edu.fpt.vetalife`, with its existing debug SHA-1 registered
and its official Google Services configuration downloaded. Cloud sign-in,
profile persistence and account/device interaction still need verification. Owner
rules are deployed and read back for profiles, meals and lesson progress. See
[Firebase setup](../docs/firebase-setup.md) for configuration and cloud-mode commands.
The default AI path uses Firebase AI Logic with the Gemini Developer API on
Spark for supported models/quotas. CLI setup has enabled `gemini-developer-api`
for the registered Android/web apps and confirmed AI Logic App Check as
`ENFORCED`, with no billing change. The App Check API is enabled; a temporary
debug-token exchange and a non-personal model healthcheck returned HTTP 200.
That token was revoked. Web reCAPTCHA provider/site key and device-specific
debug-token setup remain; native camera and real-meal accuracy are unverified.
See [Flow 2 setup](../docs/flow2-setup.md). No Gemini secret
or Functions deployment is required for this path. The former `functions/`
backend is retained as an optional legacy Blaze implementation; its quota
collection remains denied to clients.
Nov 9 readback confirmed billing disabled and no Storage buckets. The user has
approved Cloudinary as the report provider. PDF uploads use authenticated raw
assets and Firebase callable endpoints to sign uploads and issue short-lived
download links. Cloudinary credentials/preset and Functions deployment remain
to be configured. Deploying the signer requires Firebase Functions billing
(Blaze); no account billing change or production deployment has occurred.

At setup verify Google Sign-In, Analytics collection/DebugView, and register
the signing fingerprints for each build variant. Isolate SDK adapters in
`lib/firebase/` behind `lib/services/`;
Views must not call SDKs directly.

## Service integrations added 2026-11-09

FCM has explicit opt-in, Android background handling, a web service worker,
bounded UID-scoped local history, allowlisted tap destinations and device-token
registration. Web needs a VAPID public key; foreground/background/terminated
reception and denial paths still need live-device evidence. Notification payloads
must use generic content and include the recipient UID; see
[service setup](../docs/firebase-services-setup.md).

Reports generate PDFs from saved profile, meals and lesson progress using bundled
Vietnamese fonts. Cloudinary uploads use authenticated raw delivery and a
Firebase UID-bound public ID; callable Functions sign uploads and issue
time-limited downloads after checking ownership. Preview generates locally and
never uploads. Firebase Storage rules are not used for report uploads.

Analytics instruments 16 allowlisted actions with flow enums/bounded counters and
UID cleanup; [the event plan](../docs/analytics-plan.md) defines triggers/questions.
Native Crashlytics records sanitized handled failures and has a debug crash
action gated by `ENABLE_CRASH_TEST`; web Crashlytics is unsupported. Remote Config
supplies two visible feature gates with fallback defaults and retry. Both Boolean
keys were published true; [publication](../evidence/cloud/service-flags-publish-2026-11-09.json)
and [readback](../evidence/cloud/firebase-services-readback-2026-11-09.json) record
that cloud configuration. Real-device FCM delivery/flag fetch, DebugView and crash
dashboard evidence remain pending. No billing upgrade occurred. Checks actually
executed are in [test report](../docs/test-report.md).

Flow 3 progress is stored at `users/{uid}/lessonProgress/{lessonId}` with
`lessonId`, canonical UTC `readAt`, and server `updatedAt`. Reads require the
owner; writes additionally require an existing profile and one of the 30 known
IDs. Clients cannot delete progress. Introductory lesson bodies stay bundled;
this flow requires no model request or additional paid service.

The alternate MobAI handout additionally requires Firestore CRUD, two collections,
queries, realtime updates, and PDF metadata. These are reference requirements,
conditional on approved scope here. Final Assignment storage constraints differ;
defer that assignment's configuration.
