---
type: core
title: SRS Engine and Scheduling
description: SRSEngine interval math, EvaluateSRSUseCase, stage progression, and weak-word review flows.
tags: ["srs", "scheduling", "spaced-repetition", "mastery"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-ffa04ac0591c9c248e33551b
    resource: repo://VocabCraftApp/Core/SRS/SRSEngine.swift
  - id: openwiki-source-11fe568c004dd2ae010e4b73
    resource: repo://VocabCraftApp/Domain/UseCases/EvaluateSRSUseCase.swift
  - id: openwiki-source-fcefd5d6fad31cc9ef80a30b
    resource: repo://VocabCraftApp/Domain/UseCases/ReviewWeakWordsUseCase.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Implements spaced-repetition scheduling: given current mastery, ease, correctness, and response speed, computes next interval and mastery promotion.

## Entrypoints

- **Engine**: `Core/SRS/SRSEngine.swift` — pure static `calculateNextInterval(currentMastery:easeFactor:isCorrect:responseTimeMs:)->SRSResult`.
- **Repository**: `Data/Repositories/SRSRepositoryImpl.swift` + protocol `SRSRepositoryProtocol`.
- **Use case**: `Domain/UseCases/EvaluateSRSUseCase.swift` — wraps engine + repo persistence.
- **Stage tracking**: `Core/Database/Repositories/StageProgressRepository.swift` — per-stage completion fraction.
- **Weak review**: `Domain/UseCases/ReviewWeakWordsUseCase.swift` — selects overdue words.

## Mechanisms

- **Incorrect**: easeFactor decreases by 0.2 (floor 1.3), mastery resets to 0, interval =1 day.
- **Correct**: quality derived from speed (`responseTimeMs<2500 → +1`, quality 4 or 5), deltaEF = 0.1 - (5-quality)*(0.08+(5-quality)*0.02), easeFactor rises (floor 1.3), mastery increments (cap 5). Interval: 1→1 day, 2→6 days, ≥3→ 6 * easeFactor^(mastery-2) rounded.
- **EvaluateSRSUseCase** fetches `UserWordProgress`, calls engine, persists updated progress, and checks `MasteryEvaluationPolicy` (consecutiveCorrectStreak etc.) to set `isMastered`.
- **StageProgressRepository** aggregates word mastery per stage into `progressFraction`; `CompleteLessonUseCase` marks stage complete when fraction=1.0.
- **ReviewWeakWordsUseCase** queries `UserWordProgress` where `nextReviewDate <= now` or `needsReview`, ordered by overdue days, for Vault SmartReview.

## Relationships

- **Upstream**: Reflex drills produce `QuickReflexAttemptRecord` → evaluated via SRS.
- **Downstream**: Homepage progress ring, PersonalVault stats, and streak read resulting intervals.

## State, Ordering, Lifecycle

- `SRSResult` value-typed; no retained state. Repository writes are via actor.
- Scheduling order: evaluate attempt → update progress → recompute stage fraction → update widget state.

## Invariants

- `easeFactor` never below 1.3 (SM-2 floor).
- `masteryLevel` capped at 5.
- `intervalDays` ≥1.

## Failure

- Missing progress record creates default (`mastery 0, ease 2.5`) rather than throwing.
- Concurrent evaluations serialized by actor; stale reads retry.

## Configuration

No external config; thresholds hard-coded per product spec but centralized in `SRSEngine` and `MasteryEvaluationPolicy`.

## Extension

Swap algorithm by replacing `SRSEngine.calculateNextInterval`; add metadata to `SRSResult`.

## Tests

- `SRSEngineTests.swift` covers interval tables for correct/incorrect + speed bonus.
- `EvaluateSRSUseCaseTests.swift`, `MasteryEvaluationPolicyTests.swift`, `ModeSuccessStatsTests.swift`.
