# Kết nối Firebase cho VetaLife

Ứng dụng VetaLife đã có code Google Sign-In và lưu hồ sơ trên Cloud Firestore.
Cấu hình client hiện tham chiếu Firebase project `vetalife-24f03`; đăng nhập và
lưu/đọc lại hồ sơ, nhật ký trên dịch vụ thật vẫn cần xác minh. Ngày **2026-11-04**,
rules emulator đạt **9/9**, triển khai `firestore:rules` thành công và đọc lại
rules production khớp tệp cục bộ, gồm quyền nhật ký và giới hạn chủ tài khoản.
Lần triển khai này không thay đổi indexes, dữ liệu hoặc billing.
Android application ID đã đổi thành `vn.edu.fpt.vetalife` và được đăng ký lại
trong Firebase với App ID `1:455537300059:android:6bf4a62f2e23bb6b91257e`.
Cấu hình client phải được lấy từ đăng ký mới; không chỉ sửa `package_name`
trong cấu hình cũ. Cấu hình chính thức đã được tải lại; SHA-1 debug hiện có đã
được đăng ký cho app mới, cùng Android và web OAuth client trong cấu hình.
Cần xác minh Google Sign-In và toàn bộ luồng lưu/đọc lại, cô lập tài khoản trước
khi dùng chế độ cloud với dữ liệu thật.

Flow 2 mặc định dùng **Firebase AI Logic + Gemini Developer API trên Spark**.
CLI đã khởi tạo AI Logic cho Android/web app, provider hiện là
`gemini-developer-api` và App Check của AI Logic là `ENFORCED`; không đổi billing.
Tiếp tục đăng ký debug token theo thiết bị hoặc cấu hình provider/site key web
theo [hướng dẫn Flow 2](flow2-setup.md). API App Check đã bật; token exchange và
phép thử kết nối `gemini-3.6-flash` qua AI Logic đều trả HTTP 200. Ngày
**2026-11-04**, kiểm thử RPC/adapter phân tích với dữ liệu tổng hợp đạt HTTP 200,
bốn trích dẫn và bốn liên hệ sức khỏe qua bộ kiểm tra; OCR riêng đọc được chữ
trên PNG tổng hợp và không nhận nhầm thành món ăn. Token thử nghiệm đã thu hồi,
tệp JWT tạm đã xóa; không gửi hồ sơ hoặc ảnh người dùng. Các phép thử này chưa
xác minh SDK attestation trên thiết bị, UI/camera native hoặc độ chính xác với
bữa ăn thật. Kết quả và lỗi HTTP 500 từng quan sát có trong
[hướng dẫn Flow 2](flow2-setup.md#trạng-thái-project-hiện-tại--2026-11-04).
Đường này không cần Gemini secret hoặc deploy
Functions. `functions/` và `firebase.functions.legacy.json` chỉ giữ phương án
máy chủ Blaze cũ; không phải bước bắt buộc của cấu hình hiện tại.

## Chạy ngay khi chưa có Firebase

```powershell
flutter pub get
flutter run --dart-define=APP_MODE=preview
```

Chế độ mặc định cũng là `preview`. Để xem trên web:

```powershell
flutter run -d chrome --dart-define=APP_MODE=preview
```

Màn hình có nhãn “Bản xem thử · Dữ liệu lưu trên thiết bị”. Hồ sơ và mục tiêu
được lưu cục bộ, khôi phục khi mở lại. Menu hồ sơ ở Trang chủ cho phép sửa thông
tin hoặc đăng xuất để xóa dữ liệu xem thử. Không nhập thông tin nhạy cảm vào bản
xem thử trên thiết bị dùng chung. Chế độ này không gửi dữ liệu đến Firebase.

## Hoàn tất cấu hình Firebase

1. Mở project `vetalife-24f03` hoặc tạo Firebase project của bạn. Bật
   Authentication → Sign-in method → Google
   và tạo Cloud Firestore ở chế độ production.
2. Android app `vn.edu.fpt.vetalife` đã được đăng ký trong `vetalife-24f03`.
   Nếu dùng project khác, đăng ký app với cùng ID này. Namespace/applicationId
   và package MainActivity trong `android/` phải khớp với cấu hình client của app.
3. Cài Firebase CLI, đăng nhập và cài FlutterFire CLI theo
   [hướng dẫn chính thức](https://firebase.google.com/docs/flutter/setup).
   Từ thư mục gốc, chạy:

   ```powershell
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,web
   ```

   Đảm bảo lệnh ghi đè `lib/firebase_options.dart`, tạo
   `android/app/google-services.json`, và thêm Google Services Gradle plugin vào
   project Android. Không dùng App ID/OAuth client của Android app cũ cho ID mới.
   CLI phiên bản mới có thể cập
   nhật Gradle theo cấu hình project.
4. Trong thư mục `android`, lấy SHA-1/SHA-256 của debug signing key:

   ```powershell
   .\gradlew.bat signingReport
   ```

   Thêm fingerprint của variant đang chạy vào Android app trong Firebase
   Console. Chạy lại `flutterfire configure` sau khi bật Google Sign-In để lấy
   OAuth client đúng. Native Google Sign-In cần web OAuth client được tạo trong
   `google-services.json`; không dùng Android OAuth ID làm server client ID.
5. Với bản web, thêm tên miền vào Authentication → Settings → Authorized
   domains, gồm `localhost` nếu cần thử trên máy. Web dùng Firebase popup;
   Android dùng Google account picker qua `google_sign_in` 7.2.0.
6. Rules đã được triển khai và đọc lại đối chiếu trên `vetalife-24f03` như trạng
   thái đầu tài liệu. Khi dựng project khác hoặc cập nhật cấu hình, xem lại
   `firebase/firestore.rules` và indexes, sau đó triển khai vào đúng project:

   ```powershell
   firebase deploy --only "firestore:rules,firestore:indexes" --project YOUR_PROJECT_ID
   ```

7. Chạy chế độ cloud:

   ```powershell
   flutter run --dart-define=APP_MODE=cloud
   ```

   Build APK cloud khi đã hoàn tất cấu hình:

   ```powershell
   flutter build apk --release --dart-define=APP_MODE=cloud
   ```

   Cấu hình release signing trước khi phát hành. Project hiện dùng debug signing
   của template Flutter, chưa phải bản phát hành để nộp lên cửa hàng.

   Với AI trên Android debug, đăng ký App Check debug token của thiết bị; bản
   release/profile dùng Play Integrity. Với web, truyền site key reCAPTCHA công
   khai bằng `FIREBASE_APP_CHECK_WEB_SITE_KEY`; localhost debug còn cần
   `APP_CHECK_WEB_DEBUG=true` và token debug đã đăng ký. Thiếu App Check cho AI
   sẽ hiển thị thông báo cấu hình; không dùng Gemini API key thay site key.

   Có thể đăng ký token qua công cụ PowerShell từ thư mục gốc:

   ```powershell
   & .\tool\register_app_check_debug.ps1 -Platform android -DisplayName 'VetaLife my-android'
   # Dùng -Platform web cho UUID do trình duyệt tạo.
   ```

   Công cụ hỏi UUID debug token bằng ô nhập ẩn; lấy token từ log của app đang
   chạy, không dán vào chat hoặc câu lệnh. Công cụ chọn đúng App ID trong
   `vetalife-24f03`. Khởi động lại app sau khi đăng ký thành công. Xem
   [các bước lấy, đăng ký và thu hồi token](flow2-setup.md#đăng-ký-debug-token-bằng-powershell)
   để dùng trên Android/web hoặc nhập từ tệp cục bộ đã được Git bỏ qua.

AI Logic đã qua phép thử kết nối; điều đó chưa xác minh toàn bộ cloud flow.
Rules của project hiện tại đã deploy và khớp bản cục bộ; lần kiểm tra này không
triển khai indexes. Trước khi dùng dữ liệu thật, cần xác nhận Google Sign-In
hoạt động trên nền tảng đang chạy, App Check của thiết bị hợp lệ và hồ sơ/nhật ký
lưu, đọc lại, cô lập đúng tài khoản. Với bản release, cấu hình signing,
fingerprint và Play Integrity riêng cho bản phát hành.

## Dữ liệu và quyền truy cập

Document: `users/{Firebase Auth UID}`. Một lần lưu ghi đủ hồ sơ và mục tiêu trong
một document; không thể hoàn thành onboarding chỉ với một phần thông tin.

| Field | Dạng lưu |
| --- | --- |
| `displayName` | Chuỗi đã trim |
| `birthDate` | Ngày lịch `YYYY-MM-DD`, không chuyển UTC |
| `weightKg`, `heightCm` | Số hữu hạn, lớn hơn 0 |
| `goal` | `addVegetables`, `recordMeals`, `readDaily` |
| `updatedAt` | Server timestamp |

Tuổi tính từ ngày sinh tại ngày hiện tại, không lưu thêm trường tuổi. UID thuộc
đường dẫn document, không lấy từ dữ liệu form. Rules chỉ cho chủ tài khoản đọc
đúng document hồ sơ và tạo/cập nhật các field cho phép; list/delete hồ sơ bị
từ chối. Nhật ký Flow 2 có quyền owner riêng tại `users/{uid}/meals/{id}`.
Rules kiểm tra cấu trúc ngày; kiểm tra ngày lịch hợp lệ/ngày tương lai nằm trong
model/ViewModel. Bộ rules tests cục bộ kiểm tra quyền nhật ký và cô lập tài khoản;
kết quả nằm trong [test report](test-report.md). Rules production đã đọc lại khớp
bản cục bộ; thao tác lưu/đọc bằng tài khoản thật vẫn cần xác minh.

Đọc hồ sơ yêu cầu server để lỗi mạng không bị hiểu nhầm thành “chưa có hồ sơ”.
Lưu lỗi giữ form và mục tiêu để thử lại; write dùng cùng document ID nên retry
không tạo hồ sơ trùng. Timeout 15 giây không hủy write đã gửi; write trễ có thể
vẫn hoàn tất. Disk persistence của Firestore bị tắt; đăng xuất loại bỏ ViewModel
và dữ liệu cá nhân trong bộ nhớ, giữ nguyên document cloud để đăng nhập lại.

Dữ liệu preview không được chuyển tự động sang cloud. Các dịch vụ Analytics,
Crashlytics, FCM, Storage và Remote Config là phạm vi Lab 3 tiếp theo, chưa được
tích hợp trong flow 1. Chưa có Analytics parameters chứa hồ sơ cá nhân.

## Xác minh sau khi kết nối

- Hủy Google picker/popup: hiện thông báo, vẫn có thể đăng nhập lại.
- Tài khoản mới: welcome → hồ sơ → mục tiêu → home; kiểm tra document trong
  Firestore và đúng tên/mục tiêu trên home.
- Mở lại ứng dụng/đăng nhập lại: khôi phục đúng hồ sơ; tài khoản khác không thấy
  dữ liệu tài khoản trước.
- Ngắt mạng khi tải/lưu: hiện lỗi và thử lại; form không mất dữ liệu.
- Đăng xuất: về màn hình đăng nhập; document cloud vẫn còn.
- Xác minh owner rules bằng Firebase Emulator Suite trước khi lưu dữ liệu thật.

Đây là checklist cần chạy sau cấu hình, không phải các kết quả đã đạt.
