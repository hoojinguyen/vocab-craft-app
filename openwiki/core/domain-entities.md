---
type: core
title: Domain Entities and Policies
description: Word, PersonalWord, VaultWordItem, drill items, protocols, use cases, and MasteryEvaluationPolicy.
tags: ["domain", "entities", "use-cases", "policies"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-006a96b7fe7be1e0c86df192
    resource: repo://VocabCraftApp/Domain/Entities/Word.swift
  - id: openwiki-source-cdd82d075f8a4868225d28f2
    resource: repo://VocabCraftApp/Domain/Policies/MasteryEvaluationPolicy.swift
  - id: openwiki-source-fb58e0a18af45b08425b5baf
    resource: repo://VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift
  - id: openwiki-source-f94a63c0855f3289277838d2
    resource: repo://VocabCraftApp/Domain/UseCases/GenerateMixedReflexQueueUseCase.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Pure Swift domain layer containing vocabulary entities, drill models, repository protocols, and business use cases. No SwiftUI or SwiftData imports; fully testable.

## Entrypoints

- **Entities** (`Domain/Entities`): `Word`, `PersonalWord`, `VaultWordItem`, `SuggestedWord`, `ReflexDrillItem`, `MixedReflexDrillItem`, `ModeSuccessStats`.
- **Models** (`Domain/Models`): `QuickReflexAttempt`.
- **Policies**: `Domain/Policies/MasteryEvaluationPolicy.swift` — threshold for mastery promotion.
- **Protocols** (`Domain/Protocols`): `VocabularyRepositoryProtocol`, `UserProgressRepositoryProtocol`, `SRSRepositoryProtocol`, `QuickReflexAttemptRepositoryProtocol`, `AudioServiceProtocols`, `ReflexDrillable`, `ReflexSpeechEngineProtocol`.
- **UseCases** (`Domain/UseCases`): `FetchLearningPathUseCase`, `CompleteLessonUseCase`, `FetchPersonalVaultUseCase`, `ReviewWeakWordsUseCase`, `ToggleWordBookmarkUseCase`, `GenerateMixedReflexQueueUseCase`, `GenerateSmartReflexQueueUseCase`, `PracticeDrillPlanGenerator`, `RecordMixedDrillAttemptUseCase`, `ResetUserProgressUseCase`, `EvaluateSRSUseCase`, `SmartVaultWordSelector`.

## Mechanisms

- **Entity mapping**: `Word` (from dataset) ↔ `PersonalWord` (Word + progress) ↔ `VaultWordItem` (display model with bookmark state). `ModeSuccessStats` tracks per-mode success counts encoded via `ModeSuccessStatsCodec`.
- **Policies**: `MasteryEvaluationPolicy` encodes rule like consecutive correct streak ≥3 and intervalDays ≥ threshold promotes mastery; consumed by `EvaluateSRSUseCase` and `SRSEngine`.
- **UseCase pattern**: Each use case is a struct with `execute(_:)` acting on protocols, e.g., `FetchPersonalVaultUseCase` merges `VocabularyDataSource` + `UserProgressRepository` to produce filtered vault list; `GenerateMixedReflexQueueUseCase()` shuffles selected vault items into interleaved drill queue.
- **Filter service**: `VocabularyFilterService` provides search/CEFR/bookmark filters used by vault ViewModel.

## Relationships

- **Upstream**: Data layer provides repository implementations.
- **Downstream**: Feature ViewModels depend on protocol types, enabling mock injection.
- **Cross**: `SRSEngine` and `MasteryEvaluationPolicy` are downstream of `EvaluateSRSUseCase`.

## State and Lifecycle

Entities are value types (`struct`) or lightweight classes; no persistence. Use cases are stateless services instantiated once in `AppContainer`.

## Invariants

- `ReflexDrillable` conformance required for any drillable word; missing fields default via codec.
- Bookmark toggle is idempotent; vault fetch deduplicates by wordId.

## Failure

- Use cases throw domain errors (e.g., word not found) surfaced as empty states, not crashes.
- Codec decode failure on `practicedModesRaw` falls back to empty stats.

## Extension

Add use case by defining protocol + struct, register in `AppContainer`. Add entity by extending codec if persisted.

## Tests

- `DomainEntitiesTests.swift`, `VocabularyDomainEntitiesTests.swift`, `VocabularyUseCasesTests.swift`, `LearningPathUseCasesTests.swift`, `MasteryEvaluationPolicyTests.swift`, `Domain/MixedReflexQueueUseCaseTests.swift`.
