# Kết nối Firebase cho flow 1

Ứng dụng đã có code Google Sign-In và lưu hồ sơ trên Cloud Firestore. Theo yêu
cầu của bạn, chưa tạo project, đăng ký tài khoản, triển khai rules hoặc kết nối
dịch vụ thật. File `lib/firebase_options.dart` hiện là stub báo thiếu cấu hình;
FlutterFire sẽ thay file này bằng thông tin project của bạn.

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

## Sau khi tự tạo project

1. Tạo Firebase project của bạn. Bật Authentication → Sign-in method → Google
   và tạo Cloud Firestore ở chế độ production.
2. Android application ID đang dùng là `vn.edu.fpt.nep_lanh`. Giữ ID này khi
   đăng ký Android app. Nếu muốn đổi, sửa namespace/applicationId và package
   MainActivity trong `android/` trước khi cấu hình Firebase.
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
   project Android. Không tự điền ID giả vào stub. CLI phiên bản mới có thể cập
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
6. Xem lại `firebase/firestore.rules`, sau đó tự triển khai:

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
đúng document và tạo/cập nhật các field cho phép; list/delete và các collection
khác bị từ chối. Rules kiểm tra cấu trúc ngày; kiểm tra ngày lịch hợp lệ/ngày
tương lai nằm trong model/ViewModel. Cần chạy emulator kiểm tra rules trước khi
triển khai thực tế; chưa có kết quả kiểm thử Firebase rules trong lần triển khai này.

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
