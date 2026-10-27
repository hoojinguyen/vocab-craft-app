---
type: architecture
title: Dependency Injection and Navigation
description: AppContainer composition root, AppBootstrapper startup, EnvironmentKeys, AppRouter tab and deep-link routing, and view-model factories.
tags: ["architecture", "dependency-injection", "navigation", "swiftui"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-5d81637882ca78de29b1c749
    resource: repo://VocabCraftApp/App/Bootstrap/AppBootstrapper.swift
  - id: openwiki-source-50708200bbae0e3f79368a9f
    resource: repo://VocabCraftApp/App/DI/AppContainer.swift
  - id: openwiki-source-0a6810aefce766d158565f58
    resource: repo://VocabCraftApp/App/DI/EnvironmentKeys.swift
  - id: openwiki-source-a2faa9b9fbea7c8bca2152b3
    resource: repo://VocabCraftApp/App/Navigation/AppRouter.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility and Ownership

`AppContainer` in `VocabCraftApp/App/DI/AppContainer.swift` is the centralized Composition Root. It owns creation of every data source, repository, service, stored settings object, and domain use case, and it exposes view-model factories (`make...ViewModel`) so Views never construct dependencies themselves. `AppBootstrapper` in `VocabCraftApp/App/Bootstrap/AppBootstrapper.swift` performs the startup sequence that produces the container, and `VocabCraftApp` (`VocabCraftApp/App/VocabCraftApp.swift`) renders against the bootstrapper's state and injects the container and router into the SwiftUI environment.

## Entrypoints

- **App entry**: `VocabCraftApp` holds an `AppBootstrapper` as `@State`. Its `body` switches on `bootstrapper.state`: `.loading` runs `bootstrap()`, `.error` shows `DatabaseRecoveryView` (retry or confirm reset), and `.ready` renders the content for `bootstrapper.appContainer`.
- **Launch-argument screens**: `contentView(for:)` checks `ProcessInfo` arguments such as `-show-roleplay-room`, `-show-voice-call`, `-show-roleplay-summary`, and `-show-ai-config` to render debug screens directly, each with the container, router, and TTS service injected.
- **Previews/tests**: `AppContainer.mock` (`useMockData: true`, `useSampleData: true`, no-op widget refresh, isolated `UserDefaults` suite) and `AppContainer.shared` (`useMockData: false`, `useSampleData: false`) provide alternatives. Every dependency has an optional initializer parameter for explicit injection.

## Mechanisms and Control Flow

1. **Bootstrap** — `AppBootstrapper.bootstrap()` creates the `ModelContainer` through `SharedAppGroupContainer.createContainer(inMemory:)` (or an injected provider). It deletes progress tables when `-reset-progress` is passed, resolves the vocabulary data source through `AppContainer.getProductionDataSource()`, validates `BundledVocabularyDataSource` catalogs, creates the router with `createAppRouter(from:)`, and only then constructs `AppContainer(modelContainer:vocabularyDataSource:appRouter:)`. Any thrown error moves the state to `.error`; a `confirmReset()` path rebuilds the store through `SharedAppGroupContainer.resetStoreWithQuarantine()`.
2. **Repository resolution** — `AppContainer.init` builds `UserProgressModelActor` from the `ModelContainer` when one exists, falling back to `MockUserProgressRepository`. Stage progress uses `StageProgressRepositoryImpl` on the main context or `MockStageProgressRepository`. `VocabularyRepositoryImpl` is used unless `useMockData` is set, in which case `MockVocabularyRepository` is used. `SRSRepositoryImpl`, `QuickReflexAttemptRepositoryImpl`, and `ShadowingProgressRepositoryImpl` are always created.
3. **Practice wiring** — `practiceRepository` is a `PracticeModelActor` over the same `ModelContainer`, and it is passed into `SRSRepositoryImpl` so SRS writes can reach the practice store. `makePracticeHubViewModel()` and `makePracticeSessionCoordinator(...)` build the Guided Practice flow on top of it.
4. **Data source selection** — `AppContainer.getProductionDataSource()` copies the bundled `vocab_content.sqlite` into Application Support (`VocabCraft/Content/vocab_content.sqlite`) when the file is missing, the bundle version is newer, or fewer than four learning paths exist, then opens it with `SQLiteContentRepository`. On failure it returns `BundledVocabularyDataSource` as a safe fallback.
5. **Use-case wiring** — Each use case is built from resolved dependencies, for example `FetchLearningPathUseCase(dataSource:stageRepo)`, `CompleteLessonUseCase(stageRepo:progressRepo)`, and the vault, reflex, and mixed-drill use cases, and is exposed as a stored property.
6. **ViewModel factories** — `makeHomepageViewModel()`, `makePersonalVaultViewModel()`, `makeReflexBlitzViewModel(words:)`, `makeMixedReflexDrillViewModel(...)`, `makeLessonLearningViewModel(...)`, `makeSettingsViewModel()`, `makeAIAssistantHubViewModel()`, `makeRoleplayRoomViewModel(for:)`, `makeRoleplayVoiceCallViewModel(for:)`, `makeShadowingHubViewModel(...)`, `makeShadowingPracticeViewModel(for:)`, and `makeShadowingStudioViewModel(for:)` keep Views stateless.

## Environment Injection

`VocabCraftApp/App/DI/EnvironmentKeys.swift` defines three SwiftUI keys:

- `appContainer` falls back to `AppContainer.mock` when no container is injected.
- `appRouter` falls back to `appContainer.appRouter`.
- `ttsService` is optional and defaults to `nil`, so Views can receive an injected speech service.

## Upstream / Downstream Relationships

- **Upstream**: `AppBootstrapper` builds the `ModelContainer`, data source, and `AppRouter`, then creates `AppContainer`. `VocabCraftApp` forwards `onOpenURL` and background `scenePhase` events to the bootstrapper and container.
- **Downstream**: Features depend on protocols such as `FetchLearningPathUseCaseProtocol` and receive ViewModels from factories. SwiftUI Views read `@Environment(\.appContainer)` and `@Environment(\.appRouter)`.

## State, Persistence, Ordering

`AppContainer` is a `@MainActor final class`. `AppBootstrapper` is `@Observable` and `@MainActor`, and it keeps the `container`, `appContainer`, and `state` properties, plus a single `pendingDeepLink`. A deep link that arrives before the container exists (a cold launch) is stored and replayed after bootstrap succeeds. `AppRouter` is created before `AppContainer` in the bootstrap path so launch-argument tab selection and deep-link handling apply to the container's router. `UserProgressModelActor` and `PracticeModelActor` isolate SwiftData writes to actors.

## Invariants and Failure Behavior

- A missing `ModelContainer` in `AppContainer.init` degrades to in-memory mock repositories instead of crashing.
- `useMockData ?? false` selects the real repositories by default, and `useSampleData` defaults to `true`.
- `AppBootstrapper` reports store failures through `DatabaseStoreError` and the `.error` state. It does not terminate the process, and the user can retry or confirm a reset.
- `AppRouter.handleDeepLink(url:)` ignores URLs whose scheme is not `vocabcraft`. Unknown hosts select `.home`.

## Navigation and Deep Links

`AppRouter` (`VocabCraftApp/App/Navigation/AppRouter.swift`) is an `@Observable` `@MainActor` class. It owns `selectedTab`, a `NavigationPath`, and several pending handoff values: `pendingReflexBlitzConfig`, `pendingShadowingVideoId`, and `pendingSmartReview`.

- **Launch arguments**: `init(initialTab:)` selects `.aiAssistant` when any AI or shadowing test flag is present (`-tab-ai`, `-test-ai-config`, `-test-ai-room`, `-test-ai-voice`, `-test-ai-summary`, `-test-shadowing`, `-test-shadowing-hub`). It selects `.settings` for `-tab-settings`. Otherwise it uses `initialTab`.
- **Deep-link hosts** (`vocabcraft://`):
  - `reflex` (or any URL containing "reflex") parses `mode`, `phase`, `state`, `hint`, and `combo` into `pendingReflexBlitzConfig` and selects `.reflex`.
  - `shadowing` stores the `videoId` query value in `pendingShadowingVideoId`. It does not change tabs in this branch.
  - `vocabulary` selects `.vocabulary`.
  - `review` sets `pendingSmartReview` and selects `.vocabulary`.
  - `settings` selects `.settings`.
  - `ai` or `aiAssistant` selects `.aiAssistant`.
  - Any other host selects `.home`.

## Configuration and Security

- `useSampleData` controls the sample dataset seam. No secrets are stored in the container.
- Launch-argument switches (`-reset-progress`, `-tab-*`, `-show-*`, `-test-*`) are development and test hooks. They are read from `ProcessInfo` at startup.

## Extension Seams

Inject alternative implementations through initializer parameters, such as `vocabularyDataSource:`, `ttsService:`, `shadowingProgressRepository:`, `practiceRepository:`, and `appRouter:`. Add a new use case as a stored property plus a factory method, and keep Views dependent only on the factory's return type.

## Representative Tests

- `VocabCraftAppTests/App/AppContainerTests.swift`, `AppContainerVocabularyTests.swift`, and `AppContainerAITests.swift` cover container wiring for different data sources and AI features.
- `VocabCraftAppTests/App/AppBootstrapperTests.swift` covers the bootstrap state machine, retry, reset, and deep-link replay.
- `VocabCraftAppTests/AppRouterTests.swift` covers tab selection and deep-link parsing.
