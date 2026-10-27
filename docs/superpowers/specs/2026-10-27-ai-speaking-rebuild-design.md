# AI Speaking: xây lại trợ lý AI trên Gemini Live

- Ngày: 2026-10-27
- Trạng thái: Thiết kế đã được người dùng duyệt từng phần ngày 2026-10-27; spec chờ review.
- Thay thế: toàn bộ luồng AI Assistant hiện tại (Roleplay, Voice Call, Guided Practice, AI Pack). Spec `2026-10-22-ai-assistant-guided-communication-design.md` và các spec AI/voice trước đó chỉ còn là bối cảnh lịch sử.
- Sub-project #1 trong chuỗi Speaking → Writing → Listening.

## 1. Bối cảnh và mục tiêu

AI Assistant hiện tại gặp đồng thời bốn vấn đề: kỹ thuật không ổn định (voice/STT/TTS, provider), hội thoại kém chất lượng, sai trọng tâm sản phẩm (chỉ xoay quanh roleplay + target words) và kiến trúc quá phức tạp (6 LLM provider, 3 STT, 3 TTS, AI Pack, nhiều lớp "resilient"). Từ 2026-09-22 đến 2026-10-22 đã có khoảng 12 spec AI, phần lớn là remediation hạ tầng.

Mục tiêu: một trải nghiệm luyện nói với AI ổn định trên thiết bị thật, phản hồi đúng level, và sau mỗi buổi learner nhận được nhận xét cụ thể, có thể lưu lại.

### Quyết định đã thống nhất

1. Một cloud provider duy nhất: **Gemini**. Gỡ toàn bộ offline (Llama, Kokoro, WhisperKit), Groq, Apple Foundation Model, Mock provider và AI Pack.
2. Ứng dụng dùng cá nhân / nhóm nhỏ; người dùng tự nhập Gemini API key. Không backend, không ephemeral token.
3. Speaking làm trước; Writing và Listening là sub-project sau, tái sử dụng nền tảng phân tích.
4. Hội thoại **realtime voice** qua Gemini Live (speech-to-speech native). Không còn pipeline STT → LLM → TTS tự ghép.
5. Bốn loại nội dung buổi chạy trên cùng một engine, khác nhau ở blueprint: tình huống thực tế, chủ đề tự do, luyện thi (IELTS/TOEIC); "bám từ vựng đã học" là tùy chọn áp được cho mọi loại.
6. Feedback sau buổi: sửa lỗi ngữ pháp/từ, diễn đạt tự nhiên hơn, phát âm (định tính), điểm theo tiêu chí và tiến bộ theo thời gian.
7. Câu lưu từ feedback đi vào **Sổ cụm từ** trong Speaking Hub; tích hợp SRS là sub-project sau.
8. Hướng triển khai: làm lại module Speaking mới và xoá code AI cũ (không giữ song song, không feature flag).

### Giả định

- Đối tượng learner A2–B1; giải thích feedback bằng tiếng Việt.
- AI chỉ nói tiếng Anh, đúng level; tiếng Việt chỉ xuất hiện trong gợi ý khi learner yêu cầu.
- Feedback tạo sau buổi, không chen ngang hội thoại.

### Tiêu chí thành công

- Gọi ổn định trên iPhone thật với loa ngoài và AirPods: AI không tự nghe lại tiếng mình, ngắt lời hoạt động, không treo.
- AI giữ đúng vai, mục tiêu và level của blueprint.
- Mỗi buổi đủ dài cho ra feedback có câu trích khớp với lời learner thực sự nói, không bịa.

## 2. Phạm vi

### Bao gồm (v1)

- Loại buổi: **Tình huống** và **Chủ đề tự do**, mỗi loại kèm tùy chọn bám từ vựng.
- Bốn màn hình: Hub → Chuẩn bị → Đang gọi → Kết quả; Hub có biểu đồ tiến bộ và Sổ cụm từ.
- Phân tích sau buổi, lưu SwiftData schema V4, migration bỏ dữ liệu Guided Practice.
- Gỡ code AI cũ (mục 8).
- EN/VI đầy đủ cho UI, accessibility và blueprint biên soạn.

### Để ngoài v1

- Loại buổi **Luyện thi**: cần cấu trúc theo part, bấm giờ và rubric band riêng — spec riêng, dùng lại engine và analyzer.
- Đưa câu đã lưu vào SRS; tự động thay đổi mastery/lịch ôn từ bằng chứng hội thoại.
- Writing, Listening.
- Backend, ephemeral token, subscription/quota.
- Chấm phát âm chuyên sâu theo âm vị, tiếp tục buổi sau khi bị gián đoạn âm thanh, đồng bộ cloud.

## 3. Kiến trúc

```
Features/Speaking/
├─ SessionCatalog        Danh sách blueprint biên soạn: Scenario · Topic (Exam sau)
├─ SessionBlueprint      Dữ liệu thuần: vai AI, mục tiêu, level, thời lượng, từ vựng tùy chọn → system prompt
├─ LiveCallEngine        Actor duy nhất điều phối cuộc gọi
│   ├─ LiveSocket        WebSocket Gemini Live (sau protocol LiveTransport): setup, gửi/nhận frame, resumption handle
│   ├─ AudioIO           AVAudioEngine bật voice processing (khử vọng) · 16 kHz in / 24 kHz out · xả hàng phát khi bị ngắt lời
│   └─ LearnerRecorder   Ghi giọng learner ra .m4a trên máy (nguồn chuẩn cho phân tích)
├─ TranscriptAssembler   Ghép transcript hai phía thành lượt, gắn mốc thời gian tương đối với file ghi âm
├─ SessionAnalyzer       Sau buổi: audio + lượt + blueprint → Gemini generateContent → JSON theo schema
└─ UI                    Hub · Chuẩn bị · Đang gọi · Kết quả · Sổ cụm từ
```

Nguyên tắc:

1. **Một đường đi, không fallback ngầm.** Lỗi hiện rõ với hành động cụ thể.
2. **Khử vọng ở tầng OS** bằng voice processing của `AVAudioEngine`.
3. **Transcript realtime chỉ để hiển thị phụ đề**, không dùng để chấm. Chấm dựa trên audio learner ghi tại máy.
4. **Một buổi 5–8 phút**, nằm trong giới hạn một kết nối Live (~10 phút). Resumption chỉ để nối lại khi rớt, không để kéo dài buổi.
5. **Engine không biết sư phạm.** `LiveCallEngine` chỉ làm "cuộc gọi"; logic học nằm trong blueprint và analyzer.
6. **Tái sử dụng:** `AudioSessionCoordinator` (SpeechKit), nơi lưu Gemini API key hiện có, CraftUIKit, logic chọn từ đã học của Guided Practice (chuyển sang module mới), tab `aiAssistant` (đổi nội dung thành Speaking).

Ràng buộc Gemini Live cần xác minh lại với tài liệu khi lập kế hoạch: model native-audio hiện hành và ID chính xác; input PCM 16-bit 16 kHz little-endian, output 24 kHz; giới hạn phiên audio ~15 phút không nén và kết nối ~10 phút; `inputAudioTranscription`/`outputAudioTranscription`; `sessionResumption`; tool call; automatic VAD. Deployment target hiện tại iOS 17.0.

## 4. Luồng một buổi

```
Hub ─▶ Chuẩn bị ─▶ Kết nối ─▶ Đang gọi ─▶ Kết thúc ─▶ Phân tích ─▶ Kết quả
                    │  lỗi        │  rớt mạng → Nối lại (resumption, tối đa 1 lần)
                    └────────────▶ Lỗi rõ ràng: [Thử lại] [Thoát]
```

### 4.1 Chuẩn bị (chưa gọi API)

- Learner chọn blueprint và level. Nếu bật bám từ vựng: chọn tối đa 3 từ đã học (wordId Int64, có `totalReviews > 0` hoặc `masteryLevel > 0`).
- Thẻ mục tiêu: vai, nhiệm vụ, từ cần dùng.
- Kiểm tra trước: có key, quyền mic, có mạng. Thiếu gì báo đúng thứ đó và khoá nút gọi.

### 4.2 Kết nối

- Lấy lease audio session `.playAndRecord` qua `AudioSessionCoordinator`.
- Mở WebSocket, gửi `setup`: model, system instruction từ blueprint, response modality chỉ AUDIO, một giọng cố định, bật transcription hai phía, automatic VAD, bật session resumption, khai báo một tool `end_session(reason)`.
- Nhận `setupComplete` → gửi một lượt text ẩn để AI mở lời trước.

### 4.3 Vòng lặp đang gọi

| Nguồn | Sự kiện | Xử lý |
|---|---|---|
| Mic | buffer | Chuyển PCM 16 kHz, gửi `realtimeInput` theo gói ~40 ms; đồng thời ghi vào `LearnerRecorder` |
| Server | audio | Đưa vào hàng phát 24 kHz |
| Server | `interrupted` | Xả ngay hàng phát |
| Server | transcript | Vào `TranscriptAssembler` với mốc thời gian |
| Server | `turnComplete` | Đóng lượt AI |
| Server | `sessionResumptionUpdate` | Lưu handle mới nhất |
| Server | `goAway` | Nối lại bằng handle, không làm gián đoạn learner |
| Server | tool `end_session` | Kết thúc buổi khi AI xác định đã đạt mục tiêu |

- **Nút Gợi ý:** gửi lượt text ẩn yêu cầu AI cho gợi ý ngắn (có thể tiếng Việt); tăng `hintCount`.
- **Phụ đề:** mặc định ẩn, learner bật được.
- **Đồng hồ:** còn 30 giây gửi lượt text ẩn yêu cầu AI chào kết; quá 30 giây sau giới hạn thì ngắt cứng.

### 4.4 Kết thúc

Bốn cách: learner bấm Kết thúc, AI gọi `end_session`, hết giờ, lỗi không phục hồi. Trình tự: đóng socket → trả lease audio → đóng file ghi âm → **lưu ngay** `SpeakingSessionRecord` trạng thái `pendingAnalysis` (blueprint, lượt, đường dẫn audio, hintCount) → chạy phân tích.

## 5. Phân tích và chấm điểm

### 5.1 Gọi phân tích

- Gemini `generateContent` (không Live), cùng API key, structured output với `responseSchema` cố định.
- Đầu vào: audio learner inline (8 phút mono m4a ≈ 2 MB), các lượt từ transcript realtime, blueprint, `hintCount`.
- Model phải **tự chép lại lời learner từ audio** (`learnerTranscript`) trước khi chấm; mọi trích dẫn tham chiếu bản chép này.

### 5.2 Schema kết quả

| Trường | Nội dung | Giới hạn |
|---|---|---|
| `learnerTranscript[]` | Lời learner nguyên văn theo lượt | — |
| `scores` | fluency, grammar, vocabulary, pronunciation: số nguyên 1–5 bám CEFR + một câu lý do mỗi tiêu chí | 4 tiêu chí |
| `corrections[]` | turnIndex, câu gốc, câu sửa, loại lỗi, giải thích (VI) | ≤ 5 |
| `naturalPhrasings[]` | câu gốc đúng nhưng chưa tự nhiên, cách nói tự nhiên, ghi chú (VI) | ≤ 3 |
| `pronunciation[]` | từ, vấn đề, mẹo (VI) — định tính | ≤ 3 |
| `targetWords[]` | chỉ khi bật bám từ: từ, đã dùng, dùng đúng, câu trích | ≤ 3 |
| `objective` | đạt mục tiêu hay không + ghi chú | — |
| `summary` | 2 điểm mạnh, 1–2 trọng tâm lần sau (VI) | — |

### 5.3 Kiểm tra kết quả

- Decode chặt; sai schema → `analysisFailed`.
- Điểm ngoài 1–5 → `analysisFailed`.
- Câu trích trong `corrections`, `naturalPhrasings`, `targetWords` phải khớp gần đúng (chuẩn hoá chữ thường, dấu câu, khoảng trắng) với `learnerTranscript`; mục không khớp bị loại, không làm hỏng cả kết quả.
- Buổi có dưới 2 lượt learner: bỏ qua phân tích, Kết quả hiển thị "Buổi quá ngắn để nhận xét".

## 6. Lưu trữ

SwiftData schema V4:

- `SpeakingSessionRecord`: id, blueprintId, loại buổi, level, startedAt, duration, status (`pendingAnalysis` / `analyzed` / `analysisFailed` / `tooShort`), hintCount, tên file audio (tuỳ chọn), lượt (Codable), kết quả phân tích (Codable), và bốn cột điểm phẳng để vẽ biểu đồ tiến bộ.
- `SavedPhraseRecord`: id, câu gốc, câu đề xuất, ghi chú, nguồn (sessionId + loại mục), createdAt.
- Migration V3 → V4 xoá sáu model Guided Practice (`PracticeSessionRecord`, `PracticeTurnRecord`, `SupportExposureRecord`, `PracticePresentationRecord`, `WordUseEvidenceRecord`, `CommunicationProgressRecord`); giữ nguyên progress, SRS, reflex, widget.
- Audio: giữ cho 20 buổi gần nhất, xoá file cũ hơn; kết quả phân tích giữ vĩnh viễn.
- Không ghi ngược vào SRS: bằng chứng dùng từ chỉ hiển thị.
- "Phân tích lại" idempotent: ghi đè kết quả của chính record đó.

## 7. Xử lý lỗi

| Tình huống | Phát hiện | Xử lý |
|---|---|---|
| Thiếu key / key sai (401/403) | Pre-check / `setup` bị từ chối | Khoá nút gọi, dẫn tới ô nhập key trong Settings |
| Hết quota (429) | Mã lỗi | Thông báo hết hạn mức, không tự thử lại |
| Không có mạng | `NWPathMonitor` lúc chuẩn bị | Không cho gọi, giải thích |
| Rớt mạng giữa buổi | Socket đóng bất thường | "Đang nối lại…", resumption 1 lần, timeout 8 giây; thất bại → kết thúc và lưu phần đã nói |
| `goAway` | Server | Nối lại bằng handle, không hiển thị gì |
| Gián đoạn âm thanh (cuộc gọi, Siri) / vào nền | `AudioSessionCoordinator` | Kết thúc buổi và lưu; v1 không tiếp tục |
| Đổi route (tai nghe/loa) | Route change | Khởi động lại `AudioIO`, giữ socket |
| Thiếu quyền mic | Pre-check | Hướng dẫn mở Settings iOS |
| Phân tích lỗi | `SessionAnalyzer` | `analysisFailed` + nút "Phân tích lại" |

Mọi thông báo dùng key `app.speaking.*` với đủ EN/VI.

## 8. Gỡ bỏ code cũ

Xoá: `VocabCraftApp/Features/AIAssistant/` (trừ phần được chuyển sang Speaking), `VocabCraftApp/Data/AI/`, `VocabCraftApp/Data/AIPacks/`, `VocabCraftApp/Data/GuidedPractice/`, `VocabCraftApp/Core/AI/`, các engine `GeminiAudioSpeechEngine`, `GeminiTTSEngineAdapter`, `WhisperKitSpeechEngine`, `OnDemandAIModelManager`, `ResilientReflexSpeechEngine` nếu chỉ phục vụ AI, các protocol/use case chỉ dùng cho luồng cũ (`LLMProviderProtocol`, `AIPackProtocol`, `VoiceConversationEngineProtocol`, `ExecuteRoleplayTurnUseCase`, `FetchRoleplayScenariosUseCase`…), cùng test, key localization và dependency package không còn dùng.

Kế hoạch triển khai phải lập danh sách chính xác bằng cách dò tham chiếu, vì một số thành phần audio (TTS Apple, `AudioSessionCoordinator`, `SpeechRecognitionService`) đang được Reflex, Shadowing và Study dùng và phải giữ lại.

## 9. Kiểm thử

1. **Unit, không mạng:** `LiveTransport` giả phát lại fixture message server (`setupComplete`, audio, `interrupted`, transcript, `goAway`, tool call, lỗi). Trạng thái buổi là reducer thuần, test mọi nhánh ở mục 7. `AudioIO` sau protocol: test chuyển đổi 16k/24k và xả hàng phát.
2. **Analyzer:** fixture JSON hợp lệ, sai schema, trích dẫn bịa, điểm ngoài khoảng; "Phân tích lại" không tạo bản ghi trùng.
3. **Blueprint:** snapshot system prompt theo loại buổi × level.
4. **Migration V3 → V4** trên store mẫu có dữ liệu Guided Practice; dữ liệu SRS/reflex/widget không đổi.
5. **Localization:** `LocalizationTests`, đủ EN/VI cho `app.speaking.*`.
6. **Checklist thiết bị thật (bắt buộc):** loa ngoài (không tự nghe lại), AirPods, ngắt lời AI, cuộc gọi đến, bật chế độ máy bay giữa buổi, chạm giới hạn 8 phút.
7. **Đánh giá prompt (thủ công, ngoài CI):** khoảng 5 bản ghi mẫu A2/B1, chạy analyzer, đối chiếu checklist (sửa đúng, không bịa, giải thích dễ hiểu).

Quality gate theo AGENTS.md: 0 error, 0 warning, swiftlint sạch, toàn bộ test pass, CraftUIKit-first, không chuỗi hardcode.

## 10. Lộ trình sau v1

1. Loại buổi Luyện thi (IELTS/TOEIC).
2. Đưa Sổ cụm từ vào SRS.
3. Writing — dùng lại `SessionAnalyzer` và schema feedback.
4. Listening — Gemini tạo bài nghe theo level và từ đã học.
