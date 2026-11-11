# Firebase services integration

Implementation added on 2026-11-09. This guide separates executable code from
production configuration and device evidence. No billing upgrade or production
deployment is implied by a successful local build.

## Run and find the new features

```powershell
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 5210 --dart-define=APP_MODE=preview
```

Complete a profile, then open the Home profile menu. **Xuất báo cáo PDF** creates
a PDF from the saved profile, journal and read progress. **Cài đặt ứng dụng**
shows the default feature flags. Preview never uploads reports, registers FCM
tokens or sends Analytics/Crashlytics events.

Cloud uses the existing Firebase project and Google authentication:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 5211 --dart-define=APP_MODE=cloud --dart-define=FCM_VAPID_KEY=YOUR_PUBLIC_WEB_PUSH_KEY
```

Google sign-in and profile/journal saves do not require the AI web site key.
AI analysis additionally needs the App Check configuration in
[Flow 2 setup](flow2-setup.md). Never put model secrets in Dart defines.

## Rules and local emulator validation

The new Firestore rule allows only the owner to register/revoke device tokens
at `users/{uid}/devices/{base64urlToken}`. Values are a bounded token, an
allowlisted platform, and a server timestamp. Other users and anonymous clients
cannot read these documents. Existing profile, meal and progress rules remain.

Reports are stored in Cloudinary as authenticated raw PDFs. Firebase callable
functions issue a signed upload for a server-generated owner path and return
time-limited download URLs only after checking the Firebase UID. The API secret
stays in Firebase Functions Secret Manager; it is never included in Flutter.
The app rejects empty files and PDFs over 10 MiB before upload. Cloudinary
upload presets do not enforce a per-preset size limit, so set and verify the
Cloudinary account Usage Limit for raw files as an additional server-side cap.

```powershell
firebase emulators:exec --config firebase.test.json --only firestore,storage --project demo-vetalife-rules "node --test --test-concurrency=1 functions/test-rules/firestore.test.js functions/test-storage/report-storage.test.js"
```

This is a disposable demo project on ports 8185/9295, independent of production.
The report signer is in the legacy Functions codebase. Run
`npm --prefix functions run build` first, then start its Auth, Firestore and
Functions emulators with
`firebase emulators:start --config firebase.functions.legacy.json --only auth,firestore,functions`.
Flutter's `USE_FIREBASE_EMULATORS` setting targets Auth 9099, Firestore 8080 and
Functions 5001 on `127.0.0.1` by default (use `adb reverse tcp:9099 tcp:9099`,
`adb reverse tcp:8080 tcp:8080`, and `adb reverse tcp:5001 tcp:5001` when
running on an Android emulator or USB device, or pass
`--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2` if binding emulators on all
interfaces). Cloudinary requests still reach Cloudinary when using local
Functions.

On 2026-11-11 the team migrated active Firebase client configuration to the
dedicated project `vetalife-lab3`, registered Android (`vn.edu.fpt.vetalife`)
and Web apps, and deployed `firebase/firestore.rules` to `vetalife-lab3`
(including `users/{uid}/devices`). Earlier 2026-11-09 readback on `vetalife-24f03`
had billing disabled and no Storage bucket; `vetalife-lab3` is also on Spark,
so Cloud Functions deployment and production Cloudinary credentials remain
prerequisites for production report uploads:

```powershell
firebase deploy --only firestore:rules --project vetalife-lab3
firebase functions:secrets:set CLOUDINARY_API_SECRET --project vetalife-lab3
firebase deploy --config firebase.functions.legacy.json --only functions:meal-ai:createReportUploadSignature,functions:meal-ai:getReportDownloadUrl --project vetalife-lab3
```

Set the non-secret `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, and
`CLOUDINARY_REPORT_UPLOAD_PRESET` in the Functions environment for the target
project (`functions/.env.<project-id>` for production, or ignored
`functions/.env.local` + `functions/.secret.local` for local emulator testing).
In Cloudinary:

1. Create a **signed** upload preset with `overwrite=false`, `allowed_formats=pdf`,
   and `authenticated` delivery type; leave the preset **Asset folder / Folder**
   empty so the server's `u_<base64urlUid>/reports/<uuid>.pdf` public ID is
   preserved exactly.
2. In Cloudinary Console → **Settings → Security**, enable **Allow delivery of
   PDF and ZIP files** (disabled by default on free accounts; without this,
   downloading private PDFs fails with HTTP 401/404).
3. Ensure the account raw-file size Usage Limit is configured (client also
   enforces the 10 MiB limit).

Firebase Functions deployment requires Blaze billing on `vetalife-lab3`. Do not
put these values in Dart defines or commit secrets. Production signer endpoints
remain pending until Blaze billing is approved and configured; use the local
Firebase emulators (`USE_FIREBASE_EMULATORS=true`) for Spark-compatible testing.

See [readback](../evidence/cloud/firebase-services-readback-2026-11-09.json).
This deployment is configuration evidence, not a real-device FCM delivery test.

PDFs contain personal data. Upload is an explicit action, checks the current
authenticated UID, supports retry, and stores reports with authenticated
delivery. Opening a report requests a short-lived signed download URL after a
second UID check. Signing out or changing accounts disposes report state.

## Messaging

Android declares `POST_NOTIFICATIONS`; no permission prompt is shown at startup.
Home menu → **Thông báo** → **Bật thông báo** requests permission. Denial and
configuration/connection failures remain visible. Token registration runs only
for the signed-in owner. Signing out tries to invalidate delivery and remove the
device registration before closing authentication.

Web needs HTTPS or localhost, notification permission, and a public Web Push
certificate key from Firebase Console → Project settings → Cloud Messaging.
Pass that key as `FCM_VAPID_KEY`. The worker and IndexedDB bridge are in `web/`;
serve them at the same origin as the app. Background history transfers into the
owner's local inbox on opening it; history is bounded to 100 messages per UID.
Web notification clicks carry only an opaque lookup ID and remove it before
Analytics initialization. Navigation accepts only home, journal, learn, progress.

The sender must target a token from the intended recipient and include these
custom data fields:

```json
{"ownerUid":"RECIPIENT_FIREBASE_UID","destination":"journal"}
```

Use a generic notification title/body. Native/FCM may display OS notifications
before the app can validate the owner. Do not put profile, meal or health data
in push payloads. This implementation does not schedule reminders or deploy a
message-sending backend. No push was sent to another person during development.

Collect real-device evidence for foreground, background, terminated, tap,
permission-denied and logout/account-switch cases. Android force-stop and some
battery restrictions prevent delivery; distinguish these from terminated state.

## Analytics and Crashlytics

See the [event plan](analytics-plan.md): 16 allowlisted events, fixed flow enums
and bounded counts. UID is set/cleared with auth changes. Personal fields and raw
exception content are excluded. Optional SDK errors never stop a core flow.
Android collection defaults to disabled; cloud initialization enables it.

Enable Analytics debug mode on the dedicated Android test device:

```powershell
adb shell setprop debug.firebase.analytics.app vn.edu.fpt.vetalife
```

Exercise sign-in, onboarding, meal save, journal/detail, lesson read and report
generation/upload, and capture DebugView. Disable debug mode afterward using
`.none.` as the package value. A unit test verifying event calls is not
DebugView evidence.

Crashlytics supports native Android here, not web. Real handled operation errors
are reported using sanitized operation codes. For a deliberate crash on a debug
device, build with `--dart-define=ENABLE_CRASH_TEST=true`, open Settings and use
the explicit diagnostic actions. Restart the app to upload the report. Never
ship or automatically execute a test crash. Dashboard evidence remains separate
from APK compilation.

## Remote Config

Boolean parameters `learning_enabled` and `report_export_enabled` were published
on 2026-11-09 and read back. Both default to `true`, matching
`firebase/remote-config-defaults.json`. This JSON records local defaults, not a
published Remote Config template. Publication evidence is in
[the bounded result](../evidence/cloud/service-flags-publish-2026-11-09.json).
The cloud report upload still awaits Cloudinary credentials/preset and signer deployment; preview PDF generation
remains usable. Publishing flags does not prove device fetch/activation.

Settings → **Tải lại cấu hình** fetches and activates changes. Disabling learning
disables its navigation destination and blocks an already-open catalogue/reader;
weekly progress and journal remain available. Disabling report export disables
its menu entry and rejects new generation. Failed fetches preserve the current
values and show retry. Capture true → false → true behavior without rebuilding.

## Remaining real-environment evidence

- Dedicated Google account: sign-in, cancellation, saved profile/meal/progress
  reload, sign-out and account switching on Firebase.
- Cloudinary credentials/preset, signer deployment and real
  upload/download/progress/failure evidence.
- VAPID/App Check configuration and actual FCM delivery/native permission cases.
- Analytics DebugView, native Crashlytics dashboard and published Remote Config
  before/after evidence.
- ARTEMIS device runs, exploratory session and final report/slides/video.

See [test report](test-report.md) for checks actually executed. Do not mark these
items complete from a build, unit test, emulator rule check or placeholder file.
