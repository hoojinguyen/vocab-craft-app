---
type: feature
title: Reflex Drill System
description: Timed reflex drills in four modes (speaking, typing, multiple choice, listening), the Blitz session flow and phases, the mixed drill that mixes modes across the personal vault, mode handlers with time limits and hint milestones, and the cloze and hint utilities.
tags: ["reflex", "drills", "blitz", "mixed", "speech", "hints"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-a3275ac4e7e5e1e427927898
    resource: repo://VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel%2BWordPreparation.swift
  - id: openwiki-source-b24972e328406442cba76955
    resource: repo://VocabCraftApp/Features/Reflex/Core/Models/ReflexBlitzPhase.swift
  - id: openwiki-source-5263428e5c3dd0fa24a96814
    resource: repo://VocabCraftApp/Features/Reflex/Core/Utilities/ReflexClozeFormatter.swift
  - id: openwiki-source-8772d80cfe880c3f07b75a7b
    resource: repo://VocabCraftApp/Features/Reflex/Core/Utilities/ReflexHintMaskGenerator.swift
  - id: openwiki-source-453ae03dffbeb50fc22c641b
    resource: repo://VocabCraftApp/Features/Reflex/Mixed/ViewModels/MixedReflexDrillViewModel.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

Reflex drills test recall under time pressure. The learner sees a word or a sentence and answers in one of four modes. Each attempt is timed, and hints appear at set milestones. Two flows use the same mode logic:

- **Blitz** runs a session of one chosen mode over a set of words.
- **Mixed** assigns a random mode to each vault word and runs them as one queue.

Attempts feed the SRS and the mastery policy. See [SRS Engine](../core/srs-engine.md) and [Domain Entities](../core/domain-entities.md).

## Entrypoints

- **Mode enum**: `ReflexMode` (`VocabCraftApp/Domain/Models/Reflex/ReflexMode.swift`) has four cases: `speaking`, `typing`, `multipleChoice`, and `listening`. It also provides each mode's time limit and display title. `ReflexDrillSessionPlan` (same folder) describes a session plan.
- **Blitz ViewModel**: `ReflexBlitzViewModel` (`Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift`), with extensions:
  - `+Configuration`: deep-link configuration, advancing words, finishing, re-drilling weak words, and cancellation.
  - `+WordPreparation`: starting a session, the countdown, loading words, and speaking preparation.
  - `+Submissions`: option selection, typed answers, spoken matches, and recording attempts.
  - `+Timers`: the stopwatch, hint timers, the timeout timer, and pause and resume.
- **Mixed ViewModel**: `MixedReflexDrillViewModel` (`Features/Reflex/Mixed/ViewModels/MixedReflexDrillViewModel.swift`).
- **Mode handlers**: `ReflexModeHandlerProtocol` and its four implementations in `Features/Reflex/Blitz/ViewModels/Handlers/`. Each handler sets `timeLimitSeconds`, `hintMilestones`, and how to prepare a word.
- **Phases**: `ReflexBlitzPhase` (`Features/Reflex/Core/Models/ReflexBlitzPhase.swift`) has `modeSelection`, `countdown`, `drilling`, `timeoutRevealing`, and `summary`.
- **Views**: `ReflexBlitzView`, `ReflexBlitzModeSelectionView`, `ReflexCountdownOverlayView`, `ReflexBlitzSummaryView`, and the mixed views `MixedReflexDrillView` and `MixedReflexSummaryView`. Mode-specific views are in `Features/Reflex/Core/Components/Modes`.

## Mechanisms

1. **Mode selection** — `selectMode(_:)` and `startDrillSession(mode:words:)` start a Blitz session. `startCountdown()` runs the countdown, and `beginSessionDirectly()` skips it.
2. **Per-word preparation** — `loadWord(at:)` prepares the next word. The mode handler's `prepareWord` returns options, cloze stages, the eliminated option, and the hint badge. For speaking, the speech engine is primed for the word.
3. **Drilling** — Each word has a timer. The learner answers with `selectOption`, `submitTypingAnswer`, or `handleSpokenMatch`. A timeout moves the phase to `timeoutRevealing`, which shows the answer before the next word.
4. **Hints** — `scheduleHintTimers` reveals hint stages at the mode's milestones. For speaking the milestones are 2.5, 4, and 5 seconds. The cloze and mask utilities produce each stage's text.
5. **Recording** — `recordAttempt` computes `calculateResponseTimeMs()` and saves the attempt. Attempts feed `EvaluateSRSUseCase` and `MasteryEvaluationPolicy`.
6. **Mixed queue** — `MixedReflexDrillViewModel` builds its queue with `GenerateMixedReflexQueueUseCase.generate(from:)`, which assigns each vault word a random mode. If a `PracticeDrillPlanGeneratorProtocol` is provided, the view model also builds a precomputed plan from the words. `submitAnswer` requeues a failed item with `requeueFailedItem(_:)` so it returns in a different mode.
7. **Speaking in mixed mode** — `skipSpeakingCurrentWord()` skips a speaking question without penalty and moves it to the end of the queue. `fallbackSpeakingItemsToTyping()` converts speaking items when speech is unavailable.
8. **Pause and resume** — `pauseCurrentDrill()` and `resumeCurrentDrill()` stop and restart the timers.
9. **Deep links** — `applyReviewConfig(_:)` applies a `ReflexBlitzDeepLinkConfig` from `AppRouter` (`mode`, `phase`, `state`, `hint`, and `combo`).
10. **Finish** — `finishSession()` builds a `ReflexSessionSummary`. `reDrillWeakWords()` starts a new session on the words the learner missed.

## Time Limits and Hints

| Mode | Time limit | Hint milestones |
| --- | --- | --- |
| Multiple choice | 4.5 s | Defined in `MultipleChoiceModeHandler` |
| Listening | 5.5 s | Defined in `ListeningModeHandler` |
| Speaking | 6.0 s | 2.5 s, 4.0 s, 5.0 s |
| Typing | 7.5 s | Defined in `TypingModeHandler` |

Hint stages are built by `ReflexHintMaskGenerator.generateStages(...)`. It shows progressively more of the word and uses a mask strategy (`ReflexHintMaskStrategy`). `ReflexClozeFormatter` finds the target word inside an example sentence, and `ReflexDistractorGenerator` builds wrong options for multiple choice.

## Relationships

- **Upstream**: Words come from the vault (`VaultWordItem`) or the lesson deck. Speech and recognition come from `ReflexSpeechEngineProtocol`, which is implemented by `ResilientReflexSpeechEngine`. See [Audio and Speech](../core/audio-and-speech.md).
- **Downstream**: Attempts go to the SRS (see [SRS Engine](../core/srs-engine.md)) and the progress records (see [Persistence](../core/persistence.md)). Lessons come from [Homepage and Learning Path](homepage-and-learning-path.md).
- **Vault**: Mixed and weak-word drills are started from [Vocabulary and Personal Vault](vocabulary-and-personal-vault.md).

## State and Lifecycle

- A session has one current word at a time. The phase changes from `countdown` to `drilling`, then to `timeoutRevealing` or back to `drilling`, and finally to `summary`.
- `cancelActiveTimers()` and `cancelAllTasks()` clean up when the learner leaves the screen.
- Speech sessions start and stop per word. The speech engine tracks whether a session and a word are active.

## Invariants

- Each mode's time limit comes from its handler, so the view does not hardcode timings.
- A failed mixed item is requeued in a different mode. It is not repeated in the same mode.
- A timeout always ends the word, and the answer is shown before the next word.

## Failure

- Permission problems for the microphone show a permission notice (`dismissPermissionNotice()`), and the session falls back to typing where possible.
- Speech recognizer errors reach the ViewModel through `onError`.

## Configuration

- Time limits and hint milestones are constants in the mode handlers.
- The deep-link config comes from `AppRouter.pendingReflexBlitzConfig`.
- Speaking-skip behavior is enabled for mixed drills.

## Extension

- Add a mode by adding a `ReflexMode` case and a handler that conforms to `ReflexModeHandlerProtocol`, then add its view under `Features/Reflex/Core/Components/Modes`.
- Add a hint strategy by extending `ReflexHintMaskStrategy` and `ReflexHintMaskGenerator`.

## Tests

- `VocabCraftAppTests/Reflex/` covers the reflex handlers and ViewModels.
- `VocabCraftAppTests/Domain/MixedReflexQueueUseCaseTests.swift` covers queue generation and requeueing.
- `VocabCraftAppTests/Domain/PracticeDrillPlanGeneratorTests.swift` covers plan generation.
