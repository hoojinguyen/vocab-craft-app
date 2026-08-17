# Design Specification: Spoken Reflex Blitz (Continuous Spoken Vocabulary Speed Run)

Date: 2026-08-17  
Status: Approved for implementation planning

---

## 1. Purpose and Scope

Redesign and elevate **"Luyện phản xạ từ mới" (Reflex Drill)** into a high-energy, session-centric **"Spoken Reflex Blitz"** mini-game mode in VocabCraft:
- Learner engages in a fast-paced, voice-first continuous sprint of 5–10 due/targeted vocabulary words (~90–120 seconds total session).
- Eliminates the cognitive "mental translation bottleneck" (Translating Vietnamese -> English in head) by training instantaneous spoken production directly from contextual cloze sentences under soft time constraints.
- Utilizes a **Continuous Warm Speech Engine** to ensure zero latency between cards (no start/stop audio engine stutter).
- Features **Progressive Scaffolding** (subtle hint at 3.5s, auto-advance at 6.0s timeout), a **Flow-State Combo System**, and an end-of-session **Speed & Mastery Dashboard** with a 1-tap **"Củng cố từ yếu" (Instant Re-drill)** action.

---

## 2. Learner Experience & Step-by-Step Flow

```mermaid
graph TD
    A[Launch Reflex Blitz from Home / Deck] --> B[3-2-1 Countdown & Mic Warm-up]
    B --> C[Active Word Challenge: Cloze Context]
    C -->|Spoken Match < 2.5s| D[⚡️ Flash Success & Combo +1]
    C -->|At 3.5s: Show POS + First Letter Hint| E[💡 Hinted Recall]
    C -->|At 6.0s: Timeout| F[⚠️ Show Target & Play Audio Model]
    D -->|Auto-advance in 400ms| G{More Words in Session?}
    E -->|Spoken Match < 6.0s| G
    F -->|Auto-advance in 1.2s| G
    G -->|Yes| C
    G -->|No (Completed 5-10 words)| H[Speed & Mastery Dashboard]
    H -->|1-Tap Action| I[Re-drill Weak Words / Finish to Home]
```

### Step 1: Countdown & Audio Warm-up (3... 2... 1... GO!)
* A compact overlay initializes microphone permissions and starts the `AVAudioEngine` in continuous background mode to eliminate cold-start latency.
* Visual pulse transitions learners directly into the blitz flow.

### Step 2: Contextual Cloze Challenge (~3–6s per word)
* **Prompt Card**:
  * English sentence with blank: e.g. `"Her fame proved to be [ _________ ]."`
  * Concise Vietnamese subtitle below: `(Danh tiếng của cô ấy chỉ là phù du)`
  * Visual blink indicator on the blank space inviting immediate vocal response.
* **Input**: Default is 100% voice recognition. A small fallback keyboard icon (⌨️) is available at the bottom corner for quiet environments.
* **Progressive Scaffolding**:
  * $0.0\text{s} - 3.5\text{s}$: Pure recall phase without clues.
  * At $3.5\text{s}$: Dynamic pill slides in with hint: `💡 Gợi ý: adj. • e...`
  * At $6.0\text{s}$ (Timeout): Card highlights in coral/peach, reveals the answer `ephemeral`, plays native TTS audio once ($1.2\text{s}$), flags word as *Needs Practice*, and auto-advances to the next word.

### Step 3: Instant Recognition & Zero-Latency Progression
* **Instant Match**: When the learner utters the target lemma (evaluated via `TargetExpressionMatcher`), the app triggers:
  * Green flash pulse & subtle haptic feedback (`.impact(weight: .medium)`).
  * Floating Combo streak: `🔥 x3 COMBO`.
  * Auto-transition to the next card in $400\text{ms}$ without requiring any manual button taps.

### Step 4: Speed & Mastery Dashboard (End of Session)
* **Performance Summary**:
  * Average Response Time ($\bar{t}$, e.g. `1.8s/từ` - *⚡️ Reflex Master*).
  * Accuracy percentage (e.g. `8/10 từ đạt chuẩn`).
  * Max Combo Streak.
* **Word Map**:
  * ⚡️ *Phản xạ chớp nhoáng* (Target time $< 2.5\text{s}$)
  * 💡 *Nhớ có trợ giúp* ($2.5\text{s} - 6.0\text{s}$)
  * ⚠️ *Từ cần cải thiện* ($> 6.0\text{s}$ or skipped)
* **Actions**:
  * **"🔥 Củng cố ngay X từ yếu"**: 1-tap micro sprint targeting only the failed/slow words.
  * **"Hoàn thành & Lưu tiến độ"**: Applies SRS updates and returns to the home screen.

---

## 3. Speech Engine & Latency Architecture

### Continuous Audio Buffer Management
* Instead of calling `startListening()` and `stopListening()` per card, `ContinuousReflexSpeechService` retains an active `AVAudioEngine` stream throughout the entire session.
* On each card transition:
  * Speech recognition buffer is reset in $<10\text{ms}$.
  * Lemmatizer dictionary context is swapped to the new `targetLemma` and contextual phrases (`exampleSentenceEn`, `distractors`).
* This achieves zero stutter and preserves high-adrenaline immersion.

---

## 4. Spaced Repetition (SRS) & Scoring Rules

| Category | Trigger Criteria | Mastery & SRS Impact |
| :--- | :--- | :--- |
| **⚡️ Flash Reflex** | Spoken match in $< 2.5\text{s}$ without hint | Mastery Level $+1$, Interval expanded ($\times 2.5$), Ease Factor $+0.1$ |
| **💡 Hinted Recall** | Spoken match in $2.5\text{s} - 6.0\text{s}$ (with hint) | Mastery Level maintained, short review interval ($1-2$ days) |
| **⚠️ Needs Practice** | Timeout ($6.0\text{s}$) or Skip | Mastery Level reset to $0$, scheduled for urgent next-day review |

*Note on Re-drill*: Completing a successful immediate re-drill promotes a word from *Weak* to *Recovered*, preventing severe SRS penalties while reinforcing active memory.

---

## 5. Architecture and Component Boundaries

```
VocabCraftApp
├── Features/
│   └── ReflexDrill/
│       ├── Views/
│       │   ├── ReflexBlitzView.swift                // Main Blitz Screen & Flow Container
│       │   ├── ReflexBlitzCardView.swift            // Cloze Challenge Card & Hint Scaffolding
│       │   ├── ReflexBlitzHeaderView.swift          // Combo streak, Timer & Progress bar
│       │   ├── ReflexBlitzSummaryView.swift         // Speed & Mastery Dashboard + Re-drill
│       │   └── ReflexCountdownOverlayView.swift     // 3-2-1 Start Pulse
│       ├── ViewModels/
│       │   └── ReflexBlitzViewModel.swift           // Session State Machine, Timer, Scoring
│       └── Services/
│           ├── ContinuousReflexSpeechService.swift  // Zero-latency audio stream coordinator
│           └── ReflexSessionStore.swift             // Session stats persistence
```

### Component Responsibilities:
1. **`ReflexBlitzView`**: Coordinates full-screen blitz experience, countdown presentation, card animations, and summary modal.
2. **`ReflexBlitzViewModel`**: `@MainActor @Observable` class managing session index, real-time stopwatch, progressive hint triggers, combo multiplier, evaluation against `TargetExpressionMatcher`, and dispatching SRS reviews.
3. **`ContinuousReflexSpeechService`**: Manages `AVAudioEngine` session lifecycle and coordinates with Apple `SFSpeechRecognizer` / `SpeechAssessmentProtocol`.

---

## 6. Data Models

```swift
public struct ReflexBlitzAttempt: Identifiable, Codable, Sendable {
    public let id: UUID
    public let wordId: Int
    public let lemma: String
    public let responseTimeMs: Int
    public let usedHint: Bool
    public let isCorrect: Bool
    public let timestamp: Date
}

public struct ReflexBlitzSessionSummary: Identifiable, Sendable {
    public let id: UUID
    public let totalWords: Int
    public let correctWords: Int
    public let averageResponseTimeMs: Int
    public let maxComboStreak: Int
    public let weakWordAttempts: [ReflexBlitzAttempt]
    public let speedRating: String
}
```

---

## 7. Testing & Verification Plan

### Unit Tests:
- `ReflexBlitzViewModelTests`: Test state transitions (countdown -> drill -> auto-advance -> summary), hint timing triggers at 3.5s, timeout trigger at 6.0s, and combo calculation.
- `SRSIntegrationTests`: Validate that `<2.5s` yields Mastery increment, while timeouts reset mastery.
- `ContinuousSpeechBufferTests`: Verify instant reset of target matching between consecutive words.

### UI & UX Verification:
- Dark/Light mode compliance with semantic palette (`Color.vocabCanvas`, `Color.vocabHeroAccent`, `Color.vocabPeach`, `Color.vocabMint`).
- VoiceOver accessibility labels for Cloze sentences and hint pills.
- 44pt touch targets for keyboard fallback and dismiss controls.
