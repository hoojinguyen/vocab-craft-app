# Reflex Blitz Audio, Pacing, and UX Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance the Reflex Blitz drill experience by expanding the success dwell time (1000ms), adding an immediate success sound cue, preventing TTS self-echo on timeouts via async coordination, eliminating speaker buzzing by standardizing AVAudioSession, and fixing mode-switching frame drops.

**Architecture:** Async TTS completion protocol extension with speech engine pause/mute synchronization during TTS and keyboard mode; zero-distortion shared AVAudioSession configuration; 1000ms reveal pacing on correct answer; isolated sound effect trigger; 100ms stopwatch tick optimization.

**Tech Stack:** Swift 6, SwiftUI, AVFoundation (`AVSpeechSynthesizer`, `AVAudioEngine`, `AVAudioSession`), AudioToolbox (`AudioServicesPlaySystemSound`), Speech (`SFSpeechRecognizer`), Observation framework.

**Spec:** `docs/superpowers/specs/2026-08-19-reflex-blitz-audio-ux-enhancements-design.md`

## Global Constraints

- iOS 17+ deployment target, Swift 6 strict concurrency compatible.
- Audio session category must remain `.playAndRecord` with options `[.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]` (no `.allowBluetoothHFP`).
- All dwell times, animations, and timeout reveal periods must remain excluded from `responseTimeMs`.
- Tests must pass using `swift test` or `xcodebuild test`.

---

### Task 1: Core Audio Layer - Async TTS Protocol & SoundEffectService

**Files:**
- Modify: `VocabCraftApp/Domain/Protocols/AudioServiceProtocols.swift`
- Modify: `VocabCraftApp/Core/Audio/TextToSpeechService.swift`
- Create: `VocabCraftApp/Core/Audio/SoundEffectService.swift`
- Test: `VocabCraftAppTests/Core/Audio/SoundEffectAndTTSTests.swift`

**Interfaces:**
- Consumes: `AVSpeechSynthesizerDelegate`, `AudioServicesPlaySystemSound`
- Produces: `TextToSpeechProtocol.speakAsync(text:rate:locale:) async`, `SoundEffectServiceProtocol.playSuccessChime()`

- [ ] **Step 1: Write the failing test for Async TTS and SoundEffectService**

Create `VocabCraftAppTests/Core/Audio/SoundEffectAndTTSTests.swift`:
```swift
import XCTest
@testable import VocabCraftApp

@MainActor
final class SoundEffectAndTTSTests: XCTestCase {
    func testAsyncTTSCompletesSuccessfully() async {
        let tts = TextToSpeechService()
        await tts.speakAsync(text: "habit", rate: 0.5, locale: "en-US")
        XCTAssertFalse(tts.isSpeaking)
    }

    func testSoundEffectServicePlaysWithoutCrashing() {
        let soundService = SoundEffectService.shared
        soundService.playSuccessChime()
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/SoundEffectAndTTSTests`
Expected: FAIL (missing `speakAsync` and `SoundEffectService`)

- [ ] **Step 3: Implement `speakAsync` and `SoundEffectService`**

Update `VocabCraftApp/Domain/Protocols/AudioServiceProtocols.swift`:
```swift
import Foundation

/// Protocol abstraction for Text-to-Speech audio playback.
@MainActor
public protocol TextToSpeechProtocol: AnyObject {
    var isSpeaking: Bool { get }
    func speak(text: String, rate: Float, locale: String)
    func speakAsync(text: String, rate: Float, locale: String) async
    func stop()
}

public extension TextToSpeechProtocol {
    func speak(text: String) {
        speak(text: text, rate: 0.5, locale: "en-US")
    }

    func speakAsync(text: String) async {
        await speakAsync(text: text, rate: 0.5, locale: "en-US")
    }
}
```

Update `VocabCraftApp/Core/Audio/TextToSpeechService.swift` to support `speakAsync`, continuation management, and unified `AVAudioSession` options:
```swift
#if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set AVAudioSession category for TTS: \(error)")
        }
#endif
```

Create `VocabCraftApp/Core/Audio/SoundEffectService.swift`:
```swift
import AudioToolbox
import Foundation

public protocol SoundEffectServiceProtocol: Sendable {
    func playSuccessChime()
}

public final class SoundEffectService: SoundEffectServiceProtocol, @unchecked Sendable {
    public static let shared = SoundEffectService()

    public init() {}

    public func playSuccessChime() {
        #if os(iOS)
        // 1054 is the standard pleasant UI acknowledgment chime, or 1057 / 1394
        AudioServicesPlaySystemSound(1054)
        #endif
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/SoundEffectAndTTSTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Protocols/AudioServiceProtocols.swift VocabCraftApp/Core/Audio/TextToSpeechService.swift VocabCraftApp/Core/Audio/SoundEffectService.swift VocabCraftAppTests/Core/Audio/SoundEffectAndTTSTests.swift
git commit -m "feat(audio): add async TTS and sound effect service with clean AVAudioSession"
```

---

### Task 2: ContinuousReflexSpeechService Audio Session & Pause/Resume Lifecycle

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift`

**Interfaces:**
- Consumes: `ContinuousReflexSpeechProtocol`
- Produces: `pauseListening()`, `resumeListening()`, `isRecognitionMuted: Bool`

- [ ] **Step 1: Write the failing test for pause/resume and mute behavior**

Update `VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift`:
```swift
func testPauseAndResumeListening() {
    let mock = MockContinuousReflexSpeechService()
    mock.startSession()
    mock.setTargetWord(lemma: "habit", contextualPhrases: [])
    
    mock.pauseListening()
    XCTAssertTrue(mock.isRecognitionMuted)
    
    var matchDetected = false
    mock.onMatchDetected = { _ in matchDetected = true }
    mock.simulateTranscript("habit")
    XCTAssertFalse(matchDetected, "Should not detect match while listening is muted/paused")
    
    mock.resumeListening()
    XCTAssertFalse(mock.isRecognitionMuted)
    mock.simulateTranscript("habit")
    XCTAssertTrue(matchDetected, "Should detect match after resuming listening")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ContinuousReflexSpeechServiceTests`
Expected: FAIL (missing `pauseListening`, `resumeListening`, `isRecognitionMuted`)

- [ ] **Step 3: Implement pause/resume and audio session unification in `ContinuousReflexSpeechService`**

Update `ContinuousReflexSpeechProtocol`:
```swift
public protocol ContinuousReflexSpeechProtocol: AnyObject, Sendable {
    var isSessionActive: Bool { get }
    var isRecognitionMuted: Bool { get }
    var currentTranscript: String { get }
    var onMatchDetected: ((String) -> Void)? { get set }
    var onTranscriptUpdate: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }

    func startSession(contextualPhrases: [String])
    func startSession()
    func stopSession()
    func pauseListening()
    func resumeListening()
    func setTargetWord(lemma: String, contextualPhrases: [String])
    func resetBuffer()
}
```

Update `ContinuousReflexSpeechService` and `MockContinuousReflexSpeechService` to:
1. Support `isRecognitionMuted`, `pauseListening()`, `resumeListening()`.
2. Standardize `AVAudioSession`:
```swift
try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
```
3. In `startAudioStream()` tap handler and result handler, check `guard !isRecognitionMuted else { return }`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ContinuousReflexSpeechServiceTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift
git commit -m "feat(speech): add pause/resume lifecycle and clean audio session to ContinuousReflexSpeechService"
```

---

### Task 3: ReflexBlitzViewModel Pacing, Async TTS, Mode Toggle & Sound Effect

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- Consumes: `SoundEffectServiceProtocol`, `TextToSpeechProtocol.speakAsync`, `ContinuousReflexSpeechProtocol.pauseListening/resumeListening`
- Produces: Updated `handleSpokenMatch`, `handleTimeout`, `toggleKeyboardFallback`, 100ms timer ticks

- [ ] **Step 1: Write failing tests for ViewModel updates**

Update `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift` to verify:
1. `handleSpokenMatch` triggers `soundService.playSuccessChime()`, records `responseTimeMs` without including the 1000ms delay.
2. `handleTimeout` pauses speech recognizer, awaits TTS, and only advances after TTS completes.
3. `toggleKeyboardFallback` calls `pauseListening()` on keyboard active, and `resumeListening()` on keyboard inactive.

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests`
Expected: FAIL

- [ ] **Step 3: Update `ReflexBlitzViewModel`**

1. Inject `soundEffectService: SoundEffectServiceProtocol = SoundEffectService.shared`.
2. In `handleSpokenMatch`:
   - Play success sound: `soundEffectService.playSuccessChime()`.
   - Set dwell time to 1000ms: `try? await Task.sleep(for: .milliseconds(1000))`.
3. In `handleTimeout`:
   - `continuousSpeechService.pauseListening()`.
   - `Task { @MainActor [weak self] in await self?.ttsService.speakAsync(text: word.lemma, rate: 0.5, locale: "en-US"); try? await Task.sleep(for: .milliseconds(300)); self?.continuousSpeechService.resumeListening(); self?.loadWord(at: self!.currentWordIndex + 1) }`.
4. In `toggleKeyboardFallback()` / `isKeyboardFallbackActive.didSet`:
   - If `isKeyboardFallbackActive`: `continuousSpeechService.pauseListening()`.
   - Else: `continuousSpeechService.resumeListening()`.
5. In `startStopwatch()`:
   - Change `Task.sleep(for: .milliseconds(50))` to `Task.sleep(for: .milliseconds(100))` to halve re-render overhead.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift
git commit -m "feat(reflex): optimize pacing, anti-echo TTS synchronization, and mode switching in ViewModel"
```

---

### Task 4: ReflexBlitzCardView Cloze Reveal Visual Enhancements

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzWordItem`, `isCorrect`, `isTimeout`
- Produces: Enhanced `sentenceView` with highlighted inline cloze slot on success

- [ ] **Step 1: Write the failing test for cloze slot reveal styling**

Update `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift` to verify the sentence rendering logic on `isCorrect`.

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: FAIL

- [ ] **Step 3: Enhance `sentenceView` in `ReflexBlitzCardView`**

Update `sentenceView` in `ReflexBlitzCardView.swift`:
- When `isCorrect`: Format the sentence with the prefix, the target word highlighted with `.vocabMint` and bold serif, and suffix, rather than abruptly changing the entire sentence string, providing a clear visual representation of the filled word.
- Ensure the IPA badge appears smoothly below with `.vocabMint.opacity(0.14)` background.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "feat(ui): enhance sentence cloze slot reveal on correct answer in ReflexBlitzCardView"
```

---

### Task 5: End-to-End Regression Verification & Polish

**Files:**
- Test: All Reflex Drill tests and app test suite

- [ ] **Step 1: Run full test suite**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests`
Expected: ALL PASS

- [ ] **Step 2: Commit final verification**

```bash
git commit --allow-empty -m "chore(reflex): complete verification of reflex blitz audio and UX improvements"
```
