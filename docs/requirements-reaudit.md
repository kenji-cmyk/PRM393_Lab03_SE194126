# Requirements re-audit — 2026-11-09

Verdict: **not yet complete against the selected Lab 3 acceptance criteria**.
Primary sources are the Cloud-Enabled handout and Preparation Guide v5 in
`docs/requirements/`. The user approved Cloudinary as the file provider.
The alternate MobAI handout and future Final Assignment are distinct scopes.

## Re-executed checks

| Check | Result | Evidence |
| --- | --- | --- |
| Flutter unit/widget suite | 169 passed, 2 live AI tests skipped | [log](../evidence/builds/reaudit-flutter-final.log) |
| Flutter analyzer | No issues | [log](../evidence/builds/reaudit-analyze-final.log) |
| Functions syntax + Node tests | Passed; 28/28 | Executed `npm run check` and `npm test` in `functions/` |
| Firestore + legacy Storage rules | 18/18 on disposable demo project | [log](../evidence/builds/reaudit-rules.log) |
| ARTEMIS offline harness / device cases | 25 passed; 51 device attempts skipped | [log](../evidence/builds/reaudit-artemis-final.log) |
| Web cloud build | Exit 0; built `build/web` | [log](../evidence/builds/reaudit-web.log) |
| Android cloud debug APK | Exit 0; built `build/app/outputs/flutter-apk/app-debug.apk` | [log](../evidence/builds/reaudit-android.log) |

Storage rule tests validate the retained Firebase Storage implementation; they
do **not** validate Cloudinary access control or uploads. The Node suite does not
exercise a live Cloudinary upload either. Initial local attempts failed because
of sandbox access to SDK/Java/temp folders; final reruns above passed outside
the sandbox. ADB lists no devices and the installed emulator reports no AVDs.
Web build warns about WASM dry-run incompatibilities and an optional Cupertino
font reference; the JavaScript web build succeeds. Android emits upstream
native-access/Kotlin plugin migration warnings but assembles successfully.
No new manual browser or authenticated/device acceptance run is claimed.

## Outstanding acceptance requirements

| Requirement | Current evidence / missing work |
| --- | --- |
| All three flows, UI states and accessibility | Flutter implementations and local unit/widget checks exist; real device and complete Figma parity evidence remain open |
| Google Auth + Firestore | Live sign-in/cancel/save/reload/sign-out/account switching evidence missing |
| Cloudinary upload | Credentials, signed preset and signer deployment missing; real upload/download, cancellation/failure and cross-user denial unverified |
| FCM | Foreground/background/terminated reception, notification tap and permission denial need live platform evidence |
| Analytics | DebugView event evidence and actual device ARTEMIS event assertion missing |
| Crashlytics | Actual handled error + test crash with UID/custom key dashboard evidence missing |
| Remote Config | Defaults published previously; device fetch and visible true/false behavior without rebuild unverified |
| ARTEMIS | 17 cases × 3 defined; none run on a device. Missing traces, actual pass rates, flaky analysis and 15–30 minute exploration |
| AI PR review | Local findings exist; missing PR line links/output and at least three accepted fixes in separate linked commits |
| Design parity | Notifications/report/settings additions still need Figma synchronization and reviewed deviations |
| Submission | Missing report PDF (8–12 pages), slides PDF (12–15), video (5–10 minutes) |

The audit fixed `EXPORT-02`'s obsolete expected `gs` scheme to `cloudinary`.
This fixes the assertion contract; it does not turn a skipped device case into
a passed one. No billing change, deployment or real-user data mutation occurred.
