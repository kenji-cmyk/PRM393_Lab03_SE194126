# Lab 3 requirements and scaffold decisions

Status: **preparation only**. The user selected Cloud-Enabled + Preparation Guide
v5 as the primary baseline. Reserved paths do not imply completed features/tests.

## Source inventory

All four original PDFs were read in full (69 pages). They stay local in the
Git-ignored `docs/requirements/` directory.

| Local PDF | Pages | Role |
| --- | --- | --- |
| `PRM393 - Lab 3 Cloud-Enabled Mobile App (Firebase, Patrol, AI Code Review).pdf` | 18 | Primary specification; body explicitly requires ARTEMIS |
| `PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf` | 25 | Preparation guide consistent with ARTEMIS |
| `PRM393 - Lab 3 From Design to Working App with Flutter and Firebase.pdf` | 17 | Alternate handout; supporting templates retained, conflicting tool requirements deferred |
| `PRM393 - Final Assignment One Complete System on Firebase.pdf` | 9 | Future assignment context, outside current implementation scope |

## Decisions across handouts

| Area | Selected Lab 3 baseline | Other source / future scope |
| --- | --- | --- |
| Testing | ARTEMIS SDK + pytest in `e2e_test/` (Cloud-Enabled pp.8-10; guide p.23) | From Design pp.9-10 uses MobAI; no competing runner. “Patrol” in the primary filename/header is not its body requirement. |
| Root | `lib/`, `android/` directly at root (Cloud-Enabled pp.10-11) | Final pp.3-6 adds `mobile/`, `web/`, `packages/core/`; defer migration. |
| MVVM | Flat models/services/firebase/viewmodels/screens/widgets/theme/utils (Cloud-Enabled pp.4-6) | Also matches From Design pp.3-4. Replaces empty legacy placeholders. |
| State | Choose one of Provider/Riverpod during setup | No arbitrary dependency installed for a folder-only task. |
| Data | Real Lab 2 source; Firestore when storing user data (Cloud-Enabled p.3) | From Design p.5 mandates Firestore CRUD/two collections; conditional reference here. |
| File storage | Firebase Cloud Storage, generated file and per-user path (Cloud-Enabled p.6; guide pp.8-10) | From Design pp.5-6 allows alternatives; Final p.3 excludes Cloud Storage. Do not mix assignment scopes. |
| Submission | Lab03_SE194126 report 8-12 pages, slides 12-15, video 5-10 min (Cloud-Enabled pp.10-12; guide p.25) | Alternate handout has shorter report/video; Final uses different paths/names. |
| Supporting docs | Handoff gaps, design changes, fidelity, AI implementation log, test report retained | No additional MobAI, web admin, or AI product features introduced. |

## Implementation and evidence checklist

All items remain open until implementation and actual evidence exist.

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

## Preparation boundaries

Lab 2 files under `design/` and `handoff/` are templates awaiting originals.
The local name `vetalife` does not define product features.
No Firebase project ID, account, key, application ID, version pin, or cloud resource
is invented. No services are deployed and nothing is published.

Flutter manifests, `main.dart`, generated Firebase options, Android build files,
and actual Firebase CLI project configuration belong to the next setup stage.

## Scaffold validation record

Scaffold checks passed: 25 required directories, two Firebase JSON files,
eight documentation-only Python modules, Python >=3.12 in valid TOML, and
26 local Markdown links. All four original PDFs are preserved.
No application, device, Firebase integration, or ARTEMIS execution is claimed.

Local Git setup is **complete**, verified after the user performed the repair:

- Repository root: `D:/projects/vetalife`.
- Origin: `https://github.com/kenji-cmyk/PRM393_Lab03_SE194126.git` for fetch/push.
- Branch: `main` tracks `origin/main` with the target repository's existing history.
- `docs/.git` no longer exists; the original metadata is preserved under ignored
  `.local-backup/docs-git-original/`. The earlier byte-verified 28-file ZIP backup
  remains at `.local-backup/docs-git-before-root-setup.zip`.
- All four actual requirement PDF paths pass `git check-ignore --no-index`.
  Root `.gitignore` and `docs/.gitignore` keep these local references excluded.
- Temporary extraction tools/files and Git backups remain ignored.

The working tree contains the intended scaffold modifications, additions, and
removal of the old empty MVVM placeholders. Git setup verification did not publish
any changes to GitHub.
