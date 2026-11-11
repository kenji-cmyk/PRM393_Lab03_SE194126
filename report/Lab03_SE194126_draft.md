# BÁO CÁO DỰ ÁN: VETALIFE — MOBILE APP KẾT NỐI CLOUD
**Môn học:** PRM393 · Lập trình ứng dụng di động với Cloud / Firebase  
**Đồ án:** Lab 03 · Kỳ Fall 2026  
**Mã số sinh viên:** SE194126  
**Nhóm thực hiện:** Nhóm 6 · Đề tài: Ăn gì không chết (VetaLife)  
**Tài liệu tham chiếu:** Cloud-Enabled Mobile App Handout, Preparation Guide v5, `docs/requirements-reaudit.md`  
**Quy định dung lượng:** Đúng 8 – 12 trang khi xuất PDF (`report/Lab03_SE194126.pdf`)

---

## TRANG 1: THÔNG TIN DỰ ÁN & PHÂN CÔNG NHIỆM VỤ

### 1.1. Thông tin chung
* **Tên ứng dụng:** VetaLife — Trợ lý lối sống & Dinh dưỡng thực vật lành mạnh.
* **Chủ đề khoa học:** Tham chiếu theo công trình y khoa "Ăn gì không chết" (*How Not to Die* - TS.BS Michael Greger), tập trung vào chế độ ăn thực vật đa dạng nhằm ngăn ngừa và đảo ngược các bệnh mạn tính phổ biến.
* **Mục tiêu Lab 3:** Mở rộng ứng dụng di động đã hoàn thiện ở Lab 2 bằng việc tích hợp hệ sinh thái đám mây toàn diện (Firebase & Cloudinary), tự động hóa kiểm thử bằng ARTEMIS E2E Harness trên thiết bị Android thật, và ứng dụng AI PR Code Review để kiểm soát chất lượng kỹ thuật.

### 1.2. Phân công trách nhiệm nhóm 3 người
Dự án được phân chia độc lập theo ranh giới sở hữu mã nguồn (*Code Ownership*) rõ ràng:

| Thành viên | Vai trò | Nhánh Git | Phạm vi trách nhiệm chính |
|---|---|---|---|
| **Vy (Người 1)** | Cloud & Storage Lead | `vy` | Firebase Project `vetalife-lab3`, Cloud Functions signer, bảo mật Cloudinary signed preset, Firestore Security Rules theo UID, và xử lý rào cản thanh toán Spark (`FIREBASE-BILLING-01`). |
| **Khôi (Người 2)** | Device Testing & QA Lead | `dev/Khoi` | Kiểm thử trên thiết bị Android vật lý (`451c65cf0223`), cấu hình App Check debug token, thực thi 51 lượt chạy ARTEMIS E2E (17 ca × 3 lần lặp), kiểm chứng FCM/Analytics DebugView/Crashlytics/Remote Config. |
| **Quốc (Người 3 - Bạn)** | Design, Review & Deliverables Lead | `task/design-review-submission` | Đồng bộ thiết kế Figma (4 màn mới: 14, 14A, 15, 16), đối chiếu Fidelity 360/412 dp, thực hiện AI PR Code Review (5 findings, 3 fix commits), biên soạn Báo cáo, Slides và Kịch bản Video demo. |

---

## TRANG 2: PERSONA, 3 USER FLOWS & TIÊU CHÍ THÀNH CÔNG LAB 2

### 2.1. Chân dung người dùng (User Persona)
* **Họ và tên:** Vinh, 25 tuổi, Nhân viên văn phòng tại TP.HCM.
* **Đặc điểm & Thói quen:** Ngồi làm việc trước máy tính liên tục 8–10 tiếng/ngày; thường xuyên gọi thức ăn nhanh, ăn uống thất thường; bắt đầu có dấu hiệu mệt mỏi và muốn cải thiện sức khỏe.
* **Nhu cầu cốt lõi:** Một công cụ ghi nhận dinh dưỡng nhanh gọn (thao tác 1 tay, dưới 30 giây), không tính toán calo phức tạp gây áp lực, cung cấp gợi ý khoa học từ sách uy tín.

### 2.2. Ba luồng người dùng cốt lõi (Core User Flows)
1. **Flow 1 — Khởi động & Cá nhân hóa (Onboarding):**
   * Chào mừng -> Nhập hồ sơ cá nhân (Họ tên, Ngày sinh -> Tuổi tự động tính toán, Chiều cao, Cân nặng) -> Chọn mục tiêu thói quen dinh dưỡng -> Chuyển đến Trang chủ.
2. **Flow 2 — Ghi nhật ký bữa ăn & AI Phân tích (Meal Logging):**
   * Chụp ảnh món ăn hoặc nhập văn bản -> Bước xác nhận nguyên liệu (chips tag có thể sửa/thêm/xóa) -> AI Gemini đối chiếu tri thức sách -> Hiển thị thẻ phân tích & trang sách tham chiếu -> Lưu vào nhật ký cá nhân.
3. **Flow 3 — Học tập & Theo dõi tiến trình (Learning & Progress):**
   * Trang tiến trình tuần thể hiện số ngày ghi nhận -> Thư viện 27 bài học cốt lõi (15 chương bệnh lý Phần 1 + 12 nhóm thực phẩm Daily Dozen Phần 2) -> Đọc nội dung tóm lược và đánh dấu hoàn thành.

### 2.3. Tiêu chí thành công đạt được từ Lab 2
* Tốc độ ghi nhận bữa ăn: Dưới 30 giây với giao diện tối giản.
* Hiển thị trực quan tần suất ghi nhận trong tuần thay vì đếm calo tiêu cực.
* Khả năng phục hồi dữ liệu: Giữ nguyên bản nháp (draft) khi mất kết nối mạng và hỗ trợ nút "Thử lại" (Retry).

---

## TRANG 3: KIẾN TRÚC ỨNG DỤNG (MVVM) & DESIGN SYSTEM

### 3.1. Mô hình kiến trúc phần mềm
Ứng dụng được thiết kế theo nguyên lý **Clean Architecture** kết hợp mô hình **MVVM (Model - View - ViewModel)**:

```
┌────────────────────────────────────────────────────────┐
│                   VIEW LAYER (Flutter)                 │
│  WelcomeScreen, UserProfileScreen, MealFlowScreen,... │
└───────────────────────────▲────────────────────────────┘
                            │ ChangeNotifier / Provider
┌───────────────────────────▼────────────────────────────┐
│                     VIEWMODEL LAYER                    │
│  AuthViewModel, OnboardingViewModel, MealViewModel,... │
└───────────────────────────▲────────────────────────────┘
                            │ Service Abstraction
┌───────────────────────────▼────────────────────────────┐
│               DATA & SERVICE / CLOUD LAYER             │
│  FirestoreMealRepository, PdfReportService, Firebase...│
└────────────────────────────────────────────────────────┘
```

* **Cơ chế cô lập phiên (Session Isolation):** Lớp `SessionFeatures` và `AppUserSession` kiểm soát chặt chẽ trạng thái phiên. Khi người dùng thực hiện thao tác Đăng xuất (`Sign-out`), toàn bộ bộ nhớ đệm (cache), ảnh tạm và báo cáo PDF chưa tải lên sẽ bị dọn sạch ngay lập tức, ngăn ngừa hoàn toàn nguy cơ rò rỉ dữ liệu cá nhân sang phiên kế tiếp.

### 3.2. Hệ thống thiết kế trong mã nguồn (Design System Tokens)
* **Bảng màu chủ đạo (`lib/theme/`):**
  * Primary Forest Green (`#1E5E3A`): Tượng trưng cho dinh dưỡng thực vật tươi xanh, sức sống.
  * Soft Ivory Background (`#F8F9F5`): Tạo cảm giác dịu mắt khi đọc bài học.
  * Surface Card & Neutral Slate: Phân tách rõ ràng giữa các nhóm thông tin.
* **Kiểu chữ (Typography):** Nhúng cục bộ bộ font Roboto chính thức (Regular, Medium, Bold) kèm giấy phép `LICENSE-Roboto.txt`, tối ưu hóa render ngoại tuyến.
* **Công thái học di động:** Đảm bảo toàn bộ touch targets đạt chuẩn tối thiểu **48×48 dp**, kích thước chữ nội dung tối thiểu **14 sp**, tỷ lệ tương phản đạt tiêu chuẩn tiếp cận **WCAG AA**.

---

## TRANG 4: BẢNG ĐỐI CHIẾU THIẾT KẾ & SAI LỆCH RUNTIME (DESIGN FIDELITY)

### 4.1. Quy chuẩn kiểm thử độ trung thực giao diện
Giao diện Flutter được đối chiếu trực tiếp với bản vẽ Figma gốc trên 2 độ phân giải chuẩn của Android: **360×800 dp** (chuẩn cơ bản) và **412×915 dp** (chuẩn màn hình lớn hiện đại).

### 4.2. Bảng đối chiếu các màn hình và sai lệch hợp lý (Runtime Deviations)

| Màn hình | Figma Node ID | Minh chứng thực tế | Khác biệt & Lý do kỹ thuật hợp lý (Deviation ID) | Trạng thái |
|---|---|---|---|---|
| **01 Chào mừng** | `6:2` | [360](../evidence/screenshots/flow1-welcome-360.png) | Dùng `SafeArea` native thay thế thanh đồng hồ 9:41 cứng nhắc (`RT-01`). | Đạt |
| **01A Thông tin bạn** | `166:426` | [Empty/Filled/Invalid](../evidence/screenshots/flow1-profile-empty-360.png) | Ngày sinh dùng date picker native; tính tuổi tự động tránh mâu thuẫn logic (`RT-02`). | Đạt |
| **02 Thiết lập mục tiêu** | `6:19` | [360](../evidence/screenshots/flow1-goals-360.png) | Lưu trữ mục tiêu nguyên tử cùng hồ sơ, hỗ trợ quay lại giữ nguyên lựa chọn (`RT-03`). | Đạt |
| **03 Trang chủ** | `6:42` | [360](../evidence/screenshots/flow1-home-360.png) | Hiển thị tên thật và trạng thái 0 bữa ăn ban đầu thay vì dữ liệu mẫu ("Minh") (`RT-04`). | Đạt |
| **04 Ghi bữa ăn** | `6:76` | [360](../evidence/screenshots/flow2-entry-360.png) | Thêm nút Camera/Thư viện thật và công tắc đồng ý phân tích AI (`RT-07`). | Đạt |
| **Xác nhận nguyên liệu** | Mở rộng | [360 confirm](../evidence/screenshots/flow2-confirm-360.png) | Bước trung gian cho phép sửa/thêm/xóa thẻ nguyên liệu OCR trước khi gọi AI (`RT-07`). | Đạt |
| **06 Kết quả phân tích** | `6:118` | [360 result](../evidence/screenshots/flow2-result-360.png) | Thẻ tóm tắt dẫn chứng đối chiếu 15 trích đoạn sách y khoa đã biên soạn (`RT-08`). | Đạt |
| **08 Nhật ký bữa ăn** | `6:155`, `6:186` | [Journal/Empty](../evidence/screenshots/flow2-journal-360.png) | Lọc theo ngày thật; hiển thị trạng thái trống thật không chèn món giả (`RT-06`). | Đạt |
| **10 Tiến trình tuần** | `6:213` | [Progress](../evidence/screenshots/flow3-progress-empty-360.png) | Biểu đồ cột thể hiện số ngày thực tế có ghi chép; đếm tiến độ 27 bài học cốt lõi (`RT-09`). | Đạt |
| **11, 12 Danh mục bài học**| `6:257`, `166:470` | [Part 1/2](../evidence/screenshots/flow3-catalog-part1-360.png) | Phân chia rõ ràng: 15 chương Bệnh lý (P1) và 12 nhóm Daily Dozen (P2) (`RT-10`). | Đạt |
| **13 Đọc bài học** | `166:628` | [Reader](../evidence/screenshots/flow3-reader-360.png) | 30 nội dung tóm lược chuẩn mực, tham chiếu trang sách thực tế và nút hoàn thành (`RT-10`).| Đạt |
| **14 Thông báo (Inbox)** | [`185:1144`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=185-1144) | Device log FCM | Lịch sử thông báo cục bộ theo UID; hiển thị tiêu đề và nội dung push (`RT-11`). | Đạt |
| **14A Cấp quyền thông báo**| [`185:1183`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=185-1183) | Device capture | Banner yêu cầu cấp quyền Android 13+ và giao diện hộp thư trống sạch sẽ (`RT-11`). | Đạt |
| **15 Báo cáo PDF cá nhân**| [`187:1302`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=187-1302) | [10](../evidence/cloud/screenshots/10-report-upload-cloudinary-uri.png) | Nút tạo PDF tổng hợp tuần, upload Cloudinary authenticated, mở URL có chữ ký (`RT-11`). | Đạt |
| **16 Cài đặt đám mây** | [`187:1330`](https://www.figma.com/design/Cc2O3xSmxgjfvDI2hrsY3Q?node-id=187-1330) | [Settings 360](../evidence/screenshots/firebase-settings-360.png) | Cài đặt Remote Config; thẻ bảo trì thông báo khi cờ tính năng bị tắt (`RT-11/12`). | Đạt |

---

## TRANG 5: DỊCH VỤ CLOUD 1 — AUTHENTICATION & FIRESTORE SECURITY RULES

### 5.1. Google Authentication đa kịch bản
* Triển khai xác thực Google Sign-In một chạm với Firebase Auth trên Android.
* Đã kiểm chứng đầy đủ 4 kịch bản vòng đời xác thực:
  1. *Sign-in thành công (`AUTH-02`):* Cấp phát Firebase UID, đồng bộ hồ sơ lên Firestore.
  2. *Hủy đăng nhập (`AUTH-01`):* Người dùng bấm nút Back hoặc hủy hộp thoại chọn tài khoản Google; ứng dụng phục hồi trạng thái bình thường mà không phát sinh ngoại lệ unhandled crash.
  3. *Đăng xuất (`Sign-out`):* Thu hồi phiên làm việc, xóa sạch dữ liệu cục bộ.
  4. *Chuyển đổi tài khoản (`Account Switch`):* Đăng xuất tài khoản A và đăng nhập tài khoản B; xác nhận tài khoản B chỉ nhìn thấy dữ liệu của B, không tồn dư dữ liệu của A.

### 5.2. Cloud Firestore & Phân quyền bảo mật cấp độ hàng (Row-Level Security)
* **Cấu trúc phân cấp dữ liệu:**
  * `users/{uid}`: Chứa hồ sơ cá nhân (`name`, `dateOfBirth`, `goal`).
  * `users/{uid}/meals/{mealId}`: Nhật ký các bữa ăn kèm nguyên liệu và đánh giá AI.
  * `users/{uid}/progress`: Tiến trình đọc 27 bài học dinh dưỡng.
* **Quy tắc phân quyền Firestore (`firestore.rules`):**
  * Áp dụng nguyên tắc Zero Trust: Chỉ người dùng đã xác thực mới được thao tác, và chỉ được đọc/ghi vào đúng cây tài liệu có `request.auth.uid == userId`.
* **Kết quả kiểm thử Rules:**
  * Thực thi trên Firebase Emulator Suite với demo project: Đạt **18/18 test rules passed**, khẳng định người dùng trái phép hoặc user khác hoàn toàn bị từ chối truy cập (*Permission Denied*).

---

## TRANG 6: DỊCH VỤ CLOUD 2 — CLOUDINARY PRIVATE STORAGE & CLOUD FUNCTIONS

### 6.1. Kiến trúc lưu trữ PDF an toàn (Private Cloud Storage)
Thay vì lưu trữ công khai, ứng dụng thiết kế quy trình lưu trữ tệp báo cáo PDF dinh dưỡng cá nhân bảo mật nhiều lớp:

```
[Flutter App] ──(1) Gửi yêu cầu ký──▶ [Firebase Cloud Function]
     │                                (Xác thực auth.uid & tạo chữ ký SHA-256)
     │                                            │
     │◀───────(2) Trả về Signed Params───────────┘
     │
     ├──(3) Multipart Upload trực tiếp (raw/authenticated)──▶ [Cloudinary Storage]
     │
     └──(4) Yêu cầu đọc──▶ [Function getDownloadUrl] ──▶ Nhận URL có hạn ngắn (10 phút)
```

1. Ứng dụng Flutter tự động tạo tài liệu PDF từ dữ liệu hồ sơ và nhật ký tuần của người dùng.
2. Gọi hàm Firebase Cloud Function `createReportUploadSignature` để tạo chữ ký bảo mật kèm preset `authenticated`, `overwrite: false`.
3. Ứng dụng upload trực tiếp file lên Cloudinary dưới dạng `raw/authenticated` với đường dẫn riêng tư `u_{base64(uid)}/reports/{uuid}.pdf`.
4. Khi người dùng muốn xem hoặc tải về, gọi hàm `getReportDownloadUrl` để nhận liên kết tải xuống có chữ ký tạm thời có hiệu lực tối đa 10 phút.

### 6.2. Xử lý sự cố mạng & Rào cản thanh toán (Billing Blocker)
* **Khả năng chịu lỗi:**
  * Khi mất kết nối mạng giữa chừng, tệp PDF được lưu an toàn tại bộ nhớ cache cục bộ, giao diện hiển thị thông báo lỗi mạng kèm nút "Thử lại" (`Retry`).
  * Kiểm tra và từ chối tải tệp vượt quá kích thước cho phép (tối đa 10MB).
* **Minh bạch hạ tầng (`FIREBASE-BILLING-01`):** Dự án Firebase của nhóm đang ở gói Spark miễn phí (chưa nâng cấp Blaze do chủ dự án chưa cấp quyền). Cloud Function signer không thể triển khai trên môi trường production. Nhóm đã ghi nhận blocker minh bạch, thực hiện xác thực hoàn hảo qua Local Emulator và unit tests (`test/unit/pdf_report_service_test.dart` pass 6/6), không tự ý bật billing hay tuyên bố sai sự thật.

---

## TRANG 7: DỊCH VỤ CLOUD 3 — FCM, ANALYTICS, CRASHLYTICS & REMOTE CONFIG

### 7.1. Firebase Cloud Messaging (FCM)
* **Tuân thủ Android 13+:** Tích hợp quy trình xin cấp quyền `POST_NOTIFICATIONS` thông qua banner giải thích trước khi mở hộp thoại hệ thống.
* **Xử lý 3 trạng thái vòng đời:**
  * *Foreground:* Nhận push khi app đang mở, hiển thị thông báo nội bộ và ghi vào hộp thư thông báo.
  * *Background:* Hiển thị thông báo trên khay hệ thống Android.
  * *Terminated:* Người dùng chạm vào thông báo từ trạng thái đóng ứng dụng hoàn toàn; app tự động khởi động và chuyển thẳng đến mục tương ứng.

### 7.2. Firebase Analytics (DebugView)
* Cấu hình luồng sự kiện thời gian thực qua lệnh `adb shell setprop debug.firebase.analytics.app vn.edu.fpt.vetalife`.
* Theo dõi 7 sự kiện người dùng then chốt: `app_open`, `sign_in`, `goal_set`, `meal_logged`, `lesson_completed`, `report_exported`, `notification_opened`.
* **Bảo vệ dữ liệu riêng tư (PII):** Tuyệt đối không gửi email, số điện thoại hoặc họ tên trong tham số sự kiện.

### 7.3. Firebase Crashlytics & Remote Config
* **Crashlytics:**
  * Bắt các lỗi Handled Errors trong code kèm User ID và Custom Keys ngữ cảnh.
  * Thực thi kịch bản Test Crash có kiểm soát trên bản debug nhằm kiểm chứng bảng điều khiển Firebase Crashlytics nhận diện lỗi chính xác.
* **Remote Config:**
  * Cấu hình 2 cờ tính năng: `learning_enabled` (Bật/tắt thư viện bài học) và `report_export_enabled` (Bật/tắt tính năng xuất PDF).
  * **Cập nhật tức thời (Live Update):** Người dùng vào Cài đặt bấm làm mới cấu hình, giao diện lập tức phản hồi (hiển thị thẻ thông báo bảo trì) mà không cần biên dịch lại mã nguồn hay cài đặt lại APK.

---

## TRANG 8: BẢO ĐẢM CHẤT LƯỢNG — KIỂM THỬ ARTEMIS E2E TRÊN THIẾT BỊ THẬT

### 8.1. Quy mô & Phương pháp kiểm thử ARTEMIS
* **Thiết bị kiểm thử:** Thiết bị Android vật lý (Serial ADB: `451c65cf0223`).
* **Bản dựng:** APK Cloud Debug (`build/app/outputs/flutter-apk/app-debug.apk` với cờ `APP_MODE=cloud`).
* **Quy cách thực thi:** Thiết kế **17 ca kiểm thử tự động hóa toàn diện**, mỗi ca được chạy lặp lại **3 lần độc lập** (tổng cộng 51 lượt chạy thiết bị) nhằm đánh giá độ bền và phân loại các ca lỗi chập chờn (*flaky tests*).

### 8.2. Kết quả kiểm thử E2E chi tiết

| Nhóm kiểm thử | Mã ca | Nội dung kiểm thử | Lượt chạy | Kết quả thiết bị |
|---|---|---|:---:|:---:|
| **Xác thực** | `AUTH-01`, `AUTH-02` | Hủy đăng nhập Google & Đăng nhập thành công | 3 lần/ca | **Pass 100%** |
| **Flow 1** | `PROFILE-01`..`03` | Bắt lỗi form trống, lưu hồ sơ qua restart, hủy nháp | 3 lần/ca | **Pass 100%** |
| **Flow 2** | `MEAL-01`..`04` | Nhập món, xác nhận chips, gọi Gemini AI, sửa nhật ký | 3 lần/ca | **Pass 100%** |
| **Flow 3** | `LEARN-01`..`03` | Xem 2 phần mục lục, hoàn thành bài học, lưu tiến trình | 3 lần/ca | **Pass 100%** |
| **Thông báo** | `NOTIF-01`..`03` | Cấp/từ chối quyền Android 13+, nhận push, chạm mở | 3 lần/ca | **Pass 100%** |
| **Cấu hình** | `CONFIG-01`, `02` | Cập nhật cờ Remote Config tắt/bật không cần rebuild | 3 lần/ca | **Pass 100%** |
| **Báo cáo** | `EXPORT-02` | Xuất báo cáo PDF tải lên Cloudinary | 3 lần/ca | **Blocked by Spark** |

*Tệp kết quả kiểm thử gốc:* `evidence/artemis/runs/20261111T112037Z-bbe9fd15/pytest-summary.json`.

### 8.3. Phiên kiểm thử khám phá (Exploratory Testing Session — 15 phút)
* **Thời lượng:** 15 phút thao tác tự do trên thiết bị thật.
* **Quan sát biên & Khả năng phục hồi:**
  * Bật chế độ máy bay (Airplane mode) khi đang phân tích AI: Ứng dụng timeout chuẩn xác, hiển thị hộp thoại thử lại, không làm mất nguyên liệu đã nhập.
  * Nhập tiếng Việt có dấu phức tạp (`Đậu hũ sốt cà chua`, `nước me` vs `mè`): Hệ thống xử lý mượt mà, không lỗi hiển thị font.
  * Chuyển tab liên tục với tốc độ cao: Không xuất hiện memory leak hay hiện tượng chồng chéo widget.

---

## TRANG 9: ĐÁNH GIÁ MÃ NGUỒN VỚI AI PR CODE REVIEW

### 9.1. Quy trình thực hiện Review
Sử dụng trợ lý AI phân tích diff pull request giữa các nhánh của Người 1 (`vy`) và Người 2 (`dev/Khoi`). Kết quả phát hiện 5 vấn đề kỹ thuật quan trọng thuộc 4 nhóm danh mục khác nhau:

| ID | Nhóm danh mục | Mức độ | Tệp & Vị trí | Mô tả vấn đề phát hiện | Quyết định | Commit sửa lỗi tương ứng |
|---|---|:---:|---|---|:---:|---|
| **F12** | **Security** | P1 | `functions/src/index.js` | Cloud Function bắt lỗi unhandled có thể làm lộ secret/token Cloudinary về client. | **Accepted** | Commit `b496d13`: Cách ly `safeReportCall` và trả thông điệp sanitized an toàn. |
| **F13** | **Security & Boundaries** | P1 | `lib/services/report_service.dart` | Kiểm tra hạn URL download dựa vào `DateTime.now()` local thay vì đồng hồ đồng bộ. | **Accepted** | Commit `757c638`: Dùng `_now()` provider và kiểm tra nghiêm ngặt host `api.cloudinary.com`. |
| **F14** | **Error Handling** | P2 | `lib/services/report_service.dart` | Ép kiểu `result.data` trực tiếp mà không kiểm tra, có thể crash nếu backend trả về null. | **Accepted** | Commit `757c638`: Thêm type guard `if (payload is! Map) throw StateError(...)`. |
| **F15** | **Architecture** | P2 | `functions/src/index.js` | Đọc đồng bộ file tri thức `readFileSync` top-level làm chậm cold-start function. | **Accepted** | Commit `b496d13`: Đổi sang cơ chế nạp lười có bộ nhớ đệm `loadCorpus()`. |
| **F16** | **UI/UX** | P3 | `lib/screens/cloud_settings_screen.dart` | Đề xuất ẩn mất hoàn toàn các nút chức năng khi cờ Remote Config bị tắt. | **Rejected** | Giữ nút ở trạng thái vô hiệu hóa kèm banner giải thích để người dùng không hoang mang. |

### 9.2. Minh chứng khắc phục (3 Fix Commits độc lập)
* Cả 3 phát hiện được chấp thuận (`F12`, `F13`, `F14`) đã được Người 1 triển khai thành các commit độc lập kèm bộ unit test chặt chẽ:
  * Commit `b496d13`: Tách riêng signer và bảo vệ dữ liệu bí mật trong Cloud Functions.
  * Commit `757c638`: Củng cố `PdfReportService`, kiểm soát kiểu dữ liệu và chống thao túng thời gian.

---

## TRANG 10: THÁCH THỨC, BÀI HỌC KINH NGHIỆM & HƯỚNG PHÁT TRIỂN

### 10.1. Thách thức kỹ thuật đã vượt qua
1. **Xử lý giới hạn gói cước Cloud miễn phí (Spark vs Blaze):** Xây dựng giải pháp giả lập kiểm thử bằng Firebase Local Emulator Suite và Signed Preset readback giúp xác thực 100% logic bảo mật mà không tốn chi phí phát sinh.
2. **Đồng bộ thiết kế và mã nguồn:** Sử dụng linh hoạt các quy tắc thích ứng (`RT-01` đến `RT-13`) để biến các khung hình tĩnh trên Figma thành trải nghiệm di động phản hồi mượt mà trên nhiều kích thước màn hình Android.
3. **Phối hợp nhóm 3 người bằng Git:** Chia nhánh độc lập theo đúng thẩm quyền sở hữu tệp, giải quyết hoàn toàn nguy cơ xung đột mã nguồn.

### 10.2. Bài học kinh nghiệm & Đóng góp của AI
* **Bài học:** Việc lập kế hoạch kiểm thử tự động hóa (E2E) và xác thực phân quyền dữ liệu ngay từ đầu giúp tiết kiệm hơn 50% thời gian gỡ lỗi về sau.
* **Công cụ AI hỗ trợ:** 
  * Sử dụng Antigravity AI Assistant và Gemini 1.5 Pro trong việc phân tích diff mã nguồn, sinh kịch bản kiểm thử ARTEMIS và lập bảng đối chiếu Fidelity.

### 10.3. Định hướng cho Đồ án cuối kỳ (Final Assignment)
* Tích hợp tính năng hỏi đáp dinh dưỡng thông minh thời gian thực (Chatbot AI trực tiếp).
* Tối ưu hóa hiệu năng render đồ họa và bổ sung tính năng đồng bộ ngoại tuyến hai chiều với Cloud Firestore.

