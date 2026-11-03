# PRM393 Lab 3 - SE194126

Repository: <https://github.com/kenji-cmyk/PRM393_Lab03_SE194126>.

Status: **folder and documentation scaffold only**. No Flutter application,
Firebase connection, implemented E2E suite, or execution evidence exists yet.
Confirmed baseline: **Cloud-Enabled Mobile App + Preparation Guide v5**,
using **Google ARTEMIS** for Android E2E testing.

## Repository layout

```text
vetalife/                         # Local root; GitHub name may differ
├── README.md
├── .gitignore
├── design/DESIGN.md              # Approved Lab 2 specification to import
├── handoff/flutter-handoff.md    # Approved Lab 2 handoff to import
├── lib/
│   ├── models/                  # Plain Dart data models
│   ├── services/                # App services / external data access
│   ├── firebase/                # Firebase SDK adapters
│   ├── viewmodels/              # Screen state and business logic
│   ├── screens/                 # Views that render ViewModel state
│   ├── widgets/                 # Reusable components and states
│   ├── theme/                   # Lab 2 tokens and ThemeData
│   └── utils/                   # Small shared helpers
├── android/                     # Android build project reserved for setup
├── assets/{images,icons,fonts}/  # Runtime assets only
├── firebase/                    # Rules, indexes, Remote Config defaults
├── test/{unit,widget}/          # Future Flutter tests
├── e2e_test/                    # Future ARTEMIS pytest suite
├── docs/
│   └── requirements/            # Original PDFs; local and Git-ignored
├── evidence/                    # Actual console screenshots and test traces
├── report/                      # Lab03_SE194126.pdf when complete
└── slides/                      # Lab03_SE194126_slides.pdf when complete
```

See [architecture](docs/architecture.md) for folder responsibilities and diagrams,
and [requirements](docs/lab3-requirements.md) for source differences and scope.

## Before implementation

1. Import approved Lab 2 materials: Figma URL, persona, success criterion,
   all screens (at least eight), three flows, tokens, components, and handoff.
2. Complete [traceability](docs/design-traceability.md) and
   [architecture](docs/architecture.md); choose **one** of Provider or Riverpod.
3. Confirm the Android application ID and initialize Flutter **at this root**,
   preserving this scaffold. This will generate `pubspec.yaml`, `lib/main.dart`,
   Android build files, and Flutter metadata; none are fabricated here.
4. Configure the student's Firebase project using FlutterFire. Generate
   `lib/firebase_options.dart` and `android/app/google-services.json`,
   then add real Firebase CLI project configuration.
5. Integrate features and the six Firebase services; instrument, test,
   review, and produce actual submission evidence in that order.

No app or E2E command is runnable yet. See
[Firebase preparation](firebase/README.md) and [E2E preparation](e2e_test/README.md).
Record exact commands and tool versions when setup is actually performed.

## Project details to complete

| Item | Current value |
| --- | --- |
| Student ID | SE194126 |
| Topic, persona, success criterion / Figma URL | Pending approved Lab 2 materials |
| Real data source/API | Pending Lab 2; Firestore when storing user data |
| Flutter/Dart versions and package pins | Pending project initialization |
| State management | Provider or Riverpod; decision pending |
| Firebase project / Android application ID | Pending; use the student's own project |
| ARTEMIS commit and model profile | Pending installation; record exact commit |
| Python / uv / ADB versions | Python 3.12+ required; exact versions pending setup |
| Demo video | Pending; 5-10 minutes |

## Deliverables and AI disclosure

- Planning: [requirements](docs/lab3-requirements.md),
  [traceability](docs/design-traceability.md), [architecture](docs/architecture.md),
  [analytics plan](docs/analytics-plan.md).
- Verification: [test plan](docs/test-plan.md), [test report](docs/test-report.md),
  [code review](docs/code-review.md), and [evidence](evidence/README.md).
- Supporting records: [handoff gaps](docs/handoff-gaps.md),
  [design changes](docs/design-change-log.md), [fidelity check](docs/fidelity-check.md),
  [implementation AI log](docs/implementation-ai-log.md).
- Submission: `report/Lab03_SE194126.pdf` (8-12 pages),
  `slides/Lab03_SE194126_slides.pdf` (12-15 slides), demo video link above.
- Codex assisted with reading all four PDFs, comparing requirements, and preparing
  this scaffold. This does not replace the later required AI pull-request review.

The original requirement PDFs are excluded by `.gitignore`. Never commit
credentials, model API keys, service-account keys, or signing keystores.
Generated Firebase client identifiers may be tracked; Security Rules enforce access.

Local Git setup is complete: this folder is the repository root, `origin` points
to the repository above, and `main` tracks `origin/main` with its existing history.
The legacy `docs/.git` was moved to the ignored `.local-backup/` directory.
All four requirement PDFs are confirmed ignored. See the
[validation record](docs/lab3-requirements.md#scaffold-validation-record).
This repository currently contains preparation scaffolding; application features
and execution evidence will be added during the lab.
