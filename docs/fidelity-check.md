# Design fidelity check

Status: template; no app screens exist to compare.
Source: Cloud-Enabled sections 5/9; From Design section 8.

| Screen/component | Figma | App screenshot | Viewport | Difference | Reason / change ID | Status |
| --- | --- | --- | --- | --- | --- | --- |

Compare at matching dimensions (360 x 800 dp in the supporting handout).
Check layouts at 360/412 dp, 48 dp touch targets, 14 sp minimum body text, contrast,
and meaning beyond color. Verify tokens in `lib/theme/`, reusable components in
`lib/widgets/`, and real loading/empty/error situations. Store actual captures
in `evidence/screenshots/`; do not bundle evidence as runtime assets.
