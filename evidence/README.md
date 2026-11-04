# Evidence

Status: Flow 2 VetaLife browser captures are in `screenshots/flow2-*.png`.
Local analyzer, Flutter/backend/rules checks and successful web/APK builds are
recorded in [the test report](../docs/test-report.md). A
[nonsecret cloud-check summary](cloud/flow2-spark-2026-11-04.json) records live
Spark adapter analysis, synthetic-image OCR and production journal-rules readback.
Native device/attestation and real-account sign-in/save/reload remain pending.

Historical flow-1 browser captures are in `screenshots/`; original test and Android
build logs are in `builds/`. Captured 2026-11-03 on local web preview at 360/412×800.
Names/dates/measurements in captures are synthetic test input. See
[test report](../docs/test-report.md) and [review record](../docs/code-review.md).
The wider Firebase/device/ARTEMIS evidence remains pending; the folders below describe the
wider assignment evidence plan.

The original flow-1 logs and screenshots predate the VetaLife rename and Android ID change.
They remain records of those original runs and do not verify the renamed build.

| Directory | Evidence to capture during implementation |
| --- | --- |
| `console/authentication/` | Signed-out/signed-in states and Firebase Authentication Users |
| `console/storage/` | Generated file in Storage, per-user path, and access-denied checks |
| `console/messaging/` | Test push received in foreground, background, and terminated states; permission handling |
| `console/remote-config/` | Published parameters and before/after behavior without rebuilding |
| `debugview/` | Every planned Analytics event and its parameters |
| `crashlytics/` | Real handled error and deliberate test crash, including user ID and custom keys |
| `artemis/runs/` | Per-run traces, screenshots/replays, and captured Analytics output where relevant |
| `artemis/exploratory/` | The 15–30 minute exploratory session and observed issues |
| `screenshots/app/` | Actual screens, loading/empty/error states, and accessibility width checks |
| `screenshots/figma/` | Lab 2 reference screens at the same size for fidelity comparison |
| `code-review/` | Original AI review output and screenshots linked to findings and fixes |

Use stable filenames containing the case or finding ID and run number where applicable. Link artifacts from the relevant `docs/` record rather than claiming a result from a placeholder directory. Record the capture date, app revision, device, and Firebase project for reproducibility; remove credentials and other secrets from captured output.

Sources: Cloud-Enabled Mobile App handout, pp. 6–11 and 14–16; preparation guide, pp. 7–25.
