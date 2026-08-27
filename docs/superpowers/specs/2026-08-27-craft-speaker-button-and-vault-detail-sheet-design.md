# CraftSpeakerButton & VaultWordDetailSheet UI/UX Polish Design Spec

**Date**: 2026-08-27  
**Status**: In Review  
**Target Modules**: `CraftUIKit` (Design System), `VocabCraftApp` (Vocabulary Feature)

---

## 1. Overview & Objectives

### 1.1 Context & Problem Statement
During UI/UX testing of the Vocabulary Vault (`Kho Từ`) on iOS Simulator, several critical visual, interaction, and architectural issues were discovered in `VaultWordDetailSheet` and its supporting components:
1. **Audio Button Invisible Icon (Bug)**: In `VaultWordDetailSheet`, the audio pronunciation button rendered as a solid orange circle with no visible speaker icon. This was caused by `CraftIconButton` assigning its icon `foregroundColor` to `customTint` (orange) when `variant == .filled`, rendering orange on orange.
2. **Action Buttons Contrast Imbalance**: The header contained two solid circular buttons with clashing weights (solid orange audio + solid yellow filled bookmark), overpowering the word lemma and phonetic text.
3. **Bottom Sheet Clipping (Detent Issue)**: At the default `.presentationDetents([.fraction(0.55), .large])`, Section 3 ("Tiến độ phản xạ") was cut in half, leaving only the streak badge and partial clipped text visible, requiring awkward immediate manual scrolling.
4. **Fragmented Speaker Implementation**: Pronunciation/speaker buttons are duplicated across 10+ screens in the app with inconsistent ad-hoc styling instead of a unified, reusable `CraftUIKit` component.
5. **Design System & A11y Conformance**: `DynamicReflexModeBadge` used raw hardcoded colors (`.vocabLavender`, `.vocabMint`, etc.) and hardcoded Vietnamese accessibility strings, violating project design token and zero-hardcoded-strings policies.

### 1.2 Core Goals
1. **Design & Build `CraftSpeakerButton`**: Create a reusable, standardized audio playback button in `CraftUIKit` supporting idle/playing dynamic wave animations, subtle/filled/ghost variants, and optional pill layout.
2. **Fix Root Color Logic in `CraftIconButton`**: Ensure `variant == .filled`, `.danger`, or `isSelected == true` always resolves `foregroundColor` to high-contrast `theme.colors.textInverse`.
3. **Refine `VaultWordDetailSheet`**:
   - Integrate `CraftSpeakerButton` with subtle styling.
   - Refine Bookmark button to subtle harmony (40pt `.md`).
   - Increase default sheet height to `.fraction(0.68)` for clean, complete rendering of all 3 sections.
   - Add instant local reactivity for bookmark toggling.
4. **Tokenize `DynamicReflexModeBadge`**: Clean up hardcoded colors to semantic theme tokens and extract accessibility labels to `Localizable.xcstrings`.
5. **Zero Errors & Zero Warnings**: 100% bilingual parity (EN/VI), comprehensive test coverage, and strict SwiftLint compliance.

---

## 2. Architecture & Component Specifications

### 2.1 Component 1: `CraftSpeakerButton` (`CraftUIKit`)
- **Location**: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSpeakerButton.swift`
- **Component Classification**: Interactive Control Molecule

#### 2.1.1 Public API & Interfaces
```swift
import SwiftUI

/// Visual style variants for speaker audio button.
public enum CraftSpeakerButtonVariant: String, Sendable, CaseIterable {
    case subtle
    case filled
    case ghost
}

/// A dedicated pronunciation and audio playback button adhering to Apple HIG and CraftUIKit design tokens.
/// Features dynamic SF Symbol wave animation during playback, tactile haptics, and standard Layer 1 accessibility.
public struct CraftSpeakerButton: View {
    @Environment(\.craftTheme) private var theme

    public let variant: CraftSpeakerButtonVariant
    public let size: CraftIconSize
    public let isPlaying: Bool
    public let label: LocalizedStringKey?
    public let customTint: Color?
    public let action: () -> Void

    public init(
        variant: CraftSpeakerButtonVariant = .subtle,
        size: CraftIconSize = .md,
        isPlaying: Bool = false,
        label: LocalizedStringKey? = nil,
        customTint: Color? = nil,
        action: @escaping () -> Void
    )
}
```

#### 2.1.2 States & Visual Rendering
| State | Icon Symbol | SF Symbol Effect | Styling |
| :--- | :--- | :--- | :--- |
| **Idle (`isPlaying == false`)** | `speaker.wave.2.fill` / `.audio` | Static | Subtle background (`effectiveTint.opacity(0.12)`), Icon tint `effectiveTint` |
| **Playing (`isPlaying == true`)** | `speaker.wave.3.fill` | `.symbolEffect(.variableColor.iterative)` (iOS 17+) / Animated pulse | Subtle background with light active pulse or glow |
| **Pill Mode (`label != nil`)** | Speaker icon + `CraftText` | Same as above | Capsule shape with horizontal padding and 44pt touch target |

#### 2.1.3 Localization (Layer 1: `craft.*`)
- `craft.audio.pronounce`: "Phát âm từ vựng" (VI) / "Pronounce word" (EN)
- `craft.audio.playing`: "Đang phát âm..." (VI) / "Playing pronunciation..." (EN)

---

### 2.2 Component 2: `CraftIconButton` Contrast Fix (`CraftUIKit`)
- **Location**: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift`
- **Issue**: `foregroundColor` returned `customTint` even when `variant == .filled`, leading to same-color background and foreground.
- **Resolution**:
```swift
private var foregroundColor: Color {
    if variant == .filled || variant == .danger || isSelected {
        return theme.colors.textInverse
    }
    return effectiveTint
}
```

---

### 2.3 Component 3: `VaultWordDetailSheet` Refinement (`VocabCraftApp`)
- **Location**: `VocabCraftApp/Features/Vocabulary/Views/Components/VaultWordDetailSheet.swift`

#### 2.3.1 Header Layout & Button Sizing
```
┌──────────────────────────────────────────────────────────────┐
│  Procrastinate                               [ 🔊 ]   [ 🔖 ] │
│  /proʊˈkræs.tə.neɪt/                        (36-40pt) (36-40pt)
│  [ verb ]  [ B2 ]                                            │
├──────────────────────────────────────────────────────────────┤
│  Định nghĩa                                                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Trì hoãn công việc                                     │  │
│  └────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────┤
│  Ví dụ thực tế                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Don't procrastinate on important tasks.                │  │
│  │ Đừng trì hoãn những công việc quan trọng.              │  │
│  └────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────┤
│  Tiến độ phản xạ                                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ [ 🔥 1 streak ]                                        │  │
│  │ Chế độ đã luyện:                                      │  │
│  │ [ 🗣️ Nói (3.0s) ]  [ ⌨️ Gõ (4.0s) ]                    │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

#### 2.3.2 Detents & Sizing
- Change presentation detent from `.fraction(0.55)` to:
  ```swift
  .presentationDetents([.fraction(0.68), .large])
  .presentationDragIndicator(.visible)
  ```
- Ensures Section 3 ("Tiến độ phản xạ") and all practiced mode badges are fully in view upon opening.

#### 2.3.3 Bookmark Action State Handling
- Maintain local `@State private var isBookmarked: Bool` initialized with `word.isBookmarked`.
- Provide immediate visual update on tap + light impact haptic, then trigger `onToggleBookmark()`.

---

### 2.4 Component 4: `DynamicReflexModeBadge` Conformance (`VocabCraftApp`)
- **Location**: `VocabCraftApp/Features/Vocabulary/Views/Components/DynamicReflexModeBadge.swift`
- Replace raw asset colors (`.vocabLavender`, `.vocabMint`, etc.) with `theme.colors` semantic palette (e.g. `theme.colors.accent`, `theme.colors.brandPrimary`, `theme.colors.statusSuccess`, `theme.colors.statusInfo`).
- Replace hardcoded Vietnamese accessibility label with `AppStrings.Reflex.modeAccessibilityLabel(mode:duration:)`.

---

## 3. Localization Matrix (100% Bilingual Parity)

### Layer 1 (`CraftUIKit/Resources/Localizable.xcstrings`):
| Key | English (en) | Vietnamese (vi) | Extraction State |
| :--- | :--- | :--- | :--- |
| `craft.audio.pronounce` | "Pronounce word" | "Phát âm từ vựng" | manual / translated |
| `craft.audio.playing` | "Playing pronunciation..." | "Đang phát âm..." | manual / translated |

### Layer 2 (`VocabCraftApp/Resources/Localizable.xcstrings`):
| Key | English (en) | Vietnamese (vi) | Extraction State |
| :--- | :--- | :--- | :--- |
| `app.reflex.mode_a11y_format` | "Mode: %@, time limit %@" | "Chế độ: %@, giới hạn thời gian %@" | manual / translated |

---

## 4. Verification & Testing Plan

### 4.1 Automated Unit Tests
1. **`CraftSpeakerButtonTests`** (`Packages/CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`):
   - Test default initialization, custom tint, variant resolution, playing state, pill mode with label.
2. **`CraftIconButtonTests`** (`Packages/CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`):
   - Verify `foregroundColor` returns `theme.colors.textInverse` for filled, danger, and selected variants.
3. **`PersonalVaultViewsTests`** (`VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift`):
   - Verify `VaultWordDetailSheet` initialization and interaction callbacks.
4. **`LocalizationTests`**:
   - `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
   - `swift test --filter PersonalVaultLocalizationTests`

### 4.2 Code Quality & Static Analysis
- Run `swiftlint` on `Packages/CraftUIKit` and `VocabCraftApp`.
- Ensure 0 errors and 0 warnings.
