# Test plan

Status: planning template. Lab 2 screen/flow details, application behavior, test data, and executable cases are pending. This file does not claim test coverage has been implemented.

## Test boundaries

| Level | Location | Intended purpose | Status |
| --- | --- | --- | --- |
| Unit | `test/` | ViewModel state transitions and service behavior with fakes | Pending |
| Widget | `test/` | Shared components, screen states, and accessibility semantics | Pending |
| Android E2E | `e2e_test/` | Critical flows through the real app with ARTEMIS | Pending |
| Service failure/security checks | Record below and in the test report | Cancellation, network failure, denied access, and fallback behavior | Pending |

ARTEMIS is the confirmed E2E choice, following the Cloud-Enabled handout and preparation guide v5. No Patrol or MobAI runner is planned. Cloud Storage follows this Lab 3 baseline; Firestore checks will be added if required by the Lab 2 data model.

## Flow and screen mapping

Fill this from the approved Lab 2 handoff before authoring test instructions. Cover all three Lab 2 flows, including alternatives and error/recovery paths, and every relevant screen.

| Lab 2 flow | Goal/success criterion | Screens/routes | Test IDs | Test data/initial state |
| --- | --- | --- | --- | --- |
| Pending Lab 2 handoff | Pending | Pending | Pending | Pending |

## ARTEMIS case template

Author at least 10 independent cases. Replace the template row with real cases; a template is not a test case.

| ID | Flow | Preconditions and reset | Natural-language instruction | Observable expected result / structured values | Type | Implementation |
| --- | --- | --- | --- | --- | --- | --- |
| Pending | Pending | Account state, device, seed data, network, app location | Starting point, actions, and exact visible end state | Values to compare with known expectations | Happy / alternative / error / native | Pending |

Required coverage checklist, all currently pending:

- Every Lab 2 user flow end to end, including alternative and error/recovery paths.
- Google sign-in and sign-out, including cancellation and protected access.
- Main search or primary action, every top-level destination, and every kind of detail screen.
- Generated file export and upload, with progress, final URL, and failure feedback.
- Remote Config values on screen and a visible behavior change without a new build.
- At least one error-path case and one Android native interaction, such as the account picker or notification permission dialog.
- At least one case that verifies its Analytics event through captured Logcat or DebugView.
- Notification handling in foreground, background, and terminated states, including tap navigation and permission denial.
- Visible handling of failures from each integrated Firebase service.

## Execution protocol

1. Record the app revision, Flutter/Dart versions, pinned ARTEMIS commit, Python/pytest versions, device serial/model, Android version, Firebase project, and actual execution command.
2. Use a dedicated Google test account. Keep credentials and model API keys in local environment configuration.
3. Set up each case from its documented precondition so cases do not depend on execution order.
4. Use the Flash profile for regression. Ask the agent for structured observed values and assert those values, in addition to successful execution status. Key widgets need meaningful Semantics labels.
5. Run every case at least three times. Report runs, pass rate, average duration, and evidence for every run. Investigate any result below 3/3 and distinguish product defects, timing, and ambiguous instructions.
6. Record failed and skipped cases honestly with reasons and follow-up work in [the test report](test-report.md).

## Exploratory session

Plan one unscripted session using the ARTEMIS Pro profile for 15–30 minutes. Record its charter, configuration, duration, observations, issues, and evidence in [the test report](test-report.md). Status: not performed.

## Accessibility and fidelity checks

Repeat the Lab 2 checklist on the running app: contrast, touch targets of at least 48 dp, body text of at least 14 sp, no meaning conveyed only by color, and layouts at 360 dp and 412 dp. Compare Figma and app screenshots at matching dimensions. These checks are pending until screens exist.

Sources: Cloud-Enabled Mobile App handout, pp. 6–9, 14, and 17; preparation guide, pp. 4 and 23.
