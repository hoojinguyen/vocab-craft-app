# VocabCraft — Natural Voice System Upgrade (Design Spec)

- **Date:** 2026-10-05
- **Status:** Approved by Human Partner
- **Scope:** Architectural upgrade of the voice and Text-to-Speech subsystem across VocabCraft (`TextToSpeechService`, `AppleVoiceSelector`, `AppleEnhancedTTSEngine`, `GeminiAudioSpeechEngine`, `RoleplayVoiceCallViewModel`, `TurnBasedVoiceConversationEngine`).

---

## 1. Executive Summary & Problem Statement

### 1.1 The Current Problem
Hiện tại, VocabCraft sử dụng `AVSpeechSynthesizer` cơ bản trong `TextToSpeechService` với phương thức `AVSpeechSynthesisVoice(language: locale)`. Điều này dẫn đến các hạn chế nghiêm trọng về trải nghiệm người dùng:
1. **Âm thanh máy móc, phẳng lặng (Robotic & Monotone):** Hệ điều hành mặc định trả về giọng compact cơ bản (chẳng hạn như Samantha compact hoặc Apple Eloquence), không có ngữ điệu tự nhiên, cao độ phẳng lì.
2. **Thiếu cảm xúc trong đàm thoại AI (AI Roleplay):** Trong cuộc gọi thoại nhập vai (`RoleplayVoiceCallView`), nhân vật AI phát âm bằng giọng đọc hệ thống khô khan, triệt tiêu tính nhập vai và cảm giác trò chuyện với người bản xứ.
3. **Chưa tận dụng tài nguyên sẵn có:** App đã tích hợp `GeminiLLMProvider` và lưu `geminiApiKey` trong `SettingsStore`, nhưng chưa khai thác năng lực tạo giọng nói sinh động (Generative Audio / Speech Config) của Gemini.

### 1.2 The Solution: Smart Hybrid Routing Architecture
Nâng cấp toàn diện hệ thống âm thanh theo mô hình **Smart Hybrid Routing (0 đồng chi phí)**:
- **Tầng On-Device (Học từ vựng Flashcard, Vocabulary Vault, Luyện phản xạ Reflex):** Sử dụng `AppleEnhancedTTSEngine` với thuật toán tự động quét và kích hoạt giọng chất lượng cao nhất trên thiết bị (`.premium` > `.enhanced` > danh sách giọng compact tuyển chọn), kết hợp tinh chỉnh ngữ điệu (prosody tuning: pitch, rate, delays). Chạy 100% offline, 0ms latency, không tốn token.
- **Tầng Cloud AI (Cuộc gọi nhập vai AI Roleplay):** Tận dụng trực tiếp `geminiApiKey` để kích hoạt `GeminiAudioSpeechEngine` với các giọng đọc truyền cảm, có hơi thở và ngữ điệu tự nhiên (`Aoede`, `Puck`, `Charon`, `Fenrir`).
- **Resilient Fallback:** Tự động chuyển đổi tức thì về Apple On-Device TTS khi mất mạng, timeout, hoặc chưa cấu hình API key.

---

## 2. Architecture & Component Hierarchy

```
                            ┌─────────────────────────────────┐
                            │      TextToSpeechProtocol       │
                            └────────────────┬────────────────┘
                                             │
                            ┌────────────────▼────────────────┐
                            │       TextToSpeechService       │
                            │       (Smart Voice Router)      │
                            └───────┬─────────────────┬───────┘
                                    │                 │
     [Pronunciation / Offline /     │                 │  [Conversation Context +
      Fallback Context]             │                 │   Gemini Key Configured]
                                    ▼                 ▼
             ┌────────────────────────────┐    ┌────────────────────────────┐
             │   AppleEnhancedTTSEngine   │    │  GeminiAudioSpeechEngine   │
             │  • AppleVoiceSelector      │    │  • Gemini Audio REST API   │
             │  • Whitelist & Blacklist   │    │  • Persona Voice Mapping   │
             │  • Prosody Tuning          │    │  • In-Memory Audio Cache   │
             │  • AVSpeechSynthesizer     │    │  • AVAudioPlayer           │
             └──────────────┬─────────────┘    └──────────────┬─────────────┘
                            │                                 │
                            └────────────────┬────────────────┘
                                             │ [AudioSessionLease]
                                             ▼
                            ┌─────────────────────────────────┐
                            │    AudioSessionCoordinator      │
                            └─────────────────────────────────┘
```

### 2.1 Core Components

#### 1. `SpeechContext` (Domain Layer)
Mô hình hóa ngữ cảnh phát âm để router đưa ra quyết định chính xác:
```swift
public enum SpeechContext: Sendable, Equatable {
    /// Phát âm từ vựng, định nghĩa hoặc câu mẫu đơn lẻ (ưu tiên độ nhanh, chuẩn xác).
    case pronunciation(locale: String = "en-US")
    
    /// Đàm thoại nhập vai với nhân vật AI (ưu tiên biểu cảm tự nhiên, ngữ điệu người thật).
    case conversation(persona: VoicePersona, locale: String = "en-US")
}

public enum VoicePersona: String, Sendable, Codable {
    case friendlyFemale = "Aoede"     // Ấm áp, thân thiện, truyền cảm
    case friendlyMale = "Puck"         // Năng động, cởi mở, tự nhiên
    case authoritativeMale = "Charon"  // Trầm ấm, trang trọng, bản lĩnh
    case expressiveFemale = "Kore"     // Tươi vui, hoạt bát
}
```

#### 2. `AppleVoiceSelector` (Core / Audio)
Thuật toán lựa chọn giọng nói on-device tối ưu:
- **Data Source:** Truy vấn `AVSpeechSynthesisVoice.speechVoices()`.
- **Filtering & Scoring:**
  1. Lọc theo ngôn ngữ mục tiêu (mặc định prefix `en`).
  2. Ưu tiên 1: `voice.quality == .premium` (nếu người dùng đã tải Siri Neural / Premium voices).
  3. Ưu tiên 2: `voice.quality == .enhanced` (gói giọng nâng cao của Apple).
  4. Ưu tiên 3: Tuyển chọn từ danh sách trắng (Curated Whitelist): `Ava`, `Zoe`, `Allison`, `Samantha`, `Nathan`, `Tom`, `Oliver`, `Serena`.
  5. Loại trừ triệt để (Blacklist): `Albert`, `Bad News`, `Bahh`, `Bells`, `Boing`, `Bubbles`, `Cellos`, `Deranged`, `Fred`, `Eddy`, `Grandpa`, `Organ`, `Trinoids`, `Whisper`, `Zarvox` (các giọng biến dạng/hoạt hình Eloquence).
- **Concurrency & Caching:** Lưu cache kết quả theo locale với `NSLock` thread-safe.

#### 3. `AppleEnhancedTTSEngine` (Core / Audio)
- **Prosody Tuning (Tinh chỉnh ngữ điệu):**
  - `pitchMultiplier`: Cấu hình trong dải `1.05 - 1.07` (nâng nhẹ âm sắc giúp giọng đọc ấm áp, vui tươi, tránh trầm đục).
  - `rate`: Điều chỉnh dải `0.48 - 0.50` phù hợp cho người học tiếng Anh.
  - `preUtteranceDelay`: `0.05s` (tránh nuốt âm tiết đầu).
  - `postUtteranceDelay`: `0.10s` (tạo khoảng nghỉ sau câu).
- Quản lý `AVSpeechSynthesizerDelegate` và resume continuation an toàn.

#### 4. `GeminiAudioSpeechEngine` (Core / Audio)
- **API Request:** Gửi request đến Gemini API (`gemini-2.5-flash` hoặc endpoint speech tương thích) với `responseModalities: ["AUDIO"]` và `speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: persona.rawValue } } }`.
- **Audio Decoding & Playback:** Giải mã audio payload (WAV/PCM base64) và phát qua `AVAudioPlayer`.
- **Audio Lease:** Yêu cầu lease `.playback` từ `AudioSessionCoordinator` trước khi phát và giải phóng khi kết thúc.
- **In-Memory Cache:** Cache các đoạn audio theo khóa `hash(text + persona)` để phát lại tức thì khi người dùng bấm Replay.

#### 5. `TextToSpeechService` (Smart Voice Router)
- Kế thừa và tuân thủ `TextToSpeechProtocol`.
- Inject `AudioSessionCoordinator`, `SettingsStore` (để kiểm tra `isGeminiApiKeyConfigured`), `AppleEnhancedTTSEngine`, và `GeminiAudioSpeechEngine`.
- **Routing Decision:**
  - Nếu ngữ cảnh là `.conversation` VÀ `settingsStore.isGeminiApiKeyConfigured == true`: Ủy quyền cho `GeminiAudioSpeechEngine`.
  - Nếu gặp lỗi (network timeout > 3.5s, 429 quota, kết nối offline) hoặc ngữ cảnh là `.pronunciation`: Ủy quyền ngay cho `AppleEnhancedTTSEngine`.

---

## 3. Data Flow & Sequence Diagrams

### 3.1 Vocabulary & Flashcard Pronunciation Flow
```
[User taps Speaker Icon]
         │
         ▼
[TextToSpeechService.speak(text, context: .pronunciation)]
         │
         ▼
[AppleVoiceSelector.resolveBestVoice(for: "en-US")]
         │ (Returns Premium/Enhanced or Curated White-list Voice)
         ▼
[AudioSessionCoordinator.acquire(.playback)]
         │
         ▼
[AVSpeechSynthesizer.speak(utterance with pitch: 1.06, rate: 0.49)]
         │
         ▼
[Audio playback completes ──► AudioSessionCoordinator.release(lease)]
```

### 3.2 AI Roleplay Voice Call Flow (with Resilient Failover)
```
[TurnBasedVoiceConversationEngine: playCharacterSpeech(text)]
         │
         ▼
[TextToSpeechService.speakAsync(text, context: .conversation(persona))]
         │
         ├───► [Check: isGeminiApiKeyConfigured?]
         │        ├── Yes ──► Send request to Gemini Audio API
         │        │              │
         │        │              ├── Success: Play audio via AVAudioPlayer
         │        │              └── Timeout / Error: Fallback to AppleEnhancedTTSEngine
         │        │
         │        └── No  ──► Direct playback via AppleEnhancedTTSEngine
         ▼
[Playback finished ──► release lease ──► TurnBasedVoiceConversationEngine starts listening]
```

---

## 4. Audio Session & Concurrency Safety

1. **Serialized Lease Management:** Mọi thao tác phát âm thanh qua loa (dù từ `AVSpeechSynthesizer` hay `AVAudioPlayer`) đều phải thông qua `AudioSessionCoordinator.acquire(.playback)`.
2. **Smooth Turn Transitions:** Khi AI dứt lời hoặc khi người dùng ngắt lời:
   - Hủy ngay task phát âm thanh đang chạy (`stop()`).
   - Ngừng synthesizer/player lập tức.
   - Trả lease `.playback` an toàn để chuyển sang lease `.record` cho microphone nhận diện giọng nói mà không gây crash `AVAudioEngine`.
3. **Task Cancellation & Swift 6 Sendable:** Mọi lớp engine và data structure đều tuân thủ `Sendable` và `@MainActor` theo đúng chuẩn kiến trúc hiện hành của dự án.

---

## 5. Localization & String Policy

Tuân thủ nghiêm ngặt **Layer 2 Localization (`app.*`)**:
- Không hardcode bất kỳ chuỗi thông báo, log hay nhãn trạng thái nào.
- Thêm các key định danh bổ sung vào `VocabCraftApp/Resources/Localizable.xcstrings`:
  - `app.audio.voice_quality_premium`: "Chất lượng giọng nói chuẩn Studio" / "Studio Quality Voice"
  - `app.audio.voice_quality_enhanced`: "Giọng nói tự nhiên nâng cao" / "Enhanced Natural Voice"
  - `app.audio.voice_quality_standard`: "Giọng nói tiêu chuẩn" / "Standard Voice"
  - `app.audio.fallback_notice`: "Đang chuyển sang giọng đọc ngoại tuyến" / "Switched to offline voice"

---

## 6. Testing Strategy & Quality Gate

### 6.1 Unit Tests
- `AppleVoiceSelectorTests`:
  - Kiểm tra ưu tiên: Premium > Enhanced > Whitelist Compact.
  - Kiểm tra loại trừ triệt để: Đảm bảo không có giọng trong blacklist được trả về.
  - Kiểm tra tính thread-safe của cache khi gọi đồng thời từ nhiều Task.
- `AppleEnhancedTTSEngineTests`:
  - Kiểm tra gán đúng tham số `pitchMultiplier`, `rate`, `preUtteranceDelay`.
- `GeminiAudioSpeechEngineTests`:
  - Kiểm tra tạo URLRequest đúng header, auth bearer, và payload JSON.
  - Kiểm tra giải mã audio data và in-memory cache hit/miss.
- `TextToSpeechServiceRoutingTests`:
  - Test routing khi có API key $\to$ gọi Gemini.
  - Test failover khi Gemini ném lỗi $\to$ chuyển ngay sang Apple TTS mà không throw crash.
  - Test lease lifecycle với `MockAudioSessionCoordinator`.

### 6.2 Quality Standards Checklist
- [x] 100% test pass trong test suite.
- [x] 0 lỗi biên dịch, 0 cảnh báo (0 compiler warnings).
- [x] SwiftLint 0 violation.
- [x] Đầy đủ song ngữ EN & VI trong `Localizable.xcstrings`.
