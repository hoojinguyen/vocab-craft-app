# Reflex Blitz UI, UX, and Audio Refinements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine Reflex Blitz drill with segmented header colors for correct/incorrect attempts, suppress duplicate listening TTS, fix headphone audio input routing, add polite multisensory error feedback with card shake, optimize timer to 120Hz without MainActor lag, and unify the close button to the top-left.

**Architecture:** 
1. `SoundEffectService`: Extended with `playIncorrectChime()` for soft error feedback.
2. `ContinuousReflexSpeechService`: Audio session routing observer and safe tap format handling for headphones.
3. `ReflexBlitzViewModel`: Milestone-based discrete timer, attempts history tracking, listening mode TTS suppression.
4. `ReflexBlitzHeaderView`, `ReflexBlitzCardView`, `ReflexBlitzModeSelectionView`: Dynamic segment colors, smooth countdown animation, card shake, and unified top-left close button.

**Tech Stack:** Swift 6, SwiftUI, AVFoundation, SpeechKit, XCTest

**Spec:** `docs/superpowers/specs/2026-08-21-reflex-blitz-ui-ux-refinements-design.md`

## Global Constraints
- Target iOS 17.0+
- Zero MainActor frame drops or unnecessary view body invalidations
- Maintain 100% test passing across all existing Reflex Blitz unit tests

---

### Task 1: Extend SoundEffectService with Incorrect Chime

**Files:**
- Modify: `VocabCraftApp/Core/Audio/SoundEffectService.swift`
- Modify: `VocabCraftAppTests/ReflexDrillViewModelTests.swift`
- Test: `VocabCraftAppTests/Core/Audio/SoundEffectServiceTests.swift` (or `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`)

**Interfaces:**
- Produces: `SoundEffectServiceProtocol.playIncorrectChime()`

- [ ] **Step 1: Write the failing test**

Add test in `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`:
```swift
func testIncorrectOptionTriggersIncorrectChime() {
    viewModel.selectMode(.multipleChoice)
    viewModel.beginSessionDirectly()
    guard let wrongOption = viewModel.currentOptions.first(where: { !$0.isCorrect }) else {
        XCTFail("No wrong option found")
        return
    }
    viewModel.selectOption(wrongOption)
    XCTAssertEqual(mockSound.playIncorrectChimeCallCount, 1)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests/testIncorrectOptionTriggersIncorrectChime`
Expected: FAIL (compilation error: `playIncorrectChime` / `playIncorrectChimeCallCount` not defined).

- [ ] **Step 3: Implement SoundEffectServiceProtocol and SoundEffectService**

Update `VocabCraftApp/Core/Audio/SoundEffectService.swift`:
```swift
public protocol SoundEffectServiceProtocol: Sendable {
    func playSuccessChime()
    func playIncorrectChime()
}

public final class SoundEffectService: SoundEffectServiceProtocol, @unchecked Sendable {
    public static let shared = SoundEffectService()

    public init() {}

    public func playSuccessChime() {
        #if os(iOS)
        AudioServicesPlaySystemSound(1054)
        #endif
    }

    public func playIncorrectChime() {
        #if os(iOS)
        AudioServicesPlaySystemSound(1053)
        #endif
    }
}
```
Update `MockSoundEffectService` in `VocabCraftAppTests/ReflexDrillViewModelTests.swift` and any other mock occurrences:
```swift
final class MockSoundEffectService: SoundEffectServiceProtocol, @unchecked Sendable {
    var playSuccessChimeCallCount: Int = 0
    var playIncorrectChimeCallCount: Int = 0

    func playSuccessChime() {
        playSuccessChimeCallCount += 1
    }

    func playIncorrectChime() {
        playIncorrectChimeCallCount += 1
    }
}
```

- [ ] **Step 4: Update ReflexBlitzViewModel to trigger playIncorrectChime**

In `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`:
In `selectOption`:
```swift
if isCorrect {
    soundEffectService.playSuccessChime()
    comboStreak += 1
    if comboStreak > maxComboStreak {
        maxComboStreak = comboStreak
    }
} else {
    soundEffectService.playIncorrectChime()
    comboStreak = 0
}
```
In `handleTimeout`:
```swift
soundEffectService.playIncorrectChime()
```

- [ ] **Step 5: Run tests and verify they pass**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add VocabCraftApp/Core/Audio/SoundEffectService.swift VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/
git commit -m "feat(audio): add playIncorrectChime to SoundEffectService and trigger in ReflexBlitz"
```

---

### Task 2: Headphone / Bluetooth Audio Routing in ContinuousReflexSpeechService

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift`

**Interfaces:**
- Consumes: `AVAudioSession.routeChangeNotification`, `AVAudioSession.sharedInstance()`
- Produces: Robust audio session configuration with Bluetooth / external headphone input handling

- [ ] **Step 1: Write test for audio session route change and lifecycle safety**

In `VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift`:
```swift
func testServiceSurvivesRouteChangeNotification() {
    let service = ContinuousReflexSpeechService()
    service.startSession(contextualPhrases: ["hello"])
    NotificationCenter.default.post(
        name: AVAudioSession.routeChangeNotification,
        object: nil,
        userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue]
    )
    XCTAssertTrue(service.isSessionActive)
    service.stopSession()
}
```

- [ ] **Step 2: Run test to verify behavior**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ContinuousReflexSpeechServiceTests`

- [ ] **Step 3: Implement route change observer and tap safety in ContinuousReflexSpeechService**

In `VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift`:
1. Add `private var routeChangeObserver: (any NSObjectProtocol)?`
2. In `init()`, register observer for `AVAudioSession.routeChangeNotification`.
3. In `startAudioStream()`:
   - Configure category `.playAndRecord` with options `[.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]`.
   - Remove existing tap before installing: `inputNode.removeTap(onBus: 0)`.
   - Call `engine.prepare()` before `engine.start()`.
4. In `stopSession()`:
   - Clean up tap, stop engine, deactivate audio session safely.

- [ ] **Step 4: Run tests and verify they pass**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ContinuousReflexSpeechServiceTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift
git commit -m "fix(audio): handle route changes and bluetooth headphone routing in ContinuousReflexSpeechService"
```

---

### Task 3: ReflexBlitzViewModel: Listening Mode TTS Suppression & Discrete Timer

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- Produces: `ReflexBlitzViewModel.attempts` history tracking, suppression of timeout TTS in `.listening` mode, discrete timer tasks (`hintTask`, `timeoutTask`).

- [ ] **Step 1: Write failing tests for listening timeout TTS suppression and attempts tracking**

In `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`:
```swift
func testListeningModeTimeoutDoesNotSpeakAgain() {
    viewModel.selectMode(.listening)
    viewModel.beginSessionDirectly()
    // Initial speak count is 1 for listening mode opening
    XCTAssertEqual(mockTTS.speakCallCount, 1)

    viewModel.handleTimeout()
    // Speak count should STILL be 1 (not 2)
    XCTAssertEqual(mockTTS.speakCallCount, 1, "Listening mode timeout should not re-speak the lemma")
}

func testAttemptsHistoryTracksCorrectAndIncorrectOrder() {
    viewModel.selectMode(.multipleChoice)
    viewModel.beginSessionDirectly()
    
    // Word 0: Correct
    let correctOpt = viewModel.currentOptions.first(where: { $0.isCorrect })!
    viewModel.selectOption(correctOpt)
    XCTAssertEqual(viewModel.attempts.count, 1)
    XCTAssertTrue(viewModel.attempts[0].isCorrect)
    
    // Word 1: Timeout
    viewModel.advanceToNextWord()
    viewModel.handleTimeout()
    XCTAssertEqual(viewModel.attempts.count, 2)
    XCTAssertFalse(viewModel.attempts[1].isCorrect)
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests/testListeningModeTimeoutDoesNotSpeakAgain`
Expected: FAIL (mockTTS.speakCallCount is 2).

- [ ] **Step 3: Update ReflexBlitzViewModel**

In `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`:
1. In `handleTimeout()`:
   ```swift
   if selectedMode != .listening {
       ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")
   }
   ```
2. In `startStopwatch()`:
   - Implement discrete milestone tasks:
   ```swift
   private var hintTimerTask: Task<Void, Never>?
   private var timeoutTimerTask: Task<Void, Never>?

   private func startStopwatch() {
       hintTimerTask?.cancel()
       timeoutTimerTask?.cancel()
       sessionTimerTask?.cancel()

       let hintSeconds = selectedMode == .typing ? 4.5 : 3.5
       let limitSeconds = selectedMode.timeLimitSeconds

       hintTimerTask = Task { @MainActor [weak self] in
           try? await Task.sleep(for: .seconds(hintSeconds))
           guard let self = self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
           self.showHint = true
       }

       timeoutTimerTask = Task { @MainActor [weak self] in
           try? await Task.sleep(for: .seconds(limitSeconds))
           guard let self = self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
           self.handleTimeout()
       }
   }
   ```
3. Update `cancelSession()` and `loadWord(at:)` to cancel `hintTimerTask` and `timeoutTimerTask`.
4. Ensure `elapsedTimeMs` is accurately calculated from `wordStartTime` whenever `selectOption`, `submitTypingAnswer`, `handleSpokenMatch`, or `handleTimeout` is invoked.

- [ ] **Step 4: Run tests and verify they pass**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift
git commit -m "feat(reflex): suppress listening timeout TTS and optimize stopwatch tasks"
```

---

### Task 4: ReflexBlitzHeaderView: Segment Colors & Smooth Countdown Bar

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Consumes: `attempts: [ReflexBlitzAttempt]`
- Produces: Dynamic segment coloring (green/coral/purple) and smooth countdown progress bar

- [ ] **Step 1: Write tests for header segment colors based on attempts history**

In `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`:
```swift
@MainActor
func testHeaderViewSegmentColorsWithAttemptsHistory() {
    let attempts = [
        ReflexBlitzAttempt(wordId: 1, lemma: "a", pos: "", ipa: "", definitionVi: "", responseTimeMs: 1000, usedHint: false, isCorrect: true),
        ReflexBlitzAttempt(wordId: 2, lemma: "b", pos: "", ipa: "", definitionVi: "", responseTimeMs: 2000, usedHint: false, isCorrect: false)
    ]
    let header = ReflexBlitzHeaderView(
        currentIndex: 2,
        totalCount: 5,
        comboStreak: 0,
        attempts: attempts,
        onClose: {}
    )
    XCTAssertEqual(header.segmentColor(for: 0), Color.vocabMint)
    XCTAssertEqual(header.segmentColor(for: 1), Color.vocabCoral)
    XCTAssertEqual(header.segmentColor(for: 2), Color.vocabHeroAccent)
    XCTAssertEqual(header.segmentColor(for: 3), Color.vocabHairline.opacity(0.4))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests/testHeaderViewSegmentColorsWithAttemptsHistory`

- [ ] **Step 3: Update ReflexBlitzHeaderView & ReflexBlitzView**

In `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift`:
1. Add property `public let attempts: [ReflexBlitzAttempt]` (default `[]`).
2. Update `segmentColor(for index: Int) -> Color`:
   ```swift
   public func segmentColor(for index: Int) -> Color {
       if index < attempts.count {
           return attempts[index].isCorrect ? Color.vocabMint : Color.vocabCoral
       } else if index == currentIndex {
           return Color.vocabHeroAccent
       } else {
           return Color.vocabHairline.opacity(0.4)
       }
   }
   ```
3. Update countdown bar with smooth linear animation:
   ```swift
   GeometryReader { geo in
       ZStack(alignment: .leading) {
           Capsule()
               .fill(Color.vocabHairline.opacity(0.3))
               .frame(height: 4.5)

           Capsule()
               .fill(timerBarColor)
               .frame(
                   width: max(0, min(geo.size.width, geo.size.width * CGFloat(fractionRemaining))),
                   height: 4.5
               )
               .shadow(color: timerBarColor.opacity(timerStage == .urgent ? 0.6 : 0.25), radius: 5, x: 0, y: 0)
               .animation(.linear(duration: 0.1), value: fractionRemaining)
               .animation(.easeInOut(duration: 0.25), value: timerStage)
       }
   }
   ```
4. In `ReflexBlitzView.swift`, pass `attempts: viewModel.attempts` to `ReflexBlitzHeaderView`.

- [ ] **Step 4: Run tests and verify they pass**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "feat(ui): add attempts history segment coloring to ReflexBlitzHeaderView"
```

---

### Task 5: Sensory Error Feedback & Card Shake Animation

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Produces: Subtle card horizontal shake on wrong choice / timeout, `.sensoryFeedback(.error)` on reviewed incorrect.

- [ ] **Step 1: Add card shake animation in ReflexBlitzCardView**

In `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`:
1. Add `@State private var shakeOffset: CGFloat = 0`.
2. Attach `.offset(x: shakeOffset)` to the card body.
3. In `.onChange(of: isReviewed)`:
   ```swift
   .onChange(of: isReviewed) { _, reviewed in
       if reviewed && !isResultCorrect {
           withAnimation(.spring(response: 0.15, dampingFraction: 0.2, blendDuration: 0.15)) {
               shakeOffset = 6
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
               shakeOffset = 0
           }
       }
   }
   ```

- [ ] **Step 2: Add sensory feedback in ReflexBlitzView**

In `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`:
Add:
```swift
.sensoryFeedback(.error, trigger: isReviewedIncorrect) { _, isIncorrect in isIncorrect }
```
Where `isReviewedIncorrect` is computed as:
```swift
private var isReviewedIncorrect: Bool {
    if case .reviewed(let result) = viewModel.cardPhase {
        return !result.isCorrect
    }
    return false
}
```

- [ ] **Step 3: Run tests to verify view compilation and component tests**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift
git commit -m "feat(ui): add card shake animation and sensory error feedback on incorrect answers"
```

---

### Task 6: Unify Close Button to Top-Left in Mode Selection

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Produces: Top-Left close button matching `ReflexBlitzHeaderView` and Apple HIG.

- [ ] **Step 1: Update ReflexBlitzModeSelectionView Top Bar**

In `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift`:
Replace the top dismiss bar with:
```swift
// Top Dismiss Bar (Unified Top-Left)
HStack {
    Button(action: onDismiss) {
        Image(systemName: "xmark")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.vocabInk)
            .frame(width: 36, height: 36)
            .background(Color.vocabMuted.opacity(0.12))
            .clipShape(Circle())
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
    .buttonStyle(BentoCardButtonStyle())
    .accessibilityLabel("Đóng chọn chế độ")

    Spacer()
}
.padding(.horizontal, 20)
.padding(.top, 16)
```

- [ ] **Step 2: Run component tests**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift
git commit -m "fix(ui): align close button to top-left in ReflexBlitzModeSelectionView"
```

---

### Task 7: Full Test Suite & Build Verification

**Files:**
- Verify all modified files
- Run all test targets

- [ ] **Step 1: Run complete Reflex Drill test suite**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/Features/ReflexDrill`
Expected: All tests PASS with 0 failures.

- [ ] **Step 2: Build app for release / simulator**

Run: `xcodebuild clean build -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro"`
Expected: BUILD SUCCEEDED with 0 errors.

- [ ] **Step 3: Final commit & tag if needed**

```bash
git commit --allow-empty -m "chore: verify all reflex blitz UI/UX refinement tests pass"
```
