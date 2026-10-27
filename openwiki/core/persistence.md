---
type: core
title: Persistence
description: SwiftData schema versions V1 to V3 and their migration plan, the model actors that serialize writes, the shared app-group store used by the widget, UserDefaults-backed settings, and the JSON widget deck store.
tags: ["persistence", "swiftdata", "schema", "migration", "actors", "app-group"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-b7ff696f95e4904e05b351a9
    resource: repo://VocabCraftApp/Core/Database/Schemas/AppSchemaV2.swift
  - id: openwiki-source-5694d925740d017295aceec7
    resource: repo://VocabCraftApp/Core/Database/Schemas/AppSchemaV3.swift
  - id: openwiki-source-0db61ea7b3551c5ab3c560a0
    resource: repo://VocabCraftApp/Core/Database/SharedAppGroupContainer.swift
  - id: openwiki-source-4689ef33759ce866b13b26e9
    resource: repo://VocabCraftApp/Data/Local/Actors/UserProgressModelActor.swift
  - id: openwiki-source-6129f6d58cb09e213fd64071
    resource: repo://VocabCraftApp/Data/Local/Actors/UserProgressModelActor%2BMutations.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

Stores learner progress, practice history, and widget state on the device. SwiftData holds the progress records, and a few plain stores (`UserSettingsStore` in `UserDefaults`, `WidgetDeckStore` as JSON files) hold settings and widget data. Vocabulary content is not stored here. It comes from the bundled catalog (see [Dataset and Sync](dataset-and-sync.md)).

## Entrypoints

- **Schemas**: `VocabCraftApp/Core/Database/Schemas/AppSchemaV1.swift`, `AppSchemaV2.swift`, and `AppSchemaV3.swift` define `SchemaV1`, `SchemaV2`, and `SchemaV3` as `VersionedSchema` types.
- **Migration plan**: `AppMigrationPlan` in `VocabCraftApp/Core/Database/SharedAppGroupContainer.swift` lists the three schemas and two lightweight stages, V1 to V2 and V2 to V3.
- **Container**: `SharedAppGroupContainer.createContainer(configuration:storeURL:inMemory:)` builds the `ModelContainer` for `SchemaV3` with `AppMigrationPlan`. `resetStoreWithQuarantine` and `quarantineCorruptStoreFiles` handle recovery.
- **Actors**: `UserProgressModelActor` (`VocabCraftApp/Data/Local/Actors`) and `PracticeModelActor` (`VocabCraftApp/Data/GuidedPractice/PracticeModelActor.swift`) are `@ModelActor` actors. Their mutations live in extensions such as `UserProgressModelActor+Mutations.swift` and `PracticeModelActor+Mutations.swift`.
- **Repositories**: `StageProgressRepositoryImpl`, `SRSRepositoryImpl`, `QuickReflexAttemptRepositoryImpl`, `ShadowingProgressRepositoryImpl`, and `VocabularyRepositoryImpl` in `VocabCraftApp/Core/Database/Repositories` and `VocabCraftApp/Data/Repositories`.
- **Settings**: `UserSettingsStore` (`VocabCraftApp/Core/Database/UserSettingsStore.swift`) reads and writes `UserDefaults`.
- **Widget store**: `WidgetDeckStore` (`VocabCraftApp/Core/Widget/WidgetDeckStore.swift`) writes `widget_deck.json` and `widget_interaction.json`.

## Schema Versions

- **SchemaV2** adds `UserWordProgress`, `UserStageProgress`, `ReflexSessionLog`, `WidgetCurrentState`, and `QuickReflexAttemptRecord`.
- **SchemaV3** reuses the V2 progress models and adds six practice models: `PracticeSessionRecord`, `PracticeTurnRecord`, `SupportExposureRecord`, `PracticePresentationRecord`, `WordUseEvidenceRecord`, and `CommunicationProgressRecord`.
- Both steps are lightweight migrations, so existing stores upgrade without custom code.

## Mechanisms

1. **Store location**: `persistedStoreURL()` uses `user_progress.sqlite` in the app-group container `group.com.hoojinguyen.vocabcraft` when it is available. Otherwise it uses `VocabCraft/user_progress.sqlite` in Application Support, and as a last resort the temporary directory.
2. **Creation**: `createContainer` uses an in-memory configuration for `inMemory` requests and for XCTest runs with no explicit config. Otherwise it opens the file-backed store. If that fails, it moves the corrupt store aside with `quarantineCorruptStoreFiles` and throws `DatabaseStoreError.storeInitializationFailed`, which lets the bootstrapper show the recovery screen.
3. **Serialized writes**: `UserProgressModelActor` implements `UserProgressRepositoryProtocol`. It reads progress through `fetchEntity(wordId:)` and returns value snapshots (`UserWordProgressData`). Its mutations include `saveProgress`, `recordChallengeResult`, `toggleBookmark`, `markWordReviewed`, and `clearNeedsReview`. Actor isolation keeps these writes off the main thread and out of data races.
4. **Practice records**: `PracticeModelActor` implements `PracticeRepositoryProtocol` for guided practice. Its mutations (`savePendingTurn`, `preparePresentation`, `confirmPresentation`, `revise`, `commit`, and `finalize`) take an `expectedRevision` so that a stale write is rejected. Evidence is deduplicated per word before it is saved. See [Guided Practice and Roleplay](../features/guided-practice.md).
5. **Settings**: `UserSettingsStore` wraps `UserDefaults`, with `hasPersistedAppData` indicating whether the store already holds user records.
6. **Widget data**: `WidgetDeckStore.appGroup()` writes JSON into a `widget` directory in the app group, or in Application Support as a fallback. `saveDeck` and `saveInteraction` encode the widget deck and the interaction state. The widget extension reads the same files. See [Widgets and Intents](../features/widgets-and-intents.md).

## Relationships

- **Upstream**: Repositories wrap the actors, and `AppContainer` builds them from the `ModelContainer` created at boot (see [Dependency Injection](../architecture/dependency-injection.md)).
- **Downstream**: Use cases in the domain layer depend on the repository protocols, not on SwiftData types. [SRS Engine](srs-engine.md) reads and writes the progress records through its repository.

## State, Ordering, and Lifecycle

- SwiftData models are reference types owned by the actor's model context. Repositories exchange value types with the rest of the app.
- Recovery order is: create the container, check for a persisted store, quarantine on failure, and let the user confirm a reset.
- The `-reset-progress` launch argument deletes the progress tables during bootstrap. This is a test and debug path.

## Invariants

- Progress writes go through actors, and views never touch a `ModelContext` directly.
- Schema changes must come with a new `SchemaVn` and a migration stage in `AppMigrationPlan`.
- Settings and the widget deck do not share state with SwiftData records.

## Failure

- A corrupt store is moved aside, not deleted, so it can be inspected.
- `DatabaseStoreError` carries the backup URL when one exists, and `DatabaseRecoveryView` offers retry and reset.
- Repositories fall back to mock implementations when no `ModelContainer` is available.

## Configuration

- The app group ID is `group.com.hoojinguyen.vocabcraft`.
- The store file name is `user_progress.sqlite`.
- The widget directory name is `widget`.

## Extension

- For a new persisted model, add it to a new `SchemaVn`, add a lightweight or custom migration stage, and expose it through an actor and a repository protocol.
- For a new setting, add a key to `UserSettingsStore`.

## Tests

- In-memory containers are created by `SharedAppGroupContainer.createContainer(inMemory: true)`. Tests use them for repository and actor behavior.
- `VocabCraftAppTests/App/AppBootstrapperTests.swift` covers the bootstrap and recovery paths.
