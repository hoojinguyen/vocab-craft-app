---
type: core
title: Dataset Engine and Data Sources
description: DatasetEngine vocabulary dataset pipeline, data-source abstraction, sample seeding, and AppContainer wiring.
tags: ["dataset", "datasource", "vocabulary", "sync"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-e439a01ba29638c43c4da477
    resource: repo://VocabCraftApp/Core/Database/DatasetEngine.swift
  - id: openwiki-source-f7e111a8212657206b626577
    resource: repo://VocabCraftApp/Core/Database/DataSources/VocabularyDataSourceProtocol.swift
  - id: openwiki-source-bb9a8a1023913890885dcaec
    resource: repo://VocabCraftApp/Core/Database/SampleData/SampleVocabularyDataSource.swift
  - id: openwiki-source-ae3bf0d8513f8d1c5a7ce8e1
    resource: repo://VocabCraftApp/Core/Database/SampleData/VocabularySampleDataset.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Owns vocabulary dataset ingestion, staging, and serving to domain use cases. Abstracts over curated sample data vs production source via `VocabularyDataSourceProtocol`.

## Entrypoints

- **Engine**: `Core/Database/DatasetEngine.swift` — loads and indexes dataset.
- **Models**: `DatasetModels.swift` — deck/stage/word raw structures.
- **Protocol**: `Core/Database/DataSources/VocabularyDataSourceProtocol.swift` and `Domain/Protocols/DatasetDataSourceProtocol.swift` — fetch interfaces.
- **Seeders**: `Core/Database/SampleData/{SampleVocabularyDataSource, VocabularySampleDataset, SampleVaultDataSeeder}.swift`.
- **Wiring**: `VocabCraftApp.init` creates `DatasetEngine()` and passes to `AppContainer`.

## Mechanisms

1. **Loading**: `DatasetEngine` reads bundled JSON/plist dataset, decodes to `DatasetModels`, builds in-memory indexes by deckId/stageId/wordId and CEFR level.
2. **DataSource abstraction**: `VocabularyDataSourceProtocol` exposes `fetchWords(deckId:stageId:)`, `fetchWord(id:)`, `search(query:)`, etc. `SampleVocabularyDataSource` returns canned `VocabularySampleDataset`; production implementation would query `DatasetEngine` indexes.
3. **Repositories**: `VocabularyRepositoryImpl` bridges `DatasetEngine` + `UserProgressModelActor` to domain (`Word` ↔ `UserWordProgress`). Mock variant bypasses engine for tests/previews.
4. **Seeding**: `SampleVaultDataSeeder` populates preview vault words; used by `AppContainer.mock`.
5. **Selection**: `AppContainer` currently forces sample source regardless of `useSampleData` flag (both branches instantiate `SampleVocabularyDataSource()`) — seam is present for future production switch.

## Relationships

- **Upstream**: Bundle resources → `DatasetEngine`.
- **Downstream**: `FetchLearningPathUseCase`, `FetchPersonalVaultUseCase`, `ReviewWeakWordsUseCase`, `VocabularyFilterService` all depend on `VocabularyDataSourceProtocol`; UI Views never touch engine directly.

## State, Ordering, Lifecycle

Dataset is loaded synchronously at boot; indexes are immutable thereafter. `DatasetEngine` is retained by `AppContainer` (optional — nil in mock mode). Refresh requires rebuilding container.

## Invariants

- `VocabularyDataSource` methods are synchronous or async-throwing; empty results return empty arrays, not nil.
- Word IDs are stable `Int64` primary keys linking dataset → `UserWordProgress.wordId`.

## Failure

- Missing bundle dataset logs and returns empty collections; app remains navigable.
- `VocabularyRepositoryImpl` degrades to mock when `progressActor` is nil.

## Configuration

`useSampleData` flag in `AppContainer`; dataset file paths hard-coded but replaceable via injected `VocabularyDataSourceProtocol`.

## Extension

Implement `VocabularyDataSourceProtocol` backed by remote API or CoreData; inject via `AppContainer(vocabularyDataSource:)`.

## Tests

- `DatasetDataSourceTests.swift`, `DatasetEngineTests.swift`, `SampleVocabularyDataSourceTests.swift`, `VocabularyUseCasesTests.swift`.
