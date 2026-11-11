# VetaLife - Lab 2 design specification

Status: Flows 1 and 2 now have Flutter implementations; see
[runtime traceability](../docs/design-traceability.md) and
[verification](../docs/test-report.md). The statements below describe the Lab 2
design delivery. The requested profile, book-catalogue, and reader amendments are complete
in Figma's user-flow, wireframe, Final UI, and prototype pages. Static reactions
have been validated and screenshots reviewed at 360/412 dp. Application
implementation details are recorded separately; these historical design records
do not constitute a live Figma prototype interaction run.
Figma delivery references are recorded in
[the change log](../docs/design-change-log.md).

## Source and product

- [Figma file](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=0-1).
- Current application brand: **VetaLife**. Topic: **Ăn gì không chết**.
  The supplied Figma file predates the repository rebrand; its original labels
  have not been updated by this repository change.
- Product purpose: help busy people record meals, observe habits, and learn about
  varied plant-based eating. The existing design does not diagnose disease.
- Persona: Vinh, 25, office worker; busy, sits for long periods, eats irregularly,
  and wants a small maintainable change with quick one-handed input.
- Success criteria from Figma: record a meal in under 30 seconds; see weekly
  recording frequency without counting calories; preserve entered data and retry
  when the network fails.

## Figma pages

| Page | Node |
| --- | --- |
| 01 User Flow | `0:1` |
| 02 Wireframe | `2:2` |
| 03 Final UI | `2:3` |
| 04 Design System | `2:4` |
| 05 Components | `2:5` |
| 06 Prototype | `2:6` |

## User flows

| Flow | Baseline observed in Figma | Requested design amendment |
| --- | --- | --- |
| 1 - Bắt đầu | Chào mừng -> Thiết lập mục tiêu -> Trang chủ | Chào mừng -> **Thông tin của bạn** -> Thiết lập mục tiêu -> Trang chủ |
| 2 - Ghi bữa ăn | Trang chủ -> Ghi bữa ăn -> Đang phân tích -> Kết quả -> Nhật ký | Keep this flow. Network error preserves the draft, offers retry, and permits editing the meal. |
| 3 - Theo dõi & học | Trang chủ -> Tiến trình tuần -> one generic Bài học nhỏ -> Đánh dấu đã đọc -> Cập nhật tuần | Trang chủ -> Tiến trình tuần -> **Bài học nhỏ / mục lục sách** -> **Chi tiết bài học** -> Đánh dấu đã đọc -> Cập nhật tuần |

The learning catalogue follows the original book's two-part hierarchy and order:
15 chapters in part 1 and 12 Daily Dozen categories in part 2 (27 core lessons),
with three supplementary part-2 overview/conclusion entries kept separate.
See [book curriculum](../docs/book-curriculum.md) for exact chapter titles and
printed/PDF source-page mapping. Do not treat catalogue metadata as completed
lesson prose or verified health guidance.

## Screen inventory

The original Final UI had 11 screens. The amended main inventory has 18 screens:
the original eleven plus 01A, 12, 13, and the four Lab 3 cloud feature additions (14, 14A, 15, 16).
Existing numbering is retained so meal logging links are not renumbered.

| Design screen | Role | Figma Node |
| --- | --- | --- |
| 01 Chào mừng | Existing entry screen | `6:2` |
| 01A Thông tin của bạn | New profile step in flow 1 | `166:426` |
| 02 Thiết lập mục tiêu | Existing goal choice after profile completion | `6:19` |
| 03 Trang chủ | Existing top-level destination | `6:42` |
| 04 Ghi bữa ăn | Existing meal input | `6:76` |
| 05 Đang phân tích | Existing loading state | `6:101` |
| 06 Kết quả | Existing meal result | `6:118` |
| 07 Lỗi kết nối | Existing recoverable error | `6:138` |
| 08 Nhật ký bữa ăn | Existing journal with entries | `6:155` |
| 09 Nhật ký trống | Existing empty journal | `6:186` |
| 10 Tiến trình tuần | Existing weekly progress and learning entry | `6:213` |
| 11 Bài học nhỏ - Phần 1 | Updated catalogue: 15 source chapters | `6:257` |
| 12 Bài học nhỏ - Phần 2 | New catalogue: 12 Daily Dozen categories and 3 supplementary entries | `166:470` |
| 13 Chi tiết bài học | New chapter reader/detail design | `166:628` |
| 14 Thông báo (Notifications) | Lịch sử thông báo & push payloads | [`185:1144`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=185-1144) |
| 14A Cấp quyền / Hộp thư trống | Android 13+ permission banner & empty state | [`185:1183`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=185-1183) |
| 15 Báo cáo PDF cá nhân | Giao diện xuất PDF & Cloudinary signed link | [`187:1302`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=187-1302) |
| 16 Cài đặt đám mây (Settings) | Cài đặt Remote Config & bảo trì tính năng | [`187:1330`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=187-1330) |

## Personal information

The user's requested information is name, age, date of birth, weight, and height.
Age is displayed as a **read-only value calculated from date of birth**, avoiding
two conflicting inputs.

| Field | Display/input behavior |
| --- | --- |
| Họ và tên | Text input with a visible label |
| Ngày sinh | Calendar/date input displayed as `dd/MM/yyyy` |
| Tuổi | Derived from date of birth and the current local date; not independently editable |
| Cân nặng | Positive finite number, explicit `kg` unit |
| Chiều cao | Positive finite number, explicit `cm` unit |

Show inline validation for missing name, invalid/future birth date, and invalid
weight/height. Preserve entered values when validation or saving fails. A loading
state prevents duplicate continuation. The form does not introduce BMI,
diagnosis, calorie targets, or other calculations beyond derived age.

These personal values belong to the user's profile. They must not be sent as
Analytics event parameters. Authentication and persistence are implementation
contracts still to be defined before real data is collected.

The Figma prototype demonstrates empty, filled, and invalid form snapshots at
360 and 412 dp. Clicking a field selects a prepared filled snapshot; it does not
type, parse dates, calculate arbitrary ages, or save real profile data. Validation
and saving behavior described above are the future application contract.
Filled and invalid snapshots were independently reviewed at both widths, including
the corrected required-height error.

## Current learning prototype

All 30 catalogue entries (27 core lessons and 3 supplementary entries) set the
selected display title, exact source title/page, and section before opening one
reusable reader. The reader is an educational navigation/reference template;
complete chapter summaries are not authored. Its mark-read action updates a
last-read feedback label on weekly progress. This is prototype feedback, not
persisted or independently tracked completion for every lesson.
Static wiring checks confirmed that each of the four catalogue variants has 15
rows and each row sets its three selection variables before navigating to the
correct shared reader. Title, source reference, and section text bindings were
verified; this does not constitute a live interaction or content-learning test.

## Design system and accessibility

Reuse the file's Roboto typography, existing color/spacing/radius tokens, and
Button, Text Field, Card, App Bar, and navigation components. The detailed mapping
is in [the Flutter handoff](../handoff/flutter-handoff.md). The new form and
catalogue must retain visible labels, readable units/errors, touch targets of at
least 48 dp, and layouts at 360/412 dp.
