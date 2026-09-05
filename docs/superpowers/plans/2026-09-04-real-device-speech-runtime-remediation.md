# Real-Device Speech Runtime Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove AVAudioEngine hardware work from the main actor and guarantee that speaking recognition starts only after the engine is ready.

**Architecture:** A dedicated actor owns `AVAudioEngine` and serializes preparation, resume, pause, and teardown. The existing `@MainActor` speech engine coordinates UI-facing state and awaits a single in-flight preparation task before beginning a word.

**Tech Stack:** Swift 5 mode, Swift Concurrency, AVFoundation, Speech, Swift Testing/XCTest, XcodeBuildMCP.

**Spec:** `docs/superpowers/specs/2026-09-04-real-device-lesson-runtime-remediation-design.md`

## Global Constraints

- iOS deployment target remains iOS 17.0.
- Do not change lesson UI, layout, copy, localization, navigation, or progress behavior.
- Do not log transcripts, vocabulary content, or microphone audio.
- All mutable audio-engine state must have one actor owner.
- No `Task.detached` may capture mutable engine state.
- Follow RED-GREEN-REFACTOR for every production behavior change.
- Final gate requires zero compiler warnings, zero SwiftLint warnings, and all tests passing.

---

### Task 1: Define the actor-owned audio engine boundary

**Files:**
- Create: `VocabCraftApp/Core/Audio/SpeechAudioEngineController.swift`
- Create: `VocabCraftAppTests/Features/Reflex/SpeechAudioEngineControllerTests.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `AudioBufferRelay`.
- Produces: `SpeechAudioEngineControlling`, `SpeechAudioEngineController.State`, `prepare(relay:) async throws`, `resume() async throws`, `pause() async`, and `teardown() async`.

- [ ] **Step 1: Write a failing test proving concurrent prepare calls coalesce**

```swift
@Test("Concurrent prepare requests perform one hardware setup")
func concurrentPrepareCoalesces() async throws {
    let hardware = MockSpeechAudioHardware()
    let controller = SpeechAudioEngineController(hardware: hardware)

    async let first: Void = controller.prepare(relay: AudioBufferRelay())
    async let second: Void = controller.prepare(relay: AudioBufferRelay())
    _ = try await (first, second)

    #expect(await hardware.prepareCallCount == 1)
    #expect(await controller.state == .ready)
}
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:VocabCraftAppTests/SpeechAudioEngineControllerTests/concurrentPrepareCoalesces
```

Expected: compilation fails because `SpeechAudioEngineController` does not exist.

- [ ] **Step 3: Add the minimal protocol, state machine, and injected hardware seam**

```swift
protocol SpeechAudioEngineControlling: Sendable {
    func prepare(relay: AudioBufferRelay) async throws
    func resume() async throws
    func pause() async
    func teardown() async
}

actor SpeechAudioEngineController: SpeechAudioEngineControlling {
    enum State: Equatable, Sendable { case idle, preparing, ready, failed }

    private(set) var state: State = .idle
    private var preparationTask: Task<Void, Error>?
    private let hardware: any SpeechAudioHardware

    func prepare(relay: AudioBufferRelay) async throws {
        if state == .ready { return }
        if let preparationTask { return try await preparationTask.value }
        state = .preparing
        let hardware = self.hardware
        let task = Task { try await hardware.prepare(relay: relay) }
        preparationTask = task
        do {
            try await task.value
            state = .ready
            preparationTask = nil
        } catch {
            state = .failed
            preparationTask = nil
            throw error
        }
    }
}
```

The production `SpeechAudioHardware` implementation owns `AVAudioEngine`; it performs `setVoiceProcessingEnabled`, format validation, tap installation, `prepare`, and `start` only inside the actor boundary.

- [ ] **Step 4: Run the focused test and verify GREEN**

Expected: the focused test passes with no warnings.

- [ ] **Step 5: Add failing tests for pause/resume/teardown idempotency, then implement minimally**

```swift
@Test("Repeated teardown releases hardware once")
func teardownIsIdempotent() async {
    let hardware = MockSpeechAudioHardware()
    let controller = SpeechAudioEngineController(hardware: hardware)
    try? await controller.prepare(relay: AudioBufferRelay())
    await controller.teardown()
    await controller.teardown()
    #expect(await hardware.teardownCallCount == 1)
    #expect(await controller.state == .idle)
}
```

- [ ] **Step 6: Run the full controller suite and commit**

```bash
git add VocabCraftApp/Core/Audio/SpeechAudioEngineController.swift VocabCraftAppTests/Features/Reflex/SpeechAudioEngineControllerTests.swift VocabCraftApp.xcodeproj/project.pbxproj
git commit -m "fix: isolate speech audio engine hardware work"
```

### Task 2: Make speech preparation awaitable and ordered

**Files:**
- Modify: `VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift`
- Modify: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift`
- Modify: `VocabCraftApp/Core/Audio/MockResilientReflexSpeechEngine.swift`
- Modify: `VocabCraftAppTests/SpeechServiceTests.swift`

**Interfaces:**
- Consumes: `SpeechAudioEngineControlling` from Task 1.
- Produces: `prepareEngineIfNeeded() async throws` and an engine readiness guarantee before `beginWord`.

- [ ] **Step 1: Write a failing ordering test**

```swift
@Test("Word recognition waits until hardware preparation succeeds")
@MainActor
func wordWaitsForEngineReadiness() async throws {
    let controller = SuspendedSpeechAudioEngineController()
    let engine = ResilientReflexSpeechEngine(audioController: controller)
    engine.startSession(contextualPhrases: [], lazy: true)

    let task = Task { try await engine.prepareEngineIfNeeded() }
    #expect(engine.isEngineReady == false)
    await controller.completePreparation()
    try await task.value
    #expect(engine.isEngineReady)
}
```

- [ ] **Step 2: Run the focused test and verify RED**

Expected: failure because preparation is synchronous and readiness is not exposed internally to tests.

- [ ] **Step 3: Change the protocol and implementation**

```swift
public protocol ReflexSpeechEngineProtocol: AnyObject {
    func prepareEngineIfNeeded() async throws
    func beginWord(targetLemma: String, contextualPhrases: [String])
}

public func prepareEngineIfNeeded() async throws {
    guard isSessionActive, !isListeningPaused else { return }
    try await audioController.prepare(relay: bufferRelay)
    guard isSessionActive, !Task.isCancelled else {
        await audioController.teardown()
        return
    }
    isEngineReady = true
}
```

Remove `audioEngine`, `isStartingEngine`, `startAudioEngine()`, and hardware teardown code from the `@MainActor` type after all callers use the actor.

- [ ] **Step 4: Run SpeechServiceTests and verify GREEN**

- [ ] **Step 5: Add cancellation and prepare-failure tests**

Assert that cancellation never begins a word and that errors preserve domain/code when delivered to `onError`.

- [ ] **Step 6: Run SpeechServiceTests again and commit**

```bash
git add VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift VocabCraftApp/Core/Audio/MockResilientReflexSpeechEngine.swift VocabCraftAppTests/SpeechServiceTests.swift
git commit -m "fix: await speech engine readiness before recognition"
```

### Task 3: Order lesson speaking startup and cancellation

**Files:**
- Modify: `VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift`
- Modify: `VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift`

**Interfaces:**
- Consumes: awaitable preparation from Task 2.
- Produces: one cancellable `speechStartTask` and ordered prepare-then-begin behavior.

- [ ] **Step 1: Write a failing lesson-level ordering test**

```swift
@Test("Speaking begins only after engine preparation completes")
@MainActor
func speakingAwaitsPreparation() async {
    let speech = SuspendedMockReflexSpeechEngine()
    let vm = makeViewModel(speechEngine: speech)
    let item = makeSpeakingItem()

    vm.startListeningForSpeaking(targetLemma: item.word.lemma, item: item)
    #expect(speech.beginWordCallCount == 0)
    speech.completePreparation()
    await Task.yield()
    #expect(speech.beginWordCallCount == 1)
}
```

- [ ] **Step 2: Run and verify RED**

Expected: `beginWordCallCount` is 1 before preparation completes.

- [ ] **Step 3: Implement one cancellable startup task**

```swift
private var speechStartTask: Task<Void, Never>?

public func startListeningForSpeaking(targetLemma: String, item: LessonExerciseItem) {
    guard !isSpeakingDisabledForLesson, !isFeedbackPresented, speechState == .idle else { return }
    speechStartTask?.cancel()
    speechStartTask = Task { @MainActor [weak self] in
        guard let self else { return }
        do {
            try await speechEngine.prepareEngineIfNeeded()
            try Task.checkCancellation()
            guard currentExerciseItem?.id == item.id, !isFeedbackPresented else { return }
            speechEngine.resumeListening()
            speechEngine.beginWord(targetLemma: targetLemma, contextualPhrases: [targetLemma, item.word.exampleEn])
        } catch is CancellationError {
            return
        } catch {
            LessonPerformanceDiagnostics.error("lesson.speaking.prepare", error: error)
            speechState = .idle
        }
    }
}
```

Cancel `speechStartTask` from `stopListeningForSpeaking()` and `cleanup()`.

- [ ] **Step 4: Run and verify GREEN**

- [ ] **Step 5: Add a failing stale-item cancellation test, implement the guard, and rerun**

- [ ] **Step 6: Commit**

```bash
git add VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift
git commit -m "fix: serialize lesson speaking startup"
```

### Task 4: Stop redundant synchronous TTS activation

**Files:**
- Modify: `VocabCraftApp/Core/Audio/TextToSpeechService.swift`
- Modify: `VocabCraftAppTests/SpeechServiceTests.swift`

**Interfaces:**
- Consumes: session-scoped `.playAndRecord` ownership.
- Produces: no `setActive(true)` call when the lesson speech session already owns the audio session.

- [ ] **Step 1: Add a failing test with an injected audio-session facade**

```swift
@Test("TTS reuses active play-and-record session")
@MainActor
func ttsDoesNotReactivateLessonSession() {
    let session = MockAudioSession(category: .playAndRecord, isActive: true)
    let service = TextToSpeechService(audioSession: session)
    service.speak(text: "test")
    #expect(session.setActiveCallCount == 0)
}
```

- [ ] **Step 2: Verify RED, then add `AudioSessionControlling` and minimal conditional activation**

- [ ] **Step 3: Verify GREEN and run all speech tests**

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Core/Audio/TextToSpeechService.swift VocabCraftAppTests/SpeechServiceTests.swift
git commit -m "fix: reuse lesson audio session for tts"
```

### Task 5: Verify speech remediation on simulator and real device

**Files:**
- Modify: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift` only to remove temporary diagnostics after comparison.
- Evidence: `.performance-traces/lesson-speech-after.trace` (keep untracked unless the user requests otherwise).

**Interfaces:**
- Consumes: Tasks 1-4.
- Produces: verified P0 speech remediation.

- [ ] **Step 1: Run focused and full app test suites**
- [ ] **Step 2: Run CraftUIKit localization and full package tests**
- [ ] **Step 3: Run SwiftLint and device Release build with zero warnings**
- [ ] **Step 4: Record Time Profiler + Points of Interest on the same iPhone 16 Pro flow**
- [ ] **Step 5: Compare against the 358.58 ms and 346.02 ms audio stalls; require no `startAudioEngine` main-thread stack**
- [ ] **Step 6: Remove temporary diagnostic logging, rerun all gates, and commit**

```bash
git add VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift
git commit -m "test: verify real-device speech performance"
```

