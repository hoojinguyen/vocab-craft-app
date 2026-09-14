# Centralized Audio Session Coordination Design

- **Status**: Approved
- **Date**: 2026-09-14
- **Author**: hoojinguyen & Antigravity
- **Related Issue**: [#19 Centralize all speech and TTS audio-session ownership behind one coordinator](https://github.com/hoojinguyen/vocab-craft-app/issues/19)
- **Related PR**: #18 (Scoped coordinator foundation)

---

## 1. Overview & Context

In iOS applications, `AVAudioSession` is a process-global singleton. When multiple services (`TextToSpeechService`, `ResilientReflexSpeechEngine`, `SpeechRecognitionService`, and `SpeechKit.SpeechRecognitionEngine`) interact with audio hardware independently, uncoordinated mutations to category, mode, options, and active state cause severe runtime regressions:
- **Race conditions**: TTS playback deactivating the audio session while speech recognition is actively listening.
- **Incompatible modes**: One service switching category from `.playAndRecord` to `.playback`, cutting off active audio input buffers.
- **Fragmented interruption handling**: Multiple independent `NotificationCenter` observers handling `AVAudioSession.interruptionNotification`, leading to inconsistent pause/resume behaviors.
- **Stale generation cleanup**: Delayed deactivations from finished requests shutting down newly initiated audio sessions.

PR #18 established the initial foundation of an `AudioSessionCoordinator` actor and `AudioSessionLease` in `VocabCraftApp`, but its usage was limited to `TextToSpeechService` and `ResilientReflexSpeechEngine`. Direct `AVAudioSession.sharedInstance()` mutations remained in `SpeechRecognitionService` and `Packages/SpeechKit`.

This design document establishes the complete, production-grade architecture centralizing 100% of audio-session ownership behind a single coordinator actor, enforcing Clean Architecture boundaries with `SpeechKit`, and guaranteeing deterministic audio lifecycle management across all features.

---

## 2. Core Architectural Principles

1. **Single Production Mutator**: Exactly one production actor (`AudioSessionCoordinator` via `AudioSessionHardware`) is permitted to mutate `AVAudioSession`. Direct calls to `AVAudioSession.sharedInstance().setCategory`, `.setActive`, and `.overrideOutputAudioPort` are strictly banned across the rest of the codebase.
2. **Package Independence & Inversion of Control**: `Packages/SpeechKit` must never depend on `VocabCraftApp`. The coordination abstractions (`AudioSessionCoordinating`, `AudioSessionIntent`, `AudioSessionLease`, `AudioSessionEvent`) are defined inside `SpeechKit`. `VocabCraftApp` imports `SpeechKit` and supplies the production coordinator instance.
3. **Lease-Based Lifecycle**: Audio services acquire typed leases (`AudioSessionLease`) for their required intent (`.playback`, `.speechCapture`, `.duplexSpeech`) and release them when done.
4. **Dynamic Intent Escalation**: When competing leases coexist (e.g. active speech capture while TTS triggers feedback audio), the coordinator dynamically escalates the session intent to `.duplexSpeech` (`.playAndRecord` with speaker and bluetooth options) rather than choosing a last-writer-wins strategy.
5. **Generational Invalidation**: Every state transition increments a monotonically increasing `generation` counter (`UInt`). Delayed or stale release requests from older generations cannot deactivate or alter a newer session.
6. **Centralized System Event Broadcasting**: `AudioSessionCoordinator` is the sole subscriber to `AVAudioSession.interruptionNotification`, `AVAudioSession.routeChangeNotification`, and `AVAudioSession.mediaServicesWereResetNotification`, broadcasting normalized `AudioSessionEvent`s through an `AsyncStream<AudioSessionEvent>`.
7. **Permission Decoupling**: Microphone authorization is decoupled from audio session hardware activation and uses modern iOS 17+ `AVAudioApplication.requestRecordPermission`.

---

## 3. Architecture & Dependency Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      Packages/SpeechKit                     │
│                                                             │
│  ┌───────────────────────┐       ┌───────────────────────┐  │
│  │AudioSessionCoordinating│       │   AudioSessionIntent  │  │
│  │       (Protocol)      │       │   AudioSessionLease   │  │
│  └───────────▲───────────┘       │   AudioSessionEvent   │  │
│              │                   └───────────────────────┘  │
│  ┌───────────┴───────────┐       ┌───────────────────────┐  │
│  │SpeechRecognitionEngine│◄──────┤NoOpAudioSessionCoord..│  │
│  └───────────────────────┘       └───────────────────────┘  │
└──────────────┼──────────────────────────────────────────────┘
               │ imported by
┌──────────────▼──────────────────────────────────────────────┐
│                        VocabCraftApp                        │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │               AudioSessionCoordinator                 │  │
│  │       (Actor conforming to AudioSessionCoordinating)  │  │
│  └───────────▲───────────────────────────┬───────────────┘  │
│              │ Injected via              │ Mutates via      │
│              │ AppContainer              │                  │
│  ┌───────────┴───────────┐       ┌───────▼───────────────┐  │
│  │  TextToSpeechService  │       │  AudioSessionHardware │  │
│  ├───────────────────────┤       │       (Protocol)      │  │
│  │ResilientReflexSpeech..│       └───────┬───────────────┘  │
│  ├───────────────────────┤               │ Implemented by   │
│  │SpeechRecognitionServ..│       ┌───────▼───────────────┐  │
│  └───────────────────────┘       │LiveAudioSessionHardware  │
│                                  │ (AVAudioSession.shared)│  │
│                                  └───────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Detailed Component Specifications

### 4.1 Abstraction Boundary (`Packages/SpeechKit`)

Located in `Packages/SpeechKit/Sources/SpeechKit/Protocols/AudioSessionCoordinating.swift`:

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

/// Primary coordinator abstraction.
public protocol AudioSessionCoordinating: AnyObject, Sendable {
    /// Acquire an audio session lease for the given intent.
    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease

    /// Release an active lease.
    func release(_ lease: AudioSessionLease) async

    /// Asynchronous stream of audio session events.
    var events: AsyncStream<AudioSessionEvent> { get }
}
```

#### Standalone No-Op Implementation
In `Packages/SpeechKit/Sources/SpeechKit/Engine/NoOpAudioSessionCoordinator.swift`:
Provides a no-op implementation conforming to `AudioSessionCoordinating` for package unit tests and mock environments where iOS hardware is unavailable.

#### SpeechRecognitionEngine Integration
In `Packages/SpeechKit/Sources/SpeechKit/Engine/SpeechRecognitionEngine.swift`:
- Adds `private let audioCoordinator: (any AudioSessionCoordinating)?`.
- In `start(...)`: Calls `audioCoordinator?.acquire(.speechCapture)` before preparing `AVAudioEngine`. Stores `activeLease`.
- In `stopInternal()`: Asynchronously releases `activeLease` via `audioCoordinator?.release(lease)`.
- Deletes `configureAudioSession()` and all inline references to `AVAudioSession.sharedInstance()`.

---

### 4.2 Production Coordinator (`VocabCraftApp`)

Located in `VocabCraftApp/Core/Audio/AudioSessionCoordinator.swift`:

#### Hardware Abstraction (`AudioSessionHardware`)
```swift
public protocol AudioSessionHardware: Sendable {
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws
    func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
    func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws
}
```

#### Dynamic Escalation Matrix
The effective intent is derived as follows:

| Active Leases Held | Effective Hardware Intent | Category | Mode | Category Options | Output Override |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Any `.duplexSpeech` | `.duplexSpeech` | `.playAndRecord` | `.default` | `[.defaultToSpeaker, .allowBluetoothHFP]` | `.speaker` |
| `.speechCapture` AND `.playback` | `.duplexSpeech` *(Escalated)* | `.playAndRecord` | `.default` | `[.defaultToSpeaker, .allowBluetoothHFP]` | `.speaker` |
| Only `.speechCapture` | `.speechCapture` | `.playAndRecord` | `.default` | `[.defaultToSpeaker, .allowBluetoothHFP]` | `.speaker` |
| Only `.playback` | `.playback` | `.playback` | `.spokenAudio` | `[.duckOthers]` | None |
| None (Empty) | `nil` | Inactive | - | `setActive(false, options: [.notifyOthersOnDeactivation])` | - |

Whenever an audio session is in `.speechCapture` or `.duplexSpeech`, `setAllowHapticsAndSystemSoundsDuringRecording(true)` is always configured to ensure UI tactile feedback remains active during vocal interactions.

#### Centralized System Event Observation
`AudioSessionCoordinator` initializes system observers:
1. `AVAudioSession.interruptionNotification`:
   - `.began`: Emits `.interruptionBegan`.
   - `.ended`: Inspects `userInfo[AVAudioSessionInterruptionOptionKey]`. If `.shouldResume`, emits `.interruptionEnded(shouldResume: true)`, otherwise `shouldResume: false`.
2. `AVAudioSession.routeChangeNotification`:
   - Inspects `AVAudioSessionRouteChangeReasonKey` and maps to `AudioSessionEvent.RouteChangeReason`. Emits `.routeChanged(reason:)`.
3. `AVAudioSession.mediaServicesWereResetNotification`:
   - Clears all active leases: `activeLeases.removeAll()`.
   - Increments generation: `generation &+= 1`.
   - Resets effective intent to `nil`.
   - Emits `.mediaServicesReset`.

---

### 4.3 Service Migrations

#### 1. `ResilientReflexSpeechEngine` (`VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift`)
- Removes local `setupInterruptionObserver()`, `InterruptionObserverToken`, and direct `AVAudioSession.interruptionNotification` subscription.
- Retains existing dependency on `audioSessionCoordinator: (any AudioSessionCoordinating)?`.
- Starts a background event listener `Task`:
  - `.interruptionBegan` $\to$ calls `pauseListening()`.
  - `.interruptionEnded(shouldResume: true)` $\to$ calls `resumeListening()`.
  - `.mediaServicesReset` $\to$ tears down audio controller and resets engine readiness.
- Continues acquiring `.duplexSpeech` lease during active reflex drill sessions.

#### 2. `TextToSpeechService` (`VocabCraftApp/Core/Audio/TextToSpeechService.swift`)
- Removes local `setupInterruptionObserver()` and direct `AVAudioSession.sharedInstance()` subscription.
- Subscribes to `audioSessionCoordinator.events`:
  - `.interruptionBegan` $\to$ calls `stop()` immediately.
  - `.mediaServicesReset` $\to$ calls `stop()` and invalidates pending syntheses.
- Retains acquiring `.playback` lease on speak and releasing on finish/cancel/stop.

#### 3. `SpeechRecognitionService` (`VocabCraftApp/Core/Audio/SpeechRecognitionService.swift`)
- Adds `private let audioSessionCoordinator: any AudioSessionCoordinating`.
- Updates initializer: `init(locale: String = "en-US", audioSessionCoordinator: any AudioSessionCoordinating)`.
- Removes local `interruptionObserver`.
- In `startListening()`:
  - Replaces direct `audioSession.setCategory(...)` and `audioSession.setActive(...)` with:
    `let lease = try await audioSessionCoordinator.acquire(.speechCapture)`
- In `stopListening()`:
  - Replaces `try? AVAudioSession.sharedInstance().setActive(false, ...)` with:
    `await audioSessionCoordinator.release(activeLease)`
- Updates microphone permission check to use `AVAudioApplication.requestRecordPermission` and `AVAudioApplication.shared.recordPermission`.

#### 4. `LiveSpeechAuthorizer` (`VocabCraftApp/Core/Audio/SpeechCaptureError.swift`)
- Replaces legacy iOS < 17 fallback `AVAudioSession.sharedInstance().requestRecordPermission` with direct `AVAudioApplication.requestRecordPermission()`.

#### 5. `AppContainer` (`VocabCraftApp/App/DI/AppContainer.swift`)
- Holds a single, shared `audioSessionCoordinator: any AudioSessionCoordinating`.
- Passes this coordinator to:
  - `TextToSpeechService(audioSessionCoordinator: resolvedAudioCoordinator)`
  - `SpeechRecognitionService(locale: "en-US", audioSessionCoordinator: resolvedAudioCoordinator)`
  - `ResilientReflexSpeechEngine(audioSessionCoordinator: audioSessionCoordinator)` in `makeReflexSpeechEngine()`.

---

## 5. Verification & Testing Matrix

| Test Level | Scope | Verification Details |
| :--- | :--- | :--- |
| **SPM Tests** | `Packages/SpeechKit` | Run `swift test --package-path Packages/SpeechKit`. Verifies `SpeechRecognitionEngine` acquires/releases lease via coordinator and passes with 0 failures on macOS and iOS. |
| **Unit Tests** | `AudioSessionCoordinatorTests` | Test dynamic escalation (`.speechCapture` + `.playback` $\to$ `.duplexSpeech`), idempotent release, stale generation rejection, activation failure rollback, port override resiliency, and event broadcasting via `MockAudioSessionHardware`. |
| **Integration Tests** | `SpeechServiceTests` | Test `TextToSpeechService`, `ResilientReflexSpeechEngine`, and `SpeechRecognitionService` concurrent leases, rapid stop $\to$ start, TTS $\to$ capture $\to$ feedback TTS transitions without category collision. |
| **App Tests** | Full App Test Suite | Run `xcodebuild test -scheme VocabCraftAppTests` on iOS Simulator with 100% pass rate. |
| **Quality Gates** | Lints & Warnings | Run `swiftlint`. Ensure 0 warnings and 0 errors. Verify grep for `AVAudioSession.sharedInstance()` yields **0 hits** outside `LiveAudioSessionHardware`. |

---

## 6. Migration Sequence

1. **Step 1**: Move/declare `AudioSessionCoordinating`, `AudioSessionIntent`, `AudioSessionLease`, and `AudioSessionEvent` in `Packages/SpeechKit`. Add `NoOpAudioSessionCoordinator`.
2. **Step 2**: Update `Packages/SpeechKit/SpeechRecognitionEngine` to use the coordinator and remove all direct `AVAudioSession` calls. Run SPM tests.
3. **Step 3**: Update `VocabCraftApp/Core/Audio/AudioSessionCoordinator.swift` to conform to `SpeechKit.AudioSessionCoordinating`, implement dynamic escalation, event broadcasting, and system notification handlers.
4. **Step 4**: Migrate `SpeechRecognitionService`, `LiveSpeechAuthorizer`, `TextToSpeechService`, and `ResilientReflexSpeechEngine` to use the centralized coordinator and event stream.
5. **Step 5**: Update `AppContainer` to inject the shared coordinator instance into all consumers.
6. **Step 6**: Update and expand tests in `AudioSessionCoordinatorTests` and `SpeechServiceTests`.
7. **Step 7**: Run full verification (`swift test`, `xcodebuild test`, `swiftlint`, grep scan) to ensure zero errors and zero warnings.
