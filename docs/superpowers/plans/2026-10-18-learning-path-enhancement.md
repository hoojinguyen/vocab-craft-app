# Learning Path Comprehensive Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Learning Path feature into a fully operational, bilingual, multi-path curriculum system by remediating milestone treasure claims, optimizing checkpoint quiz size to 10–12 words, computing real CEFR levels, seeding 4 specialized learning paths in SQLite, and providing a unified switcher across the Homepage, Drawer, Settings, and Onboarding.

**Architecture:** Clean Architecture with repository-backed offline SQLite relational storage, SwiftData-backed user stage progress, standalone domain use cases (`ClaimTreasureRewardUseCase`, `SmartCheckpointWordSampler`), and CraftUIKit-first presentation components (`TreasureClaimSheet`, `LearningPathSwitchSheet`).

**Tech Stack:** Swift 6 (Strict Concurrency), SwiftUI, SQLite3 C API, SwiftData, Swift Testing framework (`@Suite`, `@Test`, `#expect`), CraftUIKit design system.

**Spec:** [`docs/superpowers/specs/2026-10-18-learning-path-enhancement-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-10-18-learning-path-enhancement-design.md)

## Global Constraints

- 100% CraftUIKit-first: Zero raw colors, zero ad-hoc padding/radii, all styling via `CraftTheme` tokens.
- Zero hardcoded strings: All user-facing copy in `Localizable.xcstrings` with exact EN/VI format parity.
- Quality Gate: `swift test` 100% pass rate, `swiftlint` 0 errors/0 warnings, Xcode build 0 warnings.
- Data integrity: Stage and treasure claims persist in `StageProgressRepository` keyed by unique `stageId`.

---

### Task 1: DTO & SQLite Content Repository Enhancements

**Files:**
- Modify: `VocabCraftApp/Core/Database/DataSources/VocabularyDataSourceProtocol.swift:3-105`
- Modify: `VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift:133-197`
- Test: `VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift`

**Interfaces:**
- Consumes: `VocabularyDataSourceProtocol`, `SQLite3`
- Produces:
  - `TopicDeckDTO(id:titleEn:titleVi:descriptionEn:descriptionVi:iconName:themeKey:cefrLevel:sortOrder:stages:)`
  - `SubTopicStageDTO(id:deckId:titleEn:titleVi:iconName:sortOrder:words:)`
  - Computed mode CEFR level for decks instead of hardcoded `"A1"`

- [ ] **Step 1: Write unit test verifying bilingual titles and computed CEFR levels**

```swift
@Test func testFetchTopicDecksIncludesBilingualTitlesAndCEFR() async throws {
    guard let dbURL = Bundle.main.url(forResource: "vocab_content", withExtension: "sqlite", subdirectory: "Content")
            ?? Bundle(for: SQLiteContentRepositoryTests.self).url(forResource: "vocab_content", withExtension: "sqlite") else {
        return
    }
    let repo = try SQLiteContentRepository(url: dbURL)
    let decks = try await repo.fetchTopicDecks()
    #expect(!decks.isEmpty)
    let first = decks[0]
    #expect(!first.titleEn.isEmpty)
    #expect(!first.titleVi.isEmpty)
    #expect(first.cefrLevel != "")
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/SQLiteContentRepositoryTests`
Expected: Compile error (`titleEn` not found on `TopicDeckDTO`).

- [ ] **Step 3: Update `TopicDeckDTO` and `SubTopicStageDTO`**

In `VocabularyDataSourceProtocol.swift`, add `titleEn`, `titleVi`, `descriptionEn`, `descriptionVi` properties. Provide backward-compatible computed `title: String` that resolves based on `Locale.current`.

- [ ] **Step 4: Update SQL queries in `SQLiteContentRepository.swift`**

Update `fetchTopicDecks(for:)` to query `d.title_en, d.title_vi, d.description_en, d.description_vi`, and compute CEFR mode from `senses`. Update `fetchSubTopicStages` to query `title_en, title_vi`.

- [ ] **Step 5: Run tests and verify they pass**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/SQLiteContentRepositoryTests`
Expected: PASS.

- [ ] **Step 6: Commit changes**

```bash
git add VocabCraftApp/Core/Database/DataSources/ VocabCraftAppTests/Core/Database/
git commit -m "feat(database): add bilingual titles and computed CEFR levels to deck and stage DTOs"
```

---

### Task 2: Seed the 4 Curated Learning Paths in SQLite

**Files:**
- Modify: `VocabCraftApp/Resources/Content/vocab_content.sqlite`
- Modify: `VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift`
- Test: `VocabCraftAppTests/Core/Database/LearningPathDataSourceTests.swift`

**Interfaces:**
- Consumes: `learning_paths`, `path_decks`, `decks`
- Produces: 4 learning paths accessible via `repo.fetchLearningPaths()`:
  - `essential-english-mastery` (48 decks)
  - `daily-life-travel` (26 decks)
  - `business-career` (10 decks)
  - `academic-research` (16 decks)

- [ ] **Step 1: Write test for fetching all 4 paths and their deck counts**

```swift
@Test func testFetchAllFourLearningPaths() async throws {
    let repo = try SQLiteContentRepository(url: dbURL)
    let paths = try await repo.fetchLearningPaths()
    #expect(paths.count == 4)
    let pathCodes = Set(paths.map(\.code))
    #expect(pathCodes.contains("essential-english-mastery"))
    #expect(pathCodes.contains("daily-life-travel"))
    #expect(pathCodes.contains("business-career"))
    #expect(pathCodes.contains("academic-research"))

    let dailyDecks = try await repo.fetchTopicDecks(for: "c11e8a24-9b2f-4e67-881a-637dc44d3201")
    #expect(dailyDecks.count == 26)
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -only-testing:VocabCraftAppTests/LearningPathDataSourceTests`
Expected: FAIL (paths.count == 1 instead of 4).

- [ ] **Step 3: Execute SQLite script to insert 3 additional paths and mappings**

Insert the records for `daily-life-travel`, `business-career`, and `academic-research` into `learning_paths` and map the corresponding deck IDs into `path_decks`. Increment `content_version` in `dataset_metadata`.

- [ ] **Step 4: Run test to verify all 4 paths load properly**

Run: `xcodebuild test -scheme VocabCraftApp -only-testing:VocabCraftAppTests/LearningPathDataSourceTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Resources/Content/vocab_content.sqlite VocabCraftAppTests/Core/Database/LearningPathDataSourceTests.swift
git commit -m "feat(content): seed 4 curated learning paths and path-deck mappings into sqlite"
```

---

### Task 3: Domain Use Case: `ClaimTreasureRewardUseCase`

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/ClaimTreasureRewardUseCase.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Test: `VocabCraftAppTests/Domain/ClaimTreasureRewardUseCaseTests.swift`

**Interfaces:**
- Consumes: `StageProgressRepositoryProtocol`
- Produces: `ClaimTreasureRewardUseCaseProtocol`
  - `func execute(deckId: String) async throws -> TreasureRewardResult`

- [ ] **Step 1: Write unit tests for `ClaimTreasureRewardUseCase`**

```swift
@Suite struct ClaimTreasureRewardUseCaseTests {
    @Test func testClaimTreasureFailsIfCheckpointNotCompleted() async throws {
        let stageRepo = MockStageProgressRepository()
        let useCase = ClaimTreasureRewardUseCase(stageRepo: stageRepo)
        await #expect(throws: TreasureClaimError.checkpointIncomplete) {
            try await useCase.execute(deckId: "deck_test")
        }
    }

    @Test func testClaimTreasureSucceedsWhenCheckpointCompleted() async throws {
        let stageRepo = MockStageProgressRepository()
        try await stageRepo.saveStageProgress(stageId: "checkpoint_deck_test", deckId: "deck_test", isCompleted: true, score: 100, progressFraction: 1.0)
        let useCase = ClaimTreasureRewardUseCase(stageRepo: stageRepo)
        let result = try await useCase.execute(deckId: "deck_test")
        #expect(result.xpEarned == 150)
        #expect(!result.isAlreadyClaimed)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ClaimTreasureRewardUseCaseTests`
Expected: FAIL (types not defined).

- [ ] **Step 3: Implement `ClaimTreasureRewardUseCase`**

Implement `ClaimTreasureRewardUseCase` adhering to `ClaimTreasureRewardUseCaseProtocol`. Wire it into `AppContainer`.

- [ ] **Step 4: Run test to verify passing**

Run: `xcodebuild test -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ClaimTreasureRewardUseCaseTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Domain/UseCases/ClaimTreasureRewardUseCase.swift VocabCraftApp/App/DI/AppContainer.swift VocabCraftAppTests/Domain/ClaimTreasureRewardUseCaseTests.swift
git commit -m "feat(domain): implement ClaimTreasureRewardUseCase with milestone validation"
```

---

### Task 4: Intelligent Checkpoint Word Sampling (`SmartCheckpointWordSampler`)

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/SmartCheckpointWordSampler.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift:340-360`
- Test: `VocabCraftAppTests/Domain/SmartCheckpointWordSamplerTests.swift`

**Interfaces:**
- Consumes: `TopicWordDTO`, `SubTopicStageDTO`
- Produces: `SmartCheckpointWordSampler.sample(stages:wordsByStage:weakWordIds:targetCount:) -> [TopicWordDTO]`

- [ ] **Step 1: Write unit tests for `SmartCheckpointWordSampler`**

```swift
@Suite struct SmartCheckpointWordSamplerTests {
    @Test func testSamplerReturnsExactTargetCount() {
        let sampler = SmartCheckpointWordSampler()
        let result = sampler.sample(stages: mockStages, wordsByStage: mockWordsByStage, targetCount: 10)
        #expect(result.count == 10)
    }

    @Test func testSamplerPrioritizesWeakWords() {
        let sampler = SmartCheckpointWordSampler()
        let weakId: Int64 = 42
        let result = sampler.sample(stages: mockStages, wordsByStage: mockWordsByStage, weakWordIds: [weakId], targetCount: 10)
        #expect(result.contains(where: { $0.id == weakId }))
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -only-testing:VocabCraftAppTests/SmartCheckpointWordSamplerTests`
Expected: FAIL (`SmartCheckpointWordSampler` not defined).

- [ ] **Step 3: Implement `SmartCheckpointWordSampler`**

Build the sampling logic distributing across stages and prioritizing weak words up to target count (10–12).

- [ ] **Step 4: Run test to verify passing**

Run: `xcodebuild test -scheme VocabCraftApp -only-testing:VocabCraftAppTests/SmartCheckpointWordSamplerTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Domain/UseCases/SmartCheckpointWordSampler.swift VocabCraftAppTests/Domain/SmartCheckpointWordSamplerTests.swift
git commit -m "feat(domain): add SmartCheckpointWordSampler for micro-learning milestone drills"
```

---

### Task 5: Localization & AppStrings Updates

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Test: `VocabCraftAppTests/Localization/AppStringsParityTests.swift`

**Interfaces:**
- Keys added:
  - `app.treasure.congrats_title`
  - `app.treasure.congrats_subtitle`
  - `app.treasure.claim_button`
  - `app.treasure.already_claimed`
  - `app.learning_path.switcher_title`
  - `app.learning_path.switcher_subtitle`
  - `app.learning_path.active_badge`
  - `app.learning_path.progress_format`
  - `app.learning_path.switch_action`

- [ ] **Step 1: Add EN and VI keys to `Localizable.xcstrings`**

Ensure `extractionState: "manual"` and `state: "translated"` for both languages with exact formatting specifiers.

- [ ] **Step 2: Add typed static accessors to `AppStrings.swift`**

Add `AppStrings.Treasure` and `AppStrings.LearningPath` nested enums.

- [ ] **Step 3: Run localization tests**

Run: `swift test --filter LocalizationTests` (or app string tests).
Expected: PASS.

- [ ] **Step 4: Commit changes**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift
git commit -m "feat(localization): declare bilingual copy for treasure claims and learning path switcher"
```

---

### Task 6: Presentation: `TreasureClaimSheet` & Homepage Integration

**Files:**
- Create: `VocabCraftApp/Features/Homepage/Views/TreasureClaimSheet.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`

**Interfaces:**
- Consumes: `ClaimTreasureRewardUseCaseProtocol`, `CraftButton`, `CraftBadge`, `CraftHaptics`
- Produces: Instant interactive modal for claiming treasure chest with haptics and confetti.

- [ ] **Step 1: Create `TreasureClaimSheet` view**

Design using CraftUIKit tokens: 3D chest icon with `theme.gradients.accentShine`, `+150 XP` badge, celebratory copy, and primary action button.

- [ ] **Step 2: Update `HomepageView.swift` tap handling**

In `startLesson(for:)`, check if `node.kind == .treasureChest`. If so, do not launch `LessonLearningView`; instead present `TreasureClaimSheet`.

- [ ] **Step 3: Connect claim action in `HomepageViewModel`**

On claim tap, execute `ClaimTreasureRewardUseCase`, call `applyCompletedLesson(stageId: treasureNode.id)`, trigger confetti and toast.

- [ ] **Step 4: Manual/Automated verification with `-test-treasure-claim`**

Run build on simulator: verify tapping treasure node opens claim sheet and awards XP without errors.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Homepage/Views/TreasureClaimSheet.swift VocabCraftApp/Features/Homepage/
git commit -m "feat(ui): implement TreasureClaimSheet and integrate seamless milestone reward claim"
```

---

### Task 7: Presentation: `LearningPathSwitchSheet` & Triple Entry Points

**Files:**
- Create: `VocabCraftApp/Features/Homepage/Views/LearningPathSwitchSheet.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/Features/Settings/Views/SettingsView.swift`

**Interfaces:**
- Consumes: `VocabularyDataSourceProtocol.fetchLearningPaths`, `HomepageViewModel.switchLearningPath`
- Produces: Interactive sheet allowing switching between the 4 paths with progress visualizers.

- [ ] **Step 1: Create `LearningPathSwitchSheet.swift`**

Build modal listing the 4 learning paths using `CraftCard`, CEFR tags, completion progress bars, and active indicator.

- [ ] **Step 2: Wire Entry Point 1 (Homepage Header)**

In `HomeTopHeaderView.swift`, make `ActiveJourneyBadge` tappable, passing `onSelectPath: (() -> Void)?`.

- [ ] **Step 3: Wire Entry Point 2 (Curriculum Drawer)**

In `HomepageView.swift`, pass `onAdjustPlan: { isLearningPathSwitchPresented = true }` into `CraftFluidJourney`.

- [ ] **Step 4: Wire Entry Point 3 (Settings)**

In `SettingsView.swift`, add "Learning Path" navigation row opening the switcher sheet.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Homepage/Views/LearningPathSwitchSheet.swift VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftApp/Features/Settings/
git commit -m "feat(ui): add LearningPathSwitchSheet and wire triple entry points in Header, Drawer, and Settings"
```

---

### Task 8: Onboarding Synchronization with SQLite Paths

**Files:**
- Modify: `VocabCraftApp/Features/Onboarding/Views/OnboardingGoalStepView.swift`
- Modify: `VocabCraftApp/Features/Onboarding/ViewModels/OnboardingViewModel.swift`
- Modify: `VocabCraftApp/Domain/UseCases/InitializeUserRoadmapUseCase.swift`
- Test: `VocabCraftAppTests/Features/Onboarding/OnboardingRoadmapTests.swift`

**Interfaces:**
- Consumes: `VocabularyDataSourceProtocol.fetchLearningPaths`
- Produces: Dynamic goal step loading 4 real paths and initializing active path in `UserSettingsStore`.

- [ ] **Step 1: Write test for Onboarding path initialization with real SQLite path IDs**

```swift
@Test func testInitializeRoadmapWithRealLearningPathId() async throws {
    let useCase = InitializeUserRoadmapUseCase(dataSource: realDataSource, stageRepo: stageRepo, userSettings: userSettings)
    let result = try await useCase.execute(pathId: "daily-life-travel", cefrLevel: "A1", dailyGoalCount: 10, notificationTimeInterval: 72000)
    #expect(!result.startingStage.id.isEmpty)
    #expect(userSettings.selectedLearningPathId == "daily-life-travel")
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -only-testing:VocabCraftAppTests/OnboardingRoadmapTests`
Expected: FAIL (method signature mismatch).

- [ ] **Step 3: Update `InitializeUserRoadmapUseCase` & `OnboardingViewModel`**

Load real learning paths and persist selected path into `userSettings.saveLearningPathPreference(pathId:)`.

- [ ] **Step 4: Update `OnboardingGoalStepView.swift`**

Replace static mock IDs (`deck_daily`) with dynamic path items from repository.

- [ ] **Step 5: Run tests and verify they pass**

Run: `xcodebuild test -scheme VocabCraftApp -only-testing:VocabCraftAppTests/OnboardingRoadmapTests`
Expected: PASS.

- [ ] **Step 6: Commit changes**

```bash
git add VocabCraftApp/Features/Onboarding/ VocabCraftApp/Domain/UseCases/InitializeUserRoadmapUseCase.swift VocabCraftAppTests/Features/Onboarding/
git commit -m "feat(onboarding): synchronize onboarding goal step with real sqlite learning paths"
```

---

### Task 9: Full Verification Suite & Quality Gate

**Files:**
- Repository-wide verification

- [ ] **Step 1: Run full unit test suite**

Run: `xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro"`
Expected: 100% Tests Passed.

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint`
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Run Xcode clean build with zero warnings**

Run: `xcodebuild clean build -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro"`
Expected: Build Succeeded with 0 errors and 0 warnings.

- [ ] **Step 4: Git status clean check & Final Commit**

Verify `git status` has no untracked unexpected files.
