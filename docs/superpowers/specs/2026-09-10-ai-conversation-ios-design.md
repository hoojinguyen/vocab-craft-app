# iOS: Luyện hội thoại theo vai

Ngày: 2026-09-10 · Trạng thái: Chờ người dùng review bản viết

## 1. Phạm vi và mục tiêu

Thêm bài luyện hội thoại biên soạn sẵn vào learning path, giúp người học vận dụng từ đã học trong topic. Một lần luyện khoảng 1–2 phút, dự kiến 4–6 lượt lời ngắn; đây không phải thời gian giới hạn bắt buộc.

API/content pipeline thuộc team API. iOS dùng [hợp đồng bàn giao](2026-09-10-ai-conversation-api-design.md); tên trường và endpoint phải được đối chiếu với hợp đồng team API thực sự phát hành. Không triển khai backend, onboarding, đánh giá CEFR hoặc live chatbot trong phạm vi này.

Không thêm thư viện chat ngoài. Người dùng đã đồng ý mở rộng CraftUIKit; tận dụng SpeechKit và dịch vụ đọc mẫu hiện có.

## 2. Learning path

- Hiển thị 1–2 stage hội thoại/deck tại vị trí dataset quy định, sau các lesson nguồn.
- Stage là tùy chọn: không chặn lesson tiếp theo, checkpoint, deck tiếp theo hoặc tính vào mẫu số tiến độ bắt buộc. Chỉ cho bắt đầu luyện khi các lesson nguồn đã hoàn thành.
- Unit Review Exam và Treasure giữ vai trò hiện tại. Không đi qua đường mở lesson thông thường bằng cách giả một stage chứa từ mới.
- Nội dung và tiến độ hội thoại tách riêng khỏi `CompleteLessonUseCase`; phiên bản này không bổ sung XP hoặc thay kinh tế phần thưởng.
- Dataset cũ chưa có hội thoại vẫn hiển thị và học bình thường. Schema không được hỗ trợ phải đi qua cơ chế tương thích dataset, không giải mã âm thầm thành stage thường.

## 3. Trải nghiệm

**Chuẩn bị:** mở toàn màn hình theo luồng lesson hiện tại; hiển thị tình huống, cho nghe mẫu và chọn vai A/B. Người học chạm bắt đầu sau khi chọn vai. Nếu có phiên đang dở, hiển thị Tiếp tục; không tự bật micro khi vừa mở màn hình.

**Luyện:** hiển thị toàn bộ hội thoại theo thứ tự. Nhãn vai phân biệt phần app/người học. Làm nổi bật câu hiện tại và tự cuộn khi chuyển lượt. Khi người dùng chủ động cuộn, ngừng tự kéo vị trí; có thao tác quay về câu hiện tại để bật lại chế độ theo dõi. Chạm câu để bật/tắt bản dịch Việt, mặc định ẩn.

- App đọc lời của vai còn lại; đến lượt người học tự bật nghe, kể cả khi lượt đầu thuộc người học.
- Kết thúc câu và đạt yêu cầu: tự chuyển tiếp ngay, không có màn phản hồi thành công hay nút xác nhận.
- Chưa đạt: giữ câu, đánh dấu phần thiếu/chưa rõ và chờ chạm **Thử lại**. Người học có thể nghe mẫu trước khi thử lại.
- Chưa thu được lời nói: dừng nghe và cho Thử lại, không ghi nhận là đọc sai. Lỗi hệ thống không được diễn giải thành lỗi phát âm.
- Có Tạm dừng. Nghe lại mẫu trong phiên luyện sẽ dừng thu trước; khi mẫu kết thúc vẫn chờ người học tiếp tục/thử lại, tránh bật micro bất ngờ.
- Chạm xem dịch không tự chuyển lượt hay thay nội dung; Tạm dừng là thao tác chủ động để có thêm thời gian đọc.

**Hoàn thành:** sau khi mọi lượt của vai được chọn đã đạt và phần lời còn lại của đoạn đã phát xong, hoàn thành stage. Đổi vai và luyện lại là tùy chọn. Thành tích hoàn thành stage được giữ khi luyện thêm.

**Gián đoạn:** thoát màn hình, xuống nền hoặc audio interruption sẽ dừng phát/thu và lưu trạng thái. Trở lại chờ Tiếp tục; câu đang đọc dở được đọc lại từ đầu. Không lưu audio để khôi phục.

## 4. Trạng thái và trách nhiệm

Một `ConversationSessionModel` dùng Observation, cô lập MainActor và được tạo qua dependency container hiện có. View chỉ gửi hành động/hiển thị trạng thái. Không thêm framework kiến trúc.

Các trạng thái: loading, ready, playingPartner, listening, evaluating, awaitingRetry, paused, completed, loadFailed. Trong awaitingRetry phân biệt đọc chưa đạt, không có tiếng và lỗi thu/nhận dạng để có thông điệp đúng.

Luồng chính: ready → playingPartner hoặc listening → evaluating → lượt tiếp theo hoặc awaitingRetry. Thử lại → listening. Tạm dừng/gián đoạn → paused; Tiếp tục khởi động lại lượt chưa hoàn thành. Khi người dùng thoát, callback cũ không được cập nhật phiên đã đóng.

| Thành phần | Trách nhiệm |
|---|---|
| Conversation view/session model | Chọn vai, điều phối lượt, hành động người dùng, điều hướng và trạng thái màn hình |
| Conversation audio adapter | Phát mẫu, thu lời đọc, lifecycle và độc quyền phát/thu qua coordinator chung |
| Conversation turn evaluator | Quyết định độ đủ nội dung từ kết quả nhận dạng, không phụ thuộc UI hoặc API |
| Conversation repository | Đọc bản mặc định, gọi API lấy biến thể, lưu snapshot hội thoại đang dùng |
| Conversation progress store | Lưu phiên dở và hoàn thành stage qua persistence người dùng hiện có |

Các dependency có thể thay bằng fixture/mock để phát triển iOS khi API chưa sẵn sàng. Tích hợp thật chỉ hoàn tất sau khi hợp đồng được xác nhận; mock không phải bằng chứng backend đã hoạt động.

## 5. Âm thanh và đánh giá

Tái sử dụng `TextToSpeechService`, khả năng nhận dạng/căn chỉnh câu của SpeechKit và `AudioSessionCoordinator`. Không dùng nguyên logic khớp một lemma của Reflex để đánh giá cả lượt thoại.

Engine SpeechKit hiện tự thay đổi AVAudioSession; đường Conversation phải phối hợp acquire/release qua coordinator chung, không để hai bên độc lập kích hoạt/hủy session. Việc thay đổi shared code phải giữ hành vi Reflex hiện có.

- Chỉ thu sau khi lời mẫu kết thúc thành công và micro sẵn sàng. Không coi lời mẫu bị hủy/lỗi là phát xong bình thường.
- Transcript tạm dùng để cập nhật trạng thái; chỉ chuyển lượt sau khi kết thúc lời nói và đánh giá kết quả cuối. Bổ sung chính sách này riêng, giữ mặc định cho qua sớm của Reflex nếu caller cũ cần.
- Phân biệt **độ phủ nội dung** với **độ tương đồng từ**: không cho qua chỉ vì điểm trung bình cao khi thiếu cuối câu hoặc từ mục tiêu. Cho phép khớp gần đúng, chuẩn hóa viết tắt và dấu câu; không đòi transcript trùng từng ký tự.
- Mục tiêu là phát âm tương đối dễ hiểu. Kết quả khớp transcript không được hiển thị như điểm phát âm âm vị, và không khẳng định người học phát âm sai chỉ từ lỗi nhận dạng.
- Ngưỡng số và khoảng chờ được cấu hình trong evaluator/audio adapter. Chúng chỉ được chốt sau đánh giá bản thu đại diện, trước phát hành: câu đọc đầy đủ, thiếu đầu/cuối, thiếu từ mục tiêu, ngập ngừng, giọng Việt và tiếng ồn. Không áp dụng nguyên ngưỡng 0.75 như bằng chứng chất lượng.
- Thiếu quyền micro/nhận dạng: giải thích và cho cấp quyền qua Settings hoặc thoát; không tự đánh dấu hoàn thành. Không hứa nhận dạng offline trên mọi thiết bị.

## 6. CraftUIKit và localization

Bổ sung `CraftConversationTurnView` nhận dữ liệu trình bày: nhãn vai, text EN/VI, trạng thái active/completed/retry và các token đánh giá; phát hành sự kiện xem nghĩa/nghe mẫu. Component không biết stage ID, API, database hoặc điều phối micro.

Tái sử dụng `CraftCard`, `CraftSpeakerButton`, `CraftTactileMicHubView`, thành phần speech token và button hiện có khi phù hợp. Thành phần danh sách hội thoại và theo dõi cuộn được tổ chức quanh component lượt thoại; trạng thái nghiệp vụ ở app. Bổ sung cách thể hiện node Conversation trong learning path bằng token/style hiện có.

Mọi styling mới dùng token CraftUIKit. UI/a11y dùng catalog EN/VI đầy đủ: `craft.conversation.*` cho thành phần dùng chung; `app.conversation.*` cho luồng học. Văn bản hội thoại là nội dung song ngữ từ dataset/API, không phải literal hardcode trong view và không đưa từng hội thoại sinh ra vào xcstrings.

Hỗ trợ Dynamic Type, VoiceOver và Reduce Motion; trạng thái không truyền đạt chỉ bằng màu. Không ép VoiceOver đọc mỗi transcript tạm; nút thử lại và câu cần sửa phải truy cập được.

## 7. Lưu và sinh lại nội dung

- Lưu snapshot bất biến của hội thoại đang dùng với conversation ID/revision, stage ID, dataset version và level; lưu vai, các lượt đã đạt và vị trí tiếp tục sau mỗi lượt đạt. Không chỉ lưu lúc thoát vì app có thể bị kết thúc bất ngờ.
- Phiên dở gắn với đúng snapshot; dataset cập nhật không thay câu trong phiên. Nếu stage bị gỡ, không ghi thành tích sang một stage khác.
- Thành tích hoàn thành stage độc lập với tiến độ từng lần luyện, theo người dùng và level. Việc đổi vai/tạo biến thể không xóa thành tích cũ hoặc dùng tiến độ vai cũ để hoàn thành vai mới.
- Tạo mới chỉ từ màn chuẩn bị/kết thúc. Nếu có phiên dở, yêu cầu xác nhận việc bắt đầu phiên mới; giữ toàn bộ bản cũ tới khi tạo mới thành công.
- Dùng request ID ổn định khi retry cùng yêu cầu API. Kiểm tra identity/version/level, cấu trúc và nội dung bắt buộc trước khi thay snapshot; lỗi mạng/validation giữ bản cũ. Ghi thay snapshot và reset phiên luyện nguyên tử.
- Nội dung nằm trong database người dùng, không sửa SQLite dataset. Không đồng bộ tiến độ qua API trong phạm vi này.

## 8. Kiểm thử và điều kiện hoàn tất

1. State machine: vai A/B, tự nghe, đạt chuyển ngay, chưa đạt chờ Thử lại, callback lặp/cũ không chuyển hai lượt; hoàn thành một vai đủ.
2. Audio: lời mẫu không lọt vào lượt nhận dạng; dừng/thu luân phiên; quyền bị từ chối, không có tiếng, interruption/background, hủy phát và thoát màn hình.
3. Evaluator: thiếu cuối câu/từ mục tiêu không lọt qua điểm trung bình; lỗi nhỏ được dung nạp; kiểm tra bằng audio thực tế trước khi chốt ngưỡng.
4. Persistence: tiếp tục đúng câu/vai đã chọn sau relaunch; dataset cập nhật giữ snapshot; đổi vai/sinh mới không xóa thành tích; thất bại lưu không báo thành công giả.
5. API contract: fixture chung với team API, response sai ID/version bị từ chối, retry idempotent và lỗi giữ bản cũ.
6. Learning path: stage tùy chọn không chặn tiến độ, checkpoint hoặc deck tiếp theo; dataset cũ không bị ảnh hưởng.
7. UI: toàn bộ hội thoại, tự cuộn/tự cuộn bị tạm ngưng khi người học kéo, dịch từng câu, Dynamic Type/VoiceOver, theme và EN/VI.

Chạy kiểm tra localization CraftUIKit, các package test và app test liên quan, SwiftLint và build Xcode theo quality gate của repo; kiểm tra hồi quy Speaking hiện có. Tính năng chỉ được xác nhận đầy đủ sau khi kiểm thử thiết bị thật về âm thanh và tích hợp schema/API đã hoàn thiện. Đây là spec thiết kế, chưa phải xác nhận các kiểm tra đã chạy.
