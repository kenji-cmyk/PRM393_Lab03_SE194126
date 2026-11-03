# Flow 1 browser captures

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
