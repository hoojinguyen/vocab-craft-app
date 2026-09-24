# AI Voice Roleplay (Hands-Free Call Mode & Intelligent Offline Simulation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a full-screen, hands-free conversational AI voice call mode (`RoleplayVoiceCallView`) with an animated Voice Orb, audio session coordination, real-time target word tracking with haptic feedback, and an intelligent offline simulation engine enabling 100% testing on physical devices without a Gemini API key.

**Architecture:** A finite state machine (`VoiceCallState`) coordinates audio transitions between character speech (Apple Text-to-Speech via `TextToSpeechService`) and learner input (Apple Speech-to-Text via `SpeechRecognitionService` + `SilenceDetector`). Domain logic is encapsulated in `TurnBasedVoiceConversationEngine`, with AI responses produced dynamically by `GeminiLLMProvider` (when API key is present) or `IntelligentMockLLMProvider` (contextual multi-turn dialogue simulation for offline/no-key usage).

**Tech Stack:** Swift 6, SwiftUI, AVFoundation, SpeechKit (`SpeechRecognitionService`, `SilenceDetector`, `AudioSessionCoordinator`), CraftUIKit (Design tokens, `CraftBadge`, `CraftIconButton`, `CraftHapticFeedback`).

**Spec:** `docs/superpowers/specs/2026-09-25-ai-voice-roleplay-call-design.md`

## Global Constraints

- **Swift Concurrency**: Strict `@MainActor` and `Sendable` adherence with zero concurrency warnings.
- **Design Tokens**: 100% `CraftUIKit` tokens (`CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`); zero raw colors or hardcoded paddings.
- **Zero Hardcoded Strings**: All UI text and accessibility strings declared in `VocabCraftApp/Resources/Localizable.xcstrings` across both English (`en`) and Vietnamese (`vi`).
- **Quality Gates**: Zero compiler warnings, zero SwiftLint violations, 100% passing tests.

---

### Task 1: Voice Conversation State Machine & Protocols

**Files:**
- Create: `VocabCraftApp/Domain/Protocols/VoiceConversationEngineProtocol.swift`
- Test: `VocabCraftAppTests/AI/VoiceConversationStateTests.swift`

**Interfaces:**
- Consumes: `RoleplayScenario`, `RoleplayMessage`, `RoleplaySessionSummary`
- Produces: `VoiceCallState`, `VoiceConversationEngineProtocol`

- [ ] **Step 1: Write the failing unit test**

```swift
import Testing
@testable import VocabCraftApp

@Suite("Voice Conversation State Tests")
struct VoiceConversationStateTests {
    @Test("Verify VoiceCallState equality and transitions")
    func stateEquality() {
        let idle = VoiceCallState.idle
        let speaking = VoiceCallState.speaking(characterText: "Hello there!")
        let listening = VoiceCallState.listening(liveTranscript: "I want coffee")
        let thinking = VoiceCallState.thinking
        let ended = VoiceCallState.ended

        #expect(idle != speaking)
        #expect(speaking != listening)
        #expect(listening != thinking)
        #expect(thinking != ended)
        #expect(VoiceCallState.speaking(characterText: "A") == VoiceCallState.speaking(characterText: "A"))
        #expect(VoiceCallState.speaking(characterText: "A") != VoiceCallState.speaking(characterText: "B"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/VoiceConversationStateTests`
Expected: FAIL with "cannot find type 'VoiceCallState' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Domain/Protocols/VoiceConversationEngineProtocol.swift`:

```swift
import Foundation

/// Represents the active state of an AI voice call session.
public enum VoiceCallState: Equatable, Sendable {
    case idle
    case speaking(characterText: String)
    case listening(liveTranscript: String)
    case thinking
    case ended
}

/// Abstract contract for the voice roleplay engine coordinating audio and LLM turns.
@MainActor
public protocol VoiceConversationEngineProtocol: AnyObject, Sendable {
    var state: VoiceCallState { get }
    var isMuted: Bool { get }
    var isSubtitlesVisible: Bool { get }
    var scenario: RoleplayScenario { get }
    var messages: [RoleplayMessage] { get }
    var masteredTargetWords: Set<String> { get }

    func startCall() async
    func finishUserTurnManually()
    func toggleMute()
    func toggleSubtitles()
    func endCall() async -> RoleplaySessionSummary
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/VoiceConversationStateTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Protocols/VoiceConversationEngineProtocol.swift VocabCraftAppTests/AI/VoiceConversationStateTests.swift
git commit -m "feat(ai): define VoiceCallState and VoiceConversationEngineProtocol"
```

---

### Task 2: Intelligent Offline Scenario Simulation Engine

**Files:**
- Create: `VocabCraftApp/Data/AI/IntelligentMockLLMProvider.swift`
- Test: `VocabCraftAppTests/AI/IntelligentMockLLMProviderTests.swift`

**Interfaces:**
- Consumes: `LLMProviderProtocol`, `LLMChatMessage`, `RoleplayTurnOutput`
- Produces: `IntelligentMockLLMProvider: LLMProviderProtocol`

- [ ] **Step 1: Write the failing unit test**

```swift
import Testing
@testable import VocabCraftApp

@Suite("Intelligent Mock LLM Provider Tests")
struct IntelligentMockLLMProviderTests {
    @Test("Extracts target words and advances cafe dialogue")
    func cafeScenarioTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .system, content: "Scenario: scenario_cafe_order. Target words: espresso, croissant, recommendation, decaf."),
            LLMChatMessage(role: .model, content: "Hi! Welcome to The Daily Roast. What can I get started for you today?"),
            LLMChatMessage(role: .user, content: "Can I have a hot espresso and a fresh croissant?")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are Alex the barista.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("espresso"))
        #expect(output.targetWordsUsed.contains("croissant"))
        #expect(!output.characterReply.isEmpty)
        #expect(output.refinementSuggestion != nil)
    }

    @Test("Fallback response handles free-form speech outside script")
    func freeFormFallback() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Tell me about the weather outside.")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "General conversation",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(!output.characterReply.isEmpty)
        #expect(output.pedagogicalNote != nil)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/IntelligentMockLLMProviderTests`
Expected: FAIL with "cannot find 'IntelligentMockLLMProvider' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Data/AI/IntelligentMockLLMProvider.swift`:

```swift
import Foundation

/// Intelligent offline mock LLM provider simulating contextual multi-turn roleplay conversations
/// and target word detection without network access or an API key.
public final class IntelligentMockLLMProvider: LLMProviderProtocol, @unchecked Sendable {
    public let providerIdentifier: String = "intelligent_mock"

    public init() {}

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        let lastUserMessage = messages.last(where: { $0.role == .user })?.content ?? ""
        let lowercasedUser = lastUserMessage.lowercased()

        // 1. Extract Target Words from dialogue history and user utterance
        let targetWordsUsed = extractTargetWords(from: lowercasedUser)

        // 2. Determine scenario context
        let reply: String
        let refinement: String?
        let tip: String?

        if lowercasedUser.contains("espresso") || lowercasedUser.contains("coffee") || lowercasedUser.contains("croissant") {
            // Cafe Scenario Turn
            if messages.filter({ $0.role == .user }).count <= 1 {
                reply = "Great choice! Would you like a single or double espresso? And should I warm up the croissant for you?"
                refinement = "You could say: 'I'd like a double espresso and a warmed croissant, please.'"
                tip = "In a cafe, specifying 'single or double shot' makes ordering seamless!"
            } else {
                reply = "Coming right up! That will be $6.50. You can tap your card right on the reader. Have a wonderful day!"
                refinement = "Native tip: 'Keep the change!' is common if paying cash."
                tip = "Great job finishing your cafe order using your target vocabulary!"
            }
        } else if lowercasedUser.contains("interview") || lowercasedUser.contains("experience") || lowercasedUser.contains("strength") {
            // Job Interview Scenario Turn
            reply = "Thank you for sharing that. Could you tell me about a time you handled a tight deadline or challenge?"
            refinement = "Consider using the STAR method (Situation, Task, Action, Result) when answering."
            tip = "Strong action verbs like 'managed', 'developed', and 'collaborated' elevate your response."
        } else if lowercasedUser.contains("hotel") || lowercasedUser.contains("reservation") || lowercasedUser.contains("check in") {
            // Hotel Check-In Scenario Turn
            reply = "I found your reservation right here. May I have your passport or ID card, please?"
            refinement = "Try: 'I have a reservation under the name [Your Name].'"
            tip = "'Under the name' is the standard polite phrasing for reservations."
        } else {
            // Adaptive Fallback
            reply = "That's very interesting! Could you elaborate more on that, or should we move to the next step?"
            refinement = "Natural phrasing: 'Could you give me more details on that?'"
            tip = "Keep speaking naturally. Notice how rhythm and intonation help convey meaning."
        }

        let output = RoleplayTurnOutput(
            characterReply: reply,
            targetWordsUsed: targetWordsUsed,
            refinementSuggestion: refinement,
            pedagogicalNote: tip
        )

        if let typedResult = output as? T {
            return typedResult
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Unsupported output schema for IntelligentMockLLMProvider")
        )
    }

    private func extractTargetWords(from text: String) -> [String] {
        let catalogTargetWords = [
            "espresso", "croissant", "recommendation", "decaf", "receipt",
            "experience", "collaboration", "strength", "deadline", "leadership",
            "reservation", "passport", "amenities", "checkout", "complimentary"
        ]
        return catalogTargetWords.filter { word in
            text.localizedStandardContains(word)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/IntelligentMockLLMProviderTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/IntelligentMockLLMProvider.swift VocabCraftAppTests/AI/IntelligentMockLLMProviderTests.swift
git commit -m "feat(ai): implement IntelligentMockLLMProvider with multi-turn scenario simulation"
```

---

### Task 3: Turn-Based Voice Conversation Engine

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/TurnBasedVoiceConversationEngine.swift`
- Test: `VocabCraftAppTests/AI/TurnBasedVoiceConversationEngineTests.swift`

**Interfaces:**
- Consumes: `VoiceConversationEngineProtocol`, `AudioSessionCoordinating`, `SpeechRecognitionProtocol`, `TextToSpeechProtocol`, `ExecuteRoleplayTurnUseCase`
- Produces: `TurnBasedVoiceConversationEngine: VoiceConversationEngineProtocol`

- [ ] **Step 1: Write the failing unit test**

```swift
import Testing
@testable import VocabCraftApp

@Suite("TurnBasedVoiceConversationEngine Tests")
struct TurnBasedVoiceConversationEngineTests {
    @Test("Engine transitions from idle to speaking on startCall")
    @MainActor
    func startCallLifecycle() async {
        let scenario = RoleplayScenario(
            id: "scenario_test",
            titleKey: "test_title",
            descriptionKey: "test_desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Alex",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome to The Daily Roast! What can I get for you?",
            targetWordIds: ["espresso", "croissant"],
            iconSymbol: "cup.and.saucer.fill"
        )
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = TurnBasedVoiceConversationEngine(
            scenario: scenario,
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        #expect(engine.state == .idle)
        await engine.startCall()
        #expect(engine.messages.count == 1)
        #expect(engine.state == .speaking(characterText: scenario.initialGreeting))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/TurnBasedVoiceConversationEngineTests`
Expected: FAIL with "cannot find 'TurnBasedVoiceConversationEngine' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Domain/UseCases/TurnBasedVoiceConversationEngine.swift`:

```swift
import Foundation
import Observation

@MainActor
@Observable
public final class TurnBasedVoiceConversationEngine: VoiceConversationEngineProtocol {
    public private(set) var state: VoiceCallState = .idle
    public private(set) var isMuted: Bool = false
    public private(set) var isSubtitlesVisible: Bool = true
    public let scenario: RoleplayScenario
    public private(set) var messages: [RoleplayMessage] = []
    public private(set) var masteredTargetWords: Set<String> = []

    private let ttsService: TextToSpeechProtocol
    private let speechService: SpeechRecognitionProtocol
    private let executeTurnUseCase: ExecuteRoleplayTurnUseCase
    private let completeSessionUseCase: CompleteRoleplaySessionUseCase
    private var silenceTask: Task<Void, Never>?

    public init(
        scenario: RoleplayScenario,
        ttsService: TextToSpeechProtocol,
        speechService: SpeechRecognitionProtocol,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase,
        completeSessionUseCase: CompleteRoleplaySessionUseCase
    ) {
        self.scenario = scenario
        self.ttsService = ttsService
        self.speechService = speechService
        self.executeTurnUseCase = executeTurnUseCase
        self.completeSessionUseCase = completeSessionUseCase
    }

    public func startCall() async {
        let greeting = scenario.initialGreeting
        let initialMessage = RoleplayMessage(
            id: UUID(),
            sender: .character(name: scenario.characterName),
            text: greeting,
            timestamp: Date()
        )
        messages.append(initialMessage)
        state = .speaking(characterText: greeting)

        ttsService.speak(text: greeting)
        // Schedule auto transition to listening after speech finishes
        try? await Task.sleep(for: .seconds(2.5))
        if case .speaking = state {
            startListening()
        }
    }

    public func startListening() {
        guard !isMuted else { return }
        state = .listening(liveTranscript: "")
        speechService.startListening(
            onResult: { [weak self] transcript in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.handleTranscriptUpdate(transcript)
                }
            },
            onError: { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.finishUserTurnManually()
                }
            }
        )
    }

    private func handleTranscriptUpdate(_ transcript: String) {
        state = .listening(liveTranscript: transcript)
        silenceTask?.cancel()
        silenceTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await self.processUserUtterance(transcript)
            }
        }
    }

    public func finishUserTurnManually() {
        silenceTask?.cancel()
        if case .listening(let transcript) = state, !transcript.isEmpty {
            Task { await processUserUtterance(transcript) }
        }
    }

    private func processUserUtterance(_ utterance: String) async {
        speechService.stopListening()
        state = .thinking

        let userMessage = RoleplayMessage(
            id: UUID(),
            sender: .user,
            text: utterance,
            timestamp: Date()
        )
        messages.append(userMessage)

        do {
            let output = try await executeTurnUseCase.execute(scenario: scenario, conversation: messages)
            for word in output.targetWordsUsed {
                masteredTargetWords.insert(word)
            }

            let aiMessage = RoleplayMessage(
                id: UUID(),
                sender: .character(name: scenario.characterName),
                text: output.characterReply,
                timestamp: Date(),
                refinementSuggestion: output.refinementSuggestion,
                pedagogicalNote: output.pedagogicalNote
            )
            messages.append(aiMessage)

            state = .speaking(characterText: output.characterReply)
            ttsService.speak(text: output.characterReply)

            try? await Task.sleep(for: .seconds(3.0))
            if case .speaking = state {
                startListening()
            }
        } catch {
            state = .listening(liveTranscript: "")
        }
    }

    public func toggleMute() {
        isMuted.toggle()
        if isMuted {
            speechService.stopListening()
        } else if case .listening = state {
            startListening()
        }
    }

    public func toggleSubtitles() {
        isSubtitlesVisible.toggle()
    }

    public func endCall() async -> RoleplaySessionSummary {
        speechService.stopListening()
        ttsService.stop()
        silenceTask?.cancel()
        state = .ended

        return completeSessionUseCase.execute(
            scenario: scenario,
            messages: messages,
            masteredWords: masteredTargetWords
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/TurnBasedVoiceConversationEngineTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/TurnBasedVoiceConversationEngine.swift VocabCraftAppTests/AI/TurnBasedVoiceConversationEngineTests.swift
git commit -m "feat(ai): implement TurnBasedVoiceConversationEngine with audio state orchestration"
```

---

### Task 4: Voice Orb Animated Component (`CraftVoiceOrbView`)

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/Views/Components/CraftVoiceOrbView.swift`

**Interfaces:**
- Consumes: `VoiceCallState`, `CraftTheme`, `CraftColorTokens`
- Produces: `CraftVoiceOrbView: View`

- [ ] **Step 1: Write CraftVoiceOrbView component with state animations**

Create `VocabCraftApp/Features/AIAssistant/Views/Components/CraftVoiceOrbView.swift`:

```swift
import CraftUIKit
import SwiftUI

/// Animated circular Voice Orb dynamically reflecting Speaking, Listening, and Thinking call states.
public struct CraftVoiceOrbView: View {
    public let state: VoiceCallState
    @Environment(\.craftTheme) private var theme
    @State private var isBreathing = false
    @State private var wavePhase: CGFloat = 0

    public init(state: VoiceCallState) {
        self.state = state
    }

    public var body: some View {
        ZStack {
            // Background ambient outer glow
            Circle()
                .fill(orbColor.opacity(0.18))
                .frame(width: 220, height: 220)
                .scaleEffect(scaleForState)
                .blur(radius: 20)

            // Middle soundwave ring
            Circle()
                .stroke(orbColor.opacity(0.35), lineWidth: 2)
                .frame(width: 170, height: 170)
                .scaleEffect(isBreathing ? 1.08 : 0.94)

            // Inner core liquid glass orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [orbColor, orbColor.opacity(0.65), theme.colors.surfaceCard],
                        center: .center,
                        startRadius: 10,
                        endRadius: 70
                    )
                )
                .frame(width: 130, height: 130)
                .shadow(color: orbColor.opacity(0.4), radius: 15, x: 0, y: 0)
                .overlay {
                    stateIcon
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(theme.colors.textInverse)
                }
        }
        .animation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true), value: isBreathing)
        .onAppear {
            isBreathing = true
        }
    }

    private var orbColor: Color {
        switch state {
        case .idle:
            return theme.colors.textSecondary
        case .speaking:
            return theme.colors.brandPrimary
        case .listening:
            return theme.colors.accent
        case .thinking:
            return theme.colors.warning
        case .ended:
            return theme.colors.danger
        }
    }

    private var scaleForState: CGFloat {
        switch state {
        case .speaking:
            return isBreathing ? 1.15 : 0.98
        case .listening:
            return isBreathing ? 1.25 : 1.02
        case .thinking:
            return isBreathing ? 1.05 : 0.95
        case .idle, .ended:
            return 1.0
        }
    }

    private var animationDuration: Double {
        switch state {
        case .speaking: return 0.7
        case .listening: return 0.5
        case .thinking: return 1.2
        case .idle, .ended: return 1.5
        }
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .idle:
            Image(systemName: "phone.fill")
        case .speaking:
            Image(systemName: "waveform")
        case .listening:
            Image(systemName: "mic.fill")
        case .thinking:
            Image(systemName: "sparkles")
        case .ended:
            Image(systemName: "phone.down.fill")
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/Components/CraftVoiceOrbView.swift
git commit -m "feat(ai): create CraftVoiceOrbView component with state-driven animation"
```

---

### Task 5: Voice Call ViewModel & Full-Screen View

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayVoiceCallViewModel.swift`
- Create: `VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift`

**Interfaces:**
- Consumes: `VoiceConversationEngineProtocol`, `CraftVoiceOrbView`, `CraftBadge`, `CraftHapticFeedback`
- Produces: `RoleplayVoiceCallView: View`

- [ ] **Step 1: Create RoleplayVoiceCallViewModel**

Create `VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayVoiceCallViewModel.swift`:

```swift
import CraftUIKit
import Foundation
import Observation

@MainActor
@Observable
public final class RoleplayVoiceCallViewModel {
    public let engine: VoiceConversationEngineProtocol
    public var sessionSummary: RoleplaySessionSummary?
    private var previousMasteredCount: Int = 0

    public init(engine: VoiceConversationEngineProtocol) {
        self.engine = engine
        self.previousMasteredCount = engine.masteredTargetWords.count
    }

    public var state: VoiceCallState { engine.state }
    public var scenario: RoleplayScenario { engine.scenario }
    public var masteredTargetWords: Set<String> { engine.masteredTargetWords }
    public var isMuted: Bool { engine.isMuted }
    public var isSubtitlesVisible: Bool { engine.isSubtitlesVisible }

    public func startCall() async {
        await engine.startCall()
    }

    public func finishSpeaking() {
        engine.finishUserTurnManually()
    }

    public func toggleMute() {
        engine.toggleMute()
    }

    public func toggleSubtitles() {
        engine.toggleSubtitles()
    }

    public func endCall() async {
        let summary = await engine.endCall()
        self.sessionSummary = summary
    }

    public func checkForNewTargetWordMastered() {
        if engine.masteredTargetWords.count > previousMasteredCount {
            previousMasteredCount = engine.masteredTargetWords.count
            CraftHapticFeedback.success()
        }
    }
}
```

- [ ] **Step 2: Create RoleplayVoiceCallView**

Create `VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift`:

```swift
import CraftUIKit
import SwiftUI

public struct RoleplayVoiceCallView: View {
    @State private var viewModel: RoleplayVoiceCallViewModel
    private let onDismiss: () -> Void
    @Environment(\.craftTheme) private var theme
    @State private var showConfirmEnd: Bool = false

    public init(viewModel: RoleplayVoiceCallViewModel, onDismiss: @escaping () -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: theme.spacing.md) {
                // Top Header HUD
                topHeaderBar

                // Target Words Horizontal Strip
                targetWordsStrip

                Spacer()

                // Center Stage: Voice Orb & State Text
                centerVoiceOrbStage

                Spacer()

                // Bottom Subtitle Card & Action Controls
                bottomControlsStage
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.vertical, theme.spacing.sm)
        }
        .task {
            await viewModel.startCall()
        }
        .onChange(of: viewModel.masteredTargetWords.count) { _, _ in
            viewModel.checkForNewTargetWordMastered()
        }
        #if os(iOS)
        .fullScreenCover(item: $viewModel.sessionSummary) { summary in
            RoleplaySummaryView(summary: summary) {
                onDismiss()
            }
        }
        #else
        .sheet(item: $viewModel.sessionSummary) { summary in
            RoleplaySummaryView(summary: summary) {
                onDismiss()
            }
        }
        #endif
    }

    private var topHeaderBar: some View {
        HStack {
            CraftIconButton(
                symbol: .close,
                size: .md,
                variant: .subtle,
                accessibilityLabelKey: AppStrings.Common.close
            ) {
                Task { await viewModel.endCall() }
            }

            Spacer()

            VStack(spacing: theme.spacing.xxs) {
                Text(viewModel.scenario.characterName)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)
                Text(viewModel.scenario.characterRole)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer()

            CraftBadge(
                AppStrings.AIAssistant.callActiveBadge,
                variant: .subtle,
                tone: .success,
                size: .sm
            )
        }
    }

    private var targetWordsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
                Text(AppStrings.AIAssistant.targetWordsTitle)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)

                ForEach(viewModel.scenario.targetWordIds, id: \.self) { word in
                    let isMastered = viewModel.masteredTargetWords.contains(word)
                    CraftBadge(
                        LocalizedStringKey(word),
                        iconName: isMastered ? "checkmark.circle.fill" : nil,
                        variant: isMastered ? .solid : .subtle,
                        tone: isMastered ? .success : .neutral,
                        size: .sm
                    )
                    .scaleEffect(isMastered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isMastered)
                }
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
        }
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    }

    private var centerVoiceOrbStage: some View {
        VStack(spacing: theme.spacing.lg) {
            CraftVoiceOrbView(state: viewModel.state)

            Text(stateDescription)
                .font(theme.typography.bodyLarge)
                .foregroundStyle(theme.colors.textSecondary)
                .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        }
    }

    private var bottomControlsStage: some View {
        VStack(spacing: theme.spacing.md) {
            if viewModel.isSubtitlesVisible {
                subtitlesCard
            }

            HStack(spacing: theme.spacing.lg) {
                // Subtitles toggle
                CraftIconButton(
                    symbol: .docText,
                    size: .lg,
                    variant: viewModel.isSubtitlesVisible ? .filled : .subtle,
                    accessibilityLabelKey: AppStrings.AIAssistant.toggleCaptions
                ) {
                    viewModel.toggleSubtitles()
                }

                // Hang Up Button (Red)
                Button {
                    Task { await viewModel.endCall() }
                } label: {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(theme.colors.textInverse)
                        .padding(theme.spacing.base)
                        .background(theme.colors.danger)
                        .clipShape(Circle())
                }
                .accessibilityLabel(AppStrings.AIAssistant.endCall)

                // Mute toggle
                CraftIconButton(
                    symbol: viewModel.isMuted ? .slash : .audio,
                    size: .lg,
                    variant: viewModel.isMuted ? .filled : .subtle,
                    accessibilityLabelKey: viewModel.isMuted ? AppStrings.AIAssistant.unmuteMicrophone : AppStrings.AIAssistant.muteMicrophone
                ) {
                    viewModel.toggleMute()
                }
            }
        }
    }

    private var subtitlesCard: some View {
        CraftCard(
            style: .elevated,
            cornerRadius: theme.radii.lg,
            padding: theme.spacing.md
        ) {
            Text(currentSubtitleText)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineLimit(3)
        }
    }

    private var stateDescription: LocalizedStringKey {
        switch viewModel.state {
        case .idle: return AppStrings.AIAssistant.stateIdle
        case .speaking: return AppStrings.AIAssistant.stateSpeaking
        case .listening: return AppStrings.AIAssistant.stateListening
        case .thinking: return AppStrings.AIAssistant.stateThinking
        case .ended: return AppStrings.AIAssistant.stateEnded
        }
    }

    private var currentSubtitleText: String {
        switch viewModel.state {
        case .speaking(let text):
            return text
        case .listening(let transcript):
            return transcript.isEmpty ? "..." : transcript
        case .thinking:
            return "..."
        case .idle, .ended:
            return ""
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayVoiceCallViewModel.swift VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift
git commit -m "feat(ai): create RoleplayVoiceCallViewModel and full-screen RoleplayVoiceCallView"
```

---

### Task 6: DI & Entry Point Integration

**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `IntelligentMockLLMProvider`, `RoleplayVoiceCallViewModel`, `TurnBasedVoiceConversationEngine`
- Produces: `appContainer.makeRoleplayVoiceCallViewModel(for:)`

- [ ] **Step 1: Update AppContainer.llmProvider and add call factory**

In `VocabCraftApp/App/DI/AppContainer.swift`:
```swift
public var llmProvider: LLMProviderProtocol {
    if userSettingsStore.isGeminiApiKeyConfigured {
        return GeminiLLMProvider(apiKey: userSettingsStore.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
       !envKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return GeminiLLMProvider(apiKey: envKey)
    }
    return IntelligentMockLLMProvider()
}

@MainActor
public func makeRoleplayVoiceCallViewModel(for scenario: RoleplayScenario) -> RoleplayVoiceCallViewModel {
    let engine = TurnBasedVoiceConversationEngine(
        scenario: scenario,
        ttsService: ttsService,
        speechService: speechRecognitionService,
        executeTurnUseCase: makeExecuteRoleplayTurnUseCase(),
        completeSessionUseCase: makeCompleteRoleplaySessionUseCase()
    )
    return RoleplayVoiceCallViewModel(engine: engine)
}
```

- [ ] **Step 2: Add "Start Voice Call" action button to AIAssistantHubView**

In `AIAssistantHubView.swift`, add `@State private var activeVoiceCallScenario: RoleplayScenario?` and wire the hero daily card button and scenario card buttons to trigger `activeVoiceCallScenario = scenario`, presenting `RoleplayVoiceCallView` in full screen.

- [ ] **Step 3: Add new source files to `VocabCraftApp.xcodeproj/project.pbxproj`**

Add references and build phases for the newly created files:
- `VoiceConversationEngineProtocol.swift`
- `IntelligentMockLLMProvider.swift`
- `TurnBasedVoiceConversationEngine.swift`
- `CraftVoiceOrbView.swift`
- `RoleplayVoiceCallViewModel.swift`
- `RoleplayVoiceCallView.swift`

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift VocabCraftApp.xcodeproj/project.pbxproj
git commit -m "feat(ai): wire Voice Call factory in AppContainer, Hub entry point, and pbxproj"
```

---

### Task 7: Bilingual Localization & Accessibility Parity

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Resources/AppStrings.swift`

- [ ] **Step 1: Add new localized string symbols to AppStrings.AIAssistant**

```swift
public static let startVoiceCall = "app.ai.call.start"
public static let endCall = "app.ai.call.end"
public static let callActiveBadge = "app.ai.call.active_badge"
public static let stateIdle = "app.ai.call.state.idle"
public static let stateSpeaking = "app.ai.call.state.speaking"
public static let stateListening = "app.ai.call.state.listening"
public static let stateThinking = "app.ai.call.state.thinking"
public static let stateEnded = "app.ai.call.state.ended"
public static let toggleCaptions = "app.ai.call.action.toggle_captions"
public static let muteMicrophone = "app.ai.call.action.mute"
public static let unmuteMicrophone = "app.ai.call.action.unmute"
```

- [ ] **Step 2: Add matching bilingual pairs in Localizable.xcstrings (en & vi)**

Add entries for all new keys with 100% parity:
- `app.ai.call.start`: en="Start Voice Call", vi="Bắt đầu gọi thoại"
- `app.ai.call.end`: en="End Call", vi="Kết thúc cuộc gọi"
- `app.ai.call.active_badge`: en="Voice Call Active", vi="Đang gọi thoại"
- `app.ai.call.state.speaking`: en="Character is speaking...", vi="Nhân vật đang nói..."
- `app.ai.call.state.listening`: en="Listening to you...", vi="Đang lắng nghe bạn..."
- `app.ai.call.state.thinking`: en="Thinking...", vi="Đang suy nghĩ..."
- `app.ai.call.state.ended`: en="Call ended", vi="Cuộc gọi đã kết thúc"
- `app.ai.call.action.toggle_captions`: en="Toggle Subtitles", vi="Bật/tắt phụ đề"
- `app.ai.call.action.mute`: en="Mute microphone", vi="Tắt tiếng micro"
- `app.ai.call.action.unmute`: en="Unmute microphone", vi="Bật micro"

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Resources/AppStrings.swift VocabCraftApp/Resources/Localizable.xcstrings
git commit -m "feat(localization): add bilingual localization keys for Voice Call mode"
```

---

### Task 8: End-to-End Verification & Quality Gates

**Files:**
- Execute verification commands

- [ ] **Step 1: Run complete test suite**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17"`
Expected: 100% test pass rate.

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint --strict`
Expected: 0 violations, 0 warnings.

- [ ] **Step 3: Run full clean build on Xcode**

Run: `xcodebuild clean build -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17"`
Expected: **0 errors, 0 warnings**.

- [ ] **Step 4: Manual Device Verification**

Launch app on device -> Tap "Start Voice Call" on Daily Mission ("The Daily Roast") -> Speak target words -> Verify Voice Orb animations, subtitles, target word haptics, and summary transition.
