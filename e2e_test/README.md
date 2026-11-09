# ARTEMIS Android E2E

The suite now implements **17 independent cases, each parametrized for three runs**.
Device execution is opt-in. Without configuration, all 51 device attempts are
**skipped**, not passed. Offline harness tests validate strict observations,
timeout cancellation, evidence, endpoint handling and Analytics log matching.
No Android or model run has been performed by adding this suite.

SDK: official `google/artemis`, commit
`351ca8422f7b5b54e80a9c1ce03a222e02415b6b`, package `artemis-client` 0.1.0.
The exact commit is pinned in the `live` optional dependency in `pyproject.toml`.
The daemon should use the same commit. APIs were checked against the pinned
[SDK README](https://github.com/google/artemis/blob/351ca8422f7b5b54e80a9c1ce03a222e02415b6b/packages/artemis-client/README.md),
[client](https://github.com/google/artemis/blob/351ca8422f7b5b54e80a9c1ce03a222e02415b6b/packages/artemis-client/src/artemis_client/client.py)
and [result model](https://github.com/google/artemis/blob/351ca8422f7b5b54e80a9c1ce03a222e02415b6b/packages/artemis-client/src/artemis_client/models.py).

## Install and validate offline

Use Python 3.12+ in a local environment:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -e ./e2e_test
.\.venv\Scripts\python.exe -m pytest e2e_test -q
```

The SDK is not installed by the offline dependency group. Install it only when
preparing an authorized device/model run:

```powershell
.\.venv\Scripts\python.exe -m pip install -e './e2e_test[live]'
```

The daemon is **not** installed or started by the tests. Prepare it separately
from the pinned official source, with its model credentials outside this repo.
The remote client has no runtime dependencies and uses HTTP; do not expose an
unauthenticated daemon publicly. Use a local SSH tunnel, or an authenticated
HTTPS proxy with `ARTEMIS_TOKEN` in local environment configuration.

## Preview device run

Install a preview Android build for `vn.edu.fpt.vetalife` on a dedicated test
device. The existing preview profile, meals and lesson progress will be cleared
through the application's sign-out action before each independent case. This is
why the explicit reset acknowledgment below is required.

```powershell
$env:RUN_ARTEMIS = '1'
$env:ARTEMIS_ALLOW_TEST_RESET = '1'
$env:ARTEMIS_BASE_URL = 'http://127.0.0.1:8000'
$env:ARTEMIS_DEVICE_SERIAL = 'emulator-5554' # replace with actual selected device
$env:ARTEMIS_TEST_MODE = 'preview'
.\.venv\Scripts\python.exe -m pytest e2e_test -m artemis -q
```

Only preview cases execute in this mode; cloud cases report mode skips. Every
preview case begins from welcome, then creates its own synthetic profile when
needed. It never depends on a meal/read marker left by a prior case.
Do not run parallel workers against the same device.

## Cloud and native prerequisites

Use a cloud debug Android build and dedicated Firebase test account already
available in the Android account picker. Set `ARTEMIS_TEST_MODE=cloud` and
`ARTEMIS_TEST_ACCOUNT_ALIAS` to the visible dedicated account label. The agent
must not enter passwords, create accounts, change billing, publish Remote
Config or send push notifications. Complete App Check setup separately.
The setup flags below acknowledge **real prerequisites**, not successful tests:

| Case | Additional local environment prerequisite |
| --- | --- |
| EXPORT-02 | `ARTEMIS_STORAGE_READY=1`: configured bucket/rules and enabled report feature |
| NOTIFY-01 | `ARTEMIS_NOTIFICATION_PERMISSION_FRESH=1`: Android 13+, notification permission undecided before **each** repetition |
| CONFIG-02 | `ARTEMIS_REMOTE_CONFIG_DISABLED_READY=1`: operator pre-publishes both `learning_enabled=false` and `report_export_enabled=false` on isolated test project |
| ANALYTICS-01 | `ARTEMIS_ANALYTICS_LOG`: existing file receiving a continuous **fresh** device Logcat stream with Firebase Analytics debug events |

Run CONFIG-02 separately after the normal enabled-feature cases. Restore the
isolated project's flags afterward. No tests change Remote Config remotely.
For NOTIFY-01 the operator must restore the native permission precondition
between repetitions; three runs do not assume a denied permission becomes
undecided automatically. An absent OS dialog causes a failure, not a fake pass.

Enable Analytics debugging for the dedicated device using the documented
Firebase command, then capture Logcat continuously into a local ignored file:

```powershell
adb -s <serial> shell setprop debug.firebase.analytics.app vn.edu.fpt.vetalife
adb -s <serial> logcat -v time FA:V FA-SVC:V '*:S' > tmp/analytics-logcat.txt
```

Set `ARTEMIS_ANALYTICS_LOG` to that file's absolute path in the pytest shell.
The harness remembers its byte offset **before** the task and checks only new
lines for the exact `meal_entry_start` event and Firebase tag. Existing logs or
an agent's success claim cannot satisfy this check. Disable debug collection
after testing using `setprop debug.firebase.analytics.app .none.`.
Do not commit raw logs or real account screenshots.

## Assertions and evidence

The runner uses the supported `submit(..., expected_output=...,
enable_outputter=True)` and `wait_for_task(...)` methods, checks
`TaskResult.succeeded`, then parses `TaskResult.output` as an observed JSON
object. Boolean, integer and string fields must match the authored values and
types. Malformed output and `SUCCESS` alone fail. The prompt requests field
types; expected values remain in Python assertions.

Each attempted task writes case ID, repetition, duration, SDK commit, task/trace
ID, expected/observed allowlisted fields and failure kind beneath
`evidence/artemis/runs/<UTC-session>/`. The original trace remains on the daemon
for review/replay; export its screenshots/replay separately when available.
Failed or timed-out tasks retain evidence, and unfinished tasks receive a stop
request. No raw SDK payloads, tokens or account IDs are written by the harness.
`pytest-summary.json` records every skip/failure/pass and per-case rates; all
skips produce `null` pass rate and duration. Skips are never counted as passes.

The offline fake transport tests are **not device evidence**. Native camera,
FCM foreground/background/terminated delivery, real cloud errors, full service
dashboards, and the required 15-30 minute Pro exploratory session still require
actual authorized runs and evidence. The present suite does not claim those
requirements are completed. See [the plan](../docs/test-plan.md) and
[test report](../docs/test-report.md).
