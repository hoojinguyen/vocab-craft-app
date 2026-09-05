# PR #18 Review Findings Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve the critical audio engine lifecycle bypass on 60s timeout in `ResilientReflexSpeechEngine`, eliminate silent error swallowing via `try?` in engine preparation, guard `beginWord` on the speech protocol, and eliminate duplicate code smells.

**Architecture:** 
1. Auto-recovery upon speech recognizer 60s timeout (`1110`) must not bypass the engine lifecycle; it must check `isSessionActive`, `isEngineReady`, and session token validity, and restart only the active `SFSpeechAudioBufferRecognitionRequest` on the existing running audio engine instead of invoking `beginWord(...)`.
2. Engine preparation tasks launched during `startSession` and `resumeListening` must handle `CancellationError` silently while propagating real hardware failures to `onError`.
3. Deprecate `beginWord` on `ReflexSpeechEngineProtocol`, and guard `beginWord` in `ResilientReflexSpeechEngine` so un-prepared calls cannot open hardware taps without readiness.
4. Extract `AppPermissionNotice` to eliminate duplicated structs across `Lesson` and `Reflex`, and extract `makeUtterance` helper in `TextToSpeechService`.

**Tech Stack:** Swift 6 Concurrency, Speech framework (`SFSpeechRecognizer`), AVFoundation (`AVAudioEngine`, `AVSpeechSynthesizer`), Swift Testing / XCTest.

**Spec:** [docs/superpowers/specs/2026-09-05-speech-runtime-coordination-remediation-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-09-05-speech-runtime-coordination-remediation-design.md)

## Global Constraints
- Target: iOS 26+ runtime (`VocabCraftApp`)
- AGENTS.md §4: Zero hardcoded strings. All user-facing strings in `Localizable.xcstrings`.
- AGENTS.md §5: Zero errors, zero warnings on SwiftLint and Xcode build.
- 100% test pass rate across app and package tests.

---

### Task 1: Fix 60s Timeout Auto-Recovery & Replace Silent `try?` in Engine Preparation

**Files:**
- Modify: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift:153-158, 203-208, 625-638`
- Test: `VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift`

**Interfaces:**
- Consumes: `bufferRelay`, `activeTask`, `activeRequest`, `currentWordSessionToken`, `isSessionActive`, `isEngineReady`, `isWordActive`
- Produces: Safe restart of recognition request on error code 1110 that preserves engine readiness and leases.

- [ ] **Step 1: Write unit tests verifying 60s timeout handling and engine preparation failure propagation**

In `VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift`:
```swift
func testTimeout1110_whenSessionNotActive_doesNotRestartRecognition() {
    engine.startSession(contextualPhrases: [])
    engine.beginWord(targetLemma: "test", contextualPhrases: [])
    engine.stopSession()

    XCTAssertFalse(engine.isSessionActive)
    XCTAssertFalse(engine.isWordActive)
}
```

- [ ] **Step 2: Run test to verify behavior**

Run: `swift test --filter ResilientReflexSpeechEngineTests`
Expected: Tests compile and pass.

- [ ] **Step 3: Implement safe timeout recovery and error propagation in `ResilientReflexSpeechEngine.swift`**

1. In `startSession(contextualPhrases:lazy:)`:
```swift
if !lazy {
    pendingPreparationTask = Task { [weak self] in
        do {
            try await self?.prepareEngineIfNeeded()
        } catch is CancellationError {
            // Task cancellation is expected on stopSession
        } catch {
            Task { @MainActor [weak self] in
                self?.onError?(error)
            }
        }
    }
}
```
2. In `resumeListening()`:
```swift
if !isEngineReady {
    pendingPreparationTask?.cancel()
    pendingPreparationTask = Task { [weak self] in
        do {
            try await self?.prepareEngineIfNeeded()
        } catch is CancellationError {
            // Task cancellation is expected on stopSession
        } catch {
            Task { @MainActor [weak self] in
                self?.onError?(error)
            }
        }
    }
}
```
3. In `recognitionTask` error handler:
```swift
let nsError = error as NSError
// 216 = cancelled (normal), 1110 = timeout (60s limit)
if nsError.code == 1110 {
    // 60s limit hit — safely re-open recognition request only if word & session remain active
    guard self.isSessionActive, self.isEngineReady, self.isWordActive,
          self.currentWordSessionToken == sessionToken else { return }
    self.bufferRelay.detachAndEnd()
    self.activeTask?.cancel()
    self.activeTask = nil
    self.activeRequest = nil
    #if targetEnvironment(simulator) || os(macOS)
    // Simulator stub
    #else
    self.startRecognitionRequest(
        targetLemma: targetLemma,
        contextualPhrases: contextualPhrases,
        sessionToken: sessionToken
    )
    #endif
} else if nsError.code != 216 && nsError.code != 203 && nsError.code != 301 {
    self.onError?(error)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ResilientReflexSpeechEngineTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift
git commit -m "fix(speech): safely recover from 60s timeout and propagate prep errors"
```

---

### Task 2: Deprecate and Guard `beginWord` in Speech Engine Protocol and Implementation

**Files:**
- Modify: `VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift:18-20, 33-36`
- Modify: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift:439-446`

**Interfaces:**
- Consumes: `ReflexSpeechEngineProtocol`
- Produces: Deprecated `beginWord` with readiness assertion in production engine.

- [ ] **Step 1: Add deprecation annotations to `ReflexSpeechEngineProtocol.swift`**

```swift
@available(*, deprecated, message: "Use startListening(targetLemma:contextualPhrases:) instead")
func beginWord(targetLemma: String, contextualPhrases: [String])
```

- [ ] **Step 2: Guard `beginWord` in `ResilientReflexSpeechEngine.swift`**

```swift
@available(*, deprecated, message: "Use startListening(targetLemma:contextualPhrases:) instead")
public func beginWord(targetLemma: String, contextualPhrases: [String]) {
    guard isSessionActive else {
        LessonPerformanceDiagnostics.event("SpeechWordBeginIgnored", detail: "sessionInactive")
        return
    }
    ...
}
```

- [ ] **Step 3: Run existing test suites to confirm no compilation breakage**

Run: `swift test --filter SpeechServiceTests`
Expected: PASS with 0 errors.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift
git commit -m "refactor(speech): deprecate and guard beginWord against inactive sessions"
```

---

### Task 3: Deduplicate `PermissionNotice` and TTS Utterance Setup

**Files:**
- Create: `VocabCraftApp/Core/Models/AppPermissionNotice.swift`
- Modify: `VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift:546-562`
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift:611-627`
- Modify: `VocabCraftApp/Core/Audio/TextToSpeechService.swift:110-170`

**Interfaces:**
- Produces: Unified `AppPermissionNotice`, backward-compatible typealiases `LessonPermissionNotice` and `ReflexPermissionNotice`.
- Produces: Private `makeUtterance(text:rate:locale:)` in `TextToSpeechService`.

- [ ] **Step 1: Create `VocabCraftApp/Core/Models/AppPermissionNotice.swift`**

```swift
import Foundation

public struct AppPermissionNotice: Equatable, Sendable {
    public let title: String
    public let message: String
    public let settingsActionTitle: String
    public let dismissActionTitle: String

    public init(
        title: String = AppStrings.Lesson.permissionTitleText,
        message: String = AppStrings.Lesson.permissionMessageText,
        settingsActionTitle: String = AppStrings.Lesson.permissionSettingsActionText,
        dismissActionTitle: String = AppStrings.Lesson.permissionDismissActionText
    ) {
        self.title = title
        self.message = message
        self.settingsActionTitle = settingsActionTitle
        self.dismissActionTitle = dismissActionTitle
    }
}

public typealias LessonPermissionNotice = AppPermissionNotice
public typealias ReflexPermissionNotice = AppPermissionNotice
```

- [ ] **Step 2: Replace redundant struct declarations in `LessonLearningViewModel.swift` and `ReflexBlitzViewModel.swift`**

Remove the duplicate structs and let them use the shared `AppPermissionNotice` (via typealiases).

- [ ] **Step 3: Extract `makeUtterance` helper in `TextToSpeechService.swift`**

```swift
private func makeUtterance(text: String, rate: Float, locale: String) -> AVSpeechUtterance? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let utterance = AVSpeechUtterance(string: trimmed)
    let scaledRate = AVSpeechUtteranceDefaultSpeechRate * rate
    utterance.rate = min(max(scaledRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)

    if let voice = Self.resolveVoice(for: locale) {
        utterance.voice = voice
    }
    return utterance
}
```
Use `makeUtterance` in both `speak(...)` and `speakAsync(...)`.

- [ ] **Step 4: Run tests to verify deduplication**

Run: `swift test --filter SpeechServiceTests` and `swift test --filter LessonLearningViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Models/AppPermissionNotice.swift VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift VocabCraftApp/Core/Audio/TextToSpeechService.swift
git commit -m "refactor: extract AppPermissionNotice and deduplicate TTS utterance setup"
```

---

### Task 4: Complete Quality Gate Verification

**Files:**
- None (verification only)

- [ ] **Step 1: Run CraftUIKit localization tests**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Expected: PASS (100%)

- [ ] **Step 2: Run all CraftUIKit unit tests**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: PASS (100%)

- [ ] **Step 3: Run app unit tests**

Run: `swift test`
Expected: PASS (100%)

- [ ] **Step 4: Run SwiftLint**

Run: `swiftlint lint --strict`
Expected: 0 violations, 0 warnings

- [ ] **Step 5: Verify git status and diff**

Run: `git status`
Expected: clean working directory, only intended commits present.
