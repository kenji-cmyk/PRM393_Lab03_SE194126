# Browser captures

## Flow 3 — VetaLife

Captured 2026-11-04 from the compiled preview at `http://127.0.0.1:8233`,
360/412 CSS px × 800. Synthetic profile input; actual empty meal data and
explicit read actions. No user data or completion is hard-coded in the app.

| Files | Observed state |
| --- | --- |
| `flow3-catalog-part1-360.png`, `flow3-catalog-part1-412.png` | First part, chapter order/source references; current core count |
| `flow3-catalog-part2-360.png`, `flow3-catalog-part2-412.png` | Overview and Daily Dozen order; 412 capture after introduction/beans were marked read |
| `flow3-reader-360.png`, `flow3-reader-412.png` | Selected beans reader, matching source title/pages and original introductory content |
| `flow3-progress-empty-360.png` | Actual zero-record/zero-read state |
| `flow3-progress-read-412.png` | After reload, 1/27 core and latest read beans; no meals recorded |

The reader scrolls beyond the viewport to reflection/source/mark-read controls.
Screenshots do not claim native device, live cloud account or ARTEMIS coverage.
See [test report](../../docs/test-report.md) for actions, regressions and limits.

## Flow 2 — VetaLife

Captured 2026-11-03 from the actual compiled Flutter web preview at
`http://127.0.0.1:8232`, 360/412 CSS px × 800. The eleven `flow2-*.png` files
show entry, confirmation, local-book result, journal, empty date and one expanded
source panel. Figma baseline nodes: `6:76`, `6:101`, `6:118`, `6:138`, `6:155`,
`6:186`; the photo/confirmation extension follows the user's request.

All data was typed into the running app: synthetic profile “Người thử Flow 2”,
04/11/2000, 62.5 kg, 170.5 cm, goal addVegetables; meal “Đậu hũ áp chảo, cơm
gạo lứt và rau cải”, with confirmed đậu hũ/cơm gạo lứt/cải thìa. No meal photo
was sent to an AI. Results are explicitly local matching against four of the
15 curated book passages. Model accuracy and native camera are not verified.

The browser check also verified reload persistence, date filtering, opening and
editing the same entry without duplication, source expansion and preview
sign-out cleanup across reload. No console errors were observed. Tests cover
cloud-contract behavior with injected services. See [test report](../../docs/test-report.md).

## Historical Flow 1 captures

These captures predate the VetaLife rename and show the previous brand. They are
preserved as evidence of the original run; they do not verify the renamed UI.

Captured 2026-11-03 with the actual compiled Flutter web preview at
`http://127.0.0.1:8231`, 360/412 CSS px by 800 px. Synthetic inputs:
Nguyễn Ánh, 04/11/2000 (derived age 25 at capture date), 62,5 kg, 170,5 cm;
goal `readDaily`. No seed user, meal, or health outcome was supplied by the app.

Observed live: empty form, required errors, typed valid input, derived age,
goal change/save, actual home name/goal, reload restores profile, preview sign-out
returns to welcome and a reload remains signed out. The save-error/duplicate and
native-date-cancel paths are covered by Flutter widget tests rather than these
browser captures. Screenshots are manual visual evidence, not an ARTEMIS run.

SVGs/font are runtime assets; these screenshots are not bundled into the app.
See [fidelity record](../../docs/fidelity-check.md) and
[test report](../../docs/test-report.md).
