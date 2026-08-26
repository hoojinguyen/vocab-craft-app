# Feature 1: Home — Learning Path Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the main Home tab of VocabCraft into a Duolingo-style linear learning journey using `CraftLearningPath` from `CraftUIKit`, with a sticky compact header, linear progression engine, star mastery system, and seamless transition to mixed reflex drills.

**Architecture:** Clean Architecture with a pure Swift `LearningPathDataMapper` transforming raw Deck & Stage DTOs and SwiftData `UserStageProgress` into `[LessonSection]` and `[LessonNodeModel]`. Domain UseCases (`FetchLearningPathUseCase`, `CompleteLessonUseCase`) decouple persistence from presentation. Presentation uses an `@Observable` `HomepageViewModel`, sticky `HeaderView`, and `CraftLearningPath` with auto-scroll and `CraftLessonDetailSheet`.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, CraftUIKit, XCTest / Swift Testing.

**Spec:** [`docs/superpowers/specs/2026-08-27-feature-1-home-learning-path-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-27-feature-1-home-learning-path-design.md)

## Global Constraints
- Zero hardcoded strings: All UI text must be defined in `VocabCraftApp/Resources/Localizable.xcstrings` under `app.home.*` with 100% EN and VI parity, `extractionState: "manual"`, and `state: "translated"`.
- Swift 6 & Concurrency: All ViewModels and UI entry points isolated to `@MainActor`; Repositories and UseCases `Sendable`.
- Zero compiler warnings / errors; all automated unit tests must pass.

---

## File Structure

| Layer | File Path | Responsibility |
| :--- | :--- | :--- |
| **Localization** | `VocabCraftApp/Resources/Localizable.xcstrings` | Key-value pairs for `app.home.*` in EN & VI |
| **Localization** | `VocabCraftApp/Core/Localization/AppStrings.swift` | `AppStrings.Home` strongly-typed SwiftUI helpers |
| **Data / Model** | `VocabCraftApp/Core/Database/SwiftDataModels.swift` | `UserStageProgress` schema with `progressFraction` & `score` |
| **Data / Repo** | `VocabCraftApp/Data/Repositories/StageProgressRepositoryImpl.swift` | SwiftData access for Stage Progress |
| **Domain / Repo** | `VocabCraftApp/Domain/Protocols/LearningPathRepositoryProtocol.swift` | Protocol for loading path data and completing lessons |
| **Data / Repo** | `VocabCraftApp/Data/Repositories/LearningPathRepositoryImpl.swift` | Repository implementation combining DataSource + SwiftData |
| **Domain / Mapper** | `VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift` | Pure Swift mapper from DTOs + Progress to `[LessonSection]` |
| **Domain / UseCase** | `VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift` | UseCase to load complete learning path |
| **Domain / UseCase** | `VocabCraftApp/Domain/UseCases/CompleteLessonUseCase.swift` | UseCase to record completion, stars, and weak words |
| **Presentation / VM** | `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift` | `@Observable` ViewModel for Home screen |
| **Presentation / View** | `VocabCraftApp/Features/Homepage/Views/HeaderView.swift` | Sticky Compact Header view |
| **Presentation / View** | `VocabCraftApp/Features/Homepage/Views/HomepageView.swift` | Home screen composing Sticky Header + `CraftLearningPath` |
| **Routing** | `VocabCraftApp/App/Navigation/AppRouter.swift` | Launch mixed reflex session with word payload |
| **DI** | `VocabCraftApp/App/DI/AppContainer.swift` | Wire new UseCases and ViewModels |
| **Tests** | `VocabCraftAppTests/LearningPathDataMapperTests.swift` | Unit tests for mapper & progression engine |
| **Tests** | `VocabCraftAppTests/FetchLearningPathUseCaseTests.swift` | Unit tests for fetch use case |
| **Tests** | `VocabCraftAppTests/CompleteLessonUseCaseTests.swift` | Unit tests for complete lesson use case |

---

### Task 1: Localization & AppStrings for Home Learning Path

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`

**Interfaces:**
- Consumes: None
- Produces: `AppStrings.Home` accessors for all `app.home.*` keys.

- [ ] **Step 1: Add `app.home.*` entries to `Localizable.xcstrings`**
Add the following keys to `VocabCraftApp/Resources/Localizable.xcstrings` with `extractionState: "manual"` and `state: "translated"` for both `en` and `vi`:
- `app.home.header.greeting_format` ("Hello, %@" / "Xin chào, %@")
- `app.home.header.daily_goal_format` ("Daily Goal: %lld%%" / "Mục tiêu: %lld%%")
- `app.home.header.streak_format` ("%lld days" / "%lld ngày")
- `app.home.section.unit_title_format` ("Unit %lld: %@" / "Unit %lld: %@")
- `app.home.section.checkpoint_title` ("Unit Review Exam" / "Ôn tập tổng hợp")
- `app.home.section.checkpoint_subtitle` ("Comprehensive exam covering all unit words" / "Bài kiểm tra tổng hợp toàn bộ từ vựng trong Unit")
- `app.home.node.words_duration_format` ("%lld words • %lld min" / "%lld từ • %lld phút")
- `app.home.node.objective_1_format` ("Master %lld core vocabulary words" / "Nắm vững %lld từ vựng trọng tâm")
- `app.home.node.objective_2` ("Practice 2-way Receptive & Productive recall" / "Luyện phản xạ Nhận diện & Sản xuất 2 chiều")
- `app.home.node.objective_3` ("Achieve ≥ 80%% accuracy to pass" / "Đạt độ chính xác ≥ 80%% để qua bài")
- `app.home.node.checkpoint_objective_1_format` ("Review all %lld words in this unit" / "Ôn tập toàn bộ %lld từ vựng trong Unit")
- `app.home.node.checkpoint_objective_2` ("Score ≥ 80%% accuracy to unlock the next Unit" / "Đạt độ chính xác ≥ 80%% để mở khóa Unit tiếp theo")
- `app.home.node.cta_start` ("Start Lesson" / "Bắt đầu bài học")
- `app.home.node.cta_continue_format` ("Continue (%lld%%)" / "Tiếp tục (%lld%%)")
- `app.home.node.cta_review_format` ("Review Lesson (+%lld XP)" / "Ôn lại bài học (+%lld XP)")
- `app.home.node.cta_checkpoint` ("Start Boss Exam" / "Bắt đầu thi vượt cấp")
- `app.home.node.locked_hint` ("Complete previous lessons to unlock" / "Hoàn thành các bài học trước để mở khóa")

- [ ] **Step 2: Add strongly-typed `AppStrings.Home` to `AppStrings.swift`**
Add enum `AppStrings.Home` exposing SwiftUI `LocalizedStringKey` and formatted string accessors.

- [ ] **Step 3: Verify build and test compilation**
Run: `swift test --filter LocalizationTests` (if available) or `swift build`.
Expected: Build passes with 0 errors.

- [ ] **Step 4: Commit**
```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift
git commit -m "feat(home): add bilingual localization keys for learning path"
```

---

### Task 2: SwiftData `UserStageProgress` Updates & Repository Layer

**Files:**
- Modify: `VocabCraftApp/Core/Database/SwiftDataModels.swift`
- Modify: `VocabCraftApp/Domain/Protocols/StageProgressRepositoryProtocol.swift` (or create if needed)
- Modify: `VocabCraftApp/Data/Repositories/StageProgressRepositoryImpl.swift`

**Interfaces:**
- Consumes: `UserStageProgress` model
- Produces: `StageProgressRepositoryProtocol.saveStageProgress(stageId:deckId:isCompleted:score:progressFraction:) async throws` and `fetchStageProgressMap(deckId:) async throws -> [String: UserStageProgress]`

- [ ] **Step 1: Ensure `UserStageProgress` supports `progressFraction`**
Update `UserStageProgress` in `SwiftDataModels.swift` to include `public var progressFraction: Double` with default `0.0`.

- [ ] **Step 2: Update `StageProgressRepositoryProtocol` and `StageProgressRepositoryImpl`**
Add methods:
```swift
func fetchAllStageProgress() async throws -> [UserStageProgress]
func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int, progressFraction: Double) async throws
```

- [ ] **Step 3: Update `MockStageProgressRepository`**
Implement the new methods in `MockStageProgressRepository` for reliable unit testing.

- [ ] **Step 4: Verify build**
Run: `swift build`.
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Core/Database/SwiftDataModels.swift VocabCraftApp/Data/Repositories/ VocabCraftApp/Domain/Protocols/
git commit -m "feat(progress): update UserStageProgress and StageProgressRepository with progressFraction"
```

---

### Task 3: Pure Swift `LearningPathDataMapper` with Unit Tests (TDD)

**Files:**
- Create: `VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift`
- Create: `VocabCraftAppTests/LearningPathDataMapperTests.swift`

**Interfaces:**
- Consumes: `[TopicDeckDTO]`, `[SubTopicStageDTO]`, `[TopicWordDTO]`, `[UserStageProgress]`
- Produces: `LearningPathDataMapper.map(decks:stages:words:progressList:) -> [LessonSection]`

- [ ] **Step 1: Write the failing unit tests in `LearningPathDataMapperTests.swift`**
Cover:
1. `test_new_user_first_node_active_rest_locked()`
2. `test_completed_first_node_unlocks_second_node_with_stars()`
3. `test_all_standard_nodes_completed_unlocks_checkpoint_node()`
4. `test_checkpoint_completed_unlocks_next_unit_first_node()`
5. `test_in_progress_node_preserves_progress_fraction()`

- [ ] **Step 2: Run test to verify it fails**
Run: `swift test --filter LearningPathDataMapperTests`.
Expected: FAIL (type not yet implemented).

- [ ] **Step 3: Implement `LearningPathDataMapper.swift`**
Write the transformation logic:
1. Sort decks by `sortOrder`.
2. For each deck, group stages sorted by `sortOrder`.
3. Map stages to `LessonNodeModel` (`.standard`).
4. Append 1 `.checkpoint` `LessonNodeModel` at the end of each deck.
5. Traverse all nodes globally across sections to resolve `.completed`, `.inProgress`, `.active`, `.locked`.
6. Return `[LessonSection]`.

- [ ] **Step 4: Run tests to verify they pass**
Run: `swift test --filter LearningPathDataMapperTests`.
Expected: PASS (All 5 tests pass).

- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift VocabCraftAppTests/LearningPathDataMapperTests.swift
git commit -m "feat(home): implement LearningPathDataMapper with linear progression logic and unit tests"
```

---

### Task 4: Domain Layer — `FetchLearningPathUseCase` & `CompleteLessonUseCase` (TDD)

**Files:**
- Create: `VocabCraftApp/Domain/Protocols/LearningPathRepositoryProtocol.swift`
- Create: `VocabCraftApp/Data/Repositories/LearningPathRepositoryImpl.swift`
- Create: `VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift`
- Create: `VocabCraftApp/Domain/UseCases/CompleteLessonUseCase.swift`
- Create: `VocabCraftAppTests/FetchLearningPathUseCaseTests.swift`
- Create: `VocabCraftAppTests/CompleteLessonUseCaseTests.swift`

**Interfaces:**
- Consumes: `VocabularyDataSourceProtocol`, `StageProgressRepositoryProtocol`, `UserProgressRepositoryProtocol`
- Produces:
  - `FetchLearningPathUseCaseProtocol.execute() async throws -> [LessonSection]`
  - `CompleteLessonUseCaseProtocol.execute(nodeId: String, deckId: String, accuracy: Double, weakWordIds: [Int64], xpEarned: Int) async throws -> Int` (returns stars 1-3)

- [ ] **Step 1: Write failing unit tests for `FetchLearningPathUseCaseTests` & `CompleteLessonUseCaseTests`**
Test fetching sections and completing a lesson with star calculation (95% -> 3 stars, 80% -> 2 stars, <80% -> 1 star) and weak words marking.

- [ ] **Step 2: Run tests to verify failure**
Run: `swift test --filter LearningPathUseCase`.
Expected: FAIL.

- [ ] **Step 3: Implement Repositories and UseCases**
Implement `LearningPathRepositoryImpl`, `FetchLearningPathUseCase`, and `CompleteLessonUseCase`.

- [ ] **Step 4: Run tests to verify they pass**
Run: `swift test --filter LearningPathUseCase`.
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Domain/ VocabCraftApp/Data/ Repositories/ VocabCraftAppTests/
git commit -m "feat(domain): implement FetchLearningPathUseCase and CompleteLessonUseCase with unit tests"
```

---

### Task 5: Presentation Layer — Sticky HeaderView & HomepageViewModel

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HeaderView.swift`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`

**Interfaces:**
- Consumes: `FetchLearningPathUseCaseProtocol`, `CompleteLessonUseCaseProtocol`
- Produces: `HomepageViewModel.sections`, `HomepageViewModel.loadLearningPath()`, `HomepageViewModel.handleStartLesson(node:)`

- [ ] **Step 1: Refactor `HeaderView.swift`**
Refactor `HeaderView` to be a sleek sticky header bar with avatar + radial goal ring, streak flame badge, greeting text, and notification icon.

- [ ] **Step 2: Refactor `HomepageViewModel.swift`**
Update `HomepageViewModel`:
- State holds `sections: [LessonSection]`, `selectedNodeForDetail: LessonNodeModel?`, `isLoading: Bool`, `streakDays: Int`, `dailyGoalProgress: Double`, `userName: String`.
- `loadLearningPath()` calls `FetchLearningPathUseCase`.
- `handleStartLesson(node:)` converts node words to `[ReflexBlitzWordItem]` and triggers session start via callback/router.

- [ ] **Step 3: Update `AppContainer.swift`**
Register `FetchLearningPathUseCase`, `CompleteLessonUseCase`, and update `makeHomepageViewModel()`.

- [ ] **Step 4: Verify build**
Run: `swift build`.
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Features/Homepage/ VocabCraftApp/App/DI/AppContainer.swift
git commit -m "feat(home): update HeaderView and HomepageViewModel for learning path orchestration"
```

---

### Task 6: Presentation Layer — HomepageView Integration with `CraftLearningPath`

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/App/Navigation/AppRouter.swift`

**Interfaces:**
- Consumes: `CraftLearningPath`, `CraftLessonDetailSheet`, `HomepageViewModel`
- Produces: Complete Home tab UI with sticky header and Duolingo-style path.

- [ ] **Step 1: Update `AppRouter.swift`**
Add support for `startMixedReflexSession(words: [ReflexBlitzWordItem], returnToHomeOnComplete: Bool)`.

- [ ] **Step 2: Refactor `HomepageView.swift`**
Replace the old Bento grid with:
```swift
VStack(spacing: 0) {
    HeaderView(...)
        .background(Color.vocabCanvas)
        .zIndex(1)
    
    CraftLearningPath(
        sections: viewModel.sections,
        winding: .standard,
        rowPattern: .standard,
        onNodeTap: { node in viewModel.handleNodeTap(node) },
        onStartLesson: { node in viewModel.startLesson(node) },
        showDetailModal: true,
        scrollToActive: true,
        showCelebration: false
    )
}
```

- [ ] **Step 3: Connect Session Completion Return Flow**
Ensure that when `ReflexBlitzSummaryView` completes, tapping "Tiếp tục" invokes `CompleteLessonUseCase`, returns to `.home` tab, and triggers `viewModel.loadLearningPath()`.

- [ ] **Step 4: Verify build and run all project tests**
Run: `swift test`.
Expected: PASS (0 errors, 0 test failures).

- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftApp/App/Navigation/AppRouter.swift
git commit -m "feat(home): integrate CraftLearningPath with sticky header and session transition"
```

---

### Task 7: Full Verification & QA Gate

**Files:**
- All touched files

- [ ] **Step 1: Run complete test suite**
Run: `swift test`
Expected: All tests pass.

- [ ] **Step 2: String & Localization check**
Verify zero raw English/Vietnamese string literals in views. Verify both `en` and `vi` translations exist for all `app.home.*` keys.

- [ ] **Step 3: Commit final polish**
```bash
git commit --allow-empty -m "chore(home): complete verification gate for Feature 1 Learning Path"
```
