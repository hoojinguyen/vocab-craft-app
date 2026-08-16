# Design Specification: Quick Reflex Collocation Ladder & Native Shadowing

Date: 2026-08-16  
Status: Approved for implementation planning

## 1. Purpose and Scope

Upgrade **“Luyện phản xạ từ này” (Quick Reflex)** from a 2-stage definition-translation drill into a voice-first, 3-tier productive reflex ladder grounded in Second Language Acquisition (SLA) principles:
1. **Stage 1 (Contextual Recall)**: Retrieve the target word in a cloze sentence context.
2. **Stage 2 (Collocation Chunking)**: Produce the natural word chunk / collocation associated with the target word.
3. **Stage 3 (Sentence Production & Native Shadowing)**: Produce a self-generated sentence, immediately followed by hearing an ideal native model sentence and optionally shadowing it with real-time pronunciation assessment.

The session runs inside a native SwiftUI bottom sheet (`QuickReflexDrillSheetView`), launched from `WordAccordionCard` in the personal vocabulary store, and completes in approximately 35–45 seconds.

---

## 2. Learner Experience and Step-by-Step Flow

```mermaid
graph TD
    A[Launch from Word Card] --> B[Stage 1: Contextual Recall (Word)]
    B -->|Match Lemma / Soft hints at 3s, 6s| C[Stage 2: Collocation Chunking]
    C -->|Match Collocation / Hint at 4s| D[Stage 3: Sentence Production]
    D -->|User Speaks Sentence| E[Instant Audio Mirror & Shadowing]
    E -->|Optional: Shadow model sentence with SpeechKit| F[Results & SRS Update]
```

### Step 1: Contextual Word Recall (~5–10s)
*   **Prompt**: A fill-in-the-blank English sentence (cloze) derived from `exampleSentenceEn` (e.g. `"Her fame proved to be [ ______ ]."`) paired with a concise Vietnamese definition subtitle. The target word itself is hidden.
*   **Input**: Speech first via `VocabMicControlHubView`, with instant fallback to typing.
*   **Progressive Hints**:
    *   3 seconds: Reveal part of speech (e.g. `adj.`).
    *   6 seconds: Reveal first letter (e.g. `e...`).
*   **Success Gate**: Exact match on normalized `lemma`. Transition automatically to Stage 2.

### Step 2: Collocation Chunking (~8–12s)
*   **Prompt**: Word badge is displayed (`Ephemeral` - `adj.`). Learner is challenged to speak the natural multi-word expression or collocation (e.g. `"ephemeral fame"` or `"achieve ephemeral success"`).
*   **Progressive Hints**:
    *   4 seconds: Reveal Vietnamese collocation meaning or partial phrase frame (e.g. `"... fame"`).
*   **Success Gate**: Normalized whole-phrase match against `collocationEn`. Transition to Stage 3.

### Step 3: Sentence Production & Native Shadowing (~15–20s)
*   **Phase 3a — Free Production**:
    *   Prompt presents a communicative cue (Vietnamese example translation).
    *   Learner produces any English sentence containing the target word/collocation.
    *   `TargetExpressionMatcher.contains` confirms usage.
*   **Phase 3b — Instant Audio Mirror & Native Shadowing**:
    *   Upon speech completion, the card springs open to reveal the **Ideal Native Model Sentence** (`exampleSentenceEn`).
    *   `ttsService.speak` immediately plays the native model audio.
    *   A prominent **"🎙️ Nhại lại (Shadow)"** button allows the learner to speak the sentence aloud.
    *   `SpeechAssessmentService` highlights words in real-time (Green: accurate, Yellow: acceptable, Red: needs practice) and gives an overall pronunciation score (0–100%).
    *   A **"Tiếp tục" (Continue)** button allows moving directly to results without shadowing if preferred.

### Step 4: Results & Confidence Check
*   **Performance Breakdown**:
    *   ⚡️ Recall time vs previous attempt ($\Delta t$ saved/slower).
    *   🔗 Collocation response time.
    *   🎙️ Shadowing pronunciation score (if attempted).
*   **Self-Report**: **"Đã quen"** (`.comfortable`) or **"Còn lúng túng"** (`.uncertain`).
*   **SRS Update**: Automatically evaluates and records SRS review for the word.

---

## 3. Data Model & Extraction Engine

### 1. `WordItem` Model Extension
Extend `WordItem` (and `WordRecord`) with optional collocation metadata while maintaining complete backward compatibility:
```swift
public struct WordItem: Identifiable, Equatable, Sendable {
    // Existing fields: id, lemma, phonetic, pos, definition, exampleSentenceEn, exampleSentenceVi, etc.
    public let collocationEn: String?
    public let collocationVi: String?
}
```

### 2. `CollocationExtractor` Service
A deterministic, pure domain service that resolves or extracts collocations:
1. **Pre-defined**: Returns `word.collocationEn` if present.
2. **Contextual Extraction (Fallback)**: Scans `word.exampleSentenceEn` for the `lemma` token and extracts the surrounding syntactic chunk (1 token before / after matching common verb-noun or adjective-noun boundaries).
3. **Grammatical Rule Fallback**:
   * Verb: `to [lemma] actively`
   * Noun: `great [lemma]` / `the [lemma] of`
   * Adjective: `[lemma] situation` / `very [lemma]`

---

## 4. Architecture & State Machine

```
[recallWord] ──(Match Lemma)──> [recallCollocation] ──(Match Chunk)──> [produceSentence]
                                                                               │
                                                                           (Spoke)
                                                                               ▼
[result] <───(Continue / Finish)─── [shadowModel] ◄───(Play TTS Audio)─────────┘
```

### `QuickReflexPhase` State Machine
*   `.recallWord`: Active STT listening for lemma. Timers schedule hints at 3s and 6s.
*   `.recallCollocation`: Active STT listening for collocation chunk. Timer schedules hint at 4s.
*   `.produceSentence`: Active STT listening for user sentence.
*   `.shadowModel`: TTS playback of native model + optional `SpeechAssessmentProtocol` pronunciation evaluation.
*   `.result`: Session summary card, confidence selector, and persistence dispatch.

### Component Responsibilities
*   `QuickReflexPromptFactory`: Generates a `QuickReflexPrompts` bundle containing all 3 stage prompts and the native model audio text.
*   `QuickReflexDrillViewModel`: `@MainActor @Observable` session coordinator managing phase transitions, timer handles, STT/TTS/SpeechAssessment lifecycle, and attempt persistence.
*   `QuickReflexDrillSheetView`: SwiftUI presentation layer with smooth spring animations, accessibility labels, and Dark/Light mode tokens (`Color.vocabCanvas`, `Color.vocabHeroAccent`, etc.).

---

## 5. Persistence, SRS & Scoring Rules

1. **SRS Review Trigger**:
   * SRS review (`evaluateSRSUseCase.recordReview`) is executed **only if Stage 1 (Word Recall) and Stage 2 (Collocation) succeed**.
   * Stage 3 (Sentence & Shadowing) is an expressive and pronunciation exercise; difficulties in Stage 3 do not penalize SRS mastery.
2. **Attempt Persistence (`QuickReflexAttemptRecord`)**:
   * Persists: `wordId`, `recallWordTimeMs`, `collocationTimeMs`, `produceSentenceTimeMs`, `shadowPronunciationScore`, `maxHintLevel`, `inputMode`, `retryCount`, `confidence`, `timestamp`.
   * Enables delta time comparison ($\Delta t$) with the previous successful attempt.
3. **Safety & Cancellation**:
   * Closing sheet or navigating away cleanly cancels audio sessions and background timers. No corrupt attempt or SRS record is written on mid-drill dismissal.

---

## 6. Verification and Acceptance Criteria

### Unit Tests
*   `CollocationExtractorTests`: Validates extraction from example sentences and grammatical fallback for nouns, verbs, adjectives.
*   `QuickReflexPromptFactoryTests`: Validates 3-stage prompt construction with cloze sentences and model text.
*   `QuickReflexDrillViewModelTests`: Validates full state machine transitions (`recallWord` $\rightarrow$ `recallCollocation` $\rightarrow$ `produceSentence` $\rightarrow$ `shadowModel` $\rightarrow$ `result`), hint timer triggers, speech error typing fallback, and SRS recording conditions.

### UI & Accessibility
*   VoiceOver announcements on stage progression and hint reveals.
*   Touch targets $\ge 44\text{pt}$ for all buttons and interactive controls.
*   Dynamic Type support and smooth layout adaptability.
