# Spec — Luyện hội thoại mẫu bằng nghe/nói thật

Ngày: 2026-09-14. Trạng thái: tài liệu thiết kế cho bước triển khai tiếp theo; chưa xác nhận tính năng hoàn tất.

## 1. Mục tiêu và hiện trạng

Người học mở Home → Bài học hội thoại mẫu → Bắt đầu luyện tập, nghe app đọc vai đối phương và đọc thành tiếng phần của mình. App nhận diện câu đọc, phản hồi khi cần thử lại và chuyển lượt khi đạt. Một lần luyện vẫn dùng đoạn ngắn khoảng 1–2 phút, 4–6 lượt lời.

Bản đã cài trên Hooji hiện chỉ mô phỏng audio. Commit `0c6570f2` đã thêm nút mở lesson trên Home; commit `76ce6d60` chứa UI, nội dung mẫu và state machine mô phỏng.

Trong worktree `codex/conversation-ui` có bản nháp chưa commit của evaluator, adapter audio, thay đổi SpeechKit/TTS và một số test. Chưa có `ConversationLiveSession` hoàn chỉnh hoặc UI live đã tích hợp. Một số test đang tham chiếu type chưa tồn tại; không coi working tree này là bản build đã được kiểm chứng. Người triển khai phải kiểm tra và hoàn thiện bản nháp, không tạo lại mù quáng hoặc xóa mất công việc đang có.

Spec này cụ thể hóa phần audio trong [thiết kế iOS tổng thể](2026-09-10-ai-conversation-ios-design.md). Phạm vi milestone dưới đây quyết định việc triển khai hiện tại.

## 2. Phạm vi

**Bao gồm:**
- Nghe/nói thật trên iPhone cho hai hội thoại mẫu hiện có, mở từ lesson trên Home.
- Chọn vai A/B, tự phát/thu theo lượt, nhận diện câu, kết thúc lượt, thử lại, nghe mẫu câu cần luyện.
- Tạm dừng/tiếp tục, xử lý quyền và lỗi audio, lưu tiến độ luyện cục bộ.
- Kiểm thử hồi quy Speaking hiện có và thử nghiệm thực tế trên Hooji.

**Chưa triển khai trong milestone này:**
- API sinh hội thoại, streaming chatbot, SQLite contract mới hoặc thay đổi service backend.
- Chèn stage chính thức vào từng deck, thay đổi onboarding/CEFR, XP, Unit Review Exam hoặc Treasure.
- Migration SwiftData cho conversation, đồng bộ tiến độ qua tài khoản hoặc lưu bản ghi âm.
- Chấm điểm âm vị, cam kết nhận dạng offline hoặc hỗ trợ mọi giọng đọc.

Nội dung mẫu và lesson thử nghiệm tiếp tục chỉ có trong Debug. Nút tạo hội thoại chỉ chuyển giữa các mẫu đóng gói và phải được mô tả đúng; không gọi đó là AI sinh mới.

## 3. Luồng người học

### Mở bài và chọn vai

Hiển thị tình huống, toàn bộ hội thoại và lựa chọn vai. Chưa phát âm thanh hoặc xin quyền khi chỉ mở lesson. Bấm Bắt đầu mới khởi động lượt đầu. Nếu đã có phiên live dở, hiển thị Tiếp tục và giữ vai đã chọn.

Phân biệt nội dung mẫu với chế độ mô phỏng: trên iPhone, dòng giới thiệu nói rõ đây là hội thoại mẫu có nghe/nói thật. Không hiển thị bộ chọn kết quả giả lập trong luồng live.

### Lượt đối phương

App đọc đúng câu tiếng Anh của vai còn lại. Chỉ chuyển sang lượt tiếp theo khi nhận được kết quả phát **hoàn tất thành công**. Lỗi thiết bị, timeout, hủy phát hoặc interruption không được hiểu là đã đọc xong.

### Lượt người học

1. Hiển thị “Đang chuẩn bị micro” trong lúc xin quyền và chuẩn bị audio.
2. Khi engine đã bắt đầu thu thành công, hiển thị “Đến lượt bạn — hãy đọc câu được đánh dấu”. Mic tự bật, không cần bấm thêm.
3. Hiển thị transcript đang nhận diện. Không dùng transcript tạm để cho qua câu.
4. Khi có kết quả cuối hoặc đủ khoảng im lặng sau lời nói, dừng thu và đánh giá.
5. Đạt: chuyển ngay sang lượt kế tiếp, không thêm nút xác nhận thành công.
6. Chưa đạt: giữ câu, hiển thị câu nhận diện được và hướng dẫn đọc lại; chờ nút **Thử lại**.
7. Không có tiếng: thông báo chưa nghe được lời đọc, không kết luận phát âm sai.

Bấm Thử lại mới bắt đầu lần thu mới. Có nút **Nghe mẫu** ở màn chuẩn bị và khi chờ thử lại: phát câu thuộc vai người học, không tăng tiến độ và không tự bật mic khi phát xong. Nghe mẫu lỗi vẫn ở câu hiện tại và cho thử lại.

### Hoàn thành và luyện thêm

Hoàn thành khi mọi câu của vai người học đạt và các câu đối phương còn lại đã phát xong. Đổi vai là tùy chọn; bắt đầu lượt luyện mới nhưng giữ thành tích đã hoàn thành. Không gọi `CompleteLessonUseCase`, không phát XP từ bài mẫu.

Tap bản dịch, cuộn tự do, quay lại câu hiện tại và đóng lesson giữ hành vi UI đã có.

## 4. Đánh giá câu đọc

Đánh giá độ khớp **nội dung nhận diện**, không coi đó là phép đo trực tiếp chất lượng phát âm.

- Dùng chuẩn hóa của SpeechKit: dấu câu, hoa/thường, số và viết tắt.
- Dùng căn chỉnh chuỗi từ có dung sai, không bắt transcript giống từng ký tự.
- Kiểm tra riêng độ phủ nội dung; không cho qua chỉ vì điểm trung bình cao khi mất đầu/cuối câu hoặc từ vựng mục tiêu.
- Từ bắt buộc của một lượt là các từ trong `vocabularyReferences` thực sự xuất hiện trong câu của lượt đó sau chuẩn hóa.
- Bỏ hoặc thêm phủ định làm đổi nghĩa phải yêu cầu thử lại.
- Kết quả rỗng là `silence`, không phải lỗi phát âm.
- Không hiển thị điểm số này dưới nhãn “điểm phát âm”.

Thông số khởi đầu để thử nghiệm: fuzzy token threshold `0.78`, minimum coverage/mean similarity `0.82`, initial silence `4 giây`, trailing inactivity `1.5 giây`, capture maximum `20 giây`. Đây là giá trị cấu hình tạm; chỉ chốt sau thử giọng đọc thực tế. Timer bắt đầu sau khi capture thực sự chạy, không tính thời gian người học đang cấp quyền. Không reset timer im lặng chỉ vì recognizer gửi lại transcript không thay đổi.

## 5. Audio và lifecycle

- Tái sử dụng `TextToSpeechService`, SpeechKit và coordinator chung từ `AppContainer`.
- TTS giữ quyền quản lý playback lease; adapter chỉ quản lý capture lease. Không acquire hai lần cùng một thao tác.
- Engine SpeechKit có tùy chọn không tự cấu hình/hủy AVAudioSession khi dùng coordinator bên ngoài; caller cũ giữ mặc định hiện tại.
- Phát và thu không chồng lấn. Kết quả capture chỉ trả về sau khi stop recognition và hoàn tất release lease, trước khi phát câu kế tiếp.
- `stop()` và task cancellation đều vô hiệu hóa công việc cũ, kể cả lúc đang chờ authorization, acquire lease hoặc callback.
- Mọi callback/timer gắn với một attempt ID. Callback cũ không sửa transcript, tăng tiến độ hoặc dừng attempt mới.
- Background, interruption bắt đầu, mất route đang dùng và đóng lesson đều dừng audio, lưu vị trí và chờ Tiếp tục. Không tự resume khi interruption kết thúc.
- `.inactive` do hộp thoại xin quyền không tự hủy phiên; background thực sự vẫn phải hủy.
- TTS kết thúc do timeout/hủy/lỗi trả outcome riêng. Không thay đổi semantics của caller Speaking/Reflex cũ.

## 6. Trạng thái và giao diện

`ConversationLiveSession` cô lập MainActor và dùng Observation. View chỉ gửi hành động, render dữ liệu và chuyển tiếp sự kiện lifecycle.

| Trạng thái | UI/hành động | Chuyển tiếp |
|---|---|---|
| ready | Chọn vai, Bắt đầu, Nghe mẫu | Lượt đầu |
| preparing | Đang chuẩn bị mic, Tạm dừng | listening hoặc awaitingRetry |
| playingPartner | Đang nghe đối phương, Tạm dừng | Lượt tiếp sau thành công |
| listening | Mic đang thu, transcript, Tạm dừng | evaluating |
| evaluating | Dừng mic, kiểm tra câu | Lượt tiếp hoặc awaitingRetry |
| awaitingRetry | Lý do cụ thể, Thử lại, Nghe mẫu | preparing hoặc phát mẫu |
| paused / awaitingContinue | Tiếp tục, Đóng | Khởi động lại lượt dở |
| completed | Hoàn thành, Đổi vai, hội thoại mẫu khác | Lần luyện mới |

Đang phát mẫu là trạng thái phụ `isPlayingSample`; giữ trạng thái ready/awaitingRetry để khi phát xong không vô tình tiến bài. Bấm Tạm dừng hoặc Đóng phải dừng cả phát mẫu.

Lỗi quyền: thông báo cần quyền micro/nhận dạng, nút **Mở Cài đặt**, Thử lại và Đóng. Khi quay lại từ Settings không tự bật mic. Recognizer không khả dụng, lỗi thu hoặc lỗi phát dùng thông báo hệ thống riêng, không cáo buộc người học phát âm sai.

Dùng `CraftConversationTurnView`, `CraftTactileMicHubView`, `CraftSpeakerButton`, `CraftButton` và token sẵn có. Tất cả text/a11y mới có catalog EN/VI đầy đủ, `manual` và `translated`. VoiceOver không tự đọc transcript tạm liên tục; trạng thái phải thể hiện bằng chữ, không chỉ màu.

## 7. Lưu tiến độ và chế độ thử nghiệm

Tiếp tục dùng `ConversationSessionStorage` cho milestone này, với key live riêng `debug.conversation.live.session.v1`. Không nhập tiến độ hoặc thành tích từ `debug.conversation.mock.session`.

Lưu conversation ID, role, current turn index, passed turn IDs và completion achievement sau chuyển lượt. Đối chiếu snapshot với script, lọc ID/vai không hợp lệ và không tự bắt đầu thu khi restore. Đổi nội dung chỉ khi không thu/phát; giữ bản cũ nếu việc tải mẫu thất bại.

Preview và route mock chuyên dụng có thể giữ để test UI. Simulator dùng recognition giả lập hiện có của SpeechKit phải hiển thị nhãn mô phỏng rõ ràng; simulator pass không chứng minh phát âm thật hoạt động.

## 8. Tiêu chí nghiệm thu

- **AC1:** Từ Home, Start mở luồng live; iPhone không còn bộ chọn pass giả.
- **AC2:** Vai B nghe được app đọc lượt A trước; vai A có mic tự bật khi bắt đầu.
- **AC3:** Transcript tạm không làm chuyển lượt; câu đầy đủ chỉ chuyển sau final/end-of-utterance.
- **AC4:** Câu thiếu từ mục tiêu/đầu/cuối hoặc đổi phủ định không được tự cho qua; lỗi nhỏ được dung nạp theo policy.
- **AC5:** Im lặng, lỗi và đọc chưa đạt đều chờ thao tác rõ ràng; không lặp thu tự động.
- **AC6:** Pause/Close/background/interruption dừng mic và TTS; callback cũ không làm tiến bài. Resume bắt đầu lại câu dở.
- **AC7:** Nghe mẫu không bật mic hoặc hoàn thành câu; cấp quyền không bị timeout trong lúc hộp thoại mở.
- **AC8:** Restore đúng conversation/vai/lượt, tách khỏi mock; đổi vai giữ thành tích live nhưng xóa tiến độ lần luyện.
- **AC9:** Không thay hành vi Speaking/Reflex cũ; localization, lint và các test liên quan pass.
- **AC10:** Build/cài/mở trên Hooji thành công; người dùng xác nhận nghe được partner, mic nhận lời đọc, thử lại và chuyển lượt trên máy thật.

Quality gate của repo vẫn yêu cầu zero warnings. Các warning concurrency có sẵn phải được ghi lại và phân biệt với warning mới; không gọi bản build đạt gate chỉ vì build thành công. Hiệu chỉnh giọng đọc/tiếng ồn và các tình huống thiết bị chưa chạy phải được đánh dấu chưa nghiệm thu.
