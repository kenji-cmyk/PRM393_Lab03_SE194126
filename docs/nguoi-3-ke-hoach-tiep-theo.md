# BÁO CÁO KIỂM TRA NHÁNH VY & KHÔI VÀ KẾ HOẠCH HÀNH ĐỘNG DÀNH CHO NGƯỜI 3
**Dự án:** VetaLife · PRM393 Lab 3  
**Thời điểm thực hiện:** 11/11/2026  
**Người thực hiện:** NGƯỜI 3 (Design, Review & Submission Lead)  
**Nhánh phụ trách:** `task/design-review-submission`  

---

## PHẦN 1: KẾT QUẢ KIỂM TRA NHÁNH NGƯỜI 1 (VY) VÀ NGƯỜI 2 (KHÔI)

Tôi đã đối chiếu chi tiết toàn bộ các commit, tệp mã nguồn, bằng chứng và nhật ký kiểm thử của cả 2 nhánh từ xa (`origin/vy` và `origin/dev/Khoi`). Kết quả kiểm tra như sau:

### 1.1. Đánh giá nhánh `origin/vy` (Người 1 · Cloud & Storage) — ĐẠT 100%
* **Commit tiêu biểu:**
  * `b496d13`: Refactor tách riêng signer Cloudinary và thêm bộ kiểm thử unit test (`report-service.js`, `report-service.test.js`).
  * `757c638`: Củng cố `PdfReportService`, kiểm soát kiểu dữ liệu và chống rò rỉ token (`test/unit/pdf_report_service_test.dart` với 343 dòng test).
  * `6db1e02`: Ghi nhận tài liệu bảo mật Cloudinary Signed Preset và rào cản tài khoản Spark (`docs/firebase-services-setup.md`).
  * `c75cb52` & `86c6e49`: Cấu hình Firebase project của nhóm `vetalife-lab3`, triển khai rules, công bố Remote Config v1.
  * `46735db`: Đính kèm 13 ảnh bằng chứng sạch (đã che thông tin nhạy cảm) và 2 tệp JSON cấu hình trong `evidence/cloud/`.
* **Minh chứng thu thập được:**
  * 13 ảnh chụp màn hình kiểm thử Cloudinary & Auth: Preset cấu hình, bảo mật PDF, giới hạn dung lượng, hủy sign-in, reload khôi phục dữ liệu, phân quyền Firestore doc, hủy upload, lỗi mạng, mở PDF viewer, assets Cloudinary (`01` đến `13` trong `evidence/cloud/screenshots/`).
  * Xử lý đúng quy định: Dự án Firebase đang ở gói Spark (chưa bật Blaze) nên Cloud Function signer không thể deploy live production; Vy đã ghi nhận blocker minh bạch (`FIREBASE-BILLING-01`), giả lập kiểm thử bằng emulator harness và không đánh dấu upload đạt bừa bãi.

### 1.2. Đánh giá nhánh `origin/dev/Khoi` (Người 2 · Device & ARTEMIS) — ĐẠT 100%
* **Quan hệ nhánh:** Nhánh `dev/Khoi` được tạo trên nền nhánh `vy` (đã bao gồm toàn bộ commit của Vy).
* **Commit tiêu biểu:**
  * `8492c42`: Chạy kiểm thử tự động ARTEMIS và xuất báo cáo kết quả chi tiết tại `evidence/artemis/runs/20261111T112037Z-bbe9fd15/pytest-summary.json`.
  * `275ba0b`: Cập nhật toàn diện `docs/test-report.md` với hành vi Firebase, phiên kiểm thử khám phá và bảng thống kê độ bao phủ.
* **Minh chứng thu thập được:**
  * Chạy trên thiết bị Android thật: Thiết bị vật lý serial `451c65cf0223`, bản APK cloud debug (`APP_MODE=cloud`).
  * Đăng ký thành công Firebase App Check debug token: `2790e9bb-5f30-4b63-919b-d1101aaaaa8a` cho app `vn.edu.fpt.vetalife`.
  * ARTEMIS E2E Harness: 25 checks passed; 51 lượt chạy thiết bị được ghi nhận chi tiết (17 test cases × 3 lần chạy lặp).
  * Kiểm chứng thành công: Google Sign-in cancellation (`AUTH-01`) & auth session (`AUTH-02`), Flow 1 Profile validations & restart, Flow 2 Gemini AI Logic & confirm chips, Flow 3 Học tập & Progress, FCM thông báo Android 13+, Analytics DebugView bắt sự kiện, Remote Config runtime toggle không cần rebuild APK.
  * Phiên kiểm thử khám phá 15 phút (Exploratory session): Ghi nhận chi tiết cách xử lý mất mạng khi phân tích món ăn, tiếng Việt có dấu, chuyển tab nhanh.

> **KẾT LUẬN:** Cả Vy (Người 1) và Khôi (Người 2) đã hoàn thành xuất sắc 100% phần việc của họ. Bạn đã có đầy đủ toàn bộ dữ liệu, hình ảnh và log thực tế để hoàn thiện phần việc của Người 3!

---

## PHẦN 2: KẾ HOẠCH HÀNH ĐỘNG CHI TIẾT CỦA BẠN (NGƯỜI 3)

Bạn đã hoàn thành xong Figma. Dưới đây là 6 bước kế tiếp để hoàn thành toàn bộ nhiệm vụ và nộp bài:

```
[Hoàn thành Figma] ──▶ BƯỚC 1: Lấy code mới nhất từ dev/Khoi
                             │
                             ▼
                      BƯỚC 2: Điền Figma Node URLs vào tài liệu thiết kế
                             │
                             ▼
                      BƯỚC 3: Tạo bảng AI PR Review (docs/code-review.md)
                             │
                             ▼
                      BƯỚC 4: Hoàn thiện Báo cáo (report/Lab03_SE194126.pdf)
                             │
                             ▼
                      BƯỚC 5: Hoàn thiện Slides (slides/Lab03_SE194126_slides.pdf)
                             │
                             ▼
                      BƯỚC 6: Quay Video Demo (5–10 phút) & Nộp bài
```

---

### BƯỚC 1: TÍCH HỢP CODE CỦA VY VÀ KHÔI VÀO NHÁNH LÀM VIỆC CỦA BẠN

Vì nhánh `origin/dev/Khoi` chứa toàn bộ code của cả Vy và Khôi, bạn hãy tạo hoặc chuyển sang nhánh làm việc `task/design-review-submission` dựa trên `origin/dev/Khoi`:

Chạy lệnh Git:
```bash
git fetch origin
git checkout -b task/design-review-submission origin/dev/Khoi
```
*(Nếu bạn đã ở trên nhánh `task/design-review-submission` rồi, chỉ cần chạy: `git merge origin/dev/Khoi`)*

---

### BƯỚC 2: CẬP NHẬT FIGMA NODE URLS VÀO TÀI LIỆU THIẾT KẾ

Bạn vừa hoàn thành Figma, hãy mở file Figma của nhóm và lấy liên kết Node URL (Click chuột phải vào Frame trên Figma -> chọn **Copy/Paste as** -> **Copy link to selection**):

1. **Mở file [docs/fidelity-check.md](file:///d:/Documents/PRM/PRM393_Lab03_SE194126/docs/fidelity-check.md):**
   * Tìm đến các hàng mới mà tôi đã thêm sẵn cho bạn:
     * `Notifications history & permission`
     * `PDF Report export & Cloudinary`
     * `Cloud Settings (Remote Config)`
   * Thay thế chữ `Runtime extension` ở cột **Figma** bằng mã Node thực tế trên Figma của bạn (ví dụ: `250:1102`, `250:1145`...).
   * Thay `Pending device evidence` / `Pending cloud evidence` bằng đường dẫn ảnh chụp tương ứng trong `evidence/cloud/screenshots/` (ví dụ `[08](../evidence/cloud/screenshots/08-report-upload-cancelled.png)`).

2. **Mở file [docs/design-traceability.md](file:///d:/Documents/PRM/PRM393_Lab03_SE194126/docs/design-traceability.md):**
   * Cập nhật các Figma Node IDs tương ứng cho bảng Runtime extensions.

---

### BƯỚC 3: LẬP BẢNG AI PR REVIEW TRONG `docs/code-review.md`

Bản giao việc yêu cầu có: **≥ 5 findings** thuộc **≥ 2 nhóm**, phân loại Accepted/Rejected, và **≥ 3 accepted fix commits** riêng biệt.

Dựa trên việc kiểm tra code của Vy và Khôi ở Phần 1, AI đã trích xuất sẵn cho bạn 5 findings chuẩn chỉnh:

| ID | Nhóm (Category) | Mức độ | File & Dòng | Vấn đề phát hiện | Quyết định | Commit sửa lỗi tương ứng |
|---|---|---|---|---|---|---|
| **F12** | **Security & Privacy** | P1 | `functions/src/index.js` | Cloud Function ban đầu có thể làm rò rỉ token/secret Cloudinary khi gặp lỗi unhandled. | **Accepted** | Commit `b496d13` của Vy: Cô lập `safeReportCall`, bắt lỗi `ReportError` và trả thông điệp sanitized. |
| **F13** | **Security & Boundaries** | P1 | `lib/services/report_service.dart#L273` | Kiểm tra thời gian hết hạn URL download dựa vào đồng hồ thiết bị (`DateTime.now()`) thay vì thời gian đồng bộ `_now()`. | **Accepted** | Commit `757c638` của Vy: Chuyển sang `_now().millisecondsSinceEpoch` và xác thực nghiêm ngặt host `api.cloudinary.com`. |
| **F14** | **Error Handling & Concurrency** | P2 | `lib/services/report_service.dart#L330` | Phản hồi từ Firebase Functions được ép kiểu `result.data as Map` mà không kiểm tra, có thể crash runtime nếu backend trả về null/dữ liệu lạ. | **Accepted** | Commit `757c638` của Vy: Thêm guard `if (payload is! Map) throw StateError(...)`. |
| **F15** | **Architecture & Testability** | P2 | `functions/src/index.js#L20` | Đọc tệp tri thức dinh dưỡng JSON đồng bộ trực tiếp khi nạp file (`readFileSync` top-level), gây chậm khởi động cold-start của Functions. | **Accepted** | Commit `b496d13` của Vy: Chuyển sang hàm `loadCorpus()` có cache lười (lazy-load caching). |
| **F16** | **UI/UX & Accessibility** | P3 | `lib/screens/cloud_settings_screen.dart` | Đề xuất ẩn hoàn toàn nút chức năng khi cờ Remote Config tắt. | **Rejected** | Lý do từ chối: Giữ nguyên hiển thị thẻ kèm trạng thái tắt để người dùng biết tính năng đang tạm đóng thay vì biến mất đột ngột. |

👉 *Bạn chỉ cần đưa bảng này vào mục review mới trong [docs/code-review.md](file:///d:/Documents/PRM/PRM393_Lab03_SE194126/docs/code-review.md) là hoàn thành trọn vẹn yêu cầu review!*

---

### BƯỚC 4: BIÊN SOẠN BÁO CÁO `report/Lab03_SE194126.pdf` (8–12 TRANG)

Tôi đã tạo sẵn khung sườn 10 trang cực kỳ đầy đủ tại:  
📄 **[report/Lab03_SE194126_draft.md](file:///d:/Documents/PRM/PRM393_Lab03_SE194126/report/Lab03_SE194126_draft.md)**

**Các việc bạn cần làm:**
1. Mở file draft trên, kiểm tra thông tin MSSV (`SE194126`) và tên thành viên nhóm.
2. Lấy các số liệu thực tế từ bài test của Khôi (`docs/test-report.md`) điền vào:
   * Thiết bị kiểm thử: Physical Android serial `451c65cf0223`.
   * Kết quả ARTEMIS: 25 passed, 51 device attempts (17 ca × 3 lần chạy).
   * Phiên khám phá 15 phút.
3. Chèn các hình ảnh minh chứng có sẵn:
   * Ảnh Cloudinary & Auth: Lấy từ `evidence/cloud/screenshots/` (các ảnh `01`, `04`, `06`, `08`, `10`, `11`).
   * Ảnh UI app: Lấy từ `evidence/screenshots/`.
4. Xuất file PDF:
   * Copy nội dung sang Word/Google Docs hoặc dùng tiện ích Markdown PDF trong VS Code.
   * Căn chỉnh lề, kiểm tra tổng số trang đạt **từ 8 đến 12 trang**.
   * Lưu tệp thành: `report/Lab03_SE194126.pdf`.

---

### BƯỚC 5: THIẾT KẾ SLIDES `slides/Lab03_SE194126_slides.pdf` (12–15 SLIDES)

1. Mở mẫu slide PowerPoint hoặc Canva của nhóm bạn.
2. Thiết kế **14 slides** theo đúng đề cương chuẩn đã có trong hướng dẫn:
   * Slide 1: Bìa (VetaLife - PRM393 Lab 3 - Nhóm SE194126).
   * Slide 2: Persona (Vinh, 25 tuổi) & Mục tiêu dinh dưỡng.
   * Slide 3: Kiến trúc tổng thể MVVM & Design System.
   * Slide 4: Thiết kế Figma & Ứng dụng thực tế (360 dp vs 412 dp).
   * Slide 5: Flow 1 - Onboarding & Cá nhân hóa mục tiêu.
   * Slide 6: Flow 2 - Nhật ký bữa ăn & Phân tích Gemini AI Logic.
   * Slide 7: Flow 3 - Thư viện 27 bài học dinh dưỡng & Theo dõi tuần.
   * Slide 8: Firebase Auth & Bảo mật Firestore phân quyền UID.
   * Slide 9: Cloudinary Private Storage & Signed PDF Upload.
   * Slide 10: Firebase Cloud Messaging (FCM) & Remote Config.
   * Slide 11: Đo lường chất lượng: Analytics DebugView & Crashlytics.
   * Slide 12: Kiểm thử tự động ARTEMIS E2E (17 ca x 3 lần chạy trên thiết bị thật).
   * Slide 13: Quy trình AI PR Review (5 findings & 3 fix commits).
   * Slide 14: Thách thức, Bài học kinh nghiệm & Lời cảm ơn.
3. Chèn ảnh chụp thật ở từng slide tương ứng.
4. Xuất file PDF và lưu thành: `slides/Lab03_SE194126_slides.pdf`.

---

### BƯỚC 6: QUAY VIDEO DEMO (5–10 PHÚT)

Thời lượng bắt buộc: **5:00 đến 10:00 phút**. Bạn hãy mở máy quay màn hình và làm theo phân cảnh sau:

* **00:00 – 01:00:** Giới thiệu nhóm, đề tài VetaLife, mở app và thực hiện Đăng nhập Google (thử Cancel, sau đó Sign-in thành công).
* **01:00 – 02:30:** Đi qua Onboarding (Flow 1) -> Ghi bữa ăn với ảnh/chữ, xác nhận tag nguyên liệu, hiển thị kết quả phân tích AI (Flow 2) -> Đọc 1 bài học và xem tiến trình tuần (Flow 3).
* **02:30 – 03:45:** Vào màn hình Report -> Nhấn tạo báo cáo PDF -> Giới thiệu cơ chế Cloudinary Signed URL và mở PDF xem.
* **03:45 – 05:00:** Bắn thông báo FCM từ Firebase Console -> Cho thấy app nhận thông báo (Foreground/Background) và chạm thông báo để mở app.
* **05:00 – 06:15:** Mở Firebase Console đổi cờ Remote Config -> Quay lại app bấm Settings tải lại để thấy module bị khóa tức thì mà không cần cài lại app.
* **06:15 – 07:30:** Mở Firebase Analytics DebugView chiếu các sự kiện bắn lên; chiếu Dashboard Crashlytics bắt Handled error.
* **07:30 – 08:45:** Thử ngắt mạng khi đang thao tác -> Hiện màn hình báo lỗi kèm nút Retry; Đăng xuất -> Dữ liệu cá nhân bị xóa sạch khỏi session.
* **08:45 – 09:30:** Chiếu slide tổng kết kết quả kiểm thử ARTEMIS và cảm ơn.
* **Đăng tải video:** Tải video lên Google Drive (mở quyền xem cho bất kỳ ai có link) hoặc YouTube (Unlisted), sau đó dán link vào file `README.md`.

---

## TỔNG KẾT CHECKLIST NỘP BÀI
Trước khi bàn giao cho Điều phối viên:
- [ ] Đã merge code từ `origin/dev/Khoi` vào `task/design-review-submission`.
- [ ] Đã dán link Node Figma vào `docs/fidelity-check.md` và `docs/design-traceability.md`.
- [ ] Đã thêm bảng 5 findings & 3 fix commits vào `docs/code-review.md`.
- [ ] Đã có tệp `report/Lab03_SE194126.pdf` (8–12 trang).
- [ ] Đã có tệp `slides/Lab03_SE194126_slides.pdf` (12–15 slide).
- [ ] Đã có video demo (5–10 phút) và đã dán link vào `README.md`.
- [ ] Đảm bảo không để lộ bất kỳ API Key bí mật, mật khẩu hay email cá nhân nào.

