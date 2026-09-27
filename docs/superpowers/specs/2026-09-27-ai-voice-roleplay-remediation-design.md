# AI Voice Roleplay Remediation Design Specification

**Date:** 2026-09-27  
**Status:** Approved  
**Author:** Antigravity AI Pair Programmer & Lead Developer  
**Spec Target:** `docs/superpowers/specs/2026-09-27-ai-voice-roleplay-remediation-design.md`  

---

## 1. Overview & Problem Statement

A thorough audit of the recently implemented AI Voice Roleplay Call feature identified critical flaws across four foundational layers:
1. **Broken Test Suite**: `swift test` fails 3 tests in `AppContainerAITests.swift` because `AppContainer` returns `IntelligentMockLLMProvider` as the default provider while the test assertions strictly expected `MockLLMProvider`.
2. **Audio Engine Synchronization & State Traps**:
   - Toggling mute while the character speaks traps the engine in `.speaking` indefinitely because `startListening()` exits immediately on `isMuted` without updating state.
   - Microphone errors silently leave the engine in `.listening("")` forever with no user feedback.
   - `SilenceDetector` 10s initial silence detection is a no-op because an empty transcript simply returns without re-arming.
   - Tapping "Chạm khi nói xong" with an empty transcript cancels the silence detector permanently, disabling subsequent auto-detection.
   - `activeSpeechTask` is declared as a dead variable without task assignments.
3. **Data Persistence & Domain Gaps**:
   - `CompleteRoleplaySessionUseCase` injects `userProgressRepository` but never invokes it in `execute()`, causing all target word masteries and XP earned during voice calls to be lost.
   - Word discrepancy: `IntelligentMockLLMProvider` hardcodes a disjoint word list (`espresso`, `croissant`, `deadline`, `leadership`), failing to match the actual catalog scenario target words (`beverage`, `pastry`, `innovative`, `initiative`, `accommodate`).
   - Accidental calls (<3s or 0 user turns) inappropriately trigger the celebration summary view.
4. **UI/UX & SwiftUI Animation Defects**:
   - `CraftVoiceOrbView` triggers `PhaseAnimator` on `state`. Because `state` mutates with every recognized word/syllable, the orb jitters violently during speech, and freezes when AI speech continues with a static state.
   - The "Chạm khi nói xong" button renders conditionally, causing the bottom action bar (hang up, mute, captions) to jump vertically by ~50pt during turn transitions.
   - The subtitle card duplicates the "Đang nghe..." text and renders an empty card box when idle or ended.
   - AI subtitles disappear immediately when the user turn begins, giving learners no time to read the character's speech.
   - No pre-flight microphone/speech recognition permission check exists before opening the full-screen call view.

This design document establishes the comprehensive specification to remediate these issues while strictly complying with repository standards in `AGENTS.md`.

---

## 2. Architecture & Layered Component Design

```
┌────────────────────────────────────────────────────────────────────────┐
│                        AIAssistantHubView                              │
│  • Pre-flight Permission Check (AVAudioApplication & SFSpeech)         │
│  • Denied: System Settings Alert with direct deep link                 │
│  • Authorized: Present RoleplayVoiceCallView                           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                       RoleplayVoiceCallView                            │
│  • Fixed bottom container frame (minHeight: 48) - Zero Layout Shift    │
│  • CraftVoiceOrbView: Independent breathing loop + state color morph   │
│  • Dual-Line Smart Subtitles: Faded previous AI speech + Live user text│
│  • Inline Status Banner: Connection / silence prompt ("Are you there?")│
│  • Accidental Call Guard: < 3s & 0 user turns -> dismiss without popup │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                TurnBasedVoiceConversationEngine                        │
│  • State Machine: Idle -> Speaking -> Listening -> Thinking -> Ended   │
│  • Resilient Mute: Always transition to .listening; gate mic stream    │
│  • Error Recovery: Capture speech errors and expose recoverable banner │
│  • Dual-Phase Silence: 10s initial gentle prompt + 1.5s trailing auto  │
│  • Safe Manual Turn: Preserve silence detector when transcript is empty│
│  • Active Task Lifetime: Retain and cancel background execution tasks  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                     Domain, Data & Persistence                         │
│  1. IntelligentMockLLMProvider:                                        │
│     - Dynamically extract words from scenario.targetWordIds            │
│     - Recognize scenario-specific words (beverage, pastry, etc.)       │
│  2. CompleteRoleplaySessionUseCase:                                    │
│     - Inject VocabularyDataSourceProtocol                              │
│     - Map word lemmas to Int64 wordId via VocabularyDataSource         │
│     - Record word attempts in UserProgressRepository (SRS mastery)     │
│     - Accumulate todayWordsLearned and award XP                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Component Specifications

### 3.1 TurnBasedVoiceConversationEngine Refactoring
**File:** `VocabCraftApp/Features/AIAssistant/Services/TurnBasedVoiceConversationEngine.swift`

1. **State Machine & Safe Mute Lifecycle**:
   - When `ttsService.speakAsync(text:)` finishes:
     ```swift
     guard state != .ended else { return }
     if case .speaking = state {
         startListening()
     }
     ```
   - In `startListening()`:
     ```swift
     state = .listening(liveTranscript: "")
     guard !isMuted else { return }
     // Activate silence detector and speechService...
     ```
   - In `toggleMute()`:
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
   - *Guarantee*: Toggling mute while AI is speaking will cleanly enter `.listening("")` when speech ends, leaving the mic dormant. Unmuting at any time immediately activates listening.

2. **Error Recovery & Diagnostics**:
   - Add property `public private(set) var audioErrorMessage: String?`.
   - In `speechService.startListening(onError:)`:
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
   - Provide `public func retryListening()` to clear errors and re-invoke `startListening()`.

3. **Dual-Phase Silence Handling**:
   - `initialSilenceDuration: .seconds(10)`: If 10s elapses before speech starts, trigger an inline visual hint ("Đang lắng nghe bạn nói... Hãy thử bắt đầu nhé!") without killing the mic stream or ending the turn.
   - `trailingSilenceDuration: .milliseconds(Int(silenceDelaySeconds * 1000))`: Triggers only after activity has been registered via `registerActivity()`.

4. **Safe Manual Turn Completion**:
   - In `finishUserTurnManually()`:
     ```swift
     guard case .listening(let transcript) = state else { return }
     let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
     guard !trimmed.isEmpty else { return } // Do NOT cancel silence detector if empty!
     silenceDetector?.cancel()
     Task { @MainActor [weak self] in
         await self?.processUserUtterance(trimmed)
     }
     ```

5. **Task Management**:
   - Store async jobs in `activeSpeechTask = Task { ... }` during `startCall()` and `processUserUtterance()`.
   - In `endCall()`, cancel `activeSpeechTask` and set to `nil`.

---

### 3.2 IntelligentMockLLMProvider Target Word Alignment
**File:** `VocabCraftApp/Data/AI/IntelligentMockLLMProvider.swift`

1. **Dynamic Target Word Extraction**:
   - Update `sendStructuredMessage` to parse the `systemPrompt`:
     ```swift
     // Extract target words specified in the prompt: "Target vocabulary for the user: word1, word2, ..."
     ```
   - Method signature:
     ```swift
     public func extractTargetWords(from text: String, expectedWords: [String] = []) -> [String]
     ```
   - The extractor checks both:
     - Specific `expectedWords` (derived from the scenario's `targetWordIds` in the prompt).
     - Catalog domain fallback words (`beverage`, `pastry`, `complimentary`, `reservation`, `amenities`, `accommodate`, `collaborate`, `innovative`, `initiative`, `espresso`, `croissant`, `deadline`, `leadership`).
2. **Contextual Scenario Matching**:
   - Recognize scenario keywords for Cafe, Hotel, and Interview:
     - Cafe: `espresso`, `coffee`, `croissant`, `beverage`, `pastry`.
     - Hotel: `hotel`, `reservation`, `passport`, `amenities`, `accommodate`, `check in`.
     - Interview: `interview`, `experience`, `strength`, `deadline`, `leadership`, `collaborate`, `innovative`, `initiative`.
   - Advance multi-turn dialogue naturally so users who follow the suggested words receive relevant, praise-worthy character responses.

---

### 3.3 Data Persistence & SRS Integration
**File:** `VocabCraftApp/Domain/UseCases/CompleteRoleplaySessionUseCase.swift`
**File:** `VocabCraftApp/App/DI/AppContainer.swift`

1. **Injecting VocabularyDataSource**:
   - In `CompleteRoleplaySessionUseCase.init`:
     ```swift
     public init(
         userSettingsStore: UserSettingsStore? = nil,
         userProgressRepository: (any UserProgressRepositoryProtocol)? = nil,
         vocabularyDataSource: (any VocabularyDataSourceProtocol)? = nil
     )
     ```
2. **Persistence Logic**:
   - In `execute(scenario:messages:masteredWords:)`:
     ```swift
     // 1. Fetch vocabulary items to map lemma strings to Int64 wordIds
     if let vocabularyDataSource, let userProgressRepository, !masteredWords.isEmpty {
         if let allWords = try? await vocabularyDataSource.fetchAllWordsMap() {
             let lemmaToIdMap = Dictionary(
                 allWords.values.map { ($0.word.lowercased(), $0.id) },
                 uniquingKeysWith: { first, _ in first }
             )
             for word in masteredWords {
                 if let wordId = lemmaToIdMap[word.lowercased()] {
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

     // 2. Accumulate today words learned in userSettingsStore
     if let userSettingsStore {
         await MainActor.run {
             userSettingsStore.todayWordsLearned += uniqueMastered.count
         }
     }
     ```
3. **Accidental Call Handling**:
   - Add property `isAccidentalDismissal: Bool` in `RoleplaySessionSummary` or determine when `totalTurns == 0`.
   - In `RoleplayVoiceCallViewModel`: If call duration < 3s and `totalTurns == 0`, dismiss directly without populating `sessionSummary`.

---

### 3.4 CraftVoiceOrbView Decoupled Animation
**File:** `VocabCraftApp/Features/AIAssistant/Views/Components/CraftVoiceOrbView.swift`

1. **Decoupling State Trigger from Continuous Breathing**:
   - Do not pass `trigger: state` with associated values (which changes on every transcript syllable).
   - Define a pure discrete call phase enum for visual styling:
     ```swift
     public enum OrbVisualState: Equatable {
         case idle, speaking, listening, thinking, ended
     }
     ```
   - Convert `state` to `OrbVisualState`.
   - Use a continuous `@State private var isBreathing = false` with `.repeatForever(autoreverses: true)` or a standalone `PhaseAnimator([false, true])` without a rapid-fire trigger.
   - Animate outer glow and soundwave scales based on `isBreathing` and current `OrbVisualState`.
   - Apply `.animation(.easeInOut(duration: 0.35), value: visualState)` to smoothly morph color and SF Symbols.

---

### 3.5 RoleplayVoiceCallView UI/UX & Layout Stabilization
**File:** `VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift`

1. **Fixed Control Bar Height**:
   - Place the "Chạm khi nói xong" button in a dedicated container with `frame(minHeight: 48)`.
   - When not in `.listening` mode, render an invisible spacer or gentle status indicator, preventing the bottom navigation HStack from shifting position.
2. **Dual-Line Smart Subtitles**:
   - Keep the last character utterance visible in secondary text style (dimmed opacity 0.6) above the live user transcription.
   - Display placeholder *"Nói vào micro..."* only when transcript is empty, removing duplicate *"Đang nghe..."*.
   - When state is `.idle` or `.ended`, collapse the card smoothly with `.transition(.opacity)`.
3. **Inline Error & Silence Banner**:
   - If `engine.audioErrorMessage != nil`, show an inline alert badge with a "Thử lại" (`retryListening()`) button.
   - If initial silence prompt fires, show a gentle subtitle hint encouraging the user to speak.

---

### 3.6 Pre-Flight Permission Handling
**File:** `VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`

1. **Permission Guard**:
   - Before assigning `activeVoiceCallScenario = scenario`, call `AVAudioApplication.shared.recordPermission` and `SFSpeechRecognizer.authorizationStatus()`.
   - If `.undetermined`, invoke permission requests.
   - If `.denied` or `.restricted`, present an alert informing the user:
     - Title: *"Yêu cầu quyền Microphone & Nhận diện giọng nói"*
     - Message: *"Vui lòng cho phép quyền truy cập Micro trong Cài đặt của máy để sử dụng tính năng gọi thoại cùng AI."*
     - Buttons: *"Để sau"* (Cancel) and *"Mở Cài đặt"* (opens `UIApplication.openSettingsURLString`).

---

### 3.7 Test Suite Alignment (`AppContainerAITests.swift`)
**File:** `VocabCraftAppTests/App/AppContainerAITests.swift`

1. **Fix Failing Assertions**:
   - `AppContainer` uses `IntelligentMockLLMProvider()` as the default offline provider when no API key is set.
   - Update tests to assert:
     ```swift
     #expect(container.llmProvider is IntelligentMockLLMProvider || container.llmProvider is MockLLMProvider)
     ```
   - Ensure `testDynamicLLMProviderSwitchingWithApiKey` and `testDynamicLLMProviderWhitespaceAndPersistence` pass seamlessly.

---

## 4. Verification Plan

### Automated Verification
1. **Swift Testing**:
   ```bash
   swift test
   ```
   *Requirement*: 100% passing rate across all 394+ tests in 62 suites (0 failures).
2. **SwiftLint Compliance**:
   ```bash
   swiftlint
   ```
   *Requirement*: 0 errors, 0 warnings.
3. **Full Xcode Project Compilation**:
   ```bash
   xcodebuild -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO
   ```
   *Requirement*: `** BUILD SUCCEEDED **` with 0 warnings.

### Manual Behavior Verification
1. **Mute while Speaking**: Toggle mute during AI greeting. Verify state cleanly transitions to `.listening` when audio finishes, mic remains dormant, and unmuting resumes recording instantly.
2. **Target Word Mastery**: Speak `"I would like a beverage and a pastry"` in the Cafe scenario. Verify both badges highlight green with checkmark icons.
3. **Layout Stability**: Monitor the bottom control bar during speech transitions. Verify zero vertical button jumping.
4. **Accidental Exit**: Open call and tap close within 1 second. Verify dismissal without celebration summary.
5. **Persistent SRS**: Finish a 3-turn call with 2 mastered words. Open Vocabulary/Personal Bank and verify word progress and XP incremented.
