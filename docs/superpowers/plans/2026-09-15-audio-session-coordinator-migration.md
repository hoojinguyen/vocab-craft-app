# Centralized Audio Session Coordination Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Centralize 100% of speech recognition and text-to-speech audio-session management behind one production coordinator actor (`AudioSessionCoordinator`), eliminating fragmented mutations to `AVAudioSession.sharedInstance()`, resolving race conditions with dynamic intent escalation, and serializing system events (interruptions, route changes, media resets) through a package-safe protocol in `SpeechKit`.

**Architecture:** Define `AudioSessionCoordinating`, `AudioSessionIntent`, `AudioSessionLease`, and `AudioSessionEvent` in `Packages/SpeechKit` to maintain inversion of control. Implement the concrete actor `AudioSessionCoordinator` in `VocabCraftApp` as the sole mutator of `AVAudioSession` via `AudioSessionHardware`. Migrate `SpeechRecognitionEngine`, `SpeechRecognitionService`, `TextToSpeechService`, `ResilientReflexSpeechEngine`, and `LiveSpeechAuthorizer` to acquire/release typed leases and subscribe to coordinator events. Compose all dependencies through `AppContainer`.

**Tech Stack:** Swift 5.10 / Swift 6, AVFoundation, Speech, AsyncStream, Swift Testing / XCTest.

**Spec:** [docs/superpowers/specs/2026-09-14-audio-session-coordinator-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-09-14-audio-session-coordinator-design.md)

## Global Constraints

- Exactly one production owner mutates `AVAudioSession` (`LiveAudioSessionHardware` in `VocabCraftApp`).
- No direct calls to `AVAudioSession.sharedInstance().setCategory`, `.setActive`, `.overrideOutputAudioPort`, or `.requestRecordPermission` anywhere else in app or packages.
- `Packages/SpeechKit` must not import or depend on `VocabCraftApp`.
- Minimum iOS deployment target is iOS 17.0; use `AVAudioApplication.requestRecordPermission` for microphone authorization.
- Zero compiler warnings, zero SwiftLint violations, 100% test pass rate across `SpeechKit`, `CraftUIKit`, and `VocabCraftAppTests`.

---

### Task 1: Declare AudioSession Coordination Protocols & Models in `Packages/SpeechKit`

**Files:**
- Create: `Packages/SpeechKit/Sources/SpeechKit/Protocols/AudioSessionCoordinating.swift`
- Create: `Packages/SpeechKit/Sources/SpeechKit/Engine/NoOpAudioSessionCoordinator.swift`
- Create: `Packages/SpeechKit/Tests/SpeechKitTests/AudioSessionCoordinatingTests.swift`

**Interfaces:**
- Produces:
  - `enum AudioSessionIntent: Hashable, Sendable` (`.playback`, `.speechCapture`, `.duplexSpeech`)
  - `struct AudioSessionLease: Hashable, Sendable` (`id: UUID`, `generation: UInt`, `intent: AudioSessionIntent`)
  - `enum AudioSessionEvent: Sendable, Equatable` (`.interruptionBegan`, `.interruptionEnded(shouldResume: Bool)`, `.routeChanged(reason: RouteChangeReason)`, `.mediaServicesReset`)
  - `enum RouteChangeReason: Sendable, Equatable` (`.newDeviceAvailable`, `.oldDeviceUnavailable`, `.categoryChange`, `.other`)
  - `protocol AudioSessionCoordinating: AnyObject, Sendable` (`acquire(_:) async throws -> AudioSessionLease`, `release(_:) async`, `var events: AsyncStream<AudioSessionEvent> { get }`)
  - `final class NoOpAudioSessionCoordinator: AudioSessionCoordinating`

- [ ] **Step 1: Write the failing test for AudioSessionCoordinating models and NoOpAudioSessionCoordinator**

Create `Packages/SpeechKit/Tests/SpeechKitTests/AudioSessionCoordinatingTests.swift`:
```swift
import Foundation
import XCTest
@testable import SpeechKit

final class AudioSessionCoordinatingTests: XCTestCase {
    func testLeaseInitializationAndEquality() {
        let id = UUID()
        let lease1 = AudioSessionLease(id: id, generation: 1, intent: .speechCapture)
        let lease2 = AudioSessionLease(id: id, generation: 1, intent: .speechCapture)
        let lease3 = AudioSessionLease(id: id, generation: 2, intent: .speechCapture)

        XCTAssertEqual(lease1, lease2)
        XCTAssertNotEqual(lease1, lease3)
        XCTAssertEqual(lease1.intent, .speechCapture)
        XCTAssertEqual(lease1.generation, 1)
    }

    func testNoOpAudioSessionCoordinatorAcquireAndRelease() async throws {
        let coordinator = NoOpAudioSessionCoordinator()
        let lease = try await coordinator.acquire(.playback)

        XCTAssertEqual(lease.intent, .playback)
        XCTAssertEqual(lease.generation, 1)

        await coordinator.release(lease)
    }

    func testNoOpAudioSessionCoordinatorEventsStream() async {
        let coordinator = NoOpAudioSessionCoordinator()
        var iterator = coordinator.events.makeAsyncIterator()
        // Ensure stream is valid and can yield without hanging
        let event = await iterator.next()
        XCTAssertNil(event)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/SpeechKit --filter AudioSessionCoordinatingTests`
Expected: Compilation failure due to missing types (`AudioSessionCoordinating`, `AudioSessionLease`, `NoOpAudioSessionCoordinator`).

- [ ] **Step 3: Implement AudioSessionCoordinating protocol, models, and NoOpAudioSessionCoordinator**

Create `Packages/SpeechKit/Sources/SpeechKit/Protocols/AudioSessionCoordinating.swift`:
```swift
import Foundation

/// Explicit audio session intent declared by consumers.
public enum AudioSessionIntent: Hashable, Sendable {
    /// Playback-only audio (e.g. Text-to-Speech pronunciation, audio cues).
    case playback
    /// Recording-only speech capture (e.g. speech-to-text assessment).
    case speechCapture
    /// Simultaneous input and output (e.g. interactive reflex drill with live voice & audio prompts).
    case duplexSpeech
}

/// Token representing an active lease on the coordinated audio session.
public struct AudioSessionLease: Hashable, Sendable {
    public let id: UUID
    public let generation: UInt
    public let intent: AudioSessionIntent

    public init(id: UUID = UUID(), generation: UInt, intent: AudioSessionIntent) {
        self.id = id
        self.generation = generation
        self.intent = intent
    }
}

/// Normalized system audio events broadcast by the coordinator.
public enum AudioSessionEvent: Sendable, Equatable {
    case interruptionBegan
    case interruptionEnded(shouldResume: Bool)
    case routeChanged(reason: RouteChangeReason)
    case mediaServicesReset

    public enum RouteChangeReason: Sendable, Equatable {
        case newDeviceAvailable
        case oldDeviceUnavailable
        case categoryChange
        case other
    }
}

/// Primary coordinator abstraction for managing shared audio session leases and events.
public protocol AudioSessionCoordinating: AnyObject, Sendable {
    /// Acquire an audio session lease for the given intent.
    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease

    /// Release an active lease.
    func release(_ lease: AudioSessionLease) async

    /// Asynchronous stream of audio session events.
    var events: AsyncStream<AudioSessionEvent> { get }
}
```

Create `Packages/SpeechKit/Sources/SpeechKit/Engine/NoOpAudioSessionCoordinator.swift`:
```swift
import Foundation

/// Standalone fallback coordinator that performs no audio session hardware mutations.
/// Suitable for previews, simulators, and unit testing environments.
public final class NoOpAudioSessionCoordinator: AudioSessionCoordinating, @unchecked Sendable {
    private var generation: UInt = 0
    private let lock = NSLock()

    public init() {}

    public func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        lock.lock()
        defer { lock.unlock() }
        generation += 1
        return AudioSessionLease(id: UUID(), generation: generation, intent: intent)
    }

    public func release(_ lease: AudioSessionLease) async {}

    public var events: AsyncStream<AudioSessionEvent> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/SpeechKit --filter AudioSessionCoordinatingTests`
Expected: PASS (All tests executed with 0 failures).

- [ ] **Step 5: Commit**

```bash
git add Packages/SpeechKit/Sources/SpeechKit/Protocols/AudioSessionCoordinating.swift \
        Packages/SpeechKit/Sources/SpeechKit/Engine/NoOpAudioSessionCoordinator.swift \
        Packages/SpeechKit/Tests/SpeechKitTests/AudioSessionCoordinatingTests.swift
git commit -m "feat(speechkit): define AudioSessionCoordinating abstraction and NoOp coordinator"
```

---

### Task 2: Migrate `SpeechRecognitionEngine` in `Packages/SpeechKit`

**Files:**
- Modify: `Packages/SpeechKit/Sources/SpeechKit/Engine/SpeechRecognitionEngine.swift`
- Modify: `Packages/SpeechKit/Tests/SpeechKitTests/SpeechAssessmentServiceTests.swift`

**Interfaces:**
- Consumes: `AudioSessionCoordinating`, `AudioSessionLease`, `AudioSessionIntent` from Task 1.
- Produces: Updated `SpeechRecognitionEngine` initializer taking optional `(any AudioSessionCoordinating)?`.

- [ ] **Step 1: Write the failing test for SpeechRecognitionEngine coordinator integration**

In `Packages/SpeechKit/Tests/SpeechKitTests/SpeechAssessmentServiceTests.swift` (or a dedicated test):
```swift
final class MockTrackingAudioCoordinator: AudioSessionCoordinating, @unchecked Sendable {
    private let lock = NSLock()
    var acquiredIntents: [AudioSessionIntent] = []
    var releasedLeases: [AudioSessionLease] = []

    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        lock.lock()
        defer { lock.unlock() }
        acquiredIntents.append(intent)
        return AudioSessionLease(id: UUID(), generation: 1, intent: intent)
    }

    func release(_ lease: AudioSessionLease) async {
        lock.lock()
        defer { lock.unlock() }
        releasedLeases.append(lease)
    }

    var events: AsyncStream<AudioSessionEvent> {
        AsyncStream { $0.finish() }
    }
}
```
Add test method:
```swift
func testSpeechRecognitionEngine_acquiresAndReleasesLeaseThroughCoordinator() throws {
    let mockCoordinator = MockTrackingAudioCoordinator()
    let engine = SpeechRecognitionEngine(audioCoordinator: mockCoordinator)

    try engine.start(
        contextualPhrases: ["test"],
        onPartialResult: { _ in },
        onFinalResult: { _ in },
        onError: { _ in }
    )

    XCTAssertTrue(engine.isRecording)
    XCTAssertEqual(mockCoordinator.acquiredIntents, [.speechCapture])

    engine.stop()
    XCTAssertFalse(engine.isRecording)
    // Release is scheduled asynchronously on stop
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/SpeechKit --filter SpeechAssessmentServiceTests`
Expected: Compilation failure due to missing `audioCoordinator` parameter in `SpeechRecognitionEngine.init`.

- [ ] **Step 3: Update `SpeechRecognitionEngine` implementation**

In `Packages/SpeechKit/Sources/SpeechKit/Engine/SpeechRecognitionEngine.swift`:
1. Add property `private let audioCoordinator: (any AudioSessionCoordinating)?`.
2. Update initializer:
```swift
public init(
    locale: Locale = Locale(identifier: "en-US"),
    audioCoordinator: (any AudioSessionCoordinating)? = nil
) {
    self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    self.audioCoordinator = audioCoordinator
    super.init()
}
```
3. Update `requestAuthorization`:
```swift
#elseif os(iOS)
AVAudioApplication.requestRecordPermission { micGranted in
    guard micGranted else {
        completion(false)
        return
    }
    SFSpeechRecognizer.requestAuthorization { authStatus in
        completion(authStatus == .authorized)
    }
}
#else
```
(Removes `#available(iOS 17.0, *)` branch and old `AVAudioSession.sharedInstance().requestRecordPermission`).
4. In `start(...)`:
Acquire lease before audio buffer setup:
```swift
if let coordinator = audioCoordinator {
    Task {
        _ = try? await coordinator.acquire(.speechCapture)
    }
}
```
Or manage `activeLease: AudioSessionLease?` with synchronization.
5. In `stopInternal()`:
Release `activeLease`:
```swift
if let lease = activeLease, let coordinator = audioCoordinator {
    activeLease = nil
    Task {
        await coordinator.release(lease)
    }
}
```
6. Remove `configureAudioSession()` and all references to `AVAudioSession.sharedInstance()` in `startDeviceRecognition()` and `stopInternal()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/SpeechKit`
Expected: PASS (All tests in SpeechKit package pass).

- [ ] **Step 5: Commit**

```bash
git add Packages/SpeechKit/Sources/SpeechKit/Engine/SpeechRecognitionEngine.swift \
        Packages/SpeechKit/Tests/SpeechKitTests/SpeechAssessmentServiceTests.swift
git commit -m "refactor(speechkit): inject AudioSessionCoordinating into SpeechRecognitionEngine and eliminate direct AVAudioSession mutations"
```

---

### Task 3: Upgrade `AudioSessionCoordinator` Actor in `VocabCraftApp`

**Files:**
- Modify: `VocabCraftApp/Core/Audio/AudioSessionCoordinator.swift`
- Modify: `VocabCraftAppTests/Core/Audio/AudioSessionCoordinatorTests.swift`

**Interfaces:**
- Consumes: `AudioSessionCoordinating`, `AudioSessionIntent`, `AudioSessionLease`, `AudioSessionEvent` from `SpeechKit`.
- Produces: `AudioSessionCoordinator` actor conforming to `SpeechKit.AudioSessionCoordinating`, exposing `events: AsyncStream<AudioSessionEvent>`, implementing dynamic intent escalation and system notification observing.

- [ ] **Step 1: Write failing tests for Dynamic Escalation and System Events in `AudioSessionCoordinatorTests`**

In `VocabCraftAppTests/Core/Audio/AudioSessionCoordinatorTests.swift`:
```swift
@Test("Dynamic escalation: Concurrent speechCapture and playback leases escalate effective intent to duplexSpeech")
func concurrentCaptureAndPlaybackEscalatesToDuplex() async throws {
    let mock = MockAudioSessionHardware()
    let coordinator = AudioSessionCoordinator(hardware: mock)

    let captureLease = try await coordinator.acquire(.speechCapture)
    #expect(await coordinator.effectiveIntent == .speechCapture)

    let playbackLease = try await coordinator.acquire(.playback)
    #expect(await coordinator.effectiveIntent == .duplexSpeech)
    #expect(await coordinator.activeLeaseCount == 2)

    // Releasing playback restores speechCapture
    await coordinator.release(playbackLease)
    #expect(await coordinator.effectiveIntent == .speechCapture)

    await coordinator.release(captureLease)
    #expect(await coordinator.effectiveIntent == nil)
    #expect(mock.operations.last == .setActive(false, options: [.notifyOthersOnDeactivation]))
}

@Test("Media services reset invalidates all active leases and emits reset event")
func mediaServicesResetClearsLeasesAndBroadcastsEvent() async throws {
    let mock = MockAudioSessionHardware()
    let coordinator = AudioSessionCoordinator(hardware: mock)

    let lease = try await coordinator.acquire(.speechCapture)
    #expect(await coordinator.activeLeaseCount == 1)

    // Trigger media services reset
    await coordinator.handleMediaServicesReset()

    #expect(await coordinator.activeLeaseCount == 0)
    #expect(await coordinator.effectiveIntent == nil)
    #expect(await coordinator.currentGeneration > lease.generation)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftAppTests -destination "id=3CD37798-B3F2-4B42-8842-F076AC54DCFF" -only-testing:VocabCraftAppTests/AudioSessionCoordinatorTests`
Expected: FAIL (Dynamic escalation and `handleMediaServicesReset` not yet implemented).

- [ ] **Step 3: Implement Dynamic Escalation, Event Stream, and System Notification Observers in `AudioSessionCoordinator`**

In `VocabCraftApp/Core/Audio/AudioSessionCoordinator.swift`:
1. `import SpeechKit`.
2. Remove duplicate definitions of `AudioSessionIntent`, `AudioSessionLease`, and `AudioSessionCoordinating` (re-export or rely on `SpeechKit`).
3. Update `deriveEffectiveIntent`:
```swift
private func deriveEffectiveIntent(from leases: [UUID: AudioSessionLease]) -> AudioSessionIntent? {
    if leases.isEmpty { return nil }

    let hasDuplex = leases.values.contains { $0.intent == .duplexSpeech }
    let hasCapture = leases.values.contains { $0.intent == .speechCapture }
    let hasPlayback = leases.values.contains { $0.intent == .playback }

    if hasDuplex || (hasCapture && hasPlayback) {
        return .duplexSpeech
    } else if hasCapture {
        return .speechCapture
    } else {
        return .playback
    }
}
```
4. Implement event broadcasting:
```swift
private var eventContinuations: [UUID: AsyncStream<AudioSessionEvent>.Continuation] = [:]

public var events: AsyncStream<AudioSessionEvent> {
    AsyncStream { continuation in
        let id = UUID()
        self.registerContinuation(continuation, for: id)
        continuation.onTermination = { [weak self] _ in
            Task { [weak self] in
                await self?.unregisterContinuation(for: id)
            }
        }
    }
}

private func broadcast(_ event: AudioSessionEvent) {
    for continuation in eventContinuations.values {
        continuation.yield(event)
    }
}
```
5. Centralize system observers on iOS:
- `AVAudioSession.interruptionNotification`
- `AVAudioSession.routeChangeNotification`
- `AVAudioSession.mediaServicesWereResetNotification`

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftAppTests -destination "id=3CD37798-B3F2-4B42-8842-F076AC54DCFF" -only-testing:VocabCraftAppTests/AudioSessionCoordinatorTests`
Expected: PASS (All tests in AudioSessionCoordinatorTests pass).

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/AudioSessionCoordinator.swift \
        VocabCraftAppTests/Core/Audio/AudioSessionCoordinatorTests.swift
git commit -m "feat(audio): implement dynamic intent escalation and system event broadcasting in AudioSessionCoordinator"
```

---

### Task 4: Migrate `SpeechRecognitionService` & `LiveSpeechAuthorizer` in `VocabCraftApp`

**Files:**
- Modify: `VocabCraftApp/Core/Audio/SpeechRecognitionService.swift`
- Modify: `VocabCraftApp/Core/Audio/SpeechCaptureError.swift`
- Modify: `VocabCraftAppTests/SpeechServiceTests.swift`

**Interfaces:**
- Consumes: `AudioSessionCoordinating`, `AudioSessionLease`, `AudioSessionIntent` from Task 3.
- Produces: Cleaned `SpeechRecognitionService` and `LiveSpeechAuthorizer` with zero direct `AVAudioSession.sharedInstance()` mutations.

- [ ] **Step 1: Write failing tests in `SpeechServiceTests` for `SpeechRecognitionService` with coordinator**

In `VocabCraftAppTests/SpeechServiceTests.swift`:
```swift
func testSTTService_acquiresAndReleasesLeaseThroughCoordinator() async throws {
    let mockHardware = MockAudioSessionHardware()
    let coordinator = AudioSessionCoordinator(hardware: mockHardware)
    let stt = SpeechRecognitionService(audioSessionCoordinator: coordinator)

    try stt.startListening()
    #expect(stt.isRecording)
    #expect(await coordinator.activeLeaseCount == 1)
    #expect(await coordinator.effectiveIntent == .speechCapture)

    stt.stopListening()
    #expect(!stt.isRecording)
    #expect(await coordinator.activeLeaseCount == 0)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftAppTests -destination "id=3CD37798-B3F2-4B42-8842-F076AC54DCFF" -only-testing:VocabCraftAppTests/SpeechServiceTests`
Expected: Compilation failure (initializer does not accept `audioSessionCoordinator`).

- [ ] **Step 3: Migrate `SpeechRecognitionService` and `LiveSpeechAuthorizer`**

In `VocabCraftApp/Core/Audio/SpeechRecognitionService.swift`:
1. Add `public let audioSessionCoordinator: any AudioSessionCoordinating`.
2. Update initializer:
```swift
public init(locale: String = "en-US", audioSessionCoordinator: any AudioSessionCoordinating = AudioSessionCoordinator()) {
    self.audioSessionCoordinator = audioSessionCoordinator
    ...
}
```
3. In `startListening()`:
Replace direct `AVAudioSession` mutation:
```swift
Task { @MainActor [weak self] in
    guard let self else { return }
    do {
        self.activeLease = try await self.audioSessionCoordinator.acquire(.speechCapture)
    } catch {
        self.stopListening()
        self.onErrorCallback?(error)
    }
}
```
4. In `stopListening()`:
Replace direct `AVAudioSession` deactivation:
```swift
if let lease = activeLease {
    activeLease = nil
    Task { [coordinator = audioSessionCoordinator] in
        await coordinator.release(lease)
    }
}
```
5. Remove `setupInterruptionObserver()` and direct `AVAudioSession.interruptionNotification` observer. Subscribe to `audioSessionCoordinator.events`.
6. In `LiveSpeechAuthorizer` (`SpeechCaptureError.swift`):
Replace fallback with `AVAudioApplication.requestRecordPermission()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftAppTests -destination "id=3CD37798-B3F2-4B42-8842-F076AC54DCFF" -only-testing:VocabCraftAppTests/SpeechServiceTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/SpeechRecognitionService.swift \
        VocabCraftApp/Core/Audio/SpeechCaptureError.swift \
        VocabCraftAppTests/SpeechServiceTests.swift
git commit -m "refactor(speech): migrate SpeechRecognitionService and authorizer to AudioSessionCoordinator"
```

---

### Task 5: Migrate `TextToSpeechService` & `ResilientReflexSpeechEngine` to Centralized Events

**Files:**
- Modify: `VocabCraftApp/Core/Audio/TextToSpeechService.swift`
- Modify: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift`
- Modify: `VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift`
- Modify: `VocabCraftAppTests/SpeechServiceTests.swift`

**Interfaces:**
- Consumes: `AudioSessionCoordinator.events: AsyncStream<AudioSessionEvent>` from Task 3.
- Produces: Fully event-driven TTS and Reflex speech engines without direct `NotificationCenter` observers.

- [ ] **Step 1: Write failing tests for event stream interruption handling**

In `VocabCraftAppTests/SpeechServiceTests.swift`:
```swift
@Test("TextToSpeechService stops speaking on coordinator interruptionBegan event")
@MainActor
func ttsStopsOnInterruptionEvent() async throws {
    let mockHardware = MockAudioSessionHardware()
    let coordinator = AudioSessionCoordinator(hardware: mockHardware)
    let tts = TextToSpeechService(audioSessionCoordinator: coordinator)

    tts.speak(text: "Pronunciation sample")
    await tts.playbackStartTask?.value
    #expect(tts.isSpeaking)

    await coordinator.broadcastEventForTesting(.interruptionBegan)
    // Small yield to allow async event task to execute
    try await Task.sleep(for: .milliseconds(50))
    #expect(!tts.isSpeaking)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftAppTests -destination "id=3CD37798-B3F2-4B42-8842-F076AC54DCFF" -only-testing:VocabCraftAppTests/SpeechServiceTests`
Expected: FAIL (TTS not yet hooked up to `coordinator.events`).

- [ ] **Step 3: Update `TextToSpeechService` and `ResilientReflexSpeechEngine`**

1. In `TextToSpeechService.swift`:
- Remove `interruptionObserver` property and `setupInterruptionObserver()` method.
- Add `private var eventSubscriptionTask: Task<Void, Never>?`.
- In `init`:
```swift
eventSubscriptionTask = Task { @MainActor [weak self] in
    guard let self, let events = self.audioSessionCoordinator.events else { return }
    for await event in events {
        guard let self else { break }
        switch event {
        case .interruptionBegan, .mediaServicesReset:
            self.stop()
        default:
            break
        }
    }
}
```
2. In `ResilientReflexSpeechEngine.swift`:
- Remove `InterruptionObserverToken` and local `NotificationCenter` observer.
- In `startSession(...)`:
- Start event stream observation task:
  - `.interruptionBegan` -> `pauseListening()`
  - `.interruptionEnded(shouldResume: true)` -> `resumeListening()`
  - `.mediaServicesReset` -> `stopSession(); onError?(SpeechCaptureError.enginePreparationFailed)`
- Cancel event task on `stopSession()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftAppTests -destination "id=3CD37798-B3F2-4B42-8842-F076AC54DCFF" -only-testing:VocabCraftAppTests/SpeechServiceTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/TextToSpeechService.swift \
        VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift \
        VocabCraftAppTests/SpeechServiceTests.swift \
        VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift
git commit -m "refactor(audio): migrate TextToSpeechService and ResilientReflexSpeechEngine to coordinator event stream"
```

---

### Task 6: Wire `AppContainer` & End-to-End Verification

**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftAppTests/App/AppContainerVocabularyTests.swift`

**Interfaces:**
- Consumes: Single shared `AudioSessionCoordinator` instance injected into all production audio consumers.
- Produces: Verified codebase with 0 direct `AVAudioSession` mutating calls, 0 lint issues, 0 compiler warnings.

- [ ] **Step 1: Update `AppContainer`**

In `VocabCraftApp/App/DI/AppContainer.swift`:
Ensure:
```swift
let resolvedAudioCoordinator: any AudioSessionCoordinating = audioSessionCoordinator ?? AudioSessionCoordinator()
self.audioSessionCoordinator = resolvedAudioCoordinator

self.ttsService = ttsService ?? TextToSpeechService(audioSessionCoordinator: resolvedAudioCoordinator)
```
And in `makeReflexSpeechEngine()`:
```swift
public func makeReflexSpeechEngine() -> ReflexSpeechEngineProtocol {
    ResilientReflexSpeechEngine(audioSessionCoordinator: audioSessionCoordinator)
}
```

- [ ] **Step 2: Scan for rogue direct `AVAudioSession.sharedInstance()` mutations**

Run:
```bash
git grep -n "AVAudioSession.sharedInstance()"
```
Expected: The ONLY matches must be inside `LiveAudioSessionHardware` in `AudioSessionCoordinator.swift`. All other services (`SpeechRecognitionService`, `SpeechRecognitionEngine`, `TextToSpeechService`, `ResilientReflexSpeechEngine`, `LiveSpeechAuthorizer`) must have 0 direct mutating calls.

- [ ] **Step 3: Run full verification test suite**

1. Run SpeechKit SPM tests:
```bash
swift test --package-path Packages/SpeechKit
```
2. Run CraftUIKit SPM tests:
```bash
swift test --package-path Packages/CraftUIKit
```
3. Run full App tests on iOS Simulator:
```bash
xcodebuild test -scheme VocabCraftAppTests -destination "id=3CD37798-B3F2-4B42-8842-F076AC54DCFF"
```
4. Run SwiftLint:
```bash
swiftlint
```
Expected: 100% test pass rate, 0 errors, 0 warnings.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/App/DI/AppContainer.swift \
        VocabCraftAppTests/App/AppContainerVocabularyTests.swift
git commit -m "chore(di): complete AppContainer audio session coordination injection and verify global single ownership"
```
