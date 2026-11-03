# ARTEMIS end-to-end tests

Status: structure only. No test cases, ARTEMIS client fixture, or device runs have been implemented. The `test_*.py` modules currently contain documentation only; pytest will collect no tests. An empty collection is not a passing suite.

Google ARTEMIS with pytest is the confirmed E2E choice, following the Cloud-Enabled Mobile App handout and preparation guide v5. The word Patrol in one PDF filename does not establish a separate Patrol suite. The other Lab 3 document's MobAI workflow is reference material; no MobAI runner is scaffolded here.

## Reserved suites

| Module | Future scope |
| --- | --- |
| `conftest.py` | Shared ARTEMIS client configuration: device serial, profile, and isolated starting state |
| `test_auth.py` | Google sign-in, cancellation, protected access, and sign-out |
| `test_navigation.py` | Top-level destinations and Back behavior from the Lab 2 prototype |
| `test_flows.py` | Every Lab 2 flow, including alternative and recovery paths |
| `test_detail.py` | Each kind of detail screen and its observable data |
| `test_export.py` | Generated file, upload progress, success/error feedback, and resulting URL |
| `test_profile.py` | Profile, notification center, and Remote Config behavior |
| `test_artemis_smoke.py` | Existing reserved smoke-test module; not an implemented test |

Write actual cases after the Lab 2 screens, flows, test data, and expected outcomes are available. Map each function to an ID in [the test plan](../docs/test-plan.md).

## Setup still required

1. Prepare Python 3.12+, uv, ADB, and an Android device/emulator.
2. Select and record an exact ARTEMIS commit and its supported SDK setup. Pin the versions actually used; `pyproject.toml` currently lists only the initial pytest dependency.
3. Implement the client fixture with a device serial and the Flash profile for regression tests. Use Pro for the exploratory session.
4. Provide a dedicated Google test account and model API key through local environment configuration. Never commit their credentials.
5. Implement independent cases with documented initial state and assertions on structured values reported by the agent, rather than checking `SUCCESS` alone.

No device-run command is prescribed yet because the SDK and fixture have not been selected. Once implemented, record the exact command, versions, device, and configuration in [the test report](../docs/test-report.md).

## Required evidence

- At least 10 cases covering all Lab 2 flows, sign-in/out, primary action, tabs, detail screens, export/upload, and Remote Config.
- At least one error path, one Android native interaction, and one verification of an Analytics event.
- At least three runs per case, with pass rate, average duration, and a trace ID, screenshot, or replay for every run.
- An explanation and investigation for every flaky, failed, or skipped case.
- One 15–30 minute exploratory session in the Pro profile, with its findings.

Store run artifacts in `evidence/artemis/runs/` and exploratory artifacts in `evidence/artemis/exploratory/`. These directories are placeholders until real runs occur.

Sources: Cloud-Enabled Mobile App handout, pp. 8–10 and 17; preparation guide, pp. 2 and 23.
