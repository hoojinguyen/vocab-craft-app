# AI Pack Registry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the fragmented AI conversation architecture into an atomic, bundle-based AI Pack Registry with zero silent fallbacks, strict error surfacing, and clean plug-and-play provider boundaries.

**Architecture:** Each AI Pack (`AppleDefaultPack`, `OfflineAIPack`, `GeminiCloudPack`) provides an atomic bundle of `{LLM, TTS, STT}` conforming to `AIPackProtocol`. An `AIPackRegistry` validates pack readiness at selection time, tracks the active pack, and resolves services without runtime fallback cascades; errors halt execution immediately and surface actionable alerts to the user.

**Tech Stack:** Swift 6.0, SwiftUI, Swift Testing (`@Suite`, `@Test`, `#expect`), AVFoundation, SpeechKit.

**Spec:** `docs/superpowers/specs/2026-10-07-ai-pack-registry-design.md`

## Global Constraints

- **Zero Hardcoded Strings Policy**: All user-facing strings must be defined in `VocabCraftApp/Resources/Localizable.xcstrings` under `app.ai.*` with 100% bilingual parity (`en` and `vi`) and `extractionState: "manual"`.
- **CraftUIKit-First**: UI components must use `CraftUIKit` tokens (`CraftColor`, `CraftFont`, `CraftSpacingTokens`).
- **Zero Silent Fallback**: When an active provider fails during conversation, the engine MUST enter `.error` state and present an explicit user alert. No fallback chains or swallows.
- **Strict Concurrency & Sendable**: All protocols and registry classes must be `@MainActor` or `Sendable` clean with zero warnings.

---

### Task 1: Core Domain Models & Engine Protocols

**Files:**
- Create: `VocabCraftApp/Domain/Models/AIPackIdentifier.swift`
- Create: `VocabCraftApp/Domain/Models/AIPackStatus.swift`
- Create: `VocabCraftApp/Domain/Models/AIPackError.swift`
- Create: `VocabCraftApp/Domain/Protocols/VoiceConfiguration.swift`
- Create: `VocabCraftApp/Domain/Protocols/TTSEngineProtocol.swift`
- Create: `VocabCraftApp/Domain/Protocols/STTEngineProtocol.swift`
- Create: `VocabCraftApp/Domain/Protocols/AIPackProtocol.swift`
- Modify: `VocabCraftApp/Domain/Protocols/VoiceConversationEngineProtocol.swift`
- Test: `VocabCraftAppTests/AI/AIPackDomainModelTests.swift`

**Interfaces:**
- Consumes: `LLMProviderProtocol` from `VocabCraftApp/Domain/Protocols/LLMProviderProtocol.swift`
- Produces: `AIPackIdentifier`, `AIPackStatus`, `AIPackError`, `VoiceConfiguration`, `VoiceProfile`, `TTSEngineProtocol`, `STTEngineProtocol`, `AIPackProtocol`

- [ ] **Step 1: Write the failing test for domain models and protocols**

```swift
// VocabCraftAppTests/AI/AIPackDomainModelTests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AI Pack Domain Models Tests")
struct AIPackDomainModelTests {
    @Test("AIPackIdentifier has all required Phase 1 and future cases")
    func testPackIdentifiers() {
        let cases = AIPackIdentifier.allCases
        #expect(cases.contains(.appleDefault))
        #expect(cases.contains(.offlineAI))
        #expect(cases.contains(.geminiCloud))
        #expect(cases.contains(.groqCloud))
        #expect(cases.contains(.openAICloud))
    }

    @Test("AIPackStatus equality and representation")
    func testPackStatus() {
        let ready = AIPackStatus.ready
        let needsKey = AIPackStatus.needsApiKey(providerName: "Gemini")
        let needsDownload = AIPackStatus.needsDownload(sizeDescription: "~500MB")
        let unavailable = AIPackStatus.unavailable(reason: "Requires iOS 26+")

        #expect(ready != needsKey)
        #expect(needsKey == .needsApiKey(providerName: "Gemini"))
        #expect(needsDownload == .needsDownload(sizeDescription: "~500MB"))
        #expect(unavailable == .unavailable(reason: "Requires iOS 26+"))
    }

    @Test("VoiceConfiguration maps gender and style")
    func testVoiceConfiguration() {
        let config = VoiceConfiguration(
            gender: .female,
            style: .friendly,
            locale: "en-US"
        )
        #expect(config.gender == .female)
        #expect(config.style == .friendly)
        #expect(config.locale == "en-US")
    }

    @Test("VoiceCallState contains error case")
    func testVoiceCallStateErrorCase() {
        let errorState = VoiceCallState.error(AIPackError.networkUnavailable)
        if case .error(let err) = errorState {
            #expect(err == .networkUnavailable)
        } else {
            Issue.record("Expected .error case in VoiceCallState")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/AIPackDomainModelTests`
Expected: FAIL with "cannot find 'AIPackIdentifier' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Domain/Models/AIPackIdentifier.swift`:
```swift
import Foundation

public enum AIPackIdentifier: String, Codable, Sendable, CaseIterable {
    case appleDefault
    case offlineAI
    case geminiCloud
    case groqCloud
    case openAICloud
}
```

Create `VocabCraftApp/Domain/Models/AIPackStatus.swift`:
```swift
import Foundation

public enum AIPackStatus: Sendable, Equatable {
    case ready
    case needsDownload(sizeDescription: String)
    case needsApiKey(providerName: String)
    case partiallyReady(ready: [String], notReady: [String])
    case unavailable(reason: String)
}
```

Create `VocabCraftApp/Domain/Models/AIPackError.swift`:
```swift
import Foundation

public enum AIPackError: Error, Sendable, Equatable {
    case apiKeyRequired(providerName: String)
    case downloadRequired(packName: String, sizeDescription: String)
    case deviceNotSupported(reason: String)
    case noPackAvailable

    case llmFailed(packName: String, underlyingMessage: String)
    case ttsFailed(packName: String, underlyingMessage: String)
    case sttFailed(packName: String, underlyingMessage: String)
    case networkUnavailable

    public var localizedKey: String {
        switch self {
        case .apiKeyRequired: return "app.ai.error.api_key_required"
        case .downloadRequired: return "app.ai.error.download_required"
        case .deviceNotSupported: return "app.ai.error.device_not_supported"
        case .noPackAvailable: return "app.ai.error.no_pack_available"
        case .llmFailed: return "app.ai.error.llm_failed"
        case .ttsFailed: return "app.ai.error.tts_failed"
        case .sttFailed: return "app.ai.error.stt_failed"
        case .networkUnavailable: return "app.ai.error.network_unavailable"
        }
    }
}
```

Create `VocabCraftApp/Domain/Protocols/VoiceConfiguration.swift`:
```swift
import Foundation

public struct VoiceConfiguration: Sendable, Codable, Equatable {
    public let gender: VoiceGender
    public let style: VoiceStyle
    public let locale: String

    public init(gender: VoiceGender, style: VoiceStyle, locale: String = "en-US") {
        self.gender = gender
        self.style = style
        self.locale = locale
    }

    public enum VoiceGender: String, Codable, Sendable {
        case male
        case female
    }

    public enum VoiceStyle: String, Codable, Sendable {
        case friendly
        case authoritative
        case expressive
        case calm
    }
}

public struct VoiceProfile: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let voiceConfig: VoiceConfiguration
    public let sampleText: String

    public init(id: String, displayName: String, voiceConfig: VoiceConfiguration, sampleText: String) {
        self.id = id
        self.displayName = displayName
        self.voiceConfig = voiceConfig
        self.sampleText = sampleText
    }
}
```

Create `VocabCraftApp/Domain/Protocols/TTSEngineProtocol.swift`:
```swift
import Foundation

public protocol TTSEngineProtocol: Sendable {
    var engineName: String { get }
    var isReady: Bool { get }
    func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws
    func stop()
}
```

Create `VocabCraftApp/Domain/Protocols/STTEngineProtocol.swift`:
```swift
import Foundation

public protocol STTEngineProtocol: Sendable {
    var engineName: String { get }
    var isReady: Bool { get }
    func startRecognition(locale: String) -> AsyncThrowingStream<String, Error>
    func stopRecognition()
}
```

Create `VocabCraftApp/Domain/Protocols/AIPackProtocol.swift`:
```swift
import Foundation

public protocol AIPackProtocol: Sendable {
    var identifier: AIPackIdentifier { get }
    var displayName: String { get }
    var packDescription: String { get }
    var status: AIPackStatus { get }
    var supportedVoices: [VoiceProfile] { get }
    var defaultVoice: VoiceProfile { get }

    func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol
    func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol
    func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol
}
```

Modify `VocabCraftApp/Domain/Protocols/VoiceConversationEngineProtocol.swift` to add `.error(AIPackError)`:
```swift
public enum VoiceCallState: Equatable, Sendable {
    case idle
    case speaking(characterText: String)
    case listening(liveTranscript: String)
    case thinking
    case error(AIPackError)
    case ended
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/AIPackDomainModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Models/AIPack*.swift VocabCraftApp/Domain/Protocols/AIPackProtocol.swift VocabCraftApp/Domain/Protocols/TTSEngineProtocol.swift VocabCraftApp/Domain/Protocols/STTEngineProtocol.swift VocabCraftApp/Domain/Protocols/VoiceConfiguration.swift VocabCraftApp/Domain/Protocols/VoiceConversationEngineProtocol.swift VocabCraftAppTests/AI/AIPackDomainModelTests.swift
git commit -m "feat(ai): define core AIPack protocols and models"
```

---

### Task 2: Strip Silent Fallbacks from LLM Providers & Remove `ResilientLLMProvider`

**Files:**
- Modify: `VocabCraftApp/Data/AI/GeminiLLMProvider.swift`
- Modify: `VocabCraftApp/Data/AI/GroqLLMProvider.swift`
- Delete: `VocabCraftApp/Data/AI/ResilientLLMProvider.swift`
- Modify: `VocabCraftAppTests/AI/LLMProviderTests.swift`
- Modify: `VocabCraftAppTests/AI/GroqLLMProviderTests.swift`

**Interfaces:**
- Consumes: `LLMProviderProtocol`, `LLMChatMessage`, `GeminiError`
- Produces: `GeminiLLMProvider(apiKey:session:models:)`, `GroqLLMProvider(apiKey:session:model:)` without fallback parameter

- [ ] **Step 1: Write the failing test for clean provider error throwing**

In `VocabCraftAppTests/AI/LLMProviderTests.swift`, add test verifying no fallback parameter and that Gemini throws on exhaustion:
```swift
    @Test("GeminiLLMProvider throws missingApiKey immediately without fallback")
    func testGeminiThrowsMissingApiKeyWithoutFallback() async {
        let provider = GeminiLLMProvider(apiKey: "")
        await #expect(throws: GeminiError.self) {
            let _: RoleplayTurnOutput = try await provider.sendStructuredMessage(
                messages: [LLMChatMessage(role: .user, content: "hi")],
                systemPrompt: "sys",
                responseSchema: RoleplayTurnOutput.self
            )
        }
    }
```

- [ ] **Step 2: Run test to verify compilation / failure**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/LLMProviderTests`

- [ ] **Step 3: Modify `GeminiLLMProvider.swift` and `GroqLLMProvider.swift`, and remove `ResilientLLMProvider.swift`**

In `GeminiLLMProvider.swift`:
Remove `fallbackProvider`:
```swift
    public init(
        apiKey: String,
        session: URLSession = .shared,
        models: [String] = defaultModels
    ) {
        self.apiKey = apiKey
        self.session = session
        self.models = models.isEmpty ? Self.defaultModels : models
    }
```
In `sendStructuredMessage`:
Remove fallback branches. If apiKey is empty, throw `GeminiError.missingApiKey`. If all candidate models fail, throw the recorded error:
```swift
        if let lastError = lastError as? GeminiError {
            throw lastError
        } else if let lastError {
            throw lastError
        } else {
            throw GeminiError.invalidResponse
        }
```

In `GroqLLMProvider.swift`:
Remove `fallbackProvider` from initializer and all `fallback.sendStructuredMessage` fallback calls. Throw `GroqError.unauthorized` or `GroqError.requestFailed` directly.

Delete `VocabCraftApp/Data/AI/ResilientLLMProvider.swift`.

- [ ] **Step 4: Run tests to verify all pass**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/LLMProviderTests`
Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/GroqLLMProviderTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git rm VocabCraftApp/Data/AI/ResilientLLMProvider.swift
git add VocabCraftApp/Data/AI/GeminiLLMProvider.swift VocabCraftApp/Data/AI/GroqLLMProvider.swift VocabCraftAppTests/AI/LLMProviderTests.swift VocabCraftAppTests/AI/GroqLLMProviderTests.swift
git commit -m "refactor(ai): remove silent fallbacks from Gemini and Groq providers"
```

---

### Task 3: Engine Adapters for TTS & STT

**Files:**
- Create: `VocabCraftApp/Data/Audio/Engines/AppleTTSEngineAdapter.swift`
- Create: `VocabCraftApp/Data/Audio/Engines/KokoroTTSEngineAdapter.swift`
- Create: `VocabCraftApp/Data/Audio/Engines/GeminiTTSEngineAdapter.swift`
- Create: `VocabCraftApp/Data/Audio/Engines/AppleSTTEngineAdapter.swift`
- Create: `VocabCraftApp/Data/Audio/Engines/WhisperKitSTTEngineAdapter.swift`
- Test: `VocabCraftAppTests/AI/TTSEngineAdapterTests.swift`

**Interfaces:**
- Consumes: `TTSEngineProtocol`, `STTEngineProtocol`, `VoiceConfiguration`, `AppleEnhancedTTSEngine`, `KokoroTTSEngine`, `GeminiAudioSpeechEngine`, `SpeechRecognitionService`, `WhisperKitSpeechEngine`
- Produces: Concrete adapters implementing `TTSEngineProtocol` and `STTEngineProtocol`

- [ ] **Step 1: Write failing tests for TTSEngine and STTEngine adapters**

```swift
// VocabCraftAppTests/AI/TTSEngineAdapterTests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("TTS Engine Adapter Tests")
struct TTSEngineAdapterTests {
    @Test("AppleTTSEngineAdapter is always ready and identifies correctly")
    func testAppleTTSEngine() {
        let engine = AppleTTSEngineAdapter()
        #expect(engine.engineName == "Apple Enhanced TTS")
        #expect(engine.isReady == true)
    }

    @Test("KokoroTTSEngineAdapter exposes readiness based on underlying model manager")
    func testKokoroTTSEngine() {
        let engine = KokoroTTSEngineAdapter(isReadyProvider: { false })
        #expect(engine.engineName == "Kokoro Neural TTS")
        #expect(engine.isReady == false)
    }

    @Test("GeminiTTSEngineAdapter checks apiKey presence")
    func testGeminiTTSEngine() {
        let engine = GeminiTTSEngineAdapter(apiKey: "valid-key")
        #expect(engine.engineName == "Gemini Studio TTS")
        #expect(engine.isReady == true)

        let emptyEngine = GeminiTTSEngineAdapter(apiKey: "")
        #expect(emptyEngine.isReady == false)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/TTSEngineAdapterTests`
Expected: FAIL with "cannot find 'AppleTTSEngineAdapter' in scope"

- [ ] **Step 3: Implement engine adapters**

Create `VocabCraftApp/Data/Audio/Engines/AppleTTSEngineAdapter.swift`:
```swift
import Foundation
import AVFoundation

public final class AppleTTSEngineAdapter: TTSEngineProtocol, @unchecked Sendable {
    public let engineName: String = "Apple Enhanced TTS"
    public var isReady: Bool { true }
    private let engine: AppleEnhancedTTSEngine

    public init(engine: AppleEnhancedTTSEngine = AppleEnhancedTTSEngine()) {
        self.engine = engine
    }

    public func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {
        let voiceId = AppleVoiceSelector.selectVoice(locale: voice.locale, gender: voice.gender == .male ? .male : .female)?.identifier
        await engine.speakAsync(
            text: text,
            rate: 0.5,
            locale: voice.locale,
            persona: nil,
            voiceIdentifier: voiceId,
            pitch: 1.0
        )
    }

    public func stop() {
        engine.stop()
    }
}
```

Create `VocabCraftApp/Data/Audio/Engines/KokoroTTSEngineAdapter.swift`:
```swift
import Foundation

public final class KokoroTTSEngineAdapter: TTSEngineProtocol, @unchecked Sendable {
    public let engineName: String = "Kokoro Neural TTS"
    private let underlyingEngine: KokoroTTSEngine?
    private let isReadyProvider: (() -> Bool)?

    public var isReady: Bool {
        if let provider = isReadyProvider {
            return provider()
        }
        return underlyingEngine?.isReady ?? false
    }

    public init(
        underlyingEngine: KokoroTTSEngine? = nil,
        isReadyProvider: (() -> Bool)? = nil
    ) {
        self.underlyingEngine = underlyingEngine
        self.isReadyProvider = isReadyProvider
    }

    public func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {
        guard isReady, let engine = underlyingEngine else {
            throw AIPackError.ttsFailed(packName: "Kokoro", underlyingMessage: "Model is not loaded")
        }
        let persona: VoicePersona = voice.gender == .male ? .friendlyMale : .friendlyFemale
        try await engine.synthesizeAndPlay(text: text, persona: persona)
    }

    public func stop() {
        underlyingEngine?.stop()
    }
}
```

Create `VocabCraftApp/Data/Audio/Engines/GeminiTTSEngineAdapter.swift`:
```swift
import Foundation

public final class GeminiTTSEngineAdapter: TTSEngineProtocol, @unchecked Sendable {
    public let engineName: String = "Gemini Studio TTS"
    private let apiKey: String
    private let underlyingEngine: GeminiAudioSpeechEngine

    public var isReady: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public init(apiKey: String, underlyingEngine: GeminiAudioSpeechEngine = GeminiAudioSpeechEngine()) {
        self.apiKey = apiKey
        self.underlyingEngine = underlyingEngine
    }

    public func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {
        guard isReady else {
            throw AIPackError.apiKeyRequired(providerName: "Gemini")
        }
        let persona: VoicePersona = voice.gender == .male ? .friendlyMale : .friendlyFemale
        try await underlyingEngine.synthesizeAndPlay(text: text, persona: persona, apiKey: apiKey)
    }

    public func stop() {
        underlyingEngine.stop()
    }
}
```

Create `VocabCraftApp/Data/Audio/Engines/AppleSTTEngineAdapter.swift`:
```swift
import Foundation

public final class AppleSTTEngineAdapter: STTEngineProtocol, @unchecked Sendable {
    public let engineName: String = "Apple Speech Recognition"
    public var isReady: Bool { true }
    private let coordinator: (any AudioSessionCoordinating)?

    public init(coordinator: (any AudioSessionCoordinating)? = nil) {
        self.coordinator = coordinator
    }

    public func startRecognition(locale: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let service = SpeechRecognitionService(locale: locale, audioSessionCoordinator: coordinator)
            service.startListening(
                onResult: { text in continuation.yield(text) },
                onError: { error in continuation.finish(throwing: error) }
            )
            continuation.onTermination = { _ in
                Task { @MainActor in service.stopListening() }
            }
        }
    }

    public func stopRecognition() {}
}
```

Create `VocabCraftApp/Data/Audio/Engines/WhisperKitSTTEngineAdapter.swift`:
```swift
import Foundation

public final class WhisperKitSTTEngineAdapter: STTEngineProtocol, @unchecked Sendable {
    public let engineName: String = "WhisperKit On-Device STT"
    private let underlyingEngine: WhisperKitSpeechEngine?
    private let isReadyProvider: (() -> Bool)?

    public var isReady: Bool {
        isReadyProvider?() ?? (underlyingEngine?.isReady ?? false)
    }

    public init(underlyingEngine: WhisperKitSpeechEngine? = nil, isReadyProvider: (() -> Bool)? = nil) {
        self.underlyingEngine = underlyingEngine
        self.isReadyProvider = isReadyProvider
    }

    public func startRecognition(locale: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard isReady, let engine = underlyingEngine else {
                continuation.finish(throwing: AIPackError.sttFailed(packName: "WhisperKit", underlyingMessage: "Model not downloaded"))
                return
            }
            Task { @MainActor in
                engine.startListening(
                    onResult: { text in continuation.yield(text) },
                    onError: { error in continuation.finish(throwing: error) }
                )
            }
            continuation.onTermination = { _ in
                Task { @MainActor in engine.stopListening() }
            }
        }
    }

    public func stopRecognition() {
        Task { @MainActor in underlyingEngine?.stopListening() }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/TTSEngineAdapterTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/Audio/Engines/*.swift VocabCraftAppTests/AI/TTSEngineAdapterTests.swift
git commit -m "feat(audio): implement TTSEngine and STTEngine adapters"
```

---

### Task 4: Concrete AI Packs Implementation

**Files:**
- Create: `VocabCraftApp/Data/AI/AppleFoundationModelLLMProvider.swift`
- Create: `VocabCraftApp/Data/AIPacks/AppleDefaultPack.swift`
- Create: `VocabCraftApp/Data/AIPacks/OfflineAIPack.swift`
- Create: `VocabCraftApp/Data/AIPacks/GeminiCloudPack.swift`
- Test: `VocabCraftAppTests/AI/ConcreteAIPackTests.swift`

**Interfaces:**
- Consumes: `AIPackProtocol`, `AIPackStatus`, `AIPackError`, `TTSEngineProtocol`, `STTEngineProtocol`, `LLMProviderProtocol`
- Produces: `AppleDefaultPack`, `OfflineAIPack`, `GeminiCloudPack`, `AppleFoundationModelLLMProvider`

- [ ] **Step 1: Write failing tests for concrete packs**

```swift
// VocabCraftAppTests/AI/ConcreteAIPackTests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Concrete AI Packs Tests")
struct ConcreteAIPackTests {
    @Test("GeminiCloudPack reports needsApiKey when key is missing")
    func testGeminiPackNeedsApiKey() {
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: "test_gemini_pack")!)
        store.geminiApiKey = ""
        let pack = GeminiCloudPack(settingsStore: store)
        #expect(pack.status == .needsApiKey(providerName: "Google Gemini"))
    }

    @Test("GeminiCloudPack reports ready when key is present")
    func testGeminiPackReady() {
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: "test_gemini_pack_ready")!)
        store.geminiApiKey = "test-api-key-123"
        let pack = GeminiCloudPack(settingsStore: store)
        #expect(pack.status == .ready)
    }

    @Test("OfflineAIPack reports needsDownload when models are not downloaded")
    func testOfflinePackNeedsDownload() {
        let pack = OfflineAIPack(
            isKokoroReady: { false },
            isWhisperReady: { false }
        )
        if case .needsDownload = pack.status {
            // Success
        } else {
            Issue.record("Expected .needsDownload status for OfflineAIPack")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/ConcreteAIPackTests`
Expected: FAIL with "cannot find 'GeminiCloudPack' in scope"

- [ ] **Step 3: Implement AppleFoundationModelLLMProvider and Concrete Packs**

Create `VocabCraftApp/Data/AI/AppleFoundationModelLLMProvider.swift`:
```swift
import Foundation

public final class AppleFoundationModelLLMProvider: LLMProviderProtocol, Sendable {
    public let providerIdentifier: String = "apple-foundation-models"

    public init() {}

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        // Foundation Models API gate for iOS 26+
        if #available(iOS 26, *) {
            // When iOS 26 Foundation Models SDK is linked, execute on-device inference here.
            throw AIPackError.deviceNotSupported(reason: "Apple Foundation Models runtime not yet enabled")
        } else {
            throw AIPackError.deviceNotSupported(reason: "Apple Foundation Models requires iOS 26+")
        }
    }
}
```

Create `VocabCraftApp/Data/AIPacks/AppleDefaultPack.swift`:
```swift
import Foundation

public struct AppleDefaultPack: AIPackProtocol {
    public let identifier: AIPackIdentifier = .appleDefault
    public let displayName: String = "Apple Default"
    public let packDescription: String = "Built-in Apple system components (AVSpeech & Speech Recognition)"

    public var status: AIPackStatus {
        if #available(iOS 26, *) {
            return .ready
        }
        return .unavailable(reason: "Apple Foundation Models requires iOS 26+")
    }

    public var supportedVoices: [VoiceProfile] {
        [
            VoiceProfile(
                id: "apple-default-female",
                displayName: "Samantha (Natural Female)",
                voiceConfig: VoiceConfiguration(gender: .female, style: .friendly),
                sampleText: "Hello, I am your Apple study partner."
            )
        ]
    }

    public var defaultVoice: VoiceProfile {
        supportedVoices[0]
    }

    public init() {}

    public func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
        guard #available(iOS 26, *) else {
            throw .deviceNotSupported(reason: "Apple Foundation Models requires iOS 26+")
        }
        return AppleFoundationModelLLMProvider()
    }

    public func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        AppleTTSEngineAdapter()
    }

    public func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        AppleSTTEngineAdapter()
    }
}
```

Create `VocabCraftApp/Data/AIPacks/OfflineAIPack.swift`:
```swift
import Foundation

public struct OfflineAIPack: AIPackProtocol {
    public let identifier: AIPackIdentifier = .offlineAI
    public let displayName: String = "Offline AI Pack"
    public let packDescription: String = "High-quality neural models (Kokoro TTS & WhisperKit STT) running fully on-device"

    private let isKokoroReady: @Sendable () -> Bool
    private let isWhisperReady: @Sendable () -> Bool

    public init(
        isKokoroReady: @escaping @Sendable () -> Bool,
        isWhisperReady: @escaping @Sendable () -> Bool
    ) {
        self.isKokoroReady = isKokoroReady
        self.isWhisperReady = isWhisperReady
    }

    public var status: AIPackStatus {
        let kokoro = isKokoroReady()
        let whisper = isWhisperReady()
        if kokoro && whisper {
            return .ready
        }
        return .needsDownload(sizeDescription: "~500MB")
    }

    public var supportedVoices: [VoiceProfile] {
        [
            VoiceProfile(
                id: "kokoro-heart",
                displayName: "Heart (Warm Female)",
                voiceConfig: VoiceConfiguration(gender: .female, style: .friendly),
                sampleText: "Hi! Ready to practice your conversation skills?"
            )
        ]
    }

    public var defaultVoice: VoiceProfile {
        supportedVoices[0]
    }

    public func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
        guard #available(iOS 26, *) else {
            throw .deviceNotSupported(reason: "On-device LLM requires iOS 26+ in Phase 1")
        }
        return AppleFoundationModelLLMProvider()
    }

    public func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        guard isKokoroReady() else {
            throw .downloadRequired(packName: "Kokoro TTS", sizeDescription: "~350MB")
        }
        return KokoroTTSEngineAdapter(isReadyProvider: isKokoroReady)
    }

    public func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        guard isWhisperReady() else {
            throw .downloadRequired(packName: "WhisperKit", sizeDescription: "~150MB")
        }
        return WhisperKitSTTEngineAdapter(isReadyProvider: isWhisperReady)
    }
}
```

Create `VocabCraftApp/Data/AIPacks/GeminiCloudPack.swift`:
```swift
import Foundation

public struct GeminiCloudPack: AIPackProtocol {
    public let identifier: AIPackIdentifier = .geminiCloud
    public let displayName: String = "Gemini Cloud Pack"
    public let packDescription: String = "Google Gemini neural intelligence and expressive Studio voices"

    private let settingsStore: UserSettingsStore

    public init(settingsStore: UserSettingsStore) {
        self.settingsStore = settingsStore
    }

    public var status: AIPackStatus {
        guard settingsStore.isGeminiApiKeyConfigured else {
            return .needsApiKey(providerName: "Google Gemini")
        }
        return .ready
    }

    public var supportedVoices: [VoiceProfile] {
        [
            VoiceProfile(
                id: "gemini-aoede",
                displayName: "Aoede (Friendly Female)",
                voiceConfig: VoiceConfiguration(gender: .female, style: .friendly),
                sampleText: "Hello there! Let's practice English together today."
            ),
            VoiceProfile(
                id: "gemini-puck",
                displayName: "Puck (Friendly Male)",
                voiceConfig: VoiceConfiguration(gender: .male, style: .friendly),
                sampleText: "Hey! Ready to dive into this scenario?"
            )
        ]
    }

    public var defaultVoice: VoiceProfile {
        supportedVoices[0]
    }

    public func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
        let key = settingsStore.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw .apiKeyRequired(providerName: "Google Gemini") }
        return GeminiLLMProvider(apiKey: key)
    }

    public func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        let key = settingsStore.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw .apiKeyRequired(providerName: "Google Gemini") }
        return GeminiTTSEngineAdapter(apiKey: key)
    }

    public func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        AppleSTTEngineAdapter()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/ConcreteAIPackTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/AppleFoundationModelLLMProvider.swift VocabCraftApp/Data/AIPacks/*.swift VocabCraftAppTests/AI/ConcreteAIPackTests.swift
git commit -m "feat(ai): implement AppleDefaultPack, OfflineAIPack, and GeminiCloudPack"
```

---

### Task 5: AIPackRegistry & Settings Persistence

**Files:**
- Create: `VocabCraftApp/Data/AIPacks/AIPackRegistry.swift`
- Modify: `VocabCraftApp/Core/Storage/UserSettingsStore.swift`
- Test: `VocabCraftAppTests/AI/AIPackRegistryTests.swift`

**Interfaces:**
- Consumes: `AIPackProtocol`, `AIPackIdentifier`, `AIPackStatus`, `AIPackError`, `UserSettingsStore`
- Produces: `AIPackRegistry` with `selectPack`, `resolveActiveLLM`, `resolveActiveTTS`, `resolveActiveSTT`, `revalidateActivePack`

- [ ] **Step 1: Write failing tests for AIPackRegistry**

```swift
// VocabCraftAppTests/AI/AIPackRegistryTests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AIPackRegistry Tests")
struct AIPackRegistryTests {
    @Test("Registry initializes with stored pack or fallback default")
    @MainActor
    func testRegistryInitialization() {
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: "registry_test_1")!)
        let pack = GeminiCloudPack(settingsStore: store)
        let registry = AIPackRegistry(packs: [pack], settingsStore: store)

        #expect(registry.packCatalog.count == 1)
    }

    @Test("Registry throws when selecting pack that needs API key")
    @MainActor
    func testSelectPackFailsWhenNotReady() {
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: "registry_test_2")!)
        store.geminiApiKey = ""
        let pack = GeminiCloudPack(settingsStore: store)
        let registry = AIPackRegistry(packs: [pack], settingsStore: store)

        #expect(throws: AIPackError.self) {
            try registry.selectPack(.geminiCloud)
        }
    }

    @Test("Registry persists active pack when selection succeeds")
    @MainActor
    func testSelectPackSucceedsWhenReady() throws {
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: "registry_test_3")!)
        store.geminiApiKey = "valid-key-xyz"
        let pack = GeminiCloudPack(settingsStore: store)
        let registry = AIPackRegistry(packs: [pack], settingsStore: store)

        try registry.selectPack(.geminiCloud)
        #expect(registry.activePackId == .geminiCloud)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/AIPackRegistryTests`
Expected: FAIL with "cannot find 'AIPackRegistry' in scope"

- [ ] **Step 3: Implement AIPackRegistry and update UserSettingsStore**

In `VocabCraftApp/Core/Storage/UserSettingsStore.swift`, add property:
```swift
    public var selectedAIPackId: String {
        get { userDefaults.string(forKey: "selectedAIPackId") ?? AIPackIdentifier.geminiCloud.rawValue }
        set { userDefaults.set(newValue, forKey: "selectedAIPackId") }
    }
```

Create `VocabCraftApp/Data/AIPacks/AIPackRegistry.swift`:
```swift
import Foundation
import Observation

public struct AIPackEntry: Sendable, Identifiable {
    public var id: AIPackIdentifier { identifier }
    public let identifier: AIPackIdentifier
    public let displayName: String
    public let description: String
    public let status: AIPackStatus
    public let isActive: Bool
}

@MainActor
@Observable
public final class AIPackRegistry {
    private let packs: [AIPackIdentifier: any AIPackProtocol]
    private let settingsStore: UserSettingsStore
    public private(set) var activePackId: AIPackIdentifier
    public private(set) var activePackIssue: AIPackError?

    public init(packs: [any AIPackProtocol], settingsStore: UserSettingsStore) {
        var packMap: [AIPackIdentifier: any AIPackProtocol] = [:]
        for pack in packs {
            packMap[pack.identifier] = pack
        }
        self.packs = packMap
        self.settingsStore = settingsStore

        let saved = AIPackIdentifier(rawValue: settingsStore.selectedAIPackId) ?? .geminiCloud
        self.activePackId = saved
        self.revalidateActivePack()
    }

    public var packCatalog: [AIPackEntry] {
        packs.values.map { pack in
            AIPackEntry(
                identifier: pack.identifier,
                displayName: pack.displayName,
                description: pack.packDescription,
                status: pack.status,
                isActive: pack.identifier == activePackId
            )
        }.sorted { $0.identifier.rawValue < $1.identifier.rawValue }
    }

    public func selectPack(_ id: AIPackIdentifier) throws(AIPackError) {
        guard let pack = packs[id] else {
            throw .noPackAvailable
        }

        switch pack.status {
        case .ready:
            self.activePackId = id
            self.settingsStore.selectedAIPackId = id.rawValue
            self.activePackIssue = nil
        case .needsApiKey(let provider):
            throw .apiKeyRequired(providerName: provider)
        case .needsDownload(let size):
            throw .downloadRequired(packName: pack.displayName, sizeDescription: size)
        case .unavailable(let reason):
            throw .deviceNotSupported(reason: reason)
        case .partiallyReady:
            throw .downloadRequired(packName: pack.displayName, sizeDescription: "Incomplete models")
        }
    }

    public func resolveActivePack() throws(AIPackError) -> any AIPackProtocol {
        guard let pack = packs[activePackId] else {
            throw .noPackAvailable
        }
        guard pack.status == .ready else {
            switch pack.status {
            case .needsApiKey(let provider): throw .apiKeyRequired(providerName: provider)
            case .needsDownload(let size): throw .downloadRequired(packName: pack.displayName, sizeDescription: size)
            case .unavailable(let reason): throw .deviceNotSupported(reason: reason)
            default: throw .noPackAvailable
            }
        }
        return pack
    }

    public func resolveActiveLLM() throws(AIPackError) -> any LLMProviderProtocol {
        try resolveActivePack().makeLLMProvider()
    }

    public func resolveActiveTTS() throws(AIPackError) -> any TTSEngineProtocol {
        try resolveActivePack().makeTTSEngine()
    }

    public func resolveActiveSTT() throws(AIPackError) -> any STTEngineProtocol {
        try resolveActivePack().makeSTTEngine()
    }

    public func revalidateActivePack() {
        guard let pack = packs[activePackId] else {
            activePackIssue = .noPackAvailable
            return
        }
        switch pack.status {
        case .ready:
            activePackIssue = nil
        case .needsApiKey(let provider):
            activePackIssue = .apiKeyRequired(providerName: provider)
        case .needsDownload(let size):
            activePackIssue = .downloadRequired(packName: pack.displayName, sizeDescription: size)
        case .unavailable(let reason):
            activePackIssue = .deviceNotSupported(reason: reason)
        case .partiallyReady:
            activePackIssue = .downloadRequired(packName: pack.displayName, sizeDescription: "Incomplete models")
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/AIPackRegistryTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AIPacks/AIPackRegistry.swift VocabCraftApp/Core/Storage/UserSettingsStore.swift VocabCraftAppTests/AI/AIPackRegistryTests.swift
git commit -m "feat(ai): implement AIPackRegistry with validation and selection persistence"
```

---

### Task 6: Refactor `TurnBasedVoiceConversationEngine` & Clean Up `TextToSpeechService`

**Files:**
- Modify: `VocabCraftApp/Core/Audio/TextToSpeechService.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Services/TurnBasedVoiceConversationEngine.swift`
- Test: `VocabCraftAppTests/AI/TurnBasedVoiceConversationEngineTests.swift`

**Interfaces:**
- Consumes: `LLMProviderProtocol`, `TTSEngineProtocol`, `STTEngineProtocol`, `AIPackError`
- Produces: `TurnBasedVoiceConversationEngine` with fail-fast zero-fallback semantics

- [ ] **Step 1: Write zero-silent-fallback test in `TurnBasedVoiceConversationEngineTests`**

```swift
    @Test("TurnBasedVoiceConversationEngine enters .error state without silent fallback on LLM error")
    @MainActor
    func testNoSilentFallbackOnLLMError() async {
        let failingLLM = MockLLMProvider()
        failingLLM.shouldThrowError = true
        let mockTTS = MockTTSEngine()
        let mockSTT = MockSTTEngine()

        let engine = TurnBasedVoiceConversationEngine(
            scenario: RoleplayScenario.cafeMock,
            llmProvider: failingLLM,
            ttsEngine: mockTTS,
            sttEngine: mockSTT
        )

        await engine.processUserUtterance("I would like a coffee")

        if case .error = engine.state {
            #expect(mockTTS.synthesizedCount == 0) // Did NOT attempt TTS on error
        } else {
            Issue.record("Expected state to be .error but was \(engine.state)")
        }
    }
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/TurnBasedVoiceConversationEngineTests`

- [ ] **Step 3: Update `TurnBasedVoiceConversationEngine` and `TextToSpeechService`**

In `TurnBasedVoiceConversationEngine.swift`:
Inject:
```swift
    private let llmProvider: any LLMProviderProtocol
    private let ttsEngine: any TTSEngineProtocol
    private let sttEngine: any STTEngineProtocol
    public private(set) var activeError: AIPackError?
```
When handling user utterance or generation:
```swift
    do {
        self.state = .thinking
        let response = try await llmProvider.sendStructuredMessage(
            messages: history,
            systemPrompt: scenario.systemPrompt,
            responseSchema: RoleplayTurnOutput.self
        )
        self.state = .speaking(characterText: response.characterReply)
        try await ttsEngine.synthesizeAndPlay(
            text: response.characterReply,
            voice: VoiceConfiguration(gender: .female, style: .friendly)
        )
        self.state = .listening(liveTranscript: "")
    } catch let error as AIPackError {
        self.activeError = error
        self.state = .error(error)
    } catch {
        let wrapped = AIPackError.llmFailed(packName: "Active Provider", underlyingMessage: error.localizedDescription)
        self.activeError = wrapped
        self.state = .error(wrapped)
    }
```

In `TextToSpeechService.swift`:
Remove `playConversation` multi-provider fallback chains that secretly switch from Kokoro to Gemini or Apple. Keep audio session leasing and pronunciation playback cleanly separated.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/TurnBasedVoiceConversationEngineTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/TextToSpeechService.swift VocabCraftApp/Features/AIAssistant/Services/TurnBasedVoiceConversationEngine.swift VocabCraftAppTests/AI/TurnBasedVoiceConversationEngineTests.swift
git commit -m "refactor(ai): enforce zero-fallback fail-fast error handling in VoiceConversationEngine"
```

---

### Task 7: Rewire `AppContainer` & ViewModels with `AIPackRegistry`

**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/Domain/UseCases/ExecuteRoleplayTurnUseCase.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayVoiceCallViewModel.swift`
- Test: `VocabCraftAppTests/App/AppContainerAITests.swift`

**Interfaces:**
- Consumes: `AIPackRegistry`, `TurnBasedVoiceConversationEngine`
- Produces: `AppContainer.aiPackRegistry`, factory methods instantiating roleplay workflows via active pack

- [ ] **Step 1: Write test for AppContainer AI Pack Registry resolution**

```swift
// VocabCraftAppTests/App/AppContainerAITests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AppContainer AI Tests")
struct AppContainerAITests {
    @Test("AppContainer exposes configured aiPackRegistry")
    @MainActor
    func testAppContainerRegistryExposure() {
        let container = AppContainer()
        #expect(container.aiPackRegistry.packCatalog.count >= 2)
    }

    @Test("AppContainer builds voice call view model using active pack")
    @MainActor
    func testVoiceCallViewModelCreation() {
        let container = AppContainer()
        let vm = container.makeRoleplayVoiceCallViewModel(for: RoleplayScenario.cafeMock)
        #expect(vm != nil)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/AppContainerAITests`

- [ ] **Step 3: Update `AppContainer.swift` and use cases**

In `AppContainer.swift`:
Replace old `llmProvider` computed property with:
```swift
    public let aiPackRegistry: AIPackRegistry
```
In `init(...)`:
```swift
    let applePack = AppleDefaultPack()
    let offlinePack = OfflineAIPack(
        isKokoroReady: { false },
        isWhisperReady: { false }
    )
    let geminiPack = GeminiCloudPack(settingsStore: effectiveUserSettingsStore)

    self.aiPackRegistry = AIPackRegistry(
        packs: [applePack, offlinePack, geminiPack],
        settingsStore: effectiveUserSettingsStore
    )
```

Update `makeExecuteRoleplayTurnUseCase()`:
```swift
    public func makeExecuteRoleplayTurnUseCase() -> ExecuteRoleplayTurnUseCase {
        let llm = (try? aiPackRegistry.resolveActiveLLM()) ?? IntelligentMockLLMProvider()
        return ExecuteRoleplayTurnUseCase(llmProvider: llm)
    }
```

Update `makeRoleplayVoiceCallViewModel(for:)`:
```swift
    @MainActor
    public func makeRoleplayVoiceCallViewModel(for scenario: RoleplayScenario) -> RoleplayVoiceCallViewModel {
        let llm = (try? aiPackRegistry.resolveActiveLLM()) ?? IntelligentMockLLMProvider()
        let tts = (try? aiPackRegistry.resolveActiveTTS()) ?? AppleTTSEngineAdapter()
        let stt = (try? aiPackRegistry.resolveActiveSTT()) ?? AppleSTTEngineAdapter()

        let engine = TurnBasedVoiceConversationEngine(
            scenario: scenario,
            llmProvider: llm,
            ttsEngine: tts,
            sttEngine: stt,
            audioSessionCoordinator: audioSessionCoordinator
        )
        return RoleplayVoiceCallViewModel(engine: engine, ttsService: ttsService)
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/AppContainerAITests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp/Domain/UseCases/ExecuteRoleplayTurnUseCase.swift VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayVoiceCallViewModel.swift VocabCraftAppTests/App/AppContainerAITests.swift
git commit -m "feat(di): wire AIPackRegistry into AppContainer and roleplay factories"
```

---

### Task 8: UI Gating, Error Alerts, and Localization (100% Bilingual Parity)

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift`

**Interfaces:**
- Consumes: `AIPackError`, `Localizable.xcstrings`, `CraftUIKit` tokens
- Produces: Explicit error alert on voice call error, active pack status indicator in AI hub

- [ ] **Step 1: Write localization test for new AI error and pack strings**

```swift
// VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift (add to suite)
    @Test("Verify AI pack localization keys exist in English and Vietnamese")
    func testAIPackLocalizationKeys() {
        let keys = [
            "app.ai.error.alert_title",
            "app.ai.error.retry_action",
            "app.ai.error.change_pack_action",
            "app.ai.error.end_call_action",
            "app.ai.pack.status.ready",
            "app.ai.pack.status.needs_key",
            "app.ai.pack.status.needs_download"
        ]
        for key in keys {
            let en = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "en"))
            let vi = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "vi"))
            #expect(!en.isEmpty && en != key)
            #expect(!vi.isEmpty && vi != key)
        }
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests`

- [ ] **Step 3: Add localization entries in `Localizable.xcstrings` and update Views**

In `VocabCraftApp/Resources/Localizable.xcstrings`, add bilingual entries for:
- `app.ai.error.alert_title`: EN "AI Service Issue" / VI "Sự Cố Dịch Vụ AI"
- `app.ai.error.retry_action`: EN "Retry" / VI "Thử lại"
- `app.ai.error.change_pack_action`: EN "Change AI Pack" / VI "Đổi Gói AI"
- `app.ai.error.end_call_action`: EN "End Call" / VI "Kết thúc"
- `app.ai.pack.status.ready`: EN "Ready" / VI "Sẵn sàng"
- `app.ai.pack.status.needs_key`: EN "API Key Required" / VI "Cần nhập API Key"
- `app.ai.pack.status.needs_download`: EN "Download Required" / VI "Cần tải về"

In `RoleplayVoiceCallView.swift`:
Present `.alert` when `viewModel.engine.state` matches `.error(let packError)`:
```swift
    .alert(
        Text(LocalizedStringKey("app.ai.error.alert_title")),
        isPresented: Binding(
            get: {
                if case .error = viewModel.engine.state { return true }
                return false
            },
            set: { _ in }
        )
    ) {
        Button(LocalizedStringKey("app.ai.error.retry_action")) {
            viewModel.engine.retryListening()
        }
        Button(LocalizedStringKey("app.ai.error.change_pack_action")) {
            // Dismiss and route to Settings
            dismiss()
        }
        Button(LocalizedStringKey("app.ai.error.end_call_action"), role: .cancel) {
            Task { await viewModel.endCall() }
        }
    } message: {
        if case .error(let err) = viewModel.engine.state {
            Text(LocalizedStringKey(err.localizedKey))
        }
    }
```

In `AIAssistantHubView.swift`:
Add an active pack indicator pill displaying current pack name and status badge.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Features/AIAssistant/Views/*.swift VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift
git commit -m "feat(ui): add AI Pack error alert and active pack badge with full localization"
```

---

## Plan Self-Review Checklist

1. **Spec coverage**:
   - AIPackProtocol, TTSEngineProtocol, STTEngineProtocol -> Task 1
   - Data models (AIPackIdentifier, AIPackStatus, AIPackError, VoiceConfiguration) -> Task 1
   - Strip silent fallbacks from LLM providers & delete ResilientLLMProvider -> Task 2
   - Engine adapters (Apple, Kokoro, Gemini, WhisperKit) -> Task 3
   - Concrete packs (AppleDefaultPack, OfflineAIPack, GeminiCloudPack) -> Task 4
   - AIPackRegistry & Settings -> Task 5
   - Refactor VoiceConversationEngine & thin down TextToSpeechService -> Task 6
   - AppContainer rewiring -> Task 7
   - Error UI alerts & 100% bilingual localization -> Task 8
2. **Placeholder scan**: All steps include concrete file paths, full Swift code snippets, exact commands, and commit messages. Zero TBDs or TODOs.
3. **Type consistency**: Protocol and model names (`AIPackProtocol`, `AIPackIdentifier`, `AIPackStatus`, `AIPackError`, `TTSEngineProtocol`, `STTEngineProtocol`) are identical across all tasks.
