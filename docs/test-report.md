# Test report

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
| Date and app revision | Pending |
| App package / build | Pending |
| Flutter / Dart | Pending |
| ARTEMIS commit / SDK version | Pending selection |
| Python / pytest versions | Pending |
| Device model / serial / Android version | Pending |
| Firebase project | Pending |
| Test account alias (no credentials) | Pending |
| Profile and non-secret configuration | Pending |
| Exact execution command and exit status | Pending |
| Starting state / seed data / reset procedure | Pending |

## Results by case

Use the IDs from [the test plan](test-plan.md). Run each case at least three times and link all individual runs. A skipped case is not a pass.

| Test ID | Runs completed | Passes / runs | Pass rate | Average duration | Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| No cases executed | 0 | Not applicable | Not measured | Not measured | Pending | None |

## Individual run record

| Test ID / run | Initial state | Observed structured values | Expected values | Result and duration | Trace ID / screenshot / replay | Analytics evidence, if applicable |
| --- | --- | --- | --- | --- | --- | --- |
| Pending | Pending | Pending | Pending | Pending | Pending | Pending |

Store artifacts in `evidence/artemis/runs/`. Preserve the agent's original result and relevant captured output so assertions can be checked independently.

## Failed, flaky, skipped, or blocked checks

| Test ID | Classification | Actual observation / reason | Root cause investigation | Fix or next step | Rerun evidence |
| --- | --- | --- | --- | --- | --- |
| Pending | Pending | Pending | Pending | Pending | Pending |

Any case below 3/3 needs investigation. Distinguish an app defect, timing problem, ambiguous instruction, unavailable environment, and a deliberate skip.

## Firebase behavior and failure evidence

| Service | Successful behavior | Failure / denial / cancellation behavior | Evidence | Status |
| --- | --- | --- | --- | --- |
| Authentication | Pending | Pending | Pending | Not verified |
| Cloud Storage | Pending | Pending | Pending | Not verified |
| Cloud Messaging | Pending | Pending | Pending | Not verified |
| Analytics | Pending | Pending | Pending | Not verified |
| Crashlytics | Pending | Pending | Pending | Not verified |
| Remote Config | Pending | Pending | Pending | Not verified |

## Exploratory session

| Field | Recorded value |
| --- | --- |
| Charter / app revision | Pending |
| Start / end / duration (15–30 minutes required) | Not performed |
| ARTEMIS profile | Pro, pending execution |
| Screens / flows explored | Pending |
| Observations and issues | Pending |
| Evidence | Pending; reserve `evidence/artemis/exploratory/` |

## Remaining coverage

All functional, native-interaction, Analytics, accessibility, and Firebase checks remain pending until the app and actual cases exist. Scaffold validation performed during setup must be reported separately from app test results.

Sources: Cloud-Enabled Mobile App handout, pp. 8–9 and 14; preparation guide, p. 23.
