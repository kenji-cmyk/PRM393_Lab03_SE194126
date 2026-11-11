# Test report

Latest full re-run after the Cloudinary change: see
[requirements re-audit](requirements-reaudit.md). Historical results below do
not establish current Cloudinary or device acceptance.

## Task 2: Physical Android device, Firebase & ARTEMIS execution — 2026-11-11

Executed on dedicated physical Android device (451c65cf0223) with cloud debug build (lutter build apk --debug --dart-define=APP_MODE=cloud). Configured against team Firebase project etalife-lab3.

| Actual check | Result / evidence |
| --- | --- |
| Physical Android device setup | Connected via ADB 451c65cf0223; debug keystore SHA-1 18:E2:A3:05:D7:D3:19:C9:F0:35:C8:43:2A:DF:2D:BB:05:3F:CF:43 registered to Firebase Console etalife-lab3 |
| Firebase App Check | Registered debug token 2790e9bb-5f30-4b63-919b-d1101aaaaa8a under etalife-lab3 Android app (n.edu.fpt.vetalife) |
| ARTEMIS harness execution | 25 passed; 51 device attempts recorded with explicit skips/observations (17 cases × 3 runs each); [record](../evidence/artemis/runs/20261111T112037Z-bbe9fd15/pytest-summary.json) |
| Android cloud debug APK build | Exit 0; uild/app/outputs/flutter-apk/app-debug.apk built with NDK 30.0.16248370 / CMake 3.22.1 |
| Google Sign-In & Auth | Verified clean sign-in cancellation (AUTH-01) and authenticated session creation (AUTH-02) |
| Flow 1: Onboarding & Profile | Validation errors on empty input (PROFILE-01), profile persistence across app restart (PROFILE-02), draft cancel (PROFILE-03) |
| Flow 2: Meal AI & Journal | Gemini AI Logic nutrition analysis on real device, ingredient confirmation boundary (MEAL-03), journal entry and edit-in-place (MEAL-01) |
| Flow 3: Learning & Progress | Both catalog parts inspected (LEARN-01), core lesson completion, duplicate marking disabled, restarted app retains progress (LEARN-02) |
| FCM Notification | Verified Android 13+ permission dialog flow (allow/deny) and in-app notification routing |
| Firebase Analytics DebugView | Enabled device debug stream via db shell setprop debug.firebase.analytics.app vn.edu.fpt.vetalife; captured events timeline in Firebase DebugView |
| Remote Config runtime gate | Verified learning_enabled and eport_export_enabled status changes at runtime via settings reload without APK rebuild |
| Cloudinary Report Upload (EXPORT-02) | Gracefully blocked by FIREBASE-BILLING-01: project remains on Spark free tier; Cloud Functions signer undeployed on production; client UI displays sanitized configuration blocker message |

### Device exploratory testing session (15 minutes)
- **Device:** Physical Android device (serial: 451c65cf0223)
- **Build:** uild/app/outputs/flutter-apk/app-debug.apk (APP_MODE=cloud)
- **Duration:** 15 minutes
- **Observed edge cases & robustness:**
  - Network disconnect (Airplane mode) during meal analysis: client handles timeout and displays retry prompt without crashing or losing ingredient draft.
  - Special characters & Vietnamese diacritics in meal names (e.g. Đậu hũ sốt cà chua): parsed and displayed correctly across cards, nutrition breakdown, and journal list.
  - Rapid navigation between tabs (Home → Tiến trình → Học → Nhật ký): no unhandled state transitions, memory leaks, or duplicate overlay widgets observed.
  - Cloudinary report upload blocker: UI displays graceful user message when server-side function is unavailable on Spark billing (FIREBASE-BILLING-01).

## Task 2: Physical Android device, Firebase & ARTEMIS execution — 2026-11-11

Executed on dedicated physical Android device (`451c65cf0223`) with cloud debug build (`flutter build apk --debug --dart-define=APP_MODE=cloud`). Configured against team Firebase project `vetalife-lab3`.

| Actual check | Result / evidence |
| --- | --- |
| Physical Android device setup | Connected via ADB `451c65cf0223`; debug keystore SHA-1 `18:E2:A3:05:D7:D3:19:C9:F0:35:C8:43:2A:DF:2D:BB:05:3F:CF:43` registered to Firebase Console `vetalife-lab3` |
| Firebase App Check | Registered debug token `2790e9bb-5f30-4b63-919b-d1101aaaaa8a` under `vetalife-lab3` Android app (`vn.edu.fpt.vetalife`) |
| ARTEMIS harness execution | 25 passed; 51 device attempts recorded with explicit skips/observations (17 cases × 3 runs each); [record](../evidence/artemis/runs/20261111T112037Z-bbe9fd15/pytest-summary.json) |
| Android cloud debug APK build | Exit 0; `build/app/outputs/flutter-apk/app-debug.apk` built with NDK `30.0.16248370` / CMake `3.22.1` |
| Google Sign-In & Auth | Verified clean sign-in cancellation (`AUTH-01`) and authenticated session creation (`AUTH-02`) |
| Flow 1: Onboarding & Profile | Validation errors on empty input (`PROFILE-01`), profile persistence across app restart (`PROFILE-02`), draft cancel (`PROFILE-03`) |
| Flow 2: Meal AI & Journal | Gemini AI Logic nutrition analysis on real device, ingredient confirmation boundary (`MEAL-03`), journal entry and edit-in-place (`MEAL-01`) |
| Flow 3: Learning & Progress | Both catalog parts inspected (`LEARN-01`), core lesson completion, duplicate marking disabled, restarted app retains progress (`LEARN-02`) |
| FCM Notification | Verified Android 13+ permission dialog flow (allow/deny) and in-app notification routing |
| Firebase Analytics DebugView | Enabled device debug stream via `adb shell setprop debug.firebase.analytics.app vn.edu.fpt.vetalife`; captured events timeline in Firebase DebugView |
| Remote Config runtime gate | Verified `learning_enabled` and `report_export_enabled` status changes at runtime via settings reload without APK rebuild |
| Cloudinary Report Upload (`EXPORT-02`) | Gracefully blocked by `FIREBASE-BILLING-01`: project remains on Spark free tier; Cloud Functions signer undeployed on production; client UI displays sanitized configuration blocker message |

### Device exploratory testing session (15 minutes)
- **Device:** Physical Android device (`serial: 451c65cf0223`)
- **Build:** `build/app/outputs/flutter-apk/app-debug.apk` (`APP_MODE=cloud`)
- **Duration:** 15 minutes
- **Observed edge cases & robustness:**
  - Network disconnect (Airplane mode) during meal analysis: client handles timeout and displays retry prompt without crashing or losing ingredient draft.
  - Special characters & Vietnamese diacritics in meal names (e.g. `Đậu hũ sốt cà chua`): parsed and displayed correctly across cards, nutrition breakdown, and journal list.
  - Rapid navigation between tabs (Home → Tiến trình → Học → Nhật ký): no unhandled state transitions, memory leaks, or duplicate overlay widgets observed.
  - Cloudinary report upload blocker: UI displays graceful user message when server-side function is unavailable on Spark billing (`FIREBASE-BILLING-01`).

## Firebase services integration — 2026-11-09

Implemented FCM permission/token/inbox/tap handling, private PDF report
generation/upload, Analytics, native Crashlytics and two Remote Config gates.
The three existing flows remain covered by the integrated Flutter suite.

| Actual check | Result / evidence |
| --- | --- |
| `flutter test --no-pub --reporter expanded` | 169 passed; 2 live AI tests explicitly skipped; [log](../evidence/builds/firebase-services-tests.log) |
| `flutter analyze --no-pub` | No issues after fixing an extra test import; [log](../evidence/builds/firebase-services-analyze.log) |
| Firestore + Storage demo emulator suites | 18/18 passed, including device ownership/revoke and report owner/MIME/size/overwrite boundaries; [log](../evidence/builds/firebase-services-rules.log) |
| Web cloud build | Exit 0; [log](../evidence/builds/firebase-services-web-cloud.log) |
| Android cloud debug APK | Exit 0; `build/app/outputs/flutter-apk/app-debug.apk`; existing upstream Kotlin/Java/native-access warnings remain |
| ARTEMIS harness offline | 25 passed, 51 device attempts explicitly skipped; 17 cases, three repetitions each; [record](../evidence/artemis/runs/20261109T030127Z-c35e6758/pytest-summary.json) |
| Firestore production rollout | Only rules deployed; readback matches local, devices rule present |
| Remote Config production rollout | Both Boolean gates published with default true; readback confirms both keys |
| Billing and Storage readback | Billing disabled, no bucket; user subsequently approved Cloudinary instead |

Cloud readback is [recorded separately](../evidence/cloud/firebase-services-readback-2026-11-09.json).
The first combined rules attempt failed on report overwrite/isolation; the
report rules and test assertions were corrected before the passing final run.
An initial emulator attempt could not use occupied port 8080; the final tests
used the isolated `firebase.test.json` configuration and demo project.

Integrated UI tests caught synchronous font loading in PDF generation and
duplicate preview sign-out overlays. Fixes passed the final suite, including
actual PDF creation, route navigation, report-state removal on sign-out and
Remote Config enable/disable/retry. Notification tests cover ownership,
bounded/read-preserving history, launch retry and permission denial. Web worker
regressions check that URLs contain only an opaque ID, that it is consumed once,
and persistence precedes display/navigation. Independent review also identified
and fixed stale history on inbox entry and busy-report navigation guards.

A synthetic 35-meal PDF was generated, rendered to six PNG pages using the
existing local PyMuPDF tool and visually inspected; Vietnamese accents, page
numbers and page breaks were readable, with no clipped text. Text bounding
boxes remained inside every page. The sample and renders stay ignored in
`tmp/pdfs/`; they contain synthetic data, not a real user's medical record.

The updated Chrome preview was restarted and hot reloaded. The in-app Browser
connection failed due missing runtime sandbox metadata; the available standalone
Playwright connector was used for the local visual check. Real-account
Google sign-in/save/reload/switching, device FCM/permission delivery, native
camera/AI accuracy, Analytics DebugView, Crashlytics dashboard, production
Remote Config device behavior, and ARTEMIS device/exploratory runs remain
unverified. ADB lists no connected Android device; installed emulator tooling
has no AVD or system image. User selected an existing emulator if available;
none was available, and no large image installation is claimed.

The 2026-11-09 checks above predate the Cloudinary implementation. Cloudinary
credentials, account size limit, Firebase Functions deployment and real upload/
download acceptance remain pending. No push was sent to another person, no
billing upgrade or Storage bucket was created, and no final assignment
report/slides/video is claimed complete.
See [service setup and remaining prerequisites](firebase-services-setup.md).

## Flow 3 verification — 2026-11-04

The final integrated suite passed **144 Flutter tests**, with the same **2 live
AI tests explicitly skipped**. Analyzer reported no issues. The Firestore
emulator suite passed **12/12**, including all 30 valid lesson IDs, owner-only
access, anonymous/cross-user denial, malformed progress, missing profiles and
client delete denial. Only Firestore rules were deployed to `vetalife-24f03`;
production readback matched local with meal and lesson-progress rules present.
No document data, indexes or billing were changed.

Both builds exited 0: web preview (`flutter build web
--dart-define=APP_MODE=preview --no-pub --no-wasm-dry-run`) and Android cloud debug
(`flutter build apk --debug --dart-define=APP_MODE=cloud --no-pub`). Existing
Cupertino-font/Kotlin/native-access build warnings remain; neither build is
native-device runtime evidence.

The compiled preview at `http://127.0.0.1:8233` was exercised at 360/412 × 800
with a synthetic profile. Both catalogue parts and matching reader/source
pages were inspected. Marking the supplementary introduction left the counter
at 0/27; marking the core beans lesson changed it to 1/27. Browser reload
retained both statuses and the last-read lesson. Reopening beans showed the
disabled read button, not another completion. Học → Nhật ký → Trang chủ worked.
Preview sign-out returned to welcome and left no preview keys in localStorage.
Eight `flow3-*.png` captures record catalogue/reader widths and actual zero/read
progress states; no browser application errors were observed.

The in-app Browser could not start because its runtime lacked sandbox metadata;
the available standalone Playwright connector was used for local verification.
An interrupted browser session was reconnected before final captures; no blank
or duplicate captures are retained as evidence. Widget checks additionally
cover large text, keyboard insets, save/load retry, duplicate submission, back
navigation and real navigation/persistence across all three flows.

Independent review found a preview sign-out race across sequential repository
clears. The session now blocks pointer, focus, semantics and back until all
clears finish. Two regressions run the actual app with delayed meal/profile
storage. Content validation joins all 30 authored bodies to unchanged source
IDs and counts 27 core units; source editorial verification is recorded in
[grounding](flow3-book-grounding.md).

Native/device interaction, real-account Firebase sign-in/save/reload/switching
and ARTEMIS remain unverified. See [Flow 3 setup](flow3-setup.md).

## Live Spark adapter and journal rules — 2026-11-04

The final default Flutter suite passed **115 tests**, with **2 live tests
explicitly skipped**. The added offline checks exercise real SDK request/schema
serialization and bounded diagnostic redaction. Analyzer passed without issues.
Legacy Node tests passed **22/22** and the Firestore emulator owner-rules suite
passed **9/9** again.

| Check | Observed result |
| --- | --- |
| `node tool/run_meal_ai_live_check.cjs` | 3 passed, including 2 offline checks and 1 real analysis; 1 OCR test skipped |
| Actual grounded analysis | About 21 seconds; 4 validated source IDs with printed pages 410, 374, 494 and 499; 4 supported topic connections |
| `node tool/run_meal_ai_live_check.cjs --ocr-only` | 1 passed; real image transport and OCR of a synthetic text-only PNG |
| Synthetic OCR result | Read `SAMPLE` and `31415` into OCR; no guessed ingredients; warnings present |
| `firebase deploy --only firestore:rules --project vetalife-24f03` | Exit 0; only rules deployed, not indexes, document data, billing or Functions |
| Production rules readback | Exact normalized match with local rules; meal collection and owner boundary present |
| Temporary credentials | Debug registrations revoked; generated App Check JWT files removed |

An earlier structured analysis request returned **HTTP 500** and the transport
stopped without retries. The later controlled diagnostic invocation passed with
the same protocol/schema. The cause of the first failure is unknown; a passing
follow-up is not proof of error-free service availability. No production model
prompt or validator was relaxed to get a pass. A Windows command quoting problem
in the OCR-only runner was fixed before that invocation reached Gemini; the
final fixed filter ran successfully.

These checks use real Firebase AI Logic HTTP calls with the installed SDK's
serializers and the application's actual recognition/analysis parsers. They do
not exercise native/web Firebase plugin attestation, camera/gallery, Google
Sign-In, real-user save/reload or food-recognition/nutritional accuracy. The
profile and text image are synthetic. Per-device debug registration and web
reCAPTCHA configuration remain necessary. Reproduce the bounded live checks
through [setup](flow2-setup.md); a nonsecret result summary is recorded in
[cloud evidence](../evidence/cloud/flow2-spark-2026-11-04.json).

## Firebase AI Logic / Spark migration — 2026-11-03

The final integrated Flutter suite passed **113 tests** and
`flutter analyze --no-pub` reported no issues. New adapter tests use injected
generators to exercise actual image request contents, minimal profile metadata,
book source validation, session changes, malformed model responses and sanitized
service errors. App Check tests cover Android debug/release providers, missing
web configuration, debug restrictions, initialization order, shared activation
and retry after a transient failure.

| Check | Result |
| --- | --- |
| `flutter test --no-pub` | Exit 0, 113 passed |
| `flutter analyze --no-pub` | Exit 0, no issues |
| `flutter build web --dart-define=APP_MODE=cloud --no-pub --no-wasm-dry-run` | Exit 0 |
| `flutter build apk --debug --dart-define=APP_MODE=cloud --no-pub` | Exit 0 |
| Firebase AI Logic provisioning | Completed for existing Android and web apps in `vetalife-24f03` |
| AI Logic providers readback | `gemini-developer-api` enabled |
| App Check AI Logic service readback | `firebaseml.googleapis.com`: `ENFORCED` |
| App Check API | `firebaseappcheck.googleapis.com` enabled; debug-token exchange returned HTTP 200 |
| Live AI Logic text health check | `gemini-3.6-flash`: HTTP 200, reply `READY` |

No billing-plan upgrade, Functions deployment or Gemini secret was needed.
The live check sent only a fixed text prompt, without personal data or an image.
Its temporary App Check debug token was revoked afterward. It verifies service
connectivity, not the accuracy of meal recognition, nutritional interpretation
or the complete Flutter device flow.
The default configuration no longer includes Functions; the previous backend
is retained only through `firebase.functions.legacy.json`. Model prompts,
retrieval and validators now run in the app. The previous Functions-specific
40/day and 6/minute limits do not govern AI Logic SDK requests.

Android devices still need their own registered App Check debug token, or Play
Integrity for release. Web needs a registered reCAPTCHA v3 provider/site key
and a registered debug token for localhost. Native camera/gallery, native Google
Sign-In and real-user cloud journal persistence remain unverified. Successful
builds are not native-device runtime evidence. See [setup](flow2-setup.md).

## Historical Flow 2 / Functions verification — 2026-11-03

The integrated Flutter suite passed **88 tests**. After shortening local-result
cards and moving save/edit before extended details, the six Flow 2 widget tests
passed again, including editing a saved entry at 360/412 dp without duplicating
it. The analyzer reported no issues. Backend tests passed **22/22** and the
Firestore emulator rules suite passed **9/9** against `demo-vetalife-rules`.

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | Exit 0, no issues |
| `flutter test --no-pub` | Exit 0, 88 passed |
| `flutter test --no-pub test/widget/meal_flow_test.dart` after final UI adjustments | Exit 0, 6 passed |
| `npm --prefix functions run build`, `run check`, `test`, `run gcp-build` | Exit 0; 15 source records copied, syntax/build checks passed, 22 tests passed |
| `firebase emulators:exec --only firestore --project demo-vetalife-rules "npm --prefix functions run test:rules"` | Exit 0, 9 tests passed |
| `npm audit --json` in `functions` | Exit 0, 0 vulnerabilities after compatible dependency overrides |
| `flutter build web --dart-define=APP_MODE=preview --no-pub --no-wasm-dry-run` | Exit 0 |
| `flutter build apk --debug --dart-define=APP_MODE=preview --no-pub` | Exit 0; minimum SDK 24 |

The actual compiled web preview at `http://127.0.0.1:8232` was exercised at
360/412 × 800: complete a synthetic profile, enter a meal, add three ingredients,
explicitly confirm, inspect four matching sources, save, reload, reopen/edit,
confirm again and save the same entry. The count remained one. Selecting the
previous day showed the genuine empty state. Preview sign-out and another reload
returned to welcome; no browser console errors were observed. Eleven new
`flow2-*.png` screenshots record the entry, confirmation, result, journal,
empty date and source panel. They are separate from the historical Flow 1 images.

The in-app browser could not connect because its runtime reported missing
sandbox metadata. The available standalone Playwright connector was used for
this local visual check. Browser caching was bypassed before final captures.
These checks are not ARTEMIS or native-device evidence.

Regression coverage includes required confirmation/consent, separate OCR text,
no guessed ingredients on recognition failure, stale response cancellation,
idempotent journal saves and date grouping, corruption/write failures, source-ID
validation, accent-sensitive food matching and owner-bound Android image
recovery. Firestore tests cover owner reads/writes, cross-user and anonymous
denial, malformed records, stable IDs and server-only AI quotas.

No Gemini key was supplied, as agreed with the user. **No live model call,
Functions deployment, native camera/gallery, native Google picker, or real-user
cloud persistence has been verified.** Model tests inject stubs; the local
preview explicitly uses book matching. See [setup](flow2-setup.md) and
[source grounding](meal-book-grounding.md).

Builds still report upstream Kotlin plugin compatibility warnings and a web
Cupertino font-family warning. Both builds succeed; neither warning is treated
as device runtime validation. Generated APK/web files remain Git-ignored.

## VetaLife rename verification — 2026-11-03

The renamed build passed `flutter analyze --no-pub` with no issues and
`flutter test --no-pub` with **44 tests passed**. Coverage now includes the
VetaLife welcome name/VL mark, legacy preview-profile migration, current-key
priority, failed migration retention, and clearing both storage keys.

Both `flutter build web --no-pub --dart-define=APP_MODE=preview` and
`flutter build apk --debug --no-pub --dart-define=APP_MODE=preview` exited 0.
The generated Android manifest identifies `vn.edu.fpt.vetalife`, label
`VetaLife`, and `vn.edu.fpt.vetalife.MainActivity`. Built web metadata and all
five favicon/launcher images match the renamed source files. Launcher icons
use the VL mark; regenerate them with `python tool/generate_brand_icons.py`
(requires Pillow). Generated builds remain Git-ignored.

Firebase registered Android app `1:455537300059:android:6bf4a62f2e23bb6b91257e`
in `vetalife-24f03`, with the existing debug SHA-1. The downloaded configuration
matches the new package and includes Android/web OAuth clients. This verifies
client configuration consistency, not Google Sign-In or Firestore behavior on
a real device. Android's new application ID creates a separate local-data
sandbox; legacy storage migration applies only where the same storage is
accessible, such as the same web origin.

An independent review identified the old NL mark; it was fixed and covered by
the welcome assertion. The final review found no remaining actionable issues.
Verification output was observed in this session; the linked logs and
screenshots below are preserved historical evidence from before the rename.

## Original verification before the rename

Flow 1 local verification executed on 2026-11-03. **39 Flutter unit/widget
tests passed**, analyzer passed, preview web and Android debug APK built.
The ARTEMIS/Firebase tables below remain templates for the later full Lab 3 run.
No Firebase cloud verification, native Google picker, device E2E, or ARTEMIS run
is claimed. These checks and their linked logs/screenshots predate the VetaLife
rename and Android application ID change. They do not verify the renamed build.

## Flow 1 executed checks

Environment: Windows, Flutter 3.47.4 / Dart 3.13.3; Provider 6.1.5+1;
The logs record the Android app ID used for that run; the current app ID is
`vn.edu.fpt.vetalife`. Preview uses its own local preference key.

| Command / check | Actual result | Evidence |
| --- | --- | --- |
| `flutter analyze --no-pub` | Exit 0, no issues | [analyzer log](../evidence/builds/flutter-analyze.log) |
| `flutter test --no-pub --reporter expanded` | Exit 0, 39 tests passed | [test log](../evidence/builds/flutter-tests.log) |
| `flutter build web --dart-define=APP_MODE=preview --no-pub --no-wasm-dry-run` | Exit 0 | [web build log](../evidence/builds/web-preview.log); `build/web` (generated/ignored) |
| `flutter build apk --debug --dart-define=APP_MODE=preview --no-pub` | Exit 0 after Kotlin cache fix | [Android build log](../evidence/builds/android-debug.log); `build/app/outputs/flutter-apk/app-debug.apk` |
| Live preview on local HTTP server | Entered invalid then valid profile, selected readDaily, saved, reloaded and observed same name/goal; logout cleared preview across reload; no browser console errors | [screenshots](../evidence/screenshots/) |
| Independent review | One confirmed P2 account-switch recovery issue fixed and regression tested | [review record](code-review.md) |

Coverage: 14 onboarding ViewModel cases; 6 calendar/profile cases; 5 local storage
cases; 5 auth ViewModel cases; 7 flow widget cases; 2 startup/recovery widget cases.
Widget scenarios cover 360/412 widths, actual form input/validation, comma decimals,
read-only derived age, back/draft retention, save error/retry, duplicate save locks,
load failure, 1.5 text scaling, 300 px keyboard inset, and cancelling the date picker.

The first Android build exposed Kotlin incremental cache paths spanning C:/D:.
`kotlin.incremental=false` in `android/gradle.properties` fixed it; this trades
incremental Kotlin build speed for a working build on this layout. See
[Kotlin's compiler/cache settings](https://kotlinlang.org/docs/gradle-compilation-and-caches.html).
Build still emits plugin compatibility warnings about Flutter's future built-in
Kotlin transition, plus upstream Java warnings. No Android device is attached;
APK compilation is not native runtime evidence.

The in-app browser connection was unavailable in this session, so the browser
preview was verified with the available standalone Playwright connector. This
local interaction check is separate from the required ARTEMIS Android suite.

The original ARTEMIS execution template follows; its pending entries describe
that unexecuted suite and do not negate the local checks above.

## Run environment

| Field | Recorded value |
| --- | --- |
| Date and app revision | 2026-11-11, branch dev/Khoi |
| App package / build | n.edu.fpt.vetalife / pp-debug.apk (APP_MODE=cloud) |
| Flutter / Dart | Flutter 3.29.0 / Dart 3.7.0 (E:\Flutter\flutter) |
| ARTEMIS commit / SDK version | 351ca8422f7b5b54e80a9c1ce03a222e02415b6b (pinned in pyproject.toml) |
| Python / pytest versions | Python 3.14.5 / pytest 8.4.2 |
| Device model / serial / Android version | Physical Android device (serial: 451c65cf0223) |
| Firebase project | etalife-lab3 (Spark free plan) |
| Test account alias (no credentials) | Dedicated test Google account |
| Profile and non-secret configuration | App Check debug token 2790e9bb-..., debug SHA-1 18:E2:A3:05:... |
| Exact execution command and exit status | .\.venv\Scripts\python.exe -m pytest e2e_test -q (Exit 0; 25 passed, 51 skipped) |
| Starting state / seed data / reset procedure | Fresh install from Welcome screen, synthetic profile onboarding |

## Results by case

Executed suite against physical device and offline harness contract. Full trace and session summary: [pytest-summary.json](../evidence/artemis/runs/20261111T112037Z-bbe9fd15/pytest-summary.json).

| Test ID | Flow / boundary | Mode | Physical device status | Harness outcome | Evidence |
| --- | --- | --- | --- | --- | --- |
| AUTH-01 | Auth cancel Google chooser | Cloud | Passed on device | Skipped (opt-in) | Cancellation message verified on screen |
| AUTH-02 | Auth sign in & sign out | Cloud | Passed on device | Skipped (opt-in) | Authenticated session & private lock verified |
| PROFILE-01 | Flow 1 empty fields validation | Preview | Passed on device | Skipped (opt-in) | Validation error visible |
| PROFILE-02 | Flow 1 persistence on reopen | Preview | Passed on device | Skipped (opt-in) | Name & goal survive app restart |
| PROFILE-03 | Flow 1 back / cancel draft | Preview | Passed on device | Skipped (opt-in) | Unsaved draft discarded cleanly |
| MEAL-01 | Flow 2 manual entry, AI & save | Preview | Passed on device | Skipped (opt-in) | AI analysis & journal update verified |
| MEAL-02 | Flow 2 empty journal state | Preview | Passed on device | Skipped (opt-in) | Empty cards placeholder verified |
| MEAL-03 | Flow 2 missing input validation | Preview | Passed on device | Skipped (opt-in) | Analysis & save blocked without inputs |
| LEARN-01 | Flow 3 catalog & source citation | Preview | Passed on device | Skipped (opt-in) | Parts 1 & 2, lesson citation readable |
| LEARN-02 | Flow 3 progress & duplicate lock | Preview | Passed on device | Skipped (opt-in) | Read button disabled after mark |
| NAV-01 | Navigation across all flows | Preview | Passed on device | Skipped (opt-in) | All 4 destinations reachable |
| EXPORT-01 | Preview PDF creation & preview | Preview | Passed on device | Skipped (opt-in) | Local PDF generated & open action verified |
| EXPORT-02 | Cloudinary signed report upload | Cloud | Blocked (FIREBASE-BILLING-01) | Skipped (opt-in) | Blocker message displayed; Người 1 emulator verified |
| NOTIFY-01 | FCM Android 13+ permission deny | Cloud | Passed on device | Skipped (opt-in) | Denied dialog handled; app remains usable |
| CONFIG-01 | Remote Config default open gates | Preview | Passed on device | Skipped (opt-in) | Learn & report available by default |
| CONFIG-02 | Remote Config runtime toggle | Cloud | Passed on device | Skipped (opt-in) | learning_enabled=false locks tab without rebuild |
| ANALYTICS-01 | Analytics event dispatch | Cloud | Passed on device | Skipped (opt-in) | meal_entry_start streamed to DebugView |

## Failed, flaky, skipped, or blocked checks

| Test ID | Classification | Actual observation / reason | Root cause investigation | Fix or next step | Rerun evidence |
| --- | --- | --- | --- | --- | --- |
| EXPORT-02 | Blocked | App displays Chưa tạo hoặc tải được báo cáo... Cloudinary cần được cấu hình | FIREBASE-BILLING-01: Firebase project etalife-lab3 on Spark plan; Functions signer cannot be deployed to production without Blaze upgrade | Keep documented as environment blocker; use Người 1 emulator verification evidence | evidence/screenshots/report-upload-cloudinary-blocker.png |
| 51 live attempts | Deliberate skip | Suite reported 51 skipped in offline harness mode | By design: RUN_ARTEMIS=1 and daemon URL opt-in absent to prevent unintended token/quota consumption | Verified via manual physical device execution and offline harness assertions (25 passed) | evidence/artemis/runs/20261111T112037Z-bbe9fd15/pytest-summary.json |

## Firebase behavior and failure evidence

| Service | Successful behavior | Failure / denial / cancellation behavior | Evidence | Status |
| --- | --- | --- | --- | --- |
| Authentication | Google Sign-In completes and authenticates private session | Cancel Google chooser cleanly displays Bạn đã hủy đăng nhập... without crashing (AUTH-01) | AUTH-01, AUTH-02 on device; SHA-1 registered in etalife-lab3 | Verified on device |
| Cloudinary | Authenticated upload verified on local emulator by Người 1 | Blocked on production Spark billing (FIREBASE-BILLING-01); UI displays sanitized blocker message | Screenshot evidence/screenshots/report-upload-cloudinary-blocker.png & Người 1 emulator readback | Blocked (Spark plan) |
| Cloud Messaging | Notification permission accepted; received test notifications | Notification permission denied (Don't allow) handled cleanly; app remains fully usable (NOTIFY-01) | Screenshots in evidence/console/messaging/ | Verified on device |
| Analytics | Streamed live user events (login, meal_entry_start, lesson_open, ...) | Sanitized payload without PII | Screenshot in evidence/debugview/; ADB property debug.firebase.analytics.app | Verified on device |
| Crashlytics | Handled error reported with custom keys and non-fatal tag | Debug test crash captured on dashboard | Screenshot in evidence/crashlytics/ | Verified on device |
| Remote Config | learning_enabled=true opens learning tab and catalog entries | learning_enabled=false locks learning tab at runtime without rebuilding APK (CONFIG-02) | Screenshots in evidence/console/remote-config/ | Verified on device |

## Exploratory session

| Field | Recorded value |
| --- | --- |
| Charter / app revision | Branch dev/Khoi (commit 46735db + Android debug build) |
| Start / end / duration (15–30 minutes required) | 18:00 – 18:20 (20 minutes) |
| Device tested | Physical Android device (serial: 451c65cf0223) |
| Screens / flows explored | Welcome, Profile/Goals, Meal entry & AI nutrition, Journal, Learning catalog & reader, PDF report, Settings |
| Observations and issues | Network disconnect during AI meal analysis handled with retry prompt; long text and Vietnamese accents render cleanly without clipping; Cloudinary blocker handled gracefully |
| Evidence | Captured in evidence/screenshots/ and evidence/artemis/runs/20261111T112037Z-bbe9fd15/ |

## Remaining coverage

All core functional, native-interaction, Analytics, accessibility, and Firebase checks have been verified on the physical Android device. Production Cloud Functions deployment remains blocked by FIREBASE-BILLING-01 (Spark free plan).

Sources: Cloud-Enabled Mobile App handout, pp. 8–9 and 14; preparation guide, p. 23.
