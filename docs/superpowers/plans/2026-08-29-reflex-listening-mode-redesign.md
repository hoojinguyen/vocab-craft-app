# Reflex Listening Mode Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign `ReflexListeningModeView` to adopt the 3D Tactile Flip Card architecture (`CraftFlipCard`), featuring an audio-first front stimulus with animated waveform (`CraftWaveformView`), auto-play on appear, stage-based auto-replay hints, distractor elimination, a comprehensive consolidation back face, and 4 canvas choice cards.

**Architecture:** Pure Reusable Stateless Mode View (`ReflexListeningModeView`) with 3D `CraftFlipCard` stimulus container and 4 `CraftChoiceCard`s on canvas + dedicated card builder in `ReflexBlitzView` and `MixedReflexDrillView`.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit design tokens & components (`CraftFlipCard`, `CraftWaveformView`, `CraftChoiceCard`, `CraftSpeakerButton`, `CraftBadge`, `CraftText`), Swift Testing framework.

## Global Constraints

- 100% Zero Hardcoded Strings: all user-facing strings and accessibility labels must reside in `Localizable.xcstrings` (EN & VI) and `AppStrings.ReflexBlitz`.
- 100% CraftUIKit token compliance (`theme.colors.*`, `theme.typography.*`, `theme.radii.*`, `theme.spacing.*`). No raw styling or hardcoded colors.
- Minimum 3D flip card height: `minHeight: 195` to eliminate layout jumping.
- Zero compiler warnings, zero lint errors, 100% tests passing.

---

### Task 1: Localization & AppStrings for Listening Mode

**Files:**
- Modify: `VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftAppTests/Reflex/ReflexLocalizationTests.swift`

**Interfaces:**
- Produces:
  - `AppStrings.ReflexBlitz.listeningInstructionText: String` ("app.reflex.listening.instruction")
  - `AppStrings.ReflexBlitz.listeningReplayA11y: String` ("app.reflex.listening.replay_a11y")
  - `AppStrings.ReflexBlitz.listeningWaveformA11y: String` ("app.reflex.listening.waveform_a11y")

- [ ] **Step 1: Write the failing test for new listening localization keys**

Add tests to `VocabCraftAppTests/Reflex/ReflexLocalizationTests.swift`:
```swift
@Test("Verifies Listening mode localization keys in AppStrings and Localizable catalog")
func testListeningLocalizationKeys() {
    #expect(!AppStrings.ReflexBlitz.listeningInstructionText.isEmpty)
    #expect(AppStrings.ReflexBlitz.listeningInstructionText != "app.reflex.listening.instruction")
    #expect(!AppStrings.ReflexBlitz.listeningReplayA11y.isEmpty)
    #expect(AppStrings.ReflexBlitz.listeningReplayA11y != "app.reflex.listening.replay_a11y")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexLocalizationTests`
Expected: FAIL (missing identifiers or unlocalized keys)

- [ ] **Step 3: Add localization entries to `Localizable.xcstrings` and `AppStrings+ReflexBlitz.swift`**

Update `AppStrings+ReflexBlitz.swift`:
```swift
public static var listeningInstructionText: String {
    String(localized: "app.reflex.listening.instruction", bundle: .main)
}

public static var listeningReplayA11y: String {
    String(localized: "app.reflex.listening.replay_a11y", bundle: .main)
}

public static var listeningWaveformA11y: String {
    String(localized: "app.reflex.listening.waveform_a11y", bundle: .main)
}
```

Update `Localizable.xcstrings` with both `en` and `vi` translations.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexLocalizationTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/Reflex/ReflexLocalizationTests.swift
git commit -m "feat(reflex): add listening mode localization keys"
```

---

### Task 2: Redesign `ReflexListeningModeView.swift` with 3D Flip Card & Animated Waveform

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexListeningModeView.swift`
- Modify: `VocabCraftAppTests/Features/Reflex/ReflexOtherModesTests.swift`

**Interfaces:**
- Produces: `ReflexListeningModeView` initialized with:
  ```swift
  public init(
      word: any ReflexDrillable,
      options: [ReflexBlitzOption],
      isReviewed: Bool,
      isResultCorrect: Bool = false,
      isResultTimeout: Bool = false,
      showHint: Bool = false,
      hintStage: Int = 0,
      selectedOptionText: String? = nil,
      cardBorderColor: Color = .clear,
      eliminatedOptionId: String? = nil,
      onSelectOption: ((ReflexBlitzOption) -> Void)? = nil,
      onPlayAudio: (() -> Void)? = nil,
      onReplayAudio: (() -> Void)? = nil
  )
  ```
- Choice state logic:
  - If not reviewed: `.disabled` when `hintStage >= 2 && option.id == eliminatedOptionId`, else `.idle`.
  - If reviewed: `.correct` for `option.isCorrect`, `.wrong` for `option.text == selectedOptionText`, else `.disabled`.

- [ ] **Step 1: Write the failing tests in `ReflexOtherModesTests.swift`**

```swift
@Test("Instantiates ListeningModeView with 3D Flip Card, auto-play, hint stages, and reviewed states")
func testListeningModeViewFullStates() {
    let item = ReflexBlitzWordItem.defaultStarterWords[0]
    let correctOpt = ReflexBlitzOption(id: "opt-1", text: "thói quen", isCorrect: true)
    let wrongOpt = ReflexBlitzOption(id: "opt-2", text: "cải thiện", isCorrect: false)
    let otherOpt = ReflexBlitzOption(id: "opt-3", text: "tập trung", isCorrect: false)
    let options = [correctOpt, wrongOpt, otherOpt]

    var audioPlayed = false
    var audioReplayed = false
    var selectedOption: ReflexBlitzOption?

    // 1. Active Stage 0
    let activeStage0 = ReflexListeningModeView(
        word: item,
        options: options,
        isReviewed: false,
        hintStage: 0,
        eliminatedOptionId: nil,
        onSelectOption: { selectedOption = $0 },
        onPlayAudio: { audioPlayed = true },
        onReplayAudio: { audioReplayed = true }
    )
    #expect(activeStage0.isReviewed == false)
    #expect(activeStage0.choiceState(for: correctOpt) == .idle)
    #expect(activeStage0.choiceState(for: wrongOpt) == .idle)
    #expect(activeStage0.choiceState(for: otherOpt) == .idle)

    // 2. Active Stage 2 (Distractor eliminated)
    let activeStage2 = ReflexListeningModeView(
        word: item,
        options: options,
        isReviewed: false,
        hintStage: 2,
        eliminatedOptionId: "opt-2"
    )
    #expect(activeStage2.choiceState(for: correctOpt) == .idle)
    #expect(activeStage2.choiceState(for: wrongOpt) == .disabled)
    #expect(activeStage2.choiceState(for: otherOpt) == .idle)

    // 3. Reviewed Correct
    let reviewedCorrect = ReflexListeningModeView(
        word: item,
        options: options,
        isReviewed: true,
        isResultCorrect: true,
        isResultTimeout: false,
        selectedOptionText: "thói quen"
    )
    #expect(reviewedCorrect.isReviewed == true)
    #expect(reviewedCorrect.choiceState(for: correctOpt) == .correct)
    #expect(reviewedCorrect.choiceState(for: wrongOpt) == .disabled)
    #expect(reviewedCorrect.choiceState(for: otherOpt) == .disabled)

    // 4. Reviewed Wrong
    let reviewedWrong = ReflexListeningModeView(
        word: item,
        options: options,
        isReviewed: true,
        isResultCorrect: false,
        isResultTimeout: false,
        selectedOptionText: "cải thiện"
    )
    #expect(reviewedWrong.isReviewed == true)
    #expect(reviewedWrong.choiceState(for: correctOpt) == .correct)
    #expect(reviewedWrong.choiceState(for: wrongOpt) == .wrong)
    #expect(reviewedWrong.choiceState(for: otherOpt) == .disabled)
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter ReflexOtherModesTests`
Expected: FAIL (initializer and property differences)

- [ ] **Step 3: Implement `ReflexListeningModeView.swift`**

Implement `ReflexListeningModeView`:
- Encapsulate `CraftFlipCard` (horizontal 3D flip, `.spring(response: 0.45, dampingFraction: 0.78)`).
- Front Face:
  - `CraftWaveformView(barCount: 16, isRecording: isAudioPlaying, activeColor: theme.colors.brandPrimary)` with height 40 and pulsing aura.
  - `CraftBadge` for `word.cleanPos` if `hintStage >= 1`.
  - `CraftText(AppStrings.ReflexBlitz.listeningInstructionText, style: .caption, color: theme.colors.textMuted, textAlignment: .center)`.
  - `.onAppear`: trigger `onPlayAudio?()`, set `isAudioPlaying = true`, and schedule return to false after 1.6s.
  - `.onChange(of: hintStage)`: when `hintStage > 0`, trigger `onPlayAudio?()`, set `isAudioPlaying = true`, schedule return to false after 1.6s.
- Back Face:
  - Row 1: `word.lemma` + `CraftSpeakerButton` (`variant: .subtle`, `size: .md`, `action: onReplayAudio`).
  - Row 2: `word.ipa` (`caption`, `textMuted`).
  - Row 3: `CraftBadge(word.cleanPos)` + `CraftBadge(word.cleanLevel, tone: .warning)`.
  - Row 4: `word.definitionVi` (`titleMedium`).
  - Row 5: `word.completedSentenceWithTargetWord` (`bodySerif`) + `word.exampleSentenceVi` (`caption`, `textMuted`).
- Options List:
  - `ForEach` options -> `CraftChoiceCard` with tactile 3D style and resolved `choiceState(for:)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexOtherModesTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexListeningModeView.swift VocabCraftAppTests/Features/Reflex/ReflexOtherModesTests.swift
git commit -m "feat(reflex): redesign ReflexListeningModeView with 3D flip card and animated waveform"
```

---

### Task 3: Screen Integration in `ReflexBlitzView.swift` and `MixedReflexDrillView.swift`

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift`
- Modify: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift`
- Modify: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewIntegrationTests.swift`

**Interfaces:**
- Consumes: `ReflexListeningModeView`
- Connects:
  - `onSelectOption`: passes selected option to view models.
  - `onPlayAudio` / `onReplayAudio`: triggers TTS speech for current word.
  - `eliminatedOptionId`: passed from view model during hint progression.

- [ ] **Step 1: Write integration tests for Blitz and Mixed views in listening mode**

Add tests to `ReflexBlitzViewIntegrationTests.swift` verifying `.listening` mode renders `ReflexListeningModeView` and interacts seamlessly.

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter ReflexBlitzViewIntegrationTests`

- [ ] **Step 3: Update `ReflexBlitzView.swift` and `MixedReflexDrillView.swift`**

Add `listeningCard(for:)` in `ReflexBlitzView`:
```swift
@ViewBuilder
private func listeningCard(for word: ReflexBlitzWordItem) -> some View {
    ReflexListeningModeView(
        word: word,
        options: viewModel.currentOptions,
        isReviewed: isReviewed,
        isResultCorrect: viewModel.currentAttemptIsCorrect,
        isResultTimeout: isReviewedTimeout,
        showHint: viewModel.showHint,
        hintStage: viewModel.hintStage,
        selectedOptionText: reviewResult?.selectedOption,
        cardBorderColor: theme.colors.hairline.opacity(0.4),
        eliminatedOptionId: eliminatedOptionId,
        onSelectOption: { option in
            viewModel.selectOption(option)
        },
        onPlayAudio: {
            viewModel.speakCurrentWord()
        },
        onReplayAudio: {
            viewModel.speakCurrentWord()
        }
    )
    .padding(.horizontal, theme.spacing.base)
}
```
And similarly for `MixedReflexDrillView.swift`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzViewIntegrationTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift VocabCraftAppTests/Features/Reflex/ReflexBlitzViewIntegrationTests.swift
git commit -m "feat(reflex): integrate redesigned listening mode into Blitz and Mixed drill views"
```

---

### Task 4: Full Verification Suite & Quality Gate

**Files:**
- Audit all modified files

- [ ] **Step 1: Run Swift test suite**

Run: `swift test`
Expected: 100% tests PASS

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint`
Expected: 0 errors, 0 warnings

- [ ] **Step 3: Run Xcode build / verification check**

Run: `xcodebuild -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" clean build`
Expected: **0 errors, 0 warnings**

- [ ] **Step 4: Commit any final cleanup**

```bash
git status
git commit -m "chore(reflex): complete verification for reflex listening mode redesign"
```
