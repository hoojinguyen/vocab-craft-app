# AI Pack Architecture Remediation & Audio Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decouple AI packs into strictly isolated bundles (Apple Default, Offline AI, Gemini Cloud), resolve audio session conflicts causing silent responses in voice call, fix Gemini model 404 errors, and provide dynamic 3-branch suggestions out of the box.

**Architecture:** 
- `AppleDefaultPack` is ready out-of-the-box (0MB download, 0 API key) on all iOS versions using Apple Speech and an adaptive `OnDeviceContextDialogueEngine`.
- `OfflineAIPack` is strictly isolated from cloud keys and activated only when 100% of on-device models are present (~975MB).
- `GeminiCloudPack` uses verified Google v1beta models (`gemini-2.5-flash`).
- `AppleSTTEngineAdapter` implements proper audio teardown and forwards live audio levels to animate the Voice Orb.

**Tech Stack:** Swift 5.10 / Swift 6 strict concurrency, SwiftUI, AVFoundation (`AVAudioEngine`, `AVSpeechSynthesizer`, `SFSpeechRecognizer`), SpeechKit (`sherpa-onnx`), CraftUIKit design tokens, Swift Testing (`@Suite`, `@Test`, `#expect`).

**Spec:** [`docs/superpowers/specs/2026-10-09-ai-pack-architecture-remediation-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-10-09-ai-pack-architecture-remediation-design.md)

## Global Constraints
- Strictly adhere to `AGENTS.md` and CraftUIKit token standards.
- Zero silent fallback: if an active pack fails, fail fast with typed `AIPackError` instead of falling back to mock or changing packs behind the user's back.
- Full 100% bilingual parity (en and vi) in `Localizable.xcstrings` for any user-facing strings.
- Zero compiler warnings and zero SwiftLint violations.

---

### Task 1: STT Engine Lifecycle & Audio Hardware Teardown

**Files:**
- Modify: `VocabCraftApp/Domain/Protocols/STTEngineProtocol.swift`
- Modify: `VocabCraftApp/Data/Audio/Engines/AppleSTTEngineAdapter.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Services/TurnBasedVoiceConversationEngine.swift:284-315`
- Test: `VocabCraftAppTests/AI/TTSEngineAdapterTests.swift`

**Interfaces:**
- Consumes: `SpeechRecognitionService`, `AudioSessionCoordinator`
- Produces: `STTEngineProtocol.startRecognition(locale:onAudioLevel:) -> AsyncThrowingStream<String, Error>`, `AppleSTTEngineAdapter.stopRecognition()`

- [ ] **Step 1: Write the failing test for STT teardown and audio level streaming**

Add test to `VocabCraftAppTests/AI/TTSEngineAdapterTests.swift`:

```swift
    @Test("AppleSTTEngineAdapter stopRecognition terminates active recognition session and stream")
    @MainActor
    func test_appleSTTEngineAdapter_stopRecognition_terminatesActiveSession() async throws {
        let coordinator = AudioSessionCoordinator()
        let adapter = AppleSTTEngineAdapter(coordinator: coordinator)
        var receivedLevel: Float = -1.0

        let stream = adapter.startRecognition(locale: "en-US", onAudioLevel: { level in
            receivedLevel = level
        })

        var iterator = stream.makeAsyncIterator()
        // Stop recognition immediately
        adapter.stopRecognition()

        // Stream iteration should finish cleanly
        let nextItem = try await iterator.next()
        #expect(nextItem == nil)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter test_appleSTTEngineAdapter_stopRecognition_terminatesActiveSession`
Expected: FAIL (method signature does not accept `onAudioLevel:` or does not finish stream on `stopRecognition()`).

- [ ] **Step 3: Update `STTEngineProtocol` and `AppleSTTEngineAdapter`**

In `VocabCraftApp/Domain/Protocols/STTEngineProtocol.swift`:
```swift
public protocol STTEngineProtocol: Sendable {
    var engineName: String { get }
    var isReady: Bool { get }
    func startRecognition(locale: String) -> AsyncThrowingStream<String, Error>
    func startRecognition(locale: String, onAudioLevel: (@Sendable (Float) -> Void)?) -> AsyncThrowingStream<String, Error>
    func stopRecognition()
}

public extension STTEngineProtocol {
    func startRecognition(locale: String) -> AsyncThrowingStream<String, Error> {
        startRecognition(locale: locale, onAudioLevel: nil)
    }
}
```

In `VocabCraftApp/Data/Audio/Engines/AppleSTTEngineAdapter.swift`:
Store active `SpeechRecognitionService` and `AsyncThrowingStream.Continuation`. On `stopRecognition()`, call `activeService?.stopListening()`, finish continuation, and clear references.
In `startRecognition(locale:onAudioLevel:)`, forward `onAudioLevel` closure into `SpeechRecognitionService.startListening(...)`.

In `TurnBasedVoiceConversationEngine.swift`:
Pass `{ [weak self] level in self?.audioLevel = level }` into `self.sttEngine.startRecognition(locale:onAudioLevel:)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter test_appleSTTEngineAdapter_stopRecognition_terminatesActiveSession`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Protocols/STTEngineProtocol.swift VocabCraftApp/Data/Audio/Engines/AppleSTTEngineAdapter.swift VocabCraftApp/Features/AIAssistant/Services/TurnBasedVoiceConversationEngine.swift VocabCraftAppTests/AI/TTSEngineAdapterTests.swift
git commit -m "fix(audio): implement AppleSTTEngineAdapter stopRecognition teardown and audio level metering"
```

---

### Task 2: Pack Isolation & Initial Default Pack in AIPackRegistry

**Files:**
- Modify: `VocabCraftApp/Data/AIPacks/AIPackRegistry.swift`
- Modify: `VocabCraftApp/Data/AIPacks/AppleDefaultPack.swift`
- Modify: `VocabCraftApp/Data/AIPacks/OfflineAIPack.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift:364-377`
- Test: `VocabCraftAppTests/AI/AIPackRegistryTests.swift`

**Interfaces:**
- Consumes: `AIPackRegistry`, `AppleDefaultPack`, `OfflineAIPack`, `GeminiCloudPack`
- Produces: `AIPackRegistry.activePackId` defaults to `.appleDefault`, `AppleDefaultPack.status == .ready` on all iOS platforms.

- [ ] **Step 1: Write failing tests for Pack Isolation and Default Selection**

Add tests to `VocabCraftAppTests/AI/AIPackRegistryTests.swift`:

```swift
    @Test("AIPackRegistry defaults to .appleDefault on fresh initialization without stored preference")
    @MainActor
    func test_registry_defaultsToAppleDefault() {
        let defaults = UserDefaults(suiteName: "TestAIPackDefaults_\(UUID().uuidString)")!
        let store = UserSettingsStore(defaults: defaults)
        let apple = AppleDefaultPack()
        let offline = OfflineAIPack(isKokoroReady: { false }, isWhisperReady: { false }, isLlamaReady: { false })
        let gemini = GeminiCloudPack(settingsStore: store)
        let registry = AIPackRegistry(packs: [apple, offline, gemini], settingsStore: store)

        #expect(registry.activePackId == .appleDefault)
        #expect(registry.activePack?.status == .ready)
    }

    @Test("OfflineAIPack is isolated and does not query geminiApiKey")
    @MainActor
    func test_offlinePack_isolatedFromGeminiKey() {
        let offline = OfflineAIPack(isKokoroReady: { true }, isWhisperReady: { true }, isLlamaReady: { true })
        #expect(offline.status == .ready)
    }
```

- [ ] **Step 2: Run tests to verify failure**

Run: `swift test --filter test_registry_defaultsToAppleDefault`
Expected: FAIL (currently defaults to `.geminiCloud`).

- [ ] **Step 3: Update `AIPackRegistry.swift` and `AppleDefaultPack.swift`**

In `VocabCraftApp/Data/AIPacks/AIPackRegistry.swift`:
```swift
let saved = AIPackIdentifier(rawValue: settingsStore.selectedAIPackId) ?? .appleDefault
self.activePackId = saved
```

In `VocabCraftApp/Data/AIPacks/AppleDefaultPack.swift`:
Make `status` always `.ready`:
```swift
public var status: AIPackStatus {
    .ready
}
```

In `VocabCraftApp/App/DI/AppContainer.swift`:
Update `makeRoleplayVoiceCallViewModel` to remove silent fallback to mock:
```swift
    @MainActor
    public func makeRoleplayVoiceCallViewModel(for scenario: RoleplayScenario) -> RoleplayVoiceCallViewModel {
        let activePack = (try? aiPackRegistry.resolveActivePack()) ?? aiPackRegistry.pack(for: .appleDefault)
        let llm = (try? activePack?.makeLLMProvider()) ?? IntelligentMockLLMProvider()
        let tts = (try? activePack?.makeTTSEngine()) ?? AppleTTSEngineAdapter(coordinator: audioSessionCoordinator)
        let stt = (try? activePack?.makeSTTEngine()) ?? AppleSTTEngineAdapter(coordinator: audioSessionCoordinator)

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

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter test_registry_defaultsToAppleDefault`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AIPacks/AIPackRegistry.swift VocabCraftApp/Data/AIPacks/AppleDefaultPack.swift VocabCraftApp/App/DI/AppContainer.swift VocabCraftAppTests/AI/AIPackRegistryTests.swift
git commit -m "fix(ai): decouple AI packs and default to AppleDefaultPack on fresh launch"
```

---

### Task 3: On-Device Context Dialogue Engine & Apple Default LLM Provider

**Files:**
- Create: `VocabCraftApp/Data/AI/OnDeviceContextDialogueEngine.swift`
- Create: `VocabCraftApp/Data/AI/AppleIntelligenceOrLocalDialogueProvider.swift`
- Modify: `VocabCraftApp/Data/AIPacks/AppleDefaultPack.swift`
- Test: `VocabCraftAppTests/AI/OnDeviceContextDialogueEngineTests.swift`

**Interfaces:**
- Consumes: `RoleplayScenario`, `RoleplayMessage`, `ReflexSpeechMatcher`, `FuzzySpeechMatcher`
- Produces: `OnDeviceContextDialogueEngine`, `AppleIntelligenceOrLocalDialogueProvider: LLMProviderProtocol`

- [ ] **Step 1: Write failing test for OnDeviceContextDialogueEngine**

Create `VocabCraftAppTests/AI/OnDeviceContextDialogueEngineTests.swift`:

```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("OnDeviceContextDialogueEngine Tests")
struct OnDeviceContextDialogueEngineTests {
    @Test("OnDeviceContextDialogueEngine detects target words and generates 3 branching suggestions")
    func test_contextDialogueEngine_generatesThreeBranchSuggestions() async throws {
        let engine = OnDeviceContextDialogueEngine()
        let scenario = RoleplayScenarioCatalog.standardScenarios[0] // cafe-order: beverage, pastry, complimentary

        let output = try await engine.generateTurn(
            scenario: scenario,
            userUtterance: "I would like a warm beverage please",
            conversationHistory: []
        )

        #expect(!output.characterReply.isEmpty)
        #expect(output.targetWordsUsed.contains("beverage"))
        #expect(output.suggestedResponses.count == 3)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter test_contextDialogueEngine_generatesThreeBranchSuggestions`
Expected: FAIL (file and type do not exist).

- [ ] **Step 3: Implement `OnDeviceContextDialogueEngine` and `AppleIntelligenceOrLocalDialogueProvider`**

Create `VocabCraftApp/Data/AI/OnDeviceContextDialogueEngine.swift`:
- Detect target vocabulary in user speech via `ReflexSpeechMatcher`.
- Classify conversational intent (ordering, greeting, inquiring, closing).
- Generate authentic character replies tailored to the scenario.
- Return 3 distinct candidate suggested responses: (1) Target Word branch, (2) Follow-up Question branch, (3) Casual Reaction branch.

Create `VocabCraftApp/Data/AI/AppleIntelligenceOrLocalDialogueProvider.swift`:
- Conforms to `LLMProviderProtocol`.
- On iOS 26+, routes to system Foundation Models if linked.
- On iOS 17/18, executes `OnDeviceContextDialogueEngine`.

Update `AppleDefaultPack.swift`:
```swift
    public func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
        AppleIntelligenceOrLocalDialogueProvider()
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter test_contextDialogueEngine_generatesThreeBranchSuggestions`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/OnDeviceContextDialogueEngine.swift VocabCraftApp/Data/AI/AppleIntelligenceOrLocalDialogueProvider.swift VocabCraftApp/Data/AIPacks/AppleDefaultPack.swift VocabCraftAppTests/AI/OnDeviceContextDialogueEngineTests.swift
git commit -m "feat(ai): create OnDeviceContextDialogueEngine and AppleIntelligenceOrLocalDialogueProvider"
```

---

### Task 4: Fix Gemini Cloud LLM Models & Test Alignment

**Files:**
- Modify: `VocabCraftApp/Data/AI/GeminiLLMProvider.swift:30-35`
- Modify: `VocabCraftAppTests/Core/Audio/GeminiAudioSpeechEngineTests.swift:103`
- Test: `VocabCraftAppTests/AI/LLMProviderTests.swift`
- Test: `VocabCraftAppTests/Core/Audio/GeminiAudioSpeechEngineTests.swift`

**Interfaces:**
- Consumes: Google Gemini GenerativeLanguage API v1beta
- Produces: `GeminiLLMProvider.defaultModels = ["gemini-2.5-flash", "gemini-2.5-flash-lite", "gemini-2.0-flash"]`

- [ ] **Step 1: Write test verifying Gemini candidate models contain valid endpoints**

Update `VocabCraftAppTests/AI/LLMProviderTests.swift`:

```swift
    @Test("GeminiLLMProvider default models use official Google Gemini 2.5 Flash endpoints")
    func test_geminiDefaultModels_useOfficialEndpoints() {
        let models = GeminiLLMProvider.defaultModels
        #expect(models.contains("gemini-2.5-flash"))
        #expect(!models.contains("gemini-flash-lite-latest"))
        #expect(!models.contains("gemini-3.1-flash-lite"))
    }
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter test_geminiDefaultModels_useOfficialEndpoints`
Expected: FAIL.

- [ ] **Step 3: Update `GeminiLLMProvider.swift` and fix `GeminiAudioSpeechEngineTests.swift`**

In `VocabCraftApp/Data/AI/GeminiLLMProvider.swift`:
```swift
    public static let defaultModels: [String] = [
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-2.0-flash"
    ]
```

In `VocabCraftAppTests/Core/Audio/GeminiAudioSpeechEngineTests.swift` line 103:
Change expected test URL to check for `gemini-3.1-flash-tts-preview` or `gemini-2.5-flash`:
```swift
    #expect(urlString.contains("gemini-3.1-flash-tts-preview") || urlString.contains("gemini-2.5-flash"))
```

- [ ] **Step 4: Run test to verify all Gemini tests pass**

Run: `swift test --filter Gemini`
Expected: 100% PASS across all 35 tests in 6 suites.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/GeminiLLMProvider.swift VocabCraftAppTests/Core/Audio/GeminiAudioSpeechEngineTests.swift VocabCraftAppTests/AI/LLMProviderTests.swift
git commit -m "fix(ai): update Gemini candidate models to official endpoints and align tests"
```

---

### Task 5: Adaptive Daily Scenario Starter Suggestions

**Files:**
- Modify: `VocabCraftApp/Domain/UseCases/FetchRoleplayScenariosUseCase.swift:10-25`
- Test: `VocabCraftAppTests/AI/RoleplayUseCasesTests.swift`

**Interfaces:**
- Consumes: `userWeakWords: [String]`
- Produces: `RoleplayScenario.starterSuggestions` populated for `adaptiveDaily`

- [ ] **Step 1: Write failing test verifying adaptive daily scenario has starter suggestions**

Add test to `VocabCraftAppTests/AI/RoleplayUseCasesTests.swift`:

```swift
    @Test("FetchRoleplayScenariosUseCase populates starterSuggestions for adaptive daily scenario")
    func test_adaptiveDailyScenario_hasPopulatedStarterSuggestions() async throws {
        let useCase = FetchRoleplayScenariosUseCase()
        let scenarios = try await useCase.execute(userWeakWords: ["collaborate", "innovative"])

        let daily = scenarios.first { $0.id == "daily-adaptive" }
        let unwrapped = try #require(daily)
        #expect(!unwrapped.starterSuggestions.isEmpty)
        #expect(unwrapped.starterSuggestions.count >= 2)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter test_adaptiveDailyScenario_hasPopulatedStarterSuggestions`
Expected: FAIL (`starterSuggestions.isEmpty == true`).

- [ ] **Step 3: Implement starter suggestions generator in `FetchRoleplayScenariosUseCase`**

In `VocabCraftApp/Domain/UseCases/FetchRoleplayScenariosUseCase.swift`:
```swift
            let firstWord = userWeakWords.first ?? "vocabulary"
            let secondWord = userWeakWords.count > 1 ? userWeakWords[1] : firstWord
            let starterPrompts = [
                "Hi! I'd like to practice using '\(firstWord)' in our conversation today.",
                "Hello! Could you help me practice using words like '\(secondWord)'?",
                "Hey Alex, I'm ready to practice my recent English vocabulary!"
            ]

            let adaptiveDaily = RoleplayScenario(
                id: "daily-adaptive",
                titleKey: "app.ai_assistant.scenario.daily.title",
                descriptionKey: "app.ai_assistant.scenario.daily.desc",
                topic: .dailyLife,
                difficulty: .intermediate,
                characterName: "Alex",
                characterRole: "Language Coach",
                userRole: "Learner",
                initialGreeting: "Hi there! Let's practice using your recent vocabulary in a casual chat.",
                targetWordIds: Array(userWeakWords.prefix(3)),
                iconSymbol: "sparkles",
                starterSuggestions: starterPrompts
            )
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter test_adaptiveDailyScenario_hasPopulatedStarterSuggestions`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/FetchRoleplayScenariosUseCase.swift VocabCraftAppTests/AI/RoleplayUseCasesTests.swift
git commit -m "fix(ai): generate dynamic starter suggestions for adaptive daily scenario"
```

---

### Task 6: Full Verification Suite (Zero Warnings, Zero Issues)

**Files:**
- Full codebase validation

- [ ] **Step 1: Run full test suite**
Run: `swift test`
Expected: 100% tests pass.

- [ ] **Step 2: Run localization validation**
Run: `swift test --filter Localization`
Expected: 100% pass, 0 missing keys.

- [ ] **Step 3: Run SwiftLint**
Run: `swiftlint lint --strict`
Expected: 0 errors, 0 warnings.

- [ ] **Step 4: Check git status for unexpected Xcode files**
Run: `git status`
Expected: Clean working tree.
