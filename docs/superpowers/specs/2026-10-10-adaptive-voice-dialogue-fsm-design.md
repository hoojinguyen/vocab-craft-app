# Technical Design Specification: Adaptive Multi-Turn Voice Dialogue FSM & Pedagogical Guidance

- **Author**: Antigravity Agent
- **Date**: 2026-10-10
- **Status**: Approved by User
- **Scope**: `VocabCraftApp` Core Audio/AI, `OnDeviceContextDialogueEngine`, `DialogueFSM`, `LlamaInferenceWorker`, `AppleIntelligenceOrLocalDialogueProvider`, Unit Tests
- **Dependencies**: `CraftUIKit`, `SpeechKit`, Foundation

---

## 1. Executive Summary

In voice roleplay mode (Live Call), users interact verbally with AI characters (e.g. Emma the Barista) to practice pronunciation and target vocabulary in realistic scenarios. 

Previously, turn progression on on-device engines relied on a simple linear turn counter (`turn <= 1`, `turn == 2`, `turn >= 3`). While functional for scripted turns, this model failed when users asked off-topic questions (e.g., asking for Wi-Fi or menu recommendations), spoken non-English / Vietnamese utterances, or engaged in non-linear dialogues—sometimes causing characters to prematurely charge money, skip ordering, or repeatedly loop the greeting.

This specification designs an on-device **Finite State Machine (FSM) Dialogue Architecture** with:
1. **Scenario-Specific Dialogue States**: Custom states for Cafe/Dining, Travel/Hotel, Interview/Workplace, and Daily Life.
2. **On-Device Vietnamese & Non-English Detection**: In-character pedagogical nudges (*"I only speak English here! You can say: '...' "*) accompanied by translated 3-branch English suggestions.
3. **Target Word Opportunity Injection**: Natural character prompting for unused target words (e.g., complimentary snacks/cookies) before conclusion.
4. **Adaptive Pacing & Safety Cap**: Goal-driven conclusion with a 6-turn safety cap to prevent cognitive exhaustion.
5. **Zero Breaking Changes**: Stateless reducer pattern inferring state from conversation history, requiring 0 schema migrations and maintaining 100% backward compatibility.

---

## 2. Core Architecture & Component Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           VocabCraftApp (iOS / iPadOS)                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│          TurnBasedVoiceConversationEngine / ExecuteRoleplayTurnUseCase          │
│                                       │                                         │
│                                       ▼                                         │
│                      OnDeviceContextDialogueEngine                              │
│                                       │                                         │
│            ┌──────────────────────────┼──────────────────────────┐              │
│            ▼                          ▼                          ▼              │
│  DialogueIntentClassifier   ScenarioStateReducer       TargetWordPrompter       │
│  (Unicode Vietnamese        (Topic-specific FSM        (Injects opportunities   │
│   + In-Domain Inquiries)     State Transitions)         for missing words)      │
│            │                          │                          │              │
│            └──────────────────────────┼──────────────────────────┘              │
│                                       ▼                                         │
│                              RoleplayTurnOutput                                 │
│                   (Character Reply, 3 Branches, Feedback)                       │
│                                       │                                         │
│                   ┌───────────────────┴───────────────────┐                     │
│                   ▼                                       ▼                     │
│        LlamaInferenceWorker           AppleIntelligenceOrLocalDialogueProvider  │
│        (Offline AI Pack)                      (Apple Default Pack)              │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Technical Design

### 3.1 Scenario-Specific Dialogue FSM (`ScenarioDialogueState.swift`)

Each scenario topic possesses distinct lifecycle stages reflecting real-world human interactions:

```swift
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

public enum DiningState: String, Sendable, Equatable {
    case greeting        // Initial welcome: "Welcome to Craft Cafe! What can I get for you?"
    case inquiry         // Answering questions regarding menu, Wi-Fi, decaf, recommendations
    case ordering        // User orders item(s) containing target vocabulary (beverage, pastry)
    case customizing     // Character asks for details (hot/iced, warmed pastry, size)
    case payment         // Bill presentation ($6.50), card tap, or prompting missing target word
    case completed       // Receipt & order handed over, polite farewell
}

public enum TravelState: String, Sendable, Equatable {
    case greeting
    case inquiry         // Amenities, breakfast hours, pool location
    case reservationCheck// User provides reservation details
    case idVerification  // Passport / ID request
    case keyHandover     // Room keycard, complimentary breakfast 안내
    case completed
}

public enum InterviewState: String, Sendable, Equatable {
    case greeting
    case experienceDiscussion // Experience, strengths
    case behavioralChallenge  // Handling deadlines, collaboration, innovative approaches
    case candidateQuestions   // Inviting candidate to ask questions
    case completed
}

public enum DailyLifeState: String, Sendable, Equatable {
    case greeting
    case sharing
    case followUp
    case closing
    case completed
}
```

### 3.2 Enhanced Intent Classification & Vietnamese Detection (`DialogueIntentClassifier.swift`)

```swift
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
```

#### On-Device Vietnamese Detection Algorithm
1. **Tier 1 (Diacritic Unicode Matching):**
   Scans for accented characters: `à, á, ả, ã, ạ, ă, ằ, ắ, ẳ, ẵ, ặ, â, ầ, ấ, ẩ, ẫ, ậ, đ, è, é, ẻ, ẽ, ẹ, ê, ề, ế, ể, ễ, ệ, ì, í, ỉ, ĩ, ị, ò, ó, ỏ, õ, ọ, ô, ồ, ố, ổ, ỗ, ộ, ơ, ờ, ớ, ở, ỡ, ợ, ù, ú, ủ, ũ, ụ, ư, ừ, ứ, ử, ữ, ự, kỳ, ký, kỷ, kỹ, kỵ`...
2. **Tier 2 (Common Unaccented Phrases):**
   Matches phrases such as `cho toi`, `cho em`, `ly ca phe`, `bao nhieu`, `co banh khong`, `cam on`, `tam biet`, `muon goi`, `nuoc loc`, `tinh tien`...
3. **Pedagogical In-Character Nudge Response:**
   - Persona remains 100% in character:
     *"I only speak English here, but I'd love to help! You can say: 'Could I have a beverage and a pastry, please?'"*
   - The 3-branch suggestions drawer instantly populates with the English translation conforming to target vocabulary.

#### In-Domain Side Question Handling:
- Wi-Fi: *"Our Wi-Fi is CraftGuest, no password needed! What drink can I get started for you while you connect?"*
- Restroom: *"It's right down the hallway on the left! What can I prepare for you before you head over?"*
- Hours: *"We're open until 9 PM tonight! Can I get your order ready?"*
- Keeps current state at `.inquiry` instead of incorrectly advancing to `.payment`.

### 3.3 State Transition Reducer (`ScenarioStateTransitions.swift`)

The FSM runs as a **Stateless Reducer**:
```swift
public struct ScenarioStateReducer: Sendable {
    public static func inferCurrentState(
        from history: [RoleplayMessage],
        topic: RoleplayTopic
    ) -> ScenarioDialogueState

    public static func nextState(
        currentState: ScenarioDialogueState,
        intent: UserIntent,
        userUtterance: String,
        userTurnCount: Int,
        missingTargetWords: [String]
    ) -> ScenarioDialogueState
}
```

#### Transition Rules (Dining / Cafe):
- `.greeting` + `.inDomainInquiry` $\rightarrow$ `.inquiry`
- `.greeting` or `.inquiry` + `.ordering` $\rightarrow$ `.customizing`
- `.customizing` + `.customizing` / details $\rightarrow$ `.payment`
- `.payment` + `.paymentAction` + missing words $\rightarrow$ `.payment` (prompting missing word)
- `.payment` + `.paymentAction` + 0 missing words $\rightarrow$ `.completed`
- Any state + `.closing` (when `userTurnCount >= 2`) $\rightarrow$ `.completed`
- Any state + `.nonEnglish` $\rightarrow$ remains in `currentState` (pedagogical nudge)
- Any state + `userTurnCount >= 6` $\rightarrow$ `.completed` (safety cap)

### 3.4 Target Word Opportunity Injection (`TargetWordPrompter.swift`)

Before transitioning from `.payment` to `.completed`:
1. Check `missingWords = targetWords - masteredWords`.
2. If `missingWords` is not empty, generate an in-character prompt offering the missing item:
   - Missing `complimentary`: *"Here is your order! We also offer complimentary cookies at the counter, would you like one?"*
   - Missing `pastry`: *"Coming right up! Would you like to add a fresh pastry to pair with your drink today?"*
   - Missing `beverage`: *"Great! Should I get a hot beverage started for you as well?"*
3. Update Branch 1 suggestion to: *"Yes, I would love a complimentary cookie, please!"*.
4. On the subsequent user turn, the word is detected and the call concludes naturally.

---

## 4. Error Handling & Quality Guardrails

1. **Strict Non-Fallback & Zero Hallucination**:
   All JSON generations strictly conform to `RoleplayTurnOutput` keys: `characterReply`, `targetWordsUsed`, `refinementSuggestion`, `pedagogicalNote`, `suggestedResponses`, `isConcluded`.
2. **Graceful Out-of-Domain Recovery**:
   When users ask completely unrelated questions (sports, politics), characters respond with playful in-character redirection back to the scenario.
3. **Turn Limits & Cognitive Protection**:
   Safety cap strictly capped at 6 turns. Never permits runaway loops.

---

## 5. File Structure & Scope of Changes

### New / Refactored Files:
- `VocabCraftApp/Data/AI/DialogueFSM/ScenarioDialogueState.swift`
- `VocabCraftApp/Data/AI/DialogueFSM/DialogueIntentClassifier.swift`
- `VocabCraftApp/Data/AI/DialogueFSM/ScenarioStateReducer.swift`
- `VocabCraftApp/Data/AI/DialogueFSM/TargetWordPrompter.swift`
- `VocabCraftApp/Data/AI/OnDeviceContextDialogueEngine.swift` (Orchestrates FSM components)
- `VocabCraftAppTests/AI/OnDeviceContextDialogueEngineTests.swift` (Comprehensive suite)

---

## 6. Verification & Testing Plan

1. **FSM Flow Tests**:
   - Cafe sequential ordering flow (`greeting` $\rightarrow$ `inquiry` $\rightarrow$ `ordering` $\rightarrow$ `customizing` $\rightarrow$ `payment` $\rightarrow$ `completed`).
   - Wi-Fi inquiry does not prematurely request payment.
2. **Vietnamese Language Tests**:
   - Diacritic phrases (*"Cho tôi một ly cà phê"*) trigger in-character English nudge and translated suggestions.
   - Unaccented phrases (*"cho toi mot ly ca phe"*) properly detected.
3. **Word Prompting Tests**:
   - Missing `complimentary` triggers counter cookie prompt before conclusion.
4. **Safety Cap Tests**:
   - 6th turn forces completion with polite wrap-up.
5. **Full Regression Test**:
   - Full suite execution: `swift test` (682+ tests).
   - SwiftLint: 0 violations, 0 warnings.
   - Xcodebuild: Clean build for iOS Simulator with 0 warnings.
