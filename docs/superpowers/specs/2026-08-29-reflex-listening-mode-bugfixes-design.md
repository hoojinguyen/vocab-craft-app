# Reflex Listening Mode Bugfixes & Architecture Refinement Design Specification

## 1. Overview & Objectives

This design specification establishes the refined architecture, audio lifecycle, timer synchronization, and visual transition mechanisms for **Reflex Listening Mode** (`ReflexListeningModeView`), resolving runtime bugs encountered during device testing.

### Key Objectives:
1. **Single Authoritative Audio Source**: Eliminate audio double-triggering by centralizing question start and hint stage speech triggers strictly in the ViewModel, removing ad-hoc audio execution in view lifecycle hooks.
2. **Continuous Active Waveform**: Keep `CraftWaveformView` dynamically active throughout the active countdown phase (`isRecording: !isReviewed`), eliminating fragile local timer tasks and state de-synchronization.
3. **Spoiler-Free Card Transitions**: Prevent 3D flip card answer leaks during word advances by enforcing explicit view identities (`.id("\(currentIndex)-\(word.id)")`).
4. **Synchronized 3-Stage Hint Progression**: Align Blitz and Mixed Drill timers to standard listening progression (0.0s play $\rightarrow$ 1.8s POS badge & auto-replay $\rightarrow$ 3.0s 50/50 distractor elimination & auto-replay $\rightarrow$ 5.5s timeout).
5. **Natural Audio Playback Speed**: Standardize TTS speech rate to natural 1.0x baseline, eliminating sluggish robotic speech.
6. **Silent Consolidation Back Face with Interactive Speaker**: Keep back face audio silent upon review flip (Option B), enabling interactive replay with dynamic visual feedback when the user taps `CraftSpeakerButton`.

---

## 2. Audio & TTS Architecture

### 2.1 Single Authoritative Trigger Matrix

| Event / Phase | Trigger Location | Audio Action | Speech Rate | Waveform State |
| :--- | :--- | :--- | :--- | :--- |
| **Question Start (0.0s)** | `ViewModel.loadWord(at:)` / `startDrillItem` | Speaks `word.lemma` | 1.0x (Natural) | Active (`isRecording = true`) |
| **Stage 1 Hint (1.8s)** | `ViewModel.hintStage1Task` / timer | Speaks `word.lemma` + reveals POS badge | 1.0x (Natural) | Active (`isRecording = true`) |
| **Stage 2 Hint (3.0s)** | `ViewModel.hintStage2Task` / timer | Speaks `word.lemma` + eliminates distractor | 1.0x (Natural) | Active (`isRecording = true`) |
| **Answer Submit / Timeout (5.5s)** | `ViewModel.selectOption` / `handleTimeout` | Silent on flip | N/A | Inactive (`isRecording = false`) |
| **Manual Replay (Reviewed)** | User taps `CraftSpeakerButton` on Back Face | Speaks `word.lemma` | 1.0x (Natural) | Inactive (Speaker Button Animates) |

### 2.2 Speech Speed Normalization
In `ReflexBlitzViewModel`, replace all hardcoded `rate: 0.5` parameters with default normal speed `rate: 1.0` (or omit to inherit `TextToSpeechService` default `1.0`), ensuring `scaledRate = 0.5 * 1.0 = 0.5` (standard English speed).

---

## 3. UI & Component Architecture

### 3.1 `ReflexListeningModeView` Component Structure

```
                                  ┌─────────────────────────────┐
                                  │   ReflexListeningModeView   │
                                  └──────────────┬──────────────┘
                                                 │
                   ┌─────────────────────────────┴─────────────────────────────┐
                   │                                                           │
     ┌─────────────▼─────────────┐                               ┌─────────────▼─────────────┐
     │       CraftFlipCard       │                               │   listeningOptionsListView │
     │       (.tactile3D)        │                               │ (VStack of CraftChoiceCard)│
     └─────────────┬─────────────┘                               └───────────────────────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
┌────────▼────────┐ ┌────────▼────────┐
│ frontPromptFace │ │ backResultFace  │
│ (Active Stimulus│ │ (Reviewed Word  │
│    + Waveform)  │ │  Consolidation) │
└─────────────────┘ └─────────────────┘
```

#### Front Face (`frontPromptFace`):
- **Waveform Area**: `CraftWaveformView(isRecording: !isReviewed && !reduceMotion)` — runs continuously during active countdown without local timer tasks.
- **Stage 1 POS Badge**: `hintStage >= 1 && !word.cleanPos.isEmpty` renders `CraftBadge(word.cleanPos)` with spring transition.
- **Instruction Prompt**: `CraftText(AppStrings.ReflexBlitz.listeningInstructionText, style: .caption, color: theme.colors.textMuted)`.
- **Dimensions**: `frame(maxWidth: .infinity, minHeight: 220, alignment: .center)`.

#### Back Face (`backResultFace`):
- **Header Row**: `word.lemma` (`titleLargeSerif`) + `CraftSpeakerButton` (`variant: .subtle`, `size: .md`, `isPlaying: isSpeaking`, `action: onReplayAudio`).
- **Phonetics**: `word.ipa` (`caption`, `color: theme.colors.textMuted`).
- **Badges**: `CraftBadge(word.cleanPos)` + `CraftBadge(word.cleanLevel, tone: .warning)`.
- **Definition**: `word.definitionVi` (`titleMedium`, `color: theme.colors.textPrimary`).
- **Contextual Sentence**: `word.completedSentenceWithTargetWord` (`bodySerif`) + `word.exampleSentenceVi` (`caption`).
- **Dimensions**: `frame(maxWidth: .infinity, minHeight: 220, alignment: .center)`.

#### Options List (`listeningOptionsListView`):
- 4 `CraftChoiceCard`s rendered directly on canvas.
- **State Evaluation (`choiceState(for:)`)**:
  - `!isReviewed`: If `hintStage >= 2 && option.id == eliminatedOptionId` $\rightarrow$ `.disabled`, otherwise `.idle`.
  - `isReviewed`: Correct option $\rightarrow$ `.correct`, selected wrong option $\rightarrow$ `.wrong`, all other options $\rightarrow$ `.disabled`.
- **Interaction Guard**: Taps ignored when `isReviewed == true` or option is `.disabled`.

---

## 4. View Identity & Screen Integration

### 4.1 Spoiler-Free Card Navigation
In `ReflexBlitzView.swift` and `MixedReflexDrillView.swift`, assign explicit view identity to the card container:

```swift
if let word = viewModel.currentWord {
    cardContent(for: word)
        .id("\(viewModel.currentWordIndex)-\(word.id)")
        .transition(.opacity)
}
```

### 4.2 Lifecycle Guarantees
- Advancing to the next question immediately unmounts the previous reviewed card and mounts the new card in its resting front state (`isFlipped = false`, 0°).
- No reverse-rotation animation occurs, completely eliminating back-face answer leaks.
- All internal view states and animations initialize cleanly per word item.

---

## 5. Timer & Hint Synchronization Matrix

### 5.1 Progression Specifications
- **Mode Duration**: 5.5 seconds.
- **Stage 0 (0.0s – 1.8s)**: Audio played once, continuous waveform, all 4 options active.
- **Stage 1 (1.8s – 3.0s)**: Audio auto-replayed, POS badge displayed.
- **Stage 2 (3.0s – 5.5s)**: Audio auto-replayed, 1 distractor eliminated (`.disabled`).
- **Stage 3 / Timeout (5.5s)**: Triggers `handleTimeout()`, flips to back face consolidation.

### 5.2 ViewModel Timers (`ReflexBlitzViewModel.swift`)
```swift
if selectedMode == .listening {
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
}
```

---

## 6. Testing & Quality Gate

1. **Unit Tests (`ReflexListeningModeViewTests`)**:
   - Verify continuous waveform rendering without local timer tasks.
   - Verify choice states across Active Stage 0, Stage 1, Stage 2 (eliminated distractor), and Reviewed states.
   - Verify speaker button trigger on back face.
2. **ViewModel Tests (`ReflexBlitzViewModelTests` & `MixedReflexDrillViewModelTests`)**:
   - Verify listening mode hint stages progress at 1800ms and 3000ms.
   - Verify distractor elimination is populated for listening plan items.
   - Verify audio is not spoken automatically on answer review.
3. **Compiler & Linter**:
   - 0 SwiftLint warnings, 0 Xcode build warnings.
