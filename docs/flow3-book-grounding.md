# Nguồn nội dung bài học Flow 3

## Nội dung đã biên soạn

[lesson-content.json](../assets/content/lesson-content.json) chứa **30 bài nhập
môn ngắn** bằng tiếng Việt: 15 chương phần một, 12 nhóm Daily Dozen, và 3 mục bổ
trợ phần hai. ID và thứ tự đối chiếu với
[lesson-catalog.json](../assets/content/lesson-catalog.json). Ba mục bổ trợ không
làm tăng số hoàn thành 27 bài chính.

Mỗi bài có tóm tắt, một mục đọc với hai đoạn ngắn, câu hỏi tự suy ngẫm và các
trang nguồn. Văn bản là diễn giải mới theo những đoạn đã đọc; không sao chép
đoạn sách, không nhúng bản scan, và không tự nhận tóm tắt toàn bộ chương. Nhiều
chương phần một bắt đầu bằng câu chuyện; bài nhập môn giữ đúng tính chất đó và
phân biệt trải nghiệm với bằng chứng nghiên cứu. Không suy luận nội dung khoa
học từ riêng tiêu đề chương.

## Bản sách và kiểm tra trực quan

Nguồn: *Ăn gì không chết - Sức mạnh chữa lành của thực phẩm*, Michael Greger và
Gene Stone, bản scan tiếng Việt do người dùng cung cấp ở
`docs/requirements/An-Gi-*.pdf`, 774 trang. Bản PDF và ảnh đối chiếu đều ở đường
dẫn được Git bỏ qua. PyMuPDF render từng trang; ảnh ghép hai trang chỉ phục vụ
đọc trực quan trong `tmp/pdfs/flow3-book/`, không phải asset trong ứng dụng.

Đã xem 30 trang bắt đầu của 30 mục và 18 trang bổ sung, tổng **48 trang khác
nhau**. Ở các mốc được dùng, số trang PDF đếm từ 1 bằng số trang in cộng 2.
`Lesson.printedPage/pdfPage` giữ trang bắt đầu trong mục lục;
`body.sourcePages` ghi riêng các trang thực sự hỗ trợ đoạn bài học.

| ID | Nội dung được diễn giải | Trang in dùng cho bài | Trang PDF |
| --- | --- | --- | --- |
| `p1-ch01` | Mạch vành, mảng bám và khoảng thời gian dài của thói quen | 37, 38 | 39, 40 |
| `p1-ch02` | Câu chuyện chăm sóc bệnh nhân phổi, phân biệt tự sự và chứng cứ | 54, 55 | 56, 57 |
| `p1-ch03` | Phân biệt chủ đề đột quỵ và Alzheimer, tác động tới gia đình | 70, 71 | 72, 73 |
| `p1-ch04` | Những bệnh khác nhau trong đường tiêu hóa và phạm vi kết quả | 96, 97 | 98, 99 |
| `p1-ch05` | Chuỗi sản xuất thực phẩm và bối cảnh bệnh lây giữa động vật/người | 117, 118 | 119, 120 |
| `p1-ch06` | Glucose, insulin và cách đọc câu chuyện cá nhân | 146, 147 | 148, 149 |
| `p1-ch07` | Ý nghĩa hai thành phần số đo huyết áp, không mã hóa ngưỡng cũ | 175, 176 | 177, 178 |
| `p1-ch08` | Trường hợp bệnh gan không do rượu và giới hạn suy đoán | 200, 201 | 202, 203 |
| `p1-ch09` | Chăm sóc người bệnh và sự khác biệt với khối u đặc | 217, 218 | 219, 220 |
| `p1-ch10` | Công việc lọc của thận và giới hạn của cảm nhận chủ quan | 230, 231 | 232, 233 |
| `p1-ch11` | Thời gian hình thành/phát hiện bệnh, giữ đúng kết quả nghiên cứu | 248, 249 | 250, 251 |
| `p1-ch12` | Sức khỏe tinh thần, câu chuyện cá nhân không thay điều trị | 273, 274 | 275, 276 |
| `p1-ch13` | Nguồn lời khuyên, quảng bá thực phẩm và bối cảnh tuyến tiền liệt | 291, 292 | 293, 294 |
| `p1-ch14` | Các mặt của Parkinson và câu hỏi nghiên cứu phơi nhiễm | 309, 310 | 311, 312 |
| `p1-ch15` | An toàn chăm sóc, không diễn giải tiêu đề thành từ chối bác sĩ | 326, 327 | 328, 329 |
| `p2-introduction` | Cầu nối từ phần nghiên cứu sang lựa chọn ăn uống của tác giả | 345 | 347 |
| `p2-daily-dozen` | Thực phẩm thực vật không hoàn toàn tương đương, cần nhìn sự đa dạng | 367 | 369 |
| `p2-dd01` | Ví dụ các loại đậu và dạng món ăn | 373 | 375 |
| `p2-dd02` | Ví dụ quả mọng, dạng tươi/đông lạnh/khô | 389 | 391 |
| `p2-dd03` | Các loại quả quen và cách mô tả dạng ăn | 399 | 401 |
| `p2-dd04` | Nhận biết nhóm họ cải và cách đọc lời giới thiệu hấp dẫn | 410 | 412 |
| `p2-dd05` | Rau lá và dạng sống/nấu chín trong bảng | 418 | 420 |
| `p2-dd06` | Đa dạng rau củ và nấm ngoài hai nhóm trước | 431 | 433 |
| `p2-dd07` | Hạt lanh vàng/nâu, nguyên/xay | 453 | 455 |
| `p2-dd08` | Ví dụ quả hạch, hạt và bơ hạt | 458 | 460 |
| `p2-dd09` | Nhận biết thảo mộc/gia vị và thành phần tạo vị | 468 | 470 |
| `p2-dd10` | Ví dụ ngũ cốc nguyên cám và các dạng món | 493 | 495 |
| `p2-dd11` | Thức uống là một phần của thói quen, cần mô tả thành phần | 505 | 507 |
| `p2-dd12` | Những ví dụ vận động và phân biệt đọc với thực hiện | 522 | 524 |
| `p2-conclusion` | Tai nạn ngoài chế độ ăn, an toàn và niềm vui trong đời sống | 531, 532 | 533, 534 |

Các trang in 533-534 / PDF 535-536 cũng đã xem để kiểm tra mạch của kết luận,
nhưng không cần dùng phần thảo luận cơ chế tưởng thưởng ở đó cho bài nhập môn.

## Giới hạn nội dung

- Các bài là phần đọc nhập môn có nguồn, không phải bản thay thế sách hoặc tổng
  hợp toàn bộ bằng chứng hiện nay về từng bệnh.
- Tiêu đề nguồn được giữ nguyên để người đọc tìm lại sách. Nó không trở thành
  lời hứa một bữa ăn phòng/chữa bệnh hoặc tiên lượng cá nhân.
- Không tái xuất các ngưỡng chẩn đoán, lịch tầm soát, tỷ lệ tử vong hay số lượng
  khẩu phần trong bản cũ như chỉ định cho người dùng.
- Một số câu hướng dẫn tự suy ngẫm áp dụng cách đọc vào việc ghi nhật ký: gọi rõ
  nguyên liệu, dạng ăn, cách chế biến và điều chưa biết. Chúng là câu hỏi học
  tập do ứng dụng biên soạn, không phải trích dẫn nguyên văn của tác giả.
- Không suy ra mức vận động, tình trạng bệnh, thuốc hay hoàn thành mục tiêu dinh
  dưỡng từ việc đánh dấu đọc. Dữ liệu đọc chỉ ghi thao tác người dùng xác nhận.

## Kiểm tra dữ liệu đã thực hiện

Đối chiếu đủ 30 ID duy nhất theo đúng thứ tự danh mục; không thêm bài giả hoặc
bỏ mất mục bổ trợ. Các mục có tóm tắt, đoạn đọc và câu hỏi không rỗng, cùng
trang nguồn thuộc chính mục tương ứng. Mọi cặp trang đều thỏa PDF = trang in + 2.
Tập này không thêm PDF hay ảnh scan vào Git. Kết quả kiểm thử loader, giao diện
và lưu tiến độ do điều phối viên ghi tại [test report](test-report.md).
