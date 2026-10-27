---
type: feature
title: Homepage and Learning Path
description: The home tab's learning path (decks, stages, and lesson nodes rendered as a journey), lesson unlock progression, rewards and duration estimates, the streak header, and the sheets for treasure, path switching, and vocabulary growth.
tags: ["homepage", "learning-path", "journey", "unlock", "streak", "rewards"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-fb53ef21acc4356b7243b9a0
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift
  - id: openwiki-source-87dfef18f14020bf490508de
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftSnakePathGeometry.swift
  - id: openwiki-source-4e77e0bd1d48bdea03bd727b
    resource: repo://VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift
  - id: openwiki-source-94d1e6da629f2fdff7dd9660
    resource: repo://VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift
  - id: openwiki-source-9a6771e77e38fb6c48c4b0c7
    resource: repo://VocabCraftApp/Features/Homepage/ViewModels/LessonEconomyPolicy.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

The home tab is the landing screen. It shows the learner's current learning path as a journey of lesson nodes, the daily streak and progress header, and the actions that move the learner forward: starting a lesson, claiming a treasure chest, fast-tracking a unit, or switching paths.

## Entrypoints

- **Views**: `VocabCraftApp/Features/Homepage/Views`. `HomepageView` is the root. Supporting views are `HomeTopHeaderView`, `StreakWeekStripView`, `HomeSkeletonView`, `LearningPathSwitchSheet`, `TreasureClaimSheet`, `MilestoneLexicalDeltaSheet`, and `VocabGrowthDashboardSheet`.
- **ViewModel**: `HomepageViewModel` (`Features/Homepage/ViewModels/HomepageViewModel.swift`) is `@Observable` and `@MainActor`. It is created by `AppContainer.makeHomepageViewModel()`.
- **Mapper**: `LearningPathDataMapper` converts a `LearningPathCurriculum` into `LessonSection` and `LessonNodeModel` values for the journey view. It has overloads for standard, spiral-review, checkpoint, and treasure nodes.
- **Policy**: `LessonEconomyPolicy` (`Features/Homepage/ViewModels/LessonEconomyPolicy.swift`) defines XP rewards and duration estimates.
- **Domain**: `FetchLearningPathUseCase` (`VocabCraftApp/Domain/UseCases`) builds the curriculum. Its model is `LearningPathCurriculum` in `Domain/Models`.
- **Design system**: `CraftLearningPath` and `CraftFluidJourney` in CraftUIKit. See [Design System](../architecture/design-system.md).

## Mechanisms

1. **Load** — `loadLearningPath(forceRefresh:)` calls `FetchLearningPathUseCase.execute(pathId:forceRefresh:)` with the learner's selected path ID from `UserRoadmapSettingsProtocol`. The use case reads the bundled catalog through `VocabularyDataSourceProtocol` and per-stage progress through `StageProgressRepositoryProtocol`. It caches the static curriculum.
2. **Map** — `LearningPathDataMapper` turns decks and stages into sections of nodes. Each node gets its kind (`LessonNodeKind`: `standard`, `spiralReview`, `checkpoint`, or `treasureChest`), its progress, its lock state, and its estimated duration. The mapper promotes the node after the active one to `upcoming` so the learner can see what comes next.
3. **Unlock progression** — Completion logic lives in `HomepageViewModel`:
   - `handleStandardNodeCompletion` makes the next node `active`. It makes the node after that `upcoming` if it was `locked`.
   - `handleCheckpointCompletion` marks a following treasure chest as a bonus node with a "HOT" badge, then unlocks the next section.
   - `unlockNextSection` runs when a section's last node is completed.
4. **Rewards and durations** — `LessonEconomyPolicy` sets XP per node kind: standard 25, checkpoint 80, spiral review 40, and treasure 150. It estimates minutes as `max(1, ceil(words × 0.3))` for a standard lesson, `max(2, ceil(words × 0.25))` for a spiral review, and `max(3, ceil(deckWords × 0.2))` for a checkpoint.
5. **Actions** — `handleNodeTap` opens the lesson detail sheet. `claimTreasure(node:autoTriggerMilestone:)` and `fastTrackUnit(deckId:score:)` run their use cases. `handleLessonFinished` and `applyCompletedLesson(stageId:)` update local sections. Finishing a lesson also refreshes the vocabulary growth metrics.
6. **Path switching** — `switchLearningPath(to:)` saves the selected path through the user settings.
7. **Milestones** — `triggerMilestoneDelta` shows the milestone sheet when a unit is completed.
8. **Audio** — Header pronunciation uses `AppContainer.ttsService`. See [Audio and Speech](../core/audio-and-speech.md).

## Relationships

- **Upstream**: `AppContainer` supplies the use cases and the user settings. The catalog comes from [Dataset and Sync](../core/dataset-and-sync.md), and stage progress from [Persistence](../core/persistence.md).
- **Downstream**: Lesson and drill flows are described in [Reflex Drill System](reflex-drill-system.md). The home widget is covered in [Widgets and Intents](widgets-and-intents.md).
- **Review**: Vocabulary review scheduling is described in the [SRS Engine](../core/srs-engine.md).

## State and Lifecycle

- The ViewModel loads the path through `loadLearningPath(forceRefresh:)`. The view shows `HomeSkeletonView` while loading, and the ViewModel tracks the error and empty states.
- `refreshDailyProgress()` recalculates the daily numbers. Streak state comes from `UserSettingsStore` and the progress records.
- Sheets are driven by ViewModel state, such as the vocabulary growth dashboard and the milestone delta.

## Invariants

- Completing a node advances the next node, rather than unlocking the whole path at once.
- A treasure chest that follows a checkpoint becomes a bonus node unless it is already completed.
- Lock state is changed by the ViewModel's completion handlers, so the view does not compute it.

## Failure

- An empty dataset shows `CraftEmptyState`.
- Header speech failures fall back silently.

## Configuration

- Lessons and decks come from the bundled catalog.
- XP values and duration formulas are constants in `LessonEconomyPolicy`.
- The selected path is stored through the user settings.

## Extension

- Add a node type by adding a `LessonNodeKind` case, a builder in `LearningPathDataMapper`, a reward in `LessonEconomyPolicy.xpReward(for:)`, and a rendering variant in CraftUIKit.
- Add a header metric by extending the activity tracker card in CraftUIKit.

## Tests

- `VocabCraftAppTests/Domain/LearningPathUseCasesTests.swift` covers the curriculum use case.
- `VocabCraftAppTests/Domain/PracticeDrillPlanGeneratorTests.swift` covers drill plan generation.
- `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift` and `MetricsProgressionTests.swift` cover the journey and metrics components.
