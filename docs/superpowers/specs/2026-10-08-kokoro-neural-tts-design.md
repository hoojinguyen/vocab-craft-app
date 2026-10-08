# Kokoro Neural TTS On-Device Integration — Design Specification

**Date:** 2026-10-08  
**Status:** Approved for Implementation Planning  
**Scope:** Phase 1 of Offline AI Pack Neural Upgrade — True on-device Neural TTS for Kokoro-82M (Nova & Orion voices)

---

## 1. Problem Statement & Motivation

In the VocabCraft AI subsystem, the **Offline AI Pack** promises a private, high-fidelity on-device voice experience. However:

| # | Current Issue | Root Cause | User Impact |
|---|---------------|------------|-------------|
| 1 | **Robot Apple Voice** | `KokoroTTSEngine.swift` delegates directly to `appleEngine.speakAsync` (`AVSpeechSynthesizer`) with pitch shifts (`1.08` / `0.88`). | Voices like **Nova** and **Orion** sound like generic iOS robot voices instead of human. |
| 2 | **Invalid Model Weights** | `OnDemandAIModelManager` pointed to `hexgrad/Kokoro-82M/kokoro-v0_19.pth` (raw PyTorch file, 327MB) saved as a flat binary without a mobile inference runtime. | PyTorch `.pth` files cannot be parsed or executed natively on iOS without LibTorch or ONNX/CoreML. |
| 3 | **Silent Preview Failure** | In `RoleplayVoicePickerSheet` and `SettingsView`, previewing Nova/Orion when Kokoro is not ready silently drops without user feedback. | Users cannot hear the voice preview and do not understand why it fails. |
| 4 | **Limited Profile Catalog in Pack** | `OfflineAIPack.supportedVoices` only exposed a single dummy `kokoro-heart` profile instead of the full set of personas (Nova, Orion, Sarah, Michael). | Inconsistent voice selection between settings and active pack. |

The objective of **Phase 1** is to replace the fallback mechanism with a real, high-performance **Kokoro-82M Neural TTS runtime** on iOS, delivering studio-grade 24kHz natural human speech.

---

## 2. Architectural Decisions & Selected Approach

### 2.1 Runtime Engine: `sherpa-onnx` (Static XCFramework)
We adopt **`sherpa-onnx`** (`k2-fsa/sherpa-onnx`), the production-grade C++/Metal ONNX speech processing library:
- **SPM Integration**: Linked via official Swift Package Manager dependency (`sherpa-onnx` target wrapping `SherpaOnnxIOS` and `onnxruntime-libs`).
- **Phonemizer & G2P**: Bundles native `espeak-ng-data` and `tokens.txt` within the model distribution. English text is converted directly into phonemes without Python or external process dependencies.
- **Latency & Performance**: Inference generates 24kHz raw PCM float samples in ~150–250ms on modern iPhone hardware using Metal/CPU acceleration.
- **Audio Output**: 24kHz mono audio delivered as PCM buffer or temporary in-memory WAV container for `AVAudioPlayer` / `AVAudioEngine`.

### 2.2 On-Demand Model Bundle Architecture
Rather than bloating the App Store `.ipa` bundle, Kokoro model assets are downloaded on-demand and unpacked into:
`Application Support/VocabCraft/AIModels/kokoro/`

The bundle contains 4 required files:
1. `model.onnx`: Kokoro-82M quantized neural graph (~85MB).
2. `voices.bin`: Vector style embeddings for all 54 Kokoro voices (~26MB).
3. `tokens.txt`: Phoneme token dictionary.
4. `espeak-ng-data/`: Pronunciation lexicon and G2P tables.

Total download size: **~85MB** compressed archive.

---

## 3. Detailed Component Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        VocabCraft UI Layer                             │
│  (AIAssistantHubView / RoleplayVoicePickerSheet / VoiceSettingsSheet)   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        TextToSpeechService                             │
│  (Manages AudioSessionLease, active pack engine routing, previewVoice)  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     KokoroTTSEngineAdapter                             │
│       (Conforms to TTSEngineProtocol, throws typed AIPackError)        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        KokoroTTSEngine (@MainActor)                    │
│    - Coordinates playback via AVAudioPlayer / AVAudioEngine            │
│    - Manages isSpeaking state and stop() immediate cancellation        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼ async
┌────────────────────────────────────────────────────────────────────────┐
│                KokoroInferenceWorker (Background Actor)                │
│    - Instantiates SherpaOnnxOfflineTtsWrapper                          │
│    - Generates 24kHz PCM samples off main thread (zero UI hitch)       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ reads
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│              Application Support/VocabCraft/AIModels/kokoro/            │
│         [model.onnx | voices.bin | tokens.txt | espeak-ng-data/]        │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.1 `KokoroInferenceWorker` (Background Actor)
```swift
actor KokoroInferenceWorker {
    private var ttsWrapper: SherpaOnnxOfflineTtsWrapper?
    private var isInitialized: Bool = false

    func loadModel(from directory: URL) throws
    func generateAudio(text: String, speakerId: Int, speed: Float) throws -> [Float]
    func unload()
}
```
- **Thread Safety**: Runs entirely on a background cooperative thread pool. No ONNX or graph evaluation occurs on `@MainActor`.
- **Prewarming**: Loads weights on first use or upon pack activation; caches the initialized wrapper in memory.
- **Output**: Returns raw `[Float]` samples at 24,000 Hz.

### 3.2 `KokoroTTSEngine` (@MainActor Coordinator)
```swift
@MainActor
public final class KokoroTTSEngine: NSObject, AVAudioPlayerDelegate, KokoroAudioSynthesizing, @unchecked Sendable {
    public private(set) var isSpeaking: Bool = false
    public var isReady: Bool { modelManager.isModelReady(.kokoro) }

    private let worker: KokoroInferenceWorker
    private let modelManager: OnDemandAIModelManager
    private var audioPlayer: AVAudioPlayer?
    private var activeContinuation: CheckedContinuation<Void, Error>?

    public func synthesizeAndPlay(text: String, persona: VoicePersona) async throws
    public func synthesizeAndPlay(text: String, speaker: String) async throws
    public func stop()
}
```
- **Voice Mapping**:
  - `VoicePersona.friendlyFemale` / "Nova" $\rightarrow$ `af_bella`
  - `VoicePersona.friendlyMale` / "Orion" $\rightarrow$ `am_adam`
  - `VoicePersona.expressiveFemale` / "Sarah" $\rightarrow$ `af_sarah`
  - `VoicePersona.authoritativeMale` / "Michael" $\rightarrow$ `am_michael`
- **Audio Playback**: Encapsulates samples into a 24kHz mono WAV header in memory (`Data`) and plays using `AVAudioPlayer` for sample-accurate timing and background playback support.

### 3.3 `OnDemandAIModelManager` Enhancements
1. **Archive Download & Extraction**:
   - Download destination points to a secure temporary archive.
   - Automatically unzips/unpacks contents into `modelsDirectory/kokoro/`.
2. **Strict Integrity Check**:
   ```swift
   public func isModelReady(_ type: AIModelType) -> Bool {
       switch type {
       case .kokoro:
           let dir = modelURL(for: .kokoro)
           let req = ["model.onnx", "voices.bin", "tokens.txt", "espeak-ng-data"]
           return req.allSatisfy { FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path) }
       case .whisper:
           // ...
       }
   }
   ```
3. **Backup Exclusion**:
   - Explicitly marks directory with `isExcludedFromBackup = true` to preserve iCloud quotas.

---

## 4. Error Handling & Zero Silent Fallback

1. **Selection & Execution Fail-Fast**:
   - If `synthesizeAndPlay` is called when `isReady == false`, `KokoroTTSEngineAdapter` throws:
     `AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")`.
   - If inference fails (corrupted model, OOM), throws:
     `AIPackError.ttsFailed(packName: "Kokoro", underlyingMessage: error.localizedDescription)`.
   - **Zero Silent Fallback**: Under no circumstances will `KokoroTTSEngineAdapter` or `TextToSpeechService` silently fallback to `AVSpeechSynthesizer` or mock voices when the Offline Pack is selected.
2. **UI Error Surfacing**:
   - In `RoleplayVoicePickerSheet` and `SettingsView`: If user taps Play preview on Nova/Orion while not downloaded, a non-blocking prompt or alert informs the user: *"Download required to preview Kokoro Neural Voice"*.

---

## 5. Supported Voice Catalog in `OfflineAIPack`

`OfflineAIPack.supportedVoices` is updated to offer the 4 distinct neural personas:
```swift
public var supportedVoices: [VoiceProfile] {
    [
        VoiceProfile(
            id: "kokoro-nova",
            displayName: "Nova (Warm Female)",
            voiceConfig: VoiceConfiguration(gender: .female, style: .friendly),
            sampleText: "Hi! I'm Nova. I'm excited to practice English with you today!"
        ),
        VoiceProfile(
            id: "kokoro-orion",
            displayName: "Orion (Natural Male)",
            voiceConfig: VoiceConfiguration(gender: .male, style: .friendly),
            sampleText: "Hello, I'm Orion. Let's practice speaking and build your confidence."
        ),
        VoiceProfile(
            id: "kokoro-sarah",
            displayName: "Sarah (Expressive Female)",
            voiceConfig: VoiceConfiguration(gender: .female, style: .expressive),
            sampleText: "Hey there! Ready to jump into our roleplay conversation?"
        ),
        VoiceProfile(
            id: "kokoro-michael",
            displayName: "Michael (Authoritative Male)",
            voiceConfig: VoiceConfiguration(gender: .male, style: .authoritative),
            sampleText: "Good day. Let us focus on mastering new vocabulary today."
        )
    ]
}
```

---

## 6. Localization & Design System Compliance

### 6.1 Localization Keys (`Localizable.xcstrings`)
Strict adherence to `AGENTS.md`: 100% bilingual parity (EN & VI), `extractionState: "manual"`, `state: "translated"`.

| Key | English (en) | Vietnamese (vi) |
|-----|--------------|-----------------|
| `app.ai.model.kokoro_title` | Kokoro Neural Voice | Giọng Đọc Nơ-ron Kokoro |
| `app.ai.model.kokoro_desc` | Studio-quality on-device neural voice (85MB) | Giọng nói nơ-ron chất lượng cao trên thiết bị (85MB) |
| `app.settings.voice.preview_needs_download` | Model download is required to preview this voice. | Cần tải mô hình để nghe thử giọng nói này. |
| `app.settings.voice.preview_download_action` | Download Model | Tải Mô Hình |

### 6.2 CraftUIKit Compliance
All UI controls (download bars, badges, buttons, alerts) strictly utilize:
- Tokens: `CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`.
- Components: `CraftCard`, `CraftButton`, `CraftProgressBar`, `CraftIcon`, `CraftIconButton`.
- Zero raw styling (`Color.red`, hardcoded padding, custom fonts).

---

## 7. Verification & Quality Gates

1. **Unit Tests**:
   - `KokoroTTSEngineTests`: Speaker mapping, readiness status validation, playback lifecycle, cancellation.
   - `OnDemandAIModelManagerTests`: Extraction, archive verification, deletion, `.isExcludedFromBackup`.
   - `KokoroTTSEngineAdapterTests`: Fail-fast typed error propagation without fallbacks.
   - `AIAssistantLocalizationTests`: Complete bilingual parity check for all newly introduced keys.
2. **Quality Standards**:
   - 0 compiler warnings.
   - 0 SwiftLint violations.
   - 100% test pass rate across app and `CraftUIKit`.
3. **Simulator & Audio Verification**:
   - Audio playback verified in iPhone 17 Simulator.
   - Auditory confirmation that Nova (`af_bella`) and Orion (`am_adam`) produce studio-quality 24kHz expressive speech instead of the Apple synthesizer.
