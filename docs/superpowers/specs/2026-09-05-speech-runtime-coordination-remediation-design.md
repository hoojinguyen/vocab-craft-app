# Speech Runtime Coordination Remediation Design

**Status:** Approved in conversation on 2026-09-05  
**Target:** PR #18  
**Follow-up architecture:** GitHub issue #19  
**Scope:** Repair shared speech lifecycle, countdown haptics, permission fallback, and measured Lesson Speak presentation performance without migrating every SpeechKit audio-session owner in this PR.

## Context

PR #18 moves `AVAudioEngine` work into `SpeechAudioEngineController`, but the migration is incomplete. `ResilientReflexSpeechEngine.prepareEngineIfNeeded()` still mutates `AVAudioSession` from a `@MainActor` type, `stopSession()` changes the same process-global session from an unrelated detached task, and only Lesson awaits engine preparation. Reflex Blitz and Mixed/Vocabulary Practice may call `beginWord()` before the engine is ready.

The current branch also has two deterministic test failures:

- Pause during preparation does not pause hardware after preparation completes.
- Pause while idle does not pause hardware after later preparation completes.

The shared countdown calls haptics for 3, 2, 1, and Go, but speaking flows may activate `.playAndRecord` during the countdown. This explains the observed real-device behavior in which 3 produces feedback while 2, 1, and Go are silent. Lesson also publishes `.listening` before authorization and hardware readiness, causing an immediate mic subtree transition while expensive audio setup is still in flight.

## Goals

- Serialize the `AVAudioSession` lifecycle used by `ResilientReflexSpeechEngine` and `TextToSpeechService`.
- Give Lesson, Reflex Drill, and Vocabulary Practice one atomic async speech-start operation.
- Publish listening UI and start speaking timers only after recognition is genuinely ready.
- Keep Speak auto-start while presenting a stable `.preparing` state.
- Make countdown haptics deterministic and keep microphone activation outside the countdown.
- Convert denied speech or microphone permission into a single session-level typing fallback.
- Preserve a direct migration path to the one-coordinator architecture tracked by issue #19.
- Verify the repair with deterministic lifecycle tests and a Release real-device trace.

## Non-goals

- Do not split the existing Unit Drawer or Homepage changes out of PR #18.
- Do not migrate `SpeechRecognitionService` or `Packages/SpeechKit/SpeechRecognitionEngine` to the new coordinator in this PR unless caller analysis proves either can run concurrently with the affected Lesson, Reflex, or Vocabulary flow.
- Do not redesign the visual language of the speaking card or countdown.
- Do not refactor transcript observation unless measurement proves it contributes materially to the hitch.
- Do not adopt TCA, Clean Architecture layers, or a broad feature rewrite.

## Chosen Approach

Introduce a dedicated app-core `AudioSessionCoordinator` actor rather than expanding `SpeechAudioEngineController` or adding feature-specific coordinators.

The coordinator owns category, mode, activation, route, haptics-during-recording policy, and generation-safe release for the scoped production consumers. `SpeechAudioEngineController` continues to own only `AVAudioEngine`, its input tap, preparation, pause, resume, and teardown. `ResilientReflexSpeechEngine` orchestrates capture but no longer mutates `AVAudioSession` directly. `TextToSpeechService` requests playback through the same coordinator rather than performing independent session changes.

This is intentionally the narrow migration. The abstractions and dependency direction must remain suitable for issue #19, where all remaining app and package audio-session owners will migrate to one production coordinator.

## Architecture

### Audio-session intents and leases

The app-core boundary exposes explicit intent instead of raw category switching:

```swift
enum AudioSessionIntent: Sendable {
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

`AppContainer` constructs one production coordinator and injects the same instance into `ResilientReflexSpeechEngine` and `TextToSpeechService`. Tests inject a deterministic mock.

The production actor applies these rules:

- A capture or duplex lease requires `.playAndRecord`, speaker routing, Bluetooth HFP support, and haptics/system sounds during recording.
- TTS reuses an active duplex session and must not downgrade it to `.playback`.
- Playback may use `.playback` only when no active capture or duplex lease exists.
- Release is idempotent.
- A lease contains a generation, so a stale release or teardown cannot deactivate a newer session.
- No detached task may mutate the session outside the coordinator.

### Hardware engine boundary

`SpeechAudioEngineController` remains an actor with explicit states:

```text
idle -> preparing -> ready <-> paused
          |           |
          +---------> failed
any active state ----> idle through teardown
```

A pause requested while idle or preparing is retained as intent. If preparation completes while pause is still requested, hardware is paused before the operation reports completion. Resume during preparation clears the pending pause. Concurrent prepare calls share one in-flight operation. Teardown cancels and joins preparation, removes the tap exactly once, and resets state.

### Speech capture boundary

Replace the caller-visible `prepareEngineIfNeeded()` plus synchronous `beginWord()` sequence with one async operation:

```swift
func startListening(
    targetLemma: String,
    contextualPhrases: [String]
) async throws
```

The operation:

1. Validates the session and word generation.
2. Requests speech and microphone authorization without activating audio prematurely.
3. Acquires a duplex speech lease.
4. Awaits audio-engine preparation.
5. Revalidates cancellation, session generation, and target word.
6. Opens the recognition request and attaches the relay.
7. Returns only after capture is ready to accept audio.

On cancellation or failure it invalidates the pending word, cleans up any request, tears down or pauses hardware according to session policy, and releases the lease it acquired. Errors are never swallowed with `try?` at the feature boundary.

`beginWord()` becomes private or gains a readiness precondition that no production caller can bypass. Lesson, Reflex, and Vocabulary Practice use the same async entry point.

## Feature State and Data Flow

Speaking presentation uses these explicit states:

```text
idle -> preparing -> listening -> processing -> evaluated
             |             |
             +-----------> unavailable
```

When a Speak exercise appears, the feature owner creates a task associated with the exercise identifier and generation, then publishes `.preparing`. The mic/card retains stable identity and geometry. Only the status glyph and localized copy change. The feature awaits `startListening`; after it succeeds and the exercise identifier still matches, it publishes `.listening`, triggers the listening haptic, and starts the speaking timer.

When the user advances, skips, dismisses, or changes mode, the feature cancels the start task before invalidating the word generation. Cleanup finishes through the speech boundary. A late completion from an older generation cannot publish state or affect the new exercise.

Reflex Blitz and Vocabulary Practice must not begin word timers or present listening state until the same async start operation succeeds.

## Stable Speak Presentation

Add `.preparing` to the shared speech presentation state. `CraftTactileMicHubView` and its containing speaking card preserve the same frame in idle, preparing, and listening states. The action region also keeps a stable slot; visibility and enabled state may change without inserting or removing a root layout branch.

During preparation:

- Do not publish fake audio levels.
- Show a token-based progress treatment and localized preparing copy.
- Do not run the listening pulse, waveform, speaking timer, or listening haptic.
- Keep cancel/skip behavior available according to the existing feature policy.

Animations are scoped to status, icon, and waveform changes. No implicit animation is applied to the full Lesson container.

## Countdown and Haptics

Countdown is independent of speech capture. Permission preflight may occur before or during countdown, but `.playAndRecord` activation and `AVAudioEngine` preparation begin only after the countdown `onFinish` callback.

Introduce an injectable haptic driver:

```swift
protocol CountdownHapticDriving {
    func prepare()
    func tick()
    func completion()
}
```

The production implementation retains its feedback generators for the countdown lifetime. It prepares before the first event, emits `tick()` at 3, 2, and 1, emits `completion()` at Go, and prepares the next generator after each non-final event. Tests use a spy plus injected clock to assert the exact event sequence without real sleeps.

The audio coordinator also enables haptics/system sounds during recording as an explicit safety policy for feedback that legitimately occurs while capture is active. Countdown correctness must not depend on this policy because capture is not active during countdown.

## Permission Failure and Fallback

Core code emits typed errors without user-facing literal strings:

```swift
enum SpeechCaptureError: Error, Sendable {
    case speechPermissionDenied
    case microphonePermissionDenied
    case audioSessionActivationFailed
    case enginePreparationFailed
    case recognizerUnavailable
}
```

When speech or microphone permission is denied:

- The current feature publishes `.unavailable`.
- Speak is disabled for the remainder of that Lesson, Reflex, or Vocabulary session.
- Remaining speaking items use the existing typing fallback path.
- The app presents one localized explanation with an action to open Settings.
- The same session does not repeatedly request permission or retry audio activation automatically.

All display and accessibility copy lives in the correct `Localizable.xcstrings` catalog with complete English and Vietnamese translations, manual extraction state, translated state, and matching format specifiers.

## Error Handling

Authorization, coordinator activation, engine preparation, recognizer availability, cancellation, and stale generation are distinct outcomes. Cancellation and stale work are silent cleanup paths. Permission denial produces the session fallback. Recoverable engine or audio-session failure returns the speaking presentation to an actionable state without advancing the exercise. Diagnostics log stable operation names and error codes but no localized presentation strings.

## Performance Strategy

The mandatory fixes remove synchronous audio-session mutation from the presentation actor, avoid microphone activation during countdown, and prevent premature broad UI changes.

Transcript invalidation remains measurement-gated. Add temporary debug-only `_printChanges()` or equivalent signposts to the speaking leaf and Lesson container, then capture SwiftUI Update Groups and Time Profiler in a Release build on a real device. Split transcript and speech presentation into a focused observable model only if the capture shows repeated material reevaluation of the broad Lesson subtree. Remove temporary instrumentation after the decision.

The completed implementation must produce a Release real-device trace with no lesson-related main-thread hang over 250 ms.

## Test Strategy

### Characterization and coordinator tests

- Preserve the two currently failing pause-during-preparation cases and make them pass through the corrected state machine.
- Verify capture, playback, and duplex lease behavior.
- Verify TTS cannot downgrade an active duplex session.
- Verify rapid stop then restart and stale-generation release.
- Verify idempotent release and activation-failure recovery.

### Speech engine tests

- Recognition cannot begin before coordinator and engine readiness.
- Concurrent start requests coalesce or cancel according to word generation.
- Cancellation during authorization, session activation, or engine preparation releases owned resources.
- Pause, resume, stop, and teardown preserve ordering.
- No background preparation error is swallowed.

### Feature tests

- Lesson transitions from preparing to listening only after readiness.
- Advance, skip, and disappear during preparation cannot update the next exercise.
- Reflex and Vocabulary timers begin only after listening succeeds.
- Permission denial shows one notice, disables Speak for the session, and converts remaining speaking work to typing.
- TTS to Speak and Speak to feedback TTS to the next Speak exercise preserve a valid audio session.

### Countdown tests

- Injected haptic spy observes exactly three tick events and one completion event.
- Skip finishes once and emits only its defined final feedback.
- Speech capture is not acquired before countdown completion.
- Reduced-motion behavior does not change haptic sequencing.

### Quality gates

- Run affected focused tests during every task.
- Run `swift test --filter LocalizationTests` and full CraftUIKit tests.
- Run the full app test suite.
- Run SwiftLint with zero warnings.
- Build the Xcode workspace with zero compiler warnings.
- Capture and compare a Release real-device trace for the exact Lesson Speak sequence.

## Rollout Order

1. Add characterization tests for the existing lifecycle and cross-flow races.
2. Add the coordinator, lease policy, and dependency injection.
3. Correct the hardware controller state machine.
4. Add the atomic async speech-start boundary.
5. Migrate Lesson and stabilize preparing/listening presentation.
6. Migrate Reflex Drill and Vocabulary Practice to the same readiness boundary.
7. Isolate countdown from capture and add the injectable haptic driver.
8. Add typed permission fallback and bilingual localization.
9. Measure SwiftUI invalidation and perform the conditional transcript extraction only if evidence requires it.
10. Run the complete quality gates and real-device verification.

Each step must be independently testable and committed separately. A failure in a later feature migration must not weaken coordinator or lifecycle invariants established earlier.

## Acceptance Criteria

- The two existing pause-during-preparation tests pass deterministically.
- `ResilientReflexSpeechEngine` and `TextToSpeechService` share one injected coordinator instance in production.
- Neither scoped service directly or from a detached task mutates `AVAudioSession`.
- No Lesson, Reflex, or Vocabulary production caller can begin a word before readiness.
- Speaking UI follows `idle -> preparing -> listening` without layout identity churn.
- Speaking timers and listening haptics start only after capture readiness.
- Countdown does not activate the microphone and emits haptics for 3, 2, 1, and Go.
- Advancing or exiting during preparation cannot affect the next exercise.
- Denied permission produces one localized notice and session-level typing fallback.
- TTS and speech capture transitions do not leave stale playback or recording configuration.
- Any transcript-state extraction is backed by before/after trace evidence.
- Full tests, localization tests, SwiftLint, and Xcode build complete with zero warnings.
- A Release real-device trace contains no lesson-related main-thread hang over 250 ms.

## Future Migration

GitHub issue #19 tracks the final architecture: a package-safe coordination abstraction and exactly one production `AVAudioSession` owner for all app and SpeechKit consumers. The types introduced here must be reusable or incrementally adaptable for that migration; PR #18 must not create another feature-local coordinator or a dependency from SpeechKit to the app target.
