# Design Specification: Reflex Hint Masking & Session Pre-generation Engine

- **Author**: Antigravity & User
- **Date**: 2026-08-29
- **Status**: Approved / Ready for Implementation Planning
- **Module**: `VocabCraftApp / Features / Reflex`

---

## 1. Overview & Problem Statement

In the current Reflex Blitz and drill flows, several usability and architectural constraints were identified:
1. **Cloze Hint Visibility & Static Nature**: The cloze sentence placeholder `[...]` only changed color at certain thresholds rather than revealing progressive letters, and the initial letter hint in badges was repetitive (`c... • noun`).
2. **Deterministic Distractor Elimination**: When time thresholds were reached, the system always disabled the *first* distractor in the options list (`options.first(where: { !$0.isCorrect })`), making the elimination behavior predictable.
3. **Runtime Computation Overhead**: Options and distractors were generated at the exact moment a card transitioned, introducing potential frame drops and latency during time-sensitive blitz drills.
4. **Queue & Option Positioning**: The stimulus queue and options need rigorous randomization to ensure the correct answer is uniformly distributed across positions (A, B, C, D) and words are shuffled upfront.

### Solution
Build a **Pure Pre-generation Engine & Immutable Session Blueprint Architecture**:
- Generate 100% of the session's question blueprints (`ReflexDrillSessionPlan`) upfront when entering a mode.
- Introduce dynamic **Masked Hint Generation** with multiple progressive reveal strategies (Length Mask, Prefix, Suffix, Middle Salient Clusters, Consonant Scaffolding).
- Randomly pick a distractor for Stage 3 elimination with uniform probability.
- Provide zero-allocation, $O(1)$ state lookups for SwiftUI views during countdown drilling.

---

## 2. Architecture & Domain Models

```
┌─────────────────────────────────────────────────────────────┐
│                    Reflex Drill Initiation                  │
│       (Mode Selected / Start Blitz / Mixed Drill)           │
└──────────────────────────────┬──────────────────────────────┘
                               │ Input: [ReflexDrillable], Mode
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 ReflexDrillPlanGenerator                    │
│   - Shuffles word queue upfront                             │
│   - Generates 4 options with uniform correct position (0..3)│
│   - Uniformly picks random distractor to eliminate (Stage 3)│
│   - Pre-computes 3-stage ClozeSentenceParts via Hint Engine │
└──────────────────────────────┬──────────────────────────────┘
                               │ Produces: ReflexDrillSessionPlan
                               ▼
┌─────────────────────────────────────────────────────────────┐
│              ReflexDrillSessionPlan (Immutable)             │
│   - items: [ReflexDrillPlanItem] (Pre-computed Blueprints)  │
└──────────────────────────────┬──────────────────────────────┘
                               │ Consumed by ViewModels:
                               │ ReflexBlitzViewModel, MixedReflexDrillViewModel
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    SwiftUI View Rendering                   │
│   - Stage 0: initialParts        ("[ _________ ]")          │
│   - Stage 1: lengthMaskedParts   ("[ _ _ _ _ _ _ _ _ _ ]")  │
│   - Stage 2: patternRevealedParts("[ _ _ _ ll _ _ _ _ ]")   │
│   - Stage 3: eliminatedOptionId disabled in ChoiceCard      │
│   - Reviewed: Full lemma in target color                    │
└─────────────────────────────────────────────────────────────┘
```

### 2.1 Model Specifications

```swift
import Foundation

/// Strategy for revealing characters in the masked hint.
public enum ReflexHintMaskStrategy: Equatable, Sendable {
    case shortWordPrefix        // e.g. "f _ _ _"
    case shortWordSuffix        // e.g. "_ _ _ x"
    case prefix(count: Int)     // e.g. "c h _ _ _ _ _ _ _"
    case suffix(count: Int)     // e.g. "_ _ _ _ _ _ _ g e"
    case middleCluster(text: String, range: Range<Int>) // e.g. "_ _ _ l l _ _ _ _"
    case consonantScaffold      // e.g. "c h _ l l _ n g _"
}

/// Pre-segmented cloze parts for all progressive stages to allow O(1) text rendering.
public struct ReflexClozeStageSet: Equatable, Sendable {
    public let initialParts: ClozeSentenceParts          // Stage 0: Standard blank "[ _________ ]"
    public let lengthMaskedParts: ClozeSentenceParts      // Stage 1: Length underscore "[ _ _ _ _ _ _ _ _ _ ]"
    public let patternRevealedParts: ClozeSentenceParts    // Stage 2: Masked reveal "[ _ _ _ ll _ _ _ _ ]"
    public let maskedWordString: String                   // Raw revealed string "_ _ _ l l _ _ _ _"
    public let strategy: ReflexHintMaskStrategy
}

/// Complete immutable blueprint for a single drill item within a session.
public struct ReflexDrillPlanItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let word: any ReflexDrillable
    public let assignedMode: ReflexMode
    public let options: [ReflexBlitzOption]              // 4 shuffled choices
    public let correctOptionIndex: Int                   // Index of correct option (0...3)
    public let eliminatedOptionId: String?                // Pre-selected distractor ID for Stage 3
    public let clozeStages: ReflexClozeStageSet           // Pre-computed progressive cloze stages
    public let hintBadgeText: String                     // Badge label, e.g. "...ll... • verb"
}

/// Entire immutable session plan.
public struct ReflexDrillSessionPlan: Equatable, Sendable {
    public let id: UUID
    public let mode: ReflexMode
    public let items: [ReflexDrillPlanItem]

    public var count: Int { items.count }
    public var isEmpty: Bool { items.isEmpty }
}
```

---

## 3. Algorithmic Specifications

### 3.1 `ReflexHintMaskGenerator`
Pure utility struct responsible for creating `ReflexClozeStageSet` from a target lemma and example sentence.

#### Algorithm Steps:
1. **Length Classification**:
   - Clean lemma (trim whitespace, lowercased).
   - If length $\le 4$:
     - Short word rule: 50% chance `.shortWordPrefix` (e.g. `f _ _ _`), 50% chance `.shortWordSuffix` (e.g. `_ _ _ x`).
   - If length $\ge 5$:
     - **Step A - Salient Middle Cluster Search**:
       - Scan for double consonants (`ll`, `ss`, `tt`, `cc`, `nn`, `pp`, `rr`, `mm`, `ff`, `dd`, `bb`) or distinctive digraphs (`ck`, `ch`, `sh`, `th`, `ph`, `ng`, `qu`).
       - If a cluster exists strictly between the first and last character, select `.middleCluster` (e.g. `challenge` $\rightarrow$ `_ _ _ l l _ _ _ _`).
     - **Step B - Fallback Multi-Pattern Distribution**:
       - If no internal cluster exists, randomly pick with equal probability:
         - `.prefix(count: 2)`: e.g. `c h _ _ _ _ _ _ _`
         - `.suffix(count: 2)`: e.g. `_ _ _ _ _ _ _ g e`
         - `.consonantScaffold`: Keep all consonants, replace vowels (`a, e, i, o, u`) with underscores: `c h _ l l _ n g _`.
2. **Multi-Word / Phrasal Verb Support**:
   - If lemma contains spaces (e.g., `look up`), apply masking per sub-word and preserve space separators.
3. **Stage String Generation**:
   - `initial`: `"[ _________ ]"`
   - `lengthMasked`: Underscores separated by spaces, matching character length: `"[ _ _ _ _ _ _ _ _ _ ]"`
   - `patternRevealed`: The masked string enclosed in brackets: `"[ _ _ _ l l _ _ _ _ ]"`
4. **Cloze Segment Extraction**:
   - Using `ReflexClozeFormatter`, extract `ClozeSentenceParts(prefix, slot, suffix)` for each of the 3 stage strings.

### 3.2 `ReflexDrillPlanGenerator`
Domain service for generating a `ReflexDrillSessionPlan`.

#### Algorithm Steps:
1. **Word Queue Shuffling**:
   - `let shuffledWords = words.shuffled()`
2. **Per-Item Blueprint Synthesis**:
   - For each word in `shuffledWords`:
     - Generate 4 options using `ReflexDistractorGenerator.generateOptions` with pool shuffle.
     - Locate the correct option index ($0 \le \text{index} < 4$).
     - Filter incorrect options: `let incorrect = options.filter { !$0.isCorrect }`.
     - Select 1 random incorrect option ID: `let eliminatedId = incorrect.randomElement()?.id`.
     - Generate `clozeStages` via `ReflexHintMaskGenerator.generateStages(lemma: word.lemma, sentenceEn: word.exampleSentenceEn, pos: word.cleanPos)`.
     - Build `hintBadgeText`:
       - For middle cluster: `"...<cluster>... • <pos>"`
       - For prefix: `"<prefix>... • <pos>"`
       - For suffix: `"...<suffix> • <pos>"`
       - For consonant: `"<scaffold> • <pos>"`
3. **Package Session Plan**:
   - Assemble `ReflexDrillSessionPlan(id: UUID(), mode: mode, items: planItems)`.

---

## 4. ViewModel & UI Lifecycle Integration

### 4.1 `ReflexBlitzViewModel`
- Store `public var sessionPlan: ReflexDrillSessionPlan?`
- When `startCountdown()` or `startDrillSession(mode:words:)` is called:
  - `self.sessionPlan = ReflexDrillPlanGenerator.generatePlan(words: targetWords, mode: selectedMode)`
- In `loadWord(at index: Int)`:
  - Guard `let planItem = sessionPlan?.items[safe: index]`
  - `self.currentOptions = planItem.options`
  - `self.currentClozeStages = planItem.clozeStages`
  - `self.currentEliminatedOptionId = planItem.eliminatedOptionId`
  - `self.currentHintBadgeText = planItem.hintBadgeText`

### 4.2 Progressive Stage Timing & Triggering

| Stage | Trigger Timestamp | Cloze Slot UI | Badge UI | Multiple Choice / Listening State |
| :--- | :--- | :--- | :--- | :--- |
| **0** | $0.0\text{s} - 1.6\text{s}$ | `clozeStages.initialParts` (`[ _________ ]`) | Standard POS badge | 4 choices `.idle` |
| **1** | $1.6\text{s} - 2.5\text{s}$ | `clozeStages.lengthMaskedParts` (`[ _ _ _ _ _ _ _ _ _ ]`) | POS badge | 4 choices `.idle` |
| **2** | $2.5\text{s} - 3.4\text{s}$ | `clozeStages.patternRevealedParts` (`[ _ _ _ ll _ _ _ _ ]`) with `.statusWarning` | Hint Badge (`...ll... • noun`) | 4 choices `.idle` |
| **3** | $3.4\text{s} \rightarrow \text{Timeout}$ | `clozeStages.patternRevealedParts` | Hint Badge | `eliminatedOptionId` becomes `.disabled` |
| **Reviewed** | Answer submitted / Timeout | Full target lemma in `.statusSuccess` or `.statusDanger` | Review Feedback | Correct choice `.correct`, wrong choice `.wrong` |

### 4.3 View Layer (`ReflexMultipleChoiceModeView`, `ReflexTypingModeView`, `ReflexSpeakingModeView`)
- Update views to accept `clozeStages: ReflexClozeStageSet?` and `hintStage: Int`.
- In `sentenceView`:
  ```swift
  private var activeClozeParts: ClozeSentenceParts? {
      guard let stages = clozeStages else { return clozeParts }
      switch hintStage {
      case 0: return stages.initialParts
      case 1: return stages.lengthMaskedParts
      default: return stages.patternRevealedParts
      }
  }
  ```
- Smooth spring animations when slot text changes.

---

## 5. Verification & Test Plan

### 5.1 Unit Tests (`VocabCraftAppTests`)
1. **`ReflexHintMaskGeneratorTests`**:
   - Short words ($\le 4$ chars): Verify prefix/suffix patterns and length matches lemma length.
   - Long words with double consonants (`challenge`, `connect`, `success`): Verify middle cluster extraction (`_ _ _ l l _ _ _ _`).
   - Long words without double consonants (`protect`, `energy`, `simple`): Verify valid prefix, suffix, or consonant scaffold generation.
   - Phrasal verbs / multi-words (`give up`, `take off`): Verify space preservation.
2. **`ReflexDrillPlanGeneratorTests`**:
   - Uniform distribution test: Run generator across 100 iterations, verify correct option appears at indices 0, 1, 2, 3 with balanced statistical distribution.
   - Elimination test: Verify `eliminatedOptionId` belongs to one of the 3 incorrect options, never the correct one.
   - Queue shuffling test: Verify output order is randomized compared to input list.
3. **`ReflexBlitzViewModelTests`**:
   - Verify `sessionPlan` generation and correct binding when `loadWord(at:)` executes.
   - Verify progressive hint stages (0 $\rightarrow$ 1 $\rightarrow$ 2 $\rightarrow$ 3) trigger expected UI states and option elimination.
4. **SwiftLint & Xcode Compilation**:
   - 0 errors, 0 warnings, 100% test pass rate.
