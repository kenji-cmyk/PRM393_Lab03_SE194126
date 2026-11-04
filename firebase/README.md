# Firebase configuration scaffold

Primary baseline: Cloud-Enabled Lab 3 sections 5-6 and Preparation Guide v5.
Required services: Authentication, Cloud Storage, Cloud Messaging, Analytics,
Crashlytics, and Remote Config. Use the student's own Firebase project.

| File | Purpose / current status |
| --- | --- |
| `storage.rules` | Existing deny-all placeholder; define owner-scoped `reports/{uid}/...` rules and verify before deployment |
| `remote-config-defaults.json` | Empty placeholder; define at least two behavior-changing parameters after Lab 2 scope is known |
| `firestore.rules` | Owner-only profiles, meals and lessonProgress; known lesson IDs/payload allowlists/server timestamps; 12 emulator checks passed and deployed rules match local |
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
Confirm Cloud Storage availability/billing during integration; substitution needs
lecturer approval under the selected handout.

At setup verify Google Sign-In, enable Analytics when implemented, and register
the signing fingerprints for each build variant. Isolate SDK adapters in
`lib/firebase/` behind `lib/services/`;
Views must not call SDKs directly.

Flow 3 progress is stored at `users/{uid}/lessonProgress/{lessonId}` with
`lessonId`, canonical UTC `readAt`, and server `updatedAt`. Reads require the
owner; writes additionally require an existing profile and one of the 30 known
IDs. Clients cannot delete progress. Introductory lesson bodies stay bundled;
this flow requires no model request or additional paid service.

The alternate MobAI handout additionally requires Firestore CRUD, two collections,
queries, realtime updates, and PDF metadata. These are reference requirements,
conditional on approved scope here. Final Assignment storage constraints differ;
defer that assignment's configuration.
