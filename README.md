# VetaLife - PRM393 Lab 3 - SE194126

Repository: <https://github.com/kenji-cmyk/PRM393_Lab03_SE194126>.

Status (2026-11-09): **Flows 1, 2 and 3 and the Firebase service integrations
are implemented in Flutter. Live cloud/device acceptance is still pending.**

- Flow 1: welcome, validated profile, goal, home, edit and sign-out; local preview
  and UID-scoped Firestore repositories.
- Flow 2: meal entry, optional camera/gallery recognition and OCR, editable
  ingredient confirmation, book-grounded analysis and explicit journal save.
  Cloud AI uses Firebase AI Logic; preview uses curated book matching.
- Flow 3: actual weekly meal counts, two-part catalogue, 30 introductory lessons
  (27 core), reader and explicit persisted read progress.
- Cloud additions: opt-in FCM and notification history/tap routing; data-derived
  PDF reports with private owner-scoped Cloudinary uploads; 16 planned Analytics
  events; native Crashlytics handled-error hooks and gated debug crash test;
  two Remote Config gates for learning and report export.

The home menu opens notifications (cloud only), reports and settings. Preview
uses local data, generates PDFs locally and never uploads reports to cloud or
sends Analytics events. It does not simulate receiving a push notification.

Firebase client configuration targets `vetalife-24f03`, Android ID
`vn.edu.fpt.vetalife`. On **2026-11-09**, Firestore rules were deployed and
production readback matched the local file, including `users/{uid}/devices`.
The two Boolean Remote Config keys were published with defaults `true`.
See [cloud readback](evidence/cloud/firebase-services-readback-2026-11-09.json)
and [flag publication](evidence/cloud/service-flags-publish-2026-11-09.json).

Firebase readback confirmed **billing disabled and no Storage buckets**. The
user approved Cloudinary for report uploads, avoiding Firebase Storage. Cloudinary
credentials and a signed-upload preset must be configured before cloud upload is
available. Publishing Remote Config values and deploying device rules do not
verify device fetch or real push delivery.

See [Firebase service setup](docs/firebase-services-setup.md) for prerequisites
and acceptance steps, and [test report](docs/test-report.md) for checks actually
executed. Google sign-in and account switching, cloud save/reload, actual FCM
   reception in all three app states, Cloudinary private upload/download denial,
   DebugView,
Crashlytics dashboards and Remote Config before/after changes need live evidence.
AI Logic has historical synthetic connectivity/analysis/OCR evidence; that does
not establish native attestation, camera or real-meal accuracy. Web reCAPTCHA and
per-device App Check setup remain necessary. No billing change is claimed.

Confirmed baseline: **Cloud-Enabled Mobile App + Preparation Guide v5**, using
**Google ARTEMIS** for Android E2E testing. The suite now defines **17 independent
cases with three repetitions each**; **25 offline harness checks passed and 51
device attempts were skipped**, not passed. The official SDK commit is pinned;
see [E2E setup](e2e_test/README.md). Device runs and final report/slides/video
are not complete.

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

Device/ARTEMIS validation, live Firebase service acceptance and final
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
├── android/                     # Android build configuration
├── assets/                     # Runtime asset folders and lesson metadata
│   └── content/lesson-catalog.json  # Book outline with source references
├── firebase/                    # Rules, indexes, Remote Config defaults
├── test/{unit,widget}/          # Flutter unit and widget regression tests
├── e2e_test/                    # ARTEMIS cases and offline harness tests
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

## Remaining acceptance work

1. Complete the platform prerequisites in [Firebase setup](docs/firebase-setup.md)
   and [service setup](docs/firebase-services-setup.md), including authorized web
   domains, native fingerprints, web push VAPID and App Check.
2. Configure Cloudinary report upload secrets/preset and deploy the authenticated
   Firebase Functions endpoints; then verify private upload/download behavior.
   Firestore device rules and both Remote Config defaults are already deployed/
   published.
3. Run real-account sign-in/save/reload/account-switch checks and collect live
   notification, Cloudinary, Analytics, Crashlytics and Remote Config evidence.
4. Execute [ARTEMIS cases](e2e_test/README.md), reconcile runtime adaptations with
   Figma, and produce the final report, slides and video with actual evidence.

The app and local Flutter checks are runnable now. These remaining checks are
acceptance work; successful compilation does not establish device behavior.

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
| ARTEMIS commit and model profile | SDK pinned to `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`; daemon/device execution pending |
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
This repository includes all three flows, Firebase service integration code
and local verification evidence. Live AI connectivity has been checked;
real-meal accuracy and full Firebase/device/ARTEMIS evidence remain incomplete. The previous
`functions/` backend is retained as an optional legacy Blaze implementation;
the app's default cloud AI path uses Firebase AI Logic on Spark.
