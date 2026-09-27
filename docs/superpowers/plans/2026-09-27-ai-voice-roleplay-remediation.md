# AI Voice Roleplay Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remediate critical audio synchronization traps, fix broken test suite assertions, wire SRS data persistence, dynamically align Mock LLM target word matching, decouple Voice Orb animation, and eliminate UI layout shift in the AI Voice Roleplay feature.

**Architecture:** Refactor `TurnBasedVoiceConversationEngine` for safe mute transitions, error recovery, and non-destructive silence detection; update `IntelligentMockLLMProvider` for dynamic scenario target word detection; inject `VocabularyDataSourceProtocol` into `CompleteRoleplaySessionUseCase` to map word lemmas to `Int64` IDs and persist mastery into `UserProgressRepository`; decouple `CraftVoiceOrbView` continuous breathing animation from transcript mutations; and stabilize `RoleplayVoiceCallView` control bar layout with dual-line context subtitles and pre-flight microphone permission checks.

**Tech Stack:** Swift 6, SwiftUI (Observation, `PhaseAnimator`, `@Bindable`), SpeechKit (`SilenceDetector`), AVFoundation (`TextToSpeechService`, `SpeechRecognitionService`, `AudioSessionCoordinator`), SwiftData (`UserProgressRepositoryProtocol`), CraftUIKit design tokens.

**Spec:** `docs/superpowers/specs/2026-09-27-ai-voice-roleplay-remediation-design.md`

## Global Constraints

- **Strict 0 Test Failures**: Every task must maintain or advance test passing rates (`swift test`).
- **Strict 0 Lint Violations**: All Swift files must pass `swiftlint` without errors or warnings.
- **Strict 0 Compiler Warnings**: Xcode compilation (`xcodebuild`) must succeed with 0 warnings.
- **CraftUIKit-First & Token Discipline**: Zero raw colors (`Color.red`, `Color(hex:)`), raw fonts (`.system(size:)`), or raw padding values; use `CraftColor`, `CraftFont`, `CraftSpacingTokens`, `CraftRadiusTokens`.
- **Zero Hardcoded Strings**: All user-facing strings must reside in `Localizable.xcstrings` under `app.ai_assistant.*` with 100% bilingual parity (`en` and `vi`).

---

### Task 1: Fix Test Suite Alignment in `AppContainerAITests.swift`

**Files:**
- Modify: `VocabCraftAppTests/App/AppContainerAITests.swift:36-74`

**Interfaces:**
- Consumes: `AppContainer.llmProvider: LLMProviderProtocol`
- Produces: 100% passing tests for `AppContainerAITests`

- [ ] **Step 1: Inspect the failing assertions**

In `VocabCraftAppTests/App/AppContainerAITests.swift`, `container.llmProvider is MockLLMProvider` fails because `AppContainer` defaults to `IntelligentMockLLMProvider`.

- [ ] **Step 2: Update assertions to support IntelligentMockLLMProvider**

Update `AppContainerAITests.swift` lines 41-51 and 59-73:
```swift
        // Initially empty key -> fallback mock provider (IntelligentMockLLMProvider or MockLLMProvider)
        #expect(container.llmProvider is IntelligentMockLLMProvider || container.llmProvider is MockLLMProvider)

        // Set API Key -> GeminiLLMProvider
        store.geminiApiKey = "AIzaSyFakeTestKey12345"
        #expect(container.llmProvider is GeminiLLMProvider)

        // Clear API Key -> fallback mock provider
        store.geminiApiKey = ""
        #expect(container.llmProvider is IntelligentMockLLMProvider || container.llmProvider is MockLLMProvider)
```
And in `testDynamicLLMProviderWhitespaceAndPersistence`:
```swift
        // Whitespace only treated as empty -> fallback mock provider
        store1.geminiApiKey = "   \n  \t  "
        #expect(container.llmProvider is IntelligentMockLLMProvider || container.llmProvider is MockLLMProvider)
```

- [ ] **Step 3: Run AppContainerAITests to verify it passes**

Run: `swift test --filter AppContainerAITests`  
Expected: PASS (0 issues).

- [ ] **Step 4: Commit**

```bash
git add VocabCraftAppTests/App/AppContainerAITests.swift
git commit -m "test(ai): align AppContainerAITests with default IntelligentMockLLMProvider"
```

---

### Task 2: Dynamic Target Word Detection & Scenario Alignment in `IntelligentMockLLMProvider`

**Files:**
- Modify: `VocabCraftApp/Data/AI/IntelligentMockLLMProvider.swift`
- Modify: `VocabCraftAppTests/AI/IntelligentMockLLMProviderTests.swift`

**Interfaces:**
- Consumes: `systemPrompt: String`, `messages: [LLMChatMessage]`
- Produces: `extractTargetWords(from:expectedWords:) -> [String]`, `sendStructuredMessage` matching scenario target words (`beverage`, `pastry`, `innovative`, `initiative`, `accommodate`, etc.)

- [ ] **Step 1: Write failing tests for catalog scenario words**

In `VocabCraftAppTests/AI/IntelligentMockLLMProviderTests.swift`, add tests asserting that saying `"I want a beverage and a pastry"` returns `targetWordsUsed` containing `"beverage"` and `"pastry"`, and saying `"We need to accommodate the reservation"` returns `"accommodate"` and `"reservation"`:
```swift
    @Test("Detects dynamic catalog target words for Cafe scenario")
    func detectsCatalogCafeWords() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Could I please order a hot beverage and a fresh pastry?")
        ]
        let systemPrompt = "You are Emma, a Barista. Target vocabulary for the user: beverage, pastry, complimentary."
        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            responseSchema: RoleplayTurnOutput.self
        )
        #expect(output.targetWordsUsed.contains("beverage"))
        #expect(output.targetWordsUsed.contains("pastry"))
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter detectsCatalogCafeWords`  
Expected: FAIL (targetWordsUsed does not contain "beverage").

- [ ] **Step 3: Implement dynamic word extraction in `IntelligentMockLLMProvider`**

In `IntelligentMockLLMProvider.swift`:
1. Parse `systemPrompt` for `"Target vocabulary for the user: ..."`:
```swift
        var expectedWords: [String] = []
        if let range = systemPrompt.range(of: "Target vocabulary for the user:") {
            let substring = systemPrompt[range.upperBound...]
            let line = substring.split(separator: "\n").first ?? ""
            expectedWords = line.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
```
2. In `extractTargetWords(from:expectedWords:)`:
```swift
    public func extractTargetWords(from text: String, expectedWords: [String] = []) -> [String] {
        let catalogTargetWords = [
            "beverage", "pastry", "complimentary", "reservation", "amenities", "accommodate",
            "collaborate", "collaborating", "collaboration", "innovative", "initiative",
            "espresso", "croissant", "recommendation", "decaf", "receipt",
            "experience", "strength", "deadline", "leadership", "passport", "checkout"
        ]
        let combined = Set(expectedWords.map { $0.lowercased() } + catalogTargetWords)
        return combined.filter { word in
            text.localizedStandardContains(word)
        }.sorted()
    }
```
3. Update scenario matching conditions so `beverage`, `pastry`, `innovative`, `initiative`, `accommodate` branch into their respective Cafe, Hotel, and Interview dialogues rather than falling back.

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter IntelligentMockLLMProviderTests`  
Expected: PASS (all tests pass).

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/IntelligentMockLLMProvider.swift VocabCraftAppTests/AI/IntelligentMockLLMProviderTests.swift
git commit -m "feat(ai): dynamically extract and match catalog target words in IntelligentMockLLMProvider"
```

---

### Task 3: Refactor Audio Engine Lifecycle, Safe Mute & Error Handling

**Files:**
- Modify: `VocabCraftApp/Features/AIAssistant/Services/TurnBasedVoiceConversationEngine.swift`
- Modify: `VocabCraftAppTests/AI/TurnBasedVoiceConversationEngineTests.swift`

**Interfaces:**
- Consumes: `TextToSpeechProtocol`, `SpeechRecognitionProtocol`, `SilenceDetector`
- Produces: Safe mute state transitions, `audioErrorMessage: String?`, `retryListening()`, non-destructive manual turn finish, task cancellation

- [ ] **Step 1: Write failing tests for mute during speech and manual finish safety**

In `VocabCraftAppTests/AI/TurnBasedVoiceConversationEngineTests.swift`:
```swift
    @Test("Toggling mute while speaking transitions cleanly to listening state")
    func muteWhileSpeakingTransitionsCleanly() async {
        let mockTTS = MockTextToSpeech()
        let mockSpeech = MockSpeechRecognition()
        let engine = TurnBasedVoiceConversationEngine(
            scenario: makeTestScenario(),
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: makeExecuteUseCase(),
            completeSessionUseCase: makeCompleteUseCase()
        )
        mockTTS.onSpeakAsync = { _, _, _ in
            engine.toggleMute()
            #expect(engine.isMuted)
        }
        await engine.startCall()
        #expect(engine.state == .listening(liveTranscript: ""))
        #expect(!mockSpeech.isListening) // Mic should not be capturing while muted
    }

    @Test("finishUserTurnManually with empty transcript does not cancel silence detector")
    func finishTurnWithEmptyTranscriptPreservesDetector() async {
        let mockSpeech = MockSpeechRecognition()
        let engine = TurnBasedVoiceConversationEngine(
            scenario: makeTestScenario(),
            ttsService: MockTextToSpeech(),
            speechService: mockSpeech,
            executeTurnUseCase: makeExecuteUseCase(),
            completeSessionUseCase: makeCompleteUseCase()
        )
        engine.startListening()
        engine.finishUserTurnManually() // Empty transcript
        #expect(engine.state == .listening(liveTranscript: ""))
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter muteWhileSpeakingTransitionsCleanly`  
Expected: FAIL.

- [ ] **Step 3: Implement engine state lifecycle and error handling**

In `TurnBasedVoiceConversationEngine.swift`:
1. Add property `public private(set) var audioErrorMessage: String?`.
2. In `playCharacterSpeech(_ text: String)`:
```swift
        guard state != .ended else { return }
        silenceDetector?.cancel()
        state = .speaking(characterText: text)
        await ttsService.speakAsync(text: text)
        guard state != .ended else { return }
        if case .speaking = state {
            startListening()
        }
```
3. In `startListening()`:
```swift
        audioErrorMessage = nil
        state = .listening(liveTranscript: "")
        guard !isMuted else { return }
        // Set up silenceDetector and speechService...
```
4. In `toggleMute()`:
```swift
        isMuted.toggle()
        if isMuted {
            speechService.stopListening()
            silenceDetector?.cancel()
        } else {
            if case .listening = state {
                startListening()
            }
        }
```
5. In `finishUserTurnManually()`:
```swift
        guard case .listening(let transcript) = state else { return }
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        silenceDetector?.cancel()
        Task { @MainActor [weak self] in
            await self?.processUserUtterance(trimmed)
        }
```
6. In `speechService.startListening(onError:)`:
```swift
        onError: { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if case .listening(let transcript) = self.state,
                   !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await self.processUserUtterance(transcript)
                } else {
                    self.audioErrorMessage = error.localizedDescription
                    self.silenceDetector?.cancel()
                }
            }
        }
```
7. Add `public func retryListening()`:
```swift
    public func retryListening() {
        audioErrorMessage = nil
        startListening()
    }
```
8. Manage `activeSpeechTask = Task { ... }` in `startCall()` and `processUserUtterance()`. In `endCall()`, cancel `activeSpeechTask` and set to `nil`.

- [ ] **Step 4: Run engine test suite**

Run: `swift test --filter TurnBasedVoiceConversationEngineTests`  
Expected: PASS (all tests pass).

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Services/TurnBasedVoiceConversationEngine.swift VocabCraftAppTests/AI/TurnBasedVoiceConversationEngineTests.swift
git commit -m "fix(ai): ensure safe mute transition, error recovery and non-destructive silence detection in engine"
```

---

### Task 4: Integrate SRS Mastery Persistence & Accidental Call Guard

**Files:**
- Modify: `VocabCraftApp/Domain/UseCases/CompleteRoleplaySessionUseCase.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayVoiceCallViewModel.swift`
- Modify: `VocabCraftAppTests/AI/RoleplayUseCasesTests.swift`
- Modify: `VocabCraftAppTests/AI/RoleplayVoiceCallViewModelTests.swift`

**Interfaces:**
- Consumes: `VocabularyDataSourceProtocol`, `UserProgressRepositoryProtocol`, `UserSettingsStore`
- Produces: Persisted SRS mastery for `masteredWords`, XP award in `userSettingsStore`, accidental call early dismissal

- [ ] **Step 1: Write failing tests for progress saving and accidental call guard**

In `VocabCraftAppTests/AI/RoleplayUseCasesTests.swift`:
Assert that completing a session with mastered target words queries `VocabularyDataSource` and calls `recordChallengeResult(wordId:isCorrect:true)` on `UserProgressRepository`.
In `VocabCraftAppTests/AI/RoleplayVoiceCallViewModelTests.swift`:
Assert that calling `endCall()` when `totalTurns == 0` and elapsed time < 3s sets `isAccidentalDismissal = true` on the summary or leaves `sessionSummary = nil` and calls dismissal directly.

- [ ] **Step 2: Run tests to verify failure**

Run: `swift test --filter CompleteRoleplaySessionUseCaseTests`  
Expected: FAIL.

- [ ] **Step 3: Implement persistence and accidental call logic**

1. In `CompleteRoleplaySessionUseCase.swift`:
Add `vocabularyDataSource: (any VocabularyDataSourceProtocol)? = nil` to initializer.
In `execute(scenario:messages:masteredWords:)`:
```swift
        if let vocabularyDataSource, let userProgressRepository, !masteredWords.isEmpty {
            if let allWords = try? await vocabularyDataSource.fetchAllWordsMap() {
                let lemmaMap = Dictionary(
                    allWords.values.map { ($0.word.lowercased(), $0.id) },
                    uniquingKeysWith: { first, _ in first }
                )
                for word in masteredWords {
                    if let wordId = lemmaMap[word.lowercased()] {
                        try? await userProgressRepository.recordChallengeResult(
                            wordId: wordId,
                            isCorrect: true,
                            stageId: nil,
                            deckId: scenario.id
                        )
                    }
                }
            }
        }
```
2. Update `AppContainer.makeCompleteRoleplaySessionUseCase()`:
Pass `vocabularyDataSource: vocabularyDataSource`.
3. In `RoleplayVoiceCallViewModel.swift`:
Add call start timestamp `private let callStartTime = Date()`.
In `endCall()`:
```swift
    public func endCall() async {
        let summary = await engine.endCall()
        let elapsed = Date().timeIntervalSince(callStartTime)
        if elapsed < 3.0 && summary.totalTurns == 0 {
            // Accidental quick dismissal
            self.sessionSummary = nil
            self.isCallCancelled = true
        } else {
            self.sessionSummary = summary
        }
    }
```
Add `public private(set) var isCallCancelled: Bool = false`.

- [ ] **Step 4: Run tests to verify passing**

Run: `swift test --filter RoleplayUseCasesTests` and `swift test --filter RoleplayVoiceCallViewModelTests`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/CompleteRoleplaySessionUseCase.swift VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayVoiceCallViewModel.swift VocabCraftAppTests/AI/RoleplayUseCasesTests.swift VocabCraftAppTests/AI/RoleplayVoiceCallViewModelTests.swift
git commit -m "feat(ai): persist mastered words in SRS repository and add accidental call guard"
```

---

### Task 5: Decouple Breathing Animation in `CraftVoiceOrbView`

**Files:**
- Modify: `VocabCraftApp/Features/AIAssistant/Views/Components/CraftVoiceOrbView.swift`
- Modify: `VocabCraftAppTests/AI/VoiceConversationStateTests.swift`

**Interfaces:**
- Consumes: `state: VoiceCallState`
- Produces: Fluid continuous breathing orb animation without jitter or freeze

- [ ] **Step 1: Write test for visual state mapping**

In `VocabCraftAppTests/AI/VoiceConversationStateTests.swift`, verify discrete visual mapping (`OrbVisualState: idle, speaking, listening, thinking, ended`).

- [ ] **Step 2: Refactor `CraftVoiceOrbView.swift`**

1. Introduce `OrbVisualState`:
```swift
public enum OrbVisualState: Equatable {
    case idle, speaking, listening, thinking, ended
}
```
2. Map `state.visualState: OrbVisualState`:
```swift
    private var visualState: OrbVisualState {
        switch state {
        case .idle: return .idle
        case .speaking: return .speaking
        case .listening: return .listening
        case .thinking: return .thinking
        case .ended: return .ended
        }
    }
```
3. Use a continuous `@State private var isBreathing = false` animated on appear:
```swift
        ZStack {
            // Background ambient outer glow
            Circle()
                .fill(orbColor.opacity(0.18))
                .frame(width: 220, height: 220)
                .scaleEffect(outerGlowScale(isExpanded: isBreathing))
                .blur(radius: 20)

            // Middle soundwave ring
            Circle()
                .stroke(orbColor.opacity(0.35), lineWidth: 2)
                .frame(width: 170, height: 170)
                .scaleEffect(reduceMotion ? 1.0 : (isBreathing ? 1.08 : 0.94))

            // Inner core orb
            Circle()
                .fill(RadialGradient(...))
                .frame(width: 130, height: 130)
                .shadow(color: orbColor.opacity(0.4), radius: 15, x: 0, y: 0)
                .overlay {
                    CraftIcon(stateSymbol, size: .lg, color: theme.colors.textInverse)
                }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
        .animation(.easeInOut(duration: 0.35), value: visualState)
```

- [ ] **Step 3: Run tests to verify**

Run: `swift test --filter VoiceConversationStateTests`  
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/Components/CraftVoiceOrbView.swift VocabCraftAppTests/AI/VoiceConversationStateTests.swift
git commit -m "fix(ui): decouple CraftVoiceOrbView continuous breathing from transcript mutations"
```

---

### Task 6: Stabilize Layout, Add Smart Dual-Line Subtitles & Pre-Flight Permission Handling

**Files:**
- Modify: `VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift`

**Interfaces:**
- Consumes: `AppStrings.AIAssistant`, `CraftUIKit` tokens
- Produces: Zero layout shift control bar, dual-line context subtitles, pre-flight mic permission alert, localized strings

- [ ] **Step 1: Add localization keys for mic permission and subtitle prompts**

In `VocabCraftApp/Resources/Localizable.xcstrings`:
Add keys with 100% EN/VI parity:
- `app.ai_assistant.call.permission_title`: "Microphone & Speech Permission" / "Quyền Microphone & Nhận diện"
- `app.ai_assistant.call.permission_message`: "VocabCraft needs microphone access for interactive voice roleplay." / "VocabCraft cần quyền truy cập Micro để đàm thoại với AI."
- `app.ai_assistant.call.open_settings`: "Open Settings" / "Mở Cài đặt"
- `app.ai_assistant.call.retry`: "Retry" / "Thử lại"
- `app.ai_assistant.call.speak_prompt`: "Speak into the microphone..." / "Hãy nói vào micro..."
Expose in `AppStrings.AIAssistant`.

- [ ] **Step 2: Update `RoleplayVoiceCallView.swift`**

1. Handle accidental dismissal:
```swift
        .onChange(of: viewModel.isCallCancelled) { _, isCancelled in
            if isCancelled { onDismiss() }
        }
```
2. Stabilize bottom controls with fixed container frame:
```swift
        VStack(spacing: theme.spacing.md) {
            if viewModel.isSubtitlesVisible {
                subtitlesCard
            }

            // Fixed height container for manual turn button / error banner
            ZStack {
                if let error = viewModel.engine.audioErrorMessage {
                    HStack(spacing: theme.spacing.xs) {
                        CraftIcon(.sparkles, size: .sm, color: theme.colors.statusDanger)
                        Text(AppStrings.AIAssistant.retry)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.statusDanger)
                    }
                    .onTapGesture { viewModel.engine.retryListening() }
                } else if case .listening = viewModel.state {
                    CraftButton(
                        AppStrings.AIAssistant.finishTurn,
                        variant: .secondary,
                        size: .sm
                    ) {
                        viewModel.finishSpeaking()
                    }
                }
            }
            .frame(height: 48) // Fixed height prevents jumping!

            // Bottom action buttons
            bottomActionButtons
        }
```
3. Dual-line smart subtitles:
In `subtitlesCard`, display previous AI character utterance (opacity 0.6) and user live transcript below it.
If transcript is empty, show `AppStrings.AIAssistant.speakPrompt` instead of duplicate "Listening...".

- [ ] **Step 3: Update `AIAssistantHubView.swift`**

1. Replace `CraftBadge(LocalizedStringKey(word), ...)` with `CraftBadge(verbatim: word, ...)`.
2. Add `@State private var showPermissionDeniedAlert = false`.
3. In voice call button action:
Check microphone and speech recognition permission. If denied, trigger `showPermissionDeniedAlert = true` with direct link to `UIApplication.openSettingsURLString`.

- [ ] **Step 4: Verify localization tests**

Run: `swift test --filter AIAssistantLocalizationTests`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift
git commit -m "fix(ui): stabilize voice call layout, dual-line subtitles, and pre-flight mic permission alert"
```

---

### Task 7: Full Verification Suite (Quality Gate)

**Files:**
- Repository-wide verification

- [ ] **Step 1: Run complete test suite**

Run: `swift test`  
Expected: All 394+ tests in 62 suites PASS with 0 failures.

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint`  
Expected: 0 violations, 0 serious in 290+ files.

- [ ] **Step 3: Build Xcode project**

Run: `xcodebuild -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO`  
Expected: `** BUILD SUCCEEDED **` with 0 errors and 0 warnings.

- [ ] **Step 4: Check git status for unexpected Xcode-generated files**

Run: `git status`  
Expected: Clean working tree.
