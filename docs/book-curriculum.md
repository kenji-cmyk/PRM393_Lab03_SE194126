# Chương trình bài học theo sách

Trạng thái: cấu trúc nội dung phục vụ thiết kế luồng 3; chưa biên soạn nội dung
bài học, chưa triển khai ứng dụng hoặc ghi nhận tiến trình người dùng.

## Nguồn và cách đối chiếu

- Sách: *Ăn gì không chết - Sức mạnh chữa lành của thực phẩm*, Michael Greger
  cùng Gene Stone, bản tiếng Việt do người dùng cung cấp trong
  `docs/requirements/An-Gi-*.pdf`.
- PDF scan có 774 trang. Mục lục được đọc trực tiếp từ ảnh của **trang PDF 7-8**;
  không dùng kết quả trích văn bản rỗng để suy đoán tiêu đề.
- Trong bản scan này, số trang PDF (đếm từ 1) bằng số trang in trong sách cộng 2.
  Đã đối chiếu trực quan các mốc: trang in 37 / PDF 39 (chương 1),
  345 / 347 (giới thiệu phần 2), 367 / 369 (lượng cần ăn),
  373 / 375 (đậu), và 539 / 541 (phụ lục).
- File sách gốc và ảnh scan chỉ là tài liệu cục bộ, được Git bỏ qua.
  Danh mục JSON bên dưới chỉ chứa tên mục và tham chiếu trang, không chứa sách
  hay nội dung y khoa được sao chép.

Danh mục máy đọc được: [lesson-catalog.json](../assets/content/lesson-catalog.json).

## Cấu trúc cho luồng 3

Giữ nguyên thứ tự mục lục:

1. **Phần 1:** 15 chương, mỗi chương là một bài học chính.
2. **Phần 2:** mục “Lượng cần ăn hằng ngày của bác sĩ Greger” chứa 12 nhóm
   theo đúng thứ tự sách, mỗi nhóm là một bài học chính.
3. “Giới thiệu” phần 2, phần tổng quan lượng cần ăn, và “Kết luận” được giữ
   như ba mục đọc bổ trợ, không tính vào tổng 27 bài học chính.

Trình bày màn danh mục theo hai phần; chọn phần, chọn chương/nhóm, rồi mở
chi tiết bài học trước khi đánh dấu đã đọc. Tên ngắn trên thẻ chỉ phục vụ
điều hướng; chi tiết bài phải hiển thị tên nguồn đầy đủ và trang tham chiếu.
Không tự đổi mục lục thành các nhóm chủ đề tùy ý hay trộn mục tiêu học với
kết quả chẩn đoán.

## Phần 1 - 15 chương

| ID ổn định | Tiêu đề trong mục lục | Nhãn điều hướng ngắn | Trang in | Trang PDF |
| --- | --- | --- | --- | --- |
| p1-ch01 | Để không chết vì bệnh tim | Bệnh tim | 37 | 39 |
| p1-ch02 | Để không chết vì các bệnh liên quan đến phổi | Các bệnh liên quan đến phổi | 54 | 56 |
| p1-ch03 | Để không chết vì các bệnh về não | Các bệnh về não | 70 | 72 |
| p1-ch04 | Để không chết vì ung thư đường tiêu hóa | Ung thư đường tiêu hóa | 96 | 98 |
| p1-ch05 | Để không chết vì bệnh nhiễm trùng | Bệnh nhiễm trùng | 117 | 119 |
| p1-ch06 | Để không chết vì bệnh tiểu đường | Bệnh tiểu đường | 146 | 148 |
| p1-ch07 | Để không chết vì bệnh cao huyết áp | Bệnh cao huyết áp | 175 | 177 |
| p1-ch08 | Để không chết vì bệnh gan | Bệnh gan | 200 | 202 |
| p1-ch09 | Để không chết vì các bệnh ung thư máu | Các bệnh ung thư máu | 217 | 219 |
| p1-ch10 | Để không chết vì bệnh thận | Bệnh thận | 230 | 232 |
| p1-ch11 | Để không chết vì bệnh ung thư vú | Bệnh ung thư vú | 248 | 250 |
| p1-ch12 | Để không chết vì tự tử do trầm cảm | Tự tử do trầm cảm | 273 | 275 |
| p1-ch13 | Để không chết vì ung thư tuyến tiền liệt | Ung thư tuyến tiền liệt | 291 | 293 |
| p1-ch14 | Để không chết vì bệnh Parkinson | Bệnh Parkinson | 309 | 311 |
| p1-ch15 | Để không chết vì các nguyên nhân do khám và điều trị (hoặc, Để không chết vì bác sĩ) | Các nguyên nhân do khám và điều trị | 326 | 328 |

## Phần 2 - mục tổng quan

| ID | Tiêu đề trong mục lục | Trang in | Trang PDF |
| --- | --- | --- | --- |
| p2-introduction | Giới thiệu | 345 | 347 |
| p2-daily-dozen | Lượng cần ăn hằng ngày của bác sĩ Greger | 367 | 369 |
| p2-conclusion | Kết luận | 531 | 533 |

### 12 nhóm thuộc “Lượng cần ăn hằng ngày của bác sĩ Greger”

| ID ổn định | Tiêu đề trong mục lục | Trang in | Trang PDF |
| --- | --- | --- | --- |
| p2-dd01 | Đậu | 373 | 375 |
| p2-dd02 | Quả mọng | 389 | 391 |
| p2-dd03 | Các loại trái cây khác | 399 | 401 |
| p2-dd04 | Rau củ họ cải | 410 | 412 |
| p2-dd05 | Rau xanh | 418 | 420 |
| p2-dd06 | Các loại rau củ khác | 431 | 433 |
| p2-dd07 | Hạt lanh | 453 | 455 |
| p2-dd08 | Quả hạch và các loại hạt | 458 | 460 |
| p2-dd09 | Các loại thảo mộc và gia vị | 468 | 470 |
| p2-dd10 | Ngũ cốc nguyên cám | 493 | 495 |
| p2-dd11 | Thức uống | 505 | 507 |
| p2-dd12 | Thể dục | 522 | 524 |

## Các mục tham khảo không tính là bài học chính

Giữ tham chiếu nguồn cho Lời Nhà xuất bản (trang in 7), Lời nói đầu (9),
Giới thiệu chung (15), Lời cảm ơn (538), Phụ lục / Viên uống bổ sung (539),
Chú thích (546), và Bảng chỉ mục (749). Chúng không trở thành bài học giả
hoặc làm tăng bộ đếm hoàn thành 27 bài chính.

## Hợp đồng nội dung cho thiết kế và triển khai sau

- `id` ổn định dùng để lưu tiến trình riêng theo người dùng; đổi tên nhãn không
  được làm mất trạng thái đã đọc.
- `sourceTitle` là tiêu đề nguồn; `displayTitle` là nhãn điều hướng.
- `printedPage` và `pdfPage` là trang bắt đầu theo bản sách cục bộ này.
- `kind` phân biệt chương, nhóm Daily Dozen, tổng quan, kết luận, và mục tham khảo.
- Màn chi tiết có vị trí cho tóm tắt ngắn được biên soạn lại, nguồn, nút đánh dấu
  đã đọc, và quay về danh mục. Danh mục hiện tại **không cung cấp** đoạn tóm tắt,
  thời lượng đọc, khuyến nghị điều trị, hoặc trạng thái hoàn thành mẫu.
- Chỉ tăng số bài đã hoàn thành khi người dùng thực sự đánh dấu một bài chính;
  tổng quan/kết luận không làm tăng tử số của bộ đếm 27 bài.
- Việc triển khai luồng 3 vẫn cần tuân theo Lab 2 về điều hướng và thiết kế,
  đồng thời ghi thay đổi vào tài liệu truy vết do điều phối viên cập nhật.

## Kiểm tra đã thực hiện

Đã đọc trực quan hai trang mục lục và năm trang đối chiếu. Danh mục gồm đúng
15 chương phần 1, 12 nhóm phần 2, ba mục bổ trợ phần 2; ID không trùng và
mỗi tham chiếu PDF bằng trang in cộng 2. Không chạy kiểm thử ứng dụng vì
chưa có mã ứng dụng trong phạm vi này.
