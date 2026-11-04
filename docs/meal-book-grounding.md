# Nguồn sách cho phân tích bữa ăn

## Phạm vi nội dung đã đối chiếu

Corpus [meal-knowledge.json](../assets/content/meal-knowledge.json) gồm 15 đoạn
diễn giải ngắn được biên soạn từ các trang đã đọc trực quan của bản PDF
*Ăn gì không chết - Sức mạnh chữa lành của thực phẩm*, Michael Greger và Gene
Stone, do người dùng cung cấp tại `docs/requirements/An-Gi-*.pdf`.
Đây là tập nguồn chọn lọc phục vụ Flow 2, chưa phải chỉ mục toàn bộ cuốn sách.

PDF là bản scan 774 trang; ở các trang đối chiếu, số trang PDF tính từ 1 bằng
trang in cộng 2. Dùng thư viện PyMuPDF đã có trong `tmp/pdf_tools` để render;
ảnh đối chiếu `tmp/book/meal-*.png` và sách gốc được Git bỏ qua. Mỗi nguồn bên
dưới đã được xem trực tiếp; không suy ra khuyến nghị từ tiêu đề mục lục.

| ID đoạn nguồn | Chương / nhóm | Trang in | Trang PDF | Nội dung đối chiếu |
| --- | --- | --- | --- | --- |
| `beans-protein-fibre` | Đậu | 374 | 376 | Đạm, chất xơ và cách kết hợp đậu trong bữa |
| `cruciferous-variety` | Rau củ họ cải | 410 | 412 | Danh sách nhóm họ cải; không gán tác dụng điều trị từ tên nhóm |
| `leafy-greens` | Rau xanh | 418 | 420 | Rau lá trong danh mục thực phẩm thường xuyên |
| `whole-fruit` | Các loại trái cây khác | 400 | 402 | Phân biệt nguyên quả, xay, ép; chất xơ và nghiên cứu dài hạn |
| `whole-grains` | Ngũ cốc nguyên cám | 494 | 496 | Các liên hệ nghiên cứu với tim mạch và tiểu đường loại 2 |
| `ground-flax` | Hạt lanh | 454 | 456 | Xay hạt và phối hợp với yến mạch, salad, súp |
| `nuts-seeds` | Quả hạch và các loại hạt | 459 | 461 | Dùng hạt trong sốt, súp, rau và trái cây |
| `vegetable-variety` | Các loại rau củ khác | 432 | 434 | Đa dạng loại rau; màu sắc không phải tiêu chí duy nhất |
| `salt-pressure` | Chương 7: cao huyết áp | 183 | 185 | Giảm muối thêm vào và tạo vị bằng gia vị, thảo mộc |
| `processed-sodium` | Chương 7: cao huyết áp | 182 | 184 | Natri có thể nằm trong thực phẩm chế biến sẵn |
| `meat-plant-balance` | Chương 4: ung thư đường tiêu hóa | 102 | 104 | Nghiên cứu về thịt, đậu và cân đối toàn bộ chế độ ăn |
| `red-processed-meat-context` | Chương 4: ung thư đường tiêu hóa | 106 | 108 | Liên hệ nghiên cứu dài hạn về thịt đỏ, thịt chế biến và sức khỏe |
| `refined-grain-choice` | Ngũ cốc nguyên cám | 499 | 501 | Ví dụ thay gạo trắng, bánh mì trắng và đa dạng ngũ cốc |
| `sweetened-drink-choice` | Thức uống | 506 | 508 | Ưu tiên nước và chú ý thành phần tạo ngọt trong đồ uống |
| `greens-warfarin` | Rau xanh | 419 | 421 | Lưu ý riêng cho người dùng warfarin khi đổi lượng rau xanh |

Các trang PDF đã xem bổ sung để kiểm tra ngữ cảnh gồm 39, 40, 98-112, 148, 149,
177-185, 375, 401, 413, 433, 455, 460, 495, 497-504 và 507. Không dùng các đoạn mở đầu
mang tính kể chuyện hoặc các ngưỡng chẩn đoán cũ trong sách làm dữ liệu
chẩn đoán cho ứng dụng. Các số liệu nghiên cứu và số khẩu phần trong bản sách
không được biến thành mục tiêu điều trị hoặc định lượng suy đoán từ ảnh.

## Cách dùng trường dữ liệu

- `summary` là diễn giải ý sách tại đúng trang nguồn; không phải bản chép sách.
- `mealRelevance` và `suggestion` là cách áp dụng mang tính giáo dục trong ứng
  dụng, có điều kiện xác nhận món ăn, khẩu phần và hạn chế ăn uống.
- `healthTopics` là các chủ đề để giải thích và điều hướng đọc thêm. Chúng không
  có nghĩa rằng bữa ăn được xác nhận phòng hoặc điều trị một bệnh.
- `keywords` hỗ trợ tìm đoạn liên quan; không phải nhãn phân loại y khoa. Không
  dùng từ chung `cơm`, `gạo`, `bánh mì` để tự kết luận có ngũ cốc nguyên cám.
  Các từ này có thể truy xuất đoạn `refined-grain-choice` để hỏi rõ nguyên liệu,
  nhưng cũng không được dùng để tự kết luận món chắc chắn là tinh chế. Tương tự,
  tên một đồ uống chỉ là gợi ý hỏi về đường thêm vào, không phải bằng chứng có đường.
  Tránh so khớp tên thịt rời quá rộng: `gà` có thể nằm trong `đậu gà`; bỏ dấu còn
  làm `bò` và `bơ` thành cùng chuỗi. Corpus dùng cụm rõ hơn cho các trường hợp này.
- Hai nguồn cùng `chapterId` có thể nói về những nội dung khác nhau. AI cần dùng
  `id` đoạn nguồn và trang chính xác, không chỉ tên chương, khi dẫn nội dung.

Chỉ lấy các đoạn có liên hệ với thành phần người dùng xác nhận hoặc vấn đề mà
người dùng hỏi. Khi thiếu nguồn phù hợp, báo rõ giới hạn thay vì dựng một liên
hệ bệnh lý. Ví dụ, không nhận xét mọi món có rau là có tương tác thuốc; nguồn
warfarin chỉ là lưu ý có điều kiện, không suy luận người dùng đang uống thuốc.

## Giới hạn nhận định

Một ảnh không xác định đáng tin cậy gia vị ẩn, loại dầu, khẩu phần, lượng natri,
dị ứng hoặc tổng nhu cầu năng lượng. Tuổi, cân nặng, chiều cao và mục tiêu hỗ trợ
đặt lời khuyên vào bối cảnh; các trường đó không đủ để biết bệnh nền, thai kỳ,
dị ứng, thuốc hoặc chỉ định dinh dưỡng. Không tự sinh BMI, nhu cầu điều trị hay
xác suất giảm bệnh nếu người dùng chưa yêu cầu và dữ liệu không đủ.

Sách nêu nhiều nghiên cứu và nhận định trong bối cảnh thời điểm xuất bản.
Corpus giữ nội dung như nguồn giáo dục, không coi mọi phát biểu trong sách là
hướng dẫn y khoa hiện hành. Đặc biệt, không tái sử dụng các mô tả thay thuốc
bằng thực phẩm hoặc các ngưỡng chẩn đoán trong sách để chỉ dẫn điều trị.

Đã kiểm tra nguyên tắc chung với [WHO: Healthy diet](https://www.who.int/news-room/fact-sheets/detail/healthy-diet)
và [WHO: Healthy diet, health topic](https://www.who.int/health-topics/healthy-diet):
chế độ ăn đa dạng và hạn chế muối thuộc bối cảnh thói quen ăn uống lâu dài.
WHO cũng lưu ý chế độ ăn phù hợp phụ thuộc đặc điểm cá nhân. Các trang WHO này
chỉ dùng kiểm tra cách diễn đạt an toàn, không được trộn vào corpus rồi gán
thành trích dẫn sách. Không có kết luận phòng bệnh cho cá nhân từ một bữa ăn.

Phần mở rộng thịt cũng đối chiếu cách diễn đạt với
[WHO/IARC: Red meat and processed meat](https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat).
Không đánh đồng thịt tươi và thịt chế biến, không biến phân loại bằng chứng
nguy hại hoặc số liệu nghiên cứu thành mức nguy cơ của một người. Đã xem trang
PDF 112 nói riêng về gia cầm, nhưng không đưa các mô tả liên hệ ung thư mạnh ở
đó vào corpus; món gà dùng đoạn về cân đối thịt và thực vật ở PDF 104, với giới
hạn nghiên cứu được nêu rõ. Chưa bổ sung khuyến nghị riêng cho cá hoặc trứng vì
chưa hoàn thành việc chọn nguồn trực tiếp phù hợp.

## Xác minh

Đã kiểm tra JSON đọc được, ID không trùng, `chapterId` tồn tại trong danh mục
bài học, số trang PDF bằng trang in cộng 2 và mọi trường bắt buộc hiện diện.
Việc này xác minh tập nội dung và tham chiếu, không xác minh đầu ra của mô hình
AI hoặc khả năng nhận diện món ăn trên thiết bị.
