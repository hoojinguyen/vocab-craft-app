# Learning Path Unified Lexical Ecosystem & Growth Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the VocabCraft Learning Path into a closed-loop lexical ecosystem by persisting all learned vocabulary into SwiftData/SRS, introducing spiral review and fast-track checkpoints, and proving vocabulary expansion via Milestone Delta reports and a CEFR Vocab Growth Dashboard.

**Architecture:** Clean Architecture with unidirectional data flow. Extends `CraftUIKit`'s `LessonNodeKind` with `.spiralReview`, upgrades `CompleteLessonUseCase` and `UserProgressModelActor` with single-transaction batch ingestion, introduces `FastTrackUnitUseCase` and `FetchVocabGrowthMetricsUseCase`, and embeds `MilestoneLexicalDeltaSheet` and `VocabGrowthDashboardSheet` into the Homepage.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, SQLite3, Observation, CraftUIKit tokens, XCTest / Swift Testing.

**Spec:** [`docs/superpowers/specs/2026-10-20-learning-path-unified-lexical-ecosystem-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-10-20-learning-path-unified-lexical-ecosystem-design.md)

## Global Constraints
- Target platforms: iOS 17.0+, macOS 14.0+.
- Zero hardcoded strings: Layer 1 `craft.*` in `CraftUIKit/Resources/Localizable.xcstrings`, Layer 2 `app.*` in `VocabCraftApp/Resources/Localizable.xcstrings`. 100% bilingual parity (EN & VI).
- Zero raw styling: strictly use `CraftUIKit` tokens (`CraftColor`, `CraftFont`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftShadowTokens`).
- Quality Gate: 0 warnings, 0 SwiftLint errors, 100% test pass rate.

---

### Task 1: Closed-Loop Lesson Vocabulary Persistence & Actor Batch Upsert

**Files:**
- Modify: `VocabCraftApp/Domain/Protocols/UserProgressRepositoryProtocol.swift`
- Modify: `VocabCraftApp/Data/Local/Actors/UserProgressModelActor+Mutations.swift`
- Modify: `VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift`
- Modify: `VocabCraftApp/Data/Repositories/MockUserProgressRepository.swift`
- Modify: `VocabCraftApp/Domain/UseCases/CompleteLessonUseCase.swift`
- Modify: `VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel+Completion.swift`
- Test: `VocabCraftAppTests/Domain/CompleteLessonUseCaseTests.swift`

**Interfaces:**
- Consumes: `TopicWordDTO`, `UserWordProgress`, `StageProgressRepositoryProtocol`.
- Produces: `recordBatchLessonResults(practicedWordIds:weakWordIds:stageId:deckId:)` on `UserProgressRepositoryProtocol`, updated `CompleteLessonUseCaseProtocol.execute(...)` with `practicedWordIds`.

- [ ] **Step 1: Write the failing test for CompleteLessonUseCase batch recording**

In `VocabCraftAppTests/Domain/CompleteLessonUseCaseTests.swift`:
```swift
@Test func testCompleteLessonPersistsBothCorrectAndWeakWords() async throws {
    let mockStageRepo = MockStageProgressRepository()
    let mockProgressRepo = MockUserProgressRepository()
    let useCase = CompleteLessonUseCase(stageRepo: mockStageRepo, progressRepo: mockProgressRepo)

    let practicedIds: [Int64] = [101, 102, 103]
    let weakIds: [Int64] = [102]

    let result = try await useCase.execute(
        stageId: "stage_test_1",
        deckId: "deck_test_1",
        stars: 2,
        practicedWordIds: practicedIds,
        weakWordIds: weakIds,
        progressFraction: 1.0
    )

    #expect(result.score == 2)
    #expect(mockProgressRepo.recordedBatchCalls.count == 1)
    let call = try #require(mockProgressRepo.recordedBatchCalls.first)
    #expect(call.practicedWordIds == practicedIds)
    #expect(call.weakWordIds == Set(weakIds))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CompleteLessonUseCaseTests`
Expected: Compile failure (missing `practicedWordIds` parameter).

- [ ] **Step 3: Update UserProgressRepositoryProtocol & CompleteLessonUseCase**

1. In `VocabCraftApp/Domain/Protocols/UserProgressRepositoryProtocol.swift`:
```swift
func recordBatchLessonResults(
    practicedWordIds: [Int64],
    weakWordIds: Set<Int64>,
    stageId: String?,
    deckId: String?
) async throws
```

2. In `VocabCraftApp/Data/Local/Actors/UserProgressModelActor+Mutations.swift`:
Implement `recordBatchLessonResults`:
- Fetch existing entities using `wordIds`.
- For correct words: increment `masteryLevel = min(5, masteryLevel + 1)`, reset `needsReview = false`, calculate interval days via SM-2.
- For weak words: set `needsReview = true`, increment `mistakeCount += 1`, set `consecutiveCorrectStreak = 0`, `intervalDays = 1`, `nextReviewDate = Date()`.
- Save `modelContext` once at the end.

3. Update `CompleteLessonUseCase.swift` and `MockUserProgressRepository.swift`.
4. Update `LessonLearningViewModel+Completion.swift` to pass `practicedWordIds: words.map(\.id)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CompleteLessonUseCaseTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Protocols/UserProgressRepositoryProtocol.swift \
        VocabCraftApp/Data/Local/Actors/UserProgressModelActor+Mutations.swift \
        VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift \
        VocabCraftApp/Data/Repositories/MockUserProgressRepository.swift \
        VocabCraftApp/Domain/UseCases/CompleteLessonUseCase.swift \
        VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel+Completion.swift \
        VocabCraftAppTests/Domain/CompleteLessonUseCaseTests.swift
git commit -m "feat: persist all practiced lesson words with single transaction batch upsert"
```

---

### Task 2: Dynamic Spiral Review Node & CraftUIKit Extension

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPathModels.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftPathNode.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`
- Test: `VocabCraftAppTests/Features/Homepage/LearningPathDataMapperTests.swift`

**Interfaces:**
- Consumes: `LessonNodeKind.spiralReview`, `UserStageProgressData`, `UserWordProgress`.
- Produces: `buildSpiralNode(deck:wordsNeedingReview:hasFoundActive:)` in `LearningPathDataMapper`.

- [ ] **Step 1: Write test for spiral review node injection in LearningPathDataMapper**

In `VocabCraftAppTests/Features/Homepage/LearningPathDataMapperTests.swift`:
```swift
@Test func testSpiralReviewNodeInjectedWhenWordsNeedReview() {
    let deck = TopicDeckDTO(id: "deck_1", titleEn: "Food", titleVi: "Ẩm thực", iconName: "fork.knife", themeKey: "green", cefrLevel: "A1", sortOrder: 0)
    let stage = SubTopicStageDTO(id: "stage_1", deckId: "deck_1", titleEn: "Fruits", titleVi: "Trái cây", iconName: "apple", sortOrder: 0)
    let words = [TopicWordDTO(id: 1, stageId: "stage_1", lemma: "Apple", phonetic: "/ˈæp.əl/", pos: "noun", cefrLevel: "A1", definitionVi: "Quả táo", definitionEn: "A fruit", exampleEn: "Eat apple", exampleVi: "Ăn táo")]
    let completedProgress = [UserStageProgressData(stageId: "stage_1", deckId: "deck_1", isCompleted: true, score: 3, progressFraction: 1.0, completedAt: Date())]
    let weakWordProgress = [UserWordProgressData(wordId: 1, masteryLevel: 1, needsReview: true)]

    let sections = LearningPathDataMapper.map(
        decks: [deck],
        stages: [stage],
        words: words,
        progressList: completedProgress,
        weakWords: weakWordProgress
    )

    let nodes = sections.first?.nodes ?? []
    #expect(nodes.contains(where: { $0.kind == .spiralReview }))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter LearningPathDataMapperTests`
Expected: Compile failure (`LessonNodeKind.spiralReview` does not exist).

- [ ] **Step 3: Implement spiralReview in CraftUIKit and LearningPathDataMapper**

1. In `CraftLearningPathModels.swift`:
```swift
public enum LessonNodeKind: String, Sendable, Equatable, Hashable, CaseIterable {
    case standard
    case spiralReview
    case checkpoint
    case treasureChest
}
```
2. In `CraftPathNode.swift`: handle visual shape, accent color, and symbol for `.spiralReview`.
3. In `LearningPathDataMapper.swift`:
Add parameter `weakWords: [UserWordProgressData] = []`.
If `weakWords.count >= 5`, insert a `spiralReview` node before `checkpointNode`.
4. Add localization keys in `CraftUIKit/Resources/Localizable.xcstrings` (`craft.node.spiral_review.*`) and `VocabCraftApp/Resources/Localizable.xcstrings` (`app.home.node.spiral_review_*`).

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests
swift test --filter LearningPathDataMapperTests
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/ \
        VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift \
        VocabCraftApp/Resources/Localizable.xcstrings \
        VocabCraftAppTests/Features/Homepage/LearningPathDataMapperTests.swift
git commit -m "feat: add spiral review node to CraftUIKit and LearningPathDataMapper"
```

---

### Task 3: Fast-Track Unit Checkpoint (Jump-Ahead)

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/FastTrackUnitUseCase.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: `VocabCraftAppTests/Domain/FastTrackUnitUseCaseTests.swift`

**Interfaces:**
- Consumes: `VocabularyDataSourceProtocol`, `StageProgressRepositoryProtocol`, `UserProgressRepositoryProtocol`.
- Produces: `FastTrackUnitUseCaseProtocol.execute(deckId:scorePercentage:) async throws -> FastTrackResult`.

- [ ] **Step 1: Write tests for FastTrackUnitUseCase**

In `VocabCraftAppTests/Domain/FastTrackUnitUseCaseTests.swift`:
```swift
@Test func testFastTrackSuccessMarksAllStagesAndIngestsWords() async throws {
    let mockDataSource = MockVocabularyDataSource()
    let mockStageRepo = MockStageProgressRepository()
    let mockProgressRepo = MockUserProgressRepository()
    let useCase = FastTrackUnitUseCase(
        dataSource: mockDataSource,
        stageRepo: mockStageRepo,
        progressRepo: mockProgressRepo
    )

    let result = try await useCase.execute(deckId: "deck_daily", scorePercentage: 0.90)

    #expect(result.isSuccess == true)
    #expect(mockStageRepo.savedStages.contains(where: { $0.stageId == "checkpoint_deck_daily" && $0.isCompleted }))
    #expect(mockProgressRepo.recordedBatchCalls.count >= 1)
}

@Test func testFastTrackFailureLeavesStagesUnchanged() async throws {
    let mockDataSource = MockVocabularyDataSource()
    let mockStageRepo = MockStageProgressRepository()
    let mockProgressRepo = MockUserProgressRepository()
    let useCase = FastTrackUnitUseCase(
        dataSource: mockDataSource,
        stageRepo: mockStageRepo,
        progressRepo: mockProgressRepo
    )

    let result = try await useCase.execute(deckId: "deck_daily", scorePercentage: 0.70)

    #expect(result.isSuccess == false)
    #expect(mockStageRepo.savedStages.isEmpty)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter FastTrackUnitUseCaseTests`
Expected: Compile failure (`FastTrackUnitUseCase` does not exist).

- [ ] **Step 3: Implement FastTrackUnitUseCase & wire into Homepage**

1. Create `VocabCraftApp/Domain/UseCases/FastTrackUnitUseCase.swift`:
- Check `scorePercentage >= 0.85`.
- If true: fetch all stages and words for `deckId`, save `isCompleted = true` for each, call `recordBatchLessonResults`, mark `checkpoint_\(deckId)` as completed with score 3.
2. Register in `AppContainer.swift`.
3. In `HomepageViewModel.swift`, add `fastTrackUnit(deckId:score:)`.
4. In `CraftLessonDetailSheet` callout, show "Thử Thách Vượt Cấp" CTA for locked/upcoming Checkpoints.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter FastTrackUnitUseCaseTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/FastTrackUnitUseCase.swift \
        VocabCraftApp/App/DI/AppContainer.swift \
        VocabCraftApp/Features/Homepage/ \
        VocabCraftApp/Resources/Localizable.xcstrings \
        VocabCraftAppTests/Domain/FastTrackUnitUseCaseTests.swift
git commit -m "feat: implement fast-track unit jump-ahead capability for checkpoints"
```

---

### Task 4: Vocab Growth Index (VGI) & Retention Analytics Engine

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/FetchVocabGrowthMetricsUseCase.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Test: `VocabCraftAppTests/Domain/FetchVocabGrowthMetricsUseCaseTests.swift`

**Interfaces:**
- Consumes: `UserProgressRepositoryProtocol`, `VocabularyDataSourceProtocol`.
- Produces: `FetchVocabGrowthMetricsUseCaseProtocol.execute() async throws -> VocabGrowthSnapshot`.

- [ ] **Step 1: Write unit tests for FetchVocabGrowthMetricsUseCase**

In `VocabCraftAppTests/Domain/FetchVocabGrowthMetricsUseCaseTests.swift`:
```swift
@Test func testCalculatesCEFRDistributionAndRetentionRate() async throws {
    let mockProgressRepo = MockUserProgressRepository()
    mockProgressRepo.stubbedProgress = [
        UserWordProgressData(wordId: 1, cefrLevel: "A1", masteryLevel: 4, intervalDays: 10, lastReviewDate: Date()),
        UserWordProgressData(wordId: 2, cefrLevel: "A1", masteryLevel: 1, intervalDays: 1, lastReviewDate: Date()),
        UserWordProgressData(wordId: 3, cefrLevel: "B1", masteryLevel: 2, intervalDays: 3, lastReviewDate: Date())
    ]
    let useCase = FetchVocabGrowthMetricsUseCase(progressRepo: mockProgressRepo)

    let snapshot = try await useCase.execute()

    #expect(snapshot.totalWordsAcquired == 3)
    #expect(snapshot.masteredWordsCount == 1)
    #expect(snapshot.consolidatingWordsCount == 1)
    #expect(snapshot.newWordsCount == 1)
    #expect(snapshot.estimatedRetentionRate >= 0.90)

    let a1Stat = snapshot.cefrDistribution.first(where: { $0.cefrLevel == "A1" })
    #expect(a1Stat?.acquiredCount == 2)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter FetchVocabGrowthMetricsUseCaseTests`
Expected: Compile failure (`FetchVocabGrowthMetricsUseCase` does not exist).

- [ ] **Step 3: Implement FetchVocabGrowthMetricsUseCase**

1. Create `VocabCraftApp/Domain/UseCases/FetchVocabGrowthMetricsUseCase.swift`:
- Query `progressRepo.fetchAllProgress()`.
- Group by CEFR level (`A1` to `C2`), map to `CEFRLevelStat`.
- Calculate retention rate using decay formula $R = \frac{1}{N} \sum e^{-\frac{t}{S}}$.
- Handle empty state safely ($R = 1.0$).
2. Register in `AppContainer.swift`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter FetchVocabGrowthMetricsUseCaseTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/FetchVocabGrowthMetricsUseCase.swift \
        VocabCraftApp/App/DI/AppContainer.swift \
        VocabCraftAppTests/Domain/FetchVocabGrowthMetricsUseCaseTests.swift
git commit -m "feat: implement vocab growth index and CEFR retention engine"
```

---

### Task 5: Milestone Lexical Delta Sheet

**Files:**
- Create: `VocabCraftApp/Features/Homepage/Views/MilestoneLexicalDeltaSheet.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: `VocabCraftAppTests/Features/Homepage/MilestoneLexicalDeltaSheetTests.swift`

**Interfaces:**
- Consumes: `MilestoneLexicalDelta`, `CraftUIKit` tokens (`CraftBadge`, `CraftButton`, `CraftProgressBar`).
- Produces: Interactive presentation on Checkpoint / Treasure completion.

- [ ] **Step 1: Write UI/ViewModel test for MilestoneLexicalDeltaSheet**

In `VocabCraftAppTests/Features/Homepage/MilestoneLexicalDeltaSheetTests.swift`:
```swift
@Test func testMilestoneDeltaSheetInitializesWithMetrics() {
    let delta = MilestoneLexicalDelta(
        unitId: "deck_daily",
        unitTitle: "Everyday Travel",
        cefrLevel: "A1",
        newWordsAdded: 15,
        wordsMastered: 8,
        avgResponseTimeMs: 1200,
        accuracyRate: 0.94
    )
    let view = MilestoneLexicalDeltaSheet(delta: delta, onContinue: {}, onOpenVault: {})
    #expect(view.delta.newWordsAdded == 15)
    #expect(view.delta.cefrLevel == "A1")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter MilestoneLexicalDeltaSheetTests`
Expected: Compile failure (`MilestoneLexicalDeltaSheet` does not exist).

- [ ] **Step 3: Implement MilestoneLexicalDeltaSheet & wire to Homepage**

1. Create `MilestoneLexicalDeltaSheet.swift` with:
- Top celebration icon + unit title + CEFR badge.
- Grid chip card of newly acquired words.
- Reflex telemetry: response time and retention health score.
- CEFR progress bar.
- Action buttons using `CraftButton`.
2. Update `HomepageViewModel`: trigger sheet on `handleLessonFinished` when `summary.isUnitCheckpoint == true` or `claimTreasure` succeeds.
3. Add localization keys in `VocabCraftApp/Resources/Localizable.xcstrings` (`app.milestone_report.*`).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter MilestoneLexicalDeltaSheetTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/MilestoneLexicalDeltaSheet.swift \
        VocabCraftApp/Features/Homepage/Views/HomepageView.swift \
        VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift \
        VocabCraftApp/Resources/Localizable.xcstrings \
        VocabCraftAppTests/Features/Homepage/MilestoneLexicalDeltaSheetTests.swift
git commit -m "feat: implement milestone lexical delta celebration sheet"
```

---

### Task 6: Vocab Growth Dashboard & Top Header Integration

**Files:**
- Create: `VocabCraftApp/Features/Homepage/Views/VocabGrowthDashboardSheet.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: `VocabCraftAppTests/Features/Homepage/VocabGrowthDashboardSheetTests.swift`
- Test: `VocabCraftAppTests/Features/Homepage/HomeTopHeaderViewTests.swift`

**Interfaces:**
- Consumes: `VocabGrowthSnapshot`, `CraftUIKit` tokens.
- Produces: Modal dashboard with CEFR ladder, 3-tier depth funnel, and pacing prediction.

- [ ] **Step 1: Write tests for Header Pill and VocabGrowthDashboardSheet**

In `VocabCraftAppTests/Features/Homepage/VocabGrowthDashboardSheetTests.swift`:
```swift
@Test func testVocabGrowthDashboardRendersCEFRDistribution() {
    let snapshot = VocabGrowthSnapshot(
        totalWordsAcquired: 450,
        masteredWordsCount: 200,
        consolidatingWordsCount: 150,
        newWordsCount: 100,
        estimatedRetentionRate: 0.95,
        cefrDistribution: [
            CEFRLevelStat(cefrLevel: "A1", acquiredCount: 300, targetStandardCount: 500),
            CEFRLevelStat(cefrLevel: "A2", acquiredCount: 150, targetStandardCount: 600)
        ]
    )
    let view = VocabGrowthDashboardSheet(snapshot: snapshot, onDismiss: {})
    #expect(view.snapshot.totalWordsAcquired == 450)
    #expect(view.snapshot.cefrDistribution.count == 2)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter VocabGrowthDashboardSheetTests`
Expected: Compile failure (`VocabGrowthDashboardSheet` does not exist).

- [ ] **Step 3: Implement VocabGrowthDashboardSheet & Header Pill**

1. Create `VocabGrowthDashboardSheet.swift`:
- Hero metrics: Total Words, Estimated CEFR Competence, Retention Health.
- CEFR Breakdown bars: A1 to C2 with acquired/standard ratio.
- 3-tier depth funnel: Encountered $\rightarrow$ Consolidating $\rightarrow$ Reflex Mastered.
- Pacing prediction block: estimated completion date for current CEFR tier.
2. In `HomeTopHeaderView.swift`: add clickable Lexical CEFR Pill (e.g. `450 từ • B1`).
3. In `HomepageView.swift`: attach `.sheet(isPresented: $isVocabGrowthDashboardPresented)`.
4. Add localization keys in `VocabCraftApp/Resources/Localizable.xcstrings` (`app.vocab_growth.*`).

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
swift test --filter VocabGrowthDashboardSheetTests
swift test --filter HomeTopHeaderViewTests
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/VocabGrowthDashboardSheet.swift \
        VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift \
        VocabCraftApp/Features/Homepage/Views/HomepageView.swift \
        VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift \
        VocabCraftApp/Resources/Localizable.xcstrings \
        VocabCraftAppTests/Features/Homepage/VocabGrowthDashboardSheetTests.swift \
        VocabCraftAppTests/Features/Homepage/HomeTopHeaderViewTests.swift
git commit -m "feat: implement vocab growth dashboard and lexical header pill"
```

---

### Task 7: Full Verification & Quality Gate Compliance

**Files:**
- Entire codebase

**Interfaces:**
- Full test pass, zero warnings, SwiftLint compliance.

- [ ] **Step 1: Run CraftUIKit localization test**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Expected: PASS with 100% bilingual parity.

- [ ] **Step 2: Run all unit and integration tests**

Run: `swift test`
Expected: 100% test pass rate across all suites.

- [ ] **Step 3: Run SwiftLint compliance check**

Run: `swiftlint`
Expected: 0 errors, 0 warnings.

- [ ] **Step 4: Final verification commit**

```bash
git status
git commit -m "chore: verify zero warnings and full test coverage for learning path ecosystem"
```
