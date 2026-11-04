# Flow 3 — Tiến trình và bài học theo sách

Flow 3 triển khai các màn Figma `6:213`, `6:257`, `166:470`, `166:628` trên
cùng phiên đăng nhập của Flow 1/2. Dùng các tab **Tiến trình**, **Học** hoặc
**Xem tiến trình tuần** từ Trang chủ; các tab trong Nhật ký cũng hoạt động.

## Chạy preview

```powershell
flutter pub get
flutter run -d chrome --dart-define=APP_MODE=preview
```

Hoàn tất hồ sơ → **Học** → chọn **Phần 1/Phần 2** → chọn bài → đọc nội dung,
trang nguồn và câu hỏi suy ngẫm → **Đánh dấu đã đọc**. Quay về mục lục giữ
phần đang chọn; bài đã đọc không tạo thêm lượt hoàn thành khi mở lại. Tải lại
trình duyệt giữ tiến độ. Đăng xuất preview xóa hồ sơ, nhật ký và tiến độ học,
khóa tương tác cho tới khi toàn bộ quá trình xóa hoàn tất.

Danh mục gồm 15 chương phần một, 12 nhóm Daily Dozen và 3 mục bổ trợ phần hai.
Bộ đếm **27 bài chính** không tăng khi đánh dấu Giới thiệu, tổng quan Daily
Dozen hoặc Kết luận. Mỗi bài có diễn giải nhập môn riêng và trang đã đối chiếu;
đây không phải toàn văn hay bản tóm tắt toàn bộ từng chương. Xem
[nguồn nội dung](flow3-book-grounding.md).

Màn Tiến trình lấy số bữa đã lưu từ thứ Hai tới Chủ nhật theo lịch địa phương,
bỏ ngày tương lai và không đếm trùng ID. Số ngày có ghi bữa ăn, cột biểu đồ,
văn bản thay thế và phần Điểm sáng cùng dùng một tập dữ liệu. Chúng không
chứng minh đạt mục tiêu rau xanh hoặc một mục tiêu sức khỏe. Ban đầu dữ liệu
rỗng và tiến độ bằng không, không có bữa ăn hay bài đọc mẫu.

## Cloud trên Spark

```powershell
flutter run --dart-define=APP_MODE=cloud
```

Hoàn tất Auth theo [Firebase setup](firebase-setup.md). Nội dung bài học nằm
trong assets, không gọi Gemini hay cần Secret Manager. Tiến độ riêng nằm tại
`users/{uid}/lessonProgress/{lessonId}`; đăng xuất cloud giữ dữ liệu máy chủ.
Đổi tài khoản tạo ViewModel/repository theo UID mới, không dùng tiến độ của
tài khoản trước. Firestore disk persistence vẫn tắt theo cấu hình ứng dụng.

Ngày 2026-11-04, **12 kiểm thử rules** đã đạt trong emulator và rules đã được
triển khai lên `vetalife-24f03`, đọc lại khớp mã nguồn. Chỉ owner được đọc/ghi;
ghi cần hồ sơ tồn tại, ID bài hợp lệ và timestamp máy chủ. Không sửa indexes,
dữ liệu người dùng hoặc billing. Khi áp dụng cho project khác:

```powershell
firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
```

Lỗi tải tiến độ vẫn cho đọc nội dung đã tải, nhưng yêu cầu tải lại tiến độ trước
khi đánh dấu. Lỗi lưu giữ đúng bài và trạng thái chưa hoàn thành để thử lại;
nút lưu và điều hướng được khóa khi ghi. Không tự đánh dấu khi vừa mở bài.

## Kiểm tra

```powershell
flutter analyze --no-pub
flutter test --no-pub
firebase emulators:exec --only firestore --project demo-vetalife-rules "npm --prefix functions run test:rules"
```

Kiểm thử bao gồm assets thật đủ 30 bài, 27/3 loại bài, lưu/tải lại, lỗi/thử lại,
hủy phiên, xóa preview khi lưu đang chờ, điều hướng giữa ba flow, tuần/tháng,
ngày tương lai, ID trùng, chữ 1.5× và màn hình 360/412 dp. Xem
[kết quả thực tế](test-report.md) và [review](code-review.md).

Kiểm thử emulator và web preview không thay thế việc đăng nhập, lưu/tải lại,
đổi tài khoản trên Firebase thật hoặc chạy ARTEMIS trên thiết bị Android.
