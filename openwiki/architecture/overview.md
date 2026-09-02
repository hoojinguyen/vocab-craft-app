---
type: architecture
title: Architecture Overview
description: High-level system map, SPM targets, layering, and data flow from UI through domain to persistence and speech.
tags: ["architecture", "overview", "spm", "swiftui"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-16a6a536c0a5303df5e05c6c
    resource: repo://Package.swift
  - id: openwiki-source-d85caf347254e99d90bcb93d
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift
  - id: openwiki-source-50708200bbae0e3f79368a9f
    resource: repo://VocabCraftApp/App/DI/AppContainer.swift
  - id: openwiki-source-71661d79da6d20d09e06bcfd
    resource: repo://VocabCraftApp/App/VocabCraftApp.swift
  - id: openwiki-source-fb58e0a18af45b08425b5baf
    resource: repo://VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

VocabCraft is a SwiftUI + SwiftData vocabulary learning app on iOS 17+. It orchestrates vocabulary browsing, spaced repetition, reflex drills (blitz/mixed), personal vault, and widget interactions under a Clean + MV architecture with `@Observable` ViewModels.

## Runtime and Build Entrypoints

- **App target**: `VocabCraftApp.xcodeproj` + `VocabCraft.xcworkspace`; entry `VocabCraftApp.swift` (`@main`). Generates workspace via `scripts/generate_workspace.py`.
- **SPM graph** (`Package.swift`): root library `VocabCraftApp` depends on local packages `CraftUIKit` and `SpeechKit`; exposes second library `VocabCraftWidgetExtension` for WidgetKit.
- **Platforms**: `iOS(.v17)`, `macOS(.v14)`; Swift 5.10 tools.
- **Tests**: `VocabCraftAppTests` + `CraftUIKitTests` + `SpeechKitTests`.

## Major Systems

| Layer | Location | Role |
|-------|----------|------|
| Design System | `Packages/CraftUIKit` | Tokens, themes, reusable UI components |
| Speech | `Packages/SpeechKit` + `Core/Audio` | STT/TTS, fuzzy matching, silence detection |
| Domain | `Domain/Entities|UseCases|Policies|Protocols` | Pure business rules, vocabulary and SRS logic |
| Data | `Data/Local/Actors|Repositories` + `Core/Database` | SwiftData models, actors, repositories, dataset engine |
| Features | `Features/{Homepage,Reflex,Vocabulary,Settings,AIAssistant}` | ViewModels + Views per feature |
| App | `App/DI|Navigation` | Composition root, routing |

## Control and Data Flow

1. **Boot**: `VocabCraftApp.init` → `SharedAppGroupContainer.createContainer()` → `DatasetEngine` → `AppContainer` → environment injection.
2. **Homepage**: `HomepageViewModel` calls `FetchLearningPathUseCase` (dataSource + stageRepo) → maps to `CraftLearningPath` nodes; `LessonEconomyPolicy` gates lesson unlocking; streak from `UserProgressModelActor`.
3. **Reflex**: `ReflexBlitzViewModel` / `MixedReflexDrillViewModel` generate drill queues via `GenerateMixedReflexQueueUseCase` + `PracticeDrillPlanGenerator`, drive mode handlers (Typing/Speaking/Listening/MultipleChoice), persist attempts via `RecordMixedDrillAttemptUseCase`, evaluate SRS via `EvaluateSRSUseCase`.
4. **Vault**: `PersonalVaultViewModel` via `FetchPersonalVaultUseCase` + `VocabularyFilterService`; bookmarks toggle via `ToggleWordBookmarkUseCase`; smart review via `SmartVaultWordSelector`.
5. **Persistence**: `UserWordProgress`, `UserStageProgress`, `QuickReflexAttemptRecord`, `WidgetCurrentState` stored in SwiftData; accessed through `UserProgressModelActor` for thread safety.

## Upstream / Downstream

- **CraftUIKit** is upstream of every feature; changes in tokens propagate globally.
- **SpeechKit** is upstream of Reflex speaking/listening modes.
- **SwiftData** is downstream of domain: domain entities map to/from `UserWordProgress`.

## State, Lifecycle, Ordering

- SwiftData schema versioned (`SchemaV2` + `AppMigrationPlan`).
- `UserProgressModelActor` serializes progress writes; `StageProgressRepository` wraps context per call.
- Navigation state centralized in `AppRouter` (selectedTab, NavigationPath, pendingReflexBlitzConfig).

## Invariants and Failure

- Production builds disable mocks unless explicitly injected.
- Test injection uses `AppContainer.mock` and in-memory ModelContainer.
- Unsupported URL schemes noop; missing ModelContainer falls back to mocks.

## Configuration and Operations

- Build via `xcodebuild` or Xcode; quality gate enforces `swiftlint` zero warnings, `swift test`, zero compiler warnings.
- Themes and localization are token/string-driven, not hardcoded.

## Extension Seams

Add feature by adding `Domain/UseCase` + `Features/<Feature>/ViewModel` + `Views`, register in `AppContainer` factories. Add token preset by conforming to `CraftTheme`.

## Tests

Over 50 test suites: domain use-case tests, SRS engine tests, vault/filter tests, reflex handler tests, widget intents tests, snapshot-like component tests.
