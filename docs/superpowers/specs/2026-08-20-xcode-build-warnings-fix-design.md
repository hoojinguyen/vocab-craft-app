# Xcode Build Warnings & Concurrency Fix Design Spec

**Date:** 2026-08-20  
**Author:** Antigravity (Superpowers Mode)  
**Status:** In Review  
**Target:** VocabCraft App & Widget Extension (iOS 17+, Xcode 16+)

---

## 1. Executive Summary & Goals

During clean builds and Xcode issue analysis, 13 issues and warnings were identified across the codebase and project configuration:
1. **Swift 6 Concurrency & Actor Isolation Violations (5 issues)**:
   - `AppContainerKey` & `AppRouterKey` crossing into `@MainActor` isolation while conforming to `EnvironmentKey`.
   - `voiceLock` static property on `@MainActor`-isolated `TextToSpeechService` being accessed from `nonisolated` static function `resolveVoice(for:)`.
   - `lock.lock()` and `unlock()` called directly within asynchronous `Task` closures in `ContinuousReflexSpeechService` and `SpeechRecognitionEngine`.
2. **Redundant `nonisolated(unsafe)` Annotations (3 issues)**:
   - In `SpeechRecognitionService`, `TextToSpeechService`, and `QuickReflexDrillViewModel`.
3. **Deprecated Audio APIs (3 issues)**:
   - `AVAudioSession.CategoryOptions.allowBluetooth` used instead of `allowBluetoothHFP` in `TextToSpeechService` and `ContinuousReflexSpeechService`.
4. **Target & Bundle Configuration (2 issues)**:
   - Missing `UIRequiresFullScreen` for universal device family with portrait-only orientation in `Info.plist`.
   - Signed binary stripping warning in `VocabCraftWidgetExtension` during Debug builds.
   - Outdated `LastUpgradeCheck` (Xcode project recommended settings).

### Objectives
- Eliminate 100% of compiler warnings and Xcode issue navigator items.
- Ensure strict Swift 6 concurrency compliance without runtime race conditions or async lock deadlocks.
- Maintain full backward compatibility and zero regressions across all unit tests.

---

## 2. Architecture & Subsystem Analysis

```mermaid
graph TD
    subgraph SwiftUI DI & Environment
        EK[EnvironmentKeys.swift] -->|Nonisolated default value| EV[EnvironmentValues]
        EV -->|@MainActor Accessors| Views[SwiftUI Views]
    end

    subgraph Audio & Concurrency
        TTS[TextToSpeechService] -->|nonisolated voiceLock| VoiceCache[Static Voice Cache]
        CRSS[ContinuousReflexSpeechService] -->|Synchronous checkSessionActive| TaskLoop[Task Async Loop]
        SRE[SpeechRecognitionEngine] -->|Synchronous isSessionActiveAndRecording| SimLoop[Simulator Mock Loop]
    end

    subgraph Project & Bundle Config
        Plist[Info.plist] -->|UIRequiresFullScreen=true| TargetConfig[Target Validation]
        PBX[project.pbxproj] -->|COPY_PHASE_STRIP=NO| DebugBuild[Clean Debug Build]
    end
```

---

## 3. Detailed Component Specifications

### 3.1. Swift 6 Concurrency Fixes

#### A. `EnvironmentKeys.swift`
* **Problem**: `struct AppContainerKey: EnvironmentKey` and `struct AppRouterKey: EnvironmentKey` are annotated with `@MainActor`. The `EnvironmentKey` protocol requires `static var defaultValue: Value { get }` which is non-isolated. When the conforming type is `@MainActor`, `defaultValue` becomes isolated, causing actor isolation boundary violations in Swift 6.
* **Specification**:
  - Remove `@MainActor` from `private struct AppContainerKey` and `private struct AppRouterKey`.
  - Keep `@MainActor` on the `EnvironmentValues` computed property accessors (`appContainer`, `appRouter`) to ensure SwiftUI views access them on the main thread.

#### B. `TextToSpeechService.swift`
* **Problem**: `TextToSpeechService` is `@MainActor`. Therefore, `private static let voiceLock = NSLock()` is implicitly `@MainActor`. However, `resolveVoice(for:)` is `public nonisolated static func`, which accesses `voiceLock` from non-isolated threads.
* **Specification**:
  - Explicitly declare `private nonisolated static let voiceLock = NSLock()`.
  - Retain `private nonisolated(unsafe) static var cachedVoices: [String: AVSpeechSynthesisVoice] = [:]` protected by `voiceLock`.

#### C. `ContinuousReflexSpeechService.swift`
* **Problem**: In `startAudioStream()`, `simulationTask = Task { ... }` calls `self.lock.lock()` and `self.lock.unlock()` directly inside an `async` closure. In Swift 6, `NSLock.lock()` is marked unavailable from async contexts to prevent thread pool deadlocks.
* **Specification**:
  - Implement a synchronous helper method:
    ```swift
    private func checkSessionActive(sessionId: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isSessionActive && currentSessionId == sessionId
    }
    ```
  - In `simulationTask`, invoke `self.checkSessionActive(sessionId: sessionId)`.

#### D. `SpeechRecognitionEngine.swift`
* **Problem**: In `startRecording(...)`, the simulator mock branch calls `self.lock.lock()` and `self.lock.unlock()` inside `simulationTask = Task { ... }`.
* **Specification**:
  - Implement a synchronous helper method:
    ```swift
    private func isSessionActiveAndRecording(sessionId: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return currentSessionId == sessionId && _isRecording
    }
    ```
  - Replace raw lock/unlock calls in `simulationTask` with `self.isSessionActiveAndRecording(sessionId: sessionId)`.

---

### 3.2. Redundant `nonisolated(unsafe)` Cleanups

* **`SpeechRecognitionService.swift`**:
  - Property `interruptionObserver`: Change `private nonisolated(unsafe) var interruptionObserver: NSObjectProtocol?` to `private var interruptionObserver: (any NSObjectProtocol)?`.
* **`TextToSpeechService.swift`**:
  - Property `interruptionObserver`: Change `private nonisolated(unsafe) var interruptionObserver: NSObjectProtocol?` to `private var interruptionObserver: (any NSObjectProtocol)?`.
* **`QuickReflexDrillViewModel.swift`**:
  - Property `hintTasks`: Change `private nonisolated(unsafe) var hintTasks: [Task<Void, Never>] = []` to `private var hintTasks: [Task<Void, Never>] = []`. (Since `Task<Void, Never>` is `Sendable`, the array is `Sendable`, making `nonisolated(unsafe)` redundant).

---

### 3.3. Deprecated API Migrations

* **`TextToSpeechService.swift`** (lines 76, 112) & **`ContinuousReflexSpeechService.swift`** (line 417):
  - Replace `.allowBluetooth` with `.allowBluetoothHFP` in `AVAudioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])`.

---

### 3.4. Target & Bundle Validation

* **`VocabCraftApp/App/Info.plist`**:
  - Add `<key>UIRequiresFullScreen</key><true/>`.
  - Fixes the Xcode warning: *"All interface orientations must be supported unless the app requires full screen."*

* **`VocabCraftApp.xcodeproj/project.pbxproj`**:
  - Set `COPY_PHASE_STRIP = NO;` for Debug build configurations.
  - Set `CodeSignOnCopy` on `VocabCraftWidgetExtension.appex` in `Embed App Extensions`.

---

## 4. Risk Analysis & Mitigation

| Risk | Mitigation |
| :--- | :--- |
| Changing lock mechanism affects thread safety | Synchronous helper methods use `lock.lock()` and `defer { lock.unlock() }` internally, ensuring identical synchronization semantics without blocking async worker threads. |
| Removing `@MainActor` from Keys causes unintended background instantiation | `AppContainerKey.defaultValue` uses `.mock` which is statically safe; view access remains constrained to `@MainActor` via `EnvironmentValues`. |
| Deprecated Bluetooth option breaks older headsets | `.allowBluetoothHFP` has been supported since iOS 10.0+ (deployment target is iOS 17.0+). |

---

## 5. Verification Plan

1. **Clean Build**:
   ```bash
   xcodebuild -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator' clean build
   ```
   *Pass criteria: Build succeeds with 0 warnings.*

2. **Automated Unit Tests**:
   ```bash
   xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16'
   ```
   *Pass criteria: 100% of test cases pass.*
