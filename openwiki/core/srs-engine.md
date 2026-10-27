---
type: "Reference"
title: "Srs engine"
openwiki_generated: true
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-ffa04ac0591c9c248e33551b
    resource: repo://VocabCraftApp/Core/SRS/SRSEngine.swift
  - id: openwiki-source-11fe568c004dd2ae010e4b73
    resource: repo://VocabCraftApp/Domain/UseCases/EvaluateSRSUseCase.swift
  - id: openwiki-source-fcefd5d6fad31cc9ef80a30b
    resource: repo://VocabCraftApp/Domain/UseCases/ReviewWeakWordsUseCase.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---


## Responsibility

Schedules when each vocabulary word is reviewed again. Given the current mastery level, ease factor, whether the answer was correct, and how quickly it was given, the engine computes the next mastery level, ease factor, and interval in days. The use case then stores the result as a review record.

## Entrypoints

- **Engine**: `VocabCraftApp/Core/SRS/SRSEngine.swift`. `SRSEngine.calculateNextInterval(currentMastery:easeFactor:isCorrect:responseTimeMs:)` is a pure static function that returns an `SRSResult`.
- **Use case**: `VocabCraftApp/Domain/UseCases/EvaluateSRSUseCase.swift`, `EvaluateSRSUseCaseProtocol`. `evaluateResponse(...)` is a pure computation. `recordReview(wordId:isCorrect:responseTimeMs:)` loads, computes, and saves.
- **Protocol**: `VocabCraftApp/Domain/Protocols/SRSRepositoryProtocol.swift` defines `SRSProgressItem` and `SRSRepositoryProtocol`, with `getProgress`, `saveProgress`, `logReflexSession`, and `resetAllProgress`.
- **Repository**: `VocabCraftApp/Data/Repositories/SRSRepositoryImpl.swift`. A SwiftData-backed version is used when SwiftData is available, and an in-memory dictionary version is used otherwise.
- **Due and weak words**: `VocabCraftApp/Domain/UseCases/ReviewWeakWordsUseCase.swift`, `ReviewWeakWordsUseCaseProtocol`, and `SmartReviewScheduling`.

## Mechanisms

**Incorrect answer.** The ease factor drops by 0.2 and has a floor of 1.3. Mastery resets to 0, and the interval is 1 day.

**Correct answer.**

1. Quality is 5 when `responseTimeMs` is under 2500 and 4 otherwise.
2. The ease change is `deltaEF = 0.1 - d × (0.08 + d × 0.02)`, where `d = 5 - quality`. The new ease factor is `max(1.3, easeFactor + deltaEF)`.
3. Mastery increases by 1 and is capped at 5.
4. The interval depends on the new mastery: 1 day at mastery 1, 6 days at mastery 2, and `round(6 × easeFactor^(mastery − 2))` from mastery 3 upward.

**Recording a review.** `EvaluateSRSUseCase.recordReview` does four things:

1. Loads the word's `SRSProgressItem` through `getProgress`. If none exists, it starts from `SRSProgressItem(wordId:)`.
2. Calls `evaluateResponse` with the stored mastery and ease factor.
3. Sets `nextReviewDate` to the current date plus the interval, and sets `lastReviewDate` to now. It increments `totalReviews`.
4. Calls `saveProgress` and returns the `SRSResult`.

**Due and weak words.** `ReviewWeakWordsUseCase` exposes three operations:

- `fetchDueWords(now:)` returns words whose `nextReviewDate` has passed or that are flagged `needsReview`, most overdue first. The protocol's default implementation falls back to `fetchWeakWords()`.
- `fetchWeakWords()` returns the weak words used for focused review.
- `markWordReviewed(wordId:isCorrect:)` grades a word in a Smart Review session.

**Smart Review scheduling.** `SmartReviewScheduling` runs the same `SRSEngine` math with a fixed response time of 3000 ms, since Smart Review has no response timer. It then derives the ease factor, interval, and next review date from that result.

## Relationships

- **Upstream**: Mixed and reflex drills supply correctness and response time. Reflex attempts are recorded separately through the reflex attempt repository.
- **Downstream**: The vault and homepage read the stored progress for review dates, mastery, and streak information. See [Vocabulary and Personal Vault](../features/vocabulary-and-personal-vault.md) and [Homepage and Learning Path](../features/homepage-and-learning-path.md).
- **Related**: [Domain Entities](domain-entities.md) defines the mastery policy (`MasteryEvaluationPolicy`), which is separate from the SRS interval math.

## State, Ordering, and Lifecycle

- `SRSResult` and `SRSProgressItem` are value types. The engine keeps no state.
- Every write goes through `SRSRepositoryProtocol`. In the SwiftData path, `SRSRepositoryImpl` is `@MainActor`, and it reads and writes `UserWordProgress` through its `ModelContext`.
- Scheduling order: evaluate the answer, save the progress, then let the rest of the app read it. Widget state is refreshed separately by the widget deck refresh use case.

## Invariants

- The ease factor never goes below 1.3.
- Mastery stays between 0 and 5.
- The interval is at least 1 day.
- A wrong answer always resets mastery to 0.

## Failure

- A missing progress record is treated as a new record created from `SRSProgressItem(wordId:)`. Nothing is thrown.
- Repository errors propagate to the caller as thrown errors. `recordReview` is `async throws`.
- `resetAllProgress` removes `UserWordProgress`, `ReflexSessionLog`, and `QuickReflexAttemptRecord` records in the SwiftData path. It is a no-op when there is no model context.

## Configuration

- No external configuration. The 2500 ms speed threshold, the 1.3 ease floor, the 0.2 ease drop on a wrong answer, and the 3000 ms Smart Review response time are constants in code.

## Extension

- To change the algorithm, replace `SRSEngine.calculateNextInterval` and keep its signature. `EvaluateSRSUseCase` will pick up the change.
- To track more data per review, extend `SRSResult` and `SRSProgressItem` together.

## Tests

- `VocabCraftAppTests/SRSEngineTests.swift` covers the interval table for correct and incorrect answers, including the speed bonus.
- `VocabCraftAppTests/Domain/MasteryEvaluationPolicyTests.swift` covers the mastery policy.
- `VocabCraftAppTests/EvaluateSRSUseCaseTests.swift` covers the use case. `VocabCraftAppTests/Domain/ModeSuccessStatsTests.swift` covers per-mode stats.
