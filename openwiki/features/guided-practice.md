---
type: feature
title: Guided Practice and Roleplay
description: The AI assistant tab's Guided Communication Practice feature (missions, a turn-based coaching session, support levels, and persisted evidence) and the roleplay room and voice call built on the same AI and speech services.
tags: ["guided-practice", "roleplay", "ai-assistant", "dialogue", "speech", "feature-flag"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-7e8fba6fc565645c7f828599
    resource: repo://VocabCraftApp/Core/Configuration/GuidedPracticeFeatureConfiguration.swift
  - id: openwiki-source-d61029b9ba68dc0695febe5c
    resource: repo://VocabCraftApp/Data/GuidedPractice/PracticeAIAdapter.swift
  - id: openwiki-source-c40d8b7fc222b3f0980f17bc
    resource: repo://VocabCraftApp/Data/GuidedPractice/PracticePrivacyStore.swift
  - id: openwiki-source-3b6a859c9794a4a72ef68c45
    resource: repo://VocabCraftApp/Features/AIAssistant/GuidedPractice/PracticeSessionCoordinator.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

The AI Assistant tab hosts two related experiences:

- **Guided Communication Practice** is a mission-based coaching session. The learner speaks or types a reply, the AI character responds, a validator checks whether the learner used the target words, and support escalates only as far as needed. Results are saved as practice records and used for later missions.
- **Roleplay** (scenario room and voice call) is an open conversation with a character in a scripted scenario. It uses a dialogue state machine to steer the conversation toward target words.

The feature is behind a flag. When it is off, the tab shows the legacy roleplay hub.

## Entrypoints

- **Feature flag**: `GuidedPracticeFeatureConfiguration.enabled` (`VocabCraftApp/Core/Configuration/GuidedPracticeFeatureConfiguration.swift`) is true when the `-enable-guided-practice` launch argument is present, when the `ENABLE_GUIDED_PRACTICE=1` environment variable is set, or when the `enable_guided_practice` `UserDefaults` key is true. The `-test-guided-practice` launch argument turns it on for tests.
- **Tab**: `AIAssistantHubView` (`VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`) renders `PracticeHubView` when the flag is on and the legacy roleplay content otherwise.
- **Hub**: `PracticeHubViewModel` and `PracticeHubView` (`Features/AIAssistant/GuidedPractice`) list missions and resumable sessions. They are created by `AppContainer.makePracticeHubViewModel()`.
- **Session**: `PracticeSessionCoordinator` (`Features/AIAssistant/GuidedPractice/PracticeSessionCoordinator.swift`) owns one session. It is created by `AppContainer.makePracticeSessionCoordinator(...)`. Its screens are `PracticePreparationView`, `PracticeSessionView`, and `PracticeSummaryView`.
- **Roleplay**: `RoleplayRoomViewModel`, `RoleplayVoiceCallViewModel`, and the matching views in `Features/AIAssistant/Views`.

## Domain Model

- **Missions**: `PracticeMission` lists objectives and target words. Each target is a `PracticeWordSnapshot` with a `PracticeWordSense`. `PracticeContextFamily` covers dining, shopping, planning, social, travel, and work.
- **Session**: `PracticeSession` has a `PracticeSessionStatus` (`inProgress`, `completed`, `partial`, `abandoned`). `PracticeSessionState` drives the UI: `preparing`, `awaitingLearner`, `capturing`, `processing`, `playingCharacter`, `coaching`, `paused`, `recoverableError`, `saving`, `completed`, and `partial`.
- **Turns and evidence**: `PracticeTurn`, `WordUseEvidence` (whether a target word was used correctly), `SupportExposure`, and `CommunicationProgress`.
- **Support ladder**: `PracticeSupportLevel` orders the help the learner can get: `none` < `intent` < `lexical` < `frame` < `model`. `SupportOrigin` records what triggered it, such as `prelessonReview`, `learnerRequested`, `coachSuggested`, `characterSpeech`, `correction`, or `transcriptReplay`.
- **Contracts**: `PracticeContracts.swift` holds the cross-layer contracts, including `PracticePolicyConfiguration`. The default is `PracticePolicyConfiguration.v1`.

## Mechanisms

1. **Mission selection** — `SelectPracticeMissionUseCase.select(...)` filters learner progress to eligible words, builds candidate missions, and ranks them by priority tier. Starter missions come from `PracticeTemplateCatalog.templates`.
2. **Starting** — `start(mission:mode:)` resets the state, writes an initial checkpoint through the repository, and moves to `awaitingLearner`. Input is `voice` or text, and `switchInput(to:)` changes the mode mid-session.
3. **Learner turn** — `submit(text:mode:)` and the `startCapture()`/`finishCapture()` pair create a learner turn. `persistPendingTurn` saves it first, so a crash does not lose it.
4. **Character reply** — `queryAI` calls `PracticeAIAdapter.respond(to:)`. The adapter applies a 30-second timeout, retries with a format-repair pass when the structured reply does not match the schema, and truncates history. The system prompt tells the model to treat learner text as conversation, not instructions.
5. **Assessment** — `validateAssessmentSafely` runs `AssessPracticeTurnUseCase.validate`. It checks the reply and scope, validates quoted spans, and assigns a reliability: `final`, `edited`, `notApplicable`, `needsConfirmation`, or `uncertain`. The result becomes `WordUseEvidence` for each target word.
6. **Commit** — `commitTurn` writes the turn, support exposures, and evidence in one repository transaction. Evidence is keyed by `PracticeRecordMapper.evidenceLogicalKey`, so duplicate evidence is not stored twice.
7. **Speech out** — `playCharacterSpeechIfSupported` plays the reply through `PracticeSpeechAdapter`. Playback can be replayed with `replaySpeech(text:)`.
8. **Coaching** — `handleCoachFeedback` shows any coach note from the model. `SupportPolicy` decides which support level is allowed for the next prompt.
9. **Finish** — `finish(_:)` builds a `PracticeSummary`. `PracticeDifficultyPolicy` and `CommunicationProgressPolicy` use the summary to set the next difficulty and progress. `SupportPolicy` decides how much help is allowed.
10. **Recovery** — `PracticeSessionCoordinator+Recovery` resumes an unfinished session from its checkpoint. `PracticeSessionCoordinator+Presentation` and `PracticePresentationState` manage the presentation intents shown to the learner.

**Roleplay** uses a separate path. `ScenarioStateReducer.reduce(...)` moves a `ScenarioDialogueState` (dining, travel, interview, and daily-life states) based on the learner's turn and the classified intent from `DialogueIntentClassifier`. `TargetWordPrompter.generatePrompt(missingWords:scenario:)` builds a nudge that asks for a missing target word. `TurnBasedVoiceConversationEngine` and `ResilientConversationSpeechEngine` in `Features/AIAssistant/Services` run the voice loop.

## Persistence

- `PracticeModelActor` (`Data/GuidedPractice/PracticeModelActor.swift`, with `+Mutations`) is a `@ModelActor` that implements `PracticeRepositoryProtocol`. It stores sessions, turns, support exposures, presentations, word-use evidence, and communication progress as `SchemaV3` records.
- Each mutation takes an `expectedRevision`. A write from a stale copy of the session is rejected, which prevents two copies of the same session from overwriting each other.
- `PracticeRecordMapper` converts between domain values and records, and builds the logical keys used to deduplicate turns and evidence.
- See [Persistence](../core/persistence.md) for the schema versions.

## Privacy

- `PracticePrivacyStore` (`Data/GuidedPractice/PracticePrivacyStore.swift`) writes temporary audio files per session under `temporaryAudioURL(sessionId:filename:)`. It removes a session's audio with `removeTemporaryAudio(sessionId:)` and clears everything with `removeAllTemporaryAudio()`.
- Session records store text, scores, and evidence. The temporary audio files are the only audio the store manages.

## Relationships

- **Upstream**: `AppContainer` builds the hub, coordinator, and roleplay ViewModels, and supplies the AI provider (`LLMProviderProtocol`), `PracticeSpeechAdapter`, and the repository.
- **Shared services**: Speech input and output use [Audio and Speech](../core/audio-and-speech.md). Learner progress comes from [SRS Engine](../core/srs-engine.md) and vocabulary from [Dataset and Sync](../core/dataset-and-sync.md).
- **Domain**: Models, policies, and use cases are described in [Domain Entities](../core/domain-entities.md).

## State, Ordering, and Lifecycle

- `PracticeSessionCoordinator` is an `@Observable` `@MainActor` class. It is the only owner of session state, and it runs one operation at a time. Each operation has a `PracticeOperationToken`, so a late reply from an older operation is ignored.
- The coordinator stops active audio before starting a new session (`stopActiveAudio()`).
- A learner turn is persisted as pending before the AI is called, so an interrupted session can be resumed from its checkpoint.

## Invariants

- The system prompt tells the model to treat learner messages as conversation, not instructions.
- Evidence is deduplicated by logical key, and every write checks the session revision.

## Failure

- A reply that fails schema or format checks gets one format-repair retry. Timeouts and errors are captured as a `PracticeFailure` on the coordinator, and the session state reflects the error.
- Speech playback problems fall back to on-screen text.

## Configuration

- Enable the feature with `-enable-guided-practice`, `ENABLE_GUIDED_PRACTICE=1`, or the `enable_guided_practice` user default.
- The policy version is `PracticePolicyConfiguration.v1`.
- The AI request timeout is 30 seconds.

## Extension

- Add a mission by adding a `PracticeTemplate` to `PracticeTemplateCatalog`.
- Add a roleplay scenario in `Data/AI/RoleplayScenarioCatalog.swift`, then add its dialogue states to `ScenarioDialogueState` and its transitions to `ScenarioStateReducer`.
- Swap the AI provider by implementing `PracticeAIProtocol`.

## Tests

- `VocabCraftAppTests/AI/GuidedPractice/`:
  - Coordinator and flow: `PracticeSessionCoordinatorTests.swift`, `GuidedPracticeIntegrationTests.swift`, `PracticeRecoveryTests.swift`, and `PracticePresentationTests.swift`.
  - Assessment and policy: `PracticeAssessmentTests.swift`, `PracticeDifficultyPolicyTests.swift`, and `CommunicationProgressPolicyTests.swift`.
  - Persistence: `PracticeRepositoryTests.swift`, `PracticeRepositoryTransactionsTests.swift`, and `PracticeDeletionTests.swift`.
  - Adapters and missions: `PracticeAIAdapterTests.swift`, `PracticeSpeechAdapterTests.swift`, `PracticeHubTests.swift`, and `PracticeTemplateCatalogTests.swift`.
  - Fixtures: `Fixtures/practice-assessment-cases.json`.
