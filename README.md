# VetaLife - PRM393 Lab 3 - SE194126

Repository: <https://github.com/kenji-cmyk/PRM393_Lab03_SE194126>.

Status: **Flows 1, 2 and 3 implemented in Flutter**. Flow 1: Chào mừng → Thông tin của bạn →
Thiết lập mục tiêu → Trang chủ. Includes validation, derived age, draft retention,
save/retry, local preview persistence, edit/sign-out, and cloud Auth/Firestore code.
Firebase client configuration targets project `vetalife-24f03`. The VetaLife
Android app is registered for `vn.edu.fpt.vetalife`; Google Sign-In and the full
cloud profile/journal flow still need live verification. On 2026-11-04, the nine
Firestore rules emulator checks passed, rules were deployed to `vetalife-24f03`,
and production readback matched the local rules, including meal ownership rules.
Indexes, stored data and billing were unchanged.
Flow 2: ghi bữa ăn → optional camera/gallery recognition and OCR → editable
ingredient confirmation → book-grounded feedback → explicit journal save.
Local preview matches 15 verified book passages. Cloud AI now uses Firebase AI
Logic with the Gemini Developer API through the Flutter `firebase_ai` SDK,
targeting the Spark free tier for supported models and quotas. CLI setup has
enabled `gemini-developer-api` for the Android/web apps and confirmed AI Logic
App Check enforcement as `ENFORCED`, without changing billing. A temporary
App Check token exchange and a non-personal `gemini-3.6-flash` connectivity
request both returned HTTP 200. On 2026-11-04, live RPC/adapter analysis also
returned HTTP 200 with four validated book citations and health connections;
synthetic text-card OCR passed separately without inventing ingredients.
Temporary debug tokens were revoked and JWT files removed. These checks use
synthetic data and do not verify device SDK attestation, UI, native camera or
real-meal accuracy. See [the test report](docs/test-report.md) for the observed
HTTP 500 failure before the successful controlled analysis run.
Device debug tokens and web reCAPTCHA provider/site key still need configuration.
Native camera and real-meal analysis accuracy remain unverified. No Gemini
secret or Functions deployment is required for this path.
Flow 3: real weekly meal-record counts → two-part book catalogue → selected
lesson reader → explicit read progress. There are 30 sourced introductory
lessons; 27 core lessons count toward completion, with 3 supplementary entries
tracked separately. Preview progress persists locally and clears on sign-out;
cloud progress is owner-scoped in Firestore. See [Flow 3 setup](docs/flow3-setup.md).
Confirmed baseline: **Cloud-Enabled Mobile App + Preparation Guide v5**,
using **Google ARTEMIS** for Android E2E testing.

## Run flows 1, 2 and 3

```powershell
flutter pub get
flutter run --dart-define=APP_MODE=preview
```

For browser preview: `flutter run -d chrome --dart-define=APP_MODE=preview`.
Preview is the default; its visible label identifies device-only storage.
No hard-coded user or completed meal data is supplied. Home shows your saved
name, goal and actual meal count; the journal has real empty and saved states.
Follow [Flow 2 setup](docs/flow2-setup.md) for preview, Gemini configuration,
camera/OCR confirmation, source references and journal behavior.

Complete [the Firebase setup guide](docs/firebase-setup.md), then
run `flutter run --dart-define=APP_MODE=cloud`. Cloud mode requires real config
and never falls back silently to preview. Android ID: `vn.edu.fpt.vetalife`.

For Android development, run the cloud debug app, copy its App Check debug UUID
from the log, then run `& .\tool\register_app_check_debug.ps1 -Platform android`
in another PowerShell window. Paste the UUID into the hidden prompt and restart
the app after registration. Use `-Platform web` for the browser's token; web also
requires its public reCAPTCHA site key and the debug flag described in
[the App Check steps](docs/flow2-setup.md#đăng-ký-debug-token-bằng-powershell).
Do not paste debug tokens into chat or commit them. Google Sign-In and the full
save/reload flow still need live verification with the deployed rules.

VetaLife installs as a separate Android app after the application ID change;
device-only data from the previous Android app is not transferred automatically.
On the same web origin, existing preview profiles migrate to the VetaLife
storage key. Cloud profiles remain associated with their Firebase user UID.

Toolchain used: Flutter **3.47.4**, Dart **3.13.3**, Provider **6.1.5+1**;
all direct dependencies are pinned in `pubspec.yaml` and `pubspec.lock`.
Run `flutter analyze` and `flutter test` for local validation. See
[the test report](docs/test-report.md) for executed checks and limitations.

Device/ARTEMIS validation, the remaining Firebase lab services and final
submission evidence remain future work.

## Repository layout

```text
vetalife/                         # Local root; GitHub name may differ
├── README.md
├── .gitignore
├── design/DESIGN.md              # Figma-derived design specification
├── handoff/flutter-handoff.md    # Design-derived Flutter handoff
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
├── assets/                     # Runtime asset folders and lesson metadata
│   └── content/lesson-catalog.json  # Book outline with source references
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

The requested Lab 2 profile and book-catalogue amendments are complete in Figma.
Static reactions and 360/412 dp screenshots were reviewed; see
`docs/design-change-log.md` for node references and prototype
limitations. This does not represent implemented Flutter or live interaction tests.

## Next implementation stages

1. Review the supplied [Lab 2 Figma design](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=0-1),
   [design specification](design/DESIGN.md), and [handoff](handoff/flutter-handoff.md).
   The user's amendments add personal information to flow 1 and book-chapter
   learning to flow 3; confirm any separate original written Lab 2 deliverables.
2. Continue [traceability](docs/design-traceability.md) and
   [architecture](docs/architecture.md) for flow 3 using the selected Provider
   setup. Root Flutter/Android/web initialization and flows 1/2 are complete.
3. Configure your Firebase project using [the setup guide](docs/firebase-setup.md).
   Verify the renamed Android app's signing fingerprints, owner rules, and
   Google Sign-In with the real project.
4. Implement the remaining flows and Firebase services; instrument, test,
   review, and produce actual submission evidence in that order.

The app and local Flutter checks are runnable now. Android ARTEMIS E2E remains
pending; see [E2E preparation](e2e_test/README.md).

## Project details to complete

| Item | Current value |
| --- | --- |
| Student ID | SE194126 |
| Topic / brand | Ăn gì không chết / VetaLife |
| Persona / success criteria | Vinh, 25, office worker; quick meal logging, visible weekly frequency, preserved draft on network failure |
| Figma URL / design amendments | Linked above; flow 1 profile and flow 3 book catalogue recorded in the design change log |
| Real data source/API | Preview: device storage; cloud profile: users/{uid} in Firestore after configuration |
| Flutter/Dart versions and package pins | Flutter 3.47.4 / Dart 3.13.3; exact pins in pubspec.yaml/lock |
| State management | Provider 6.1.5+1 |
| Firebase project / Android application ID | vetalife-24f03 / vn.edu.fpt.vetalife; Android app registered, cloud behavior unverified |
| ARTEMIS commit and model profile | Pending installation; record exact commit |
| Python / uv / ADB versions | Python 3.12+ required; exact versions pending setup |
| Demo video | Pending; 5-10 minutes |

## Deliverables and AI disclosure

- Planning: [requirements](docs/lab3-requirements.md),
  [traceability](docs/design-traceability.md), [architecture](docs/architecture.md),
  [analytics plan](docs/analytics-plan.md), [book curriculum](docs/book-curriculum.md).
- Verification: [test plan](docs/test-plan.md), [test report](docs/test-report.md),
  [code review](docs/code-review.md), and [evidence](evidence/README.md).
- Supporting records: [handoff gaps](docs/handoff-gaps.md),
  [design changes](docs/design-change-log.md), [fidelity check](docs/fidelity-check.md),
  [implementation AI log](docs/implementation-ai-log.md).
- Submission: `report/Lab03_SE194126.pdf` (8-12 pages),
  `slides/Lab03_SE194126_slides.pdf` (12-15 slides), demo video link above.
- Codex assisted with reading the four lab PDFs, comparing requirements, preparing
  this scaffold, inspecting the supplied Figma design, and documenting the requested
  profile and book-catalogue amendments. This does not replace the later required AI pull-request review.

The original requirement PDFs are excluded by `.gitignore`. Never commit
credentials, model API keys, service-account keys, or signing keystores.
Generated Firebase client identifiers may be tracked; Security Rules enforce access.

Local Git setup is complete: this folder is the repository root, `origin` points
to the repository above, and `main` tracks `origin/main` with its existing history.
The legacy `docs/.git` was moved to the ignored `.local-backup/` directory.
The lab requirement PDFs and source book remain local and Git-ignored. See the
[validation record](docs/lab3-requirements.md#scaffold-validation-record).
This repository includes flows 1/2 and their local execution evidence. Live AI
connectivity has been checked; real-meal accuracy, flow 3 and full
Firebase/ARTEMIS evidence remain to be completed. The previous
`functions/` backend is retained as an optional legacy Blaze implementation;
the app's default cloud AI path uses Firebase AI Logic on Spark.
