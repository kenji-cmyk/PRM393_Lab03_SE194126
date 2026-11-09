# Firebase setup for VetaLife

Status (2026-11-09): all three flows have Flutter code, including Google Sign-In,
Firestore profile/journal/read progress, opt-in FCM, personal PDF generation and
Cloudinary report upload, 16 Analytics actions, native Crashlytics and two Remote
Config gates. See [service setup](firebase-services-setup.md) for the additional
services. Implementation is not live-cloud acceptance evidence.

Client configuration targets `vetalife-24f03`; Android ID is `vn.edu.fpt.vetalife`.
On **2026-11-09**, Firestore rules were deployed and production readback matched
the local file, including FCM device rules. Both Boolean Remote Config keys were
published with defaults `true`. See [readback](../evidence/cloud/firebase-services-readback-2026-11-09.json)
and [publication](../evidence/cloud/service-flags-publish-2026-11-09.json).

Readback confirmed billing disabled and no Storage buckets. The user later
approved Cloudinary for PDF uploads. **Cloudinary credentials/preset and the
Firebase Functions signer are not configured/deployed yet**; local PDF
generation/export remains available. No billing upgrade occurred. Device rules
and published flag values are configuration evidence, not actual device
reception/fetch evidence.

Real-account sign-in/save/reload/account switching, three-state push reception,
private Cloudinary upload/denial, DebugView, Crashlytics dashboard and visible Remote
Config before/after changes still need live evidence. Checks actually executed
are recorded in [test report](test-report.md).

## Run without Firebase

```powershell
flutter pub get
flutter run -d chrome --dart-define=APP_MODE=preview
```

Preview is the default and visibly identifies device-only storage. Profiles,
meals and read progress are local; sign-out clears them. Preview generates PDFs
locally without upload and does not send Analytics or simulate incoming push.
Preview data is not automatically migrated to cloud.

## Complete Firebase client configuration

1. Use the registered project `vetalife-24f03`, or deliberately configure a
   separate project for testing. Enable Google in Authentication and provision
   Firestore. Keep production rules restrictive.
2. The registered Android app uses `vn.edu.fpt.vetalife`; web has its own app
   registration. Official client options are in `lib/firebase_options.dart` and
   Android's `android/app/google-services.json`. These are public client
   identifiers, not service-account credentials. Do not invent or commit secrets.
3. If registrations change, install/login to Firebase CLI and FlutterFire CLI as
   appropriate, then run `flutterfire configure` for the intended project and
   platforms. Preserve the repository's Gradle plugins and pinned dependencies;
   review generated changes rather than replacing build files blindly.
4. Get the debug variant's SHA-1/SHA-256 from `android`:

   ```powershell
   .\gradlew.bat signingReport
   ```

   Register the actual variant fingerprint in Firebase, enable Google Sign-In,
   and download/regenerate official configuration. Native `google_sign_in`
   requires the web OAuth client in `google-services.json`; an Android OAuth ID
   is not a substitute server client ID.
5. For web, add the testing domain to Authentication authorized domains,
   including `localhost` when needed. Web uses a Firebase popup; Android uses the
   native Google account picker.
6. Firestore rules including `users/{uid}/devices` were deployed and read back
   on Nov 9. For later changes or another project, validate with emulators before
   deployment. Storage rules remain local: there is no bucket, and cloud upload
   is deferred under the user's Spark decision. Follow
   [service setup](firebase-services-setup.md). Index deployment is separate.
7. Run cloud mode:

   ```powershell
   flutter run --dart-define=APP_MODE=cloud
   ```

   Cloud failures are visible and never silently fall back to preview. For a
   release APK use `flutter build apk --release --dart-define=APP_MODE=cloud`
   only after configuration. The current release build still uses the template's
   debug signing; configure release signing/fingerprints before distribution.

## AI Logic and App Check

Firebase AI Logic has historical synthetic healthcheck, analysis and OCR evidence
from 2026-11-04. It uses the Gemini Developer API on supported Spark quotas; no
Gemini secret or Functions deployment is needed for this path. Temporary tokens
used for those checks were revoked. This evidence does not establish real-meal
accuracy, camera behavior, device SDK attestation or the complete account flow.

Android debug requires that device's registered App Check debug UUID; release
and profile use Play Integrity. Web requires the registered reCAPTCHA provider
and public `FIREBASE_APP_CHECK_WEB_SITE_KEY`. Localhost debug also requires
`APP_CHECK_WEB_DEBUG=true` and its registered debug token. Do not use a Gemini
API key in place of the reCAPTCHA site key. See [Flow 2 setup](flow2-setup.md).

From the repository root, register the UUID copied from the running app's log:

```powershell
& .\tool\register_app_check_debug.ps1 -Platform android -DisplayName 'VetaLife my-android'
# Use -Platform web for the browser UUID.
```

The tool prompts with hidden input; never paste debug tokens into chat or commit
them. Restart the app after registration. Revoke temporary registrations when
finished. Source options and signing details must match the actual device build.

## Data and permissions

| Path / value | Contract |
| --- | --- |
| `users/{uid}` | Atomic profile/goal document owned by the authenticated UID |
| `displayName` | Trimmed string |
| `birthDate` | Calendar date `YYYY-MM-DD`, not converted to UTC |
| `weightKg`, `heightCm` | Finite positive numbers |
| `goal` | `addVegetables`, `recordMeals`, or `readDaily` |
| `updatedAt` | Server timestamp |
| `users/{uid}/meals/{id}` | Owner journal; stable IDs make retry/update idempotent |
| `users/{uid}/lessonProgress/{lessonId}` | Owner read progress for validated lesson IDs |
| `users/{uid}/devices/{encodedToken}` | FCM token/platform/server timestamp; owner rules deployed/read back Nov 9 |
| `reports/{uid}/{generatedId}.pdf` | Private PDF, generated filename/type and 10 MiB cap; upload deferred/no bucket; rules not deployed |
| `learning_enabled`, `report_export_enabled` | Remote Config booleans published true Nov 9; device fetch unverified |

Age is derived from birth date rather than persisted separately. UID comes from
authentication, never form input. Profile list/delete is denied. Model/ViewModel
validation complements rules: calendar validity and future-date checks run in
client code; rules restrict payload shape/ownership.

Profile reads require the server so network failure is not mistaken for a new
account. Errors retain input for retry. A write timeout does not cancel an
already submitted write; late completion is possible. Firestore disk persistence
is disabled, and cloud sign-out drops session ViewModels without deleting cloud
documents. Preview sign-out does delete its local preview data.

Cloud PDF locations are authenticated `gs://` references with authenticated
download, not public bearer download URLs. Analytics allows fixed enums/bounded
counts and the session UID, never profile/meal text or raw exception payloads.
Native Crashlytics does not support web. FCM tokens are sensitive: do not expose
them in public logs. Notification payloads must use generic public content.

## Live acceptance after setup

- Cancel/retry the Google picker or popup; confirm visible recovery.
- New account: complete welcome/profile/goals and verify the matching Firestore
  document, home name and goal.
- Save a meal and read progress; reload/relogin and verify the same saved values.
- Switch accounts; verify no previous account UI data, inbox or generated PDF.
- Disconnect network during reads/writes; check error/retry and retained draft.
- Sign out; return to sign-in while cloud documents remain intact.
- Complete service-specific success/denial/background/failure checks in
  [service setup](firebase-services-setup.md), preserving actual evidence.

This is an acceptance checklist, not a claim that those checks have passed.
