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
| Meal entry | `6:76` | [360](../evidence/screenshots/flow2-entry-360.png), [412](../evidence/screenshots/flow2-entry-412.png) | 360/412×800 | Real camera/gallery buttons & manual text; explicit upload consent | RT-07 | Render reviewed; widget tested |
| Recognition & Confirm | Runtime extension | [360](../evidence/screenshots/flow2-confirm-360.png), [412](../evidence/screenshots/flow2-confirm-412.png) | 360/412×800 | Editable ingredient chips & OCR recognition before analysis | RT-07 | Render reviewed; widget tested |
| Meal result & Sources | `6:118` | [360](../evidence/screenshots/flow2-result-360.png), [412](../evidence/screenshots/flow2-result-412.png), [sources 412](../evidence/screenshots/flow2-sources-412.png) | 360/412×800 | Curated book passages & AI grounded citations; expandable sources | RT-08 | Render reviewed; widget tested |
| Journal & Empty state | `6:155`, `6:186` | [360 journal](../evidence/screenshots/flow2-journal-360.png), [412](../evidence/screenshots/flow2-journal-412.png); [360 empty](../evidence/screenshots/flow2-empty-360.png), [412](../evidence/screenshots/flow2-empty-412.png) | 360/412×800 | Date filtering & live user records; real empty state without sample items | RT-06 | Render reviewed; rules tested |
| Weekly progress | `6:213` | [360 empty](../evidence/screenshots/flow3-progress-empty-360.png), [412 read](../evidence/screenshots/flow3-progress-read-412.png) | 360/412×800 | Actual recorded meal days & core reading counter (27 units) | RT-09 | Render reviewed; widget tested |
| Lesson catalogue (Part 1 & 2) | `6:257`, `166:470` | [360 part 1](../evidence/screenshots/flow3-catalog-part1-360.png), [412](../evidence/screenshots/flow3-catalog-part1-412.png); [360 part 2](../evidence/screenshots/flow3-catalog-part2-360.png), [412](../evidence/screenshots/flow3-catalog-part2-412.png) | 360/412×800 | 15 chapters + 12 Daily Dozen categories + 3 supplementary units | RT-10 | Render reviewed; curriculum tested |
| Lesson reader / detail | `166:628` | [360](../evidence/screenshots/flow3-reader-360.png), [412](../evidence/screenshots/flow3-reader-412.png) | 360/412×800 | 30 authored introductory bodies, book page refs & completion toggle | RT-10 | Render reviewed; progress tested |
| 14 Notifications (Inbox) | [`185:1144`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=185-1144) | Device captures | 360/412×800 | UID-scoped local notification inbox; push payload display | RT-11 | UI synced; device verified |
| 14A Cấp quyền / Trống | [`185:1183`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=185-1183) | Device captures | 360/412×800 | Android 13+ permission banner; genuine empty state without mock items | RT-11 | UI synced; device verified |
| 15 Báo cáo PDF cá nhân | [`187:1302`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=187-1302) | [10](../evidence/cloud/screenshots/10-report-upload-cloudinary-uri.png), [11](../evidence/cloud/screenshots/11-report-opened-pdf-viewer.png) | 360/412×800 | Sourced PDF generation; signed Cloudinary upload & short-lived download | RT-11 | UI synced; unit & emulator tested |
| 16 Cài đặt đám mây (Settings) | [`187:1330`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=187-1330) | [360](../evidence/screenshots/firebase-settings-360.png) | 360×800 | Feature flags toggle (learning & export); graceful fallback banners | RT-11/12 | UI synced; Remote Config verified |

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
