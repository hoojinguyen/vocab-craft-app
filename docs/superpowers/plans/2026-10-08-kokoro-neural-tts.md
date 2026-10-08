# Kokoro Neural TTS On-Device Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the Offline AI Pack with authentic on-device Kokoro-82M Neural TTS via `sherpa-onnx`, delivering studio-grade 24kHz expressive speech for Nova (`af_bella`) and Orion (`am_adam`) with zero robot fallback.

**Architecture:** Integrate the `sherpa-onnx` static iOS library via SPM. On-demand model bundle (~85MB) downloaded and unpacked into `Application Support/VocabCraft/AIModels/kokoro/` with `.isExcludedFromBackup = true`. Neural inference runs inside a background actor `KokoroInferenceWorker` to eliminate UI hitches, outputting 24kHz PCM samples played via `AVAudioPlayer` under `KokoroTTSEngine` with strict typed error handling and zero silent fallbacks.

**Tech Stack:** Swift 6 Concurrency (Actors, Sendable), `sherpa-onnx` (ONNX Runtime, Metal/CPU, espeak-ng-data G2P), AVFoundation (`AVAudioPlayer`, `AVAudioSession`), SwiftUI & CraftUIKit design tokens.

**Spec:** [`docs/superpowers/specs/2026-10-08-kokoro-neural-tts-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-10-08-kokoro-neural-tts-design.md)

## Global Constraints

- Zero Hardcoded Strings: All user-facing text must be declared in `VocabCraftApp/Resources/Localizable.xcstrings` under `app.*` with 100% bilingual parity (`en` and `vi`), `extractionState: "manual"`, `state: "translated"`.
- CraftUIKit-First: UI changes strictly use `CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, and `CraftUIKit` components. Zero raw styling.
- Zero Silent Fallbacks: If Kokoro model is missing or fails, throw `AIPackError` directly; never silently downgrade to `AVSpeechSynthesizer` or mock voices.
- Quality Gates: Zero compiler warnings, zero SwiftLint violations, 100% unit tests pass across `VocabCraftAppTests` and `CraftUIKit`.

---

### Task 1: `OnDemandAIModelManager` Archive Extraction & Model Integrity

**Files:**
- Modify: `VocabCraftApp/Core/Audio/OnDemandAIModelManager.swift`
- Create: `VocabCraftAppTests/Audio/OnDemandAIModelManagerTests.swift`

**Interfaces:**
- Consumes: `AIModelType.kokoro`, `AIModelDownloadState`, `modelsDirectory: URL`
- Produces:
  - `OnDemandAIModelManager.isModelReady(.kokoro) -> Bool` checking 4 files (`model.onnx`, `voices.bin`, `tokens.txt`, `espeak-ng-data`)
  - `OnDemandAIModelManager.extractArchive(at:to:) throws` for unzipping or expanding `.tar.bz2`/`.zip` model archives
  - Remote URL updated to official compressed Kokoro ONNX model archive (`kokoro-en-v0_19-ios.tar.bz2`)

- [ ] **Step 1: Write failing test for Kokoro model integrity and archive extraction**

```swift
// VocabCraftAppTests/Audio/OnDemandAIModelManagerTests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("OnDemandAIModelManager Tests")
struct OnDemandAIModelManagerTests {
    @Test("isModelReady returns false when required Kokoro files are missing")
    @MainActor
    func testModelNotReadyWhenFilesMissing() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        #expect(!manager.isModelReady(.kokoro))
    }

    @Test("isModelReady returns true only when all 4 Kokoro files exist")
    @MainActor
    func testModelReadyWhenAllFilesExist() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let kokoroDir = tempDir.appendingPathComponent("kokoro")
        try FileManager.default.createDirectory(at: kokoroDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let required = ["model.onnx", "voices.bin", "tokens.txt", "espeak-ng-data"]
        for file in required {
            let path = kokoroDir.appendingPathComponent(file)
            if file == "espeak-ng-data" {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
            } else {
                try "dummy".write(to: path, atomically: true, encoding: .utf8)
            }
        }

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        #expect(manager.isModelReady(.kokoro))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/OnDemandAIModelManagerTests`
Expected: FAIL (because `isModelReady` checks `contents.isEmpty` without checking specific 4 files).

- [ ] **Step 3: Implement 4-file integrity check & archive unpacking in `OnDemandAIModelManager`**

Modify `VocabCraftApp/Core/Audio/OnDemandAIModelManager.swift`:
Update `isModelReady`:
```swift
    public func isModelReady(_ type: AIModelType) -> Bool {
        let dir = modelURL(for: type)
        switch type {
        case .kokoro:
            let requiredFiles = ["model.onnx", "voices.bin", "tokens.txt", "espeak-ng-data"]
            let isComplete = requiredFiles.allSatisfy {
                FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path)
            }
            if isComplete {
                if kokoroState != .ready { updateState(.ready, for: .kokoro) }
                return true
            }
            return false
        case .whisper:
            if FileManager.default.fileExists(atPath: dir.path),
               let contents = try? FileManager.default.contentsOfDirectory(atPath: dir.path),
               !contents.isEmpty {
                if whisperState != .ready { updateState(.ready, for: .whisper) }
                return true
            }
            return false
        }
    }
```
Add extraction support in `urlSession(_:downloadTask:didFinishDownloadingTo:)` to unpack archive files into `dest` directory.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/OnDemandAIModelManagerTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/OnDemandAIModelManager.swift VocabCraftAppTests/Audio/OnDemandAIModelManagerTests.swift
git commit -m "feat(audio): add 4-file integrity validation and archive handling to OnDemandAIModelManager"
```

---

### Task 2: Background `KokoroInferenceWorker` & Real `KokoroTTSEngine`

**Files:**
- Create: `VocabCraftApp/Core/Audio/KokoroInferenceWorker.swift`
- Modify: `VocabCraftApp/Core/Audio/KokoroTTSEngine.swift`
- Create: `VocabCraftAppTests/Audio/KokoroTTSEngineTests.swift`

**Interfaces:**
- Consumes: `SherpaOnnxOfflineTtsWrapper`, `OnDemandAIModelManager`, `VoicePersona`
- Produces:
  - `KokoroInferenceWorker`: `generateSamples(text: String, speakerId: Int, speed: Float) async throws -> [Float]`
  - `KokoroTTSEngine`: `synthesizeAndPlay(text: String, persona: VoicePersona) async throws` using background inference and 24kHz `AVAudioPlayer` playback
  - Persona to Speaker mapping:
    - `.friendlyFemale` $\rightarrow$ `af_bella` (speaker id for Nova)
    - `.friendlyMale` $\rightarrow$ `am_adam` (speaker id for Orion)
    - `.expressiveFemale` $\rightarrow$ `af_sarah` (speaker id for Sarah)
    - `.authoritativeMale` $\rightarrow$ `am_michael` (speaker id for Michael)

- [ ] **Step 1: Write failing test for `KokoroTTSEngine` persona mapping and synthesis protocol**

```swift
// VocabCraftAppTests/Audio/KokoroTTSEngineTests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("KokoroTTSEngine Tests")
struct KokoroTTSEngineTests {
    @Test("Voice profile mapping maps personas to valid Kokoro speaker names")
    @MainActor
    func testVoiceProfileMapping() {
        let engine = KokoroTTSEngine()
        #expect(engine.voiceProfile(for: .friendlyFemale) == "af_bella")
        #expect(engine.voiceProfile(for: .friendlyMale) == "am_adam")
        #expect(engine.voiceProfile(for: .expressiveFemale) == "af_sarah")
        #expect(engine.voiceProfile(for: .authoritativeMale) == "am_michael")
    }

    @Test("synthesizeAndPlay throws when model is not ready")
    @MainActor
    func testSynthesizeThrowsWhenNotReady() async {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        let engine = KokoroTTSEngine(modelManager: manager)

        #expect(!engine.isReady)
        await #expect(throws: Error.self) {
            try await engine.synthesizeAndPlay(text: "Hello", persona: .friendlyFemale)
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/KokoroTTSEngineTests`
Expected: FAIL (because existing `KokoroTTSEngine` delegates to `appleEngine.speakAsync` without throwing when `isReady == false`).

- [ ] **Step 3: Implement `KokoroInferenceWorker` and update `KokoroTTSEngine`**

Create `VocabCraftApp/Core/Audio/KokoroInferenceWorker.swift`:
- Background actor wrapping `sherpa-onnx` initialization and sample generation.
- Generates 24,000Hz PCM `[Float]` samples off `@MainActor`.
- Converts raw PCM samples to standard 24kHz 16-bit WAV header `Data`.

Update `VocabCraftApp/Core/Audio/KokoroTTSEngine.swift`:
- Checks `guard isReady else { throw AIPackError.downloadRequired(...) }`.
- Calls `worker.generateAudioData(...)`.
- Plays audio data via `AVAudioPlayer` with delegate tracking `isSpeaking`.
- `stop()` halts audio player and cancels active continuation immediately.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/KokoroTTSEngineTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/KokoroInferenceWorker.swift VocabCraftApp/Core/Audio/KokoroTTSEngine.swift VocabCraftAppTests/Audio/KokoroTTSEngineTests.swift
git commit -m "feat(audio): implement background KokoroInferenceWorker and WAV playback in KokoroTTSEngine"
```

---

### Task 3: `KokoroTTSEngineAdapter`, `OfflineAIPack` Voices & Zero Silent Fallback

**Files:**
- Modify: `VocabCraftApp/Data/Audio/Engines/KokoroTTSEngineAdapter.swift`
- Modify: `VocabCraftApp/Data/AIPacks/OfflineAIPack.swift`
- Modify: `VocabCraftAppTests/AI/ConcreteAIPackTests.swift`

**Interfaces:**
- Consumes: `KokoroTTSEngine`, `TTSEngineProtocol`, `VoiceConfiguration`, `VoiceProfile`
- Produces:
  - `OfflineAIPack.supportedVoices` returning 4 neural profiles: Nova (`af_bella`), Orion (`am_adam`), Sarah (`af_sarah`), Michael (`am_michael`)
  - `KokoroTTSEngineAdapter` throws typed `AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")` when `isReady == false`
  - Throws `AIPackError.ttsFailed` on synthesis failure without silent fallback

- [ ] **Step 1: Write failing test in `ConcreteAIPackTests` for `OfflineAIPack` supported voices**

```swift
// In VocabCraftAppTests/AI/ConcreteAIPackTests.swift
@Test("OfflineAIPack provides Nova, Orion, Sarah, and Michael neural voices")
func testOfflineAIPackSupportedVoices() {
    let pack = OfflineAIPack(
        isKokoroReady: { true },
        isWhisperReady: { true }
    )
    let voices = pack.supportedVoices
    #expect(voices.count == 4)
    #expect(voices.contains(where: { $0.id == "kokoro-nova" && $0.voiceConfig.gender == .female }))
    #expect(voices.contains(where: { $0.id == "kokoro-orion" && $0.voiceConfig.gender == .male }))
    #expect(voices.contains(where: { $0.id == "kokoro-sarah" }))
    #expect(voices.contains(where: { $0.id == "kokoro-michael" }))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/ConcreteAIPackTests/testOfflineAIPackSupportedVoices`
Expected: FAIL (currently only 1 voice `kokoro-heart` exists in `OfflineAIPack.supportedVoices`).

- [ ] **Step 3: Update `OfflineAIPack.swift` and `KokoroTTSEngineAdapter.swift`**

In `VocabCraftApp/Data/AIPacks/OfflineAIPack.swift`:
- Update `supportedVoices` to return `kokoro-nova`, `kokoro-orion`, `kokoro-sarah`, and `kokoro-michael` profiles.
- Set `defaultVoice` to `supportedVoices[0]` (`kokoro-nova`).

In `VocabCraftApp/Data/Audio/Engines/KokoroTTSEngineAdapter.swift`:
- Ensure `synthesizeAndPlay` cleanly maps `VoiceConfiguration` or persona and calls `engine.synthesizeAndPlay`.
- Throws typed `AIPackError.downloadRequired` when `!isReady`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/ConcreteAIPackTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AIPacks/OfflineAIPack.swift VocabCraftApp/Data/Audio/Engines/KokoroTTSEngineAdapter.swift VocabCraftAppTests/AI/ConcreteAIPackTests.swift
git commit -m "feat(ai): expose Nova and Orion voices in OfflineAIPack with strict fail-fast error propagation"
```

---

### Task 4: Voice Preview UX Feedback & 100% Bilingual Localization

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/Components/RoleplayVoicePickerSheet.swift`
- Modify: `VocabCraftApp/Features/Settings/Views/SettingsView.swift`
- Modify: `VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift`

**Interfaces:**
- Consumes: `AppStrings.Settings`, `Localizable.xcstrings`, `OnDemandAIModelManager.shared.isModelReady(.kokoro)`
- Produces:
  - Localized strings: `app.settings.voice.preview_needs_download`, `app.settings.voice.preview_download_action`, `app.ai.model.kokoro_desc`
  - Inline prompt / feedback in `RoleplayVoicePickerSheet` when tapping play on un-downloaded Kokoro voice

- [ ] **Step 1: Write failing test for new localization keys**

```swift
// In VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift
@Test("Kokoro preview and model localization keys exist in both en and vi")
func testKokoroLocalizationKeys() throws {
    let keys = [
        "app.settings.voice.preview_needs_download",
        "app.settings.voice.preview_download_action",
        "app.ai.model.kokoro_title",
        "app.ai.model.kokoro_desc"
    ]
    for key in keys {
        #expect(hasTranslation(key: key, locale: "en"), "Missing English translation for \(key)")
        #expect(hasTranslation(key: key, locale: "vi"), "Missing Vietnamese translation for \(key)")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests/testKokoroLocalizationKeys`
Expected: FAIL.

- [ ] **Step 3: Add localization keys and update UI sheets**

1. In `VocabCraftApp/Resources/Localizable.xcstrings`:
   Add:
   - `app.settings.voice.preview_needs_download`: EN "Model download is required to preview this voice." / VI "Cần tải mô hình để nghe thử giọng nói này."
   - `app.settings.voice.preview_download_action`: EN "Download Model" / VI "Tải Mô Hình"
   - `app.ai.model.kokoro_title`: EN "Kokoro Neural Voice" / VI "Giọng Đọc Nơ-ron Kokoro"
   - `app.ai.model.kokoro_desc`: EN "Studio-quality on-device neural voice (85MB)" / VI "Giọng nói nơ-ron chất lượng cao trên thiết bị (85MB)"
2. In `VocabCraftApp/Core/Localization/AppStrings.swift`:
   Add typed constants under `AppStrings.Settings` and `AppStrings.AIModelDownload`.
3. In `RoleplayVoicePickerSheet.swift`:
   When `handlePreview` is tapped on a `.kokoroNeural` voice and `!modelManager.isModelReady(.kokoro)`, surface an alert or banner guiding the user to download the model instead of silently ignoring.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftApp/Features/AIAssistant/Views/Components/RoleplayVoicePickerSheet.swift VocabCraftApp/Features/Settings/Views/SettingsView.swift VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift
git commit -m "feat(ui): add download required preview alert and 100% bilingual localization for Kokoro voices"
```

---

### Task 5: End-to-End Verification, SwiftLint & Simulator Auditory Check

**Files:** None (verification task)

- [ ] **Step 1: Run complete unit test suite**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17"`
Expected: 100% tests pass.

- [ ] **Step 2: Run SwiftLint check**

Run: `swiftlint lint --strict`
Expected: 0 violations, 0 warnings.

- [ ] **Step 3: Run full compiler check**

Run: `xcodebuild clean build -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17"`
Expected: Build Succeeded with 0 errors, 0 warnings.

- [ ] **Step 4: Live Audio Simulator Verification**

Run app on Simulator, trigger voice preview of **Nova** and **Orion**, verify clean 24kHz audio playback.
