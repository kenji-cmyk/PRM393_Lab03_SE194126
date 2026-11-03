# Test report

Status: Flow 1 local verification executed on 2026-11-03. **39 Flutter unit/widget
tests passed**, analyzer passed, preview web and Android debug APK built.
The ARTEMIS/Firebase tables below remain templates for the later full Lab 3 run.
No Firebase project, native Google picker, device E2E, or ARTEMIS run is claimed.

## Flow 1 executed checks

Environment: Windows, Flutter 3.47.4 / Dart 3.13.3; Provider 6.1.5+1;
Android app ID `vn.edu.fpt.nep_lanh`. Preview uses its own local preference key.

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
