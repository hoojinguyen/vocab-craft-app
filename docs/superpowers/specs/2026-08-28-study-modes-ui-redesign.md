# Design Specification: Study Modes UI & Interaction Redesign

**Date:** 2026-08-28  
**Status:** Approved by User  
**Scope:** `VocabCraftApp` Study Modes (Reflex Blitz, Mixed Reflex Drill) & `CraftUIKit` (Countdown Overlay, Feedback Sheet)

---

## 1. Overview & Problem Statement

Users navigating through study modes (such as Reflex Blitz and Mixed Reflex Drills) experienced two primary UX and visual quality issues:

1. **Countdown Stage Flaws (Bleed-Through & Typography)**:
   - The countdown overlay (`CraftCountdownOverlay`) rendered atop an already active drill view with semi-transparency (`opacity(0.92)`), allowing the first question to bleed through and spoil the initial challenge.
   - Typography and modality badges were undersized and lacked Apple HIG polish (e.g. Apple Fitness+ style grand typography, dynamic spring motion, ambient backdrop glow, and tap-to-skip support).

2. **Reviewed State Redundancy & Cluttered Feedback Sheet**:
   - `ReflexBlitzCardReviewedView` and `CraftFeedbackSheet` duplicated 100% of vocabulary information (lemma, phonetic IPA, pronunciation button, Vietnamese definition, English sentence, and Vietnamese translation were shown simultaneously on both the Card and the bottom Sheet).
   - `CraftFeedbackSheet` had horizontal outer margins and did not dock edge-to-edge with the screen bottom, appearing like a floating squashed card rather than a native iOS bottom action dock.

---

## 2. Architecture & Design Principles

### 2.1 Complete State Isolation & Zero Bleed-Through
- The container view state machine (`ReflexBlitzView`, `MixedReflexDrillView`) isolates the `.countdown` phase from the `.drilling` phase.
- During `.countdown`, the drill view is **not mounted** or is fully obscured behind a 100% opaque, theme-tokenized canvas.
- Tapping anywhere during the countdown triggers an immediate skip into the first drill challenge.

### 2.2 Strict Division of Responsibility (Card vs. Bottom Sheet)
- **Challenge Card (`ReflexBlitzCardView`)**: The sole owner of **Learning Content & In-Place Reveal**.
  - *Active State*: Vietnamese definition prompt, cloze sentence `[ • • • • ]` or initial hint `[ h • • • ]`, and mode-specific input controls (text field, waveform, choice cards).
  - *Reviewed State*: In-place target word insertion in the sentence (green for correct, red/coral for incorrect/timeout), POS badge, IPA phonetics, audio playback button, Vietnamese definition, and Vietnamese sentence translation. Also includes compact user attempt tags (e.g. `⌨️ Đã gõ: "..."` or `🎙️ Đã nhận diện: "..."`).
- **Bottom Feedback Sheet (`CraftFeedbackSheet`)**: The sole owner of **Status Signaling & Thumb-Zone Progression**.
  - Full-width edge-to-edge docked to the bottom (`maxWidth: .infinity`, `ignoresSafeArea(edges: .bottom)`).
  - *When Correct*: Status badge pill (`✓ Chính xác!`, plus combo streak flame if applicable) and a full-width tactile CTA button (`Tiếp tục`). Zero repeated vocabulary content.
  - *When Incorrect / Timeout*: Status badge pill (`✕ Chưa chính xác` or `⏰ Hết giờ!`) and a full-width tactile CTA button (`Tiếp tục`). Zero repeated vocabulary content.

---

## 3. Detailed Component Specifications

### 3.1 `CraftCountdownOverlay` (`Packages/CraftUIKit`)
- **Visual Backdrop**: Opaque dark canvas background (`theme.colors.canvasBackground`) with a subtle radial gradient ambient glow matching the active mode's primary tint.
- **Hero SF Symbol**: Large 48pt symbol using `.symbolEffect(.pulse)` / `.symbolEffect(.bounce)`.
- **Mode Title & Directive**:
  - Title: `theme.typography.titleLarge` (bold, `theme.colors.textPrimary`).
  - Directive: `theme.typography.bodyMedium` (`theme.colors.textSecondary`).
- **Grand Number / GO! Indicator**:
  - 92pt `SF Pro Rounded Heavy/Black` typography.
  - Color gradient: Peach/Mint accent tokens.
  - Animation: Spring bounce on step change (`.spring(response: 0.35, dampingFraction: 0.6)`).
  - Haptics: `.impact(weight: .heavy)` on countdown ticks, `.notificationOccurred(.success)` on `GO!`.
- **Skip Gesture**: `.onTapGesture` to bypass countdown and immediately invoke `onFinish()`.

### 3.2 `CraftFeedbackSheet` (`Packages/CraftUIKit`)
- **Docking Geometry**:
  - `maxWidth: .infinity` and `.ignoresSafeArea(edges: .bottom)`.
  - Top corner radius: 24pt (`topLeadingRadius`, `topTrailingRadius`); bottom corners: 0pt.
  - Top highlight stroke gradient using `theme.depths.topHighlight`.
- **Surface Styling**: Semantic tinting over `surfaceCard` / `ultraThinMaterial` (subtle green tint on success, subtle red/coral tint on danger).
- **Internal Content**:
  - Header row: Semantic status badge pill + optional streak counter badge.
  - Primary CTA: Full-width `CraftButton` (size: `.lg`, style: `.tactile3D` / `.primary`).

### 3.3 Study Modalities Interaction Matrix

| Modality | Time Limit | Active Interaction | Reviewed Presentation |
| :--- | :---: | :--- | :--- |
| **Gõ từ (Typing)** | 7.5s | Cloze sentence + auto-focused `CraftTextField`. Enter/Submit button freezes timer. Ghost skip button in thumb reach. | Keyboard automatically dismisses. Card highlights target word in cloze sentence + `⌨️ Đã gõ: "..."` tag. Full-width Feedback Sheet slides up. |
| **Phát âm (Speaking)** | 6.0s | Real-time `CraftWaveformView` audio visualizer + continuous speech matcher. Instant auto-pass on word match. Fallback keyboard button. | Microphone deactivates. Card highlights target word in cloze sentence + `🎙️ Đã nhận diện: "..."` tag. Full-width Feedback Sheet slides up. |
| **Trắc nghiệm (Multiple Choice)** | 4.5s | 2x2 grid of 4 tactile choice cards (A, B, C, D). Single tap instant submit. | Selected card shows state (green/red), correct choice highlighted. Card reveals sentence. Full-width Feedback Sheet slides up. |
| **Luyện nghe (Listening)** | 5.5s | Auto-plays audio immediately. Cloze sentence and English lemma hidden. Waveform visualizer + Replay button. 4 Vietnamese meaning choices. | Card unhides full English sentence, lemma, IPA, and definition. Full-width Feedback Sheet slides up. |

---

## 4. Compliance with Project Standards & Architecture

1. **Design System & Token Discipline**:
   - 100% token usage: `theme.colors.*`, `theme.typography.*`, `theme.spacing.*`, `theme.radii.*`, `theme.shadows.*`, `theme.depths.*`.
   - Zero raw hardcoded colors or fonts.
2. **Localization Architecture**:
   - Layer 1 (`craft.*`) in `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`.
   - Layer 2 (`app.reflex.*`) in `VocabCraftApp/Resources/Localizable.xcstrings`.
   - 100% bilingual parity between EN and VI with exact format specifiers (`%lld`, `%@`).
3. **Strict Quality Gate**:
   - Zero compiler warnings (Swift 6 strict concurrency safe).
   - Zero SwiftLint warnings.
   - 100% test pass rate on unit and localization test suites.
