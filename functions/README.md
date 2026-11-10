# Optional legacy VetaLife meal AI functions — Blaze

The app's default cloud AI path now uses Firebase AI Logic with the Gemini
Developer API on Spark. Follow [the current setup guide](../docs/flow2-setup.md)
for that path. The files in this directory preserve the previous server-side
implementation for an explicit future Blaze deployment; the default root
Firebase configuration does not deploy this codebase.

The secret commands, server-profile lookup and per-UID quotas below apply only
to this legacy backend. They are not prerequisites for Firebase AI Logic, and
the default app no longer calls these Functions. Local rules tests in this
directory remain useful for the shared Firestore journal rules.

Node 22 Firebase Functions v2 callables in `asia-southeast1`:

- `recognizeMeal({imageBase64, mimeType})`: OCR plus provisional visible-food
  recognition. JPEG/PNG/WebP only, at most 4 MiB decoded. No uploaded image is
  stored. Recognition never receives the user's profile.
- `analyzeMeal({meal, confirmed: true})`: analyzes confirmed ingredient data
  against the source-mapped book corpus. Requires `users/{uid}` and derives
  age server-side. Name, exact birthday, UID and photo are omitted from the
  Gemini prompt. Returned citations are resolved by this server, not fabricated
  by the model. The Flutter app explicitly saves the result to its journal.

Both require Firebase Authentication. Requests share limits of 40 per UTC day
and 6 per minute per UID, enforced atomically in the server-only Firestore
collection `_mealAiUsage`. Keep that collection denied in client rules. Valid
requests consume a quota slot even if the provider fails, bounding retry costs.
The legacy callable options still set `enforceAppCheck: false`; this is separate
from the default AI Logic service, whose enforcement is confirmed `ENFORCED`.
Enable enforcement for any future legacy deployment only after configuring its
client providers. These limits are protection for an authenticated client, not a
replacement for App Check or operational billing controls.

## Prepare and verify

```powershell
cd functions
npm ci
npm run build
npm run check
npm test
```

The normal test command runs isolated backend unit tests only. Firestore rules
have a separate emulator suite. From the repository root:

```powershell
firebase emulators:exec --only firestore --project demo-vetalife-rules "npm --prefix functions run test:rules"
```

The rules suite requires `FIRESTORE_EMULATOR_HOST` pointing to a loopback host
and uses the `demo-vetalife-rules` project ID. It never falls back to a real
Firestore database. It checks owner journal access, idempotent record IDs,
cross-user/anonymous denial, parent profile requirements, rejected extra photo
fields, bounded record shape, forbidden cloud deletion and server-only quota
documents. Keep these checks separate from tests that stub Gemini/profile
dependencies. The test-only Firebase SDK is pinned to the Node 22-compatible
major versions; its dependencies are not needed by deployed functions.

`build` copies only `assets/content/meal-knowledge.json` into `functions/data/`.
The full PDF and scan images never enter the function bundle. The copy is
generated and ignored; run build again when the verified corpus changes.
To opt into this legacy backend later, use the separate
`firebase.functions.legacy.json` configuration and its
`npm --prefix "$RESOURCE_DIR" run build` predeploy hook.
The cloud `gcp-build` step only checks the already bundled JavaScript: the
repository-level assets directory is outside the uploaded Functions source.
This keeps cloud builds from trying to copy a file that only exists locally.

The lockfile keeps Firebase `app` and `app-compat` aligned with the pinned web
SDK so the rules-test compat plugins share one app registry on Node 22.
Overrides also pin patched gRPC/glob/minimatch transitive dependencies; verify
unit and emulator rules tests when updating this dependency set.

## Cloudinary private report uploads

The report callables sign direct Cloudinary uploads and issue ten-minute
download links only after checking the authenticated user's owner-bound public
ID. Cloudinary stores reports as `raw` + `authenticated`; the API secret is
available only to these callables through Firebase Secret Manager. Flutter
uploads to the `raw/upload` endpoint using the returned signature and should
enforce the returned 10 MiB client limit.

Configure a **signed** Cloudinary upload preset for raw PDF reports with
`allowed_formats=pdf`, `overwrite=false`, and authenticated access. Leave the
preset's **Asset folder / Folder** empty so Cloudinary preserves the exact
owner-bound `public_id` (`u_<base64urlUid>/reports/<uuid>.pdf`) verified by
the Flutter client. In Cloudinary Console → **Settings → Security**, also enable
**Allow delivery of PDF and ZIP files** so authenticated raw PDF downloads do
not fail with HTTP 401/404. Cloudinary upload presets do not provide a
per-preset file-size limit, so configure the product environment's maximum
raw-file upload size if a hard server-side size cap is required; the callable
signature binds the preset, generated public ID, authenticated delivery type,
timestamp and `overwrite=false`. The callable can't verify the body size during
a direct-to-Cloudinary upload.

Set `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, and
`CLOUDINARY_REPORT_UPLOAD_PRESET` in `functions/.env.<project-id>` (or
`functions/.env.local` for local emulator testing). Store the secret separately:

```powershell
firebase functions:secrets:set CLOUDINARY_API_SECRET --project <project-id>
```

For local Functions emulation without Blaze, run `npm run build`, put the
non-secret keys in ignored `functions/.env.local` and `CLOUDINARY_API_SECRET=...`
in ignored `functions/.secret.local`, then start:

```powershell
firebase emulators:start --config firebase.functions.legacy.json --only auth,firestore,functions
```

When targeting local emulators from an Android emulator or USB device, run
`adb reverse tcp:9099 tcp:9099`, `adb reverse tcp:8080 tcp:8080`, and
`adb reverse tcp:5001 tcp:5001` before launching Flutter with
`--dart-define=APP_MODE=cloud --dart-define=USE_FIREBASE_EMULATORS=true`.

The Functions codebase is not deployed by the default Firebase configuration
and deploying Firebase Functions requires a Blaze project. No Cloudinary
credentials are present in source control and no Functions or Cloudinary
deployment is performed by local code changes.

## Secret and model

Create a Gemini Developer API key in your own Google AI project, then store it
with Firebase Secret Manager. Do not paste it into Flutter, source control,
terminal output or issue comments.

```powershell
firebase functions:secrets:set GEMINI_API_KEY --project vetalife-24f03
```

The default model is `gemini-3.8-flash`. An optional `GEMINI_MODEL` parameter
can be placed in `functions/.env.vetalife-24f03` for another compatible model.
There is no provider fallback that could mislabel generated results.

For local Functions emulation, put `GEMINI_API_KEY=...` in ignored
`functions/.secret.local`, build the corpus, and start the Functions, Auth and
Firestore emulators. Configure Flutter to target the same emulator project and
authenticate through the Auth emulator; callables reject unauthenticated users.
An emulator request still contacts Gemini and can incur provider usage unless
the test harness injects a stub. Unit tests inject stubs and make no API calls.

The parent project owns emulator ports and Flutter composition. A production
Functions deployment requires an enabled billing plan, Secret Manager/API
permissions, and verified owner rules. No deployment or live AI test is claimed
by adding this code. After configuration, deploy only the two callables and
the required rules, then verify using a test user and a non-sensitive meal.

## Content and error behavior

Unknown ingredients with no matching verified source produce
`failed-precondition` so the user can clarify the ingredients. Unconfirmed
submissions are rejected before reading a profile or calling Gemini. Invalid
images/inputs produce `invalid-argument`; quota returns `resource-exhausted`;
model timeouts return `deadline-exceeded`; bad/invented references return
`data-loss`; provider/internal failures return a generic `unavailable` without
provider messages or stack traces. The client must retain drafts for retry.

Model calls are bounded at 45 seconds and the callable at 60 seconds. Aborting
a request stops local waiting; it does not guarantee the provider stops work or
waives billing. Book retrieval is word-boundary matching over confirmed
ingredient names; it does not infer that generic rice is whole-grain rice or
that any unspecified oil is a particular food. Retrieval is deliberately a
small curated set rather than a claim to search the full book. Accented food
names match with accents preserved, preventing tamarind (`me`) from being
classified as sesame (`mè`). Completely unaccented input supports multiword
aliases, but ambiguous one-syllable accented aliases do not use that fallback.

System instructions and output validation restrict feedback to education,
source-mapped topics and long-term eating patterns. They prohibit diagnosis,
individual disease-prevention promises, numeric risk estimates and invented
calorie/BMI targets. These are application guardrails, not clinical validation;
real-provider output and native runtime remain separate checks.

Official references checked on 2026-11-03:

- [Gemini 3.8 Flash model and capabilities](https://aistudio.google.com/docs/models/gemini-3.8-flash)
- [Google Gen AI JavaScript SDK](https://github.com/googleapis/js-genai)
- [Gemini structured outputs](https://aistudio.google.com/docs/structured-output)
- [Firebase callable functions](https://firebase.google.com/docs/functions/callable)
- [Firebase secrets and parameters](https://firebase.google.com/docs/functions/config-env)
