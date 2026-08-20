# Xcode Build Warnings & Concurrency Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate all 13 compiler warnings, Swift 6 actor-isolation diagnostics, deprecated API usages, and project configuration issues across `VocabCraftApp`.

**Architecture:** 
- Align Swift Concurrency with Swift 6 strict concurrency rules (actor boundaries for `EnvironmentKey`, static locks, and async-safe locking patterns).
- Migrate deprecated AudioSession APIs to modern equivalents (`allowBluetoothHFP`).
- Normalize Info.plist and project build settings to satisfy Xcode target validation requirements.

**Tech Stack:** Swift 6 / Swift 5.10, SwiftUI, AVFoundation, SpeechKit, Xcode 16+

**Spec:** [`docs/superpowers/specs/2026-08-20-xcode-build-warnings-fix-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-20-xcode-build-warnings-fix-design.md)

## Global Constraints

- Must compile cleanly with 0 warnings on Xcode 16+ / iOS 17.0+ deployment target.
- Must not break existing unit tests (`VocabCraftAppTests`).
- Maintain thread safety and actor isolation correctness across all audio and view-model services.

---

### Task 1: Fix Swift 6 Concurrency & Actor Isolation Violations

**Files:**
- Modify: [`VocabCraftApp/App/DI/EnvironmentKeys.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/App/DI/EnvironmentKeys.swift)
- Modify: [`VocabCraftApp/Core/Audio/TextToSpeechService.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Audio/TextToSpeechService.swift)
- Modify: [`VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift)
- Modify: [`VocabCraftApp/Core/SpeechKit/Engine/SpeechRecognitionEngine.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/SpeechKit/Engine/SpeechRecognitionEngine.swift)

**Interfaces:**
- Consumes: `EnvironmentKey`, `NSLock`, `AVSpeechSynthesisVoice`, `SFSpeechAudioBufferRecognitionRequest`
- Produces: Nonisolated `EnvironmentKey` default values, nonisolated static `voiceLock`, and synchronous lock helper methods.

- [ ] **Step 1: Update `EnvironmentKeys.swift` to remove `@MainActor` from Keys**

In `VocabCraftApp/App/DI/EnvironmentKeys.swift`:
```swift
import SwiftUI

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue: AppContainer = .mock
}

private struct AppRouterKey: EnvironmentKey {
    static let defaultValue: AppRouter? = nil
}
```

- [ ] **Step 2: Update `voiceLock` in `TextToSpeechService.swift`**

In `VocabCraftApp/Core/Audio/TextToSpeechService.swift`:
```swift
    private nonisolated(unsafe) static var cachedVoices: [String: AVSpeechSynthesisVoice] = [:]
    private nonisolated static let voiceLock = NSLock()
```

- [ ] **Step 3: Update `ContinuousReflexSpeechService.swift` async locking**

In `VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift`:
Add helper method:
```swift
    private func checkSessionActive(sessionId: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isSessionActive && currentSessionId == sessionId
    }
```
And in `startAudioStream()` replace:
```swift
        simulationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self = self, self.checkSessionActive(sessionId: sessionId) else {
                    break
                }
            }
        }
```

- [ ] **Step 4: Update `SpeechRecognitionEngine.swift` async locking**

In `VocabCraftApp/Core/SpeechKit/Engine/SpeechRecognitionEngine.swift`:
Add helper method:
```swift
    private func isSessionActiveAndRecording(sessionId: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return currentSessionId == sessionId && _isRecording
    }
```
And in `startRecording(...)` simulator task replace:
```swift
        simulationTask = Task { [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(for: .milliseconds(400))
            guard self.isSessionActiveAndRecording(sessionId: sessionId) else { return }

            let target = phrases.first ?? "Sample utterance"
            let words = target.split(separator: " ")
            if words.count > 1 {
                let partial = words.prefix(max(1, words.count / 2)).joined(separator: " ")
                onPartialResult(partial)
            }

            try? await Task.sleep(for: .milliseconds(600))
            guard self.isSessionActiveAndRecording(sessionId: sessionId) else { return }

            onFinalResult(target)
        }
```

- [ ] **Step 5: Verify build for Task 1**

Run:
```bash
xcodebuild build -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator'
```
Expected: Build succeeds without Swift 6 actor isolation or async lock errors.

---

### Task 2: Remove Redundant `nonisolated(unsafe)` Modifiers

**Files:**
- Modify: [`VocabCraftApp/Core/Audio/SpeechRecognitionService.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Audio/SpeechRecognitionService.swift)
- Modify: [`VocabCraftApp/Core/Audio/TextToSpeechService.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Audio/TextToSpeechService.swift)
- Modify: [`VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift)

- [ ] **Step 1: Clean up `interruptionObserver` in `SpeechRecognitionService.swift`**

In `VocabCraftApp/Core/Audio/SpeechRecognitionService.swift:35`:
```swift
    private var interruptionObserver: (any NSObjectProtocol)?
```

- [ ] **Step 2: Clean up `interruptionObserver` in `TextToSpeechService.swift`**

In `VocabCraftApp/Core/Audio/TextToSpeechService.swift:11`:
```swift
    private var interruptionObserver: (any NSObjectProtocol)?
```

- [ ] **Step 3: Clean up `hintTasks` in `QuickReflexDrillViewModel.swift`**

In `VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift:85`:
```swift
    // Task handles are mutated on main actor and cancelled during deinit/teardown.
    private var hintTasks: [Task<Void, Never>] = []
```

- [ ] **Step 4: Verify build for Task 2**

Run:
```bash
xcodebuild build -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator'
```
Expected: Build succeeds without `'nonisolated(unsafe)' has no effect` warnings.

---

### Task 3: Replace Deprecated `allowBluetooth` API

**Files:**
- Modify: [`VocabCraftApp/Core/Audio/TextToSpeechService.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Audio/TextToSpeechService.swift)
- Modify: [`VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift)

- [ ] **Step 1: Update audio category options in `TextToSpeechService.swift`**

In `TextToSpeechService.swift` lines 76 and 112:
```swift
try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
```

- [ ] **Step 2: Update audio category options in `ContinuousReflexSpeechService.swift`**

In `ContinuousReflexSpeechService.swift` line 417:
```swift
try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
```

- [ ] **Step 3: Verify build for Task 3**

Run:
```bash
xcodebuild build -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator'
```
Expected: Build succeeds without `allowBluetooth was deprecated` warnings.

---

### Task 4: Fix iPad Full Screen & Orientation Configuration

**Files:**
- Modify: [`VocabCraftApp/App/Info.plist`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/App/Info.plist)

- [ ] **Step 1: Add `UIRequiresFullScreen` to `Info.plist`**

In `VocabCraftApp/App/Info.plist`:
```xml
	<key>UIRequiresFullScreen</key>
	<true/>
```

- [ ] **Step 2: Verify Info.plist XML validation**

Run:
```bash
plutil -lint VocabCraftApp/App/Info.plist
```
Expected: `VocabCraftApp/App/Info.plist: OK`

---

### Task 5: Fix Debug Binary Stripping & Extension CodeSign

**Files:**
- Modify: [`VocabCraftApp.xcodeproj/project.pbxproj`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp.xcodeproj/project.pbxproj)

- [ ] **Step 1: Ensure `COPY_PHASE_STRIP = NO` for Debug configurations**

In `VocabCraftApp.xcodeproj/project.pbxproj`:
Ensure all Debug `buildSettings` configurations contain `COPY_PHASE_STRIP = NO;`.

- [ ] **Step 2: Ensure `CodeSignOnCopy` on `Embed App Extensions` build phase**

In `project.pbxproj`:
```
300000402D50000000000002 /* VocabCraftWidgetExtension.appex in Embed App Extensions */ = {isa = PBXBuildFile; fileRef = 200000402D50000000000000 /* VocabCraftWidgetExtension.appex */; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, CodeSignOnCopy, ); }; };
```

---

### Task 6: Verification & Test Execution

**Files:**
- Test target: `VocabCraftAppTests`

- [ ] **Step 1: Run full clean build**

Run:
```bash
xcodebuild -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator' clean build
```
Expected: `** BUILD SUCCEEDED **` with 0 warnings.

- [ ] **Step 2: Run unit test suite**

Run:
```bash
xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: `** TEST SUCCEEDED **` with all unit tests passing.
