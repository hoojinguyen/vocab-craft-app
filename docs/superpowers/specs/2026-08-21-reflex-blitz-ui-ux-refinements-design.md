# Reflex Blitz UI, UX, and Audio Refinements Design

## Overview
This document specifies the technical design to refine UI/UX consistency, audio routing, multisensory feedback, and render performance in the **Reflex Blitz** drill feature of VocabCraftApp.

---

## 1. Problem Statements & Goals

1. **Header Segmented Progress Bar Colors:**
   - *Problem:* Past question segments in `ReflexBlitzHeaderView` display a single accent color (`vocabHeroAccent`) regardless of whether the user answered correctly or incorrectly.
   - *Goal:* Render past segments in green (`vocabMint`) for correct answers and coral red (`vocabCoral`) for incorrect/timeout attempts.

2. **Listening Mode TTS Over-speaking:**
   - *Problem:* In Listening Mode (`.listening`), the target lemma is already spoken when the card loads. When the user picks a wrong answer or the timer expires, `handleTimeout()` triggers TTS again, causing redundant, repetitive audio playback.
   - *Goal:* Suppress automatic TTS replay on incorrect attempts or timeouts in Listening Mode, relying instead on the user-initiated "Nghe lại phát âm" replay button.

3. **Headphone / Bluetooth Microphone Input Failure in Speech Drill:**
   - *Problem:* When users connect Bluetooth headphones (AirPods, Bluetooth headsets) or wired headsets, speech recognition fails to capture spoken voice.
   - *Goal:* Correctly route audio input to external microphones, handle `AVAudioSession` route changes dynamically, and ensure audio buffer formats match speech recognition requirements.

4. **Multisensory Error Feedback (Haptic + Sound + Visual Shake):**
   - *Problem:* Choosing an incorrect option or timing out lacks sensory and visual feedback, making the response feel abrupt and unclear.
   - *Goal:* Provide a polite, non-punitive wrong answer sound effect, tactile haptic feedback (`.error` / `.impact`), and a subtle horizontal card shake animation.

5. **Countdown Timer Stutter & High-Frequency View Re-renders:**
   - *Problem:* `ReflexBlitzViewModel` ticks every 100ms via `Task.sleep`, mutating `@Observable` properties (`elapsedTimeMs`, `fractionRemaining`) 10 times per second. This triggers continuous MainActor body re-evaluations (including Regex parsing and view rebuilding), causing visual stutter on ProMotion (120Hz) displays and consuming unnecessary CPU/battery.
   - *Goal:* Decouple the visual countdown bar using SwiftUI continuous animations or `TimelineView`, and transition ViewModel timing to discrete milestone tasks (hint trigger, timeout trigger).

6. **Inconsistent Close Button Positioning:**
   - *Problem:* The close button is on the top-right in `ReflexBlitzModeSelectionView`, but on the top-left in `ReflexBlitzHeaderView`.
   - *Goal:* Unify the close button to the **top-left (Top-Leading)** across both screens according to Apple HIG drill flow guidelines.

---

## 2. Detailed Technical Design

### Feature 1: Header Segmented Progress Bar History
- **Data Flow:**
  - `ReflexBlitzViewModel` maintains `attempts: [ReflexBlitzAttempt]`.
  - Pass `attempts` (or `attemptResults: [Bool]`) into `ReflexBlitzHeaderView`.
- **Segment Color Logic:**
  ```swift
  private func segmentColor(for index: Int) -> Color {
      if index < attempts.count {
          return attempts[index].isCorrect ? Color.vocabMint : Color.vocabCoral
      } else if index == currentIndex {
          return Color.vocabHeroAccent
      } else {
          return Color.vocabHairline.opacity(0.4)
      }
  }
  ```
- **Accessibility:**
  - Update `accessibilityLabel` for progress to indicate completed score (e.g., "Tiến độ: từ 3 trên 10, đúng 2, sai 1").

---

### Feature 2: Listening Mode TTS Behavior
- **Timeout & Selection Handling in `ReflexBlitzViewModel`:**
  - In `handleTimeout()`:
    ```swift
    if selectedMode != .listening {
        ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")
    }
    ```
  - In `selectOption(_ option:)`:
    - Only play success chime for correct answers.
    - Do not trigger TTS playback for incorrect options in Listening Mode. The reviewed card retains the dedicated `onReplayAudio` speaker button.

---

### Feature 3: Bluetooth & Headset Audio Routing in `ContinuousReflexSpeechService`
- **Audio Session Category & Options:**
  - Ensure category is set to `.playAndRecord` with options:
    `[.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]` (or `.allowBluetoothHFP` where available).
- **Route Change Handling:**
  - Register `AVAudioSession.routeChangeNotification` observer.
  - When route changes (e.g. `AVAudioSessionRouteChangeReason.newDeviceAvailable` or `.oldDeviceUnavailable`):
    - Restart audio engine tap with the new hardware format if active.
- **Engine Tap Installation & Format Check:**
  - Call `inputNode.removeTap(onBus: 0)` prior to `installTap`.
  - Validate `recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0`.
  - Call `audioEngine.prepare()` before `audioEngine.start()`.

---

### Feature 4: Multisensory Error Feedback & Card Shake
1. **Sound Effect:**
   - In `SoundEffectServiceProtocol`, add `func playIncorrectChime()`.
   - Implement `playIncorrectChime()` using `AudioServicesPlaySystemSound(1053)` (or 1073 - soft negative cue) on iOS.
   - Call `soundEffectService.playIncorrectChime()` in `ReflexBlitzViewModel` when:
     - `selectOption` receives an incorrect option.
     - `submitTypingAnswer` receives an incorrect input (or on timeout).
2. **Haptic Feedback:**
   - In `ReflexBlitzView`, add sensory feedback modifier:
     ```swift
     .sensoryFeedback(.error, trigger: isReviewedIncorrect) { _, isIncorrect in isIncorrect }
     ```
3. **Card Shake Animation:**
   - In `ReflexBlitzCardView`, add a `@State private var shakeOffset: CGFloat = 0`.
   - When an incorrect answer or timeout occurs, trigger a spring shake effect:
     ```swift
     withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
         shakeOffset = 6
     }
     DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
         shakeOffset = 0
     }
     ```

---

### Feature 5: Smooth 120Hz Countdown Bar & Performance Optimization
- **SwiftUI View Animation:**
  - `ReflexBlitzHeaderView` countdown bar is animated smoothly using SwiftUI's animation engine from `1.0` to `0.0` over `timeLimitSeconds` whenever `currentIndex` changes.
  - Alternatively, calculate progress via `TimelineView(.animation)` or a progress view anchored to `wordStartTime`.
- **ViewModel Stopwatch Optimization:**
  - Replace the 100ms busy loop with discrete timers:
    - `hintTask`: `Task.sleep(for: .seconds(hintThreshold))` -> sets `showHint = true`.
    - `timeoutTask`: `Task.sleep(for: .seconds(timeLimitSeconds))` -> calls `handleTimeout()`.
  - Retain `elapsedTimeMs` calculation at the exact moment of user answer (`Date().timeIntervalSince(wordStartTime)`), preserving millisecond precision without continuous polling.
  - This eliminates 10 view invalidations per second, ensuring zero frame drops.

---

### Feature 6: Unified Top-Left Close Button Alignment
- **`ReflexBlitzModeSelectionView`:**
  - Change top bar layout from trailing close button to leading close button:
    ```swift
    HStack {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.vocabInk)
                .frame(width: 36, height: 36)
                .background(Color.vocabMuted.opacity(0.12))
                .clipShape(Circle())
        }
        Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.top, 16)
    ```
- Both `ReflexBlitzModeSelectionView` and `ReflexBlitzHeaderView` now place the close button at Top-Left (Leading), standardizing thumb muscle memory.

---

## 3. Files Impacted

| File | Component | Description |
|------|-----------|-------------|
| `VocabCraftApp/Core/Audio/SoundEffectService.swift` | Core / Audio | Add `playIncorrectChime()` for soft error tone |
| `VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift` | Reflex Drill / Audio | Handle route changes, Bluetooth mic input format, tap safety |
| `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift` | Reflex Drill / ViewModel | Pass attempts to header, discrete milestone timers, suppress listening timeout TTS |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift` | Reflex Drill / Views | Segment colors based on attempts history, smooth linear timer animation |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift` | Reflex Drill / Views | Add card shake animation on wrong answer/timeout |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift` | Reflex Drill / Views | Move close button to Top-Left |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift` | Reflex Drill / Views | Add `.sensoryFeedback(.error)` for wrong answers |
| `VocabCraftAppTests/Features/ReflexDrill/...` | Tests | Unit tests for updated timer behavior, attempts history, and sound effects |

---

## 4. Verification Plan

### Automated Tests
- Run unit test suite:
  ```bash
  xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests
  ```

### Manual Verification
1. **Header Colors:** Answer 1 correct, 1 wrong, 1 timeout -> verify green, red, red segments.
2. **Listening Mode:** Pick wrong option / timeout -> verify no duplicate TTS audio.
3. **Headphones:** Connect Bluetooth/wired headset -> verify speech recognition responds to spoken words.
4. **Error Sensory Feedback:** Select wrong option -> verify subtle chime, error haptic, and card shake.
5. **Timer Smoothness:** Observe countdown bar -> verify fluid 60/120fps motion with zero UI stutter.
6. **Close Button:** Verify close button is at Top-Left in Mode Selection, Header, and drilling views.
