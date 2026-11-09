# Code review

## Firebase integration review — 2026-11-09

Independent implementation, QA and review agents inspected the integrated
change. Accepted findings below cover session isolation, privacy, navigation,
recovery and file permissions. These are local review records, not a published
PR review. Separate fix commits and PR line links remain to be produced for the
assignment; no commit or PR was created by this task.

| Finding | Evidence and decision | Applied correction / regression |
| --- | --- | --- |
| F5, P1: preview retained generated personal PDF after sign-out | `SessionFeatures` previously survived local repository clearing and retained report bytes. Accepted: the next preview profile could open the previous report. | [Session key recreation](../lib/app.dart), [actual generate/sign-out/re-onboard test](../test/widget/firebase_features_test.dart). |
| F6, P2: notification navigation could interrupt a busy PDF operation | Direct inbox callbacks could pop the report route during generation/open. Accepted. | [Session route and notification guards](../lib/widgets/session_features.dart); pending notification is reconsidered when report completes. |
| F7, P2: background inbox stayed stale when opened from Home | The notification screen was not mounted when the app resumed, so its lifecycle callback did not run. Accepted. | [Refresh on opening inbox](../lib/widgets/session_features.dart). |
| F8, P2: notification content persisted in URL and replayed after reload | Worker originally placed recipient/title/body JSON in the launch query. Accepted: privacy and repeated-navigation defect. | [Opaque worker lookup](../web/firebase-messaging-sw.js), [capture/remove/consume once](../web/notification-history.js), [six JS regressions](../functions/test/notification-web.test.js). |
| F9, P2: initial-message retry skipped terminated launch | Listener initialization was marked done before `getInitialMessage()` succeeded. Accepted. | [Separate launch-ready flag](../lib/services/notification_service.dart), [failed-first-read retry test](../test/unit/notification_test.dart). |
| F10, P2: synchronous font loading broke PDF generation | Actual preview widget test reproduced an empty `Future.wait` font result. Accepted. | [Sequential font loading](../lib/services/report_service.dart); actual PDF generation passes [integrated widget tests](../test/widget/firebase_features_test.dart). |
| F11, P1: Storage create behavior allowed overwriting an existing report | Emulator exposed overwrite despite no update rule. Accepted. | [Explicit `resource == null`](../firebase/storage.rules), [overwrite-denial emulator test](../functions/test-storage/report-storage.test.js). |

The Storage emulator also showed that reserved download-token metadata cannot
be reliably forbidden by custom-metadata rules. The app deliberately uses
authenticated `getData` and does not obtain/share bearer URLs. The claim that
rules prevent an owner deliberately publishing their own file was rejected and
removed; owner isolation is tested through authenticated Storage access.

Verification: 169 Flutter passes, 2 live AI skips; 18 emulator rule passes;
28 Node passes. The reviewer did not claim real FCM/native/cloud UI behavior.
See [test report](test-report.md) for deployment, builds and remaining evidence.

## Flow 3 review — 2026-11-04

An independent reviewer traced new models, both progress repositories,
LearningViewModel, asset joins, catalogue/reader/progress UI, routing and owner
rules against the actual integrated diff.

- F4 (P2): preview sign-out cleared learning first, then awaited meal/profile
  deletion while navigation could become active again. A new read could survive
  sign-out. A delayed-storage reproduction confirmed the race.
- Fix: a session-wide signing-out state blocks duplicate logout, pointer, focus,
  semantics and back across all three stores, with loading feedback and finally
  restoration. Actual-app regressions cover both slow meal and profile deletion.
- Re-review: the reviewer confirmed the fix and reported no other confirmed
  defect in scope. Coordinator regression tests passed 2/2; final full suite
  passed 144 tests with 2 live skips, and analyzer was clean.

This local review is separate from the wider assignment's later GitHub PR-review
deliverable. It does not establish native-device or real-account cloud behavior.

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
