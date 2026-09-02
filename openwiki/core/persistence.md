---
type: core
title: Persistence and State
description: SwiftData models, ModelActor, repositories, UserSettingsStore, and SharedAppGroupContainer for widget sync.
tags: ["persistence", "swiftdata", "modelactor", "settings"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-0db61ea7b3551c5ab3c560a0
    resource: repo://VocabCraftApp/Core/Database/SharedAppGroupContainer.swift
  - id: openwiki-source-c0b750b55f87a41517279d65
    resource: repo://VocabCraftApp/Core/Database/SwiftDataModels.swift
  - id: openwiki-source-4689ef33759ce866b13b26e9
    resource: repo://VocabCraftApp/Data/Local/Actors/UserProgressModelActor.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Durable storage for learning progress, stage progress, attempt logs, and widget state. Isolates concurrency via actor, exposes repository protocols to domain.

## Entrypoints

- **Models** (`Core/Database/SwiftDataModels.swift`): `UserWordProgress`, `UserStageProgress`, `ReflexSessionLog`, `QuickReflexAttemptRecord`, `WidgetCurrentState`.
- **Actor**: `Data/Local/Actors/UserProgressModelActor.swift` — `@ModelActor`.
- **Repositories**: `Data/Repositories/{SRSRepositoryImpl, VocabularyRepositoryImpl, QuickReflexAttemptRepositoryImpl, MockUserProgressRepository}` + `Core/Database/Repositories/StageProgressRepository`.
- **Settings**: `Core/Database/UserSettingsStore.swift` — `@Observable` + `@AppStorage` facade.
- **Container**: `Core/Database/SharedAppGroupContainer.swift` — creates `ModelContainer` with app-group store, handles migration (`SchemaV2`, `AppMigrationPlan`).

## Mechanisms

- **ModelActor concurrency**: `UserProgressModelActor` owns `ModelContext`; all writes go through `modelExecutor`, reads via `fetch` descriptors. Prevents data races from Views.
- **Repositories**: Each repo wraps a context/actor and implements protocol: `SRSRepositoryImpl.saveProgress(:)`, `VocabularyRepositoryImpl.fetchWord(:)` merges dataset + progress, `StageProgressRepositoryImpl` tracks `progressFraction`.
- **Settings**: `UserSettingsStore` persists theme preset, TTS preferences, streak, etc., via `UserDefaults` / SwiftData; observed by `CraftThemeManager` and Views.
- **Widget sync**: `SharedAppGroupContainer` configures `ModelConfiguration(url: appGroupURL)` so widget extension shares same store; `WidgetCurrentState` holds current word for widget timeline.
- **Schema**: `SwiftDataModels.swift` defines `#if canImport(SwiftDataMacros)` for SwiftData vs fallback sendable stubs for Swift Package tests.

## Relationships

- **Upstream**: `VocabCraftApp` creates `ModelContainer` → `AppContainer` creates actor → repos → use cases.
- **Downstream**: Widget extension reads `WidgetCurrentState` via same container; Views read via ViewModels that observe repos.

## State, Ordering, Lifecycle

- Container creation is first operation at boot; failure falls back to in-memory container.
- Writes are serialized by actor; reads may be concurrent via fetch descriptors with predicates/sorts.
- `UserWordProgress.mistakeCount`, `consecutiveCorrectStreak`, `masteryLevel`, `intervalDays`, `nextReviewDate` drive SRS scheduling.

## Invariants

- `wordId` unique; `stageId` unique; `QuickReflexAttemptRecord.id` unique UUID.
- `ModeSuccessStatsCodec` round-trips via `modeSuccessCountsRaw` string; malformed string decodes to empty.
- Actor methods are main-actor-isolated where UI-observed.

## Failure

- Missing store file creates fresh store; migration failures retry via `AppMigrationPlan`.
- Test mode always uses `inMemory: true` container to avoid filesystem side effects.

## Configuration

App-group identifier defined in entitlements; can toggle in-memory for tests/previews.

## Extension

Add model by adding `@Model` class + migration, register in `SchemaV2`, expose via new repository.

## Tests

- `SwiftDataModelsTests.swift`, `StageProgressRepositoryTests.swift`, `UserProgressModelActorConcurrencyTests.swift`, `UserSettingsStoreTests.swift`, `WidgetIntentsTests.swift`.
