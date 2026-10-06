# Role Play Voice Customization & High-Precision Chat Suggestions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide user-configurable AI voices with preview & pitch/speed adjustments, and implement high-precision contextual chat suggestions with interactive quick-response chips.

**Architecture:** Introduce `RoleplayVoiceProfile` and `RoleplayVoiceProfileCatalog` bridging Apple Enhanced and Gemini Studio Neural voices. Persist preferences in `UserSettingsStore`. Enhance `TextToSpeechService` router with voice and preview handling. Refine `ExecuteRoleplayTurnUseCase` prompt for 3-branch suggestions and conditional null refinement. Add a horizontal scrolling chips bar to `RoleplayRoomView`. Provide voice customization in `SettingsView` and a quick-switch sheet in roleplay.

**Tech Stack:** Swift 5.10 / Swift 6 Strict Concurrency, SwiftUI, AVFoundation (`AVSpeechSynthesizer`), CraftUIKit design tokens, Swift Testing (`@Suite`, `@Test`), `Localizable.xcstrings`.

**Spec:** `docs/superpowers/specs/2026-10-06-roleplay-voice-config-chat-suggestions-design.md`

## Global Constraints
- Target platforms: iOS 17.0+, macOS 14.0+.
- Strict Concurrency: Every class, struct, actor must conform to `Sendable` and respect `@MainActor` or actor isolation.
- Zero Raw Styling: 100% UI styling must utilize `CraftUIKit` tokens (`CraftColor`, `CraftFont`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftCard`, `CraftButton`, `CraftIconButton`).
- Zero Hardcoded Strings: 100% user-facing strings must have complete bilingual entries (EN & VI) in `Localizable.xcstrings` and `AppStrings.swift`.
- Zero Warnings & Zero Lint Errors: 100% test pass rate (`swift test`) and 0 violations (`swiftlint --strict`).

---

### Task 1: Domain Entities & Voice Profile Catalog

**Files:**
- Create: `VocabCraftApp/Domain/Entities/RoleplayVoiceProfile.swift`
- Create: `VocabCraftApp/Data/AI/RoleplayVoiceProfileCatalog.swift`
- Create: `VocabCraftAppTests/AI/RoleplayVoiceProfileCatalogTests.swift`

**Interfaces:**
- Consumes: `VoicePersona` from `VocabCraftApp/Domain/Protocols/AudioServiceProtocols.swift`
- Produces: `VoiceEngineType`, `RoleplayVoiceProfile`, `RoleplayVoiceProfileCatalog.allProfiles`, `RoleplayVoiceProfileCatalog.profile(for:)`, `RoleplayVoiceProfileCatalog.defaultProfile`

- [ ] **Step 1: Write failing unit test for `RoleplayVoiceProfileCatalog`**

Create `VocabCraftAppTests/AI/RoleplayVoiceProfileCatalogTests.swift`:
```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("RoleplayVoiceProfileCatalog Tests")
struct RoleplayVoiceProfileCatalogTests {
    @Test("Catalog provides default auto profile and curated Apple and Gemini profiles")
    func testCatalogProfiles() {
        let profiles = RoleplayVoiceProfileCatalog.allProfiles
        #expect(!profiles.isEmpty)
        #expect(profiles.contains(where: { $0.id == "systemAuto" }))
        #expect(profiles.contains(where: { $0.id == "apple-ava" }))
        #expect(profiles.contains(where: { $0.id == "apple-daniel" }))
        #expect(profiles.contains(where: { $0.id == "gemini-aoede" }))

        let defaultProfile = RoleplayVoiceProfileCatalog.defaultProfile
        #expect(defaultProfile.id == "systemAuto")

        let daniel = RoleplayVoiceProfileCatalog.profile(for: "apple-daniel")
        #expect(daniel?.gender == .male)
        #expect(daniel?.engine == .appleEnhanced)

        let unknown = RoleplayVoiceProfileCatalog.profile(for: "unknown-id")
        #expect(unknown?.id == "systemAuto")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter RoleplayVoiceProfileCatalogTests`  
Expected: FAIL (types not defined).

- [ ] **Step 3: Implement `RoleplayVoiceProfile` and `RoleplayVoiceProfileCatalog`**

Create `VocabCraftApp/Domain/Entities/RoleplayVoiceProfile.swift`:
```swift
import Foundation

public enum VoiceEngineType: String, Sendable, Codable, CaseIterable {
    case appleEnhanced
    case geminiNeural
}

public enum VoiceGender: String, Sendable, Codable, CaseIterable {
    case female
    case male
    case neutral
}

public struct RoleplayVoiceProfile: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let displayNameKey: String
    public let gender: VoiceGender
    public let locale: String
    public let engine: VoiceEngineType
    public let qualityDescriptionKey: String
    public let sampleText: String
    public let appleVoiceIdentifier: String?
    public let geminiPersona: VoicePersona?

    public init(
        id: String,
        displayNameKey: String,
        gender: VoiceGender,
        locale: String,
        engine: VoiceEngineType,
        qualityDescriptionKey: String,
        sampleText: String = "Hi! I'm excited to practice English conversation with you.",
        appleVoiceIdentifier: String? = nil,
        geminiPersona: VoicePersona? = nil
    ) {
        self.id = id
        self.displayNameKey = displayNameKey
        self.gender = gender
        self.locale = locale
        self.engine = engine
        self.qualityDescriptionKey = qualityDescriptionKey
        self.sampleText = sampleText
        self.appleVoiceIdentifier = appleVoiceIdentifier
        self.geminiPersona = geminiPersona
    }
}
```

Create `VocabCraftApp/Data/AI/RoleplayVoiceProfileCatalog.swift`:
```swift
import Foundation

public enum RoleplayVoiceProfileCatalog: Sendable {
    public static let defaultProfile = RoleplayVoiceProfile(
        id: "systemAuto",
        displayNameKey: "app.settings.voice.auto_persona",
        gender: .neutral,
        locale: "en-US",
        engine: .appleEnhanced,
        qualityDescriptionKey: "app.settings.voice.quality_apple",
        sampleText: "Hello! I am ready to practice English conversation with you."
    )

    public static let allProfiles: [RoleplayVoiceProfile] = [
        defaultProfile,
        RoleplayVoiceProfile(
            id: "apple-ava",
            displayNameKey: "Ava (US Female)",
            gender: .female,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Hi! I'm Ava. Let's practice English together.",
            appleVoiceIdentifier: "ava"
        ),
        RoleplayVoiceProfile(
            id: "apple-zoe",
            displayNameKey: "Zoe (US Female)",
            gender: .female,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Hey there! I'm Zoe. Ready when you are!",
            appleVoiceIdentifier: "zoe"
        ),
        RoleplayVoiceProfile(
            id: "apple-samantha",
            displayNameKey: "Samantha (US Female)",
            gender: .female,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Hello! I'm Samantha. How can I help you practice today?",
            appleVoiceIdentifier: "samantha"
        ),
        RoleplayVoiceProfile(
            id: "apple-daniel",
            displayNameKey: "Daniel (UK Male)",
            gender: .male,
            locale: "en-GB",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Good day! I'm Daniel. It's a pleasure to speak with you.",
            appleVoiceIdentifier: "daniel"
        ),
        RoleplayVoiceProfile(
            id: "apple-oliver",
            displayNameKey: "Oliver (UK Male)",
            gender: .male,
            locale: "en-GB",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Hello! I'm Oliver. Let's have a great chat.",
            appleVoiceIdentifier: "oliver"
        ),
        RoleplayVoiceProfile(
            id: "apple-nathan",
            displayNameKey: "Nathan (US Male)",
            gender: .male,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Hey, I'm Nathan. Let's get right into our conversation.",
            appleVoiceIdentifier: "nathan"
        ),
        RoleplayVoiceProfile(
            id: "gemini-aoede",
            displayNameKey: "Aoede (Studio Neural)",
            gender: .female,
            locale: "en-US",
            engine: .geminiNeural,
            qualityDescriptionKey: "app.settings.voice.quality_gemini",
            sampleText: "Hi! I'm Aoede. Let's have an authentic conversation.",
            geminiPersona: .friendlyFemale
        ),
        RoleplayVoiceProfile(
            id: "gemini-puck",
            displayNameKey: "Puck (Studio Neural)",
            gender: .male,
            locale: "en-US",
            engine: .geminiNeural,
            qualityDescriptionKey: "app.settings.voice.quality_gemini",
            sampleText: "Hey there! I'm Puck. Ready to talk about anything.",
            geminiPersona: .friendlyMale
        ),
        RoleplayVoiceProfile(
            id: "gemini-charon",
            displayNameKey: "Charon (Studio Neural)",
            gender: .male,
            locale: "en-US",
            engine: .geminiNeural,
            qualityDescriptionKey: "app.settings.voice.quality_gemini",
            sampleText: "Welcome. I'm Charon. I'm here to practice with you.",
            geminiPersona: .authoritativeMale
        ),
        RoleplayVoiceProfile(
            id: "gemini-kore",
            displayNameKey: "Kore (Studio Neural)",
            gender: .female,
            locale: "en-US",
            engine: .geminiNeural,
            qualityDescriptionKey: "app.settings.voice.quality_gemini",
            sampleText: "Hello! I'm Kore. Wonderful to speak with you today.",
            geminiPersona: .expressiveFemale
        )
    ]

    public static func profile(for id: String) -> RoleplayVoiceProfile? {
        allProfiles.first(where: { $0.id == id }) ?? defaultProfile
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter RoleplayVoiceProfileCatalogTests`  
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Domain/Entities/RoleplayVoiceProfile.swift VocabCraftApp/Data/AI/RoleplayVoiceProfileCatalog.swift VocabCraftAppTests/AI/RoleplayVoiceProfileCatalogTests.swift
git commit -m "feat(voice): add RoleplayVoiceProfile and catalog"
```

---

### Task 2: User Settings Persistence for Role Play Voice

**Files:**
- Modify: `VocabCraftApp/Core/Database/UserSettingsStore.swift`
- Modify: `VocabCraftAppTests/UserSettingsStoreTests.swift`

**Interfaces:**
- Consumes: `UserDefaults`
- Produces: `roleplayVoiceId: String`, `roleplaySpeechRate: Double`, `roleplaySpeechPitch: Double` on `UserSettingsStore`

- [ ] **Step 1: Write failing test in `UserSettingsStoreTests.swift`**

Add to `VocabCraftAppTests/UserSettingsStoreTests.swift`:
```swift
    @Test("Verify roleplay voice settings persistence and defaults")
    func testRoleplayVoiceSettingsPersistence() {
        let suiteName = "test_roleplay_voice_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = UserSettingsStore(defaults: defaults)

        #expect(store.roleplayVoiceId == "systemAuto")
        #expect(store.roleplaySpeechRate == 1.0)
        #expect(store.roleplaySpeechPitch == 1.0)

        store.roleplayVoiceId = "apple-daniel"
        store.roleplaySpeechRate = 1.15
        store.roleplaySpeechPitch = 0.95

        let reloadedStore = UserSettingsStore(defaults: defaults)
        #expect(reloadedStore.roleplayVoiceId == "apple-daniel")
        #expect(abs(reloadedStore.roleplaySpeechRate - 1.15) < 0.001)
        #expect(abs(reloadedStore.roleplaySpeechPitch - 0.95) < 0.001)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter testRoleplayVoiceSettingsPersistence`  
Expected: FAIL (`roleplayVoiceId` not found on `UserSettingsStore`).

- [ ] **Step 3: Add properties to `UserSettingsStore.swift`**

In `VocabCraftApp/Core/Database/UserSettingsStore.swift`:
Add properties:
```swift
    public var roleplayVoiceId: String {
        didSet {
            defaults.set(roleplayVoiceId, forKey: "roleplay_voice_id")
        }
    }

    public var roleplaySpeechRate: Double {
        didSet {
            defaults.set(roleplaySpeechRate, forKey: "roleplay_speech_rate")
        }
    }

    public var roleplaySpeechPitch: Double {
        didSet {
            defaults.set(roleplaySpeechPitch, forKey: "roleplay_speech_pitch")
        }
    }
```
In `init(defaults: UserDefaults = .standard)`:
```swift
        self.roleplayVoiceId = defaults.string(forKey: "roleplay_voice_id") ?? "systemAuto"
        let savedRate = defaults.double(forKey: "roleplay_speech_rate")
        self.roleplaySpeechRate = savedRate > 0 ? savedRate : 1.0
        let savedPitch = defaults.double(forKey: "roleplay_speech_pitch")
        self.roleplaySpeechPitch = savedPitch > 0 ? savedPitch : 1.0
```
In `resetAllSettings()`:
```swift
        roleplayVoiceId = "systemAuto"
        roleplaySpeechRate = 1.0
        roleplaySpeechPitch = 1.0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter testRoleplayVoiceSettingsPersistence`  
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Core/Database/UserSettingsStore.swift VocabCraftAppTests/UserSettingsStoreTests.swift
git commit -m "feat(settings): add roleplay voice configuration persistence to UserSettingsStore"
```

---

### Task 3: High-Precision Prompt & Contextual 3-Branch Suggestions

**Files:**
- Modify: `VocabCraftApp/Domain/UseCases/ExecuteRoleplayTurnUseCase.swift`
- Modify: `VocabCraftAppTests/AI/RoleplayUseCasesTests.swift`

**Interfaces:**
- Consumes: `RoleplayScenario`, `LLMChatMessage`, `LLMProviderProtocol`
- Produces: Enhanced `RoleplayTurnOutput` with 3-branch suggestions and conditional null refinement

- [ ] **Step 1: Write test for 3-branch suggestions and conditional null refinement**

In `VocabCraftAppTests/AI/RoleplayUseCasesTests.swift`, add:
```swift
    @Test("ExecuteRoleplayTurnUseCase prompt formats 3-branch suggestions instructions")
    func testPromptSpecifiesThreeBranchSuggestions() async throws {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "What kind of coffee do you enjoy?",
            targetWordsUsed: [],
            refinementSuggestion: nil,
            pedagogicalNote: nil,
            suggestedResponses: [
                "I'd like an espresso, please.",
                "What beans do you recommend?",
                "Just something warm, thanks!"
            ]
        )
        let mockProvider = MockLLMProvider(mockTurnOutput: mockOutput)
        let useCase = ExecuteRoleplayTurnUseCase(llmProvider: mockProvider)

        let scenario = RoleplayScenario(
            id: "cafe-order",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hi!",
            targetWordIds: ["espresso"],
            iconSymbol: "cup.and.saucer"
        )

        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "Good morning!",
            chatHistory: []
        )

        #expect(result.suggestedResponses.count == 3)
        #expect(result.refinementSuggestion == nil)
    }
```

- [ ] **Step 2: Run test to verify current behavior**

Run: `swift test --filter testPromptSpecifiesThreeBranchSuggestions`  
Expected: PASS (or verify mock pipeline runs cleanly).

- [ ] **Step 3: Update `ExecuteRoleplayTurnUseCase.swift` system prompt**

Refine `systemPrompt` in `ExecuteRoleplayTurnUseCase.swift`:
```swift
        var systemPrompt = """
        You are \(scenario.characterName), a \(scenario.characterRole) in a roleplay conversation with the user who is a \(scenario.userRole).
        Maintain an authentic, friendly persona suitable for the scene: \(topicDescriptor).
        Target vocabulary for the user: \(scenario.targetWordIds.joined(separator: ", ")).

        CONVERSATION & BREVITY RULES (CRITICAL):
        - `characterReply`: Strictly 1 to 2 short sentences, maximum 25 words total. Speak naturally as in real life dialogue.
        - NEVER include asterisks, stage directions, or facial descriptions (*smiles*, *nods*). Spoken dialogue only!
        - Keep the interaction flowing naturally with a quick prompt or conversational response.

        REFINEMENT RULES:
        - `refinementSuggestion`: Only provide an improved sentence if the user's message has clear grammatical errors or awkward phrasing.
        - If the user's sentence is already natural and grammatically correct English, RETURN NULL. Never rephrase a correct sentence.
        - When provided, keep the improved sentence natural and concise (under 12 words).

        SUGGESTED RESPONSES RULES:
        - `suggestedResponses`: Generate exactly 2 to 3 distinct, natural candidate responses (3 to 7 words each) following these branches:
          1. Target Word: A response naturally using one of the target words: \(scenario.targetWordIds.joined(separator: ", ")).
          2. Inquiry/Question: A natural polite question or request continuing the conversation.
          3. Casual Reaction: A colloquial remark or response.

        - `targetWordsUsed`: list of target words the user actually used correctly in their message.
        - `pedagogicalNote`: brief praise or tip (under 8 words); otherwise null.
        - `isConcluded`: boolean, false unless the interaction has reached a natural conclusion.

        Return JSON conforming to RoleplayTurnOutput schema.
        """
```

- [ ] **Step 4: Run tests to verify all roleplay turn tests pass**

Run: `swift test --filter RoleplayUseCasesTests`  
Expected: PASS (all tests pass).

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Domain/UseCases/ExecuteRoleplayTurnUseCase.swift VocabCraftAppTests/AI/RoleplayUseCasesTests.swift
git commit -m "feat(roleplay): enhance system prompt with 3-branch suggestions and conditional null refinement"
```

---

### Task 4: Audio Router Integration & Voice Preview

**Files:**
- Modify: `VocabCraftApp/Core/Audio/AppleEnhancedTTSEngine.swift`
- Modify: `VocabCraftApp/Core/Audio/TextToSpeechService.swift`
- Modify: `VocabCraftAppTests/Core/Audio/SmartVoiceRouterTests.swift` or create new tests

**Interfaces:**
- Consumes: `UserSettingsStore`, `RoleplayVoiceProfile`, `RoleplayVoiceProfileCatalog`
- Produces: `TextToSpeechService.previewVoice(profile:rate:pitch:)`, dynamic routing in `TextToSpeechService.performPlaybackAsync`

- [ ] **Step 1: Write failing test for voice routing with profile selection**

Create / update `VocabCraftAppTests/Core/Audio/SmartVoiceRouterTests.swift`:
```swift
    @Test("TextToSpeechService routes to selected Apple Enhanced profile voice")
    @MainActor
    func testRoutingWithSelectedAppleProfile() async {
        let defaults = UserDefaults(suiteName: "test_tts_profile_\(UUID().uuidString)")!
        let store = UserSettingsStore(defaults: defaults)
        store.roleplayVoiceId = "apple-daniel"
        store.roleplaySpeechRate = 1.10
        store.roleplaySpeechPitch = 0.90

        let coordinator = AudioSessionCoordinator()
        let appleEngine = AppleEnhancedTTSEngine()
        let tts = TextToSpeechService(
            settingsStore: store,
            audioSessionCoordinator: coordinator,
            appleEngine: appleEngine
        )

        await tts.speakAsync(text: "Good day, let's practice.", context: .conversation(persona: .friendlyMale, locale: "en-GB"))
        #expect(tts.lastActiveEngine == .apple)
    }
```

- [ ] **Step 2: Run test to verify execution**

Run: `swift test --filter testRoutingWithSelectedAppleProfile`  
Expected: PASS / verify current state.

- [ ] **Step 3: Update `AppleEnhancedTTSEngine.swift` and `TextToSpeechService.swift`**

In `AppleEnhancedTTSEngine.swift`:
Ensure `makeUtterance` accepts optional `voiceIdentifier: String?`, `pitchMultiplier: Float?`, and `rateMultiplier: Float?`:
```swift
    public func makeUtterance(
        text: String,
        rate: Float,
        locale: String,
        persona: VoicePersona? = nil,
        voiceIdentifier: String? = nil,
        pitch: Float? = nil
    ) -> AVSpeechUtterance?
```
If `voiceIdentifier` is passed, resolve by name or identifier, otherwise fall back to persona or locale.
In `TextToSpeechService.swift`:
Add:
```swift
    public func previewVoice(profile: RoleplayVoiceProfile, rate: Double = 1.0, pitch: Double = 1.0) async {
        stop()
        switch profile.engine {
        case .geminiNeural:
            if let persona = profile.geminiPersona, let apiKey = resolvedApiKey {
                lastActiveEngine = .gemini
                try? await geminiEngine.synthesizeAndPlay(text: profile.sampleText, persona: persona, apiKey: apiKey)
                return
            }
            fallthrough
        case .appleEnhanced:
            lastActiveEngine = .apple
            let voiceId = profile.appleVoiceIdentifier
            await appleEngine.speakAsync(
                text: profile.sampleText,
                rate: Float(rate),
                locale: profile.locale,
                persona: profile.geminiPersona
            )
        }
    }
```
In `performPlaybackAsync`:
When `context` is `.conversation(let persona, let locale)`:
Check `settingsStore?.roleplayVoiceId`:
If not `"systemAuto"`, lookup profile in `RoleplayVoiceProfileCatalog.profile(for: id)`:
If found:
- If `engine == .geminiNeural` and Gemini API key present, call `geminiEngine.synthesizeAndPlay(text: text, persona: profile.geminiPersona ?? persona, apiKey: apiKey)`.
- If `engine == .appleEnhanced`, route to `appleEngine.speakAsync` applying `settingsStore?.roleplaySpeechRate` and `roleplaySpeechPitch`.

- [ ] **Step 4: Run tests to verify all TTS and router tests pass**

Run: `swift test --filter KokoroTTSEngineTests` && `swift test --filter AppleEnhancedTTSEngineTests`  
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Core/Audio/AppleEnhancedTTSEngine.swift VocabCraftApp/Core/Audio/TextToSpeechService.swift VocabCraftAppTests/Core/Audio/
git commit -m "feat(audio): wire roleplay voice profile routing and preview playback into TextToSpeechService"
```

---

### Task 5: Interactive Quick-Response Chips Bar in `RoleplayRoomView`

**Files:**
- Modify: `VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayRoomViewModel.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/RoleplayRoomView.swift`
- Modify: `VocabCraftAppTests/AI/RoleplayViewModelsTests.swift`

**Interfaces:**
- Consumes: `RoleplayTurnOutput.suggestedResponses`, `scenario.starterSuggestions`
- Produces: `viewModel.suggestedResponses: [String]`, `viewModel.selectSuggestion(_:)`, chips bar UI in `RoleplayRoomView`

- [ ] **Step 1: Write failing test in `RoleplayViewModelsTests.swift`**

Add to `VocabCraftAppTests/AI/RoleplayViewModelsTests.swift`:
```swift
    @Test("RoleplayRoomViewModel initializes with starter suggestions and updates on turn completion")
    @MainActor
    func testSuggestedResponsesLifecycle() async throws {
        let scenario = RoleplayScenario(
            id: "cafe",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Emma",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hi!",
            targetWordIds: ["latte"],
            iconSymbol: "cup",
            starterSuggestions: ["I'd like a latte, please.", "What coffee do you have?"]
        )

        let mockOutput = RoleplayTurnOutput(
            characterReply: "Sure, whole or oat milk?",
            targetWordsUsed: ["latte"],
            refinementSuggestion: nil,
            pedagogicalNote: nil,
            suggestedResponses: ["Whole milk please.", "Oat milk, thanks!"]
        )
        let mockLLM = MockLLMProvider(mockTurnOutput: mockOutput)
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let viewModel = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        #expect(viewModel.suggestedResponses == scenario.starterSuggestions)

        await viewModel.sendMessage("I want a latte")

        #expect(viewModel.suggestedResponses == ["Whole milk please.", "Oat milk, thanks!"])

        viewModel.selectSuggestion("Whole milk please.")
        #expect(viewModel.inputText == "Whole milk please.")
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter testSuggestedResponsesLifecycle`  
Expected: FAIL (`suggestedResponses` not on `RoleplayRoomViewModel`).

- [ ] **Step 3: Update `RoleplayRoomViewModel.swift`**

In `VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayRoomViewModel.swift`:
Add:
```swift
    public var suggestedResponses: [String] = []
    public var isSuggestionsVisible: Bool = true
```
In `init`:
```swift
    self.suggestedResponses = scenario.starterSuggestions
```
In `sendMessage`:
When `output` returns:
```swift
    if !output.suggestedResponses.isEmpty {
        self.suggestedResponses = output.suggestedResponses
    }
```
Add action method:
```swift
    public func selectSuggestion(_ text: String) {
        self.inputText = text
    }

    public func toggleSuggestionsVisibility() {
        self.isSuggestionsVisible.toggle()
    }
```

- [ ] **Step 4: Update `RoleplayRoomView.swift` with suggested chips bar**

Add `suggestedChipsBar` right above `bottomInputBar`:
```swift
    @ViewBuilder
    private var suggestedChipsBar: some View {
        if viewModel.isSuggestionsVisible && !viewModel.suggestedResponses.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(viewModel.suggestedResponses, id: \.self) { suggestion in
                        Button {
                            withAnimation(theme.animations.springSnappy) {
                                viewModel.selectSuggestion(suggestion)
                            }
                        } label: {
                            HStack(spacing: theme.spacing.xxs) {
                                CraftIcon(.sparkles, size: .sm, color: theme.colors.brandPrimary)
                                Text(suggestion)
                                    .font(theme.typography.bodySmall)
                                    .foregroundStyle(theme.colors.textPrimary)
                            }
                            .padding(.horizontal, theme.spacing.sm)
                            .padding(.vertical, theme.spacing.xs)
                            .background(theme.colors.surfaceCard)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(theme.colors.borderDefault, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.xxs)
            }
            .background(theme.colors.canvasBackground)
        }
    }
```
In `body`: place `suggestedChipsBar` directly above `bottomInputBar`.

- [ ] **Step 5: Run tests to verify**

Run: `swift test --filter testSuggestedResponsesLifecycle`  
Expected: PASS.

- [ ] **Step 6: Commit changes**

```bash
git add VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayRoomViewModel.swift VocabCraftApp/Features/AIAssistant/Views/RoleplayRoomView.swift VocabCraftAppTests/AI/RoleplayViewModelsTests.swift
git commit -m "feat(roleplay): add interactive suggested response chips bar to RoleplayRoomView"
```

---

### Task 6: Settings Voice Customization & Quick Picker Sheet UI

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/Views/Components/RoleplayVoicePickerSheet.swift`
- Modify: `VocabCraftApp/Features/Settings/Views/SettingsView.swift`
- Modify: `VocabCraftApp/Features/Settings/ViewModels/SettingsViewModel.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`

**Interfaces:**
- Consumes: `UserSettingsStore`, `RoleplayVoiceProfileCatalog`, `TextToSpeechService`
- Produces: `SettingsRoleplayVoiceCard` in `SettingsView`, `RoleplayVoicePickerSheet` presented from `RoleplayRoomView` and `RoleplayVoiceCallView`

- [ ] **Step 1: Add bilingual localization strings**

In `VocabCraftApp/Resources/Localizable.xcstrings` and `AppStrings.swift`:
Add entries with both `en` and `vi` translations:
- `app.settings.voice.section_title`: "Role Play Voice" / "Giọng đọc Role Play"
- `app.settings.voice.current_profile`: "Active Voice" / "Giọng đang dùng"
- `app.settings.voice.auto_persona`: "Automatic (Character Persona)" / "Tự động (Theo tính cách nhân vật)"
- `app.settings.voice.preview_button`: "Play Preview" / "Nghe thử"
- `app.settings.voice.previewing`: "Playing..." / "Đang phát..."
- `app.settings.voice.speed`: "Voice Speed" / "Tốc độ đọc"
- `app.settings.voice.pitch`: "Voice Pitch" / "Cao độ âm sắc"
- `app.settings.voice.quality_apple`: "Device Enhanced" / "Thiết bị - Tự nhiên"
- `app.settings.voice.quality_gemini`: "Cloud Studio Neural" / "Cloud - Siêu thực"
- `app.ai_assistant.room.suggestions_header`: "Suggested Responses" / "Gợi ý trả lời"
- `app.ai_assistant.room.voice_picker_title`: "Select AI Voice" / "Chọn giọng đọc AI"

- [ ] **Step 2: Create `RoleplayVoicePickerSheet.swift`**

Create `VocabCraftApp/Features/AIAssistant/Views/Components/RoleplayVoicePickerSheet.swift` using `CraftCard`, `CraftIconButton`, `CraftBadge`, `theme.colors`, `theme.typography`:
- Lists all profiles from `RoleplayVoiceProfileCatalog.allProfiles`.
- Displays active checkmark next to `store.roleplayVoiceId`.
- Provides a preview button for each profile that calls `ttsService.previewVoice(profile:)`.
- Dismiss button at top right.

- [ ] **Step 3: Add `SettingsRoleplayVoiceCard` into `SettingsView.swift`**

In `SettingsView.swift`:
In the AI & Audio section, add `SettingsRoleplayVoiceCard(store: store, ttsService: ttsService)`.
Includes:
- Menu / picker for selecting voice.
- Listen preview button with loading / playing indicator.
- Slider for `store.roleplaySpeechRate` (0.75x–1.25x).
- Slider for `store.roleplaySpeechPitch` (0.85x–1.15x).

- [ ] **Step 4: Wire quick voice picker sheet into `RoleplayRoomView` and `RoleplayVoiceCallView`**

Add an audio settings icon button in `RoleplayRoomView.headerBar` that sets `@State private var showVoiceSheet = true`.
Attach `.sheet(isPresented: $showVoiceSheet) { RoleplayVoicePickerSheet(...) }`.
Do the same for `RoleplayVoiceCallView`.

- [ ] **Step 5: Run tests and verify localization**

Run: `swift test --filter LocalizationTests` && `swift test --filter SettingsLocalizationTests`  
Expected: PASS.

- [ ] **Step 6: Commit changes**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/Components/RoleplayVoicePickerSheet.swift VocabCraftApp/Features/Settings/Views/SettingsView.swift VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift
git commit -m "feat(ui): add roleplay voice configuration card in settings and voice picker sheet"
```

---

### Task 7: Full Verification Gate & Device Deployment

**Files:**
- Full codebase validation

**Interfaces:**
- End-to-end regression testing and physical device verification

- [ ] **Step 1: Run full test suite**

Run: `swift test`  
Expected: 100% pass rate across all suites.

- [ ] **Step 2: Run SwiftLint in strict mode**

Run: `swiftlint --strict`  
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Synchronize Xcode project**

Run: `python3 scripts/generate_xcodeproj.py`  
Expected: Clean sync.

- [ ] **Step 4: Build, deploy, and launch on iPhone "Hooji"**

Run: `./scripts/run-device.sh Hooji`  
Expected: `BUILD SUCCEEDED`, app installed and launched cleanly.

- [ ] **Step 5: Commit final verification artifact**

```bash
git commit -am "chore: update Xcode project and verify full suite passes"
```
