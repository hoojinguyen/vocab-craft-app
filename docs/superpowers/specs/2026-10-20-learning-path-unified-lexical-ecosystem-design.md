# Design Spec: Learning Path Unified Lexical Ecosystem & Growth Verification

- **Date**: 2026-10-20
- **Status**: Approved
- **Topic**: Learning Path Unified Lexical Ecosystem (SRS Spiral Review, Fast-Track Checkpoint, Vocab Growth Index & Proof of Progress)
- **Target Platforms**: iOS 17.0+, macOS 14.0+
- **Architecture**: Clean Architecture / SwiftData / CraftUIKit-first Design System

---

## 1. Executive Summary & Goals

### 1.1 Context & Problem Statement
Currently, VocabCraft provides a gamified learning journey (`CraftFluidJourney` / `CraftLearningPath`) powered by curated curricula across 4 learning paths. However, an architectural audit reveals critical bottlenecks:
1. **Broken Lexical Data Pipeline**: When completing a lesson, [`CompleteLessonUseCase`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/UseCases/CompleteLessonUseCase.swift) records *only weak/incorrect words* to SwiftData (`UserWordProgress`). Successfully practiced words are completely dropped, meaning they never enter the Personal Vault or the Spaced Repetition (SRS) queue.
2. **Lack of Proof of Vocabulary Growth**: Learners have no tangible, scientifically grounded proof of their vocabulary expansion. There is no CEFR-aligned tracking ($A1 \rightarrow C2$), no memory retention estimation, and no unit-level delta report.
3. **Rigid Linear Progression**: Learners with prior English proficiency are forced to plod through introductory units sequentially without the ability to test out of units they already know.
4. **Disconnection from Spaced Repetition (SRS)**: The learning path does not feature spiral review mechanisms; once a unit is completed, its vocabulary is not systematically interwoven into future path nodes to counter the Ebbinghaus forgetting curve.

### 1.2 Core Objectives
- **Closed-Loop Persistence**: Record 100% of practiced lesson vocabulary into SwiftData in a single atomic transaction, initiating SM-2 SRS schedules ($E\text{-Factor} = 2.5$, $Interval = 1\text{ day}$, $MasteryLevel = 1$).
- **Spiral Spaced Repetition on the Path**: Inject dynamic `.spiralReview` nodes into the journey before unit checkpoints when previous vocabulary is due for review, paired with a sticky HUD on the journey surface.
- **Fast-Track Checkpoints (Jump-Ahead)**: Allow learners to challenge unit checkpoints prematurely; achieving $\ge 85\%$ marks all intermediate stages complete, ingests the unit's vocabulary, and unlocks the next unit.
- **Quantifiable Proof of Progress**:
  - **Milestone Lexical Delta Sheet**: Triggered after every unit checkpoint/treasure claim, highlighting newly acquired words, response times, and CEFR ladder contribution.
  - **Vocab Growth Dashboard**: Accessible from the homepage top header, presenting overall vocabulary counts, CEFR distribution ($A1 \dots C2$), lexical depth funnels (Encountered $\rightarrow$ Consolidating $\rightarrow$ Mastered), and retention health.

---

## 2. Architecture & Subsystems

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION (SwiftUI)                          │
│                                                                        │
│  ┌───────────────────────┐  ┌──────────────────────────────────────┐   │
│  │   HomeTopHeaderView   │  │           CraftFluidJourney          │   │
│  │ (Lexical CEFR Pill)   │  │   (Standard, Spiral, Checkpoint)     │   │
│  └───────────┬───────────┘  └──────────────────┬───────────────────┘   │
│              │ (tap)                           │                       │
│              ▼                                 ▼                       │
│  ┌───────────────────────┐  ┌──────────────────────────────────────┐   │
│  │ VocabGrowthDashboard  │  │      MilestoneLexicalDeltaSheet      │   │
│  │  (CEFR & VGI Funnel)  │  │    (Unit Delta & Retention Proof)    │   │
│  └───────────────────────┘  └──────────────────────────────────────┘   │
└────────────────────────────────────▲───────────────────────────────────┘
                                     │
┌────────────────────────────────────┴───────────────────────────────────┐
│                           DOMAIN LAYER                                 │
│                                                                        │
│  ┌─────────────────────────────┐   ┌────────────────────────────────┐  │
│  │    CompleteLessonUseCase    │   │ FetchVocabGrowthMetricsUseCase │  │
│  │ (Batch Upsert All Words)    │   │    (VGI & CEFR Engine)         │  │
│  └──────────────┬──────────────┘   └───────────────┬────────────────┘  │
│                 │                                  │                   │
│                 ▼                                  ▼                   │
│  ┌─────────────────────────────┐   ┌────────────────────────────────┐  │
│  │     FastTrackUnitUseCase    │   │    FetchLearningPathUseCase    │  │
│  │   (Unit Skip & Unlock)      │   │ (Dynamic Spiral Node Mapping)  │  │
│  └─────────────────────────────┘   └────────────────────────────────┘  │
└────────────────────────────────────▲───────────────────────────────────┘
                                     │
┌────────────────────────────────────┴───────────────────────────────────┐
│                      DATA & PERSISTENCE LAYER                          │
│                                                                        │
│  ┌─────────────────────────────┐   ┌────────────────────────────────┐  │
│  │    UserProgressModelActor   │   │     SQLiteContentRepository    │  │
│  │ (SwiftData Batch Upsert)    │   │  (Decks, Lessons, Senses, CEFR)│  │
│  └─────────────────────────────┘   └────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Component & Domain Specifications

### 3.1 Closed-Loop Lesson Persistence
#### Interface Updates
In `CompleteLessonUseCaseProtocol`:
```swift
public protocol CompleteLessonUseCaseProtocol: Sendable {
    func execute(
        stageId: String,
        deckId: String,
        stars: Int,
        practicedWordIds: [Int64],
        weakWordIds: [Int64],
        progressFraction: Double
    ) async throws -> LessonCompletionResult
}
```

#### Actor Batch Ingestion
In `UserProgressModelActor`:
```swift
public func recordBatchLessonResults(
    practicedWordIds: [Int64],
    weakWordIds: Set<Int64>,
    stageId: String,
    deckId: String
) throws {
    let now = Date()
    let existingEntities = try fetchEntities(wordIds: Set(practicedWordIds))
    let existingMap = Dictionary(existingEntities.map { ($0.wordId, $0) }, uniquingKeysWith: { a, _ in a })

    for wordId in practicedWordIds {
        let isCorrect = !weakWordIds.contains(wordId)
        if let existing = existingMap[wordId] {
            if isCorrect {
                existing.masteryLevel = min(5, existing.masteryLevel + 1)
                existing.needsReview = false
                existing.consecutiveCorrectStreak += 1
                let nextDays = calculateNextInterval(mastery: existing.masteryLevel, easeFactor: existing.easeFactor)
                existing.intervalDays = nextDays
                existing.nextReviewDate = Calendar.current.date(byAdding: .day, value: nextDays, to: now) ?? now
            } else {
                existing.needsReview = true
                existing.mistakeCount += 1
                existing.consecutiveCorrectStreak = 0
                existing.intervalDays = 1
                existing.nextReviewDate = now
            }
            existing.totalReviews += 1
            existing.lastReviewDate = now
            existing.sourceNodeId = stageId
            existing.sourceDeckId = deckId
        } else {
            let nextDays = isCorrect ? 1 : 0
            let newProgress = UserWordProgress(
                wordId: wordId,
                cefrLevel: "A1",
                masteryLevel: isCorrect ? 1 : 0,
                isBookmarked: false,
                easeFactor: 2.5,
                intervalDays: max(1, nextDays),
                nextReviewDate: Calendar.current.date(byAdding: .day, value: nextDays, to: now) ?? now,
                lastReviewDate: now,
                totalReviews: 1,
                needsReview: !isCorrect,
                mistakeCount: isCorrect ? 0 : 1,
                sourceDeckId: deckId,
                sourceNodeId: stageId,
                consecutiveCorrectStreak: isCorrect ? 1 : 0
            )
            modelContext.insert(newProgress)
        }
    }
    try modelContext.save()
}
```

### 3.2 Dynamic Spiral Review Nodes on the Path
#### Model Extension (`CraftUIKit`)
In `LessonNodeKind`:
```swift
public enum LessonNodeKind: String, Sendable, Equatable, Hashable, CaseIterable {
    case standard
    case spiralReview   // Periodic spaced review node consolidating past units
    case checkpoint
    case treasureChest
}
```

#### Mapping Rules in `LearningPathDataMapper`
1. For each `TopicDeckDTO`, query user word progress records associated with preceding decks.
2. If `dueForReviewWords.count >= 5`:
   - Inject a `LessonNodeModel` with `kind: .spiralReview`, `iconName: "arrow.triangle.2.circlepath.circle.fill"`, titled `"app.home.node.spiral_review_title"`.
   - Placed immediately before the `checkpoint` node of the deck.
   - If user completes the spiral session, `stageId: "spiral_\(deck.id)"` is marked completed.
3. If `< 5` words require review:
   - Omit the node or render in a `.completed` state with bonus badge, keeping the journey uncluttered.

### 3.3 Fast-Track Unit Checkpoint (Jump-Ahead)
1. **Interactive Entry**: In `CraftLessonDetailSheet`, if the user selects a Checkpoint node whose prerequisite standard nodes are not yet completed:
   - Offer the **Fast-Track Challenge** action: `"app.home.checkpoint.fast_track_cta"`.
2. **Passing Gate ($\ge 85\%$)**:
   - Executes `FastTrackUnitUseCase`:
     - Queries all `SubTopicStageDTO` for the deck.
     - Marks all `stageId` as `isCompleted = true` in `StageProgressRepository`.
     - Ingests all `TopicWordDTO` for the deck into `UserWordProgress` with `masteryLevel = 1`.
     - Marks the `checkpoint_<deckId>` complete.
     - Unlocks the next unit and promotes the user to claim the `treasure_<deckId>`.
3. **Failing Gate ($< 85\%$)**:
   - Evaluates weak words and presents actionable guidance pointing to the specific stages needing attention, leaving streak unharmed.

### 3.4 Vocab Growth Index (VGI) & Analytics Engine
#### Domain Contract
```swift
public protocol FetchVocabGrowthMetricsUseCaseProtocol: Sendable {
    func execute() async throws -> VocabGrowthSnapshot
}

public struct VocabGrowthSnapshot: Sendable, Equatable {
    public let totalWordsAcquired: Int
    public let masteredWordsCount: Int        // Level >= 4
    public let consolidatingWordsCount: Int    // Level 2...3
    public let newWordsCount: Int              // Level 1
    public let estimatedRetentionRate: Double  // 0.0 ... 1.0 (e.g. 0.94)
    public let cefrDistribution: [CEFRLevelStat]
}

public struct CEFRLevelStat: Sendable, Equatable, Identifiable {
    public var id: String { cefrLevel }
    public let cefrLevel: String               // "A1", "A2", "B1", "B2", "C1", "C2"
    public let acquiredCount: Int
    public let targetStandardCount: Int        // A1: 500, A2: 600, B1: 800, B2: 1000, C1: 1200, C2: 1500
    public var masteryPercentage: Double {
        guard targetStandardCount > 0 else { return 0 }
        return min(1.0, Double(acquiredCount) / Double(targetStandardCount))
    }
}
```

#### Retention Decay Model
Memory retention $R$ is computed across active user words:
$$R = \frac{1}{N} \sum_{i=1}^{N} e^{-\frac{\max(0, t_i)}{S_i}}$$
- $t_i$: Days since `lastReviewDate`.
- $S_i$: Memory stability parameter derived from `intervalDays \times (easeFactor / 2.5)`.
- If reviews are conducted on time, $R$ remains in the $90\%-98\%$ bracket.

---

## 4. User Interface Specifications

### 4.1 Milestone Lexical Delta Sheet (`MilestoneLexicalDeltaSheet.swift`)
- **Presentation**: Modal bottom sheet presented upon completing any Checkpoint or opening a Treasure Chest.
- **Detents**: `[.fraction(0.65), .large]` with `.tactile3D` surface style.
- **Key Visual Elements**:
  - Celebration banner with unit title and CEFR badge (`CraftBadge(cefrLevel, tone: .primary)`).
  - Lexical delta card:
    - Large metric callout: `+18` words added to long-term memory.
    - Word chip grid displaying the acquired words with quick pronunciation buttons.
  - Performance telemetry:
    - Average reflex latency (e.g. `1.1s / word`).
    - Estimated retention health (`96%`).
  - CEFR progression bar (`CraftProgressBar`): e.g. `B1: 240/800 Words (30%)`.
  - Actions:
    - `CraftButton("Tiếp tục lộ trình", variant: .primary)` $\rightarrow$ Dismisses sheet and scrolls to the next active node.
    - `CraftButton("Xem trong Personal Vault", variant: .subtle)` $\rightarrow$ Routes to Vault with unit filter.

### 4.2 Vocab Growth Dashboard (`VocabGrowthDashboardSheet.swift`)
- **Presentation**: Modal presentation accessible via the Lexical Pill in `HomeTopHeaderView`.
- **Detents**: `[.large]`.
- **Key Visual Elements**:
  - Hero summary card displaying:
    - Total acquired vocabulary (`1,250 Words`).
    - Estimated CEFR competence label (`B1+ Threshold`).
    - Overall retention score (`94% Healthy`).
  - CEFR Mastery Ladder: Vertical list of 6 CEFR levels with segmented fill bars and acquired/target counts.
  - Lexical Depth Funnel:
    - 3-tier visualization showing progression: *Encountered (Level 1)* $\rightarrow$ *Consolidating (Level 2-3)* $\rightarrow$ *Reflex Mastered (Level 4-5)*.
  - Smart Pacing Predictor:
    - Projections based on 7-day average pace: *"At 10 words/day, you will complete B1 on Nov 15th."*

### 4.3 Design System & Localization Compliance
- Strict CraftUIKit token usage:
  - Colors: `theme.colors.brandPrimary`, `theme.colors.surfaceElevated`, `theme.colors.textPrimary`, `theme.colors.textSecondary`, `theme.colors.borderDefault`.
  - Spacing & Radius: `theme.spacing.*`, `theme.radius.*`.
  - Shadows & Depth: `theme.shadows.*`, `theme.depths.*`.
- Localization: All user-facing strings declared in `Localizable.xcstrings`:
  - `app.vocab_growth.*`
  - `app.milestone_report.*`
  - `app.home.checkpoint.*`
  - `craft.learning_path.*`
  - 100% parity between `en` and `vi`.

---

## 5. Error Handling, Edge Cases & Data Safety

| Scenario | Impact | Mitigation / Recovery |
| :--- | :--- | :--- |
| SwiftData context save fails during batch ingestion | Learner risks losing word acquisition record | Wrap in non-fatal error boundary; retry queue in memory; UI displays success for stage while retrying in background. |
| User jumps ahead on Checkpoint but loses network during test | Offline test session | All curriculum content is bundled offline in SQLite (`vocab_content.sqlite`); jump test executes completely offline without external network dependency. |
| Learner has 0 past words when calculating retention | Division by zero in retention model | Fallback gracefully: return $1.0$ ($100\%$) default retention. |
| User switches between curated learning paths | Inconsistent CEFR or stage progress | Learning paths share global `UserWordProgress` by `wordId`; progress on common vocabulary is preserved automatically across paths. |

---

## 6. Testing & Quality Strategy

1. **Domain Logic Tests**:
   - `CompleteLessonUseCaseTests`: Assert both correct words and weak words are upserted into `UserWordProgress` with correct initial mastery and interval values.
   - `FastTrackUnitUseCaseTests`: Assert $\ge 85\%$ marks all deck stages complete and upserts all deck words; assert $< 85\%$ leaves stages intact.
   - `FetchVocabGrowthMetricsUseCaseTests`: Verify CEFR distribution calculations, retention decay formula, and edge conditions ($0$ words, $100\%$ mastered).
2. **Mapper & Presentation Tests**:
   - `LearningPathDataMapperTests`: Assert `.spiralReview` node is added when previous units have words with `needsReview == true`, and omitted when clean.
   - `HomeTopHeaderViewTests`: Verify lexical pill displays formatted word count and CEFR level correctly.
3. **Quality Gates**:
   - `swift test`: 100% pass rate across all suites.
   - `swiftlint`: 0 warnings, 0 errors.
   - Xcode clean compile: 0 warnings, 0 concurrency diagnostic errors.
