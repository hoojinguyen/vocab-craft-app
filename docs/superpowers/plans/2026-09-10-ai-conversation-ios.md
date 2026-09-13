# iOS Conversation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver optional, resumable conversation role practice using CraftUIKit and SpeechKit.

**Architecture:** An observable session model coordinates injected audio, content and progress dependencies. Pure evaluation and progression policies remain independently testable. API implementation belongs to the API team; production integration waits for their released contract.

**Tech Stack:** Swift, SwiftUI, Observation, SwiftData, SpeechKit, CraftUIKit, Swift Testing/XCTest; retain current iOS 17/macOS 14 package floors.

**Spec:** [Approved iOS design](../specs/2026-09-10-ai-conversation-ios-design.md); [API handoff](../specs/2026-09-10-ai-conversation-api-design.md).

## Global Constraints

- Không thêm thư viện chat ngoài.
- API/content pipeline thuộc team API.
- Stage là tùy chọn: không chặn lesson tiếp theo, checkpoint, deck tiếp theo hoặc tính vào mẫu số tiến độ bắt buộc.
- Không lưu audio để khôi phục.
- Mọi styling mới dùng token CraftUIKit.
- Hoàn thành một vai là đủ; retry requires an explicit tap, first arrival at a user turn listens automatically.
- No backend changes, new XP policy, onboarding redesign, live chat or phoneme-score claims.
- Preserve existing Reflex behavior when changing shared speech code. All UI/a11y strings require complete manual EN/VI catalog entries.
- Each coding task follows red → green → focused regression → review → commit. Do not commit unexpected Xcode metadata without explaining it.

## Execution boundaries and file map

Tasks 1–6 form the iOS implementation milestone using controlled fixtures. Task 7 connects production data only after the API team delivers a compatible bundle, response fixtures and client authentication contract. Task 8 is the release gate. Do not expose fixtures to production users or call milestone one full feature completion.

Create domain files under `VocabCraftApp/Domain/Conversation/` for immutable data, evaluation and progress rules; create the screen and session owner under `VocabCraftApp/Features/Conversation/`. Audio integration belongs in `Core/Audio/ConversationAudioAdapter.swift`; data access in `Core/Database/Repositories/ConversationProgressStore.swift` and `Core/Conversation/`. CraftUIKit owns generic display components only. Tests mirror these directories under `VocabCraftAppTests`; package tests stay in their packages.

Before execution use the worktree skill to inspect isolation and existing changes. Re-read AGENTS.md, both specs and applicable Swift skills. No implementation is part of writing this plan.

## Task 1: Domain identities, immutable snapshots and progress

**Files:** Create `Domain/Conversation/ConversationModels.swift`, `ConversationProgress.swift`, `ConversationContentValidator.swift`; create `VocabCraftAppTests/Domain/Conversation/ConversationModelsTests.swift` and `ConversationFixtures.swift`. Paths under Domain are relative to `VocabCraftApp`.

**Interfaces:** `ConversationRole: String, Codable, Sendable { case a, b }`; `ConversationTurn` has index, role, EN/VI text and target sense UUIDs/forms. `ConversationSnapshot` has UUID id/stageID, stageRevision, contentVersion, CEFR string, targets and ordered turns. `ConversationProgress` has snapshotID, role, nextTurnIndex, passedTurnIndices, stageCompleted. `ConversationContentValidator.validate(_:expectedStageID:expectedLevel:) throws` checks identity, level, complete bilingual text, 4–6 turns, A/B participation and target references. Empty optional datasets remain valid outside the snapshot validator.

- [ ] Write the progress failure test below; add malformed turn order, missing VI and wrong-stage fixture cases. `ConversationFixtures.fourTurns` is a four-turn EN/VI fixture alternating A/B, with deterministic UUIDs, one target per role and stage metadata; keep content outside product views.

```swift
@Test func changingRoleDoesNotCarryPassedTurns() {
    var progress = ConversationProgress(snapshotID: UUID(), role: .a,
        nextTurnIndex: 4, passedTurnIndices: [0, 2], stageCompleted: true)
    progress.restart(role: .b)
    #expect(progress.passedTurnIndices.isEmpty)
    #expect(progress.nextTurnIndex == 0)
    #expect(progress.stageCompleted)
}
```

- [ ] Run `swift test --filter ConversationModelsTests`; expect missing domain types, then validation failures while implementing.
- [ ] Implement immutable Codable/Sendable models, validation errors and restart behavior. Restart clears attempt progress, not the stage achievement:

```swift
mutating func restart(role: ConversationRole) {
    self.role = role
    nextTurnIndex = 0
    passedTurnIndices = []
}
```

- [ ] Run the same filter, verify UUIDs never convert to legacy Int64 word IDs; review scope and commit `feat: model conversation snapshots and role progress`.

## Task 2: Sentence completion policy and evaluation

**Files:** Create `Domain/Conversation/ConversationTurnEvaluator.swift`; modify `Packages/SpeechKit/Sources/SpeechKit/SpeechAssessmentService.swift` and `Protocols/SpeechAssessmentProtocol.swift`; test `VocabCraftAppTests/Domain/Conversation/ConversationTurnEvaluatorTests.swift` and existing `Packages/SpeechKit/Tests/SpeechKitTests/SpeechAssessmentServiceTests.swift`.

**Interfaces:** `ConversationTurnEvaluator.evaluate(transcript: String, target: String, requiredForms: [String]) -> ConversationTurnDecision` with passed, retry, noSpeech. `SpeechCompletionPolicy` exposes `.instantMatch` and `.endOfUtterance`; existing callers default to instantMatch. Conversation uses endOfUtterance. Evaluation tolerances are internal configurable policy, never displayed as acoustic pronunciation scores.

- [ ] Add a failing omission test and a service test that feeds a matching partial transcript then a final result; endOfUtterance must emit completion only for the latter. Also cover silence finalization without duplicate completion.

```swift
@Test func missingTargetAtEndCannotPass() {
    let result = ConversationTurnEvaluator().evaluate(
        transcript: "I would like a", target: "I would like a reservation",
        requiredForms: ["reservation"])
    #expect(result == .retry)
}
```

- [ ] Run `swift test --filter ConversationTurnEvaluatorTests` and `swift test --package-path Packages/SpeechKit --filter SpeechAssessmentServiceTests`; confirm new cases fail before changes.
- [ ] Add policy branching around early completion, preserving existing final/silence paths. Normalize punctuation/contractions, align complete target text via SpeechKit, reject missing content and missing required forms separately from fuzzy similarity. Empty transcript is noSpeech.

```swift
if completionPolicy == .instantMatch && eval.isPassed && hasSufficientCoverage {
    stopAssessing()
    onCompletion(eval)
}
```

- [ ] Test complete sentence, acceptable fuzzy word, omitted beginning/end, negation, target word and empty transcript. Run both filters plus existing ReflexSpeechMatcherTests. Commit `feat: evaluate complete conversation turns`.

## Task 3: Coordinated playback and capture

**Files:** Create `Core/Audio/ConversationAudioAdapter.swift`, `Domain/Conversation/ConversationAudioProtocol.swift`, `VocabCraftAppTests/Core/ConversationAudioAdapterTests.swift`; modify `Packages/SpeechKit/Sources/SpeechKit/Engine/SpeechRecognitionEngine.swift` for injected audio lifecycle and `Core/Audio/TextToSpeechService.swift` only where completion versus cancellation needs an explicit result. Use existing `Core/Audio/AudioSessionCoordinator.swift`.

**Interfaces:** MainActor `ConversationAudioProtocol`: `play(text: String) async throws`, `capture(target: String, requiredForms: [String]) async throws -> ConversationTurnDecision`, `stop()`. `play` returns normally only for finished playback; cancellation throws. Adapter owns generation tokens and capture leases; package cannot import app coordinator.

- [ ] Create `ConversationAudioSpy` implementing this protocol: logs play/capture/stop, returns configurable decisions, allows suspended playback to simulate cancellation. Write ordering/cancellation tests before wiring live engine.

```swift
// Required trace for a partner turn followed by user capture:
#expect(events == ["playStarted", "playFinished", "captureStarted"])
// Cancelled playback must never cause captureStarted.
```

- [ ] Run `swift test --filter ConversationAudioAdapterTests`; expect new ordering assertions to fail against incomplete wiring.
- [ ] Provide an injected engine lifecycle so the conversation path acquires/releases the app coordinator lease instead of directly toggling AVAudioSession. Keep legacy construction supported. Stop capture before playback and reject stale callbacks by generation:

```swift
generation += 1
let activeGeneration = generation
try await playback(text)
try Task.checkCancellation()
guard generation == activeGeneration else { throw CancellationError() }
```

- [ ] Test denied permission, playback failure, stop during capture, no speech, stale callback and interruption; run existing speech service and coordinator tests. Commit `feat: coordinate conversation playback and recording`.

## Task 4: Durable snapshot and role progress

**Files:** Create `Core/Database/Schemas/AppSchemaV3.swift`, `Core/Database/Repositories/ConversationProgressStore.swift`, `Domain/Conversation/ConversationProgressStoreProtocol.swift`, `VocabCraftAppTests/Core/ConversationProgressStoreTests.swift`; modify `Core/Database/SharedAppGroupContainer.swift`, `Core/Database/SwiftDataModels.swift`. Preserve frozen V1/V2 schema definitions.

**Interfaces:** MainActor `ConversationProgressStoreProtocol`: `load(key: String) throws -> ConversationStoredSession?`, `save(key: String, snapshot: ConversationSnapshot, progress: ConversationProgress) throws`. StoredSession contains snapshot and progress. Key encodes current local profile identity, stage UUID and CEFR unambiguously; use the same key when loading/replacing. No new account system.

- [ ] Write save/reopen test, replacement failure test and V2→V3 migration test with existing vocabulary records preserved. Use in-memory SwiftData for transactional unit tests and a temporary disk URL for reopen/migration.

```swift
try store.save(key: key, snapshot: snapshot, progress: progress)
let restored = try store.load(key: key)
#expect(restored?.snapshot.id == snapshot.id)
#expect(restored?.progress.passedTurnIndices == progress.passedTurnIndices)
```

- [ ] Run `swift test --filter ConversationProgressStoreTests`; expect missing schema/store before implementation.
- [ ] Add a versioned conversation record to V3 containing unique key and Codable snapshot/progress Data; retain all existing model fields. Extend migration chain and current aliases together; never modify historic schemas. Encode before mutation, save snapshot/progress in one context transaction and roll back on failure:

```swift
do { try context.save() }
catch { context.rollback(); throw error }
```

- [ ] Run migration, app-group/widget regression and store tests; verify errors are thrown rather than silently accepted when persistence is unavailable. Commit `feat: persist conversation practice sessions`.

## Task 5: Observable session state machine

**Files:** Create `Features/Conversation/ConversationSessionModel.swift`, `ConversationSessionState.swift`, `VocabCraftAppTests/Features/Conversation/ConversationSessionTests.swift`.

**Interfaces:** MainActor observable model initialized with snapshot, progress key, audio protocol and progress store. Exposes `state`, `currentTurnIndex`, `selectedRole`, `progress`; actions `start(role:) async`, `retry() async`, `pause()`, `resume() async`, `close()`, `restart(role:) async`. State cases exactly follow spec: loading, ready, playingPartner, listening, evaluating, awaitingRetry, paused, completed, loadFailed. awaitingRetry includes a typed reason.

- [ ] Test with Task 3 spy and Task 4 in-memory store: A/B first turn, retry remains idle until explicit action, final partner line plays before completed, duplicate callback ignored, reopen paused, save failure does not report completed.

```swift
await model.start(role: .a)
#expect(model.state == .awaitingRetry(.readAgain))
let captureCount = audio.captureCount
await Task.yield()
#expect(audio.captureCount == captureCount)
await model.retry()
#expect(audio.captureCount == captureCount + 1)
```

- [ ] Run `swift test --filter ConversationSessionTests`; verify failure, then implement one transition at a time.
- [ ] Drive ordered turns using role; await playback or capture, check task/session generation, persist a passed turn before advancing. On retry return control to UI, never loop into recording automatically. Completing all selected-role turns plus trailing playback preserves stage achievement.

```swift
let decision = try await audio.capture(target: turn.textEn,
                                      requiredForms: turn.requiredForms)
guard generation == currentGeneration else { return }
switch decision {
case .passed: try savePassedTurnAndAdvance()
case .retry: state = .awaitingRetry(.readAgain)
case .noSpeech: state = .awaitingRetry(.noSpeech)
}
```

`savePassedTurnAndAdvance()` is a private model helper: update a copy of progress, persist, then publish the new progress/index. `currentGeneration` is captured before the async turn. Errors publish a retry/persistence notice without advancing. `close`/`pause` invalidate generation, cancel task and stop audio; persisted checkpoints survive abrupt termination.

- [ ] Run session/audio/store filters together and review interruption/resume paths. Commit `feat: orchestrate resumable conversation role practice`.

## Task 6: CraftUIKit component and practice screen

**Files:** Create `Packages/CraftUIKit/Sources/CraftUIKit/Components/Conversation/CraftConversationTurnView.swift`, corresponding `Tests/CraftUIKitTests/Components/CraftConversationTurnTests.swift`; create `Features/Conversation/ConversationView.swift`, `ConversationTranscriptView.swift`, `ConversationSummaryView.swift`, `ConversationScrollPolicy.swift`, `VocabCraftAppTests/Features/Conversation/ConversationScrollPolicyTests.swift`; update both Localizable.xcstrings catalogs.

**Interfaces:** Turn view receives roleLabel, EN/VI strings, translation visibility, active/retry/completed presentation, speech tokens and onToggleTranslation/onReplay closures. It never owns recording or persistence. Transcript view owns manual-scroll tracking; `ConversationScrollPolicy` has `isFollowing`, `userScrolled()`, `returnToCurrent()`.

- [ ] Write scroll policy test and EN/VI key parity checks; create deterministic component previews for pending/active/retry and long bilingual text with Dynamic Type.

```swift
@Test func manualScrollStopsFollowing() {
    var policy = ConversationScrollPolicy()
    policy.userScrolled()
    #expect(!policy.isFollowing)
    policy.returnToCurrent()
    #expect(policy.isFollowing)
}
```

- [ ] Run `swift test --filter ConversationScrollPolicyTests` and CraftUIKit LocalizationTests; confirm missing behavior/key failures.
- [ ] Compose using CraftCard, microphone hub, speaker/button and token components. All font/color/spacing/radius values come from theme. Implement supported-platform scrolling with ScrollViewReader and track user dragging separately from programmatic scrolling:

```swift
.onChange(of: currentTurnIndex) { _, index in
    guard scrollPolicy.isFollowing else { return }
    proxy.scrollTo(index, anchor: .center)
}
```

- [ ] Connect start/role choice, pause/resume, retry and summary actions to model; tapping text toggles translation only. Register scene/audio interruption callbacks to pause, never auto-resume. Localize `app.conversation.*` and `craft.conversation.*`, including a11y. Use static fixture files only for previews/tests.
- [ ] Verify long text, Reduce Motion, VoiceOver focus and no per-transcript announcement spam; run localization and component/policy tests. Review screen states before commit `feat: add CraftUIKit conversation practice screens`.

## Task 7: Production content integration and optional path nodes

**Files:** Create `Core/Conversation/ConversationRepository.swift`, `ConversationAPIClient.swift`, `ConversationDatasetReader.swift`, `Domain/Conversation/ConversationRepositoryProtocol.swift`, `ConversationStageAvailability.swift`; create `VocabCraftAppTests/Core/ConversationRepositoryTests.swift`, `VocabCraftAppTests/Domain/Conversation/ConversationStageAvailabilityTests.swift`. Modify `App/DI/AppContainer.swift`, `Features/Homepage/Views/HomepageView.swift`, `Features/Homepage/ViewModels/LearningPathDataMapper.swift`, `HomepageViewModel.swift`, CraftUIKit learning path model/node/detail components.

**Precondition:** API team supplies final schema version, sample SQLite, default and variant fixtures, endpoint/auth/idempotency behavior. Compare against handoff; resolve incompatible fields before writing production mappings. Do not modify the API repo. Keep this task pending if these inputs are missing; other tasks can complete.

**Interfaces:** `ConversationRepositoryProtocol` exposes `load(stageID: UUID, level: String) async throws -> ConversationSnapshot`, `regenerate(stageID: UUID, level: String, requestID: UUID) async throws -> ConversationSnapshot`. Dataset reader maps final UUID/sense contract without Int64 coercion. Stage availability takes source lesson IDs plus completed lesson IDs; optional node completion is separate from required progression.

- [ ] Add contract tests against delivered fixture: wrong stage/level/version rejected, old dataset yields no conversation nodes, failed regeneration retains old snapshot, repeated request reuses ID. Add pure source-availability test:

```swift
@Test func allSourcesAreRequiredForPractice() {
    #expect(!ConversationStageAvailability.canPractice(
        sources: ["lesson-a", "lesson-b"], completed: ["lesson-a"]))
}
```

- [ ] Run `swift test --filter ConversationRepositoryTests` and `swift test --filter ConversationStageAvailabilityTests`; confirm new assertions fail.
- [ ] Map final wire/dataset fields in adapters, validate before store replacement, apply service auth via existing configuration (never admin credentials). Preserve requestID through retries, disallow generation during active practice, confirm replacing a suspended attempt, atomically reset attempt only after a valid response.

```swift
static func canPractice(sources: Set<String>, completed: Set<String>) -> Bool {
    !sources.isEmpty && sources.isSubset(of: completed)
}
```

- [ ] Add `.conversation` presentation kind and update exhaustive switches, accessible labels and callouts. Mapper inserts nodes at supplied anchors without consuming required active-node position; checkpoint eligibility filters required lesson nodes only. In-memory progression and reload mapping must agree. Route Conversation to a separately constructed session screen; do not call `CompleteLessonUseCase` or award lesson XP.
- [ ] Run mapper/homepage/contract tests, including skipped conversation before checkpoint, missing source and regenerated completed stage. Smoke test the real delivered bundle/API. Commit `feat: integrate optional conversation stages with content contract`.

## Task 8: Verification and pronunciation acceptance gate

**Files:** Create `docs/validation/conversation-ios.md`; add meaningful regressions to prior task test files when device/integration failures reveal missing behavior.

- [ ] Discover simulator destination using `xcodebuild -showdestinations -scheme VocabCraftAppTests -project VocabCraftApp.xcodeproj`; select an available iOS simulator ID and save it as task-specific `CONVERSATION_SIM_ID` for subsequent shell commands. Do not invent a destination.
- [ ] Run each command and preserve full failures. All must pass without warnings before feature completion:

```bash
swift test --package-path Packages/CraftUIKit --filter LocalizationTests
swift test --package-path Packages/CraftUIKit
swift test --package-path Packages/SpeechKit
swift test
swiftlint
xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftAppTests -destination "platform=iOS Simulator,id=$CONVERSATION_SIM_ID"
xcodebuild build -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,id=$CONVERSATION_SIM_ID"
```

- [ ] On physical iPhone verify speaker and headset turn handoff, permission denial, silence, background/call interruption, retry, resume and manual scrolling. Record actual device/OS and observed results, not assumed outcomes.
- [ ] Evaluate representative readings against evaluator defaults: correct full sentences, small accent differences, omitted start/end/target, noise and pauses. Set thresholds only from these results; record false accept/retry cases and adjust code with regression tests. If device/audio evidence is unavailable, mark this gate outstanding and do not claim pronunciation behavior verified.
- [ ] Self-review spec coverage, perform code review per repo workflow, fix findings, inspect git diff/status for generated files. Commit validated changes and report any remaining external API/device gate explicitly.

## Plan self-review

Coverage: spec learning path → Task 7; experience/UI → Tasks 5–6; state → Task 5; audio/evaluation → Tasks 2–3, 8; CraftUIKit/localization → Task 6; persistence/regeneration → Tasks 1, 4, 7; verification → Task 8. Domain interfaces are introduced before consumers; backend creation remains outside scope. Numeric speech calibration and production wire mapping are explicit evidence gates, not guessed contracts.
