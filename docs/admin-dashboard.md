# VetaLife Admin

Dashboard quản lý người dùng chạy bằng Flutter Web, tách khỏi ứng dụng điện thoại.
Firebase đang dùng là **vetalife-24f03**. Lối vào là `lib/admin_main.dart`;
`lib/main.dart` tiếp tục chạy ứng dụng người dùng.

## Chức năng

- Đăng nhập Google và kiểm tra custom claim Boolean `admin: true`.
- Danh sách tài khoản có phân trang; tìm chính xác email hoặc UID.
- Lọc trạng thái, vai trò, xác minh email; tìm nhanh tên/email/UID và sắp xếp trong trang hiện tại.
- Xem thông tin tài khoản, hồ sơ, số bữa ăn và số bài học đã đánh dấu đọc.
- Xem nhật ký bữa ăn của từng tài khoản: tên món, loại bữa, thời gian ăn, số thành phần và ghi chú, có phân trang.
- Trang Thống kê có số tài khoản hoạt động/khóa/admin/xác minh email, tài khoản mới và đăng nhập trong 7/30 ngày. Quét tối đa 2.000 tài khoản và hiển thị rõ khi chưa bao phủ hết.
- Bảng hoạt động của các tài khoản trong trang đang tải: số bữa ăn, bài học và lỗi tải riêng từng dòng; tải theo yêu cầu.
- Sửa tên hiển thị tài khoản Authentication (1–100 ký tự); tên trong hồ sơ sức khỏe được hiển thị riêng.
- Xác nhận trước khi khóa/mở tài khoản hoặc thu hồi phiên đăng nhập.
- Chặn thao tác với tài khoản của chính admin và các admin khác.
- Ghi nhật ký thao tác server trong `adminAuditLogs`, không chứa nội dung hồ sơ.
- Trang nhật ký quản trị có phân trang, làm mới và lọc theo UID người dùng, hiển thị người thực hiện và trạng thái thao tác.

Thẻ tổng quan trong trang Người dùng là số liệu **trang hiện tại**, không phải tổng toàn bộ Firebase.
Các bộ lọc và sắp xếp danh sách cũng chỉ áp dụng cho trang đã tải; tìm chính xác
email/UID dùng API để tra tài khoản ngoài trang hiện tại.
Dashboard không xóa tài khoản hoặc sửa nội dung sức khỏe của người dùng.
Thu hồi phiên chặn việc làm mới phiên; ID token đã cấp có thể còn hiệu lực đến
khi hết hạn đối với các dịch vụ không kiểm tra revocation. Các API admin kiểm
tra quyền, trạng thái khóa và thời điểm thu hồi của người gọi trên mỗi yêu cầu.

## Chạy tại máy này với Firebase thật

Kiểm tra ngày 2026-11-12 xác nhận billing của project chưa bật. Chế độ local
không cần triển khai Functions: một server chỉ lắng nghe trên `127.0.0.1` phục vụ
giao diện và API admin, vẫn dùng Firebase Authentication và Firestore thật.

Tài khoản `khoina231@gmail.com` đã được cấp quyền admin theo lựa chọn của chủ
project. Nếu đang có phiên đăng nhập cũ, đăng xuất rồi đăng nhập lại hoặc dùng
nút kiểm tra lại quyền để lấy ID token mới.

Từ thư mục repository:

```powershell
npm.cmd --prefix functions ci
flutter.bat build web -t lib/admin_main.dart --output build/admin-web --dart-define=ADMIN_FUNCTIONS_HOST=127.0.0.1
firebase.cmd login
node functions/scripts/serve-admin.mjs --firebase-cli
```

Mở **http://localhost:5178**. Dùng `localhost` vì đây là domain đã được cho phép
trong Firebase Auth của project. Không mở bằng IP `127.0.0.1` nếu chưa thêm IP
này vào authorized domains. Giao diện gọi API loopback bằng Firebase ID token;
server xác minh token có kiểm tra revocation và kiểm tra quyền admin trực tiếp
từ Firebase Auth. Tài khoản thường bị từ chối ngay cả khi tự gọi API.

Giữ terminal server chạy. Dừng bằng Ctrl+C. Server này chỉ phục vụ máy hiện tại,
không phải URL public để truy cập từ điện thoại hoặc máy khác. Không mở cổng,
tunnel hay reverse proxy server local này ra Internet. OAuth của Firebase CLI
được dùng trong bộ nhớ của server, không ghi vào source và không gửi trình duyệt.
Chỉ chạy server từ máy của người vận hành được tin cậy. Có thể bỏ `--firebase-cli`
để dùng Application Default Credentials đã được cấu hình hợp lệ cho project.

## Cấp và thu hồi quyền admin

Quyền admin không có trong form người dùng, Firestore hay một allowlist email
trên trình duyệt. Dùng CLI từ môi trường có quyền quản trị Firebase Auth:

```powershell
# Kiểm tra UID trước; mặc định không ghi thay đổi.
node functions/scripts/manage-admin.mjs --grant --email admin@example.com --firebase-cli

# Chỉ chạy khi đã xác nhận đúng tài khoản cần cấp quyền.
node functions/scripts/manage-admin.mjs --grant --email admin@example.com --firebase-cli --apply

# Thu hồi quyền của một admin; giữ lại các custom claims khác.
node functions/scripts/manage-admin.mjs --revoke --uid TARGET_UID --firebase-cli --apply
```

Tool chặn cấp quyền cho tài khoản đã khóa và chặn thu hồi admin hoạt động cuối
cùng. Không chạy đồng thời nhiều lệnh cấp/thu hồi vì việc cập nhật custom claims
không phải transaction. `--uid` và `--email` loại trừ nhau. Không có credentials
trong bundle Flutter. Không cấp service-account key cho người sử dụng dashboard.

## Triển khai public khi đã có hạ tầng phù hợp

Chưa triển khai dashboard hay Functions lên production. Deploy Firebase Functions
cần project đủ điều kiện triển khai; không tự bật billing trong task này.

Sau khi người vận hành chuẩn bị billing/IAM và chọn hosting site riêng cho admin:

```powershell
flutter.bat build web -t lib/admin_main.dart --output build/admin-web
firebase.cmd deploy --config firebase.admin.json --project vetalife-24f03 --only functions:adminListUsers,functions:adminGetUser,functions:adminSetUserDisabled,functions:adminRevokeUserSessions,functions:adminUpdateDisplayName,functions:adminListAuditLogs,functions:adminGetUserJournal,functions:adminGetStatistics

# Tạo/chọn hosting site dành riêng cho admin và gắn target trước khi deploy.
firebase.cmd target:apply hosting admin YOUR_ADMIN_HOSTING_SITE --project vetalife-24f03
firebase.cmd deploy --config firebase.admin.json --project vetalife-24f03 --only hosting:admin
```

Bản public phải build **không có** `ADMIN_FUNCTIONS_HOST`, để gọi Functions HTTPS
đã triển khai thay vì loopback. Thêm domain site admin vào authorized domains của
Firebase Authentication trước khi thử đăng nhập. Target `admin` tránh ghi đè
hosting người dùng. Config dùng codebase `meal-ai` hiện có nhưng chỉ deploy tám
API admin trong lệnh trên; chúng không dùng Gemini/Cloudinary secrets. CLI có thể
yêu cầu các parameter không bí mật của entry Functions chung; không deploy các
Functions meal/report ngoài phạm vi cần thiết.

Lịch sử quản trị lọc theo UID dùng chỉ mục đơn mặc định và phân trang theo mã
bản ghi, tránh phụ thuộc composite index chưa triển khai. Lịch sử toàn hệ thống
vẫn sắp theo thời gian mới nhất. Nhật ký bữa ăn là mục riêng, sắp theo thời gian ăn.

## Kiểm thử và giới hạn

Bản mở rộng nhật ký/thống kê: 22 widget tests admin đạt (bao gồm bộ lọc, đổi tên,
nhật ký bữa ăn, thống kê, màn hình 360px và bảng desktop); 80 backend tests đạt.
Kiểm tra chỉ đọc Firebase thật đã đạt cho API thống kê, nhật ký bữa ăn và lịch sử
quản trị lọc theo UID của tài khoản admin. Không sửa dữ liệu trong kiểm tra này.
Kết nối browser automation hiện lỗi môi trường; chưa xác minh tương tác đăng nhập
và bố cục trực tiếp trên trình duyệt. Chưa triển khai API mới lên Firebase;
server local đã dùng các API mới trực tiếp.

```powershell
flutter.bat analyze
flutter.bat test
npm.cmd --prefix functions test

$env:GCLOUD_PROJECT = 'demo-vetalife-admin'
firebase.cmd emulators:exec --config firebase.admin-test.json --only auth,firestore,functions --project demo-vetalife-admin "node --test --test-concurrency=1 functions/test-admin/admin-emulator.test.js"
```

Emulator dùng dữ liệu giả và project demo riêng; không dùng credential production
để tạo/xóa tài khoản kiểm thử. Fixture chỉ nạp API admin, không đọc secret AI/PDF.
Đọc thêm `functions/test-admin/README.md`.

Đã chạy: Flutter Analyze không lỗi; 181 Flutter tests đạt, 2 live tests được bỏ
qua; build web đạt; 69 backend/transport/role tests đạt; 10 kiểm thử emulator đạt.
Server local đã trả HTTP 200 cho trang/bundle và HTTP 401 cho API chưa đăng nhập.
Review độc lập không còn lỗi xác nhận chưa xử lý. Kết nối browser automation
hiện lỗi transport `sandboxPolicy`, nên chưa khẳng định đã thao tác đăng nhập
Google và quản lý người dùng thật trên trình duyệt. Chưa thử khóa tài khoản thật.
