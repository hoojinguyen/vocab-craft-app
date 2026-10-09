# Adaptive Multi-Turn Voice Dialogue FSM Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and integrate an on-device Finite State Machine (FSM) dialogue system for roleplay voice calls that supports topic-specific states, Vietnamese/non-English detection with pedagogical nudges, target word opportunity injection, and adaptive 6-turn pacing.

**Architecture:** A stateless reducer pattern inside `OnDeviceContextDialogueEngine` decomposes dialogue management into modular components (`ScenarioDialogueState`, `DialogueIntentClassifier`, `TargetWordPrompter`, and `ScenarioStateReducer`), inferring conversation progression from message history and generating contextual responses and 3-branch suggestions without schema migrations or network dependencies.

**Tech Stack:** Swift 5.9 / Swift 6, SwiftUI, Swift Testing framework (`@Suite`, `@Test`), Xcode `project.pbxproj`, Foundation.

**Spec:** [`docs/superpowers/specs/2026-10-10-adaptive-voice-dialogue-fsm-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-10-10-adaptive-voice-dialogue-fsm-design.md)

## Global Constraints

- 100% On-Device & Zero Network calls for local AI packs.
- Zero Hardcoded Raw UI Strings (must use semantic structures conforming to project standards).
- Zero Compiler Warnings and Zero SwiftLint violations.
- Full bilingual test coverage and 100% pass rate across the full test suite.
- Preserve backward compatibility for `LLMProviderProtocol`, `VoiceConversationEngineProtocol`, and `RoleplayTurnOutput`.

---

### Task 1: Scenario Dialogue State Models (`ScenarioDialogueState.swift`)

**Files:**
- Create: `VocabCraftApp/Data/AI/DialogueFSM/ScenarioDialogueState.swift`
- Test: `VocabCraftAppTests/AI/ScenarioDialogueStateTests.swift`

**Interfaces:**
- Consumes: `RoleplayTopic` from `VocabCraftApp/Domain/Entities/RoleplayScenario.swift`
- Produces: `ScenarioDialogueState`, `DiningState`, `TravelState`, `InterviewState`, `DailyLifeState`

- [ ] **Step 1: Write the failing test**

Create `VocabCraftAppTests/AI/ScenarioDialogueStateTests.swift`:
```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("ScenarioDialogueState Tests")
struct ScenarioDialogueStateTests {
    @Test("DiningState identifies completed state correctly")
    func testDiningStateCompletion() {
        let state = ScenarioDialogueState.dining(.completed)
        #expect(state.isCompleted == true)

        let activeState = ScenarioDialogueState.dining(.ordering)
        #expect(activeState.isCompleted == false)
    }

    @Test("TravelState identifies completed state correctly")
    func testTravelStateCompletion() {
        let state = ScenarioDialogueState.travel(.completed)
        #expect(state.isCompleted == true)

        let activeState = ScenarioDialogueState.travel(.reservationCheck)
        #expect(activeState.isCompleted == false)
    }

    @Test("InterviewState and DailyLifeState identify completed state correctly")
    func testInterviewAndDailyLifeStateCompletion() {
        let interview = ScenarioDialogueState.interview(.completed)
        #expect(interview.isCompleted == true)

        let daily = ScenarioDialogueState.dailyLife(.completed)
        #expect(daily.isCompleted == true)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ScenarioDialogueStateTests`
Expected: FAIL with compilation error (types not found)

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Data/AI/DialogueFSM/ScenarioDialogueState.swift`:
```swift
import Foundation

public enum ScenarioDialogueState: Sendable, Equatable {
    case dining(DiningState)
    case travel(TravelState)
    case interview(InterviewState)
    case dailyLife(DailyLifeState)

    public var isCompleted: Bool {
        switch self {
        case .dining(let state): return state == .completed
        case .travel(let state): return state == .completed
        case .interview(let state): return state == .completed
        case .dailyLife(let state): return state == .completed
        }
    }
}

public enum DiningState: String, Sendable, Equatable, CaseIterable {
    case greeting
    case inquiry
    case ordering
    case customizing
    case payment
    case completed
}

public enum TravelState: String, Sendable, Equatable, CaseIterable {
    case greeting
    case inquiry
    case reservationCheck
    case idVerification
    case keyHandover
    case completed
}

public enum InterviewState: String, Sendable, Equatable, CaseIterable {
    case greeting
    case experienceDiscussion
    case behavioralChallenge
    case candidateQuestions
    case completed
}

public enum DailyLifeState: String, Sendable, Equatable, CaseIterable {
    case greeting
    case sharing
    case followUp
    case closing
    case completed
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ScenarioDialogueStateTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/DialogueFSM/ScenarioDialogueState.swift VocabCraftAppTests/AI/ScenarioDialogueStateTests.swift
git commit -m "feat(ai): define ScenarioDialogueState and lifecycle models for dialogue FSM"
```

---

### Task 2: Dialogue Intent Classification & Vietnamese Detection (`DialogueIntentClassifier.swift`)

**Files:**
- Create: `VocabCraftApp/Data/AI/DialogueFSM/DialogueIntentClassifier.swift`
- Test: `VocabCraftAppTests/AI/DialogueIntentClassifierTests.swift`

**Interfaces:**
- Consumes: Foundation string methods, `RoleplayScenario`
- Produces: `DialogueIntentClassifier`, `InDomainTopic`, `UserIntent`

- [ ] **Step 1: Write the failing test**

Create `VocabCraftAppTests/AI/DialogueIntentClassifierTests.swift`:
```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("DialogueIntentClassifier Tests")
struct DialogueIntentClassifierTests {
    @Test("Detects Vietnamese text with diacritics as nonEnglish")
    func testDetectsVietnameseWithDiacritics() {
        let classifier = DialogueIntentClassifier()
        let intent = classifier.classify(utterance: "Cho tôi một ly cà phê và bánh ngọt", scenario: RoleplayScenario.cafeMock)
        if case .nonEnglish(let detected) = intent {
            #expect(!detected.isEmpty)
        } else {
            Issue.record("Expected .nonEnglish intent, got \(intent)")
        }
    }

    @Test("Detects common unaccented Vietnamese phrases as nonEnglish")
    func testDetectsUnaccentedVietnamese() {
        let classifier = DialogueIntentClassifier()
        let intent = classifier.classify(utterance: "cho toi mot ly ca phe", scenario: RoleplayScenario.cafeMock)
        if case .nonEnglish = intent {
            // Success
        } else {
            Issue.record("Expected .nonEnglish intent for unaccented Vietnamese, got \(intent)")
        }
    }

    @Test("Detects in-domain inquiries for Wi-Fi and opening hours")
    func testDetectsInDomainInquiries() {
        let classifier = DialogueIntentClassifier()
        let wifiIntent = classifier.classify(utterance: "Do you have free wifi here?", scenario: RoleplayScenario.cafeMock)
        #expect(wifiIntent == .inDomainInquiry(topic: .wifi))

        let hoursIntent = classifier.classify(utterance: "What time do you close tonight?", scenario: RoleplayScenario.cafeMock)
        #expect(hoursIntent == .inDomainInquiry(topic: .openingHours))
    }

    @Test("Detects ordering and closing phrases correctly")
    func testDetectsOrderingAndClosing() {
        let classifier = DialogueIntentClassifier()
        let orderIntent = classifier.classify(utterance: "I would like a beverage and a pastry please", scenario: RoleplayScenario.cafeMock)
        #expect(orderIntent == .ordering)

        let closeIntent = classifier.classify(utterance: "Thank you so much, that is all, bye!", scenario: RoleplayScenario.cafeMock)
        #expect(closeIntent == .closing)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter DialogueIntentClassifierTests`
Expected: FAIL with compilation error (DialogueIntentClassifier does not exist)

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Data/AI/DialogueFSM/DialogueIntentClassifier.swift`:
```swift
import Foundation

public enum InDomainTopic: Sendable, Equatable {
    case wifi
    case openingHours
    case restroom
    case recommendation
    case decaf
    case amenities
    case breakfast
}

public enum UserIntent: Sendable, Equatable {
    case greeting
    case nonEnglish(detectedText: String)
    case inDomainInquiry(topic: InDomainTopic)
    case outOfDomainQuestion
    case ordering
    case customizing
    case paymentAction
    case closing
    case generalStatement
}

public struct DialogueIntentClassifier: Sendable {
    public init() {}

    private static let vietnameseDiacritics: CharacterSet = CharacterSet(
        charactersIn: "àáảãạăằắẳẵặâầấẩẫậđèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬĐÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴ"
    )

    private static let unaccentedVietnameseTokens: [String] = [
        "cho toi", "cho em", "ly ca phe", "ca phe", "bao nhieu", "co banh",
        "cam on", "tam biet", "nuoc loc", "tinh tien", "muon goi", "khong co",
        "lam on", "o dau", "may gio", "phong ve sinh", "co wifi"
    ]

    public func isVietnamese(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        // Tier 1: Check for Vietnamese accented characters
        if trimmed.unicodeScalars.contains(where: { Self.vietnameseDiacritics.contains($0) }) {
            return true
        }

        // Tier 2: Check for unaccented common Vietnamese word patterns
        let lower = trimmed.lowercased()
        for token in Self.unaccentedVietnameseTokens where lower.contains(token) {
            return true
        }

        return false
    }

    public func classify(utterance: String, scenario: RoleplayScenario) -> UserIntent {
        let trimmed = utterance.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .generalStatement }

        if isVietnamese(trimmed) {
            return .nonEnglish(detectedText: trimmed)
        }

        let lower = trimmed.lowercased()

        if isClosingPhrase(lower) {
            return .closing
        }
        if isPaymentPhrase(lower) {
            return .paymentAction
        }
        if let topic = detectInDomainInquiry(lower, scenarioTopic: scenario.topic) {
            return .inDomainInquiry(topic: topic)
        }
        if isOrderingPhrase(lower) {
            return .ordering
        }
        if isCustomizingPhrase(lower) {
            return .customizing
        }
        if isGreetingPhrase(lower) {
            return .greeting
        }
        if lower.hasSuffix("?") && isOutOfDomainQuestion(lower) {
            return .outOfDomainQuestion
        }

        return .generalStatement
    }

    private func detectInDomainInquiry(_ lower: String, scenarioTopic: RoleplayTopic) -> InDomainTopic? {
        if lower.contains("wifi") || lower.contains("wi-fi") || lower.contains("internet") {
            return .wifi
        }
        if lower.contains("open") || lower.contains("close") || lower.contains("hours") {
            return .openingHours
        }
        if lower.contains("restroom") || lower.contains("bathroom") || lower.contains("toilet") {
            return .restroom
        }
        if lower.contains("recommend") || lower.contains("specialty") || lower.contains("best-seller") || lower.contains("popular") {
            return .recommendation
        }
        if lower.contains("decaf") {
            return .decaf
        }
        if lower.contains("amenities") || lower.contains("pool") || lower.contains("gym") {
            return .amenities
        }
        if lower.contains("breakfast") {
            return .breakfast
        }
        return nil
    }

    private func isClosingPhrase(_ text: String) -> Bool {
        let closingTokens = [
            "goodbye", "bye", "see you", "that's all", "that is all",
            "thank you, bye", "have a good day", "have a great day", "check please"
        ]
        return closingTokens.contains { text.contains($0) }
    }

    private func isPaymentPhrase(_ text: String) -> Bool {
        let paymentTokens = [
            "card", "cash", "tap", "receipt", "keep the change", "pay", "here you go", "here is my"
        ]
        return paymentTokens.contains { text.contains($0) }
    }

    private func isOrderingPhrase(_ text: String) -> Bool {
        let orderingPhrases = [
            "i would like", "i'd like", "could i have", "can i get",
            "may i have", "please give me", "i will take", "i'll have",
            "order", "i want"
        ]
        return orderingPhrases.contains { text.contains($0) }
    }

    private func isCustomizingPhrase(_ text: String) -> Bool {
        let customizingTokens = [
            "hot", "iced", "warm", "heated", "large", "small", "medium", "single", "double", "regular"
        ]
        return customizingTokens.contains { text.contains($0) }
    }

    private func isGreetingPhrase(_ text: String) -> Bool {
        let greetings = ["hello", "hi", "hey", "good morning", "good afternoon", "good evening"]
        return greetings.contains { text.hasPrefix($0) || text == $0 }
    }

    private func isOutOfDomainQuestion(_ text: String) -> Bool {
        let unrelated = ["football", "soccer", "president", "weather", "crypto", "capital"]
        return unrelated.contains { text.contains($0) }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter DialogueIntentClassifierTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/DialogueFSM/DialogueIntentClassifier.swift VocabCraftAppTests/AI/DialogueIntentClassifierTests.swift
git commit -m "feat(ai): add DialogueIntentClassifier with on-device Vietnamese and inquiry detection"
```

---

### Task 3: Target Word Opportunity Injection (`TargetWordPrompter.swift`)

**Files:**
- Create: `VocabCraftApp/Data/AI/DialogueFSM/TargetWordPrompter.swift`
- Test: `VocabCraftAppTests/AI/TargetWordPrompterTests.swift`

**Interfaces:**
- Consumes: `RoleplayScenario`, `masteredTargetWords: Set<String>`
- Produces: `TargetWordPrompter.generatePrompt(missingWords:scenario:) -> (prompt: String, suggestion: String)?`

- [ ] **Step 1: Write the failing test**

Create `VocabCraftAppTests/AI/TargetWordPrompterTests.swift`:
```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("TargetWordPrompter Tests")
struct TargetWordPrompterTests {
    @Test("Prompts complimentary pastry when complimentary is missing in cafe")
    func testPromptsComplimentary() {
        let scenario = RoleplayScenario.cafeMock
        let prompt = TargetWordPrompter.generatePrompt(missingWords: ["complimentary"], scenario: scenario)

        #expect(prompt != nil)
        #expect(prompt?.characterSpeech.localizedCaseInsensitiveContains("complimentary") == true)
        #expect(prompt?.suggestedResponse.localizedCaseInsensitiveContains("complimentary") == true)
    }

    @Test("Returns nil when no missing words remain")
    func testReturnsNilWhenAllWordsUsed() {
        let scenario = RoleplayScenario.cafeMock
        let prompt = TargetWordPrompter.generatePrompt(missingWords: [], scenario: scenario)
        #expect(prompt == nil)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TargetWordPrompterTests`
Expected: FAIL with compilation error (TargetWordPrompter does not exist)

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Data/AI/DialogueFSM/TargetWordPrompter.swift`:
```swift
import Foundation

public struct TargetWordPromptResult: Sendable {
    public let characterSpeech: String
    public let suggestedResponse: String
    public let targetWord: String
}

public struct TargetWordPrompter: Sendable {
    public static func generatePrompt(missingWords: [String], scenario: RoleplayScenario) -> TargetWordPromptResult? {
        guard let targetWord = missingWords.first(where: { scenario.targetWordIds.contains($0) }) else {
            return nil
        }

        let normalized = targetWord.lowercased()

        switch scenario.topic {
        case .dining:
            switch normalized {
            case "complimentary":
                return TargetWordPromptResult(
                    characterSpeech: "Here is your drink! We also offer complimentary cookies today, would you like one?",
                    suggestedResponse: "Yes, I would love a complimentary cookie, please!",
                    targetWord: normalized
                )
            case "pastry":
                return TargetWordPromptResult(
                    characterSpeech: "Coming right up! Would you like to add a fresh pastry to pair with your drink today?",
                    suggestedResponse: "Yes, please add a fresh pastry.",
                    targetWord: normalized
                )
            case "beverage":
                return TargetWordPromptResult(
                    characterSpeech: "Should I prepare a delicious hot beverage for you as well?",
                    suggestedResponse: "Yes, a warm beverage would be great.",
                    targetWord: normalized
                )
            default:
                return TargetWordPromptResult(
                    characterSpeech: "Would you like to try our \(targetWord) today?",
                    suggestedResponse: "Yes, tell me more about the \(targetWord).",
                    targetWord: normalized
                )
            }

        case .travel:
            switch normalized {
            case "amenities":
                return TargetWordPromptResult(
                    characterSpeech: "Here is your keycard! Don't forget to check out our hotel amenities on the 5th floor.",
                    suggestedResponse: "What time are the hotel amenities open?",
                    targetWord: normalized
                )
            case "reservation":
                return TargetWordPromptResult(
                    characterSpeech: "May I double check the name on your reservation?",
                    suggestedResponse: "The reservation is under my full name.",
                    targetWord: normalized
                )
            case "accommodate":
                return TargetWordPromptResult(
                    characterSpeech: "Please let us know if there is anything else we can accommodate during your stay!",
                    suggestedResponse: "Could you accommodate a late checkout tomorrow?",
                    targetWord: normalized
                )
            default:
                return TargetWordPromptResult(
                    characterSpeech: "Please let us know if you need assistance with \(targetWord).",
                    suggestedResponse: "Thank you for the help with \(targetWord).",
                    targetWord: normalized
                )
            }

        case .interview, .workplace:
            switch normalized {
            case "collaborate":
                return TargetWordPromptResult(
                    characterSpeech: "Could you tell me how you collaborate with teammates when facing tough deadlines?",
                    suggestedResponse: "I actively collaborate with teammates to meet goals.",
                    targetWord: normalized
                )
            case "innovative":
                return TargetWordPromptResult(
                    characterSpeech: "Can you share an innovative approach you applied in your recent project?",
                    suggestedResponse: "We implemented an innovative system to streamline work.",
                    targetWord: normalized
                )
            default:
                return TargetWordPromptResult(
                    characterSpeech: "How do you view \(targetWord) in your daily work?",
                    suggestedResponse: "I value \(targetWord) in our project workflows.",
                    targetWord: normalized
                )
            }

        case .dailyLife:
            return TargetWordPromptResult(
                characterSpeech: "What are your thoughts on \(targetWord)?",
                suggestedResponse: "I think \(targetWord) is very helpful.",
                targetWord: normalized
            )
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TargetWordPrompterTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/DialogueFSM/TargetWordPrompter.swift VocabCraftAppTests/AI/TargetWordPrompterTests.swift
git commit -m "feat(ai): add TargetWordPrompter to inject natural opportunities for missing vocabulary"
```

---

### Task 4: Scenario State Reducer & Context Transition Engine (`ScenarioStateReducer.swift`)

**Files:**
- Create: `VocabCraftApp/Data/AI/DialogueFSM/ScenarioStateReducer.swift`
- Test: `VocabCraftAppTests/AI/ScenarioStateReducerTests.swift`

**Interfaces:**
- Consumes: `ScenarioDialogueState`, `UserIntent`, `TargetWordPrompter`, `RoleplayScenario`
- Produces: `ScenarioStateReducer.reduce(...) -> (nextState: ScenarioDialogueState, reply: String, suggestions: [String], isConcluded: Bool)`

- [ ] **Step 1: Write the failing test**

Create `VocabCraftAppTests/AI/ScenarioStateReducerTests.swift`:
```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("ScenarioStateReducer Tests")
struct ScenarioStateReducerTests {
    @Test("In-domain Wi-Fi inquiry transitions to inquiry state and does not charge money")
    func testInDomainWifiInquiry() {
        let result = ScenarioStateReducer.reduce(
            currentState: .dining(.greeting),
            intent: .inDomainInquiry(topic: .wifi),
            userUtterance: "Do you have wifi?",
            userTurnCount: 1,
            missingWords: ["beverage", "pastry"],
            scenario: RoleplayScenario.cafeMock
        )

        #expect(result.nextState == .dining(.inquiry))
        #expect(!result.characterReply.localizedCaseInsensitiveContains("$6.50"))
        #expect(result.characterReply.localizedCaseInsensitiveContains("wifi") || result.characterReply.localizedCaseInsensitiveContains("craftguest"))
        #expect(result.isConcluded == false)
    }

    @Test("Vietnamese speech returns in-character pedagogical nudge and keeps state")
    func testVietnamesePedagogicalNudge() {
        let result = ScenarioStateReducer.reduce(
            currentState: .dining(.greeting),
            intent: .nonEnglish(detectedText: "Cho tôi một ly cà phê"),
            userUtterance: "Cho tôi một ly cà phê",
            userTurnCount: 1,
            missingWords: ["beverage"],
            scenario: RoleplayScenario.cafeMock
        )

        #expect(result.nextState == .dining(.greeting))
        #expect(result.characterReply.contains("I only speak English here"))
        #expect(result.suggestedResponses.first?.contains("beverage") == true || result.suggestedResponses.first?.contains("coffee") == true)
        #expect(result.isConcluded == false)
    }

    @Test("Safety cap forces conclusion at turn 6")
    func testSafetyCapAtTurnSix() {
        let result = ScenarioStateReducer.reduce(
            currentState: .dining(.inquiry),
            intent: .generalStatement,
            userUtterance: "Tell me more",
            userTurnCount: 6,
            missingWords: [],
            scenario: RoleplayScenario.cafeMock
        )

        #expect(result.isConcluded == true)
        #expect(result.nextState.isCompleted == true)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ScenarioStateReducerTests`
Expected: FAIL with compilation error (ScenarioStateReducer does not exist)

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Data/AI/DialogueFSM/ScenarioStateReducer.swift`:
```swift
import Foundation

public struct ScenarioTurnResult: Sendable {
    public let nextState: ScenarioDialogueState
    public let characterReply: String
    public let suggestedResponses: [String]
    public let isConcluded: Bool
}

public struct ScenarioStateReducer: Sendable {
    public static let maxSafetyTurns: Int = 6

    public static func inferCurrentState(
        from history: [RoleplayMessage],
        topic: RoleplayTopic
    ) -> ScenarioDialogueState {
        let userTurns = history.filter { $0.sender == .user }
        guard !userTurns.isEmpty else {
            switch topic {
            case .dining: return .dining(.greeting)
            case .travel: return .travel(.greeting)
            case .interview, .workplace: return .interview(.greeting)
            case .dailyLife: return .dailyLife(.greeting)
            }
        }

        // Check if last character message indicated completed
        if let lastAi = history.last(where: { if case .character = $0.sender { return true } else { return false } }),
           lastAi.text.localizedCaseInsensitiveContains("have a wonderful day") ||
           lastAi.text.localizedCaseInsensitiveContains("enjoy your stay") ||
           lastAi.text.localizedCaseInsensitiveContains("follow up soon") {
            switch topic {
            case .dining: return .dining(.completed)
            case .travel: return .travel(.completed)
            case .interview, .workplace: return .interview(.completed)
            case .dailyLife: return .dailyLife(.completed)
            }
        }

        // Infer based on conversation progress
        let count = userTurns.count
        switch topic {
        case .dining:
            if count == 1 { return .dining(.customizing) }
            if count >= 2 { return .dining(.payment) }
            return .dining(.greeting)
        case .travel:
            if count == 1 { return .travel(.idVerification) }
            if count >= 2 { return .travel(.keyHandover) }
            return .travel(.greeting)
        case .interview, .workplace:
            if count == 1 { return .interview(.behavioralChallenge) }
            if count >= 2 { return .interview(.candidateQuestions) }
            return .interview(.greeting)
        case .dailyLife:
            if count == 1 { return .dailyLife(.followUp) }
            if count >= 2 { return .dailyLife(.closing) }
            return .dailyLife(.greeting)
        }
    }

    public static func reduce(
        currentState: ScenarioDialogueState,
        intent: UserIntent,
        userUtterance: String,
        userTurnCount: Int,
        missingWords: [String],
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        // Rule 1: Safety Cap check
        if userTurnCount >= maxSafetyTurns {
            let reply = "It has been so wonderful chatting with you! I will get everything finalized for you now, have a fantastic day ahead!"
            let completedState: ScenarioDialogueState
            switch scenario.topic {
            case .dining: completedState = .dining(.completed)
            case .travel: completedState = .travel(.completed)
            case .interview, .workplace: completedState = .interview(.completed)
            case .dailyLife: completedState = .dailyLife(.completed)
            }
            return ScenarioTurnResult(
                nextState: completedState,
                characterReply: reply,
                suggestedResponses: ["Thank you so much, goodbye!", "Have a great day!", "Take care!"],
                isConcluded: true
            )
        }

        // Rule 2: Explicit closing intent from user
        if intent == .closing && userTurnCount >= 2 {
            let reply = "Thank you so much! Here is your receipt and everything you need. Have a wonderful day!"
            let completedState: ScenarioDialogueState
            switch scenario.topic {
            case .dining: completedState = .dining(.completed)
            case .travel: completedState = .travel(.completed)
            case .interview, .workplace: completedState = .interview(.completed)
            case .dailyLife: completedState = .dailyLife(.completed)
            }
            return ScenarioTurnResult(
                nextState: completedState,
                characterReply: reply,
                suggestedResponses: ["Thanks so much, goodbye!", "Have a great day!", "See you next time!"],
                isConcluded: true
            )
        }

        // Rule 3: Non-English (Vietnamese) pedagogical nudge
        if case .nonEnglish = intent {
            let recommendedPhrase: String
            if scenario.topic == .dining {
                recommendedPhrase = "Could I have a beverage and a pastry, please?"
            } else if scenario.topic == .travel {
                recommendedPhrase = "I have a reservation under my name, please."
            } else {
                recommendedPhrase = "I would like to share my experience on this project."
            }
            let reply = "I only speak English here, but I'd love to help! You can say: '\(recommendedPhrase)'"
            let suggestions = [
                recommendedPhrase,
                "Could you recommend something for me?",
                "Sorry, could you help me in English?"
            ]
            return ScenarioTurnResult(
                nextState: currentState,
                characterReply: reply,
                suggestedResponses: suggestions,
                isConcluded: false
            )
        }

        // Rule 4: Topic-specific transitions
        switch currentState {
        case .dining(let diningState):
            return reduceDining(
                state: diningState,
                intent: intent,
                utterance: userUtterance,
                userTurnCount: userTurnCount,
                missingWords: missingWords,
                scenario: scenario
            )
        case .travel(let travelState):
            return reduceTravel(
                state: travelState,
                intent: intent,
                utterance: userUtterance,
                userTurnCount: userTurnCount,
                missingWords: missingWords,
                scenario: scenario
            )
        case .interview(let interviewState):
            return reduceInterview(
                state: interviewState,
                intent: intent,
                utterance: userUtterance,
                userTurnCount: userTurnCount,
                missingWords: missingWords,
                scenario: scenario
            )
        case .dailyLife(let dailyState):
            return reduceDailyLife(
                state: dailyState,
                intent: intent,
                utterance: userUtterance,
                userTurnCount: userTurnCount,
                missingWords: missingWords,
                scenario: scenario
            )
        }
    }

    private static func reduceDining(
        state: DiningState,
        intent: UserIntent,
        utterance: String,
        userTurnCount: Int,
        missingWords: [String],
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        if case .inDomainInquiry(let topic) = intent {
            let reply: String
            switch topic {
            case .wifi:
                reply = "Our Wi-Fi is CraftGuest with no password needed! What delicious drink can I get started for you while you connect?"
            case .openingHours:
                reply = "We're open until 9 PM every day! What can I prepare for you today?"
            case .restroom:
                reply = "The restroom is right down the hallway on the left! What drink or snack can I get started for you first?"
            case .decaf:
                reply = "Yes, all our espresso beverages can be prepared decaf! Would you like a decaf latte or americano?"
            case .recommendation, .amenities, .breakfast:
                reply = "Our hot caramel latte and fresh almond pastries are our customer favorites! Would you like to try one?"
            }
            return ScenarioTurnResult(
                nextState: .dining(.inquiry),
                characterReply: reply,
                suggestedResponses: [
                    "I'd like a caramel beverage and a pastry.",
                    "Do you have any decaf options?",
                    "That sounds wonderful, thank you!"
                ],
                isConcluded: false
            )
        }

        switch state {
        case .greeting, .inquiry:
            let reply = "Great choice! Would you like your beverage hot or iced? And should I warm up the pastry for you?"
            return ScenarioTurnResult(
                nextState: .dining(.customizing),
                characterReply: reply,
                suggestedResponses: [
                    "I'd prefer it hot, and please warm the pastry.",
                    "Iced beverage, please.",
                    "Could I get that to go?"
                ],
                isConcluded: false
            )

        case .customizing:
            if let wordPrompt = TargetWordPrompter.generatePrompt(missingWords: missingWords, scenario: scenario) {
                return ScenarioTurnResult(
                    nextState: .dining(.payment),
                    characterReply: "Coming right up! That will be $6.50. " + wordPrompt.characterSpeech,
                    suggestedResponses: [
                        wordPrompt.suggestedResponse,
                        "Here is my card to tap.",
                        "Just the drink is fine, thanks!"
                    ],
                    isConcluded: false
                )
            } else {
                return ScenarioTurnResult(
                    nextState: .dining(.payment),
                    characterReply: "Coming right up! That will be $6.50. You can tap your card right on the reader.",
                    suggestedResponses: [
                        "Here is my card to tap.",
                        "Could I also have a receipt, please?",
                        "Keep the change, have a great day!"
                    ],
                    isConcluded: false
                )
            }

        case .payment:
            return ScenarioTurnResult(
                nextState: .dining(.completed),
                characterReply: "All set! Here is your receipt and your fresh order. Thank you for visiting Craft Cafe, have a wonderful day!",
                suggestedResponses: [
                    "Thank you so much, have a great day!",
                    "Thanks, goodbye!",
                    "See you next time!"
                ],
                isConcluded: true
            )

        case .completed:
            return ScenarioTurnResult(
                nextState: .dining(.completed),
                characterReply: "Have a wonderful day, goodbye!",
                suggestedResponses: ["Goodbye!"],
                isConcluded: true
            )
        }
    }

    private static func reduceTravel(
        state: TravelState,
        intent: UserIntent,
        utterance: String,
        userTurnCount: Int,
        missingWords: [String],
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        switch state {
        case .greeting, .inquiry:
            return ScenarioTurnResult(
                nextState: .travel(.idVerification),
                characterReply: "Welcome! I found your reservation right here. May I please see your passport or ID card?",
                suggestedResponses: [
                    "Here is my passport and reservation details.",
                    "Could you confirm the reservation name?",
                    "Do you have room on a high floor?"
                ],
                isConcluded: false
            )
        case .reservationCheck, .idVerification:
            if let wordPrompt = TargetWordPrompter.generatePrompt(missingWords: missingWords, scenario: scenario) {
                return ScenarioTurnResult(
                    nextState: .travel(.keyHandover),
                    characterReply: "Thank you. Here is your keycard for room 402. " + wordPrompt.characterSpeech,
                    suggestedResponses: [
                        wordPrompt.suggestedResponse,
                        "Thank you for the keycard.",
                        "What time is checkout tomorrow?"
                    ],
                    isConcluded: false
                )
            } else {
                return ScenarioTurnResult(
                    nextState: .travel(.keyHandover),
                    characterReply: "Thank you. Here is your keycard for room 402. Complimentary breakfast is served from 6:30 to 10 AM. Enjoy your stay!",
                    suggestedResponses: [
                        "Thank you, have a wonderful day!",
                        "Could you tell me where the elevator is?",
                        "Thanks for your help!"
                    ],
                    isConcluded: false
                )
            }
        case .keyHandover, .completed:
            return ScenarioTurnResult(
                nextState: .travel(.completed),
                characterReply: "You're all set! Don't hesitate to dial 0 if you need anything at all. Have a wonderful stay with us!",
                suggestedResponses: ["Thank you so much!", "Goodbye!"],
                isConcluded: true
            )
        }
    }

    private static func reduceInterview(
        state: InterviewState,
        intent: UserIntent,
        utterance: String,
        userTurnCount: Int,
        missingWords: [String],
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        switch state {
        case .greeting, .experienceDiscussion:
            if let wordPrompt = TargetWordPrompter.generatePrompt(missingWords: missingWords, scenario: scenario) {
                return ScenarioTurnResult(
                    nextState: .interview(.behavioralChallenge),
                    characterReply: "Thank you for sharing that. " + wordPrompt.characterSpeech,
                    suggestedResponses: [
                        wordPrompt.suggestedResponse,
                        "I prioritize clear communication under deadlines.",
                        "I enjoy solving complex technical challenges."
                    ],
                    isConcluded: false
                )
            } else {
                return ScenarioTurnResult(
                    nextState: .interview(.behavioralChallenge),
                    characterReply: "That demonstrates excellent initiative. Could you tell me about a time you collaborated under a tight deadline?",
                    suggestedResponses: [
                        "I collaborated closely with the team to deliver on time.",
                        "We streamlined our tasks to meet the deadline.",
                        "Communication was key to our project success."
                    ],
                    isConcluded: false
                )
            }
        case .behavioralChallenge:
            return ScenarioTurnResult(
                nextState: .interview(.candidateQuestions),
                characterReply: "That is a great example of problem solving. Do you have any questions for us about the team or role?",
                suggestedResponses: [
                    "What does success look like in the first 90 days?",
                    "How does the team foster innovation?",
                    "Thank you, that covers my questions."
                ],
                isConcluded: false
            )
        case .candidateQuestions, .completed:
            return ScenarioTurnResult(
                nextState: .interview(.completed),
                characterReply: "Thank you for those insightful questions! We are very excited about your background and will follow up soon. Have a great day!",
                suggestedResponses: ["Thank you for your time, goodbye!", "I look forward to hearing from you!"],
                isConcluded: true
            )
        }
    }

    private static func reduceDailyLife(
        state: DailyLifeState,
        intent: UserIntent,
        utterance: String,
        userTurnCount: Int,
        missingWords: [String],
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        if userTurnCount <= 1 {
            return ScenarioTurnResult(
                nextState: .dailyLife(.followUp),
                characterReply: "That sounds very interesting! Could you tell me a little bit more about what you have in mind?",
                suggestedResponses: ["I was thinking about that yesterday.", "It really makes a big difference.", "What do you think?"],
                isConcluded: false
            )
        } else {
            return ScenarioTurnResult(
                nextState: .dailyLife(.completed),
                characterReply: "That covers everything wonderfully! Thank you for the great conversation, have a wonderful day!",
                suggestedResponses: ["Thank you, have a great day!", "See you soon!"],
                isConcluded: true
            )
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ScenarioStateReducerTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/DialogueFSM/ScenarioStateReducer.swift VocabCraftAppTests/AI/ScenarioStateReducerTests.swift
git commit -m "feat(ai): implement ScenarioStateReducer with stateless transition logic and in-character prompts"
```

---

### Task 5: Integrate FSM Subsystem into `OnDeviceContextDialogueEngine`

**Files:**
- Modify: `VocabCraftApp/Data/AI/OnDeviceContextDialogueEngine.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`
- Test: `VocabCraftAppTests/AI/OnDeviceContextDialogueEngineTests.swift`

**Interfaces:**
- Consumes: `DialogueIntentClassifier`, `ScenarioStateReducer`, `TargetWordPrompter`, `ScenarioDialogueState`
- Produces: `OnDeviceContextDialogueEngine.generateTurn(scenario:userUtterance:conversationHistory:)` leveraging FSM logic

- [ ] **Step 1: Write integration tests**

Update `VocabCraftAppTests/AI/OnDeviceContextDialogueEngineTests.swift` with multi-turn FSM test cases:
```swift
    @Test("Dining FSM transitions naturally without premature billing on inquiry")
    func testDiningFSMInquiryAndOrdering() async throws {
        let engine = OnDeviceContextDialogueEngine()
        let scenario = RoleplayScenario.cafeMock

        // Turn 1: User asks about Wi-Fi
        let output1 = try await engine.generateTurn(
            scenario: scenario,
            userUtterance: "Do you have free wifi here?",
            conversationHistory: []
        )
        #expect(!output1.characterReply.contains("$6.50"))
        #expect(output1.isConcluded == false)

        // Turn 2: User orders beverage and pastry
        let history1 = [
            RoleplayMessage(sender: .character(name: "Emma"), text: output1.characterReply),
            RoleplayMessage(sender: .user, text: "Do you have free wifi here?")
        ]
        let output2 = try await engine.generateTurn(
            scenario: scenario,
            userUtterance: "I'd like a hot beverage and a pastry please",
            conversationHistory: history1
        )
        #expect(output2.targetWordsUsed.contains("beverage") || output2.targetWordsUsed.contains("pastry"))
        #expect(output2.isConcluded == false)
    }

    @Test("Vietnamese utterance triggers pedagogical nudge with English suggested responses")
    func testVietnamesePedagogicalNudgeIntegration() async throws {
        let engine = OnDeviceContextDialogueEngine()
        let scenario = RoleplayScenario.cafeMock

        let output = try await engine.generateTurn(
            scenario: scenario,
            userUtterance: "Cho tôi một ly cà phê và bánh ngọt",
            conversationHistory: []
        )
        #expect(output.characterReply.contains("I only speak English here"))
        #expect(output.suggestedResponses.count == 3)
        #expect(output.isConcluded == false)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter OnDeviceContextDialogueEngineTests`
Expected: FAIL (because existing `OnDeviceContextDialogueEngine` does not yet call FSM components)

- [ ] **Step 3: Update `OnDeviceContextDialogueEngine.swift` and Xcode project**

Refactor `OnDeviceContextDialogueEngine.swift` to delegate turn generation to `DialogueIntentClassifier` and `ScenarioStateReducer`.
Register the new DialogueFSM files in `VocabCraftApp.xcodeproj/project.pbxproj` so they compile in Xcode targets.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter OnDeviceContextDialogueEngineTests`
Expected: PASS

- [ ] **Step 5: Run full test suite & SwiftLint**

Run: `swift test` and `swiftlint lint`
Expected: 100% pass, 0 lint warnings

- [ ] **Step 6: Commit**

```bash
git add VocabCraftApp/Data/AI/OnDeviceContextDialogueEngine.swift VocabCraftApp.xcodeproj/project.pbxproj VocabCraftAppTests/AI/OnDeviceContextDialogueEngineTests.swift
git commit -m "feat(ai): integrate DialogueFSM into OnDeviceContextDialogueEngine with seamless multi-turn progression"
```

---

### Task 6: Full Verification & Build Quality Gate

**Files:**
- Test all AI packs, voice conversations, and Xcode build settings

- [ ] **Step 1: Run complete test suite**

Run: `swift test`
Expected: All 682+ tests passing.

- [ ] **Step 2: Run Localization Tests**

Run: `swift test --filter LocalizationTests`
Expected: All 43 localization tests passing.

- [ ] **Step 3: Run SwiftLint**

Run: `swiftlint lint --strict`
Expected: 0 violations, 0 warnings.

- [ ] **Step 4: Run Xcodebuild for Simulator**

Run: `xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **` with 0 warnings.

- [ ] **Step 5: Final Git Status Check**

Run: `git status`
Expected: Clean working tree.
