# Lab 3 requirements and scaffold decisions

Status (2026-11-09): **all three primary flows have Flutter implementations**.
Auth/Firestore, FCM, PDF generation/Cloudinary, Analytics, native Crashlytics
and Remote Config integrations are now present. Completion of the whole Lab 3
still requires the original checklist's live acceptance evidence, ARTEMIS,
AI PR review and final submission artifacts. See [test report](test-report.md)
and [service setup](firebase-services-setup.md).

| Area | Implementation | Remaining evidence / setup |
| --- | --- | --- |
| Flows 1/2/3 | Profile and goals; meal confirmation/analysis/journal; weekly progress and learning | Real-device interactions and design parity; preview evidence is separate |
| Auth/Firestore | Google sign-in and UID-scoped profile/meal/lesson progress | Real-account sign-in, save/reload and switching |
| Cloudinary | Generated personal PDF, signed owner-bound upload, progress/cancel and temporary private download | Credentials/preset and signer deployment missing; live upload/download not verified |
| FCM | Explicit permission, background handlers, bounded UID history, tap destinations and deployed device-token rules | Platform/VAPID prerequisites, foreground/background/terminated delivery and denial evidence |
| Analytics | 16 allowlisted events, fixed flow enum, bounded counts and UID lifecycle | DebugView screenshots and ARTEMIS event assertion |
| Crashlytics | Native handled-error hooks, UID/custom keys and gated debug crash action | Android dashboard evidence for real handled failure and test crash |
| Remote Config | Two Boolean defaults published true; learning/export controls and fetch/retry UI | Real-device fetch and visible before/after plus failure evidence |

On 2026-11-09, Firestore rules deployment/readback matched the local source,
including device-token rules, and both Boolean Remote Config defaults were
published true. Evidence: [readback](../evidence/cloud/firebase-services-readback-2026-11-09.json)
and [publication](../evidence/cloud/service-flags-publish-2026-11-09.json).
Historical Storage readback showed no buckets and billing disabled. The user
subsequently approved Cloudinary; its credentials/preset and signer deployment
remain pending. These observations do not establish real FCM delivery, Remote
Config device fetch or cloud file upload. See the latest
[requirements re-audit](requirements-reaudit.md).

ARTEMIS now has 17 independent cases, each parametrized for three runs. The 25
offline harness tests passed; all 51 device attempts were skipped. The official
SDK SHA and device prerequisites are in [E2E setup](../e2e_test/README.md).
The device-execution and exploration requirements below remain open.

## Source inventory

The four assignment handouts were read in full (69 pages). They stay local in
the Git-ignored `docs/requirements/` directory.

| Local PDF | Pages | Role |
| --- | --- | --- |
| `PRM393 - Lab 3 Cloud-Enabled Mobile App (Firebase, Patrol, AI Code Review).pdf` | 18 | Primary specification; body explicitly requires ARTEMIS |
| `PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf` | 25 | Preparation guide consistent with ARTEMIS |
| `PRM393 - Lab 3 From Design to Working App with Flutter and Firebase.pdf` | 17 | Alternate handout; supporting templates retained, conflicting tool requirements deferred |
| `PRM393 - Final Assignment One Complete System on Firebase.pdf` | 9 | Future assignment context, outside current implementation scope |

The user subsequently supplied a fifth PDF: the 774-page scanned Vietnamese
book *Ăn gì không chết*. Its table of contents (PDF pages 7-8) and selected
source-page offsets were inspected for the Lab 2 flow-3 amendment; a full reading
of the 774 pages is not claimed. See [book curriculum](book-curriculum.md).
The book stays in the same ignored local directory.

## Decisions across handouts

| Area | Selected Lab 3 baseline | Other source / future scope |
| --- | --- | --- |
| Testing | ARTEMIS SDK + pytest in `e2e_test/` (Cloud-Enabled pp.8-10; guide p.23) | From Design pp.9-10 uses MobAI; no competing runner. “Patrol” in the primary filename/header is not its body requirement. |
| Root | `lib/`, `android/` directly at root (Cloud-Enabled pp.10-11) | Final pp.3-6 adds `mobile/`, `web/`, `packages/core/`; defer migration. |
| MVVM | Flat models/services/firebase/viewmodels/screens/widgets/theme/utils (Cloud-Enabled pp.4-6) | Also matches From Design pp.3-4. Replaces empty legacy placeholders. |
| State | Provider 6.1.5+1 selected and used | Preserve the existing injected-service/ViewModel composition. |
| Data | Real Lab 2 source; Firestore when storing user data (Cloud-Enabled p.3) | From Design p.5 mandates Firestore CRUD/two collections; conditional reference here. |
| File storage | Cloudinary authenticated raw PDFs with owner-scoped callable signer (user confirmed instructor acceptance) | Original Cloud-Enabled baseline names Firebase Cloud Storage (p.6; guide pp.8-10); implementation uses the approved alternative. Final assignment scope remains distinct. |
| Submission | Lab03_SE194126 report 8-12 pages, slides 12-15, video 5-10 min (Cloud-Enabled pp.10-12; guide p.25) | Alternate handout has shorter report/video; Final uses different paths/names. |
| Supporting docs | Handoff gaps, design changes, fidelity, AI implementation log, test report retained | No additional MobAI, web admin, or AI product features introduced. |

## Implementation and evidence checklist

The original acceptance checklist is retained below. An unchecked item can have
implemented code; it stays open until its complete implementation **and actual
required evidence** exist. The matrix above records code progress separately.

- [ ] Import approved Lab 2 topic/persona/success criterion/Figma/handoff.
- [ ] Trace and implement every Final UI screen (at least 8) and all 3 flows,
  including alternatives/errors/recovery (Cloud-Enabled pp.2-3).
- [ ] Preserve navigation; add sign-in/profile if absent; explicit loading/data/
  empty/error/retry states and real data on all applicable screens.
- [ ] MVVM with injected services, no SDK calls/business logic in Views (pp.4-5).
- [ ] Theme and reusable components from Lab 2; accessibility at 360/412 dp,
  at least 48 dp targets and 14 sp body text (p.6).
- [ ] Auth: Google sign-in/cancel/sign-out, auth routing, local-state cleanup,
  visible failures and console evidence (p.6; guide pp.5-7).
- [ ] Storage: generated file reflects data, owner path, upload progress/URL,
  owner-only rules and failure evidence (p.6; guide pp.8-10).
- [ ] FCM: Android 13+ permission, foreground/background/terminated reception,
  history, tap navigation, denial/failure handling (p.7; guide pp.11-13).
- [ ] Analytics: plan before code, at least 7 events with types/questions/flow steps,
  user ID, no personal parameters, DebugView evidence (p.7; guide pp.14-16).
- [ ] Crashlytics: real handled error and test crash, user ID/custom key,
  dashboard evidence (p.7; guide pp.17-19).
- [ ] Remote Config: at least 2 defaults changing visible behavior without
  rebuild, before/after and failure evidence (p.7; guide pp.20-22).
- [ ] ARTEMIS: at least 10 independent cases, error/native coverage, observed
  value assertions, analytics check, at least 3 runs each, traces/pass rates/
  flaky explanations, 15-30 min exploration (pp.8-9; guide p.23).
- [ ] AI PR review: at least 5 line-linked findings of at least 2 kinds,
  decisions/reasons, at least 3 accepted fixes in separate linked commits,
  AI tools disclosed (p.10; guide p.24).
- [ ] Real report/slides/video/evidence complete and accessible (pp.11-16).

## Implementation boundaries

The supplied Figma/handoff and source book are the design/content references;
three flow implementations and runtime adaptations are mapped in
[traceability](design-traceability.md). Corresponding runtime additions still
need reconciliation with the source Figma before claiming complete parity.

The configured client project is `vetalife-24f03`; identifiers come from existing
Firebase registration. Firestore device rules and both Remote Config defaults
were deployed/published on 2026-11-09 with readback evidence; no billing upgrade
or app publication occurred. Storage has no bucket and its rules were not
deployed. The user approved Cloudinary as the storage alternative. The Functions
signer still needs Cloudinary credentials and deployment before live upload
acceptance. Historical synthetic AI evidence and current local/cloud checks are
recorded in the [test report](test-report.md).

## Scaffold validation record

Scaffold checks passed: 25 required directories, two Firebase JSON files,
eight documentation-only Python modules, Python >=3.12 in valid TOML, and
26 local Markdown links. All four original PDFs are preserved.
This historical scaffold record is not application, device, Firebase integration
or ARTEMIS execution evidence; later checks are recorded in the test report.

Local Git setup is **complete**, verified after the user performed the repair:

- Repository root: `D:/projects/vetalife`.
- Origin: `https://github.com/kenji-cmyk/PRM393_Lab03_SE194126.git` for fetch/push.
- Branch: `main` tracks `origin/main` with the target repository's existing history.
- `docs/.git` no longer exists; the original metadata is preserved under ignored
  `.local-backup/docs-git-original/`. The earlier byte-verified 28-file ZIP backup
  remains at `.local-backup/docs-git-before-root-setup.zip`.
- All five current PDF paths (four handouts and the book) pass
  `git check-ignore --no-index`.
  Root `.gitignore` and `docs/.gitignore` keep these local references excluded.
- Temporary extraction tools/files and Git backups remain ignored.

The historical Git setup verification did not publish changes to GitHub.
Subsequent application implementation and validation are recorded separately.
