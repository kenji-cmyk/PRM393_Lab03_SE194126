# Design traceability

Status: Flows 1, 2 and 3 implemented and tested in Flutter; see [test report](test-report.md).
Figma amendments for flows 1/3 remain the design baseline. The Flutter browser
preview has live interaction and screenshot evidence; cloud/native interaction
remain subject to the limits in the test report. Source:
[Lab 2 design](../design/DESIGN.md),
[handoff](../handoff/flutter-handoff.md), and
[Figma Final UI](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=2-3).

Flow 1 uses `OnboardingStage` in `FlowScreen` rather than URL deep links; route
paths below retain the proposed information architecture. Flow 2 uses
`MealStage` and `MealFlowScreen` in the same user session. Flow 3 uses
`LearningStage`, `LearningViewModel` and `LearningFlowScreen`. Existing
Figma IDs identify actual design nodes; amendment links and prototype limits are in
[the change log](design-change-log.md).

## Screens and flow steps

| Screen / flow | Existing Figma node | Proposed route / screen | Planned ViewModel / data | State and verification |
| --- | --- | --- | --- | --- |
| 01 Chào mừng - flow 1 | `6:2` | welcome / WelcomeScreen | OnboardingViewModel | Implemented; opens the real profile form |
| 01A Thông tin của bạn - flow 1 | `166:426` | profile / UserProfileScreen | OnboardingViewModel / retained private draft | Required fields, strict date validation, derived age, comma-decimal measures; unit/widget tests and browser captures |
| 02 Thiết lập mục tiêu - flow 1 | `6:19` | goals / GoalSetupScreen | OnboardingViewModel / HabitGoal | Single selection, back retention, duplicate guard, save/retry tested |
| 03 Trang chủ - flow 1 destination | `6:42` | home / HomeScreen | OnboardingViewModel / persisted UserProfile | Actual saved name and goal; edit/sign-out; browser reload restores preview profile; implemented meal/progress/learning navigation and service menu |
| 04 Ghi bữa ăn - flow 2 | `6:76` | entry / MealFlowScreen | MealViewModel / MealDraft | Manual input, meal time, camera/gallery, explicit upload consent; draft retained |
| Added recognition/confirmation | User-requested runtime extension | recognizing / confirm | MealViewModel / MealRecognition | Separate OCR and provisional ingredients; edit/add/remove and explicit confirmation before analysis |
| 05 Đang phân tích - flow 2 | `6:101` | analyzing | MealViewModel / MealIntelligence | Cancel/edit ignores late results; local book matching or authenticated Firebase AI Logic |
| 06 Kết quả - flow 2 | `6:118` | result | MealViewModel / MealAnalysis | Highlight and suggestion cards, save/edit, profile context, sourced book topics/pages |
| 07 Lỗi kết nối - flow 2 | `6:138` | error | Same draft/service | Retry recognition/analysis without losing input; save failure retains result |
| 08 Nhật ký bữa ăn - flow 2 | `6:155` | journal | MealViewModel / MealRepository | Owner records, date selection, notes/detail, same-ID update; local and emulator rules tests |
| 09 Nhật ký trống - flow 2 | `6:186` | journal empty date | MealViewModel | Genuine empty state and add-meal action; no sample meals |
| 10 Tiến trình tuần - flow 3 | `6:213` | progress / LearningFlowScreen | LearningViewModel + saved MealViewModel records | Actual local-week counts, zero state, accessible chart and last read |
| 11 Bài học nhỏ - Phần 1 - flow 3 | `6:257` | catalog / LearningFlowScreen | LearningViewModel / validated source catalogue | 15 chapters, actual read counter, same-part return |
| 12 Bài học nhỏ - Phần 2 - flow 3 | `166:470` | catalog / LearningFlowScreen | Same catalogue with separate part selection | 12 core categories + 3 supplementary entries; only core units count toward 27 |
| 13 Chi tiết bài học - flow 3 | `166:628` | detail / LearningFlowScreen | Selected Lesson body + owner progress repository | 30 authored introductory bodies, source pages, explicit idempotent save/retry, reload and session cleanup tests |

Auth routing and UID-scoped ownership adapters are implemented; real Google
sign-in/account switching still need live verification. The 2026-11-09 update adds
notification history/permission UI, PDF report UI and app settings under the home
menu. These reuse existing tokens and do not invent Figma node IDs. They remain
runtime extensions awaiting source-design reconciliation. See [Firebase setup](firebase-setup.md)
and [service setup](firebase-services-setup.md).

| Runtime extension | Implementation / data | Acceptance status |
| --- | --- | --- |
| Notifications | NotificationViewModel / FirebaseNotificationService; UID local history and device registration | Device rules deployed/read back Nov 9; three-state delivery, permission and tap evidence pending |
| Personal PDF report | ReportViewModel / PdfReportService; saved profile/meals/read progress, Cloudinary authenticated raw owner path | Local PDF export available; Cloudinary credentials/preset and signer deployment pending |
| App settings | AppSettings / two Remote Config flags controlling learning and export | Both Boolean defaults published true Nov 9; device fetch/before-after evidence pending |
| Instrumentation | AppTelemetry in Auth/onboarding/meal/learning/report actions | 16 planned events and native sanitized error hooks; DebugView/Crashlytics dashboard evidence pending |

## Runtime adaptations recorded for flow 1

| ID | Adaptation and reason | Verification / source-design status |
| --- | --- | --- |
| RT-01 | Native SafeArea/system time replace the painted 9:41; scrollable, width-constrained content supports keyboard and text enlargement | Widget layout checks at 360/412 dp, 1.5 text scale and simulated keyboard; browser screenshots |
| RT-02 | Editable date plus 48 dp “Chọn ngày sinh” action opens the localized picker; real form replaces prototype snapshots; height hint shortened to “Nhập số đo” so it fits the 360 dp two-column control | Date validation/unit tests, picker-cancel widget test; runtime action added without changing source Figma |
| RT-03 | One flow ViewModel retains profile and goal across back navigation and atomically saves the completed profile | Unit/widget save/retry/dedup tests; avoids independent form/goal lifetime loss |
| RT-04 | Home shows actual name/selected goal and a zero-meal initial state instead of the design's sample Minh and 1/2 meals | Live browser capture and persistence reload; meal storage is flow 2 |
| RT-05 | Explicit preview label, profile edit/sign-out menu, cloud Google sign-in and pre-home sign-out recovery added with existing tokens | Preview live-tested; auth VM/recovery widget tests pass; cloud requires setup |
| RT-06 | All four navigation destinations now open their implemented flow inside the same session | Integration test covers Home → Progress → Learn → Journal → Learn → Home |
| RT-07 | Camera/gallery and editable recognition confirmation extend the original entry screen; no prototype simulation buttons | Widget checks at 360/412 dp and large text; no native camera evidence claimed |
| RT-08 | Result keeps primary save/edit after summary cards; optional deeper book sources follow below | 15 curated page-mapped passages; AI Logic output references validated in the client |
| RT-09 | Weekly bars/counts use real saved meals instead of sample heights; the card says days recorded instead of implying vegetable compliance | Calendar/week/future-date/duplicate-ID tests; text alternatives share the same values |
| RT-10 | Reader adds original introductory content and inspected source pages to the Figma reading template; catalogue adds the actual core read count | 30 bodies, 48 pages visually inspected; explicit completion and supplementary exclusions tested |
| RT-11 | Home menu adds cloud notifications, PDF reports and settings; feature routes belong to the session | Runtime extension; source Figma sync and live device acceptance pending |
| RT-12 | Remote Config can temporarily close learning/report generation with visible states and defaults | Local behavior and live evidence recorded separately in test report |

These runtime adaptations are documented here. No Figma source file was changed
in this implementation session; corresponding Figma additions remain to be synced
before claiming complete Lab 3 design/app parity.

## Tokens and components

| Figma source | Planned implementation location | Verification |
| --- | --- | --- |
| Color, typography, spacing and radius tokens on `2:4` | `lib/theme/` | Mapped in AppTheme; existing flow checks and new service UI checks in test report |
| Button / Text Field / Card / App Bar on `2:5` | `lib/widgets/` | Shared components reused in forms/catalogue and new service screens |
| Navigation / Dialog / Loading / Empty / Error on `2:5` | `lib/widgets/` | Existing navigation/loading/error components reused; device acceptance pending |

## Changes and source fidelity

- DC-01 adds profile information in flow 1 at the user's request. Date of birth
  supplies derived age, so two editable values cannot disagree.
- DC-02 replaces generic learning content with book-part/chapter navigation and
  a selected-lesson detail.
- The exact source hierarchy and page mapping are recorded in
  [book-curriculum.md](book-curriculum.md). Long source passages and the PDF itself
  are not app content assets.
- See [design-change-log.md](design-change-log.md) for design status and Figma
  delivery references. Executed Flutter/browser checks and their limits are in
  the test report; these are separate from device/ARTEMIS evidence. The E2E suite now contains
  17 cases with three repetitions; 25 offline checks passed and all 51 device
  attempts were skipped. See [E2E setup](../e2e_test/README.md) for the pinned SDK.
