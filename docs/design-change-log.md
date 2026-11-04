# Design change log

## Flow 2 runtime extension — 2026-11-03

Implemented the existing meal-entry/loading/result/error/journal/empty screens
from nodes `6:76`, `6:101`, `6:118`, `6:138`, `6:155`, `6:186`. The user's new
camera/gallery feature adds provisional image recognition, separate OCR text,
editable ingredient confirmation, upload consent, profile-aware Gemini service
integration and book-page references. The result retains summary cards followed
by primary save/edit; detailed sources follow below. Figma loading/empty SVGs
were downloaded and the existing icons/tokens reused.

These additions are implemented in code. The external Figma file was not
modified in this task. See [traceability](design-traceability.md),
[setup](flow2-setup.md) and [verification](test-report.md).

These changes are explicitly requested by the user. They extend the Lab 2
design before Flutter implementation. The existing meal-entry flow is retained.

The repository now uses the VetaLife brand. This rename updates application
branding and handoff text; the linked source Figma file and its existing captures
retain their original labels and are not claimed to have been renamed.

| ID/date | Area | Original design | Requested amendment | Reason | Figma delivery / status |
| --- | --- | --- | --- | --- | --- |
| DC-01 / 2026-11-03 | Flow 1, personal profile | Chào mừng -> Thiết lập mục tiêu -> Trang chủ | Add 01A Thông tin của bạn: name, date of birth, derived read-only age, weight in kg, height in cm; include invalid-input recovery | User requested these fields; deriving age avoids conflicting DOB/age entries | [Final UI profile](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=166-426) complete; user-flow, wireframe and prototype updated; static wiring and screenshots reviewed |
| DC-02 / 2026-11-03 | Flow 3, Bài học nhỏ | One generic article about varied plant eating | Book catalogue organized by the source book's two parts and chapter order, selected-lesson detail, and read feedback | User requested close alignment with the book's table of contents | [Part 1](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=6-257), [Part 2](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=166-470), [reader](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=166-628) complete; static selection wiring and screenshots reviewed |

Source file:
[Figma - VetaLife / Ăn gì không chết](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=0-1).

Content references:
[book curriculum](book-curriculum.md), [design specification](../design/DESIGN.md),
[Flutter handoff](../handoff/flutter-handoff.md), and
[traceability](design-traceability.md).

The profile fields come from the user's request. Their addition does not create
a medical scoring/personalized-advice feature. Lesson metadata preserves source
titles and page references; complete lesson prose and user-progress persistence
are later implementation work.

## Created prototype nodes and limits

| Design | 360 dp prototype node(s) | 412 dp prototype node(s) |
| --- | --- | --- |
| Profile empty / filled / invalid | `171:883` / `171:927` / `171:971` | `171:1015` / `171:1059` / `171:1103` |
| Book catalogue part 1 | `13:563` | `66:792` |
| Book catalogue part 2 | `171:1181` | `171:1395` |
| Selected-lesson reader | `171:1339` | `171:1553` |

The profile uses prepared state snapshots. Field clicks show a mocked filled
state; this is not native text/date entry or real saved profile data. All 30
catalogue entries set prototype string variables for the selected title,
source title/page, and section before navigating to the shared reader. The
reader's mark-read action changes last-read feedback on the weekly screen; it
does not implement persistent per-user/per-lesson progress. Reader content is
a source-reference template, not authored chapter summaries.

## Final design verification

- User-flow page `0:1` now shows four steps in flow 1 and six in flow 3.
- Wireframe page `2:2` contains profile `172:434`, part 1 `52:947`,
  part 2 `172:478`, and reader `172:636`.
- Final UI and prototype pages were updated, with profile/catalogue/reader
  composition screenshots reviewed. Filled and invalid form snapshots were
  independently checked at 360/412 dp. The missing required-height error was
  corrected in invalid snapshots `171:971` and `171:1103`.
- Static inspection verified 15 rows in each of the four catalogue variants,
  each with three `SET_VARIABLE` actions followed by navigation to its correct
  reader; title/source/section text bindings are present.
- Existing Text Field input/value layers now fill their available width in
  all five variants so narrow form columns do not overflow. Full-width styling
  remains the existing design.
- The coordinator reported no remaining actionable design findings. Local
  repository checks passed: 46 relative Markdown links, catalogue counts of
  27 core plus 3 supplementary entries, all 5 source PDFs ignored, and diff
  whitespace validation.

This evidence is static reaction inspection and screenshot review. No live
prototype/browser interaction, native form input, Flutter runtime, Firebase,
or ARTEMIS execution is claimed. The reader remains a source-reference/learning
template, without full chapter summaries.
