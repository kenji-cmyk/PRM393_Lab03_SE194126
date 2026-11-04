# Code review

## App Check tooling review — 2026-11-04

An independent reviewer reproduced a P2 issue in the PowerShell registration
helper: with `ErrorActionPreference=Stop`, native stderr can throw before exit
code handling and expose raw CLI output. The invocation is now caught locally
and rethrows a fixed message without the native ErrorRecord. Mocked CLI runs on
Windows PowerShell 5.1 verified stderr redaction, suppressed stdout, a display
name containing spaces and restored experiment settings. The reviewer confirmed
the fix and found no additional blocker in the bounded live runner/test.

Live model checks subsequently passed for synthetic grounded analysis and
text-image OCR. They are separate from device UI/attestation evidence; see the
[test report](test-report.md).

## Firebase AI Logic / Spark review — 2026-11-03

An independent reviewer inspected the integrated AI Logic adapter, App Check
bootstrap, dependency/config changes and their tests. One confirmed P2 issue
was fixed: Firebase Core Web can restore a cached App Check provider during
initialization, so setting the debug flag only before explicit activation was
too late. The bootstrap now sets the opt-in debug flag before initializing
Firebase. A regression checks the order: debug flag, Firebase initialization,
App Check activation. The reviewer confirmed the fix without additional
confirmed findings. Final analyzer and all 113 Flutter tests passed.

The review does not turn client-side prompt/citation checks into server-side
enforcement. AI Logic access relies on App Check and provider quotas; Firestore
owner rules continue to govern the journal. Real device attestation and meal
recognition accuracy require separate runtime validation.

## Flow 2 review and fixes — 2026-11-03

An independent read-only review covered Flutter state/session boundaries,
Gemini contracts, source retrieval, image recovery and Firestore owner rules.

- F2 (P2): removing Vietnamese accents could map `nước me` to sesame (`mè`).
  Fixed matching in Dart and Node to preserve accented distinctions, with
  conservative fallback for unaccented multiword aliases. Regressions check
  tamarind/sesame and butter/beef distinctions.
- F3 (P2): native lost-image recovery is app-wide and could expose account A's
  pending photo to account B. Added a pending owner marker, discard-on-mismatch,
  and preview sign-out cleanup. Six recovery tests cover account/preview
  isolation, missing ownership and matching recovery.
- QA additionally reproduced sign-out during pending initialization restoring
  an old photo. Capturing the operation generation before the journal await
  prevents the stale initialization from recovering it afterward.

These findings were fixed and regression-tested. The final source review was
completed locally; the assignment's separate GitHub PR review remains pending.
No live Gemini/native-device safety or accuracy claim follows from these tests.

## Historical Flow 1 review

Status: Flow 1 received an independent Codex review on 2026-11-03. One confirmed
finding was fixed and tested. This local review is separate from the required
GitHub PR review with at least five findings and linked fix commits; no PR/commit
has been created in this implementation task.

## Flow 1 independent review

- Tool: Codex `wf_reviewer`, separate read-only agent from the implementation agents.
- Scope: app/bootstrap/auth, owner-bound Firestore adapter and rules, profile/date
  validation, lifecycle/disposal, preview storage, screen state and tests.
- Finding F1 (P2, recovery): `lib/screens/flow_screen.dart`, error stage originally
  exposed only retry. An authenticated user facing persistent permission/network
  errors could not sign out or switch accounts before reaching Home.
- Decision: accepted. Cloud-only sign-out now remains available during loading,
  welcome, profile, goals and error. It is disabled during profile saving. Preview
  retains its local-only behavior.
- Evidence: `test/widget_test.dart` verifies error-stage retry plus sign-out;
  `test/unit/auth_view_model_test.dart` covers auth routing, cancellation/retry,
  duplicate sign-in prevention, failure visibility and sign-out failure recovery.
- Re-review: finding resolved; no additional confirmed defect introduced by the fix.
  Focused reviewer run passed 7 tests; coordinator's complete suite passed 39.
- Remaining validation: real Firebase setup/rules emulator, native account picker
  and device behavior. No cloud/live-account result is inferred from fake-service tests.

The full-assignment PR-review template remains below for future execution.

## Review scope

| Field | Recorded value |
| --- | --- |
| Pull request / base and head revisions | Pending |
| Review date | Pending |
| AI review tool and version/configuration | Pending |
| Files reviewed | Pending |
| Original tool output | Pending; reserve `evidence/code-review/` |

Review a pull request with an AI code review tool. Record at least five findings tied to file and line, covering at least two categories: bug, security, architecture, performance, test gap, or maintainability. Inspect relevant Firebase rules and failure handling as part of the review.

## Findings and decisions

The row below is a template, not a finding. Retain the original tool output, then judge each suggestion independently.

| ID | Tool | File:line | Category | Severity (own judgment) | Finding | Decision | Technical reason | Fix commit / evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pending | Pending | Pending | Pending | Pending | Pending | Accepted / modified / rejected | Cite a requirement, measurable effect, or actual constraint | Pending |

Fix at least three accepted findings, each in a separate commit that names its finding ID, and link the commits here. No fix commits are required or claimed during this structure-only setup.

## Verification after fixes

| Finding ID | Check / exact command | Actual result and exit status | Evidence | Remaining limitations |
| --- | --- | --- | --- | --- |
| Pending | Pending | Not run | Pending | Pending |

## Tool disclosure

Disclose every AI tool used for implementation, tests, documentation, and slides, together with its actual purpose. The project-wide implementation log and root README should carry the complete disclosure; this record must identify the tool that performed each review.

Sources: Cloud-Enabled Mobile App handout, pp. 9–10, 15, and 17–18; preparation guide, p. 24.
