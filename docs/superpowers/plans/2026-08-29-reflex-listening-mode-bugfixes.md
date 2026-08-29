# Reflex Listening Mode Bugfixes & Architecture Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all audio lifecycle, timer synchronization, 3D flip card answer leak, and continuous waveform visualizer bugs in Reflex Listening Mode across Blitz and Mixed Reflex Drills.

**Architecture:** Centralize all audio playback authority into the ViewModel, run a continuous waveform during active countdown without local timer tasks, synchronize 3-stage hint timers (1.8s POS badge & auto-replay, 3.0s 50/50 distractor elimination & auto-replay, 5.5s timeout), enforce explicit `.id` view identity to prevent card flip-back spoilers, and normalize TTS speech rate to 1.0x.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit, Observation, AVFoundation, Swift Testing.

## Global Constraints

- Zero hardcoded English/Vietnamese strings; all text must use `AppStrings.ReflexBlitz` and `Localizable.xcstrings`.
- Zero raw styling; all tokens must come from `CraftUIKit` (`theme.colors`, `theme.typography`, `theme.spacing`, `theme.radii`, `theme.depths`).
- CraftUIKit-First: Reuse `CraftFlipCard`, `CraftWaveformView`, `CraftChoiceCard`, `CraftSpeakerButton`, `CraftBadge`.
- Zero compiler warnings, zero SwiftLint warnings, 100% test pass rate.

---

### Task 1: Timer Progression & Plan Generation Verification

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Core/Models/ReflexMode.swift:48-71`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexModeTests.swift`

**Interfaces:**
- Consumes: `ReflexMode.hintStage(forElapsedTimeMs:)`
- Produces: Correct hint stage integer (0, 1, 2, 3) for listening mode at 1800ms, 3000ms, 5500ms.

- [ ] **Step 1: Write the failing test for ReflexMode listening hint stages**

```swift
import Testing
@testable import VocabCraftApp

@Suite("ReflexMode Listening Tests")
struct ReflexModeListeningTests {
    @Test("Verifies Listening mode hint stage thresholds")
    func testListeningHintStages() {
        let mode = ReflexMode.listening
        #expect(mode.timeLimitSeconds == 5.5)
        #expect(mode.hintStage(forElapsedTimeMs: 0) == 0)
        #expect(mode.hintStage(forElapsedTimeMs: 1799) == 0)
        #expect(mode.hintStage(forElapsedTimeMs: 1800) == 1)
        #expect(mode.hintStage(forElapsedTimeMs: 2999) == 1)
        #expect(mode.hintStage(forElapsedTimeMs: 3000) == 2)
        #expect(mode.hintStage(forElapsedTimeMs: 5499) == 2)
        #expect(mode.hintStage(forElapsedTimeMs: 5500) == 3)
    }
}
```

- [ ] **Step 2: Update `ReflexMode.swift` listening hint stage thresholds**

Update `VocabCraftApp/Features/Reflex/Core/Models/ReflexMode.swift`:
```swift
        case .listening:
            if elapsed >= 5500 { return 3 }
            if elapsed >= 3000 { return 2 }
            if elapsed >= 1800 { return 1 }
            return 0
```

- [ ] **Step 3: Run test to verify it passes**

Run: `swift test --filter ReflexModeListeningTests`
Expected: PASS

- [ ] **Step 4: Commit Task 1**

```bash
git add VocabCraftApp/Features/Reflex/Core/Models/ReflexMode.swift VocabCraftAppTests/Features/Reflex/ReflexModeTests.swift
git commit -m "fix(reflex): update listening mode hint stage progression thresholds"
```

---

### Task 2: ViewModel Audio Lifecycle, Hint Timers & Speed Normalization

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift:316-394, 458-461, 608-611`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelListeningTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzViewModel`, `TextToSpeechProtocol`, `ReflexMode.listening`
- Produces: Proper 3-stage timer execution for `.listening`, single audio trigger per stage, natural 1.0x speech speed, silent back face on review.

- [ ] **Step 1: Write the failing tests for ViewModel listening timers and audio behavior**

```swift
import Testing
@testable import VocabCraftApp

@MainActor
@Suite("ReflexBlitzViewModel Listening Tests")
struct ReflexBlitzViewModelListeningTests {
    @Test("Simulates listening mode elapsed time and verifies hint progression")
    func testListeningHintProgression() {
        let mockTTS = MockTextToSpeechService()
        let vm = ReflexBlitzViewModel(
            words: ReflexBlitzWordItem.defaultStarterWords,
            continuousSpeechService: MockContinuousSpeechService(),
            ttsService: mockTTS,
            evaluateSRSUseCase: MockEvaluateSRSUseCase(),
            soundEffectService: MockSoundEffectService()
        )
        vm.startDrillSession(mode: .listening)
        
        #expect(vm.hintStage == 0)
        
        vm.simulateElapsedTime(ms: 1800)
        #expect(vm.hintStage == 1)
        
        vm.simulateElapsedTime(ms: 3000)
        #expect(vm.hintStage == 2)
    }

    @Test("Verifies answer submission in listening mode does not auto-speak on review flip")
    func testListeningAnswerSubmissionMuteReview() {
        let mockTTS = MockTextToSpeechService()
        let vm = ReflexBlitzViewModel(
            words: ReflexBlitzWordItem.defaultStarterWords,
            continuousSpeechService: MockContinuousSpeechService(),
            ttsService: mockTTS,
            evaluateSRSUseCase: MockEvaluateSRSUseCase(),
            soundEffectService: MockSoundEffectService()
        )
        vm.startDrillSession(mode: .listening)
        let initialSpeakCount = mockTTS.speakCallCount
        
        if let option = vm.currentOptions.first {
            vm.selectOption(option)
        }
        
        // Should not have spoken again during selectOption review flip
        #expect(mockTTS.speakCallCount == initialSpeakCount)
    }
}
```

- [ ] **Step 2: Update `ReflexBlitzViewModel.swift`**

1. In `loadWord(at:)`:
```swift
        if selectedMode == .listening {
            ttsService.speak(text: word.lemma, rate: 1.0, locale: "en-US")
        }
```
2. In `startStopwatch()`:
Add explicit branch for `.listening`:
```swift
        if selectedMode == .multipleChoice {
            hintTimerTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(1600))
                guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
                self.hintStage = max(self.hintStage, 1)
            }
            hintStage2Task = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(2500))
                guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
                self.hintStage = max(self.hintStage, 2)
            }
            hintStage3Task = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(3400))
                guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
                self.hintStage = max(self.hintStage, 3)
            }
        } else if selectedMode == .listening {
            hintTimerTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(1800))
                guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
                self.hintStage = max(self.hintStage, 1)
                self.speakCurrentWord()
            }
            hintStage2Task = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(3000))
                guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
                self.hintStage = max(self.hintStage, 2)
                self.speakCurrentWord()
            }
        } else {
            let hintSeconds = selectedMode == .typing ? 4.5 : 3.5
            hintTimerTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(hintSeconds))
                guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
                self.hintStage = 1
            }
        }
```
3. In `speakLemma(_:)`:
```swift
    public func speakLemma(_ lemma: String) {
        ttsService.speak(text: lemma, rate: 1.0, locale: "en-US")
    }
```
4. In `simulateElapsedTime(ms:)`:
```swift
        if selectedMode == .multipleChoice {
            if ms >= 1600 { self.hintStage = max(self.hintStage, 1) }
            if ms >= 2500 { self.hintStage = max(self.hintStage, 2) }
            if ms >= 3400 { self.hintStage = max(self.hintStage, 3) }
        } else if selectedMode == .listening {
            if ms >= 1800 { self.hintStage = max(self.hintStage, 1) }
            if ms >= 3000 { self.hintStage = max(self.hintStage, 2) }
        } else {
            let hintThreshold = selectedMode == .typing ? 4500 : 3500
            if ms >= hintThreshold {
                self.hintStage = 1
            }
        }
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `swift test --filter ReflexBlitzViewModelListeningTests`
Expected: PASS

- [ ] **Step 4: Commit Task 2**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelListeningTests.swift
git commit -m "fix(reflex): synchronize listening mode hint timers, audio auto-replay, and speech rate"
```

---

### Task 3: Refactor ReflexListeningModeView for Continuous Waveform & Stable Layout

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexListeningModeView.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexOtherModesTests.swift`

**Interfaces:**
- Consumes: `ReflexListeningModeView`, `CraftWaveformView`, `CraftFlipCard`, `CraftChoiceCard`, `CraftSpeakerButton`
- Produces: Clean listening view without local timer tasks, continuous waveform during countdown, `minHeight: 220` stability, interactive speaker on back face.

- [ ] **Step 1: Update unit tests in `ReflexOtherModesTests.swift`**

Verify `ReflexListeningModeView` initializers, continuous active states, and distractor elimination at stage 2.

- [ ] **Step 2: Refactor `ReflexListeningModeView.swift`**

1. Remove `@State private var isAudioPlaying: Bool = false` and `@State private var audioTimerTask: Task<Void, Never>?`.
2. Remove `triggerAudioPlayback()`, `.onAppear`, `.onDisappear`, and `.onChange(of: hintStage)` since the ViewModel authoritative audio controls playback.
3. Pass `isRecording: !isReviewed` to `CraftWaveformView`:
```swift
    private var frontPromptFace: some View {
        VStack(spacing: theme.spacing.md) {
            CraftWaveformView(
                barCount: 16,
                spacing: theme.spacing.xs,
                minHeight: 6,
                maxHeight: 40,
                barWidth: 4,
                isRecording: !isReviewed,
                activeColor: theme.colors.brandPrimary
            )
            .frame(height: 40)
            .accessibilityHidden(true)

            if hintStage >= 1 && !word.cleanPos.isEmpty {
                CraftBadge(
                    word.cleanPos,
                    variant: .subtle,
                    tone: .neutral,
                    size: .sm,
                    shape: .capsule
                )
                .transition(.scale.combined(with: .opacity))
            }

            CraftText(
                AppStrings.ReflexBlitz.listeningInstructionText,
                style: .caption,
                color: theme.colors.textMuted,
                textAlignment: .center
            )
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .padding(.vertical, theme.spacing.xs)
    }
```
4. Set back face `minHeight: 220` and support speaker replay action.
```swift
    private var backResultFace: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .center) {
                CraftText(
                    word.lemma,
                    style: .titleLargeSerif,
                    color: theme.colors.textPrimary,
                    textAlignment: .leading
                )

                Spacer(minLength: theme.spacing.sm)

                if let onReplayAudio {
                    CraftSpeakerButton(
                        variant: .subtle,
                        size: .md,
                        isPlaying: false,
                        label: nil,
                        action: onReplayAudio
                    )
                }
            }
            // remaining rows...
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
    }
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `swift test --filter testListeningModeViewFullStates`
Expected: PASS

- [ ] **Step 4: Commit Task 3**

```bash
git add VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexListeningModeView.swift VocabCraftAppTests/Features/Reflex/ReflexOtherModesTests.swift
git commit -m "refactor(reflex): streamline ReflexListeningModeView with continuous waveform and layout stability"
```

---

### Task 4: Spoiler-Free Card Navigation & View Identity Integration

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift:181-184, 290-314`
- Modify: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift:142-143, 226-250`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewIntegrationTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzView`, `MixedReflexDrillView`, `cardContent(for:)`
- Produces: Zero-spoiler card mounting with `.id("\(currentIndex)-\(word.id)")` and clean transitions.

- [ ] **Step 1: Write integration test for card view identity in `ReflexBlitzViewIntegrationTests.swift`**

Verify that advancing to the next word mounts a clean card instance without reverse-rotation glitch.

- [ ] **Step 2: Update `ReflexBlitzView.swift` and `MixedReflexDrillView.swift`**

In `ReflexBlitzView.swift`:
```swift
                if let word = viewModel.currentWord {
                    cardContent(for: word)
                        .id("\(viewModel.currentWordIndex)-\(word.id)")
                        .transition(.opacity)
                }
```
In `listeningCard(for:)`:
Remove redundant `onPlayAudio` since `loadWord(at:)` and hint timers manage playback. Keep `onReplayAudio: { viewModel.speakCurrentWord() }`.

In `MixedReflexDrillView.swift`:
```swift
                challengeCard(for: currentItem)
                    .id("\(viewModel.currentIndex)-\(currentItem.id)")
                    .transition(.opacity)
```
In `listeningChallengeCard(for:...)`:
Keep `onReplayAudio: { viewModel.playAudioForCurrentWord() }` and remove redundant `onPlayAudio`.

- [ ] **Step 3: Run integration tests to verify they pass**

Run: `swift test --filter ReflexBlitzViewIntegrationTests`
Expected: PASS

- [ ] **Step 4: Commit Task 4**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift VocabCraftAppTests/Features/Reflex/ReflexBlitzViewIntegrationTests.swift
git commit -m "fix(reflex): eliminate flip card spoiler leak with explicit view identity and clean transitions"
```

---

### Task 5: Full Test Suite Verification & Quality Gate

**Files:**
- Entire codebase

**Interfaces:**
- Swift Testing test suites, SwiftLint, compiler checks

- [ ] **Step 1: Run complete Reflex test suite**

Run: `swift test --filter Reflex`
Expected: 100% test pass rate

- [ ] **Step 2: Run SwiftLint check**

Run: `swiftlint`
Expected: 0 errors, 0 warnings

- [ ] **Step 3: Commit all remaining cleanups**

```bash
git status
git commit -m "chore(reflex): complete verification for listening mode bugfixes"
```
