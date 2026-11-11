# SLIDES THUYẾT TRÌNH: VETALIFE — CLOUD-ENABLED MOBILE APP
**Môn học:** PRM393 · Fall 2026  
**Nhóm đồ án:** Lab 03 · Mã SV: SE194126  
**Độ dài:** Đúng 14 slides (Quy định: 12–15 slides)  
**Tệp xuất bản:** `slides/Lab03_SE194126_slides.pdf`

---

### SLIDE 1: TRANG BÌA (TITLE SLIDE)
* **Tiêu đề lớn:** VetaLife — Trợ lý lối sống & Dinh dưỡng lành mạnh
* **Phụ đề:** Ứng dụng Di động kết nối Cloud & Hệ sinh thái Firebase / Cloudinary
* **Môn học:** PRM393 - Lập trình Di động nâng cao
* **Thông tin nhóm:** MSSV: SE194126 | Lớp: SE18... | Giảng viên hướng dẫn: ...
* **Phân công 3 thành viên:**
  * Người 1 (Vy): Cloud Services, Cloud Functions & Cloudinary Storage
  * Người 2 (Khôi): Device Testing, ARTEMIS E2E Harness & Firebase Telemetry
  * Người 3 (Bạn): Design Systems, AI PR Review & Deliverables Lead

---

### SLIDE 2: BỐI CẢNH DỰ ÁN & PERSONA NGƯỜI DÙNG
* **Vấn đề thực tế:** Người trẻ hiện đại bận rộn, ngồi nhiều, ăn uống thất thường, thiếu công cụ theo dõi dinh dưỡng đơn giản không áp lực.
* **Cơ sở khoa học:** Dựa trên công trình nghiên cứu "Ăn gì không chết" (How Not to Die - Dr. Michael Greger).
* **Persona đại diện:** Vinh, 25 tuổi, nhân viên văn phòng.
* **Mục tiêu cốt lõi:**
  * Ghi nhận bữa ăn trong < 30 giây.
  * Theo dõi tần suất tuần trực quan (không đếm calo gây căng thẳng).
  * Tiếp cận 27 bài học dinh dưỡng chuẩn mực dễ hiểu.

---

### SLIDE 3: KIẾN TRÚC TỔNG THỂ ỨNG DỤNG (MVVM)
* **Mô hình Clean Architecture & MVVM:**
  * **View (Flutter UI):** Reactive Widgets, chia nhỏ theo component tái sử dụng.
  * **ViewModel (State Management):** Sử dụng `ChangeNotifier` & `Provider`, quản lý trạng thái độc lập từng luồng.
  * **Model & Repository:** Phân tầng dữ liệu cục bộ và dữ liệu đám mây.
* **Cơ chế cô lập phiên (Session Isolation):**
  * `SessionFeatures` đảm bảo dọn sạch toàn bộ cache và dữ liệu tạm khi đăng xuất, ngăn ngừa rò rỉ dữ liệu giữa các phiên người dùng.

---

### SLIDE 4: DESIGN SYSTEM & TÍNH TOÀN VẸN THIẾT KẾ (FIDELITY)
* **Chuẩn hóa Design Tokens:**
  * Màu sắc chủ đạo: Forest Green (`#1E5E3A`), Ivory Background.
  * Kiểu chữ: Roboto nhúng cục bộ (Regular, Medium, Bold).
  * Quy chuẩn công thái học: Touch target ≥ 48 dp, cỡ chữ nội dung ≥ 14 sp.
* **Đối chiếu Viewport đa màn hình:**
  * Thử nghiệm và tương thích hoàn hảo trên cả 2 độ phân giải: **360×800 dp** và **412×915 dp**.
  * Bảng sai lệch hợp lý (`RT-01` -> `RT-13`): SafeArea tránh tai thỏ, picker ngày sinh native, banner Remote Config thân thiện.

---

### SLIDE 5: 3 LUỒNG NGHIỆP VỤ CỐT LÕI (CORE FLOWS)
* **Flow 1 — Bắt đầu (Onboarding):**
  * Nhập hồ sơ cá nhân (tính tuổi tự động từ ngày sinh) -> Chọn mục tiêu lối sống -> Trang chủ.
* **Flow 2 — Ghi nhật ký bữa ăn & AI Phân tích:**
  * Chụp ảnh/nhập món -> Xác nhận nguyên liệu (chips tag) -> Gemini AI Logic đối chiếu tri thức sách -> Lưu nhật ký.
* **Flow 3 — Học tập & Tiến trình:**
  * Thống kê số ngày ghi nhận trong tuần -> Mục lục 27 bài học chia làm 2 phần (Bệnh lý & Daily Dozen) -> Đánh dấu hoàn thành.

---

### SLIDE 6: FIREBASE AUTHENTICATION & FIRESTORE SECURITY RULES
* **Google Sign-in đa kịch bản:**
  * Xử lý trơn tru: Đăng nhập thành công, Hủy đăng nhập (Cancel), Đăng xuất (Sign-out), Chuyển đổi tài khoản (Account Switch).
* **Bảo mật Firestore cấp độ hàng (Row-level Security):**
  * Cấu trúc đường dẫn: `/users/{uid}/meals/{mealId}` và `/users/{uid}/progress`.
  * Quy tắc bảo mật: `request.auth.uid == resource.data.ownerId`.
  * **Kết quả:** Đạt **18/18 test rules** trên Firebase Emulator, chứng minh tài khoản A tuyệt đối không truy cập được dữ liệu tài khoản B.

---

### SLIDE 7: LƯU TRỮ ĐÁM MÂY CLOUDINARY & FIREBASE FUNCTIONS
* **Mô hình xuất báo cáo PDF bảo mật:**
  * App gửi yêu cầu cấp chữ ký -> Cloud Function `createReportUploadSignature` ký số bảo mật.
  * App upload tệp trực tiếp lên Cloudinary dưới dạng `raw/authenticated` với Signed Preset.
  * Xem lại báo cáo qua URL tải xuống có thời hạn ngắn (`getReportDownloadUrl`).
* **Khả năng chịu lỗi:**
  * Chống rò rỉ token khi gặp lỗi mạng; hỗ trợ Retry lưu trữ offline tạm thời.
  * Xử lý minh bạch giới hạn gói Spark (`FIREBASE-BILLING-01`).

---

### SLIDE 8: FIREBASE CLOUD MESSAGING (FCM)
* **Đa trạng thái vòng đời ứng dụng:**
  * **Foreground:** Nhận thông báo trong app, cập nhật ngay vào Inbox thông báo.
  * **Background:** Đẩy thông báo lên thanh hệ thống Android.
  * **Terminated:** Chạm vào thông báo để khởi động app và điều hướng đến màn hình chi tiết.
* **Tuân thủ nền tảng Android 13+:**
  * Quản lý quyền `POST_NOTIFICATIONS` chuyên biệt, có màn hình giải thích quyền trước khi yêu cầu hệ thống.

---

### SLIDE 9: GIÁM SÁT VẬN HÀNH: ANALYTICS & CRASHLYTICS
* **Firebase Analytics (DebugView):**
  * Bắt và ghi nhận 7 sự kiện cốt lõi: `app_open`, `sign_in`, `goal_set`, `meal_logged`, `lesson_completed`, `report_exported`, `notification_opened`.
  * **Bảo vệ quyền riêng tư:** Tuyệt đối không gửi thông tin nhận dạng cá nhân (PII) trong tham số sự kiện.
* **Firebase Crashlytics:**
  * Bắt các ngoại lệ Handled Errors kèm ngữ cảnh người dùng (`user_id`, `custom_keys`).
  * Thực hiện kịch bản Test Crash có kiểm soát trên bản debug.

---

### SLIDE 10: QUẢN LÝ TÍNH NĂNG ĐỘNG VỚI REMOTE CONFIG
* **Kiểm soát tính năng từ xa (Feature Flags):**
  * Cờ 1: `learning_module_enabled` (Bật/tắt thư viện bài học).
  * Cờ 2: `report_export_enabled` (Bật/tắt tính năng xuất PDF).
* **Trải nghiệm người dùng vượt trội:**
  * Giao diện cập nhật tức thì (Live Update) sau khi nạp cấu hình mới.
  * Không làm crash app, không yêu cầu người dùng phải khởi động lại hay cài đặt lại APK.

---

### SLIDE 11: KIỂM THỬ TỰ ĐỘNG ARTEMIS E2E TRÊN THIẾT BỊ THẬT
* **Quy mô kiểm thử:**
  * Thiết bị vật lý: Android Device serial `451c65cf0223` (Build Cloud Debug).
  * 17 Test cases tự động hóa toàn diện, chạy lặp lại **3 lần mỗi ca** (Tổng cộng 51 lượt chạy).
* **Kết quả đo lường:**
  * Bộ harness offline: 25/25 checks passed.
  * Kiểm thử khám phá (Exploratory Testing Session): 15 phút thử thách các tình huống ngắt mạng đột ngột, nhập tiếng Việt có dấu, xoay màn hình.

---

### SLIDE 12: ĐẢM BẢO CHẤT LƯỢNG BẰNG AI PR CODE REVIEW
* **Quy trình Review hiện đại:**
  * Sử dụng trợ lý AI phân tích diff pull request giữa các nhánh `vy` và `dev/Khoi`.
* **5 Phát hiện trọng yếu (Findings):**
  * **F12 (P1 - Security):** Nguy cơ lộ secret Cloudinary trong unhandled error -> Đã khắc phục (`b496d13`).
  * **F13 (P1 - Security):** Thời gian URL tải dựa vào giờ máy local -> Đã đổi sang thời gian server (`757c638`).
  * **F14 (P2 - Error Handling):** Ép kiểu response Cloud Function không an toàn -> Thêm runtime type guard (`757c638`).
  * **F15 (P2 - Performance):** Đọc file JSON đồng bộ làm chậm cold-start -> Chuyển sang lazy cache (`b496d13`).
  * **F16 (P3 - UX):** Đề xuất ẩn nút khi tắt Remote Config -> Từ chối để giữ trải nghiệm nhất quán.

---

### SLIDE 13: BÀI HỌC KINH NGHIỆM & THÁCH THỨC ĐÃ VƯỢT QUA
* **Thách thức kỹ thuật:**
  * Vượt qua rào cản hạn chế của tài khoản Cloud miễn phí (Spark vs Blaze) bằng kiến trúc mock/emulator minh bạch.
  * Phối hợp Git nhịp nhàng giữa 3 nhánh độc lập mà không xảy ra xung đột merge.
  * Duy trì độ trung thực thiết kế (Fidelity) giữa bản vẽ Figma và code Flutter thực tế.
* **Bài học rút ra:**
  * Tầm quan trọng của việc viết Unit Test và E2E Test tự động hóa ngay từ đầu.
  * Tận dụng sức mạnh của AI trong việc phản biện mã nguồn và kiểm soát chất lượng.

---

### SLIDE 14: TỔNG KẾT & LIÊN KẾT MINH CHỨNG
* **Trạng thái hoàn thành:** Đạt 100% các tiêu chí nghiệm thu của Lab 3.
* **Liên kết kho lưu trữ (Repository):** `https://github.com/PRM393-SE194126/vetalife`
* **Video Demo (5–10 phút):** [Đường dẫn video trên Google Drive / YouTube]
* **Lời cảm ơn:** Cảm ơn Thầy/Cô và các bạn đã theo dõi phần trình bày của nhóm!
* **Q&A:** Sẵn sàng giải đáp các câu hỏi phản biện.

