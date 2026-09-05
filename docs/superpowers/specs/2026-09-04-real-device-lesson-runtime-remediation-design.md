# Real-Device Lesson Runtime Remediation Design

**Status:** Approved in conversation on 2026-09-04  
**Baseline artifact:** `.performance-traces/lesson-time-profiler.trace`  
**Device:** iPhone 16 Pro, iOS 26.6.1  
**Scope:** Runtime performance and speech reliability only. Continue-button placement, homepage auto-scroll/focus, and other UX/layout changes are explicitly excluded.

## Problem statement

The prior lesson-performance work reduced background journey cost and audio-session churn, but a 322.8-second real-device Time Profiler capture still recorded six main-thread stalls: 358.58 ms, 358.71 ms, 346.02 ms, 686.99 ms, 255.07 ms, and 666.65 ms.

Two stalls resolve directly to `ResilientReflexSpeechEngine.startAudioEngine()`. The method remains isolated to `@MainActor` and synchronously performs voice-processing activation, audio-unit graph construction, tap installation, `prepare()`, and `start()`. Speaking presentation also calls `prepareEngineIfNeeded()`, `resumeListening()`, and `beginWord(...)` without awaiting engine readiness.

The remaining high-cost intervals are dominated by SwiftUI/AttributeGraph work. The strongest app frames are `CraftSparkleView.drawParticles`, `LessonLearningViewModel.withMutation`, and `AppContainer.mock`. `EnvironmentValues.appContainer` uses a computed mock fallback, so SwiftUI can construct a full dependency graph while evaluating an uninjected environment.

## Architecture

### Audio boundary

Introduce a dedicated `SpeechAudioEngineController` actor that exclusively owns `AVAudioEngine` and all hardware-facing setup, pause, resume, and teardown. `ResilientReflexSpeechEngine` remains the `@MainActor` presentation-facing state owner, but it must await the controller before opening a recognition request.

Represent engine startup explicitly as `idle`, `preparing`, `ready`, or `failed`. Concurrent preparation callers share one in-flight task. Cancellation or lesson exit must invalidate the pending word and tear down the actor-owned graph exactly once.

Do not change the lesson UI. Do not activate the microphone during discovery, typing, listening, or multiple-choice steps. TTS must reuse an already-active `.playAndRecord` session without synchronously reactivating it for every utterance.

### Render/state boundary

Keep `AppContainer.mock` as a fresh factory for tests, but introduce one stable environment fallback instance so view evaluation cannot repeatedly allocate repositories and stores.

Move draft typing input into leaf-owned `@State` inside the typing exercise adapter. The lesson view model receives the final answer only on submit. This prevents every keystroke from mutating the broad lesson observation graph.

`CraftSparkleView` retains its design but precomputes invariant particle values and guarantees its timeline is removed immediately after the one-second effect finishes.

## Acceptance criteria

- `AVAudioEngine` hardware setup has no `@MainActor` call stack.
- A speaking word cannot begin recognition before engine state is `ready`.
- Concurrent prepare calls create one hardware setup operation.
- Lesson exit cancels pending speech start and tears down once.
- Environment fallback returns the same container identity on repeated reads.
- Typing keystrokes do not mutate `LessonLearningViewModel.typingText`; submit commits one value.
- A Release build, real-device trace contains no lesson-related main-thread hang over 250 ms.
- All app tests, CraftUIKit tests, localization tests, SwiftLint, and Xcode build complete with zero warnings.

