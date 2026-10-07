# AI Pack Registry — Design Specification

**Date:** 2026-10-07
**Status:** Approved for Phase 1 Implementation
**Scope:** Architectural refactor of AI provider system (LLM, TTS, STT)

---

## 1. Problem Statement

The current AI conversation feature has multiple critical issues:

| # | Problem | Location | Impact |
|---|---------|----------|--------|
| 1 | Silent fallback across all layers | `GeminiLLMProvider`, `TextToSpeechService` | User selects Gemini but hears Apple TTS without knowing. LLM silently falls back to Mock |
| 2 | Fallback logic baked into individual providers | `GeminiLLMProvider.init(fallbackProvider:)`, `GroqLLMProvider.init(fallbackProvider:)` | Each provider decides its own fallback — inconsistent, uncontrollable |
| 3 | No concept of "AI Pack" (bundle) | `AppContainer.llmProvider` | LLM and TTS/STT wired independently with ad-hoc chains |
| 4 | `ResilientLLMProvider` exists but unused | `ResilientLLMProvider.swift` | Dead code, adds confusion |
| 5 | `TextToSpeechService` is a god class | 742+ lines, 4 duplicate fallback chains | `playWithKokoro`, `playWithGemini`, `performTestingConversationPlayback`, `performTestingProfilePlayback` — copy-paste fallback logic |
| 6 | `VoicePersona` hardcoded to Gemini names | `AudioServiceProtocols.swift` | "Aoede", "Puck" are Gemini-specific, not provider-agnostic |
| 7 | Provider selection = API key presence | `AppContainer.llmProvider` | Has key = use it, no key = skip. Not an explicit user choice |

## 2. Design Principles

1. **Bundle-based selection**: User chooses a complete AI Pack (LLM + TTS + STT). No mix-and-match.
2. **Zero silent fallback**: If a provider fails at runtime, the app stops and shows an explicit error with actionable options. Never silently switches to another provider.
3. **Fail-fast validation**: Pack availability is validated at selection time (before conversation), not mid-conversation.
4. **Deep modules**: Each pack is a deep module — small interface (`AIPackProtocol`), rich implementation hidden inside.
5. **Open for extension**: Adding a new pack = adding one struct conforming to `AIPackProtocol` + one line in `AppContainer`.

## 3. Three-Tier Provider Model

| Tier | Pack | LLM | TTS | STT | Requirements |
|------|------|-----|-----|-----|-------------|
| 1 — Always available | Apple Default | Apple Foundation Models | AVSpeechSynthesizer | Apple Speech | iOS 26+ for LLM |
| 2 — Download required | Offline AI | Apple FM (Phase 1) / llama.cpp (Phase 2) | Kokoro | WhisperKit | ~500MB download |
| 3 — API key required | Gemini Cloud | Gemini API | Gemini TTS | Apple Speech | Gemini API key |
| 3 — API key required | Groq Cloud (Phase 2) | Groq API | Kokoro/Apple | WhisperKit/Apple | Groq API key |
| 3 — API key required | OpenAI Cloud (future) | GPT API | OpenAI TTS | Whisper API | OpenAI API key |

### Device Availability Matrix

| Device | iOS Version | Apple Default | Offline AI | Cloud Packs |
|--------|-------------|---------------|------------|-------------|
| iPhone 16+ | iOS 26+ | ✅ Full | ✅ Full (after download) | ✅ With API key |
| iPhone 14-15 | iOS 26+ | ✅ Full | ✅ Full (after download) | ✅ With API key |
| Older devices | iOS 18-25 | ❌ No LLM | ❌ No LLM (Phase 1) | ✅ With API key |

On iOS < 26 without a cloud API key: AI conversation feature is **gated** — user sees a clear explanation and is guided to either upgrade iOS or enter an API key.

## 4. Core Abstractions

### 4.1 AIPackIdentifier

```swift
public enum AIPackIdentifier: String, Codable, Sendable, CaseIterable {
    case appleDefault
    case offlineAI
    case geminiCloud
    case groqCloud
    case openAICloud
}
```

### 4.2 AIPackStatus

```swift
public enum AIPackStatus: Sendable, Equatable {
    case ready
    case needsDownload(sizeDescription: String)
    case needsApiKey(providerName: String)
    case partiallyReady(ready: [String], notReady: [String])
    case unavailable(reason: String)
}
```

### 4.3 AIPackError (typed throws)

```swift
public enum AIPackError: Error, Sendable, Equatable {
    // Selection-time
    case apiKeyRequired(providerName: String)
    case downloadRequired(packName: String, sizeDescription: String)
    case deviceNotSupported(reason: String)
    case noPackAvailable

    // Runtime
    case llmFailed(packName: String, underlyingMessage: String)
    case ttsFailed(packName: String, underlyingMessage: String)
    case sttFailed(packName: String, underlyingMessage: String)
    case networkUnavailable

    var userMessage: String { /* localized user-facing message */ }
    var recoverySuggestion: String { /* localized guidance */ }
}
```

### 4.4 AIPackProtocol

```swift
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

### 4.5 TTSEngineProtocol (new)

Replaces the fallback-heavy approach in `TextToSpeechService`. Each engine knows only how to synthesize — no cross-engine fallback.

```swift
public protocol TTSEngineProtocol: Sendable {
    var engineName: String { get }
    var isReady: Bool { get }
    func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws
    func stop()
}
```

### 4.6 STTEngineProtocol (new)

```swift
public protocol STTEngineProtocol: Sendable {
    var engineName: String { get }
    var isReady: Bool { get }
    func startRecognition(locale: String) -> AsyncThrowingStream<String, Error>
    func stopRecognition()
}
```

### 4.7 VoiceConfiguration & VoiceProfile

Provider-agnostic voice description. Each pack maps this to its engine-specific voice IDs internally.

```swift
public struct VoiceConfiguration: Sendable, Codable, Equatable {
    public let gender: VoiceGender
    public let style: VoiceStyle
    public let locale: String

    public enum VoiceGender: String, Codable, Sendable { case male, female }
    public enum VoiceStyle: String, Codable, Sendable {
        case friendly, authoritative, expressive, calm
    }
}

public struct VoiceProfile: Sendable, Codable, Equatable, Identifiable {
    public let id: String                   // "gemini-aoede", "kokoro-af-heart"
    public let displayName: String          // "Aoede (Friendly Female)"
    public let voiceConfig: VoiceConfiguration
    public let sampleText: String           // For voice preview
}
```

Voice mapping per pack:
- **Gemini**: `.friendly + .female` → `"Aoede"`
- **Kokoro**: `.friendly + .female` → `"af_heart"`
- **Apple**: `.friendly + .female` → best matching `AVSpeechSynthesisVoice`

When user switches pack → voice selection resets to `defaultVoice` of the new pack.

## 5. AIPackRegistry

Single source of truth for pack management and selection.

```swift
@MainActor
@Observable
public final class AIPackRegistry {
    private let packs: [AIPackIdentifier: any AIPackProtocol]
    private(set) var activePackId: AIPackIdentifier  // persisted
    private(set) var activePackIssue: AIPackError?

    init(packs: [any AIPackProtocol], settingsStore: UserSettingsStore)

    var packCatalog: [AIPackEntry] { /* all packs with status */ }

    func selectPack(_ id: AIPackIdentifier) throws(AIPackError)
    func resolveActiveLLM() throws(AIPackError) -> any LLMProviderProtocol
    func resolveActiveTTS() throws(AIPackError) -> any TTSEngineProtocol
    func resolveActiveSTT() throws(AIPackError) -> any STTEngineProtocol
    func revalidateActivePack()
}
```

### Pack Selection Flow

```
User taps pack in Settings
    │
    ▼
Registry.selectPack(id)
    ├─ pack.status == .ready → activate, persist ✓
    ├─ .needsApiKey → throw, UI: "Enter API key"
    ├─ .needsDownload → throw, UI: "Download required"
    └─ .unavailable → throw, UI: "Device not supported"

User CANNOT activate a pack that is not .ready
```

### Mid-Conversation Error Flow

```
Provider throws error during conversation
    │
    ▼
VoiceConversationEngine catches
    │
    ▼
state = .error, packError = AIPackError.llmFailed(...)
    │
    ▼
UI shows BLOCKING alert:
  ┌──────────────────────────────────────────┐
  │  ⚠️ [Pack Name] is not responding        │
  │                                          │
  │  Error: [description]                    │
  │                                          │
  │  [Retry]  [Change AI Pack]  [End Call]   │
  └──────────────────────────────────────────┘

NO automatic fallback. User always decides.
```

### Revalidation

`revalidateActivePack()` is called:
- On app foreground
- When UserSettingsStore changes (API key added/removed)
- Before starting a conversation

If the active pack becomes invalid (e.g., API key deleted), `activePackIssue` is set and the UI surfaces a non-blocking banner in the AI Assistant hub.

## 6. Concrete Packs — Phase 1

### 6.1 AppleDefaultPack

```swift
struct AppleDefaultPack: AIPackProtocol {
    let identifier = AIPackIdentifier.appleDefault

    var status: AIPackStatus {
        if #available(iOS 26, *) { return .ready }
        return .unavailable(reason: "Apple Foundation Models requires iOS 26+")
    }

    func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
        guard #available(iOS 26, *) else {
            throw .deviceNotSupported(reason: "Apple Foundation Models requires iOS 26+")
        }
        return AppleFoundationModelLLMProvider()
    }

    func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        return AppleTTSEngine()
    }

    func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        return AppleSTTEngine()
    }
}
```

### 6.2 OfflineAIPack

```swift
struct OfflineAIPack: AIPackProtocol {
    let identifier = AIPackIdentifier.offlineAI
    private let downloadManager: ModelDownloadManager

    var status: AIPackStatus {
        let kokoroReady = downloadManager.isModelReady(.kokoro)
        let whisperReady = downloadManager.isModelReady(.whisperKit)
        let llmReady: Bool = {
            if #available(iOS 26, *) { return true }
            return downloadManager.isModelReady(.onDeviceLLM)
        }()

        if llmReady && kokoroReady && whisperReady { return .ready }
        if !llmReady && !kokoroReady && !whisperReady {
            return .needsDownload(sizeDescription: "~500MB")
        }
        return .partiallyReady(
            ready: [/* ready engine names */],
            notReady: [/* not ready engine names */]
        )
    }

    func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
        // Phase 1: Apple Foundation Models
        // Phase 2: OnDeviceLLMProvider (llama.cpp/MLX)
        guard #available(iOS 26, *) else {
            throw .deviceNotSupported(reason: "On-device LLM not yet available for iOS < 26")
        }
        return AppleFoundationModelLLMProvider()
    }

    func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        guard downloadManager.isModelReady(.kokoro) else {
            throw .downloadRequired(packName: "Kokoro TTS", sizeDescription: "~350MB")
        }
        return KokoroTTSEngine()
    }

    func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        guard downloadManager.isModelReady(.whisperKit) else {
            throw .downloadRequired(packName: "WhisperKit", sizeDescription: "~150MB")
        }
        return WhisperKitSTTEngine()
    }
}
```

### 6.3 GeminiCloudPack

```swift
struct GeminiCloudPack: AIPackProtocol {
    let identifier = AIPackIdentifier.geminiCloud
    private let settingsStore: UserSettingsStore

    var status: AIPackStatus {
        guard settingsStore.isGeminiApiKeyConfigured else {
            return .needsApiKey(providerName: "Google Gemini")
        }
        return .ready
    }

    func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
        let key = settingsStore.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw .apiKeyRequired(providerName: "Gemini") }
        return GeminiLLMProvider(apiKey: key)  // No fallbackProvider
    }

    func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        let key = settingsStore.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw .apiKeyRequired(providerName: "Gemini") }
        return GeminiTTSEngine(apiKey: key)
    }

    func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        return AppleSTTEngine()  // Declared, not a fallback
    }
}
```

### 6.4 Groq Composite Pack (Phase 2)

Groq has no TTS/STT. It declares dependency on OfflineAIPack and resolves at selection time:

```swift
struct GroqCloudPack: AIPackProtocol {
    let identifier = AIPackIdentifier.groqCloud
    private let settingsStore: UserSettingsStore
    private let offlinePack: OfflineAIPack

    var status: AIPackStatus {
        guard settingsStore.isGroqApiKeyConfigured else {
            return .needsApiKey(providerName: "Groq")
        }
        return .ready
    }

    func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        // Deterministic: use Offline engines if available, Apple if not
        // NOT a runtime fallback — decided when engine is created
        if offlinePack.status == .ready {
            return try offlinePack.makeTTSEngine()
        }
        return AppleTTSEngine()
    }
}
```

## 7. Existing Code Changes

### 7.1 Delete

| File | Reason |
|------|--------|
| `ResilientLLMProvider.swift` | Dead code, replaced by pack architecture |
| `IntelligentMockLLMProvider` usage in production | Keep for tests only |

### 7.2 Refactor — Remove Fallback Logic

**`GeminiLLMProvider.swift`:**
- Remove `fallbackProvider` init parameter
- Remove all fallback-to-fallbackProvider logic
- On failure after exhausting models: throw `GeminiError.allModelsFailed`

**`GroqLLMProvider.swift`:**
- Same treatment — remove `fallbackProvider`, throw on failure

**`TextToSpeechService.swift`:**
- Remove `playWithKokoro` (Kokoro→Gemini→Apple fallback chain)
- Remove `playWithGemini` (Gemini→Apple fallback chain)
- Remove `playConversation` (engine selection + fallback)
- Remove `performTestingConversationPlayback` and `performTestingProfilePlayback` (duplicate fallback)
- Reduce to thin coordinator for pronunciation-only playback (~150 lines)
- Conversation playback moves to `VoiceConversationEngine` using `TTSEngineProtocol` directly

**`AppContainer.swift`:**
- Remove `llmProvider` computed property with chain logic
- Add `aiPackRegistry: AIPackRegistry` property
- Factory methods use `registry.resolveActiveLLM()`, etc.

### 7.3 Refactor — VoicePersona → VoiceConfiguration

- Remove `VoicePersona` enum with Gemini-specific names ("Aoede", "Puck", "Charon", "Kore")
- Replace with provider-agnostic `VoiceConfiguration` (gender + style)
- Each engine maps `VoiceConfiguration` → engine-specific voice ID internally

### 7.4 Refactor — VoiceConversationEngine

- `TurnBasedVoiceConversationEngine` receives `LLMProviderProtocol`, `TTSEngineProtocol`, `STTEngineProtocol` via DI
- No longer knows about specific engines (Kokoro, Gemini, Apple)
- On provider error: sets `state = .error`, stores `packError: AIPackError`
- `VoiceCallState` gains `.error` case

### 7.5 VoiceCallState Update

```swift
public enum VoiceCallState: Equatable, Sendable {
    case idle
    case speaking(characterText: String)
    case listening(liveTranscript: String)
    case thinking
    case error      // NEW
    case ended
}
```

## 8. File Structure

```
VocabCraftApp/
├── Domain/
│   ├── Protocols/
│   │   ├── AIPackProtocol.swift              ← NEW
│   │   ├── TTSEngineProtocol.swift           ← NEW
│   │   ├── STTEngineProtocol.swift           ← NEW
│   │   ├── LLMProviderProtocol.swift         ← KEEP (unchanged)
│   │   ├── VoiceConfiguration.swift          ← NEW (replaces VoicePersona)
│   │   ├── AudioServiceProtocols.swift       ← REFACTOR (remove VoicePersona)
│   │   └── VoiceConversationEngineProtocol.swift ← REFACTOR (add .error state)
│   └── Models/
│       ├── AIPackIdentifier.swift            ← NEW
│       ├── AIPackStatus.swift                ← NEW
│       └── AIPackError.swift                 ← NEW
│
├── Data/
│   ├── AIPacks/                              ← NEW directory
│   │   ├── AIPackRegistry.swift              ← NEW
│   │   ├── AppleDefaultPack.swift            ← NEW
│   │   ├── OfflineAIPack.swift               ← NEW
│   │   └── GeminiCloudPack.swift             ← NEW
│   ├── AI/
│   │   ├── GeminiLLMProvider.swift           ← REFACTOR (remove fallback)
│   │   ├── GroqLLMProvider.swift             ← REFACTOR (remove fallback)
│   │   ├── AppleFoundationModelLLMProvider.swift  ← NEW
│   │   ├── MockLLMProvider.swift             ← KEEP (tests only)
│   │   └── ResilientLLMProvider.swift        ← DELETE
│   └── Audio/
│       ├── Engines/                          ← NEW directory
│       │   ├── AppleTTSEngine.swift
│       │   ├── KokoroTTSEngine.swift
│       │   ├── GeminiTTSEngine.swift
│       │   ├── AppleSTTEngine.swift
│       │   └── WhisperKitSTTEngine.swift
│       └── TextToSpeechService.swift         ← REFACTOR (thin, pronunciation only)
│
├── Features/
│   └── AIAssistant/
│       └── Services/
│           └── TurnBasedVoiceConversationEngine.swift  ← REFACTOR (pack-aware)
│
├── App/
│   └── DI/
│       └── AppContainer.swift                ← REFACTOR (use AIPackRegistry)
```

## 9. AppContainer Wiring

```swift
// AppContainer.swift — simplified
let aiPackRegistry = AIPackRegistry(
    packs: [
        AppleDefaultPack(),
        OfflineAIPack(downloadManager: modelDownloadManager),
        GeminiCloudPack(settingsStore: userSettingsStore),
        // Adding a new pack = adding one line here
    ],
    settingsStore: userSettingsStore
)

// Factory methods use registry
func makeExecuteRoleplayTurnUseCase() -> ExecuteRoleplayTurnUseCase {
    ExecuteRoleplayTurnUseCase(packRegistry: aiPackRegistry)
}

@MainActor
func makeRoleplayVoiceCallViewModel(for scenario: RoleplayScenario) throws -> RoleplayVoiceCallViewModel {
    let llm = try aiPackRegistry.resolveActiveLLM()
    let tts = try aiPackRegistry.resolveActiveTTS()
    let stt = try aiPackRegistry.resolveActiveSTT()

    let engine = TurnBasedVoiceConversationEngine(
        scenario: scenario,
        llmProvider: llm,
        ttsEngine: tts,
        sttEngine: stt,
        audioSessionCoordinator: audioSessionCoordinator
    )

    return RoleplayVoiceCallViewModel(engine: engine)
}
```

## 10. Testing Strategy

### Mock Infrastructure

```swift
struct MockAIPack: AIPackProtocol {
    var mockStatus: AIPackStatus = .ready
    var mockLLM: (any LLMProviderProtocol)?
    var shouldThrowOnMake = false
    // ...
}
```

### Critical Test Cases

| Layer | Test | Purpose |
|-------|------|---------|
| Pack | `test_geminiPack_statusNeedsApiKey_whenNoKey` | Pack reports correct status |
| Pack | `test_offlinePack_statusNeedsDownload_whenModelsNotReady` | Download gating works |
| Registry | `test_selectPack_throws_whenPackNotReady` | Cannot activate broken pack |
| Registry | `test_selectPack_persists_activePackId` | User choice persisted |
| Registry | `test_revalidate_setsIssue_whenApiKeyRemoved` | Revalidation catches changes |
| Engine | `test_startCall_setsErrorState_whenLLMFails` | Error propagation works |
| Engine | `test_startCall_setsErrorState_whenTTSFails` | TTS error propagation |
| Engine | `test_noSilentFallback_whenProviderFails` | **CRITICAL**: verify NO fallback |
| Integration | `test_fullConversationTurn_withMockPack` | Happy path end-to-end |

### Zero-Fallback Verification Test

```swift
@Test("LLM failure does NOT trigger fallback to another provider")
func noSilentFallback() async {
    let failingLLM = MockLLMProvider(shouldFail: true)
    let secondaryLLM = MockLLMProvider(shouldFail: false)

    let engine = TurnBasedVoiceConversationEngine(
        llmProvider: failingLLM,
        ttsEngine: mockTTS,
        sttEngine: mockSTT
    )

    await engine.startCall()

    #expect(engine.state == .error)
    #expect(engine.packError != nil)
    #expect(secondaryLLM.callCount == 0)
}
```

## 11. Phase Plan

### Phase 1 (Current Scope)

1. Define core protocols (`AIPackProtocol`, `TTSEngineProtocol`, `STTEngineProtocol`)
2. Define data models (`AIPackIdentifier`, `AIPackStatus`, `AIPackError`, `VoiceConfiguration`)
3. Implement `AIPackRegistry`
4. Implement 3 concrete packs: `AppleDefaultPack`, `OfflineAIPack`, `GeminiCloudPack`
5. Wrap existing engines to conform to new protocols (`AppleTTSEngine`, `KokoroTTSEngine`, etc.)
6. Create `AppleFoundationModelLLMProvider` (new)
7. Refactor `GeminiLLMProvider` and `GroqLLMProvider` — remove all fallback logic
8. Refactor `TurnBasedVoiceConversationEngine` — use protocol-based DI, fail-fast errors
9. Refactor `TextToSpeechService` — thin coordinator for pronunciation only
10. Refactor `AppContainer` — use `AIPackRegistry`
11. Delete `ResilientLLMProvider.swift`
12. Replace `VoicePersona` with `VoiceConfiguration`
13. Add error UI: pack error alerts, pack status in Settings
14. Write tests for all layers

### Phase 2 (Future)

- `GroqCloudPack` implementation
- On-device LLM (llama.cpp/MLX) integration into `OfflineAIPack`
- `OpenAICloudPack` implementation
- Pack management UI in Settings (download progress, API key management)

## 12. Key Invariants

These must hold true at all times:

1. **No silent fallback**: If a provider fails at runtime, the conversation pauses and the user is shown an explicit error with actionable options (Retry / Change Pack / End Call).
2. **Pack is atomic**: A pack either provides all three services (LLM + TTS + STT) or throws. No partial service delivery.
3. **Selection-time validation**: A pack cannot be activated unless its `status == .ready`.
4. **User controls the pack**: The app never switches packs automatically. The user always decides.
5. **Engine isolation**: Each TTS/STT engine implementation knows nothing about other engines. No cross-engine fallback logic inside any engine.
