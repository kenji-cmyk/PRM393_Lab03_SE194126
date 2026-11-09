# Test plan

Status: three Flutter flows and Firebase integrations now have unit/widget and
rules checks. The ARTEMIS suite implements 17 independent scenario contracts
with three repetitions each. **Actual Android ARTEMIS runs remain unperformed**;
offline skips or harness passes do not establish mobile behavior.

## Boundaries

| Level | Location | What it establishes |
| --- | --- | --- |
| Dart unit/widget | `test/` | ViewModel state, UI navigation and failures using injected services |
| Firestore/Storage emulator | `functions/test-rules/`, `functions/test-storage/` | Ownership, malformed payloads, upload constraints; no production-device claim |
| ARTEMIS Android | `e2e_test/` | Real installed app, native interaction, explicit observations and daemon trace IDs |
| Live Firebase/device | Evidence referenced in test report | Real sign-in, persistence, notification delivery and service dashboards |

Primary baseline remains Cloud-Enabled Lab 3 + Preparation Guide v5. No Patrol
or MobAI runner is substituted. The source SDK is pinned to official
`google/artemis` commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`.

## Implemented ARTEMIS contracts

All preview scenarios independently sign out, start at welcome, and create a
synthetic profile when needed. Cloud scenarios use an explicitly selected test
account and documented per-case prerequisites. No scenario relies on a prior
scenario's profile, meal or read marker.

| ID | Flow/boundary | Action and observed assertions | Mode |
| --- | --- | --- | --- |
| AUTH-01 | Auth/native/error | Cancel Google chooser; cancellation visible, remains signed out | Cloud |
| AUTH-02 | Auth | Sign in dedicated account then sign out; private home inaccessible | Cloud |
| PROFILE-01 | Flow 1/error | Submit empty required fields; validation visible and no home | Preview |
| PROFILE-02 | Flow 1/persistence | Saved synthetic name/goal survive app reopen | Preview |
| PROFILE-03 | Flow 1/back | Unsaved name survives goals/back; cancel keeps saved home name | Preview |
| MEAL-01 | Flow 2 | Manual ingredients, explicit confirmation, analyze, save/edit same record; count remains one | Preview |
| MEAL-02 | Flow 2/empty | Empty journal and zero saved cards | Preview |
| MEAL-03 | Flow 2/error | Missing name/confirmation blocks analysis and saving | Preview |
| LEARN-01 | Flow 3/detail | Both catalogue parts, actual lesson body, source page and Back | Preview |
| LEARN-02 | Flow 3/progress | Supplementary read counts zero core; beans counts one; duplicate mark disabled; reopen retains one | Preview |
| NAV-01 | All flows | Home/progress/learn/journal/home, actual zero weekly meals | Preview |
| EXPORT-01 | PDF | Data-derived PDF completion and open action; no cloud upload | Preview |
| EXPORT-02 | Storage/native | Upload completion, private gs scheme, authenticated PDF preview | Cloud |
| NOTIFY-01 | FCM/native/error | Android 13+ dialog appears, denial visible, app remains usable | Cloud |
| CONFIG-01 | Remote Config defaults | Learning/report default open and entry points available | Preview |
| CONFIG-02 | Remote Config remote | Operator-published false flags fetched; both features visibly blocked without rebuild | Cloud |
| ANALYTICS-01 | Analytics/Flow 2 | Entry form visible plus exact event in independently captured new Firebase Logcat lines | Cloud |

See `e2e_test/cases.py` for exact goals and typed assertions;
`e2e_test/README.md` for environment, prerequisite reset and run commands.
Each case has three parametrized attempts. Missing device/configuration means
explicit skip; a configured but unavailable device or failed assertion fails.
No test daemon or paid model is started automatically.

## Evidence and reliability protocol

1. Record revision, SDK commit, Python/pytest, Android model/version, installed
   build mode, device alias and non-secret project configuration.
2. Select a dedicated account/device. Read and acknowledge the reset behavior.
   Native permission must be reset between NOTIFY-01 repetitions; disabled
   Remote Config is tested separately from enabled report/learning cases.
3. Run every applicable case three times. Compare structured observed values,
   not only the daemon's success status. Preserve trace IDs and export daemon
   screenshots/replays where available.
4. Keep `evidence/artemis/runs/<session>/` case JSON and pytest summary. Rates
   exclude skipped attempts; all-skipped rates remain null. Investigate every
   failure/flaky result and explain incomplete case prerequisites.
5. Analytics requires a fresh continuous Logcat capture; stale lines are rejected.
   Do not commit raw logs, tokens, credentials or real account screenshots.

## Required live work still pending

- Full real-account Firebase sign-in, owner save/reload and account switching.
- Camera/gallery on Android, recognition failure and genuine meal analysis.
- FCM foreground, background, terminated delivery, notification tap routing,
  token rotation and cross-account cleanup; NOTIFY-01 covers permission only.
- Cloudinary signed upload/failure and owner-checked private PDF reopen.
- Analytics DebugView evidence, Crashlytics handled error/test crash and dashboard,
  Remote Config before/after/failure evidence.
- A 15-30 minute ARTEMIS Pro exploratory session with actual observations,
  duration, screenshots/replay, issues and follow-up decisions.
- Final accessibility and Figma comparison on device at 360/412 dp, large text,
  48 dp touch targets and 14 sp body text. Widget coverage alone is insufficient.

Use `docs/test-report.md` for executed results. Authored scenarios are not an
assertion that these live checks have passed.
