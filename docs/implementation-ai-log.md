# Implementation AI log

This records actual assistance, not the later required AI pull-request review.
Supporting source: From Design section 9 / Appendix A, which asks for six entries
over implementation. Do not fabricate entries before work occurs.

The historical entries below describe work before the VetaLife rename. Existing
test/build logs and screenshots remain records of those original runs.

## SETUP-01 - Folder scaffold (2026-11-03)

- Tool: Codex with specialized Flutter and QA agents.
- User prompt, verbatim:

> để bạn có thể hiểu được rõ cấu trúc mà tôi muốn implement bạn hãy đọc toàn bộ các file pdf trong requirements, nó có chứa các yêu câu của bài lab3, trước mắt tôi cần bạn khởi tạo folder structure cho đúng với yêu cầu trước khi thực hiện bài lab, không cần commit requirements lên gh

- Output: full reading/comparison of four PDFs (69 pages), folder structure,
  document templates, evidence locations, and ignore rules. No app features.
- Decision: user confirmed ARTEMIS / Cloud-Enabled + Preparation Guide v5.
  MobAI and Final Assignment conflicts are documented separately.
- Verification: final scaffold checks in `docs/lab3-requirements.md`.

## DESIGN-02 - Lab 2 profile and book-learning amendments (2026-11-03)

- Tool: Codex, Figma MCP, and local PDF inspection, with specialized source/documentation agents.
- User prompt, verbatim:

> https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q/Nh%C3%B3m-6-%E2%80%94-%C4%82n-g%C3%AC-kh%C3%B4ng-ch%E1%BA%BFt?node-id=0-1&t=LY7d13uJ8gCSYKzA-0 đây là màn hình của lab2, tui muốn bạn ở luồng 1 hãy thêm màn hình nhập thông tin người dùng như tên tuổi ngày tháng năm sinh cân nặng chiều cao, và ở luồng 3 cái màn hình bài học nhỏ tui muốn bạn bám sát vào cuốn sách ăn gì không chết bằng cách sẽ phân chia các bài học thành mục lục của sách, bạn có thể đọc sách đó trong folder requirements

- Input inspected: supplied Figma pages, existing components/tokens/prototype links,
  and the local scanned source book's table of contents.
- Output: design/handoff/traceability amendments for a personal-information step
  in flow 1 and source-mapped book-part/chapter learning in flow 3.
- Decision: reuse the existing VetaLife design system. Name/DOB/weight/height
  are entered; age is derived from DOB. Preserve source chapter identity and
  keep read progress separate from static lesson metadata.
- Figma output: 01A profile (`166:426`), part-1 catalogue (`6:257`), part-2
  catalogue (`166:470`), and shared reader (`166:628`). Prototype variants include
  empty/filled/invalid profile snapshots at 360/412 dp and 30 source-matched
  catalogue entries using selected-title/source/section string variables.
- Verification: coordinator completed user-flow/wireframe/Final UI/prototype
  updates. Composition screenshots were reviewed; QA independently checked
  filled/invalid profiles at 360/412 dp after the required-height error fix.
  Static inspection confirmed 15 rows in each of four catalogue variants,
  three selection-variable actions and correct reader navigation per row,
  and title/source/section bindings. No remaining actionable design findings.
- Local checks: coordinator confirmed 46 relative links, 27 core plus 3
  supplementary entries, all 5 PDFs ignored, and diff whitespace validation.
  The assigned-document pass also checked UTF-8 and 39 local links.
- Prototype limits: profile input is mocked by snapshot navigation; mark-read
  sets last-read feedback only. No actual validation/saving or per-lesson
  persisted progress exists. Reader content is a source-reference template.
- No Flutter app, API, persisted profiles, medical recommendations, runtime test
  results, or lesson prose beyond the inspected source mapping are claimed.
  No live prototype/browser interaction or native form-input run was performed.

## IMPLEMENT-03 - Flow 1 Flutter (2026-11-03)

- Tool: Codex, Figma MCP, Flutter/Dart tools, specialized Flutter, QA and
  independent review agents; local browser check through Playwright after the
  in-app browser connection failed.
- User request: implement the first flow from the supplied Cloud-Enabled Lab 3
  PDF and Figma Final UI node `2:3`. User clarification: no Firebase project
  exists yet; they will create it after coding.
- Input: PDF requirement text, Figma contexts/screenshots for `6:2`, `166:426`,
  `6:19`, `6:42`, existing handoff and design tokens. Original SVGs downloaded
  into runtime assets; Roboto bundled with its license.
- Output: root Flutter Android/web project, Provider MVVM flow, profile/date
  validation and derived age, goal choice, retained draft/back/retry, saved home,
  local preview persistence, Google/Firebase adapters and owner rules/setup guide.
- Review: accepted F1 recovery finding; exposed sign-out before home when profile
  loading fails. Added focused auth and widget regression checks. Reviewer confirmed
  the fix; this is not the later required line-linked GitHub PR review.
- Verification: 39 local tests pass, analyzer clean, web build and Android debug
  APK build pass; live preview entry/save/reload inspected with screenshots.
- Limits: no cloud project/resource created, no rules deployment/emulator run,
  no native account picker or ARTEMIS evidence. Runtime Figma amendments are
  recorded but not written back to the source design in this session.
- Files: `lib/`, `android/`, `web/`, runtime assets, manifests, tests, rules and
  implementation docs. No commit/push/publication was requested or performed.

## IMPLEMENT-04 - Firebase AI Logic on Spark (2026-11-03)

- Tool: Codex with Flutter implementation, setup/documentation and independent
  review agents; Firebase CLI and official Firebase/FlutterFire documentation.
- User prompt, verbatim:

> hãy thực hiện phương án firebase AI logic trên spark

- Output: cloud meal adapter now uses `firebase_ai` with App Check instead of
  Functions. It sends image bytes for recognition/OCR and confirmed ingredients,
  minimal profile metadata and selected book passages for analysis. The app
  validates source IDs and uses corpus page numbers. Legacy Functions remains
  optional through a separate config file.
- Project setup: enabled Gemini Developer API for the existing Android/web
  registrations, enabled Firebase App Check API, and confirmed AI Logic App Check
  enforcement. No billing upgrade or Gemini secret was used.
- Verification: analyzer clean, 113 Flutter tests pass, cloud web and Android
  debug builds pass. A nonpersonal text request to `gemini-3.6-flash` through
  Firebase AI Logic returned HTTP 200 and `READY`. Temporary debug tokens were
  revoked. Reviewer finding about web debug initialization order was fixed and
  regression-tested.
- Limits: device-specific App Check token registration, web reCAPTCHA provider
  setup, native camera/sign-in, complete cloud journal flow and real meal
  recognition accuracy remain unverified. This is not ARTEMIS evidence.
- Files: `lib/services/ai_logic_meal_intelligence.dart`, meal grounding and
  App Check bootstrap, dependency locks, Firebase configs, tests and setup docs.

## VERIFY-05 - Live Spark adapter and split commits (2026-11-04)

- User prompt: `tiếp tục thực hiện task`; retained earlier authorization to split
  commits and push `main`.
- Output: hidden-input PowerShell App Check registration helper, bounded live
  test runner with automatic temporary-token cleanup, opt-in analysis/OCR tests,
  and a synthetic text-only image fixture. Normal tests never call Gemini.
- Verification: 115 Flutter tests pass with 2 live skips; analyzer clean; legacy
  backend 22/22 and rules emulator 9/9. Real grounded analysis passed with 4
  validated corpus citations, followed by a separate synthetic OCR pass.
  An initial HTTP 500 was observed; its cause is unknown. No automatic retry or
  relaxation of validation was introduced.
- Cloud: deployed only owner-scoped Firestore rules to `vetalife-24f03` and
  verified the deployed contents match local. Indexes/data/billing unchanged.
  Temporary App Check debug registrations were revoked and JWT files removed.
- Review: fixed and rechecked a native stderr disclosure issue on PowerShell
  5.1. No Android device was attached; native camera, SDK attestation, Google
  Sign-In and real-user cloud persistence remain unverified.

## IMPLEMENT-06 - Flow 3 from Figma (2026-11-04)

- User prompt: `tiếp tục triển khai flow 3 dựa trên figma`.
- Tools: Figma design contexts/screenshots for `6:213`, `6:257`, `166:470`,
  `166:628`; specialized domain/UI/book agents and independent review; Flutter
  tooling, PDF rendering, Firebase rules emulator and local browser verification.
- Output: actual weekly meal-record progress, two-part catalogue, 30 sourced
  introductory lesson bodies, explicit owner read state, retry and session-safe
  preview cleanup. Core completion excludes the three supplementary entries.
- Editorial verification: 48 pages visually inspected; 46 cited in the bodies.
  Book scans remain ignored and no full chapter text is reproduced.
- Validation: 144 Flutter tests pass, 2 live AI skips, analyzer clean, 12 rules
  tests pass, web preview and Android cloud debug builds pass. Browser tested
  both widths, 0→1 core completion, supplementary exclusion, reload, repeat read,
  navigation and preview sign-out; 8 screenshots retained.
- Cloud: rules-only deployment and exact normalized readback for lesson progress
  succeeded; data/indexes/billing unchanged. No live model calls needed for Flow 3.
- Review: fixed a reproduced multi-store sign-out race and added actual-app
  delayed-storage regressions. Native/ARTEMIS and real Firebase account flow
  remain unverified. Figma source file was read only.

## Further entries

| ID/date | Tool | Verbatim prompt or saved path | Output | Actual verification | Decision/reason | Files/commit |
| --- | --- | --- | --- | --- | --- | --- |
