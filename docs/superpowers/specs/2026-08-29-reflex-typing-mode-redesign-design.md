# Design Specification: Reflex Blitz Typing Mode Redesign

**Date**: 2026-08-29  
**Status**: Validated Design Spec  
**Target Feature**: VocabCraft Reflex Blitz - Typing Modality

---

## 1. Overview & Goals

The Reflex Blitz Typing Mode provides high-intensity, active-recall spelling and vocabulary retrieval drills. This design updates the typing interface to align visually and structurally with the 3D stimulus container pattern used in Multiple Choice mode while delivering a fluid, iOS-native keyboard experience.

### Key Objectives:
1. **Unified Stimulus Presentation**: Adopt the 3D Tactile `CraftFlipCard` container positioned near the header bar (consistent with Multiple Choice mode).
2. **Keyboard-Docked Input Bar**: Move the input field out of the card body into a floating pill docked smoothly above the iOS software keyboard.
3. **Streamlined Interaction Flow**: Auto-focus keyboard on appearance; trigger immediate validation on keyboard Return (`.submitLabel(.go)`); dismiss keyboard and floating bar upon answer submission or timeout.
4. **Subtle User Input Review**: When the card flips to its back face upon completion or timeout, display the user's typed response subtly under the lemma/IPA without distracting from the correct target word.
5. **Zero Friction & Strict Token Discipline**: Remove the skip button for Typing mode, strictly adhere to `CraftTheme` tokens, and enforce 100% bilingual localization keys without hardcoded strings.

---

## 2. User Experience & Screen Flow

```
[Countdown Overlay (3-2-1)]
            │
            ▼
┌─────────────────────────────────────────────────────────┐
│ Header: Progress bar, Combo streak, Circular timer       │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 3D Flip Card (Front Face):                          │ │
│ │  - Vietnamese Definition (large, centered)          │ │
│ │  - Badges (POS, CEFR, Hint if triggered)            │ │
│ │  - Cloze Sentence with missing slot: "I eat an ___" │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Floating Input Pill (above keyboard):               │ │
│ │  [ ⌨️  Nhập câu trả lời...                        ] │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ iOS Software Keyboard (Auto-focused, Return = Go)   │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
            │
            ▼ (User presses Return or Timer reaches 0)
┌─────────────────────────────────────────────────────────┐
│ Header: Progress & Timer paused                         │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 3D Flip Card (Back Face - Flipped):                 │ │
│ │  - Lemma (Serif) + Speaker Button                   │ │
│ │  - IPA Phonetic                                     │ │
│ │  - Subtle User Input: "Đã nhập: 'apple'" (Muted)   │ │
│ │  - POS & CEFR Badges                                │ │
│ │  - Vietnamese Definition                            │ │
│ │  - Complete Example Sentence (EN & VI)              │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ (Keyboard & Input Pill smoothly dismissed)              │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ CraftFeedbackSheet (Slide up from bottom):          │ │
│ │  - Status: Correct / Incorrect / Time's Up          │ │
│ │  - "Tiếp tục" (Continue) CTA Button                 │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Component & UI Architecture

### 3.1 `ReflexTypingModeView` Component

`ReflexTypingModeView` is an isolated SwiftUI view responsible for rendering the 3D flip card and managing the keyboard-docked input field.

#### Props & Bindings:
- `word: any ReflexDrillable` — The current active vocabulary challenge item.
- `isReviewed: Bool` — Whether the current drill is in the review/feedback stage.
- `isResultCorrect: Bool` — Whether the submission was correct.
- `isResultTimeout: Bool` — Whether the word timed out without a correct answer.
- `showHint: Bool` & `hintStage: Int` — Progressive assistance parameters.
- `typingText: Binding<String>` — Bound user text input.
- `clozeParts: ClozeSentenceParts?` — Formatted cloze segments (prefix, slot, suffix).
- `displayedSentence: String` — Active cloze sentence string or completed sentence.
- `userSubmittedText: String?` — The snapshot of what the user typed when submitted.
- `onSubmit: () -> Void` — Action callback triggered on non-empty Enter press.
- `onReplayAudio: (() -> Void)?` — Audio pronunciation callback on card back face.

#### Flip Card Front Face:
- **Vietnamese Definition**: `CraftText(word.definitionVi, style: .titleLarge, textAlignment: .center)` (max 2 lines).
- **Badges**: Clean Part of Speech (`word.cleanPos`) and CEFR level (`word.cleanLevel`).
- **Cloze Sentence**: Highlighted blank slot `___` with dynamic theme tinting (`theme.colors.brandPrimary` or `statusWarning` when hint active).
- **Container**: `CraftFlipCard` with `style: .tactile3D`, `axis: .horizontal`, `cornerRadius: theme.radii.xl`, `padding: theme.spacing.base`, `showSpecularGlare: true`.

#### Flip Card Back Face:
- **Target Lemma & Speaker**: `CraftText(word.lemma, style: .titleLargeSerif)` with `CraftSpeakerButton(size: .md)`.
- **IPA Phonetic**: `CraftText(word.ipa, style: .caption, color: theme.colors.textMuted)`.
- **User Input Subtitle**:
  - If correct: `CraftText(AppStrings.ReflexBlitz.typingEnteredPrefix(userSubmittedText), style: .caption, color: theme.colors.textMuted)`
  - If incorrect/typo: `CraftText(AppStrings.ReflexBlitz.typingYouTypedPrefix(userSubmittedText), style: .caption, color: theme.colors.textMuted)`
  - If timeout without typing: Omitted or neutral indicator.
- **Badges**: POS & CEFR capsules.
- **Vietnamese Definition**: `CraftText(word.definitionVi, style: .titleMedium)`.
- **Example Sentence**: Completed English sentence with target word bolded, followed by Vietnamese translation.

#### Keyboard-Docked Input Bar:
- Visible strictly when `!isReviewed`.
- Layout: Floating horizontal capsule (`CraftRadiusTokens.pill` or `lg`), styled with `surfaceElevated` background, `hairline` border, and subtle shadow (`theme.shadows.sm`).
- Internal elements:
  - Leading keyboard SF symbol (`keyboard` in `textMuted`).
  - Native `TextField` / `CraftTextField` with placeholder `AppStrings.ReflexBlitz.typingPlaceholderText` (`"Nhập câu trả lời..."` / `"Type your answer..."`).
  - `@FocusState` bound to auto-focus on appear.
  - `.submitLabel(.go)`.
  - `.autocorrectionDisabled()`, `.textInputAutocapitalization(.never)`.
  - `.onSubmit`: Checks `trimmed.isEmpty`; if empty, no action is taken (prevents accidental skips); if non-empty, calls `onSubmit()`.

### 3.2 Integration with `ReflexBlitzView`

- **Phase Handling**: When `phase == .drilling` and `selectedMode == .typing`:
  - Directly render `ReflexTypingModeView` without wrapping in the legacy static `ReflexCardContainerView`.
  - The bottom "Bỏ qua" (Skip) button is removed for Typing mode (`selectedMode == .typing`).
- **Review State Transition**:
  - When `submitTypingAnswer` or `handleTimeout` is invoked, `cardPhase` transitions to `.reviewed(result)`.
  - `isTextFieldFocused` is set to `false`, dismissing the keyboard.
  - `CraftFlipCard` flips horizontally to the back face.
  - `CraftFeedbackSheet` slides up from the bottom with status `.success`, `.error`, or `.warning`.
  - Pressing "Tiếp tục" in `CraftFeedbackSheet` clears the input and advances to the next word via `viewModel.advanceToNextWord()`.

---

## 4. Localization Strategy

All strings must strictly follow the Layer 2 App taxonomy and provide 100% bilingual parity (`en` & `vi`) with `extractionState: "manual"` and `state: "translated"` in `VocabCraftApp/Resources/Localizable.xcstrings`:

| Key | English (`en`) | Vietnamese (`vi`) |
| :--- | :--- | :--- |
| `app.reflex.typing.placeholder` | `"Type your answer..."` | `"Nhập câu trả lời..."` |
| `app.reflex.typing.entered_prefix` | `"Entered: \"%@\""` | `"Đã nhập: \"%@\""` |
| `app.reflex.typing.you_typed_prefix` | `"You typed: \"%@\""` | `"Bạn đã nhập: \"%@\""` |

---

## 5. Non-Functional & Quality Requirements

1. **Zero Hardcoded Strings**: All text rendered via `Localizable.xcstrings` and `AppStrings.ReflexBlitz`.
2. **Design System Conformance**: All paddings, colors, fonts, and corner radii utilize `CraftTheme` (`craftTheme.spacing.*`, `craftTheme.colors.*`, `craftTheme.radii.*`).
3. **Accessibility**: All interactive and visual elements provide descriptive `.accessibilityLabel` modifiers.
4. **Sensory Feedback**: Leverage existing `.sensoryFeedback` triggers for success, error, and timeout haptics.
5. **Zero Compiler & Linter Warnings**: Strict compliance with Swift concurrency, zero build warnings, and clean `swiftlint` output.

---

## 6. Verification Plan

- **Automated Tests**:
  - Run `swift test` on `CraftUIKit` to verify design system integrity.
  - Run app tests for `ReflexBlitzViewModel` to ensure correct answer evaluation, timeout handling, and streak calculations.
- **Manual & Simulator Verification**:
  - Verify keyboard auto-focus on drill start.
  - Verify floating input bar placement across different iPhone simulator sizes.
  - Verify smooth transition: keyboard dismisses, card flips to back face, and bottom feedback sheet animates up.
  - Verify that pressing Enter with empty text does not submit.
  - Verify English and Vietnamese language rendering.
