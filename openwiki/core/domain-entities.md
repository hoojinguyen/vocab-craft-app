---
type: "Reference"
title: "Domain entities"
openwiki_generated: true
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-006a96b7fe7be1e0c86df192
    resource: repo://VocabCraftApp/Domain/Entities/Word.swift
  - id: openwiki-source-cdd82d075f8a4868225d28f2
    resource: repo://VocabCraftApp/Domain/Policies/MasteryEvaluationPolicy.swift
  - id: openwiki-source-fb58e0a18af45b08425b5baf
    resource: repo://VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift
  - id: openwiki-source-f94a63c0855f3289277838d2
    resource: repo://VocabCraftApp/Domain/UseCases/GenerateMixedReflexQueueUseCase.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---


## Responsibility

The domain layer (`VocabCraftApp/Domain`) holds vocabulary entities, drill and session models, business policies, repository and service protocols, and use cases. It does not import SwiftUI or SwiftData, so it can be tested without a UI or a store. Persistence and UI sit in the Data and Features layers and depend on these protocols.

## Entrypoints

- **Entities** (`Domain/Entities`): `Word`, `PersonalWord`, `VaultWordItem` (conforms to `ReflexDrillable`), `SuggestedWord`, `MixedReflexDrillItem`, `ModeSuccessStats` with its `ModeSuccessStatsCodec`, `LessonPlanModels`, and the roleplay types `RoleplayScenario`, `RoleplayMessage`, `RoleplayTurnOutput`, `RoleplaySessionSummary`, and `RoleplayVoiceProfile`.
- **Models** (`Domain/Models`):
  - `QuickReflexAttempt`, `UserStageProgressData`, `LearningPathCurriculum`, and the AI pack types (`AIPackError`, `AIPackIdentifier`, `AIPackStatus`).
  - `Reflex/` holds `ReflexMode` and `ReflexDrillSessionPlan`.
  - `Shadowing/` holds the shadowing video, word-timestamp, and progress models.
  - `GuidedPractice/` holds `PracticeSession`, `PracticeTurn`, `PracticeMission`, `PracticeContracts`, `CommunicationProgress`, `SupportExposure`, and `WordUseEvidence`.
- **Policies** (`Domain/Policies`): `MasteryEvaluationPolicy`, plus `GuidedPractice/` with `CommunicationProgressPolicy`, `PracticeDifficultyPolicy`, and `SupportPolicy`.
- **Protocols** (`Domain/Protocols`): repository protocols (`VocabularyRepositoryProtocol`, `UserProgressRepositoryProtocol`, `SRSRepositoryProtocol`, `QuickReflexAttemptRepositoryProtocol`, `PracticeRepositoryProtocol`, and the three Shadowing repository protocols), speech and audio protocols (`TTSEngineProtocol`, `STTEngineProtocol`, `ReflexSpeechEngineProtocol`, `VoiceConversationEngineProtocol`, `VoiceConfiguration`, `AudioServiceProtocols`), AI protocols (`LLMProviderProtocol`, `PracticeAIProtocol`, `AIPackProtocol`), `UserRoadmapSettingsProtocol`, and `ReflexDrillable`.
- **Use cases** (`Domain/UseCases`), with the main ones listed:
  - Learning path and lessons: `FetchLearningPathUseCase`, `CompleteLessonUseCase`, `FastTrackUnitUseCase`, `ClaimTreasureRewardUseCase`, `InitializeUserRoadmapUseCase`, and `LessonPlanGenerator`.
  - Vault and review: `FetchPersonalVaultUseCase`, `ReviewWeakWordsUseCase`, `ToggleWordBookmarkUseCase`, `SmartVaultWordSelector`, and `SmartCheckpointWordSampler`.
  - Reflex and SRS: `GenerateMixedReflexQueueUseCase`, `RecordMixedDrillAttemptUseCase`, `PracticeDrillPlanGenerator`, `EvaluateSRSUseCase`, and `ResetUserProgressUseCase`.
  - Metrics: `FetchVocabGrowthMetricsUseCase`.
  - Roleplay: `FetchRoleplayScenariosUseCase`, `ExecuteRoleplayTurnUseCase`, and `CompleteRoleplaySessionUseCase`.
  - GuidedPractice (`UseCases/GuidedPractice`): `SelectPracticeMissionUseCase` and `AssessPracticeTurnUseCase`.

## Mechanisms

- **Entity mapping**: `Word` comes from the catalog. `PersonalWord` joins a word with its progress. `VaultWordItem` is the display model with bookmark state, and it is the input to the mixed reflex queue.
- **Mastery**: `MasteryEvaluationPolicy.evaluate(currentStreak:practicedModes:isCorrect:currentMode:)` returns the next streak, the set of practiced modes, and the mastery flag. A wrong answer resets the streak and the practiced modes. Mastery needs a streak of at least `requiredStreakForMastery` (3) and at least `requiredDistinctModesForMastery` (2) distinct reflex modes.
- **Mixed queue**: `GenerateMixedReflexQueueUseCase` assigns each vault item a random reflex mode, producing `MixedReflexDrillItem` values. `requeueFailedItem(_:)` picks a different mode for a retry and marks the item as a retry.
- **Vault**: `FetchPersonalVaultUseCase` takes a `PersonalVaultFilter` and an optional search query and returns a `PersonalVaultResult` with `PersonalWord` values and `PersonalVaultMetrics`. It reads the catalog through `VocabularyDataSourceProtocol` and the progress through `UserProgressRepositoryProtocol`.
- **Mode stats**: `ModeSuccessStats` tracks per-mode success counts. `ModeSuccessStatsCodec` stores them in the persisted `practicedModesRaw` field.
- **GuidedPractice**: `SelectPracticeMissionUseCase` chooses a mission, and `AssessPracticeTurnUseCase` scores a turn. The policies adjust difficulty and support levels. See [Guided Practice and Roleplay](../features/guided-practice.md).

## Relationships

- **Upstream**: The Data layer implements the repository protocols. Speech and AI adapters implement the engine and provider protocols.
- **Downstream**: Feature ViewModels depend on protocol types, which enables mock injection in tests. [SRS Engine](srs-engine.md) is downstream of `EvaluateSRSUseCase`.
- **Composition**: `AppContainer` builds the use cases and exposes them through stored properties and `make...UseCase()` factories. See [Dependency Injection](../architecture/dependency-injection.md).

## State and Lifecycle

Entities are value types (`struct`), and use cases are stateless services created once by `AppContainer`. The domain layer persists nothing. Persistence happens behind repository protocols.

## Invariants

- A `ReflexDrillable` must provide the fields the drill modes need. `VaultWordItem` conforms.
- A correct answer increments the streak only. A wrong answer resets it to 0 and clears the practiced modes.

## Failure

- Use cases report missing data as empty results or thrown errors. ViewModels turn those into empty states rather than crashes.
- A `ModeSuccessStatsCodec` decode failure on `practicedModesRaw` falls back to empty stats.

## Extension

- Add a use case by defining a protocol and a struct, then register it in `AppContainer`.
- Add a persisted entity by extending its codec and the matching Data-layer mapper.

## Tests

- Entity behavior: `VocabCraftAppTests/DomainEntitiesTests.swift` and `VocabCraftAppTests/Domain/VocabularyDomainEntitiesTests.swift`.
- `VocabCraftAppTests/Domain/VocabularyUseCasesTests.swift` and `LearningPathUseCasesTests.swift` cover the vocabulary and learning-path use cases.
- `VocabCraftAppTests/Domain/MasteryEvaluationPolicyTests.swift` covers the mastery rules.
- `VocabCraftAppTests/Domain/MixedReflexQueueUseCaseTests.swift` covers the mixed queue.
