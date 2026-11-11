# HƯỚNG DẪN THỰC THI CHI TIẾT DÀNH CHO NGƯỜI 3
**Dự án:** VetaLife · PRM393 Lab 3  
**Vai trò:** NGƯỜI 3 · THIẾT KẾ, PR REVIEW VÀ NỘP BÀI  
**Nhánh Git:** `task/design-review-submission` (nhánh từ `main` tại commit `2ecc063`)  
**Tài liệu tham chiếu:** `docs/requirements-reaudit.md`, `design/DESIGN.md`, `docs/design-traceability.md`, `docs/code-review.md`, `report/README.md`, `slides/README.md`.

---

## MỤC LỤC
1. [Tổng quan trách nhiệm & Phạm vi file](#1-tổng-quan-trách-nhiệm--phạm-vi-file)
2. [Quy trình làm việc & Thứ tự phụ thuộc](#2-quy-trình-làm-việc--thứ-tự-phụ-thuộc)
3. [Phần 1: Đồng bộ thiết kế Figma & Đối chiếu Fidelity](#3-phần-1-đồng-bộ-thiết-kế-figma--đối-chiếu-fidelity)
4. [Phần 2: Quy trình AI PR Review & Theo dõi 3 Fix Commits](#4-phần-2-quy-trình-ai-pr-review--theo-dõi-3-fix-commits)
5. [Phần 3: Biên soạn Báo cáo Lab03_SE194126.pdf (8–12 trang)](#5-phần-3-biên-soạn-báo-cáo-lab03_se194126pdf-812-trang)
6. [Phần 4: Thiết kế Slides Lab03_SE194126_slides.pdf (12–15 slides)](#6-phần-4-thiết-kế-slides-lab03_se194126_slidespdf-1215-slides)
7. [Phần 5: Kịch bản & Quay Video Demo (5–10 phút)](#7-phần-5-kịch-bản--quay-video-demo-510-phút)
8. [Checklist nghiệm thu trước khi bàn giao (Definition of Done)](#8-checklist-nghiệm-thu-trước-khi-bàn-giao-definition-of-done)

---

## 1. TỔNG QUAN TRÁCH NHIỆM & PHẠM VI FILE

### 1.1. File bạn độc quyền sở hữu (Write Access)
Bạn có toàn quyền chỉnh sửa và chịu trách nhiệm cao nhất về nội dung các file/thư mục sau:
* `design/` (Các tệp thiết kế, hình ảnh token, tài liệu thiết kế).
* `docs/design-traceability.md` (Bảng truy vết thiết kế giữa Figma và mã Flutter).
* `docs/fidelity-check.md` (Bảng đối chiếu sai lệch giao diện 360/412 dp).
* `docs/code-review.md` (Báo cáo kết quả review mã nguồn bằng AI).
* `report/` (Nơi đặt mã nguồn và tệp xuất bản `report/Lab03_SE194126.pdf`).
* `slides/` (Nơi đặt mã nguồn và tệp xuất bản `slides/Lab03_SE194126_slides.pdf`).
* Kịch bản video và tệp/đường dẫn video demo (5–10 phút).

### 1.2. File bạn KHÔNG ĐƯỢC tự ý sửa
* `functions/` và `lib/services/report_service.dart` (Do **Người 1** sở hữu).
* `e2e_test/`, `evidence/artemis/` và các file test thiết bị (Do **Người 2** sở hữu).
* *Lưu ý:* Nếu cần sửa file ngoài phạm vi, phải nhắn tin trao đổi với người sở hữu trước.

---

## 2. QUY TRÌNH LÀM VIỆC & THỨ TỰ PHỤ THUỘC

```
[BẮT ĐẦU NGAY]
       │
       ▼
Giai đoạn 1: Thiết kế & Đối chiếu Fidelity (Làm độc lập ngay)
       │ • Đọc tài liệu thiết kế & hiện trạng app
       │ • Đồng bộ Figma cho Notifications, Report, Settings (360/412 dp)
       │ • Cập nhật docs/design-traceability.md & docs/fidelity-check.md
       │
       ▼
Giai đoạn 2: AI PR Review (Khi Người 1 & Người 2 tạo Pull Request)
       │ • Chạy AI review trên PR của Người 1 & Người 2
       │ • Lập bảng ≥ 5 findings thuộc ≥ 2 nhóm (docs/code-review.md)
       │ • Phân loại Accepted / Rejected
       │ • Nhắc Người 1/2 tạo ≥ 3 commits riêng sửa các lỗi Accepted
       │
       ▼
Giai đoạn 3: Tổng hợp Báo cáo, Slides & Video (Khi nhận bàn giao từ N1 & N2)
       │ • Thu thập log, screenshot, số liệu test thật từ Người 1 & 2
       │ • Biên soạn Report (8–12 trang)
       │ • Thiết kế Slides (12–15 trang)
       │ • Dựng Video demo (5–10 phút)
       │
       ▼
[BÀN GIAO CHO ĐIỀU PHỐI VIÊN]
```

---

## 3. PHẦN 1: ĐỒNG BỘ THIẾT KẾ FIGMA & ĐỐI CHIẾU FIDELITY

### 3.1. Nhiệm vụ cần làm trên Figma
Hiện tại nhánh mã nguồn đã có 3 màn hình tính năng mới được tích hợp ở menu Home (`HomeScreen`), bạn cần thiết kế hoặc đồng bộ lên Figma:
1. **Màn hình Notifications (Thông báo):**
   * Danh sách lịch sử thông báo (tiêu đề, nội dung tóm tắt, thời gian nhận, trạng thái đã đọc/chưa đọc).
   * Thẻ / Banner nhắc cấp quyền thông báo trên Android 13+ (POST_NOTIFICATIONS).
   * Các trạng thái: *Empty* (chưa có thông báo nào), *Loading* (đang đồng bộ), *Error* (lỗi tải danh sách).
2. **Màn hình Report (Báo cáo dinh dưỡng cá nhân):**
   * Thẻ xem tóm tắt thông số tuần (calo, nhóm chất, bài học đã hoàn thành).
   * Nút hành động: "Xuất báo cáo PDF" (Generate PDF).
   * Trạng thái tạo báo cáo: *Generating spinner*, trạng thái tải lên Cloudinary, và nút "Mở liên kết tải xuống an toàn" (URL có chữ ký bảo mật).
   * Trạng thái lỗi: Mất mạng, file quá lớn, nút *Thử lại* (Retry).
3. **Màn hình Settings (Cài đặt cấu hình):**
   * Các công tắc điều khiển tính năng từ Remote Config:
     * Cờ `learning_module_enabled` (Bật/tắt xem bài học).
     * Cờ `report_export_enabled` (Bật/tắt tính năng xuất PDF).
   * Trạng thái giao diện phản hồi khi tính năng bị đóng từ Remote Config (thông báo tính năng tạm thời đóng, không cho bấm nút nhưng không làm sập ứng dụng).

### 3.2. Chuẩn kích thước & Viewports
* Bắt buộc có thiết kế ở cả 2 chuẩn màn hình:
  * **360 dp** (360 × 800 dp) — Chuẩn tham chiếu cơ sở của Android.
  * **412 dp** (412 × 915 dp) — Chuẩn màn hình thiết bị hiện đại (Pixel, Samsung cao cấp).
* Đảm bảo: Touch target tối thiểu **48 dp**, cỡ chữ nội dung tối thiểu **14 sp**, độ tương phản màu đạt chuẩn WCAG AA.

### 3.3. Cập nhật tài liệu:
* Mở file [docs/fidelity-check.md](file:///d:/Documents/PRM/PRM393_Lab03_SE194126/docs/fidelity-check.md):
  * Thêm các dòng đối chiếu cho 3 màn hình mới.
  * Gắn kèm đường dẫn Figma Node URL cụ thể (ví dụ: `https://www.figma.com/design/...?...node-id=...`).
  * Ghi rõ lý do sai lệch hợp lý (Adaptation / Deviation ID) như:
    * `RT-11`: Menu Home mở rộng thêm 3 tính năng Notifications, Report, Settings.
    * `RT-12`: Sử dụng SafeArea native của Flutter để tránh tai thỏ / thanh điều hướng hệ thống.
    * `RT-13`: Trạng thái Remote Config tắt tính năng hiển thị banner thay vì ẩn mất nút gây khó hiểu cho người dùng.
* Cập nhật file [docs/design-traceability.md](file:///d:/Documents/PRM/PRM393_Lab03_SE194126/docs/design-traceability.md): Khớp nối giữa ViewModel, mã nguồn Flutter và Figma node.

---

## 4. PHẦN 2: QUY TRÌNH AI PR REVIEW & THEO DÕI 3 FIX COMMITS

### 4.1. Điều kiện tiên quyết của một bài Review hợp lệ
* **Công cụ sử dụng:** Dùng AI (Antigravity Assistant, Gemini Code Assist, Claude) để rà soát diff.
* **Số lượng:** Tối thiểu **5 findings** được phát hiện.
* **Độ sâu:** Thuộc tối thiểu **2 nhóm danh mục khác nhau**:
  * *Nhóm 1: Security & Privacy (Bảo mật & Quyền riêng tư)*: Kiểm tra rò rỉ token, secret Cloudinary trong client, vi phạm phân quyền UID trong Firestore/Storage, lưu trữ URL download nhạy cảm.
  * *Nhóm 2: Concurrency & State Management (Bất đồng bộ & Quản lý trạng thái)*: Lỗi race condition khi sign-out mà tác vụ mạng vẫn đang chạy, khôi phục ảnh rò rỉ giữa 2 tài khoản, listener không được hủy dẫn đến memory leak.
  * *Nhóm 3: Error Handling & Network Resilience (Xử lý lỗi mạng)*: Ứng dụng treo khi mất mạng giữa chừng lúc upload Cloudinary, lỗi thiếu timeout, thiếu retry.
  * *Nhóm 4: UI/UX & Accessibility (Trải nghiệm & Khả năng tiếp cận)*: Thiếu Semantics label, touch target nhỏ hơn 48dp, mất nội dung khi xoay màn hình hoặc đổi cỡ chữ.

### 4.2. Cấu trúc bảng Review trong `docs/code-review.md`
Mỗi finding phải có đầy đủ thông tin:
| ID | Nhóm (Category) | Mức độ | File & Dòng (Link diff) | Mô tả vấn đề (AI output tóm tắt) | Quyết định | Lý do & Hướng xử lý |
|---|---|---|---|---|---|---|
| F12 | Security | P1 | `lib/services/report_service.dart#L45` | URL tải xuống có chữ ký bị in ra console log khi debug | **Accepted** | Cần xóa log hoặc che chuỗi token trước khi in |
| F13 | Concurrency | P2 | `lib/viewmodels/notification_view_model.dart#L78` | Gọi refresh khi dispose gây lỗi setState trên unmounted widget | **Accepted** | Thêm kiểm tra `if (!mounted) return;` |
| F14 | Error Handling | P2 | `functions/src/index.js#L112` | Thiếu kiểm tra kích thước file trước khi tạo chữ ký | **Accepted** | Thêm điều kiện chặn file > 10MB tại Cloud Function |
| F15 | UI/UX | P3 | `lib/screens/settings_screen.dart#L30` | Thiếu thông báo khi cờ Remote Config tắt | **Rejected** | Thiết kế đã có sẵn fallback component riêng |
| F16 | Security | P2 | `lib/services/auth_service.dart#L60` | Token Google Sign-in lưu vào biến static | **Accepted** | Đưa vào secure storage hoặc session ViewModel |

### 4.3. Theo dõi 3 Fix Commits độc lập
* Yêu cầu Người 1 hoặc Người 2 sau khi nhận review phải sửa ít nhất **3 lỗi Accepted** thành **3 commit riêng biệt** trên Git (không gộp chung vào 1 commit khổng lồ).
* Ví dụ cấu trúc commit message chuẩn:
  * `fix(report): redact signed download url from console logs (Fixes F12)`
  * `fix(notification): guard state update against unmounted widget (Fixes F13)`
  * `fix(functions): enforce maximum 10MB file limit on signed preset (Fixes F14)`
* Điền mã hash commit (ví dụ `a1b2c3d`) và liên kết commit vào bảng tổng kết trong `docs/code-review.md`.

---

## 5. PHẦN 3: BIÊN SOẠN BÁO CÁO `report/Lab03_SE194126.pdf` (8–12 TRANG)

> **Cảnh báo quan trọng:** Độ dài bắt buộc là **từ 8 đến 12 trang**. Nếu ít hơn 8 trang hoặc nhiều hơn 12 trang sẽ bị trừ điểm theo barem chấm của Lab 3.

### Khung đề cương 10 trang gợi ý chuẩn chỉnh:
* **Trang 1: Bìa & Thông tin chung**
  * Tên trường, môn học: PRM393 - Lập trình Di động với Cloud/Firebase.
  * Tên dự án: **VetaLife - Trợ lý lối sống & dinh dưỡng lành mạnh**.
  * Thông tin nhóm & phân công 3 người: Họ tên, MSSV (SE194126), vai trò đảm nhiệm (Người 1: Cloud/Backend; Người 2: Test/ARTEMIS; Người 3: Design/Review/Lead Deliverables).
  * Mục lục chi tiết.
* **Trang 2: Tổng quan đồ án & Tiêu chí nghiệm thu từ Lab 2**
  * Giới thiệu Persona người dùng (ví dụ: nhân viên văn phòng bận rộn muốn kiểm soát dinh dưỡng).
  * 3 Luồng người dùng chính (Flow 1: Onboarding & Thiết lập mục tiêu; Flow 2: Nhận diện & Ghi nhật ký bữa ăn; Flow 3: Thư viện bài học dinh dưỡng).
  * Tiêu chí thành công và kết quả đạt được từ Lab 2 làm nền tảng cho Lab 3.
* **Trang 3: Kiến trúc ứng dụng & Hệ thống thiết kế (Design System)**
  * Sơ đồ kiến trúc tổng thể (MVVM: Model - ViewModel - View kết hợp Service Layer).
  * Quản lý trạng thái bằng `Provider` / `ChangeNotifier` và Session Isolation.
  * Bảng ánh xạ Design System: Bảng mã màu (Tokens), font Roboto chuẩn, kích thước khoảng cách (spacing), và các widget dùng chung (`CustomButton`, `StatusCard`, `ErrorDialog`).
* **Trang 4: Bảng đối chiếu thiết kế (Design Fidelity & Deviations)**
  * Bảng tổng hợp đối chiếu giữa Figma và Flutter UI trên 2 màn hình 360 dp và 412 dp.
  * Giải trình chi tiết các sai lệch hợp lý (`RT-01` đến `RT-13`), chứng minh ứng dụng thích ứng tốt với thiết bị thực tế.
* **Trang 5: Dịch vụ Firebase 1 — Authentication, Firestore & Security Rules**
  * Luồng đăng nhập Google Sign-in: Sign-in, Cancel, Sign-out, Chuyển đổi tài khoản (Account switching).
  * Mô hình dữ liệu Firestore: Quy tắc cách ly dữ liệu cá nhân theo `request.auth.uid`.
  * Minh chứng chạy kiểm thử Firestore Security Rules (18/18 test case đạt).
* **Trang 6: Dịch vụ Cloud 2 — Cloudinary Private PDF & Cloud Functions**
  * Kiến trúc lưu trữ PDF an toàn: App gửi yêu cầu -> Firebase Functions cấp chữ ký (`createReportUploadSignature`) -> App upload trực tiếp lên Cloudinary dưới dạng `raw/authenticated` -> Lấy URL tải xuống tạm thời qua `getReportDownloadUrl`.
  * Xử lý lỗi: Mất mạng, file quá dung lượng cho phép, người dùng hủy thao tác.
  * *Bằng chứng từ Người 1:* Log Cloud Functions, ảnh dashboard Cloudinary (đã che secret/API key).
* **Trang 7: Dịch vụ Firebase 3 — FCM, Analytics, Crashlytics & Remote Config**
  * **FCM:** Xử lý 3 trạng thái (Foreground, Background, Terminated) và màn hình xin cấp quyền Android 13+.
  * **Analytics:** Bảng theo dõi tối thiểu 7 sự kiện người dùng (đính kèm ảnh DebugView sạch, không chứa thông tin cá nhân).
  * **Crashlytics:** Bằng chứng bắt lỗi Handled Error và Test Crash trên bản Debug (kèm Custom Key và User ID).
  * **Remote Config:** Cơ chế bật/tắt tính năng từ xa; minh chứng giao diện thay đổi tức thì mà không cần cài lại app.
* **Trang 8: Đảm bảo chất lượng & Báo cáo kiểm thử ARTEMIS E2E**
  * Bảng tổng hợp kết quả chạy kiểm thử ARTEMIS E2E (17 test cases × 3 lần chạy = 51 lượt chạy).
  * Tỷ lệ pass/fail thực tế, phân tích nguyên nhân các ca flaky hoặc fail.
  * Tóm tắt kết quả phiên kiểm thử khám phá (Exploratory Testing Session 15–30 phút).
* **Trang 9: Đánh giá mã nguồn (AI PR Review)**
  * Bảng tổng hợp 5 findings từ AI review (gắn link PR, số dòng code).
  * Minh chứng 3 commits sửa lỗi tương ứng của Người 1 và Người 2.
  * Bài học rút ra trong việc áp dụng AI hỗ trợ kiểm soát chất lượng mã nguồn.
* **Trang 10: Khó khăn, Bài học kinh nghiệm & Hướng phát triển**
  * Những thách thức lớn trong quá trình thực hiện Lab 3 (Ví dụ: Giới hạn gói Firebase Spark với Cloud Functions, độ trễ mạng khi upload Cloudinary).
  * Bài học kinh nghiệm trong phối hợp nhóm 3 người và quản lý mã nguồn Git.
  * Danh sách các công cụ AI đã hỗ trợ trong dự án.
  * Đề xuất hướng hoàn thiện cho đồ án tốt nghiệp cuối kỳ (Final Assignment).

---

## 6. PHẦN 4: THIẾT KẾ SLIDES `slides/Lab03_SE194126_slides.pdf` (12–15 SLIDES)

> **Cảnh báo quan trọng:** Độ dài bắt buộc là **từ 12 đến 15 slides**. Mỗi slide phải có tiêu đề rõ ràng, ưu tiên hình ảnh/sơ đồ/ảnh chụp thực tế, không đưa các đoạn văn bản quá dài.

### Cấu trúc 14 slides mẫu:
1. **Slide 1:** Bìa bài thuyết trình (Tên dự án VetaLife, PRM393 Lab 3, Nhóm thực hiện & MSSV SE194126).
2. **Slide 2:** Bối cảnh, Persona & Mục tiêu dự án.
3. **Slide 3:** Kiến trúc phần mềm: MVVM + Clean Architecture trên Flutter.
4. **Slide 4:** Design System & Tính toàn vẹn thiết kế (Figma vs App 360/412 dp).
5. **Slide 5:** Luồng nghiệp vụ chính: Onboarding, Meal Logging AI & Learning Library.
6. **Slide 6:** Firebase Authentication & Phân quyền bảo mật dữ liệu Firestore (UID Isolation).
7. **Slide 7:** Lưu trữ đám mây Cloudinary: Upload PDF bảo mật với Signed Preset & Cloud Functions.
8. **Slide 8:** Firebase Cloud Messaging (FCM): Nhận thông báo đa trạng thái & Quyền Android 13+.
9. **Slide 9:** Giám sát vận hành: Firebase Analytics (DebugView) & Crashlytics.
10. **Slide 10:** Quản lý cấu hình động: Firebase Remote Config không cần rebuild app.
11. **Slide 11:** Kiểm thử tự động với ARTEMIS E2E Harness: Độ bao phủ & Tỷ lệ Pass thực tế.
12. **Slide 12:** Đảm bảo chất lượng bằng AI PR Review: 5 Findings & 3 Fix Commits thực tế.
13. **Slide 13:** Thách thức kỹ thuật, Giải pháp khắc phục & Bài học nhóm.
14. **Slide 14:** Lời cảm ơn, Q&A và Liên kết Repository/Video Demo.

---

## 7. PHẦN 5: KỊCH BẢN & QUAY VIDEO DEMO (5–10 PHÚT)

### 7.1. Tiêu chuẩn video
* **Thời lượng:** Chuẩn từ **5:00 đến 10:00 phút** (dưới 5 phút hoặc quá 10 phút sẽ vi phạm quy chế nộp bài).
* **Độ phân giải:** 1080p (Full HD), âm thanh thuyết minh rõ ràng, không lẫn tạp âm.
* **Bảo mật:** Tuyệt đối che/không để lộ: API Secret, Private Token, Email cá nhân thật, thông tin thẻ tín dụng/billing.

### 7.2. Kịch bản phân cảnh chi tiết (Storyboarding)

| Thời gian | Nội dung phân cảnh | Thao tác trên màn hình | Dẫn chứng kỹ thuật cần làm nổi bật |
|---|---|---|---|
| **00:00 – 01:00** | Giới thiệu dự án & Đăng nhập Google | Mở app, bấm Đăng nhập bằng Google. Thử hủy đăng nhập (Cancel), sau đó đăng nhập thành công. | Kiểm tra UID trên Firebase Auth và Firestore database. |
| **01:00 – 02:30** | Trải nghiệm 3 luồng ứng dụng | Đi qua Onboarding (Flow 1) -> Ghi nhật ký bữa ăn & Nhận diện AI (Flow 2) -> Đọc bài học (Flow 3). | Dữ liệu lưu đúng UID cá nhân, tính toán dinh dưỡng tức thì. |
| **02:30 – 03:45** | Xuất báo cáo PDF & Cloudinary | Vào màn hình Report -> Bấm "Tạo báo cáo tuần" -> Hiển thị spinner -> Tải lên Cloudinary thành công -> Bấm mở link xem PDF. | Giải thích cơ chế chữ ký bảo mật từ Cloud Function và URL ngắn hạn. |
| **03:45 – 05:00** | Kiểm chứng FCM (Thông báo đẩy) | Cấp quyền trên Android 13+ -> Bắn thông báo test từ Firebase Console: thử khi app đang mở (Foreground) và app đang đóng (Background/Terminated). Chạm vào thông báo để mở đúng màn hình. | Log FCM Token, payload tin nhắn, badge thông báo. |
| **05:00 – 06:15** | Kiểm chứng Remote Config | Đang mở app -> Vào Firebase Console đổi cờ `learning_module_enabled` từ `true` sang `false` -> Quay lại app bấm Fetch -> Giao diện lập tức khóa module bài học và hiện thông báo bảo trì mà không cần tắt app/rebuild. | Tính năng cập nhật tức thời (Live update). |
| **06:15 – 07:30** | Kiểm chứng Analytics & Crashlytics | Thực hiện một số thao tác trong app -> Mở Firebase Analytics DebugView chiếu thấy các sự kiện bắn lên. Kích hoạt nút Test Crash / Handled Error -> Chiếu dashboard Crashlytics nhận log lỗi kèm custom key UID. | Bảo mật không rò rỉ PII trong sự kiện Analytics. |
| **07:30 – 08:45** | Xử lý lỗi & Trường hợp biên | Thử ngắt mạng Wifi/4G khi đang upload ảnh hoặc tạo report -> App hiện màn hình báo lỗi mạng kèm nút "Thử lại" (Retry). Đăng xuất tài khoản (Sign-out) -> Bộ nhớ đệm bị xóa sạch an toàn. | Khả năng chịu lỗi và tính độc lập phiên người dùng. |
| **08:45 – 09:30** | Tổng kết | Chiếu trang kết quả test ARTEMIS và slide tổng kết. Cảm ơn người xem. | Đồng bộ thông tin với báo cáo. |

---

## 8. CHECKLIST NGHIỆM THU TRƯỚC KHI BÀN GIAO (DEFINITION OF DONE)

Hãy kiểm tra lại từng mục trước khi gửi link cho Điều phối viên dự án:
- [ ] **Nhánh Git:** Toàn bộ công việc thực hiện trên nhánh `task/design-review-submission`.
- [ ] **Figma Links:** Đã có link Node Figma cho 3 màn mới (Notifications, Report, Settings) và các trạng thái runtime.
- [ ] **Fidelity Record:** Đã cập nhật file `docs/fidelity-check.md` và `docs/design-traceability.md` với các sai lệch hợp lệ (deviations).
- [ ] **AI PR Review:** File `docs/code-review.md` có đầy đủ:
  - Tối thiểu 5 findings có gắn link dòng code cụ thể.
  - Các findings thuộc ít nhất 2 nhóm khác nhau.
  - Phân loại rõ ràng Accepted / Rejected kèm lý do.
  - Ít nhất 3 commits sửa lỗi riêng biệt có gắn hash và link PR.
- [ ] **Tệp Báo cáo:** Tệp `report/Lab03_SE194126.pdf` đã hoàn thành, mở được bình thường, **độ dài đúng 8–12 trang**.
- [ ] **Tệp Slides:** Tệp `slides/Lab03_SE194126_slides.pdf` đã hoàn thành, mở được bình thường, **độ dài đúng 12–15 slides**.
- [ ] **Tệp Video:** Video demo hoàn chỉnh, thời lượng **từ 5:00 đến 10:00 phút**, âm thanh rõ ràng, có link đính kèm trong `README.md`.
- [ ] **Đồng bộ số liệu:** Số lượng ca kiểm thử, tỷ lệ pass/fail của ARTEMIS hoàn toàn khớp nhau giữa Report, Slides, Video và `docs/test-report.md`.
- [ ] **Quyền riêng tư & Bảo mật:** Đã kiểm tra và che toàn bộ: API Secret, Firebase Private Key, Token, Email cá nhân, URL Cloudinary có chữ ký trong mọi hình ảnh, báo cáo, slides và video.
- [ ] **Không sửa phạm vi ngoài:** Không có commit nào của Người 3 làm thay đổi code trong `functions/`, `e2e_test/`, `lib/services/report_service.dart`.

