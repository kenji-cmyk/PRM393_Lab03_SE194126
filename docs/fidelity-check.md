# Design fidelity check

Status: Flow 1 implemented and browser-rendered at 360/412 px, with separate
Flutter widget checks at 360/412 logical widths. Figma targets were read using
design context and screenshots. Browser screenshots exclude the native status
bar. Runtime adaptations are in [traceability](design-traceability.md).
Source: Cloud-Enabled sections 5/9; From Design section 8.

| Screen/component | Figma | App screenshot | Viewport | Difference | Reason / change ID | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Welcome | `6:2` | [360](../evidence/screenshots/flow1-welcome-360.png), [412](../evidence/screenshots/flow1-welcome-412.png) | 360/412×800 | Native safe area; explicit local preview label | RT-01/05 | Render reviewed |
| Profile empty/filled/invalid | `166:426` | [360 empty](../evidence/screenshots/flow1-profile-empty-360.png), [filled](../evidence/screenshots/flow1-profile-filled-360.png), [invalid](../evidence/screenshots/flow1-profile-invalid-360.png); [412 empty](../evidence/screenshots/flow1-profile-empty-412.png), [filled](../evidence/screenshots/flow1-profile-filled-412.png), [invalid](../evidence/screenshots/flow1-profile-invalid-412.png) | 360/412×800 | Real input and picker action; scrollable errors | RT-01/02 | Render reviewed; form widget tested |
| Goal choice | `6:19` | [360](../evidence/screenshots/flow1-goals-360.png), [412](../evidence/screenshots/flow1-goals-412.png) | 360/412×800 | Actual selected goal can differ from source sample | RT-03 | Render reviewed; selection/save tested |
| Home | `6:42` | [360](../evidence/screenshots/flow1-home-360.png), [412](../evidence/screenshots/flow1-home-412.png) | 360/412×800 | Actual name/goal and empty meal state; edit menu and preview label | RT-04/05 | Render reviewed; live reload restored profile |

SVG assets are the original local Figma exports: back 26×26; home, journal,
progress and learn 32×32, used at their intrinsic sizes. Roboto regular/medium/bold
is bundled locally with its license. The hero's three circles are original native
Figma shapes, implemented as native geometry. No screenshot is a runtime asset.
This is visual review, not a pixel-diff certification or native-device UI run.

Compare at matching dimensions (360 x 800 dp in the supporting handout).
Check layouts at 360/412 dp, 48 dp touch targets, 14 sp minimum body text, contrast,
and meaning beyond color. Verify tokens in `lib/theme/`, reusable components in
`lib/widgets/`, and real loading/empty/error situations. Store actual captures
in `evidence/screenshots/`; do not bundle evidence as runtime assets.
