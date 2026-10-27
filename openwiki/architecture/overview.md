---
type: architecture
title: Architecture Overview
description: Layered architecture of VocabCraft (SwiftUI and SwiftData, iOS 17+), covering the SPM package graph, feature modules including Guided Practice and Shadowing, boot sequence, and data flow between layers.
tags: ["architecture", "overview", "swiftui", "swiftdata", "clean-architecture"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-16a6a536c0a5303df5e05c6c
    resource: repo://Package.swift
  - id: openwiki-source-d85caf347254e99d90bcb93d
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift
  - id: openwiki-source-5d81637882ca78de29b1c749
    resource: repo://VocabCraftApp/App/Bootstrap/AppBootstrapper.swift
  - id: openwiki-source-50708200bbae0e3f79368a9f
    resource: repo://VocabCraftApp/App/DI/AppContainer.swift
  - id: openwiki-source-71661d79da6d20d09e06bcfd
    resource: repo://VocabCraftApp/App/VocabCraftApp.swift
  - id: openwiki-source-fb58e0a18af45b08425b5baf
    resource: repo://VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

VocabCraft is a SwiftUI and SwiftData vocabulary learning app for iOS 17+. It covers vocabulary browsing, spaced repetition, reflex drills (blitz and mixed), the personal vault, a learning path and homepage, Shadowing video practice, an AI assistant with Guided Practice and roleplay, a home-screen widget, and onboarding. It uses a Clean + MV architecture with `@Observable` ViewModels.

## Runtime and Build Entrypoints

- **App target**: `VocabCraftApp.xcodeproj`. The root `VocabCraftApp` struct in `VocabCraftApp/App/VocabCraftApp.swift` is the `@main` entry, marked `#if !SWIFT_PACKAGE`.
- **SPM graph** (`Package.swift`, swift-tools-version 5.10):
  - Root library `VocabCraftApp` depends on the local packages `Packages/CraftUIKit` and `Packages/SpeechKit`, and on the local `SwiftDataMacros` target.
  - A second library, `VocabCraftWidgetExtension`, depends on `VocabCraftApp` and `CraftUIKit` for WidgetKit.
  - Both targets enable the `StrictConcurrency` upcoming feature.
  - The `VocabCraftAppTests` test target bundles the Guided Practice assessment fixture `AI/GuidedPractice/Fixtures/practice-assessment-cases.json`.
- **Platforms**: `iOS(.v17)` and `macOS(.v14)`.
- **Tests**: `VocabCraftAppTests`, `Packages/CraftUIKit/Tests/CraftUIKitTests`, and `Packages/SpeechKit/Tests/SpeechKitTests`.

## Major Systems

| Layer | Location | Role |
|-------|----------|------|
| Design System | `Packages/CraftUIKit` | Tokens, theme presets, surface styles, and reusable containers and components |
| Speech | `Packages/SpeechKit` and `VocabCraftApp/Core/Audio` | STT and TTS engines, reflex speech recognition, and the audio session |
| Domain | `VocabCraftApp/Domain/{Entities,Models,Policies,Protocols,UseCases,Widget}` | Business rules, SRS, GuidedPractice and Shadowing models, and protocols |
| Data | `VocabCraftApp/Data/{AI,AIPacks,Audio,GuidedPractice,Local,Repositories,DataSources}` and `VocabCraftApp/Core/Database` | SwiftData models and actors, repositories, AI providers, dataset engine |
| Features | `VocabCraftApp/Features/{AIAssistant,Homepage,Lesson,Onboarding,Reflex,Settings,Shadowing,Vocabulary}` | ViewModels and Views per feature |
| App | `VocabCraftApp/App/{Bootstrap,DI,Navigation,Views}` | Bootstrap, composition root, routing, and the database recovery screen |

## Control and Data Flow

1. **Boot**: `VocabCraftApp` owns an `AppBootstrapper` (`App/Bootstrap/AppBootstrapper.swift`). `bootstrap()` creates the SwiftData `ModelContainer` through `SharedAppGroupContainer`, validates the bundled vocabulary catalog, creates the `AppRouter`, and then constructs `AppContainer`. The root view renders the app only in the `.ready` state. Otherwise it shows a progress view or `DatabaseRecoveryView`.
2. **Homepage**: `HomepageViewModel` calls `FetchLearningPathUseCase`, which reads the dataset and stage progress and maps the result to `CraftLearningPath` nodes. A lesson-economy policy gates unlocks, and the streak comes from `UserProgressModelActor`.
3. **Reflex**: `ReflexBlitzViewModel` and `MixedReflexDrillViewModel` build drill queues through `GenerateMixedReflexQueueUseCase` and `PracticeDrillPlanGenerator`. They run mode handlers (typing, speaking, listening, multiple choice), record attempts through `RecordMixedDrillAttemptUseCase`, and evaluate SRS through `EvaluateSRSUseCase`.
4. **Vault**: `PersonalVaultViewModel` uses `FetchPersonalVaultUseCase`. Bookmarks go through `ToggleWordBookmarkUseCase`, and smart review uses `ReviewWeakWordsUseCase`.
5. **Guided Practice and roleplay**: The AI assistant hub, roleplay room, and voice-call ViewModels are built by `AppContainer` factories. Practice sessions are coordinated by `PracticeSessionCoordinator` and persisted through `PracticeModelActor`. The dialogue state machine in `Data/AI/DialogueFSM` drives conversation turns.
6. **Shadowing**: The Shadowing hub and practice ViewModels read the video catalog through `ShadowingVideoRepositoryImpl` and `ShadowingCatalogRepository`, and store progress through `ShadowingProgressRepositoryImpl`.
7. **Persistence**: SwiftData models include `UserWordProgress`, `UserStageProgress`, `QuickReflexAttemptRecord`, and the practice records. Writes are serialized by `UserProgressModelActor` and `PracticeModelActor`.

## Upstream and Downstream

- **CraftUIKit** is upstream of every feature. Token changes propagate globally.
- **SpeechKit** and `Core/Audio` are upstream of the reflex speaking and listening modes, and of roleplay voice calls.
- **SwiftData** sits downstream of the domain. Domain entities map to and from the persisted records.
- **The widget extension** reads the shared app-group store, and its deck is refreshed when the app enters the background.

## State, Lifecycle, and Ordering

- The SwiftData schema is versioned in `Core/Database/Schemas` (`AppSchemaV1`, `AppSchemaV2`, and `AppSchemaV3`).
- `UserProgressModelActor` and `PracticeModelActor` serialize their writes, and repositories wrap the actors per call.
- Navigation state is centralized in `AppRouter` (`selectedTab`, `NavigationPath`, and pending handoffs for reflex config, Shadowing video ID, and smart review).

## Invariants and Failure

- Mock repositories are used only when the container is built with `useMockData` or when no `ModelContainer` is available. Production launches use SwiftData.
- A store failure moves `AppBootstrapper` to its `.error` state, where the user can retry or confirm a reset.
- Unsupported URL schemes are ignored by `AppRouter`.

## Configuration and Operations

- Build and test with `xcodebuild` or Xcode. The quality gate runs SwiftLint, `swift test`, and a check for zero compiler warnings. See [Build, Test and Quality](../operations/build-test-and-quality.md).
- Themes and localized strings are token- and string-driven rather than hardcoded. See [Localization and Theming](../operations/localization-and-theming.md).

## Extension Seams

- Add a feature by adding a domain use case, a feature ViewModel and Views, and a factory on `AppContainer`.
- Add a theme preset by conforming a type to `CraftTheme` (see [Design System](design-system.md)).
- Inject alternative implementations through `AppContainer` initializer parameters (see [Dependency Injection](dependency-injection.md)).

## Related Pages

- [Dependency Injection](dependency-injection.md)
- [Design System](design-system.md)
- [Persistence](../core/persistence.md)
- [Guided Practice and Roleplay](../features/guided-practice.md)
- [Shadowing](../features/shadowing.md)

## Tests

The test suites cover domain use cases, the SRS engine, vault and filter logic, reflex handlers, widget intents, the AI and Guided Practice flows, and component rendering in CraftUIKit.
