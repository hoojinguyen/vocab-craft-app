---
type: feature
title: Homepage and Learning Path
description: Homepage composition, FetchLearningPath, LessonEconomyPolicy, streak, and CraftLearningPath rendering.
tags: ["homepage", "learning-path", "streak", "feature"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
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
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Primary landing screen showing learning path snake, streak header, and lesson unlock status.

## Entrypoints

- **View**: `Features/Homepage/Views/HomepageView.swift` + `HomeTopHeaderView.swift`, `StreakWeekStripView.swift`, `HomeSkeletonView.swift`.
- **ViewModel**: `Features/Homepage/ViewModels/HomepageViewModel.swift` — `@Observable`.
- **Mapper**: `LearningPathDataMapper.swift` — maps domain path to `CraftLearningPathModels`.
- **Policy**: `LessonEconomyPolicy.swift` — unlock cost/requirements.
- **CraftUIKit**: `Containers/LearningPath/{CraftLearningPath, CraftLessonNode, CraftSnakePathGeometry, CraftPathUnlockSurge}.swift`.

## Mechanisms

1. **Fetch**: ViewModel calls `fetchLearningPathUseCase.execute()` (dataSource + stageRepo) → list of decks/stages/nodes.
2. **Mapping**: `LearningPathDataMapper` converts to `CraftJourneyModels` with progress fractions, lock states, theme overrides.
3. **Economy**: `LessonEconomyPolicy` checks prerequisites (previous stage completed, streak sufficient) and coin cost; exposes `canUnlock(node:)`.
4. **Rendering**: `CraftLearningPath` draws SVG-like snake via `CraftSnakePathGeometry`, places `CraftLessonNode` + `CraftNodeConnector`; completed nodes animate via `CraftLearningPathAnimations`. Header shows streak flame via `CraftStreakCard`.
5. **Navigation**: Tap node → `CraftLessonDetailSheet` → start lesson via `CompleteLessonUseCase` flow.
6. **TTS**: Header pronunciation via `AppContainer.ttsService`.

## Relationships

- **Upstream**: `DatasetEngine` + `StageProgressRepository` → use case → ViewModel.
- **Downstream**: Tapping lesson navigates to Reflex drills; completing lesson updates stage progress and triggers streak increment via `UserProgressModelActor`.

## State and Lifecycle

ViewModel loads on `.task`; handles loading/skeleton, success, empty. Streak state derived from `UserSettingsStore` + `UserProgressModelActor` daily rollover.

## Invariants

- Snake geometry deterministic for given node count; connector path recomputed on size change.
- Locked nodes are not tappable; policy is single source of truth.

## Failure

- Empty dataset shows `CraftEmptyState`.
- Fetch error surfaces as retry view; TTS failure degrades silently.

## Configuration

Lessons and decks defined in bundled dataset; economy thresholds in `LessonEconomyPolicy`.

## Extension

Add lesson type by adding node variant + mapper case; add header metric by extending `CraftActivityTrackerCard`.

## Tests

- `LearningPathUseCasesTests.swift`, `PracticeDrillPlanGeneratorTests.swift`, `CraftLearningPathTests.swift`, `MetricsProgressionTests.swift`.
