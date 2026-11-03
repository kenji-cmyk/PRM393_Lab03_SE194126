# Evidence

Status: directories only. No Firebase behavior, test result, or code review finding is evidenced yet.

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
