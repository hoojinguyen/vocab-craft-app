# AI Assistant: Scenario Roleplay Technical Design Specification

- **Date**: 2026-09-22
- **Topic**: AI Assistant Scenario Roleplay Subsystem
- **Status**: Approved by User, Ready for Implementation Planning
- **Classification**: Architectural

---

## 1. Executive Summary & Problem Statement

### 1.1 Context
VocabCraft currently offers an engaging gamified vocabulary acquisition path ([HomepageView.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Homepage/Views/HomepageView.swift)), spaced repetition drills ([ReflexBlitzView.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift)), and a structured word vault ([VocabularyView.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift)). However, Tab 3 on the main navigation bar is currently occupied by [AIAssistantPlaceholderView.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/AIAssistant/Views/AIAssistantPlaceholderView.swift), which acts as a "Coming Soon" placeholder.

### 1.2 The Problem
Language learners frequently develop "passive vocabulary" (recognizing words and recalling definitions in multiple-choice quizzes) but struggle to activate those words in real conversations ("active production").

### 1.3 The Solution
Implement the **AI Scenario Roleplay** subsystem: an immersive, conversational environment where learners interact with AI characters across diverse real-world situations (ordering coffee, job interview, hotel check-in). The system gamifies active production by pinning **Target Words** (derived from the learner's weak SRS words and recent lessons), recognizing them in speech/text, providing non-intrusive refinement suggestions, and feeding successful usage back into the Spaced Repetition System ([SRSEngine.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/SRS/SRSEngine.swift)).

---

## 2. Goals & Non-Goals

### 2.1 Goals
- **Provider-Agnostic LLM Architecture**: Abstract LLM communication via `LLMProviderProtocol` so the app is completely decoupled from any specific vendor (Google Gemini as the initial provider, with ready expansion to OpenAI, Anthropic Claude, or Apple On-Device Intelligence).
- **Offline & Preview Testability**: Provide a deterministic `MockLLMProvider` enabling 100% of unit tests, UI tests, and SwiftUI previews to run without network connectivity or API quota consumption.
- **Adaptive Daily Scenario**: Dynamically generate or recommend scenarios targeting the learner's weakest SRS words ([ReviewWeakWordsUseCase.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/UseCases/ReviewWeakWordsUseCase.swift)).
- **Tactile Gamification**: Real-time Target Word chips with haptic feedback and spring animations upon successful usage during conversation.
- **Zero Hardcoded Strings & CraftUIKit-First**: 100% adherence to project design tokens and complete bilingual (English & Vietnamese) parity in `Localizable.xcstrings`.

### 2.2 Non-Goals (Future Phases)
- Free-form multi-agent group chats (deferred to Phase 2).
- Real-time full-duplex WebSocket audio streaming (initial implementation uses turn-based SpeechKit transcription + text LLM + TTS playback).
- Custom scenario authoring by end-users (catalog + adaptive generation are prioritized).

---

## 3. Architecture & LLM Provider Abstraction

```
┌─────────────────────────────────────────────────────────────┐
│                 AIAssistant Feature Layer                   │
│   AIAssistantHubView ──> RoleplayRoomView ──> SummaryView   │
│                 AIAssistantViewModel                        │
└──────────────────────────────┬──────────────────────────────┘
                               │ uses
┌──────────────────────────────▼──────────────────────────────┐
│                    Domain Layer (Use Cases)                 │
│  FetchScenariosUseCase  ExecuteTurnUseCase  CompleteSession │
└──────────────────────────────┬──────────────────────────────┘
                               │ calls
┌──────────────────────────────▼──────────────────────────────┐
│                 LLMProviderProtocol (Core)                  │
│       sendStructuredMessage<T>(messages, prompt, schema)     │
└──────────────┬───────────────────────────────┬──────────────┘
               │ conforms                      │ conforms
┌──────────────▼──────────────┐ ┌──────────────▼──────────────┐
│      GeminiLLMProvider      │ │        MockLLMProvider      │
│  (Google Gemini 1.5/2.0     │ │ (Deterministic for Unit     │
│   Flash REST / SDK Client)  │ │  Tests & SwiftUI Previews)  │
└─────────────────────────────┘ └─────────────────────────────┘
```

### 3.1 Provider Protocol Definition
Located in `VocabCraftApp/Domain/Protocols/LLMProviderProtocol.swift`:

```swift
public protocol LLMProviderProtocol: Sendable {
    var providerIdentifier: String { get }
    
    /// Sends chat history and prompt, returning strongly typed structured output.
    func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T
}

public struct LLMChatMessage: Codable, Sendable, Equatable {
    public enum Role: String, Codable, Sendable {
        case user
        case model
        case system
    }
    
    public let role: Role
    public let content: String
    
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}
```

### 3.2 Single-Turn Structured Generation Schema
Located in `VocabCraftApp/Domain/Entities/RoleplayTurnOutput.swift`:

```swift
public struct RoleplayTurnOutput: Codable, Sendable, Equatable {
    /// In-character response spoken/displayed to the learner
    public let characterReply: String
    
    /// Exact target words the learner successfully produced in their utterance
    public let targetWordsUsed: [String]
    
    /// Optional subtle suggestion for a more natural phrasing
    public let refinementSuggestion: String?
    
    /// Brief encouraging pedagogical note or context nuance
    public let pedagogicalNote: String?
}
```

---

## 4. Domain Entities & Use Cases

### 4.1 Entities
- **`RoleplayScenario`**:
  - `id: String`
  - `titleKey: String` (localization key)
  - `descriptionKey: String`
  - `topic: ScenarioTopic` (`.travel`, `.workplace`, `.dailyLife`, `.dining`, `.interview`)
  - `difficulty: ScenarioDifficulty` (`.beginner`, `.intermediate`, `.advanced`)
  - `characterName: String`
  - `characterRole: String`
  - `userRole: String`
  - `initialGreeting: String`
  - `targetWordIds: [String]`
  - `iconSymbol: String` (CraftSymbol raw value)
- **`RoleplayMessage`**:
  - `id: UUID`
  - `sender: MessageSender` (`.user`, `.character(name: String)`)
  - `text: String`
  - `timestamp: Date`
  - `refinement: String?`
  - `pedagogicalNote: String?`
- **`RoleplaySessionSummary`**:
  - `scenarioId: String`
  - `totalTurns: Int`
  - `targetWordsAttempted: [String]`
  - `targetWordsMastered: [String]`
  - `fluencyScore: Int` (0-100)
  - `xpEarned: Int`
  - `refinementsSummary: [SentenceRefinementPair]`

### 4.2 Use Cases
1. **`FetchRoleplayScenariosUseCase`**:
   - Loads bundled scenario templates.
   - Leverages `ReviewWeakWordsUseCase` to identify the user's lowest-mastery words and synthesizes a **"Daily Adaptive Scenario"**.
2. **`ExecuteRoleplayTurnUseCase`**:
   - Receives learner input.
   - Performs client-side target word matching for instant optimistic feedback.
   - Formulates system prompt and queries `LLMProviderProtocol`.
   - Returns validated `RoleplayTurnOutput`.
3. **`CompleteRoleplaySessionUseCase`**:
   - Computes mastery updates via [SRSEngine.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/SRS/SRSEngine.swift) for all successfully produced target words (`isCorrect: true, quality = 5`).
   - Persists updated word mastery to SwiftData via `SRSRepositoryProtocol`.
   - Records session statistics and updates daily streak progress.

---

## 5. UI/UX Architecture & CraftUIKit Components

### 5.1 Screen 1: `AIAssistantHubView` (Replaces `AIAssistantPlaceholderView`)
- Replaces [AIAssistantPlaceholderView.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/AIAssistant/Views/AIAssistantPlaceholderView.swift).
- **Header**: `CraftPageHeader` titled `app.ai_assistant.hub.title`.
- **Hero Card**: `CraftCard(style: .outlined)` showcasing the **Daily Adaptive Scenario** with:
  - `CraftBadge` ("Daily Mission").
  - Target word chips (`CraftBadge(variant: .subtle)`).
  - Primary CTA button `CraftButton` ("Start Roleplay").
- **Topic Filter**: Horizontal scroll strip of category pills.
- **Scenario Grid**: 2-column or list view of scenarios with difficulty badges, icons, and word counts.

### 5.2 Screen 2: `RoleplayRoomView`
- **Top Navigation Bar**:
  - Exit button with native confirmation dialog (`"Discard active session?"`).
  - Character avatar and name/role display.
  - "Finish" button to conclude session early.
- **Pinned Target Words Strip**:
  - Horizontal bar below header showing required words.
  - State transitions:
    - *Pending*: Neutral subtle tone.
    - *Used*: Spring animation to `statusSuccess`, light haptic pulse.
- **Dialogue Stream (`ScrollViewReader`)**:
  - AI bubble: Left-aligned, `surfaceCard` style, replay audio button (`CraftIconButton`).
  - Learner bubble: Right-aligned, `brandPrimary` style.
  - Subtle Refinement Expander: An interactive pill below the user bubble (`💡 Refine phrasing`) that smoothly expands to show the suggested phrasing without breaking conversation flow.
- **Bottom Input Bar**:
  - Voice mode: Dictation using [SpeechKit](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/SpeechKit/Package.swift) with audio waveform pulse.
  - Text mode: Rounded text field with send button.

### 5.3 Screen 3: `RoleplaySummaryView`
- Confetti celebration `CraftConfetti` for $\ge 80\%$ target word completion.
- Fluency score and word mastery count.
- SRS level-up badges (`+1 Mastery Level`).
- List of key takeaways comparing user utterances with refined native alternatives.
- Action buttons: "Practice Again" or "Return to Hub".

---

## 6. Audio, Speech & Error Handling Integration

### 6.1 Speech & TTS
- **Voice In**: Integrated via `Packages/SpeechKit` (`SpeechRecognitionService`). Streams transcribed speech directly into the input text field.
- **Voice Out**: Integrated via `VocabCraftApp/Core/Audio/TTSService.swift`. Automatically vocalizes character replies when voice mode is active.

### 6.2 Error Resilience
- **Network Outage**: Displays non-blocking `CraftToast`. User utterance is preserved; a "Retry" button resends the last turn.
- **Invalid API Key / Quota 429**: In development/testing, falls back gracefully to `MockLLMProvider` with a warning toast. In production, guides user to check internet or subscription.
- **Malformed LLM Output**: Strict JSON decoding with fallback parser that extracts plain text if JSON schema is compromised, preventing view crashes.

---

## 7. Localization & Zero Hardcoded Strings

All user-visible copy must be registered in `VocabCraftApp/Resources/Localizable.xcstrings` under the `app.ai_assistant.*` taxonomy with complete English and Vietnamese translations.

### Key Catalog Entries
- `app.ai_assistant.hub.title`:
  - `en`: "AI Assistant"
  - `vi`: "Trợ lý AI"
- `app.ai_assistant.hub.daily_mission`:
  - `en`: "Today's Adaptive Scenario"
  - `vi`: "Tình huống đề xuất hôm nay"
- `app.ai_assistant.room.target_words_title`:
  - `en`: "Target Words"
  - `vi`: "Từ vựng mục tiêu"
- `app.ai_assistant.room.refine_button`:
  - `en`: "💡 See natural phrasing"
  - `vi`: "💡 Xem gợi ý diễn đạt tự nhiên"
- `app.ai_assistant.room.finish_session`:
  - `en`: "Finish Session"
  - `vi`: "Kết thúc phiên"
- `app.ai_assistant.summary.congratulations`:
  - `en`: "Great conversation!"
  - `vi`: "Cuộc trò chuyện tuyệt vời!"
- `app.ai_assistant.summary.srs_updated`:
  - `en`: "Mastery upgraded in SRS"
  - `vi`: "Đã nâng cấp độ nhớ trong SRS"
- `app.ai_assistant.error.network_failed`:
  - `en`: "Unable to connect to AI service. Tap to retry."
  - `vi`: "Không thể kết nối tới dịch vụ AI. Chạm để thử lại."

---

## 8. Verification & Testing Strategy

### 8.1 Automated Unit Tests
- `LLMProviderTests`: Test `MockLLMProvider` JSON schema encoding/decoding and error handling.
- `ExecuteRoleplayTurnUseCaseTests`: Verify target word matching heuristics, prompt assembly, and response parsing.
- `CompleteRoleplaySessionUseCaseTests`: Verify SRS mastery increments (`SRSEngine`) and persistence to repository.
- `AIAssistantHubViewModelTests`: Verify scenario loading and daily adaptive scenario selection logic.
- `RoleplayRoomViewModelTests`: Verify message appending, state changes (`idle`, `transcribing`, `thinking`, `streaming`), and target word achievement triggers.

### 8.2 Localization & Quality Gates
- SwiftLint: 0 errors, 0 warnings.
- Compiler: 0 errors, 0 warnings.
- Localization test: Verify EN and VI parity for all `app.ai_assistant.*` keys.
