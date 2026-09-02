---
type: architecture
title: Dependency Injection and Navigation
description: AppContainer composition root, EnvironmentKeys, AppRouter tab and deep-link routing, and view-model factories.
tags: ["architecture", "dependency-injection", "navigation", "swiftui"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-50708200bbae0e3f79368a9f
    resource: repo://VocabCraftApp/App/DI/AppContainer.swift
  - id: openwiki-source-0a6810aefce766d158565f58
    resource: repo://VocabCraftApp/App/DI/EnvironmentKeys.swift
  - id: openwiki-source-a2faa9b9fbea7c8bca2152b3
    resource: repo://VocabCraftApp/App/Navigation/AppRouter.swift
  - id: openwiki-source-71661d79da6d20d09e06bcfd
    resource: repo://VocabCraftApp/App/VocabCraftApp.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility and Ownership

`AppContainer` in `VocabCraftApp/App/DI/AppContainer.swift` is the centralized Composition Root. It owns creation of every data source, repository, service, and domain use case. `VocabCraftApp` struct bootstraps `AppContainer` after constructing `ModelContainer` and `DatasetEngine`, then injects it into the SwiftUI environment via `EnvironmentKeys`.

## Entrypoints

- **App entry**: `VocabCraftApp.init()` builds `SharedAppGroupContainer` / fallback `ModelContainer`, parses `ProcessInfo.arguments` for initial tab, creates `AppRouter`, and finally `AppContainer(datasetEngine:modelContainer:appRouter:)`.
- **Previews/tests**: `AppContainer.mock` (useMockData=true) and `.shared` provide deterministic alternatives; individual initializers accept explicit mocks for any dependency.

## Mechanisms and Control Flow

1. **Repository resolution** — `AppContainer.init` resolves `UserProgressModelActor` from `ModelContainer`, then picks concrete repos: `StageProgressRepositoryImpl` when SwiftData is available otherwise `MockStageProgressRepository`; `VocabularyRepositoryImpl` vs `MockVocabularyRepository` based on `datasetEngine`; always creates `SRSRepositoryImpl` + `QuickReflexAttemptRepositoryImpl`.
2. **DataSource switch** — `useSampleData` flag (currently both branches return `SampleVocabularyDataSource()`) isolates production data source seam for future dataset replacement.
3. **Use-case wiring** — Each use case is instantiated with resolved dependencies: `FetchLearningPathUseCase(dataSource:stageRepo)`, `CompleteLessonUseCase(stageRepo:progressRepo)`, vault/reflex use cases, etc.
4. **ViewModel factories** — `makePersonalVaultViewModel()`, `makeHomepageViewModel()`, `makeReflexBlitzViewModel(words:)`, `makeMixedReflexDrillViewModel(selectedWords:)`, `makeSettingsViewModel()` encapsulate ViewModel creation so Views stay stateless.

## Upstream / Downstream Relationships

- **Upstream**: `VocabCraftApp.swift` → `AppContainer`; `SharedAppGroupContainer` + `DatasetEngine` feed into it.
- **Downstream**: Features import only protocols (`FetchLearningPathUseCaseProtocol` etc.) and receive ViewModels from factories; SwiftUI Views read `@Environment(\.appContainer)` and `@Environment(\.appRouter)`.

## State, Persistence, Ordering

`AppContainer` is `@MainActor final class`, created once and held by `VocabCraftApp`. It holds `userSettingsStore` (Observable) and `appRouter` (`@Observable`). Ordering: AppRouter must be created before AppContainer so deep-link args parsed in `VocabCraftApp` are honored.

## Invariants and Failure Behavior

- Missing `ModelContainer` gracefully degrades to in-memory mocks instead of crashing.
- `useMockData ?? (datasetEngine == nil)` ensures previews never require real dataset.
- `VocabCraftApp` fatalErrors only when both primary and fallback `ModelContainer` creation fail in testing.
- Navigation failures (unknown URL scheme) fall back to `.home` without crashing.

## Configuration and Security

- `useSampleData` toggles dataset source; no secrets are stored in container.
- `UserProgressModelActor` isolates SwiftData writes to its actor.

## Extension Seams

Inject alternative implementations via initializer (e.g., `vocabularyDataSource:`, `ttsService:`, `appRouter:`). Add new use cases as stored properties + factory methods without changing Views.

## Representative Tests

- `VocabCraftAppTests/App/AppContainerVocabularyTests.swift` verifies container wiring with different data sources.
- `VocabCraftAppTests/AppRouterTests.swift` covers tab selection and deep-link parsing.
