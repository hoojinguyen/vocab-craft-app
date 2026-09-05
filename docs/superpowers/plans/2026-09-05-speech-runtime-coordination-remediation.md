# Speech Runtime Coordination Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Lesson, Reflex Drill, and Vocabulary Practice speaking reliable and smooth by serializing scoped audio-session ownership, awaiting capture readiness, preserving stable Speak UI, and restoring deterministic countdown haptics.

**Architecture:** Add one app-scoped `AudioSessionCoordinator` actor shared by `ResilientReflexSpeechEngine` and `TextToSpeechService`, while keeping `SpeechAudioEngineController` focused on `AVAudioEngine`. Replace caller-managed prepare/begin sequencing with one atomic async `startListening` operation and make each feature start timers/UI listening only after readiness.

**Tech Stack:** Swift 6, Swift Concurrency actors and tasks, Observation, SwiftUI, AVFoundation, Speech, Swift Testing/XCTest, CraftUIKit, XcodeBuildMCP, SwiftLint.

**Spec:** `docs/superpowers/specs/2026-09-05-speech-runtime-coordination-remediation-design.md`

## Global Constraints

- Keep all work in PR #18; do not split Unit Drawer or Homepage changes into another PR.
- Scope the coordinator migration to `ResilientReflexSpeechEngine` and `TextToSpeechService`; issue #19 owns the full SpeechKit migration.
- Preserve Speak auto-start, with a stable `.preparing` state before `.listening`.
- Do not activate `.playAndRecord` or start `AVAudioEngine` during 3–2–1–Go.
- Permission denial must show one localized notice and use typing fallback for the rest of the feature session.
- All new display and accessibility strings require complete English and Vietnamese entries with manual extraction and translated state.
- Use CraftUIKit components and design tokens; add no raw view styling.
- Do not extract transcript observation unless a Release real-device trace proves broad invalidation is material.
- Every task follows red-green-refactor and ends with focused passing tests before commit.
- Final completion requires all tests, localization tests, SwiftLint, zero-warning Xcode build, and a Release real-device trace with no Lesson-related main-thread hang over 250 ms.

---

## File Structure

### New production files

- `VocabCraftApp/Core/Audio/AudioSessionCoordinator.swift` — process-global audio intent, lease, protocol, hardware abstraction, and production actor.
- `VocabCraftApp/Core/Audio/SpeechCaptureError.swift` — typed core failures used by all three affected features.
- `Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Countdown/CountdownHapticDriver.swift` — retained, injectable countdown haptic boundary.

### New test files

- `VocabCraftAppTests/Core/Audio/AudioSessionCoordinatorTests.swift` — lease precedence, generation, idempotency, and failure tests.

### Existing files with focused changes

- `VocabCraftApp/Core/Audio/SpeechAudioEngineController.swift` — retain pause intent across idle/preparing and finish cleanup deterministically.
- `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift` — acquire/release lease and expose atomic `startListening`.
- `VocabCraftApp/Core/Audio/TextToSpeechService.swift` — acquire playback through the coordinator; remove direct and detached session mutations.
- `VocabCraftApp/Core/Audio/MockResilientReflexSpeechEngine.swift` and `VocabCraftAppTests/Mocks/MockReflexServices.swift` — async start control and typed failure support.
- `VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift` — replace public prepare/begin sequencing with `startListening`.
- `VocabCraftApp/App/DI/AppContainer.swift` — own and inject exactly one coordinator.
- `VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift` — preparing/readiness/cancellation/fallback orchestration.
- `VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift` — stable preparing/listening presentation.
- `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift` and `SpeakingModeHandler.swift` — defer capture and stopwatch until readiness.
- `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift` — defer capture and item timer until readiness.
- `Packages/CraftUIKit/.../CraftSpeechModels.swift`, `CraftTactileMicHubView.swift`, and `CraftVoiceMatchCard.swift` — add and render `.preparing` without root identity changes.
- `Packages/CraftUIKit/.../CraftCountdownOverlay.swift` — inject clock/haptic driver and retain generators.
- Both app and CraftUIKit `Localizable.xcstrings` catalogs — bilingual preparing, permission, and Settings copy.

---

### Task 1: Lock Down Existing Audio-Engine Lifecycle Races

**Files:**
- Modify: `VocabCraftApp/Core/Audio/SpeechAudioEngineController.swift`
- Test: `VocabCraftAppTests/Features/Reflex/SpeechAudioEngineControllerTests.swift`

**Interfaces:**
- Consumes: existing `SpeechAudioHardware.prepare`, `pause`, `resume`, and `teardown` async methods.
- Produces: `SpeechAudioEngineController.prepare(relay:)`, `pause()`, `resume()`, and `teardown()` with retained pause intent and deterministic transitions.

- [ ] **Step 1: Re-run the two existing red tests as characterization evidence**

Use XcodeBuildMCP `test_sim` with:

```text
-only-testing:VocabCraftAppTests/SpeechAudioEngineControllerTests/pauseDuringPreparationPausesHardwareOnCompletion
-only-testing:VocabCraftAppTests/SpeechAudioEngineControllerTests/pauseWhileIdlePausesHardwareOnCompletion
```

Expected: both fail at `pauseCallCount == 1` before implementation.

- [ ] **Step 2: Add a teardown-versus-pending-pause regression test**

```swift
@Test("Teardown clears pending pause before the next lifecycle")
func teardownClearsPendingPause() async throws {
    let hardware = MockSpeechAudioHardware()
    let controller = SpeechAudioEngineController(hardware: hardware)
    await controller.pause()
    await controller.teardown()
    try await controller.prepare(relay: AudioBufferRelay())
    #expect(await hardware.pauseCallCount == 0)
}
```

- [ ] **Step 3: Run the controller suite and verify the new test is red-capable**

Use XcodeBuildMCP `test_sim` with `-only-testing:VocabCraftAppTests/SpeechAudioEngineControllerTests`.

Expected: the two known tests fail; the new lifecycle reset assertion fails if teardown preserves stale pause intent.

- [ ] **Step 4: Implement retained pause intent without changing state truthfulness**

Add `private var pauseRequested = false`. `pause()` sets it even from `.idle` or `.preparing`; `resume()` clears it. After hardware prepare succeeds, call `hardware.pause()` when `pauseRequested`, while keeping controller state `.ready` because the graph is prepared. `teardown()` clears the flag after invalidating the generation.

- [ ] **Step 5: Run the controller suite twice**

Expected on both runs: all `SpeechAudioEngineControllerTests` pass deterministically.

- [ ] **Step 6: Commit the lifecycle repair**

```bash
git add VocabCraftApp/Core/Audio/SpeechAudioEngineController.swift VocabCraftAppTests/Features/Reflex/SpeechAudioEngineControllerTests.swift
git commit -m "fix(audio): serialize pause intent with engine preparation"
```

---

### Task 2: Add the Scoped Audio-Session Coordinator

**Files:**
- Create: `VocabCraftApp/Core/Audio/AudioSessionCoordinator.swift`
- Create: `VocabCraftAppTests/Core/Audio/AudioSessionCoordinatorTests.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj` only if the project does not use synchronized file groups.

**Interfaces:**
- Consumes: `AVAudioSession` through an injected `AudioSessionHardware` protocol.
- Produces: `AudioSessionIntent`, `AudioSessionLease`, `AudioSessionCoordinating.acquire(_:)`, and `release(_:)`.

- [ ] **Step 1: Write coordinator tests before the production type**

Cover these exact cases with a recording mock hardware:

```swift
@Test func captureAcquireConfiguresDuplexAndHaptics() async throws
@Test func playbackDoesNotDowngradeActiveCapture() async throws
@Test func lastCaptureReleaseRestoresPlaybackWhenPlaybackLeaseRemains() async throws
@Test func staleGenerationReleaseCannotDeactivateNewSession() async throws
@Test func duplicateReleaseIsIdempotent() async throws
@Test func activationFailureDoesNotPublishLease() async throws
```

The mock records ordered operations such as `.setCategory(.playAndRecord)`, `.allowHaptics(true)`, `.setActive(true)`, and `.setCategory(.playback)`.

- [ ] **Step 2: Run the new suite and verify compile/test failure**

Use XcodeBuildMCP `test_sim` with `-only-testing:VocabCraftAppTests/AudioSessionCoordinatorTests`.

Expected: fail because the coordinator types do not exist.

- [ ] **Step 3: Implement the public boundary and internal hardware seam**

```swift
enum AudioSessionIntent: Hashable, Sendable {
    case playback
    case speechCapture
    case duplexSpeech
}

struct AudioSessionLease: Hashable, Sendable {
    let id: UUID
    let generation: UInt
    let intent: AudioSessionIntent
}

protocol AudioSessionCoordinating: Sendable {
    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease
    func release(_ lease: AudioSessionLease) async
}
```

Implement `AudioSessionCoordinator` as an actor with an `[UUID: AudioSessionLease]` registry, monotonic generation, derived effective intent, and a single `applyEffectiveIntent()` path. Wrap `AVAudioSession` in `AudioSessionHardware` so tests never touch device hardware.

- [ ] **Step 4: Apply the exact scoped policy**

For `.speechCapture` and `.duplexSpeech`, configure `.playAndRecord`, `.default`, `[.defaultToSpeaker, .allowBluetoothHFP]`, call `setAllowHapticsAndSystemSoundsDuringRecording(true)`, activate, and route to speaker. For playback-only, configure `.playback`, `.spokenAudio`, `[.duckOthers]`, then activate. Do not downgrade while any capture/duplex lease exists. Do not deactivate on a stale or duplicate release.

- [ ] **Step 5: Run coordinator and controller suites**

Expected: all tests pass with deterministic operation ordering.

- [ ] **Step 6: Commit the coordinator**

```bash
git add VocabCraftApp/Core/Audio/AudioSessionCoordinator.swift VocabCraftAppTests/Core/Audio/AudioSessionCoordinatorTests.swift VocabCraftApp.xcodeproj/project.pbxproj
git commit -m "feat(audio): add scoped audio session coordinator"
```

Do not stage `project.pbxproj` if it was not modified.

---

### Task 3: Inject One Coordinator into TTS and Speech Engines

**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/Core/Audio/TextToSpeechService.swift`
- Modify: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift`
- Modify: `VocabCraftAppTests/SpeechServiceTests.swift`
- Test: `VocabCraftAppTests/App/AppContainerVocabularyTests.swift`

**Interfaces:**
- Consumes: `AudioSessionCoordinating` from Task 2.
- Produces: `TextToSpeechService(audioSessionCoordinator:)`, `ResilientReflexSpeechEngine(audioController:audioSessionCoordinator:speechRecognizer:)`, and one `AppContainer.audioSessionCoordinator` instance.

- [ ] **Step 1: Add dependency identity and TTS policy tests**

Add an internal test-visible coordinator accessor or instance-identity spy, then verify:

```swift
@Test func appContainerSharesCoordinatorBetweenTTSAndCreatedSpeechEngines()
@Test func ttsPlaybackAcquireDoesNotReplaceActiveDuplexLease() async throws
@Test func ttsStopReleasesOnlyItsPlaybackLease() async throws
```

- [ ] **Step 2: Run the focused tests and verify they fail**

Use XcodeBuildMCP `test_sim` for `SpeechServiceTests` and `AppContainerVocabularyTests`.

- [ ] **Step 3: Make AppContainer the composition owner**

Add:

```swift
let audioSessionCoordinator: any AudioSessionCoordinating
```

Resolve it before TTS creation, inject it into the default `TextToSpeechService`, and pass the same instance from `makeReflexSpeechEngine()`.

- [ ] **Step 4: Migrate TTS without changing TextToSpeechProtocol**

Keep the synchronous `speak` API. Replace direct configuration with a stored, generation-checked `playbackStartTask` that awaits `.playback` acquisition before calling `synthesizer.speak` on MainActor. Store the lease and release it from `stop`, `didFinish`, and `didCancel`; cancellation must prevent an older request from starting after a newer `speak` call. `speakAsync` uses the same acquisition helper. Remove `ensureAudioSessionActive`, `isAudioSessionConfigured`, and the detached session mutation from `prewarm`; voice prewarming remains synchronous and session-free.

- [ ] **Step 5: Inject but do not yet consume the coordinator in the speech engine**

Store `audioSessionCoordinator` and preserve existing behavior until Task 4 moves acquisition into the atomic start path. This keeps the dependency change independently reviewable.

- [ ] **Step 6: Run TTS, AppContainer, and existing speech tests**

Expected: all focused tests pass and existing `TextToSpeechProtocol` callers compile unchanged.

- [ ] **Step 7: Commit dependency composition**

```bash
git add VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp/Core/Audio/TextToSpeechService.swift VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift VocabCraftAppTests/SpeechServiceTests.swift VocabCraftAppTests/App/AppContainerVocabularyTests.swift
git commit -m "refactor(audio): share coordinator across tts and speech"
```

---

### Task 4: Replace Prepare-and-Begin with Atomic Async Speech Start

**Files:**
- Create: `VocabCraftApp/Core/Audio/SpeechCaptureError.swift`
- Modify: `VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift`
- Modify: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift`
- Modify: `VocabCraftApp/Core/Audio/MockResilientReflexSpeechEngine.swift`
- Modify: `VocabCraftAppTests/Mocks/MockReflexServices.swift`
- Modify: `VocabCraftAppTests/SpeechServiceTests.swift`
- Modify: `VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift`

**Interfaces:**
- Consumes: coordinator from Task 2 and hardware controller from Task 1.
- Produces: `ReflexSpeechEngineProtocol.startListening(targetLemma:contextualPhrases:) async throws` and typed `SpeechCaptureError`.

- [ ] **Step 1: Write atomicity and cleanup tests**

Use suspended coordinator/controller mocks to verify:

```swift
@Test func startListeningDoesNotOpenWordBeforeLeaseAndEngineAreReady() async throws
@Test func cancelledStartReleasesItsLeaseAndDoesNotOpenWord() async
@Test func staleStartCannotReplaceNewerWord() async throws
@Test func stopDuringStartJoinsCleanupBeforeRestart() async throws
@Test func deniedMicrophoneThrowsTypedPermissionError() async
```

- [ ] **Step 2: Run focused speech suites and verify failure**

Expected: new tests fail because `startListening` and typed errors do not exist.

- [ ] **Step 3: Change the protocol boundary**

Add:

```swift
func startListening(
    targetLemma: String,
    contextualPhrases: [String]
) async throws
```

Remove `prepareEngineIfNeeded`, `resumeListening`, and `beginWord` from the public protocol after all Task 4 compilation fixes. Keep private helpers inside the concrete engine where useful. Update both mocks with a suspendable `startListening` continuation, call counts, captured target, and configurable typed failure.

- [ ] **Step 4: Implement ordered acquisition and recognition start**

Inside `ResilientReflexSpeechEngine`, increment a word generation; request authorization; acquire `.duplexSpeech`; await controller preparation/resume; check cancellation, active session, and generation; then create and attach the recognition request. Store the active lease. On any failure, clean up the request and release only the lease acquired by that operation.

- [ ] **Step 5: Remove all direct AVAudioSession changes from the scoped engine**

Delete `setCategory`, `setActive`, speaker override, and detached playback mutation. `stopSession` cancels the active start task, invalidates generation, orders controller teardown, and releases the stored lease through the coordinator.

- [ ] **Step 6: Replace hardcoded NSError messages with typed errors**

Map speech denial, microphone denial, activation failure, engine preparation failure, and unavailable recognizer to `SpeechCaptureError`. Do not add localized presentation strings to the core error type.

- [ ] **Step 7: Run all speech-engine and TTS tests twice**

Expected: the atomicity, cancellation, restart, and existing recognition tests pass on both runs.

- [ ] **Step 8: Commit the atomic speech boundary**

```bash
git add VocabCraftApp/Core/Audio/SpeechCaptureError.swift VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift VocabCraftApp/Core/Audio/MockResilientReflexSpeechEngine.swift VocabCraftAppTests/Mocks/MockReflexServices.swift VocabCraftAppTests/SpeechServiceTests.swift VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift
git commit -m "refactor(speech): make capture startup atomic"
```

---

### Task 5: Add Stable Preparing UI and Lesson Permission Fallback

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftSpeechModels.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftTactileMicHubView.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/VoiceMatch/CraftVoiceMatchCard.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Modify: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftSpeechUIComponentTests.swift`
- Modify: `Packages/CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift`
- Modify: `VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift`
- Modify: `VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift`
- Modify: `VocabCraftAppTests/Features/Lesson/LessonLocalizationTests.swift`

**Interfaces:**
- Consumes: atomic `startListening` and `SpeechCaptureError` from Task 4.
- Produces: `CraftSpeechState.preparing`, `CraftSpeechState.unavailable`, and Lesson session-level fallback.

- [ ] **Step 1: Add CraftUIKit model/render/localization tests**

Verify `.preparing` and `.unavailable` are equatable, render a body, do not report `isListening`, and resolve `craft.speech.preparing` plus unavailable accessibility copy in both `en` and `vi`.

- [ ] **Step 2: Add Lesson transition tests with suspended start**

```swift
@Test func speakingPublishesPreparingUntilAtomicStartReturns() async
@Test func listeningIsPublishedOnlyAfterStartSucceeds() async
@Test func advanceDuringPreparingCannotUpdateNextExercise() async
@Test func permissionDeniedDisablesSpeakingForSessionAndUsesTypingFallback() async
@Test func permissionNoticeIsPresentedOnlyOncePerSession() async
```

- [ ] **Step 3: Run CraftUIKit and Lesson suites and verify the new cases fail**

Use SwiftPM through XcodeBuildMCP for CraftUIKit and `test_sim` for Lesson tests.

- [ ] **Step 4: Add stable CraftUIKit states**

Add `.preparing` and `.unavailable` to `CraftSpeechState`. In `CraftTactileMicHubView`, keep the existing 136-point hub container and 80-point primary circle for all states; use existing theme typography, colors, spacing, and progress components. Pulse and waveform remain active only for `.listening`. Scope animations to the changed icon/status values.

- [ ] **Step 5: Change Lesson orchestration**

Set `.preparing` before creating the start task. Await `speechEngine.startListening`; re-check item ID, feedback state, generation, and cancellation; only then set `.listening`. Remove fake initial audio levels and the prepare/resume/begin sequence. On permission denial set `.unavailable`, mark Speak disabled, convert remaining speaking steps through the existing typing fallback transformation, and publish one dialog state with Settings action.

- [ ] **Step 6: Keep the action area structurally stable**

In `LessonExerciseContainerView`, use one fixed action container for retry/skip status. Change opacity, accessibility, and disabled state instead of adding/removing the whole root control region when speech state changes.

- [ ] **Step 7: Add bilingual strings**

Add manual, translated EN/VI values for preparing, permission explanation, open Settings, and unavailable accessibility content in the correct catalogs. Use `craft.*` only for reusable component copy and `app.lesson.*` for Lesson behavior.

- [ ] **Step 8: Run CraftUIKit localization/UI tests and Lesson tests**

Expected: all new state, cancellation, fallback, and localization tests pass.

- [ ] **Step 9: Commit Lesson and shared UI state**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftSpeechModels.swift Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftTactileMicHubView.swift Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/VoiceMatch/CraftVoiceMatchCard.swift Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings Packages/CraftUIKit/Tests/CraftUIKitTests/CraftSpeechUIComponentTests.swift Packages/CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift VocabCraftAppTests/Features/Lesson/LessonLocalizationTests.swift
git commit -m "fix(lesson): await speech readiness with stable preparing ui"
```

---

### Task 6: Migrate Reflex Drill and Vocabulary Practice

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/Handlers/SpeakingModeHandler.swift`
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift`
- Modify: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift` if any path still constructs an uninjected engine.
- Modify: `VocabCraftAppTests/Features/Reflex/ReflexModeHandlersTests.swift`
- Modify: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift`
- Modify: `VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift`
- Modify: `VocabCraftAppTests/App/AppContainerVocabularyTests.swift`

**Interfaces:**
- Consumes: atomic start, preparing/unavailable states, and shared AppContainer factory.
- Produces: readiness-gated Reflex/Vocabulary timers and identical permission fallback semantics.

- [ ] **Step 1: Replace old tests that expect capture during countdown**

Assert instead:

```swift
@Test func speakingCountdownDoesNotStartAudioSessionOrCapture()
@Test func reflexStopwatchWaitsForSpeechReadiness() async
@Test func reflexCancellationDuringStartDoesNotLoadStaleWord() async
@Test func mixedTimerWaitsForSpeechReadiness() async
@Test func mixedPermissionDenialUsesTypingForRemainingSpeakingItems() async
@Test func vocabularyUsesAppContainerSpeechEngineFactory()
```

- [ ] **Step 2: Run the focused Reflex/Mixed tests and verify failure against current eager behavior**

Expected: countdown and timer assertions fail before migration.

- [ ] **Step 3: Make SpeakingModeHandler preparation data-only**

Remove the synchronous `speechEngine.beginWord` side effect from `prepareWord`. The handler continues to produce options/hints and declares its speaking timing policy; the view model owns the async effect.

- [ ] **Step 4: Gate Reflex word activation and stopwatch**

During the global countdown do not call `startSession` in a mode that prepares hardware. After countdown completion, create a word-generation task, publish preparing, await `startListening`, verify current index/generation, then call `startStopwatch`. Cancel this task from timeout, word advance, mode change, summary, and dismissal.

- [ ] **Step 5: Gate Mixed/Vocabulary item activation and timer**

Replace direct `beginWord` in `startDrillItem` with the same async sequence. Do not start the 30 ms timer loop until readiness. Use `appContainer.makeReflexSpeechEngine()` for production construction so it receives the shared coordinator.

- [ ] **Step 6: Apply session-level permission fallback**

On typed permission denial, show the one-time localized feature notice and run remaining speaking items through typing mode. Do not retry activation in the same session.

- [ ] **Step 7: Run Reflex, Mixed, Vocabulary, Lesson, and audio suites**

Expected: all affected callers compile without public `beginWord`; all timers and capture effects obey readiness.

- [ ] **Step 8: Commit cross-feature migration**

```bash
git add VocabCraftApp/Features/Reflex VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftAppTests/Features/Reflex VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift VocabCraftAppTests/App/AppContainerVocabularyTests.swift
git commit -m "fix(reflex): gate speaking flows on capture readiness"
```

---

### Task 7: Make Countdown Haptics Deterministic

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Countdown/CountdownHapticDriver.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Countdown/CraftCountdownOverlay.swift`
- Modify: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftCountdownOverlayTests.swift`
- Modify: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift`
- Modify: `VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift`

**Interfaces:**
- Consumes: countdown lifecycle and feature capture gates from Task 6.
- Produces: `CountdownHapticDriving.prepare/tick/completion` and an injected deterministic countdown clock/delay.

- [ ] **Step 1: Write the exact haptic-sequence test**

```swift
@Test func countdownEmitsThreeTicksThenCompletion() async {
    let haptics = CountdownHapticSpy()
    let clock = ImmediateCountdownClock()
    let model = CountdownSequence(startNumber: 3, clock: clock, haptics: haptics)
    await model.run()
    #expect(haptics.events == [.prepare, .tick, .tick, .tick, .completion])
}
```

Also test skip finishes once, reduced motion does not change events, and cancellation emits no late completion.

- [ ] **Step 2: Run CraftCountdownOverlay tests and verify failure before the new seams exist**

- [ ] **Step 3: Implement retained production generators**

Create a `@MainActor` production driver that owns one `UIImpactFeedbackGenerator` and one `UINotificationFeedbackGenerator` for the overlay lifetime. Prepare before count 3, use impact for 3/2/1, success for Go, and prepare the impact generator after each non-final tick.

- [ ] **Step 4: Extract deterministic sequence from view rendering**

Move countdown progression into a small `@MainActor` sequence/model injected with clock and haptic driver. `CraftCountdownOverlay` renders its state and uses `.task` cancellation. Preserve current localized strings, tap-to-skip behavior, Reduce Motion behavior, and CraftUIKit tokens.

- [ ] **Step 5: Verify countdown and capture ordering**

Run CraftUIKit countdown tests plus Reflex/Mixed tests proving no capture acquisition occurs before the completion callback.

- [ ] **Step 6: Commit countdown repair**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Countdown/CountdownHapticDriver.swift Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Countdown/CraftCountdownOverlay.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CraftCountdownOverlayTests.swift VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift
git commit -m "fix(craftuikit): make countdown haptics deterministic"
```

---

### Task 8: Measure and Conditionally Narrow Lesson Observation

**Files:**
- Measure: `VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift`
- Measure: `VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift`
- Conditionally create: `VocabCraftApp/Features/Lesson/ViewModels/LessonSpeechPresentation.swift`
- Conditionally modify: `VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift`

**Interfaces:**
- Consumes: stable preparing/listening UI from Task 5.
- Produces only when evidence requires it: a focused `@MainActor @Observable LessonSpeechPresentation` owning `state`, `liveTranscript`, and derived speaking presentation values.

- [ ] **Step 1: Capture a Release real-device baseline for the repaired flow**

Use XcodeBuildMCP device workflow with Release configuration. Capture SwiftUI Update Groups, Time Profiler, and Hangs/Hitches for: countdown → non-speaking step → Speak preparation → listening → feedback → next step. Record longest main-thread hang and update counts for the Lesson container and speaking leaf.

- [ ] **Step 2: Decide against an explicit threshold**

Do not extract state when there is no Lesson-related hang over 250 ms and transcript updates do not repeatedly invalidate the broad container with material body cost. If either condition is present and correlated with transcript mutation, continue to Step 3; otherwise record “no extraction required” in the PR verification note and proceed to Task 9.

- [ ] **Step 3: Write focused observation tests before extraction, only if triggered**

Verify transcript updates mutate `LessonSpeechPresentation` without changing unrelated Lesson progress, feedback, hint, or answer state. Verify the speaking leaf consumes the focused model.

- [ ] **Step 4: Extract the focused presentation model, only if triggered**

```swift
@MainActor
@Observable
final class LessonSpeechPresentation {
    var state: CraftSpeechState = .idle
    var liveTranscript = ""
}
```

The Lesson view model owns one instance and performs orchestration; the speaking leaf observes the focused instance. Do not move navigation, persistence, exercise generation, or answer evaluation into this type.

- [ ] **Step 5: Re-run the identical trace and tests**

Expected: no behavior difference, lower broad-container updates, and no Lesson-related hang over 250 ms. Remove `_printChanges()` and temporary debug signposts.

- [ ] **Step 6: Commit only evidence-backed changes**

If extraction was required:

```bash
git add VocabCraftApp/Features/Lesson/ViewModels/LessonSpeechPresentation.swift VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift
git commit -m "perf(lesson): narrow speech observation updates"
```

If extraction was not required, do not create an empty commit.

---

### Task 9: Full Verification and PR Evidence

**Files:**
- Modify only if required by failures: files already owned by Tasks 1–8.
- Do not commit generated `.xcresult`, DerivedData, trace, user-state, or workspace metadata unless the repository explicitly tracks a designated evidence artifact.

**Interfaces:**
- Consumes: all prior deliverables.
- Produces: zero-warning verification evidence and a concise PR #18 summary.

- [ ] **Step 1: Inspect the worktree before verification**

Run `git status --short` and `git diff --check`. Explain any Xcode-generated or unexpected file before staging it; do not commit it silently.

- [ ] **Step 2: Run CraftUIKit localization tests**

Use XcodeBuildMCP SwiftPM test support for `Packages/CraftUIKit` with `--filter LocalizationTests`.

Expected: pass with complete EN/VI parity.

- [ ] **Step 3: Run full CraftUIKit tests**

Expected: all tests pass with no warnings.

- [ ] **Step 4: Run the full app test suite twice for race confidence**

Use XcodeBuildMCP `test_sim` for workspace `VocabCraft.xcworkspace`, scheme `VocabCraftApp`, on the configured iPhone simulator. The first run proves correctness; the second must reproduce zero failures in lifecycle and cross-flow tests.

- [ ] **Step 5: Run SwiftLint**

Run the repository-configured SwiftLint command. Expected: zero errors and zero warnings.

- [ ] **Step 6: Build the full workspace**

Use XcodeBuildMCP `build_sim` and, when device signing is available, `build_device` with Release configuration. Expected: zero compiler errors and zero warnings.

- [ ] **Step 7: Perform the real-device interaction matrix**

Verify these sequences on a physical device:

```text
Lesson: countdown 3/2/1/Go -> discovery/listening -> Speak -> feedback -> next exercise
Reflex: countdown 3/2/1/Go -> first Speak -> next word -> exit during preparation
Vocabulary: TTS playback -> Speak -> typing fallback after denied permission
Rapid lifecycle: enter Speak -> advance during preparing -> re-enter Speak
Audio route: speaker and available Bluetooth HFP route
```

Expected: every countdown event produces haptic feedback; mic activates only after Go; no stale recording, crackle, frozen waveform, premature timer, or lag in the next exercise.

- [ ] **Step 8: Capture the final Release trace**

Use the identical Task 8 scenario and record CPU, main-thread hangs, SwiftUI update groups, and memory peak. Expected: no Lesson-related main-thread hang over 250 ms.

- [ ] **Step 9: Audit direct scoped AVAudioSession mutations**

Run:

```bash
rg -n "AVAudioSession\.sharedInstance|setCategory\(|setActive\(" VocabCraftApp/Core/Audio
```

Expected: scoped production session mutations exist only inside `AudioSessionCoordinator`; remaining `SpeechRecognitionService` occurrences are explicitly documented as issue #19 scope and confirmed not to participate in the affected concurrent flows.

- [ ] **Step 10: Update PR #18 description or comment with evidence**

Include fixed root causes, test totals, two consecutive race-suite results, localization/lint/build status, device/OS, trace metrics, and link to issue #19. Do not claim the full one-owner migration is complete.

- [ ] **Step 11: Commit any final test-only correction, then inspect status**

```bash
git status --short
git log --oneline origin/main..HEAD
```

Expected: no unexplained generated changes and a readable sequence of independently reviewable commits.
