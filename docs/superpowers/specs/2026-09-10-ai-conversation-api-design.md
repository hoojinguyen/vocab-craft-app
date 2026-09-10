# API handoff: Stage hội thoại AI trong deck

Ngày: 2026-09-10 · Trạng thái: Chờ review hợp đồng kỹ thuật

Yêu cầu sản phẩm dưới đây đã được thống nhất. Tên bảng, trường và endpoint là hợp đồng đề xuất để team API và iOS review trước triển khai. Phạm vi chỉ gồm hội thoại; không bao gồm onboarding hay thiết kế lại learning path.

## 1. Kết quả sản phẩm

- Mỗi deck có 1–2 stage hội thoại **tùy chọn**, đặt sau một nhóm lesson từ vựng. Không chặn bài tiếp theo, Unit Review Exam hoặc điều kiện hoàn thành deck; Treasure giữ vai trò phần thưởng.
- Hội thoại hai vai A/B, khoảng 4–6 lượt lời ngắn, mục tiêu một lần luyện 1–2 phút. Thời lượng là mục tiêu thiết kế, không phải giới hạn cắt thu âm.
- Dùng một nhóm từ đã học trong các lesson trước đó của cùng deck, đúng nghĩa và phù hợp CEFR. Không cố nhồi toàn bộ từ của deck vào một đoạn.
- Người học nghe mẫu, chọn một vai, đọc từng lượt; hoàn thành một vai là đủ. Đổi vai là luyện thêm. Chạm từng câu để hiện/ẩn bản dịch Việt.
- Giữ hội thoại để luyện lại; có nút tạo hội thoại mới với cùng nhóm từ mục tiêu. Tạo mới không xóa trạng thái hoàn thành stage đã đạt.

## 2. Trách nhiệm

**API/content pipeline:** định nghĩa vị trí stage và nguồn từ; sinh, kiểm tra và duyệt hội thoại mặc định; đóng gói SQLite; cung cấp biến thể theo yêu cầu. Biến thể cá nhân được kiểm tra tự động, không tự trở thành nội dung editorial đã duyệt.

**iOS:** chọn nội dung theo learning path/level, kiểm tra các lesson nguồn đã hoàn thành trước khi cho luyện; phát giọng mẫu, thu âm, đối chiếu lời đọc, hiển thị dịch và lưu nội dung/tiến độ người dùng riêng với SQLite dataset bất biến. Stage bị thiếu điều kiện nguồn vẫn không chặn learning path.

Không gửi audio lên endpoint sinh hội thoại. Không có live chat, chấm phát âm phía API hoặc yêu cầu sinh file audio trong phiên bản này. App chấp nhận cách đọc tương đối rõ; đối chiếu transcript không được gọi là điểm phát âm chính xác.

## 3. Hợp đồng dataset đề xuất

Schema hiện tại của API có `lessons`, `lesson_senses`, `learning_paths`, `path_decks`; chưa có stage hội thoại. Đề xuất thêm bảng riêng để không biến hội thoại thành lesson học từ mới:

| Bảng | Trường chính và ràng buộc |
|---|---|
| `conversation_stages` | `id`, `deck_id`, `after_lesson_id`, `position`, `title_en`, `title_vi`, `is_optional` (luôn true), `revision` |
| `conversation_stage_sources` | `stage_id`, `lesson_id`; khóa ghép, không trùng |
| `conversation_stage_targets` | `stage_id`, `cefr_level`, `sense_id`, `sort_order`; nhóm từ cố định theo stage và level |
| `conversations` | `id`, `stage_id`, `cefr_level`, `revision`, `title_en`, `title_vi`, `situation_en`, `situation_vi` |
| `conversation_turns` | `conversation_id`, `turn_index`, `speaker` (A/B), `text_en`, `text_vi` |
| `conversation_turn_targets` | `conversation_id`, `turn_index`, `sense_id`, `surface_form` |

ID dùng cùng định dạng UUID của hợp đồng API, không dùng ID từ Int64 cũ của app. `position` sắp thứ tự nếu cùng điểm chèn; thứ tự hiển thị là ngay sau lesson được neo, trước lesson tiếp theo hoặc checkpoint cuối deck.

Các lesson nguồn phải thuộc cùng deck và không nằm sau `after_lesson_id`. Mỗi target sense phải có trong ít nhất một lesson nguồn. `surface_form` chỉ ra dạng từ/cụm từ thực tế trong câu; kiểm tra quan hệ với sense, không chỉ khớp chuỗi lemma.

Vì một deck có thể dùng lại ở nhiều learning path, xuất một hội thoại mặc định cho mỗi cặp `(stage_id, cefr_level)` được hỗ trợ. Level không được suy ra chỉ từ deck ID. Mọi target của cặp đó phải xuất hiện đúng nghĩa trong hội thoại; không bắt cả hai vai đều chứa toàn bộ target.

Chỉ xuất stage và bản mặc định đã duyệt, với đầy đủ khóa ngoại và EN/VI. Cùng release phải có đủ các bản mặc định mà stage quảng bá hỗ trợ. Các trường editorial như trạng thái duyệt không bắt buộc xuất sang SQLite.

Đây là thay đổi hợp đồng dataset: cập nhật schema version/manifest và kiểm tra tương thích client theo quy trình release hiện có. Không âm thầm sửa schema v1 rồi để client cũ diễn giải stage mới như lesson bắt buộc. iOS cần adapter sang hợp đồng sense UUID mới trước khi sử dụng tính năng.

## 4. Endpoint tạo biến thể đề xuất

`POST /v1/conversation-stages/{stage_id}/variants`

Endpoint dành cho app, không dùng quyền hoặc credential quản trị CMS. Áp dụng cơ chế xác thực client của service và hạn mức theo caller; không nhúng khóa nhà cung cấp AI trong app.

Request:

```json
{
  "content_version": 12,
  "stage_revision": 1,
  "cefr_level": "A2",
  "previous_conversation_id": "UUID",
  "request_id": "UUID"
}
```

`previous_conversation_id` có thể null. Service tự lấy topic, nguồn từ và target từ đúng snapshot/version; không nhận prompt hoặc danh sách từ tự do từ client. Version trong ví dụ chỉ minh họa.

Response thành công (`200`) chứa `conversation_id`, `stage_id`, `stage_revision`, `content_version`, `cefr_level`, `target_sense_ids`, `title_en/vi`, `situation_en/vi`, và `turns`. Mỗi turn chứa `turn_index`, `speaker`, `text_en`, `text_vi`, `targets: [{sense_id, surface_form}]`. Cấu trúc nội dung tương đương bản mặc định trong SQLite.

- `request_id` là khóa idempotency theo caller: retry cùng payload trả cùng kết quả, không tạo thêm biến thể; cùng khóa khác payload trả `409`.
- Chỉ trả thành công sau khi kiểm tra toàn bộ nội dung. Giới hạn tối đa hai lần gọi model trong một yêu cầu (sinh và sửa); hết thời gian hoặc vẫn không đạt thì trả lỗi, không trả bản dở dang.
- Biến thể cần khác nội dung bản trước, nhưng giữ nhóm từ và level. Không bảo đảm mọi lần đều tạo được bản mới.
- `404`: stage không tồn tại; `409`: snapshot/revision không còn phục vụ hoặc xung đột request; `422`: level không được hỗ trợ; `429`: vượt hạn mức; `503`: sinh/kiểm tra nội dung chưa thành công. Dùng envelope lỗi chuẩn của service với mã máy đọc được; không trả stack trace hoặc prompt model.
- Khi lỗi, app giữ hội thoại cũ. Chỉ thay bản hiện tại khi response đầy đủ và hợp lệ. Lượt luyện đang chạy luôn gắn với một conversation ID; không thay nội dung giữa lượt.

## 5. Kiểm tra nội dung

Kiểm tra xác định: đúng hai vai, 4–6 lượt có thứ tự liên tục, hai vai đều có lời; EN/VI không rỗng; toàn bộ target được tham chiếu và xuất hiện trong câu; ID thuộc snapshot và nhóm từ được phép. Các từ nối thông thường ngoài nhóm target được phép.

Kiểm tra ngôn ngữ: câu tự nhiên theo tình huống, đúng nghĩa của sense, bản dịch tương ứng, độ khó phù hợp CEFR và độ dài phục vụ bài ngắn. Kiểm tra cấu trúc không thay thế kiểm tra chất lượng ngôn ngữ: bản mặc định cần người duyệt, biến thể cần bước đánh giá tự động và bộ mẫu đánh giá chất lượng trước phát hành.

## 6. Tiêu chí nghiệm thu

1. Bundle xuất đúng vị trí 1–2 stage/deck, đúng nguồn từ trước đó; loại nội dung chưa duyệt và phát hiện khóa ngoại sai.
2. Deck dùng ở nhiều level nhận đúng bản mặc định và nhóm target tương ứng.
3. Endpoint giữ nguyên snapshot, nhóm từ và level; từ chối ID/revision/level không hợp lệ.
4. Retry idempotent, xử lý xung đột, hạn mức, timeout và output AI sai mà không phát hành nội dung lỗi.
5. Cùng cấu trúc hội thoại đọc được từ SQLite và response API; test hợp đồng có fixture chung cho iOS.
6. Test tích hợp iOS xác nhận bỏ qua stage vẫn mở bài tiếp theo; lỗi sinh mới giữ bản cũ; hoàn thành một vai là đủ; tạo mới không mất thành tích.

## 7. Ngoài phạm vi và bàn giao

Không thay Unit Review Exam/Treasure, không làm bài kiểm tra CEFR, không quyết định provider/model mới trong spec này. Tiến độ luyện và kiểm tra giọng nói thuộc spec iOS tiếp theo; không ghi vào dataset.

Nguồn đối chiếu: `vocab-craft-api/contracts/v1/dataset.sql`; API spec `2026-09-10-ai-curriculum-authoring-and-learning-paths-design.md`; app `LearningPathDataMapper.swift`, `SpeechAssessmentService.swift`, `FuzzySpeechMatcher.swift`.

Team API và iOS review hợp đồng trên trước triển khai, đặc biệt migration dataset và endpoint dành cho app. Đây là tài liệu bàn giao, chưa phải xác nhận endpoint hoặc schema đã được implement.
