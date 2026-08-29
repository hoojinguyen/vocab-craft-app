# Design Specification: Reflex Blitz Typing Mode Redesign

**Date**: 2026-08-29  
**Status**: Validated Design Spec  
**Target Feature**: VocabCraft Reflex Blitz & Mixed Reflex Drill — Typing Modality

---

## 1. Overview & Goals

The Reflex Blitz Typing Mode provides high-intensity, active-recall spelling and vocabulary retrieval drills. Following real-world device testing and UX evaluation, this design refines the typing interface to deliver:
1. **Zero-Jitter Multi-Stage Hinting**: Immediate pre-allocated character length slot (`[ _ _ _ _ _ ]`) to prevent horizontal layout jumping, followed by progressive Part-of-Speech badge reveal and selective letter reveal.
2. **External Typed Word Review**: Clean separation of the user's typed attempt outside the card, positioned in the space beneath the flipped card face. Empty attempts on timeout are omitted cleanly.
3. **Robust Keyboard Lifecycle & Auto-Focus**: Unfailing auto-focus across sequential words (Word 1, 2, 3...) with smooth keyboard avoidance and transition coordination.
4. **Mixed Reflex Drill Parity**: Elimination of silent answer drops on incorrect inputs, removal of double-nested card containers, and adoption of the standard 3D flip card review.
5. **Audio Sequencing**: Coordinated chime sound effects and TTS English pronunciation to prevent overlapping audio clips.

---

## 2. User Experience & Screen Flow

### Active Challenge State (`!isReviewed`)

```
┌─────────────────────────────────────────────────────────┐
│ Header: Progress Bar, Combo Streak, Circular Timer      │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 3D Flip Card (Front Face):                          │ │
│ │  - Vietnamese Definition (Large, Centered)          │ │
│ │  - [Stage >= 1] POS Badge (Fade-in: "noun" / "verb")│ │
│ │  - Cloze Sentence with Pre-allocated Length Mask:   │ │
│ │    "I eat an [ _ _ _ _ _ ] every day."              │ │
│ │    [Stage >= 2] Warning color: "[ a _ _ _ e ]"      │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│                         (Spacer)                        │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Floating Keyboard-Docked Input Bar:                 │ │
│ │  [ ⌨️  Nhập câu trả lời...                        ] │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ iOS Software Keyboard (Auto-focused, Return = Go)   │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Reviewed Feedback State (`isReviewed`)

```
┌─────────────────────────────────────────────────────────┐
│ Header: Progress & Timer Paused                         │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 3D Flip Card (Back Face - Flipped):                 │ │
│ │  - Lemma (Serif) + Speaker Button                   │ │
│ │  - IPA Phonetic                                     │ │
│ │  - Badges (Clean POS capsule)                       │ │
│ │  - Vietnamese Definition                            │ │
│ │  - Complete Example Sentence (EN & VI)              │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│  (Spacing ~16pt)                                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │ [If Typed] CraftBadge: "Đã nhập: \"apple\""       │  │
│  │            or "Bạn đã nhập: \"aple\""             │  │
│  │ [If Empty Timeout] (Hidden / Omitted)             │  │
│  └───────────────────────────────────────────────────┘  │
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

### 3.1 Multi-Stage Hinting Mechanism (7.5s Time Limit)

1. **Stage 0 (`0.0s – 2.5s` - Initial)**:
   - Front card displays **Vietnamese Definition** + **Cloze Sentence** with pre-allocated underscore length mask: `[ _ _ _ _ _ ]` in `theme.colors.brandPrimary`.
   - POS badge and CEFR level are hidden to promote unassisted recall.
   - Pre-allocated length slot ensures that the sentence footprint is identical throughout all hint stages, completely preventing text reflow and layout jitter.
2. **Stage 1 (`2.5s – 4.5s` - Part of Speech Scaffold)**:
   - Part of Speech badge (`word.cleanPos`, e.g. `noun`, `verb`) smoothly fades in via `.opacity(hintStage >= 1 ? 1.0 : 0.0)` with `.animation(.easeInOut(duration: 0.2), value: hintStage)`.
   - CEFR badge remains omitted on the front face for visual clarity.
3. **Stage 2 (`4.5s – 7.5s` - Letter / Pattern Scaffold)**:
   - The slot updates to reveal initial/ending letters or internal double consonants (e.g. `[ a _ _ _ e ]` or `[ _ _ ll _ _ ]`).
   - Slot color transitions to `theme.colors.statusWarning`.

### 3.2 Flip Card Stimulus (`CraftFlipCard`)

- **Front Face**:
  - `CraftText(word.definitionVi, style: .titleLarge, textAlignment: .center)` (max 2 lines).
  - Part of Speech capsule badge with `.opacity(hintStage >= 1 ? 1.0 : 0.0)`.
  - Cloze sentence with dynamic slot coloring.
- **Back Face (Canonical Source of Truth)**:
  - Row 1: Lemma in `style: .titleLargeSerif` + `CraftSpeakerButton(size: .md)` on trailing edge.
  - Row 2: IPA Phonetic in `style: .caption, color: textMuted`.
  - Row 3: POS capsule badge.
  - Row 4: Vietnamese Definition in `style: .titleMedium`.
  - Row 5: Full English example sentence (bolded lemma in `statusSuccess` / `statusDanger`) + Vietnamese translation.
  - Standardized compact height (~180–200pt), ensuring no overlap with `CraftFeedbackSheet`.

### 3.3 External Typed Answer Badge (Below Card)

- Positioned directly below `CraftFlipCard` with standard spacing (`theme.spacing.base` / `16pt`).
- Render conditions:
  - **Correct Answer**: `CraftBadge(AppStrings.ReflexBlitz.typingEnteredPrefix(userSubmittedText), variant: .subtle, tone: .success, size: .md, shape: .capsule)`
  - **Incorrect Answer**: `CraftBadge(AppStrings.ReflexBlitz.typingYouTypedPrefix(userSubmittedText), variant: .subtle, tone: .danger, size: .md, shape: .capsule)`
  - **Empty Timeout**: If `userSubmittedText` is nil or empty after whitespace trimming, **no badge is rendered**.
  - **No Duplicate Icons**: Avoid icon repetition with `CraftFeedbackSheet` by omitting leading icons on the answer badge.

### 3.4 Keyboard Docking & Focus Lifecycle

- **Focus Coordination**:
  - Use `.id(word.id)` on `ReflexTypingModeView` in parent drill views so each word instantiation has clear identity.
  - Trigger `@FocusState` activation with a small microtask delay (`Task { @MainActor in try? await Task.sleep(for: .milliseconds(80)); isTextFieldFocused = true }`) to ensure the UIKit responder chain accepts focus after previous sheet dismissal.
- **Keyboard Dismissal & Transitions**:
  - When Enter is pressed or timeout occurs, set `isTextFieldFocused = false`.
  - Animate the input bar smoothly downwards while the feedback sheet slides up, preventing layout jumping.

### 3.5 Mixed Reflex Drill Integration (`MixedReflexDrillView`)

- **Answer Submission**: Remove the blocking `guard isCorrect else { return }` filter in `MixedReflexDrillView.submitTypingAnswer(_:)`. Both correct and incorrect submissions must be dispatched to `viewModel.submitAnswer(...)` and transition to `.reviewed`.
- **Card Container**: Remove `ReflexCardContainerView` wrapping `ReflexTypingModeView` to eliminate double card nesting.
- **Reviewed State**: Enable `CraftFlipCard` 3D flip card review for `.typing` modality in Mixed Reflex Drills.

### 3.6 Audio & Sound Sequencing

- When an answer is submitted or times out:
  1. Play sound chime (`soundEffectService.playSuccessChime()` or `playIncorrectChime()`) immediately.
  2. Dispatch TTS pronunciation (`ttsService.speak(text: word.lemma)`) with a 250ms delay to prevent audio clipping.

---

## 4. Localization Strategy

All strings utilize `Localizable.xcstrings` under the Layer 2 App taxonomy (`app.reflex.*`) with 100% bilingual parity (`en` & `vi`):

| Key | English (`en`) | Vietnamese (`vi`) |
| :--- | :--- | :--- |
| `app.reflex.typing.placeholder` | `"Type your answer..."` | `"Nhập câu trả lời..."` |
| `app.reflex.typing.entered_prefix` | `"Entered: \"%@\""` | `"Đã nhập: \"%@\""` |
| `app.reflex.typing.you_typed_prefix` | `"You typed: \"%@\""` | `"Bạn đã nhập: \"%@\""` |

---

## 5. Verification Plan

1. **Automated Unit Tests**:
   - `ReflexOtherModesTests`: Verify `ReflexTypingModeView` active hinting, cloze parts, external typed badge rendering, and callback triggers.
   - `ReflexBlitzViewModelTests`: Verify typing answer validation (case/whitespace insensitivity, streak, timeout, audio sequencing).
   - `MixedReflexDrillViewModelTests`: Verify incorrect typing answers record properly and loop back in queue.
2. **SwiftLint & Xcode Compilation**:
   - 0 compiler warnings, 0 lint warnings, 100% test pass rate.
3. **Interactive Simulator Verification**:
   - Keyboard auto-focus on Word 1, Word 2, and Word 3.
   - Zero layout jumping during 3D flip and feedback sheet presentation.
   - External typed answer badge placement and empty timeout omission.
