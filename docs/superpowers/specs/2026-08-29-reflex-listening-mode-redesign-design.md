# Reflex Listening Mode Redesign Design Specification

## 1. Overview & Goals

The goal of this design is to elevate **Reflex Listening Mode** (`ReflexListeningModeView`) to have full visual, architectural, and motion parity with **Multiple Choice Mode** (`ReflexMultipleChoiceModeView`) and **Typing Mode** (`ReflexTypingModeView`).

Key objectives:
1. **3D Flip Card Stimulus**: Replace the static container with an interactive 3D `CraftFlipCard` (`.tactile3D` style).
2. **Audio-First Front Stimulus**:
   - Animated dynamic sound wave (`CraftWaveformView`) as the central hero element.
   - Auto-play TTS audio when the question appears (`.onAppear`).
   - Auto-replay audio dynamically at each hint progression stage (`hintStage` 0 → 1 → 2) without needing a manual replay button during the active countdown.
   - Stage-based hints: Stage 0 = pure audio + sound wave; Stage 1 = auto-replay + Part-of-Speech badge (`word.cleanPos`); Stage 2 = auto-replay + eliminate 1 distractor option.
3. **Comprehensive Consolidation Back Face**:
   - 3D 180° flip upon user answer submission or timeout.
   - Displays Target Lemma, manual Audio Replay speaker button (`CraftSpeakerButton`), IPA pronunciation, POS & CEFR badges, Vietnamese definition, and full example sentence with Vietnamese translation.
4. **Interactive Options List**:
   - 4 `CraftChoiceCard`s rendered directly on the canvas background.
   - Options present Vietnamese definitions (matching `ReflexDistractorGenerator.generateOptions`).
   - Card states (`CraftChoiceState`): `.idle`, `.disabled` (when eliminated or unselected after review), `.correct` (green), `.wrong` (red).
5. **Zero Hardcoded Strings & 100% Token Compliance**:
   - All strings localized in `Localizable.xcstrings` (EN & VI) via `AppStrings.ReflexBlitz`.
   - All styling derived exclusively from `CraftUIKit` design tokens (`craftTheme`).

---

## 2. Component Architecture

```
                                  ┌─────────────────────────────┐
                                  │   ReflexListeningModeView   │
                                  └──────────────┬──────────────┘
                                                 │
                   ┌─────────────────────────────┴─────────────────────────────┐
                   │                                                           │
     ┌─────────────▼─────────────┐                               ┌─────────────▼─────────────┐
     │       CraftFlipCard       │                               │      optionsListView      │
     │       (.tactile3D)        │                               │ (VStack of CraftChoiceCard)│
     └─────────────┬─────────────┘                               └───────────────────────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
┌────────▼────────┐ ┌────────▼────────┐
│  frontPromptFace│ │ backResultFace  │
│ (Active Stimulus│ │ (Reviewed Word  │
│    + Waveform)  │ │  Consolidation) │
└─────────────────┘ └─────────────────┘
```

---

## 3. Detailed View Specifications

### 3.1 `ReflexListeningModeView.swift`

#### View Properties:
```swift
public struct ReflexListeningModeView: View {
    @Environment(\.craftTheme) private var theme

    public let word: any ReflexDrillable
    public let options: [ReflexBlitzOption]
    public let isReviewed: Bool
    public let isResultCorrect: Bool
    public let isResultTimeout: Bool
    public let showHint: Bool
    public let hintStage: Int
    public let selectedOptionText: String?
    public let cardBorderColor: Color
    public let eliminatedOptionId: String?
    public let onSelectOption: ((ReflexBlitzOption) -> Void)?
    public let onPlayAudio: (() -> Void)?
    public let onReplayAudio: (() -> Void)?
}
```

#### Front Prompt Face (`frontPromptFace`):
- **Waveform Area**:
  - `CraftWaveformView` with 16 dynamic bars, `theme.colors.brandPrimary` / `theme.colors.accent`, pulsing glow.
  - Active audio animation triggered on card appear and hint stage transitions.
- **Hint Stage Badges**:
  - `hintStage >= 1`: Shows Part of Speech badge (`word.cleanPos`) via `CraftBadge` with scale/opacity transition.
- **Instruction Subtitle**:
  - `CraftText(AppStrings.ReflexBlitz.listeningInstructionText, style: .caption, color: theme.colors.textMuted, textAlignment: .center)`
- **Sizing**: `frame(maxWidth: .infinity, minHeight: 195, alignment: .center)` to prevent height jumping during 3D flip.

#### Back Result Face (`backResultFace`):
- **Row 1**: `word.lemma` (`titleLargeSerif`) + `CraftSpeakerButton` (`variant: .subtle`, `size: .md`, `action: onReplayAudio`).
- **Row 2**: `word.ipa` (`caption`, `color: theme.colors.textMuted`).
- **Row 3**: `CraftBadge(word.cleanPos)` + `CraftBadge(word.cleanLevel, tone: .warning)`.
- **Row 4**: `word.definitionVi` (`titleMedium`, `color: theme.colors.textPrimary`).
- **Row 5**: `word.completedSentenceWithTargetWord` (`bodySerif`) + `word.exampleSentenceVi` (`caption`, `color: theme.colors.textMuted`).

#### Options List (`optionsListView`):
- 4 `CraftChoiceCard`s on the canvas background.
- Option prefix: `prefixStyle: .none` or `.circle` (`A`, `B`, `C`, `D`).
- State resolution via `choiceState(for: option)`:
  - If `isReviewed`: `.correct` for the right answer, `.wrong` for the selected wrong answer, `.disabled` for others.
  - If not `isReviewed`: `.disabled` if `hintStage >= 2 && option.id == eliminatedOptionId`, else `.idle`.

---

## 4. Audio & Hint Progression Lifecycle

1. **Initial Appearance (`.onAppear`)**:
   - `onPlayAudio?()` is called immediately to speak the target word.
   - Internal state `isAudioPlaying = true` animates `CraftWaveformView`.
   - Timer resets `isAudioPlaying = false` after ~1.6s.
2. **Hint Progression (`.onChange(of: hintStage)`)**:
   - When `hintStage` increases to 1: Automatically plays audio again + displays POS badge.
   - When `hintStage` increases to 2: Automatically plays audio again + eliminates 1 wrong distractor choice.
3. **Reviewed Consolidation (`isReviewed == true`)**:
   - User taps the manual `CraftSpeakerButton` on the back face to replay audio at will.

---

## 5. Screen Integration

### 5.1 `ReflexBlitzView.swift`
Update `cardContent(for:)` dispatcher to treat `.listening` with its dedicated 3D flip card:
```swift
@ViewBuilder
private func cardContent(for word: ReflexBlitzWordItem) -> some View {
    if viewModel.selectedMode == .multipleChoice {
        multipleChoiceCard(for: word)
    } else if viewModel.selectedMode == .typing {
        typingCard(for: word)
    } else if viewModel.selectedMode == .listening {
        listeningCard(for: word)
    } else {
        containerCard(for: word)
    }
}
```

### 5.2 `MixedReflexDrillView.swift`
Update `cardContent(for:)` dispatcher identically to support Mixed Reflex Drills with the new listening card layout.

---

## 6. Localization & Design System Tokens

1. **String Keys**:
   - `app.reflex.listening.instruction` = "Nghe và chọn nghĩa đúng" / "Listen and choose the meaning"
   - `app.reflex.listening.replay_a11y` = "Phát lại âm thanh từ vựng" / "Replay vocabulary audio"
2. **Design Tokens**:
   - Colors: `theme.colors.brandPrimary`, `theme.colors.accent`, `theme.colors.textPrimary`, `theme.colors.textMuted`, `theme.colors.statusSuccess`, `theme.colors.statusDanger`
   - Spacing: `theme.spacing.xs`, `theme.spacing.sm`, `theme.spacing.md`, `theme.spacing.base`
   - Typography: `theme.typography.titleLargeSerif`, `theme.typography.titleMedium`, `theme.typography.bodySerif`, `theme.typography.caption`

---

## 7. Testing & Verification

1. **Unit Tests (`ReflexListeningModeViewTests`)**:
   - Test active state rendering (waveform, POS badge hidden at stage 0, shown at stage 1).
   - Test distractor elimination at stage 2.
   - Test reviewed state rendering (correct choice highlighting, wrong choice highlighting, back face details).
2. **Integration Tests**:
   - Verify `ReflexBlitzView` in `.listening` mode renders flip card and completes attempts correctly.
   - Verify `MixedReflexDrillView` seamlessly renders `.listening` items.
3. **Localization Tests**:
   - Verify 100% parity across EN & VI strings.
4. **Compiler & Linter**:
   - 0 SwiftLint warnings, 0 Xcode build warnings.
