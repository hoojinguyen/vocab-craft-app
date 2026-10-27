---
type: "Reference"
title: "Dataset and sync"
openwiki_generated: true
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-50708200bbae0e3f79368a9f
    resource: repo://VocabCraftApp/App/DI/AppContainer.swift
  - id: openwiki-source-3d6a5b7535a86ab0b3946425
    resource: repo://VocabCraftApp/Core/Database/DataSources/BundledVocabularyDataSource.swift
  - id: openwiki-source-f7e111a8212657206b626577
    resource: repo://VocabCraftApp/Core/Database/DataSources/VocabularyDataSourceProtocol.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---


## Responsibility

Supplies the vocabulary catalog (decks, stages, and words) to domain use cases and repositories. It hides where the content comes from behind `VocabularyDataSourceProtocol`, so the same use cases run against the bundled JSON catalog, the copied SQLite content database, or mock data. Learner progress is not part of this layer. It lives in SwiftData (see [Persistence](persistence.md)).

## Entrypoints

- **Protocol**: `VocabCraftApp/Core/Database/DataSources/VocabularyDataSourceProtocol.swift` declares `fetchTopicDecks()`, `fetchSubTopicStages(deckId:)`, `fetchWordsForStage(stageId:)`, `searchWords(query:)`, `fetchWordById(id:)`, `fetchWordsByIds(ids:)`, `fetchAllWordsMap()`, `fetchLearningPaths()`, and `fetchTopicDecks(for:)`. A default implementation of `fetchLearningPaths()` returns `LearningPathDTO.defaultCuratedPaths`.
- **Bundled JSON source**: `BundledVocabularyDataSource.swift` loads `vocabulary_catalog.json` (`resourceName` defaults to `vocabulary_catalog`) from the bundle.
- **SQLite source**: `SQLiteContentRepository.swift` opens a `vocab_content.sqlite` file. It exposes the static helpers `readContentVersion(at:)` and `readLearningPathCount(at:)`.
- **Wire format**: `VocabularyCatalogDTO.swift` holds the decoded catalog. `TopicDeckDTO`, `SubTopicStageDTO`, `TopicWordDTO`, and `LearningPathDTO` are the DTOs. `TopicDeckDTO` picks Vietnamese or English titles and descriptions from the current locale, with fallback to the other language.
- **Mock and preview data**: `VocabCraftApp/Data/Local/Mock/MockVocabularyDataSource.swift` and `VocabCraftApp/Core/Database/SampleData/SampleVaultDataSeeder.swift`.
- **Wiring**: `AppContainer.getProductionDataSource()` (`VocabCraftApp/App/DI/AppContainer.swift`) chooses the production source. `AppBootstrapper` passes that source into `AppContainer`.

## Mechanisms

1. **Production source selection** — `getProductionDataSource()` copies the bundled `vocab_content.sqlite` (from the bundle root or `Content/`) into `Application Support/VocabCraft/Content/vocab_content.sqlite`. It copies when the file is missing, when the bundle content version is newer than the stored copy, when the `current_content_version` in `UserDefaults` is older, or when the stored copy has fewer than four learning paths. The new version is stored as `max(bundle, destination, 8)`. It then returns a `SQLiteContentRepository` for that file.
2. **Safe fallback** — If that setup throws, the function logs the error and returns `BundledVocabularyDataSource()`.
3. **Bundled JSON indexing** — `BundledVocabularyDataSource.loadAndIndex(bundle:resourceName:)` decodes `VocabularyCatalogDTO` and builds in-memory indexes: decks sorted by `sortOrder`, stages per deck, words per stage, and words by ID. Word IDs are `Int64`. `getOrLoadCatalog()` caches the result through the storage helper. `validateCatalog()` runs at boot. `starterWords(forStageId:)` provides built-in starter words.
4. **Repositories** — `VocabularyRepositoryImpl` joins the data source with `UserProgressModelActor` (`Word` to `UserWordProgress`). `MockVocabularyRepository` replaces it when the container is built with `useMockData`.
5. **Shadowing catalog** — Shadowing content is separate. `ShadowingSQLiteDatabase` (`VocabCraftApp/Data/DataSources/ShadowingSQLiteDatabase.swift`) opens `ShadowingCatalog.sqlite` from the bundle and throws `databaseNotFound` when it is missing. See [Shadowing](../features/shadowing.md).

## Relationships

- **Upstream**: The bundle resources (`vocabulary_catalog.json`, `vocab_content.sqlite`, `ShadowingCatalog.sqlite`) feed the sources above.
- **Downstream**: `FetchLearningPathUseCase`, `FetchPersonalVaultUseCase`, and `ReviewWeakWordsUseCase` depend on the protocol. Views never read the catalog directly.

## State, Ordering, Lifecycle

- The JSON catalog is indexed once and cached. The SQLite content file is replaced only by the version check at launch, so a newer bundled catalog reaches existing installs at the next boot.
- The copy from bundle to Application Support happens synchronously in `getProductionDataSource()`. A failure there is handled by the fallback in step 2.
- Refreshing the catalog within a running session requires a new container. Repositories do not watch the file.

## Invariants

- Source methods return empty collections when nothing matches, not `nil`. `fetchWordById` is the one method that returns an optional.
- Word IDs are stable `Int64` values. They link catalog words to `UserWordProgress.wordId`.
- `getProductionDataSource()` ignores `AppContainer.useSampleData`. That flag is stored on the container, and the production source is always chosen the same way.

## Failure

- A malformed catalog produces `VocabularyCatalogError.decodingFailed`, which `validateCatalog()` surfaces. Boot then moves to the database recovery state.
- An unreadable SQLite file falls back to the bundled JSON source.
- `VocabularyRepositoryImpl` falls back to mock behavior when `progressActor` is `nil`.

## Configuration

- `current_content_version` in `UserDefaults` tracks the installed content version.
- The bundled resource names are fixed in code (`vocabulary_catalog`, `vocab_content`). Injecting a different `VocabularyDataSourceProtocol` into `AppContainer(vocabularyDataSource:)` replaces the source.

## Extension

- Implement `VocabularyDataSourceProtocol` against a remote API or another store, then pass it to `AppContainer(vocabularyDataSource:)`.
- To ship new content, update `vocabulary_catalog.json` or `vocab_content.sqlite` and bump the content version so existing installs replace their copy.

## Tests

- `VocabCraftAppTests/Domain/VocabularyUseCasesTests.swift` covers the vocabulary use cases built on the data source.
- `VocabCraftAppTests/App/AppContainerVocabularyTests.swift` covers how `AppContainer` selects its vocabulary source.
