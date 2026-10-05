# VocabCraft — Role Play AI Architecture Upgrade (Groq LLM + On-Device Kokoro-TTS & WhisperKit)

- **Date:** 2026-10-06
- **Status:** Approved by Human Partner
- **Scope:** Architectural overhaul of the AI Roleplay and Speech Subsystems across VocabCraft (`GroqLLMProvider`, `ResilientLLMProvider`, `KokoroTTSEngine`, `WhisperKitSpeechEngine`, `OnDemandAIModelManager`, `TextToSpeechService`, `ResilientConversationSpeechEngine`, `UserSettingsStore`, `SettingsView`, `RoleplayRoomView`).

---

## 1. Executive Summary & Problem Statement

### 1.1 The Current Problem
Trong tính năng luyện nói nhập vai **AI Role Play** (`RoleplayRoomView`, `RoleplayVoiceCallView`), hệ thống hiện tại đang gặp 3 rào cản nghiêm trọng:
1. **Gemini API thiếu ổn định, liên tục chạm trần Rate Limit và lỗi HTTP 503:**
   * Gemini Free Tier (`gemini-flash-latest`, `gemini-2.5-flash-preview-tts`) liên tục trả về lỗi HTTP 503 (Service Unavailable) và HTTP 429 (Rate Limit / Quota Exceeded), khiến cuộc trò chuyện thoại của người dùng bị đứt gãy giữa chừng.
2. **Chất lượng giọng nói của iOS mặc định còn hạn chế:**
   * Khi fallback hoặc chạy TTS mặc định (`AVSpeechSynthesizer`), âm thanh phát ra mang tính cơ học, thiếu ngữ điệu biểu cảm và không tạo được cảm giác tự nhiên như đang trò chuyện với người bản xứ.
3. **Độ chính xác của nhận diện giọng nói khi học phát âm:**
   * `SFSpeechRecognizer` của iOS dễ bị ảnh hưởng bởi tạp âm môi trường và xử lý chưa tối ưu ngữ âm người học tiếng Anh khi phát âm chưa chuẩn.

### 1.2 The Solution: Unified Modular AI Pipeline (Hybrid Cloud + On-Device Neural)
Người dùng chấp nhận tăng dung lượng tải của ứng dụng để đổi lấy chất lượng cao nhất và loại bỏ hoàn toàn sự phụ thuộc vào cloud rate limit. Giải pháp bao gồm:
1. **Cloud LLM Layer (Groq API - Llama 3.3 70B & 3.1 8B):**
   * Tốc độ suy luận siêu tốc (~300–500 tokens/s), chuẩn định dạng OpenAI Chat Completions với JSON Schema Structured Output (`RoleplayTurnOutput`).
   * Miễn phí, ổn định cao, triệt tiêu lỗi 503; kết hợp chuỗi fallback: **Groq $\rightarrow$ Gemini $\rightarrow$ IntelligentMock**.
2. **On-Device Voice Synthesis (Kokoro-TTS ~150MB):**
   * Mô hình neural Kokoro-82M chạy trực tiếp trên thiết bị (Core ML / ONNX Runtime), tạo ra giọng nói 24kHz tự nhiên, giàu cảm xúc, 0 độ trễ mạng, 0 rate limit.
   * `TextToSpeechService` đóng vai trò router: ưu tiên Kokoro khi model đã sẵn sàng, tự động fallback sang `AppleEnhancedTTSEngine`.
3. **On-Device Speech Recognition (WhisperKit Core ML ~40–50MB):**
   * Mô hình `openai_whisper-tiny.en` chạy trên Apple Neural Engine (ANE), nhận diện chính xác vượt trội đối với người học ngoại ngữ; tự động fallback sang `SFSpeechRecognizer`.
4. **On-Demand AI Model Manager (`OnDemandAIModelManager`):**
   * Tải model nền theo nhu cầu (~190MB tổng cộng) lưu tại `Application Support/VocabCraft/AIModels/` (loại trừ khỏi iCloud Backup).
   * Không chặn người dùng: người dùng có thể tham gia Role Play ngay lập tức bằng engine mặc định trong lúc tải model ngầm.
   * Giao diện quản lý dung lượng trong Cài đặt (`SettingsView`) cho phép xóa giải phóng bộ nhớ máy bất kỳ lúc nào.

---

## 2. High-Level Architecture Diagram

```
                                  [RoleplayVoiceCall / Room View]
                                                 │
                   ┌─────────────────────────────┴─────────────────────────────┐
                   ▼                                                           ▼
         [Speech-to-Text (STT)]                                      [LLM Turn Execution]
         AudioBufferRelay (16kHz)                                    ExecuteRoleplayTurnUseCase
                   │                                                           │
        ┌──────────┴──────────┐                                                ▼
        ▼                     ▼                                     [ResilientLLMProvider]
[WhisperKit Engine]   [Apple Speech]                                           │
  (Core ML ANE)        (Fallback)                             ┌────────────────┼────────────────┐
        │                     │                               ▼                ▼                ▼
        └──────────┬──────────┘                             [Groq]         [Gemini]          [Mock]
                   │ Transcript                             (Primary)     (Fallback 1)    (Fallback 2)
                   ▼                                          │
        [ReflexSpeechMatcher]                                 ▼
         Target Words Matched                      RoleplayTurnOutput (JSON)
                   │                                          │
                   └──────────────────┬───────────────────────┘
                                      ▼
                           [Text-to-Speech (TTS)]
                            TextToSpeechService
                                      │
                         ┌────────────┴────────────┐
                         ▼                         ▼
                 [KokoroTTSEngine]         [AppleEnhancedTTS]
                 (On-Device Neural)            (Fallback)
                         │                         │
                         └────────────┬────────────┘
                                      ▼
                           AudioSessionCoordinator
                        (.duplexSpeech Audio Lease)
```

---

## 3. Detailed Component Specifications

### 3.1 LLM Layer: `GroqLLMProvider` & Resilient Routing

#### Protocol Conformance
Triển khai `LLMProviderProtocol` (`VocabCraftApp/Domain/Protocols/LLMProviderProtocol.swift`):
```swift
public final class GroqLLMProvider: LLMProviderProtocol, Sendable {
    public let providerIdentifier: String = "groq-llama"
    private let apiKey: String
    private let session: URLSession
    private let model: String // Default: "llama-3.3-70b-versatile"
    ...
}
```

#### API Specification
* **Endpoint:** `POST https://api.groq.com/openai/v1/chat/completions`
* **Headers:**
  * `Authorization: Bearer <groqApiKey>`
  * `Content-Type: application/json`
* **Payload Structure:**
  * `model`: `llama-3.3-70b-versatile` (ưu tiên) hoặc `llama-3.1-8b-instant`.
  * `temperature`: `0.7`
  * `response_format`: `{ "type": "json_object" }`
  * `messages`: System prompt mô tả kịch bản Role Play và lịch sử hội thoại.

#### Resilient LLM Router (`ResilientLLMProviderRouter`)
* Khi `sendStructuredMessage` được gọi:
  1. Nếu có `groqApiKey`: gọi `GroqLLMProvider`.
  2. Nếu Groq trả về lỗi (429 / 5xx / timeout) hoặc không có key: thử `GeminiLLMProvider` (nếu có `geminiApiKey`).
  3. Nếu cả hai thất bại: chuyển sang `IntelligentMockLLMProvider` sinh câu trả lời cục bộ có ý nghĩa ngữ cảnh, không làm crash hay đứt cuộc gọi.

#### Settings & Persistence
* Mở rộng `UserSettingsStore`:
  * Bổ sung thuộc tính `groqApiKey: String` lưu an toàn qua Keychain / UserDefaults.
  * Thêm cờ `isGroqApiKeyConfigured: Bool`.
* Cập nhật `SettingsView` và `AIConfigSheet`:
  * Thêm ô nhập Groq API Key, hướng dẫn nhận key miễn phí tại Groq Console (`console.groq.com`).
  * Huy hiệu trạng thái kết nối (`Active (Groq Llama 3.3)` / `Fallback Gemini` / `Mock Mode`).

---

### 3.2 On-Device Voice Synthesis: `KokoroTTSEngine`

#### Model & Specifications
* **Mô hình:** Kokoro-82M (82 triệu tham số, style-based neural TTS).
* **Định dạng âm thanh xuất ra:** 24kHz 16-bit Mono PCM $\rightarrow$ chuyển đổi sang WAV container bằng thuật toán `pcmToWav`.
* **Kích thước lưu trữ:** ~120–150MB (gồm weights, config và style vectors).

#### Voice Persona Mapping
Ánh xạ các `VoicePersona` hiện có sang voice profiles của Kokoro:
| `VoicePersona` | Persona thực tế | Kokoro Voice ID |
| :--- | :--- | :--- |
| `.friendlyFemale` | Nữ thân thiện, ấm áp | `af_bella` |
| `.friendlyMale` | Nam trẻ trung, dễ gần | `am_adam` |
| `.authoritativeMale` | Nam chững chạc, phát âm chuẩn | `am_michael` |
| `.empatheticFemale` | Nữ truyền cảm, nhẹ nhàng | `af_sarah` |

#### Router Integration trong `TextToSpeechService`
```swift
switch context {
case .conversation(let persona, let locale):
    if kokoroEngine.isReady {
        lastActiveEngine = .kokoro
        try await kokoroEngine.synthesizeAndPlay(text: text, persona: persona)
    } else {
        lastActiveEngine = .apple
        await appleEngine.speakAsync(text: text, rate: rate, locale: locale)
    }
case .pronunciation:
    lastActiveEngine = .apple
    await appleEngine.speakAsync(text: text, rate: rate, locale: locale)
}
```

---

### 3.3 On-Device Speech Recognition: `WhisperKitSpeechEngine`

#### Model & Architecture
* **Framework:** `WhisperKit` từ Argmax (Core ML + Apple Neural Engine).
* **Mô hình mục tiêu:** `openai_whisper-tiny.en` (~40MB).
* **Đầu vào âm thanh:** 16kHz PCM Audio Buffer từ `AudioBufferRelay`.
* **Chiến lược xử lý (Streaming & VAD):**
  * `AudioBufferRelay` chuyển tiếp buffer âm thanh liên tục tới bộ đệm của WhisperKit.
  * Khi `SilenceDetector` kích hoạt sự kiện ngắt câu (người dùng ngừng nói sau ngưỡng cấu hình ~750ms), WhisperKit hoàn tất suy luận câu thoại (transcription).
  * Chuỗi văn bản được gửi tới `ReflexSpeechMatcher.isReflexMatch` và `FuzzySpeechMatcher` để tính điểm từ vựng mục tiêu.

#### Resilient Recognition Router
* Trong `ResilientConversationSpeechEngine`:
  * Nếu `whisperEngine.isReady`: Sử dụng WhisperKit Engine.
  * Nếu chưa sẵn sàng: Sử dụng pipeline `SFSpeechAudioBufferRecognitionRequest` của iOS như hiện tại.

---

### 3.4 Model Lifecycle & Quản lý Tài nguyên (`OnDemandAIModelManager`)

#### Vị trí Lưu trữ
* **Đường dẫn:** `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("VocabCraft/AIModels")`.
* **Cấu hình sao lưu:** Đánh dấu `URLResourceValues.isExcludedFromBackup = true` để tuân thủ chính sách App Store (không sao lưu file có thể tải lại vào iCloud).

#### Trạng thái Tải (`AIModelDownloadState`)
```swift
public enum AIModelDownloadState: Sendable, Equatable {
    case notDownloaded
    case downloading(progress: Double) // 0.0 ... 1.0
    case ready
    case error(String)
}
```

#### Giao diện Người dùng (UI/UX)
1. **Roleplay Upgrade Card (Tại `RoleplayRoomView` / `RoleplayVoiceCallView`):**
   * Banner phong cách `CraftCard` giới thiệu gói AI giọng nói tự nhiên.
   * Tiến trình tải hiển thị bằng `CraftProgressBar`.
   * Nút **"Để sau"**: Cho phép người dùng bắt đầu luyện tập ngay với Apple Engine mà không phải chờ.
2. **Khu vực Quản lý Bộ nhớ (Tại `SettingsView`):**
   * Hiển thị kích thước thực tế của từng mô hình trên ổ đĩa.
   * Nút **"Xóa mô hình" (Free up storage)** với dialog xác nhận chuẩn `CraftDialog` để giải phóng dung lượng.

---

## 4. Error Handling & Resilience Matrix

| Kịch bản sự cố | Hành vi xử lý của hệ thống | Trải nghiệm người dùng |
| :--- | :--- | :--- |
| **Groq API trả về 429 hoặc timeout** | Router tự động gọi `GeminiLLMProvider`. Nếu tiếp tục lỗi, gọi `IntelligentMockLLMProvider`. | Cuộc trò chuyện diễn ra bình thường, độ trễ tăng nhẹ (~1s). |
| **Chưa có Groq API Key** | Router dùng Gemini API Key (nếu có) hoặc Mock Provider. | Người dùng vẫn trải nghiệm được kịch bản mẫu. |
| **Model Kokoro chưa tải xong** | `TextToSpeechService` phát giọng qua `AppleEnhancedTTSEngine`. | Không có tiếng im lặng; giọng nói vẫn phát ra bằng AVSpeech tuyển chọn. |
| **Model WhisperKit chưa tải xong** | Nhận diện giọng nói qua `SFSpeechRecognizer` mặc định. | Luyện nói hoạt động bình thường ngay từ giây đầu tiên. |
| **Mất kết nối mạng khi đang tải model** | `URLSessionDownloadTask` tạm dừng hoặc báo lỗi nhẹ; hỗ trợ tải tiếp khi có mạng. | Nút "Thử lại", không gián đoạn app. |
| **Cuộc gọi điện thoại đến / Siri ngắt** | `AudioSessionCoordinator` bắt sự kiện `.interruptionBegan`, tạm dừng TTS/STT và phục hồi khi kết thúc. | Âm thanh sạch sẽ, không méo tiếng hay treo mic. |

---

## 5. Quality Gate & Testing Strategy

### 5.1 Unit Tests
* `GroqLLMProviderTests`:
  * Kiểm thử khởi tạo thiếu API Key $\rightarrow$ throw / fallback.
  * Kiểm thử decode JSON hợp lệ của `RoleplayTurnOutput`.
  * Kiểm thử fallback sang Gemini khi Groq trả về HTTP 429 / 500.
* `OnDemandAIModelManagerTests`:
  * Kiểm thử chuyển đổi trạng thái tải (`notDownloaded` $\rightarrow$ `downloading` $\rightarrow$ `ready`).
  * Kiểm thử xóa file model và xác nhận `FileManager` đã giải phóng dung lượng.
* `SmartVoiceRouterTests` & `TextToSpeechServiceTests`:
  * Kiểm thử ưu tiên `KokoroTTSEngine` khi ready, và fallback sang `AppleEnhancedTTSEngine`.
* `SpeechRecognitionServiceTests`:
  * Kiểm thử streaming buffer và chuyển đổi giữa WhisperKit và Apple Speech.

### 5.2 Localization (Bản địa hóa 100% EN & VI)
* Bổ sung đầy đủ chuỗi bản dịch song ngữ vào `VocabCraftApp/Resources/Localizable.xcstrings`:
  * `app.settings.ai_groq_key_title`
  * `app.settings.ai_groq_key_placeholder`
  * `app.settings.ai_models_section_title`
  * `app.settings.ai_models_kokoro_title`
  * `app.settings.ai_models_whisper_title`
  * `app.settings.ai_models_delete_button`
  * `app.roleplay.ai_model_download_banner_title`
  * `app.roleplay.ai_model_download_banner_desc`
  * `app.roleplay.ai_model_download_action`
* Chạy kiểm thử: `swift test --filter LocalizationTests`.

### 5.3 Xcode Build & Lint Compliance
* 0 Compiler Warnings.
* 0 SwiftLint Warnings/Errors.
* 100% Test Pass Rate.
