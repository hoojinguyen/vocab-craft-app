---
type: "feature"
title: "Reflex Drill System"
description: "Reflex Blitz and Mixed drills: modes, DrillPlan generation, hint masking, cloze, distractor logic, and summary flows."
tags: ["reflex", "drills", "srs", "feature"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-4424fb6a614ae3d266d5843d
    resource: repo://VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift
  - id: openwiki-source-5263428e5c3dd0fa24a96814
    resource: repo://VocabCraftApp/Features/Reflex/Core/Utilities/ReflexClozeFormatter.swift
  - id: openwiki-source-8772d80cfe880c3f07b75a7b
    resource: repo://VocabCraftApp/Features/Reflex/Core/Utilities/ReflexHintMaskGenerator.swift
  - id: openwiki-source-453ae03dffbeb50fc22c641b
    resource: repo://VocabCraftApp/Features/Reflex/Mixed/ViewModels/MixedReflexDrillViewModel.swift
generated: { by: "opencode", at: "2026-09-02T08:37:35.164Z" }
---

## Responsibility

Provides rapid-fire vocabulary drills: Blitz (single-mode) and Mixed (interleaved typing/speaking/listening/multiple-choice) with adaptive queues and tactile feedback.

## Entrypoints

- **Blitz**: `Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift` + handlers `{Typing, Speaking, Listening, MultipleChoice}ModeHandler`, Views `ReflexBlitzView/Summary/ModeSelection/CountdownOverlay`.
- **Mixed**: `Features/Reflex/Mixed/ViewModels/MixedReflexDrillViewModel.swift`, Views `MixedReflexDrillView/Summary`.
- **Core**: `Features/Reflex/Core/Components/{Container/ReflexCardContainer, Modes/*ModeView, Consolidation}`, Models `ReflexBlitzOption, ReflexBlitzPhase, ReflexCardPhase`, Utilities `ReflexClozeFormatter, ReflexDistractorGenerator, ReflexHintMaskGenerator, ReflexDrillPlanGenerator/PlanItemBuilder`.
- **Domain**: `GenerateMixedReflexQueueUseCase`, `GenerateSmartReflexQueueUseCase`, `PracticeDrillPlanGenerator`, `RecordMixedDrillAttemptUseCase`.

## Mechanisms

1. **Queue generation**: Blitz uses predefined `ReflexBlitzWordItem.defaultStarterWords`; Mixed builds queue from selected `VaultWordItem` via `GenerateMixedReflexQueueUseCase` (shuffles, interleaves modes) or smart variant that biases weak words via `ModeSuccessStats`.
2. **Plan**: `PracticeDrillPlanGenerator` expands queue into `ReflexDrillPlanItem` list with cloze, distractors, hint levels. `ReflexDrillPlanGenerator` (feature) builds session plan with phase ordering.
3. **Handlers**: Each mode conforms to `ReflexModeHandlerProtocol`; e.g., `TypingModeHandler` validates typed answer via `ReflexClozeFormatter` + `ReflexTextMatchEngine`; `SpeakingModeHandler` delegates to `ResilientReflexSpeechEngine` + fuzzy matcher.
4. **Hint masking**: `ReflexHintMaskStrategy` / `ReflexHintMaskGenerator` progressively reveals letters (e.g., first/last, vowel masking) per attempt count.
5. **Flow**: `ReflexBlitzViewModel` phases: `modeSelection` → `countdown` → `drilling` (iterates `ReflexCardPhase`) → `summary` (`ReflexSessionSummary` with stars, XP). Mixed similar but with per-card mode switching.
6. **Persistence**: `RecordMixedDrillAttemptUseCase` logs `QuickReflexAttemptRecord` and triggers `EvaluateSRSUseCase`.

## Relationships

- **Upstream**: Vocabulary dataset + `UserWordProgress` → queue → plan → handlers.
- **Downstream**: Summary sheet offers retry/next; SRS update propagates to Homepage/Vault.

## State and Lifecycle

ViewModels are `@Observable` with `@MainActor`; current index, phase, hintLevel, combo, and per-card results held in memory. Session summary computed at end.

## Invariants

- `ReflexMode` raw values drive handler selection; unknown mode defaults to typing.
- `ReflexClozeStageSet` defines stage progression for cloze blanks; distractor generation avoids duplicate correct answer.

## Failure

- Empty queue shows empty state; STT unavailable shows fallback typing/hint UI when `allowSpeakingSkip` true.
- Speech timeout auto-fails card but allows manual retry.

## Configuration

Distractor count, hint mask strategy, and countdown duration are constants in utilities.

## Extension

Add mode by implementing `ReflexModeHandlerProtocol` + View; add plan step by extending `ReflexDrillPlanGenerator`.

## Tests

- `MixedReflexDrillViewModelTests.swift`, `MixedReflexDrillViewsTests.swift`, `MixedReflexQueueUseCaseTests.swift`, `SmartReflexQueueUseCaseTests.swift`, `ReflexDrillableTests.swift`, `ReflexLocalizationTests.swift`.
