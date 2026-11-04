# Flow 2 — Firebase AI Logic trên Spark

Flow 2 giữ các màn hình Figma `6:76`, `6:101`, `6:118`, `6:138`, `6:155`
và `6:186`, cùng phần mở rộng ảnh/OCR và xác nhận thành phần. Đường cloud
mặc định dùng Firebase AI Logic qua SDK Flutter `firebase_ai`, với Gemini
Developer API. Không cần triển khai Cloud Functions hoặc tạo Gemini secret.

## Chạy bản xem thử cục bộ

```powershell
flutter pub get
flutter run -d chrome --dart-define=APP_MODE=preview
```

Hoàn tất hồ sơ → **Ghi bữa ăn** → nhập tên món → **Tiếp tục xác nhận** → thêm
thành phần đã biết → xác nhận → **Đối chiếu với sách** → **Lưu vào nhật ký**.
Nhật ký lọc theo ngày, mở/sửa được kết quả và cập nhật số bữa trên Trang chủ.
Lưu lại bữa đã sửa cập nhật cùng ID.

Bản xem thử đối chiếu tên thành phần với **15 đoạn sách đã đọc và dẫn trang**.
Nó không gọi Gemini hoặc giả lập nhận diện. Ảnh chọn trong bản xem thử chỉ được
xem trước; nhận diện tự động cần cloud. Dữ liệu cục bộ được xóa khi đăng xuất
khỏi bản xem thử.

## Cấu hình Firebase AI Logic miễn phí theo hạn mức

### Trạng thái project hiện tại — 2026-11-04

- Firebase CLI `init ailogic` đã hoàn tất cho Android app
  `1:455537300059:android:6bf4a62f2e23bb6b91257e` và web app
  `1:455537300059:web:74e2fcd06bfd330291257e` trong `vetalife-24f03`.
- `ailogic:providers:list` đã trả về `gemini-developer-api`.
- `appcheck:services:get ailogic` đã trả về **ENFORCED**.
- API `firebaseappcheck.googleapis.com` đã bật. Trao đổi token App Check debug
  thử nghiệm trả HTTP **200**; một yêu cầu kiểm tra kết nối tới
  `gemini-3.6-flash` qua endpoint Firebase AI Logic trả HTTP **200**, nội dung
  `READY`. Không gửi hồ sơ cá nhân hoặc ảnh bữa ăn trong phép thử này. Token
  tạm đã được thu hồi sau kiểm tra.
- Kiểm thử RPC/adapter thật với dữ liệu tổng hợp: phân tích trả HTTP **200**
  sau khoảng **21 giây**, bốn trích dẫn ở trang in **410, 374, 494, 499** và bốn
  liên hệ sức khỏe qua bộ kiểm tra của adapter. OCR riêng mất khoảng **10 giây**,
  đọc được `SAMPLE 31415` trên thẻ chữ PNG và giữ `ingredients=[]` kèm cảnh báo.
  Cả hai debug token tạm đã thu hồi, không còn tệp JWT. Một yêu cầu phân tích
  trước đó từng trả HTTP **500**; yêu cầu giữ nguyên sau đó đã đạt khi chạy
  kiểm tra có kiểm soát, chưa xác định nguyên nhân lỗi và không thêm tự retry.
- Không thay đổi billing và không nâng project lên Blaze.
- Rules emulator đã chạy lại đạt **9/9**. Triển khai riêng `firestore:rules`
  thành công; đọc lại rules production khớp tệp cục bộ, có rules nhật ký và
  giới hạn chủ tài khoản. Không thay đổi indexes hoặc dữ liệu. Việc này chưa
  xác minh toàn bộ luồng đăng nhập/lưu/đọc lại bằng tài khoản thật.
- Web chưa có reCAPTCHA provider/site key. Thiết bị Android hoặc trình duyệt
  debug cần token của chính môi trường chạy được đăng ký trong App Check.
  Các phép thử RPC/adapter không xác minh attestation của SDK trên thiết bị,
  thao tác UI, camera native, nhận diện bữa ăn hoặc độ chính xác đánh giá dinh
  dưỡng trên dữ liệu thật.

Với project hiện tại, tiếp tục phần App Check bên dưới. Các bước khởi tạo sau
dùng khi cần dựng lại cấu hình hoặc chuyển sang project khác:

1. Mở [Firebase console](https://console.firebase.google.com/project/vetalife-24f03/overview),
   chọn project `vetalife-24f03` và giữ gói **Spark**.
2. Vào **AI Services → AI Logic → Get started**. Chọn **Gemini Developer API**,
   rồi hoàn tất quy trình bật API/dịch vụ. Provider Agent Platform/Vertex AI
   yêu cầu billing, không phải đường Spark được chọn cho dự án này.
3. Giữ App Check được enforce cho AI Logic và cấu hình ứng dụng như phần dưới.
   Hướng dẫn chính thức hiện tự bật enforcement trong quy trình AI Logic.
4. Hoàn tất Google Sign-In và Firestore theo [Firebase setup](firebase-setup.md).
   App Android là `vn.edu.fpt.vetalife`, minimum SDK **24**.
5. Rules hồ sơ/nhật ký của project hiện tại đã triển khai như trạng thái trên.
   Khi dựng lại hoặc cập nhật cấu hình, kiểm tra rules/indexes rồi triển khai:

   ```powershell
   firebase deploy --only "firestore:rules,firestore:indexes" --project vetalife-24f03
   ```

Khởi tạo AI Logic có thể dùng CLI hoặc quy trình console; lệnh
`firebase functions:secrets:set` không thuộc cấu hình Spark này. AI Logic dùng
cơ chế ủy quyền do Firebase quản lý; không đặt Gemini API key trong code,
`--dart-define`, hoặc tệp cấu hình Firebase client.

Model mặc định là `gemini-3.6-flash`. Có thể chọn model tương thích bằng
`--dart-define=GEMINI_MODEL=MODEL_ID`; model đó phải có quyền truy cập trên
project và hỗ trợ ảnh/structured output. Free tier có hạn mức và chỉ hỗ trợ
một số model; không có lời hứa sử dụng miễn phí không giới hạn. Model mặc định
đã qua phép thử kết nối nói trên; model override khác cần kiểm tra quyền truy cập
và hạn mức trên project.

Nguồn chính thức:
[hướng dẫn Flutter](https://firebase.google.com/docs/ai-logic/get-started?platform=flutter),
[giá và Spark](https://firebase.google.com/docs/ai-logic/pricing?api=dev),
[ủy quyền AI Logic](https://firebase.google.com/docs/ai-logic/faq-and-troubleshooting).

## App Check cho Android và web

Trong **Security → App Check → Apps**, chọn đúng Android/web app đã đăng ký.
Trong tab **APIs**, giữ AI Logic ở trạng thái enforced; CLI đã xác nhận
**ENFORCED** cho dịch vụ này trong project hiện tại.

- **Android debug:** mã dùng debug provider cho bản debug. Chạy app, lấy token
  debug từ log và đăng ký bằng công cụ bên dưới hoặc menu **Manage debug tokens**
  của chính app Android. Token này là thông tin bí mật phát triển, không đưa vào Git.
- **Android release/profile:** cấu hình **Play Integrity** cho app cùng signing
  fingerprint của bản phát hành. Không dùng debug provider/token để phát hành.
- **Web:** đăng ký provider reCAPTCHA v3 cho web app và lấy **site key công khai**.
  Truyền site key bằng `FIREBASE_APP_CHECK_WEB_SITE_KEY`. Đây không phải Gemini
  key hoặc reCAPTCHA secret. Chỉ các miền phát hành phù hợp thuộc cấu hình
  reCAPTCHA production. Khi chạy localhost, thêm
  `--dart-define=APP_CHECK_WEB_DEBUG=true` trong bản debug. Mã đặt debug flag
  trước khi kích hoạt App Check; đăng ký token được in trong console bằng
  **Manage debug tokens** của web app. Không thêm localhost vào miền production
  để bỏ qua kiểm tra. Bản release/profile không cho dùng debug flag này.

Thiếu cấu hình web App Check sẽ chặn tính năng AI bằng thông báo cấu hình;
đăng nhập, hồ sơ và nhật ký vẫn có thể sử dụng theo cấu hình dịch vụ của chúng.

```powershell
# Android debug: sau khi đăng ký App Check debug token
flutter run --dart-define=APP_MODE=cloud

# Web localhost: đăng ký debug token khi chạy lần đầu
flutter run -d chrome --dart-define=APP_MODE=cloud --dart-define=APP_CHECK_WEB_DEBUG=true --dart-define=FIREBASE_APP_CHECK_WEB_SITE_KEY=YOUR_PUBLIC_RECAPTCHA_V3_SITE_KEY
```

### Đăng ký debug token bằng PowerShell

1. Chạy app debug bằng lệnh Android hoặc web ở trên. Với web, hoàn tất provider
   reCAPTCHA và thay site key trước khi chạy. Mở tính năng AI để SDK tạo token
   nếu log chưa xuất hiện.
2. Lấy **App Check debug token dạng UUID** từ log Flutter/Android hoặc console
   trình duyệt. Không dùng Gemini API key hay App Check JWT và không gửi token
   vào chat.
3. Mở PowerShell thứ hai tại thư mục dự án, đăng nhập Firebase CLI nếu cần,
   rồi chọn đúng nền tảng:

   ```powershell
   firebase login
   & .\tool\register_app_check_debug.ps1 -Platform android -DisplayName 'VetaLife my-android'
   # Hoặc, cho token do trình duyệt tạo:
   & .\tool\register_app_check_debug.ps1 -Platform web -DisplayName 'VetaLife my-browser'
   ```

   Công cụ hỏi token bằng ô nhập ẩn. Dán UUID tại lời nhắc đó rồi nhấn Enter;
   không đặt token trực tiếp trong câu lệnh. Công cụ ánh xạ đúng Android/web
   App ID trong `vetalife-24f03` và không in token hoặc đầu ra CLI chứa token.
   Dùng tên riêng cho mỗi thiết bị/trình duyệt; nếu tên đã tồn tại, chọn tên mới
   hoặc quản lý mục cũ trong Firebase Console.
4. Khi báo đăng ký thành công, dừng và chạy lại app, rồi thử nhận diện/phân tích.
   Nếu xóa dữ liệu ứng dụng hoặc dùng trình duyệt/profile khác, SDK có thể tạo
   token mới và cần đăng ký lại.

Nếu đã lưu UUID vào tệp cục bộ, có thể dùng
`& .\tool\register_app_check_debug.ps1 -Platform android -TokenFile tmp/app-check-debug-token.txt -DisplayName 'VetaLife my-android-2'`.
Tệp chỉ chứa UUID, không chứa cả dòng log; `tmp/` đã được Git bỏ qua. Không commit
token. Thu hồi token không còn dùng tại **App Check → Apps → Manage debug tokens**.
Debug token chỉ dùng cho phát triển; bản phát hành dùng provider production nêu trên.

Xem [App Check Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers)
và [debug provider](https://firebase.google.com/docs/app-check/flutter/debug-provider)
để cấu hình đúng môi trường.

## Nhận diện và phân tích

Chụp/chọn ảnh → đồng ý gửi dữ liệu → **Nhận diện món từ ảnh** → sửa/xóa/thêm
thành phần → xác nhận → **Phân tích bữa ăn**. OCR là chữ đọc được; danh sách
món là nhận diện hình ảnh có thể sai. Chữ trên nhãn không tự trở thành thành
phần đã xác nhận.

Adapter dùng hồ sơ đã tải của phiên đăng nhập hiện tại, chỉ gửi tuổi suy ra,
cân nặng, chiều cao và mục tiêu vào prompt. Tên, ngày sinh đầy đủ và UID không
được đưa vào prompt. Việc này được xử lý trong client, không phải một máy chủ
riêng đọc lại hồ sơ. Ảnh nhận diện không kèm hồ sơ.

Kết quả gồm điểm nổi bật, gợi ý cải thiện, liên hệ hồ sơ/chủ đề sách và số trang.
Model trả ID nguồn; app đối chiếu với các đoạn đã chọn rồi gắn tiêu đề/trang
từ corpus. ID giả hoặc liên hệ chủ đề không được nguồn hỗ trợ bị từ chối.
Corpus mới bao phủ một phần sách, không phải chỉ mục tìm kiếm toàn cuốn.

## Dữ liệu, quyền và hạn mức

- JPEG/PNG/WebP tối đa **4 MiB**, ảnh không lưu trong nhật ký.
- Phân tích chỉ dùng danh sách đã xác nhận. Sửa nội dung yêu cầu xác nhận lại;
  lỗi giữ bản nháp và phản hồi về muộn sau khi hủy không ghi đè màn hiện tại.
- Nhật ký cloud tại `users/{uid}/meals/{id}` vẫn dùng owner rules. Đăng xuất
  cloud giữ lịch sử của chủ tài khoản; đăng xuất preview xóa dữ liệu cục bộ.
- Prompt/corpus/validator nằm trong ứng dụng nên có thể bị xem hoặc sửa ở
  client. Chúng không thay thế một ranh giới kiểm tra phía máy chủ.
- Đường Spark dựa vào App Check enforcement và quota AI Logic/Gemini. Giới hạn
  cũ **40/ngày, 6/phút** của backend Functions không áp dụng cho SDK trực tiếp.
  Có thể chỉnh quota AI Logic trong console theo
  [tài liệu quota](https://firebase.google.com/docs/ai-logic/quotas).
- Ảnh không chứng minh lượng dầu/muối/đường, dị ứng hay khẩu phần. Liên hệ bệnh
  trong sách nói về thói quen dài hạn; không kết luận một bữa ăn phòng/chữa bệnh.

Nguồn sách: [grounding](meal-book-grounding.md).
Hợp đồng dữ liệu: [contract](flow2-contract.md).

## Kiểm thử và emulator

```powershell
flutter analyze --no-pub
flutter test --no-pub
firebase emulators:exec --only firestore --project demo-vetalife-rules "npm --prefix functions run test:rules"
```

Rules tests vẫn dùng công cụ kiểm thử trong thư mục legacy `functions/`; cần
`npm --prefix functions ci` khi chưa cài dependencies kiểm thử. Chúng chỉ dùng
Firestore emulator và project demo. Kiểm thử AI mặc định dùng generator giả được
tiêm vào, không cần secret hay gọi model thật; hai kiểm thử live được bỏ qua.

Muốn kiểm tra adapter với AI Logic thật trên Windows, cần Node **22+**, Flutter,
Firebase CLI cài bằng npm và phiên `firebase login` có quyền trên project:

```powershell
node tool/run_meal_ai_live_check.cjs
# Thêm một phép nhận diện/OCR bằng ảnh PNG tổng hợp chỉ chứa chữ:
node tool/run_meal_ai_live_check.cjs --include-ocr
# Chỉ kiểm tra OCR, không gọi lại phân tích:
node tool/run_meal_ai_live_check.cjs --ocr-only
```

Mỗi lần chạy gọi tối đa một phân tích; tùy chọn `--include-ocr` thêm một nhận
diện/OCR, còn `--ocr-only` chỉ gọi nhận diện/OCR. Công cụ dùng dữ liệu tổng hợp,
không gửi hồ sơ cá nhân, ảnh người dùng
hoặc Gemini key. Nó đăng ký App Check debug token tạm, đổi lấy JWT cho kiểm thử,
rồi thu hồi token và xóa tệp JWT trong `tmp/` khi kết thúc. Đây là yêu cầu dịch
vụ thật và dùng quota thật, không tự thử lại.

Kết quả **2026-11-04**: Flutter mặc định **115 đạt, 2 live bỏ qua**, analyzer
không có vấn đề. Lần chạy live phân tích đạt **3 kiểm thử** (gồm 2 kiểm tra
offline), lần OCR riêng đạt **1 kiểm thử**. Đây là kiểm tra RPC và adapter với
App Check token tạm, chưa thay thế kiểm tra SDK attestation, UI/camera trên
thiết bị hoặc độ chính xác nhận diện/phân tích bữa ăn thật. Xem
[test report](test-report.md) cho bằng chứng và giới hạn.

Auth và Firestore có thể chạy emulator:

```powershell
firebase emulators:start --only auth,firestore --project vetalife-24f03
flutter run -d chrome --dart-define=APP_MODE=cloud --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1 --dart-define=APP_CHECK_WEB_DEBUG=true --dart-define=FIREBASE_APP_CHECK_WEB_SITE_KEY=YOUR_PUBLIC_RECAPTCHA_V3_SITE_KEY
```

Android emulator dùng host `10.0.2.2`. **AI Logic không được emulated trong
dự án này**: nhận diện/phân tích vẫn gọi dịch vụ thật, cần console/App Check
hợp lệ và sử dụng quota thật. Không coi Auth/Firestore emulator là một cách
giả lập Gemini.

## Backend Functions cũ

`functions/` và `firebase.functions.legacy.json` giữ đường máy chủ trước đây
cho lựa chọn Blaze riêng biệt; app mặc định không gọi nó. Không cần tạo secret
hay triển khai codebase đó để dùng AI Logic trên Spark. Xem
[legacy README](../functions/README.md) khi có nhu cầu triển khai máy chủ sau.
