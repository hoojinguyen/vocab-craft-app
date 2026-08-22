# CraftUIKit Design System Specification

## 1. Overview & Problem Statement

### 1.1 Problem Statement
As applications expand in feature count and UI density, the lack of a standardized UI component library and design token system leads to:
- **UI/UX Inconsistency:** Different padding, colors, corner radii, and interaction states across screens.
- **High Tech Debt & Duplication:** Every new feature reimplements buttons, text fields, cards, badges, and progress bars from scratch.
- **Difficult Re-branding / Theme Portability:** Styles are hardcoded with static colors (`Color.vocabPeach`, `Color(red: ...)`), making multi-theming or reusing components in other applications painful.

### 1.2 Solution: CraftUIKit
`CraftUIKit` is an independent, domain-agnostic, token-driven SwiftUI Design System & Component Library packaged as a standalone Local Swift Package. It provides:
1. **Zero Domain Logic Dependency:** Completely decoupled from vocabularies, decks, database models, or app logic.
2. **3-Tier Design Token Architecture:** Global Tokens -> Semantic Tokens -> Component Tokens.
3. **100% Theme Swappability:** Any application can supply a custom theme conforming to `CraftTheme` and inject it via SwiftUI Environment (`.craftTheme(MyTheme())`).
4. **SwiftUI-Native Ergonomics:** Supports both composable view builders (`CraftButton(...)`) and native SwiftUI styles (`.buttonStyle(.craftPrimary())`).
5. **Built-in Motion, Gradients & Apple HIG Accessibility:** Standardized spring curves, tactile haptic feedback, reduce motion compliance, and 44pt+ touch targets.

---

## 2. Architecture & Package Structure

### 2.1 Package Layout
`CraftUIKit` lives at the root of the repository as a standalone Swift Package:

```
CraftUIKit/
├── Package.swift
├── Sources/
│   └── CraftUIKit/
│       ├── Tokens/
│       │   ├── CraftTheme.swift                // Root theme protocol
│       │   ├── CraftColorTokens.swift          // Semantic color palette protocol & defaults
│       │   ├── CraftTypographyTokens.swift     // Typography scale protocol & font styles
│       │   ├── CraftSpacingTokens.swift        // Spacing scale (4, 8, 12, 16, 24, 32, 48)
│       │   ├── CraftRadiusTokens.swift         // Corner radius scale (sm: 8, md: 12, lg: 16, full)
│       │   ├── CraftShadowTokens.swift         // Drop shadows & elevation
│       │   ├── CraftGradientTokens.swift       // Gradients (Hero, Glass, Shine, Fade)
│       │   ├── CraftAnimationTokens.swift      // Spring curves & tactile motion tokens
│       │   └── Themes/
│       │       └── CraftDefaultTheme.swift     // Default modern slate & indigo theme
│       ├── Environment/
│       │   └── CraftThemeEnvironment.swift     // @Environment(\.craftTheme) & .craftTheme() modifier
│       ├── Modifiers/
│       │   ├── PressEffectModifier.swift       // .craftPressEffect()
│       │   ├── ShimmerModifier.swift           // .craftShimmer()
│       │   └── TypographyModifier.swift        // .craftTypography()
│       ├── Components/
│       │   ├── Atoms/
│       │   │   ├── CraftText.swift             // Dynamic type typography atom
│       │   │   ├── CraftBadge.swift            // Status & category badges (Solid, Subtle, Outline)
│       │   │   ├── CraftIcon.swift             // SF Symbol standardized icon
│       │   │   ├── CraftIconButton.swift       // Circle/Square tactile icon button
│       │   │   ├── CraftDivider.swift          // Hairline divider
│       │   │   └── CraftSpinner.swift          // Smooth loading indicator
│       │   ├── Controls/
│       │   │   ├── CraftButton.swift           // Primary, Secondary, Outline, Ghost, Danger
│       │   │   ├── CraftTextField.swift        // Inset/Outlined textfield with leading/trailing slots & error state
│       │   │   ├── CraftSearchBar.swift        // Dedicated search bar with auto clear
│       │   │   ├── CraftToggle.swift           // Custom styled toggle switch
│       │   │   ├── CraftStepper.swift          // [-] [Value] [+] counter control
│       │   │   └── CraftPill.swift             // Selectable filter chip / pill
│       │   ├── Containers/
│       │   │   ├── CraftCard.swift             // Flat, Elevated, Outlined, Gradient, Pressable
│       │   │   ├── CraftProgressBar.swift      // Linear & segmented progress bar
│       │   │   ├── CraftProgressRing.swift     // Circular gauge indicator
│       │   │   ├── CraftListRow.swift          // Standardized settings / list item row
│       │   │   └── CraftEmptyState.swift       // Illustration/icon + title + description + CTA
│       │   └── Overlays/
│       │       ├── CraftToast.swift            // Floating HUD toast alert
│       │       ├── CraftBottomSheet.swift      // Grabber sheet container
│       │       └── CraftDialog.swift           // Confirmation modal alert
│       └── Previews/
│           └── CraftCatalogView.swift          // Interactive component gallery
└── Tests/
    └── CraftUIKitTests/
        ├── ThemeTests.swift
        └── ComponentSnapshotTests.swift
```

---

## 3. Design Token Specifications

### 3.1 `CraftTheme` Contract
```swift
public protocol CraftTheme: Sendable {
    var colors: CraftColorTokens { get }
    var typography: CraftTypographyTokens { get }
    var spacing: CraftSpacingTokens { get }
    var radii: CraftRadiusTokens { get }
    var shadows: CraftShadowTokens { get }
    var gradients: CraftGradientTokens { get }
    var animations: CraftAnimationTokens { get }
}
```

### 3.2 Semantic Color Tokens (`CraftColorTokens`)
All colors dynamically adjust between Light and Dark modes:
- **Canvas & Backgrounds:** `canvasBackground`, `surfaceCard`, `surfaceElevated`, `surfaceSubtle`
- **Brand & Action:** `brandPrimary`, `brandSecondary`, `accent`
- **Text & Ink:** `textPrimary`, `textSecondary`, `textMuted`, `textInverse`
- **Borders & Lines:** `borderDefault`, `borderFocus`, `hairline`
- **Status & Feedback:** `statusSuccess`, `statusWarning`, `statusDanger`, `statusInfo`

### 3.3 Typography Scale (`CraftTypographyTokens`)
- `displayLarge`: 32pt, Bold
- `titleLarge`: 24pt, Bold
- `titleMedium`: 18pt, SemiBold
- `headline`: 16pt, SemiBold
- `bodyLarge`: 16pt, Regular
- `bodyMedium`: 14pt, Regular
- `label`: 12pt, Medium / SmallCaps
- `caption`: 11pt, Regular

### 3.4 Spacing & Radii Scale
- **Spacing:** `xs: 4pt`, `sm: 8pt`, `md: 12pt`, `base: 16pt`, `lg: 24pt`, `xl: 32pt`, `xxl: 48pt`
- **Radii:** `xs: 4pt`, `sm: 8pt`, `md: 12pt`, `lg: 16pt`, `xl: 24pt`, `full: 9999pt`

### 3.5 Motion & Gradient Tokens
- **Spring Curves:**
  - `springSnappy`: `response: 0.22, damping: 0.65` (buttons, taps, chips)
  - `springSmooth`: `response: 0.35, damping: 0.85` (sheets, modals, card expands)
  - `springBouncy`: `response: 0.45, damping: 0.55` (milestones, celebrations)
- **Gradients:** `brandHero`, `surfaceGlass`, `accentShine`, `fadeBottom`

---

## 4. Component Library (Phase 1 Scope)

### 4.1 Atoms
1. **`CraftText`:** Renders text using typography tokens, scaling automatically with Dynamic Type.
2. **`CraftBadge`:** Variants (`.solid`, `.subtle`, `.outline`), tones (`.primary`, `.success`, `.warning`, `.danger`, `.neutral`), sizes (`.sm`, `.md`).
3. **`CraftIcon`:** Standardized SF Symbol sizing (`sm: 14`, `md: 18`, `lg: 24`, `xl: 32`).
4. **`CraftIconButton`:** Tactile circle or square button with background, spring tap feedback, and accessibility label.
5. **`CraftDivider`:** Thin hairline separator with tokenized color.
6. **`CraftSpinner`:** Smooth rotating activity indicator adapting to brand primary color.

### 4.2 Controls & Inputs
1. **`CraftButton`:**
   - Variants: `.primary`, `.secondary`, `.outline`, `.ghost`, `.danger`
   - Sizes: `.sm` (32pt), `.md` (44pt HIG minimum), `.lg` (54pt hero)
   - Features: `isLoading` spinner state, disabled state, spring press tactile animation, native `ButtonStyle` support.
2. **`CraftTextField`:**
   - States: Default, Focused (border glow), Error (red highlight + helper text message), Disabled.
   - Slots: `leadingIcon`, `trailingAction` (clear button, password toggle).
3. **`CraftSearchBar`:** Pill-shaped search bar with focus ring and clear action.
4. **`CraftToggle`:** Accessible toggle switch bound to theme accent color.
5. **`CraftStepper`:** `[-] [Value] [+]` stepper control with custom step increments and direct editing.
6. **`CraftPill` / `CraftFilterChip`:** Tap-to-select pill chip with active/inactive states and optional leading icon.

### 4.3 Containers & Surfaces
1. **`CraftCard`:**
   - Styles: `.flat`, `.elevated`, `.outlined`, `.gradient`
   - Optional `isPressable: true` with `.craftPressEffect()` for Bento grids.
2. **`CraftProgressBar`:** Linear continuous or stepped progress bar with animated value changes.
3. **`CraftProgressRing`:** Circular completion gauge.
4. **`CraftListRow`:** Standardized row for settings/lists (Leading icon in colored squircle + Title + Subtitle + Trailing control).
5. **`CraftEmptyState`:** Empty list placeholder with icon, title, description, and primary CTA button.

### 4.4 Overlays & Feedback
1. **`CraftToast`:** Top/Bottom HUD toast with auto-dismiss and spring presentation.
2. **`CraftBottomSheet`:** Modal bottom sheet with rounded corners and drag indicator.
3. **`CraftDialog`:** Alert dialog with title, message, primary action, and cancel buttons.

---

## 5. App Integration & Migration Strategy

### 5.1 Step 1: Package Dependency Setup
1. Create `CraftUIKit` folder with its `Package.swift`.
2. Add `CraftUIKit` as local package dependency in root `Package.swift` and `VocabCraftApp.xcodeproj`.

### 5.2 Step 2: Define `VocabTheme`
In `VocabCraftApp/Core/DesignSystem/VocabTheme.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct VocabTheme: CraftTheme {
    public var colors: CraftColorTokens = VocabColorTokens()
    public var typography: CraftTypographyTokens = CraftDefaultTypographyTokens()
    public var spacing: CraftSpacingTokens = CraftDefaultSpacingTokens()
    public var radii: CraftRadiusTokens = CraftDefaultRadiusTokens()
    public var shadows: CraftShadowTokens = CraftDefaultShadowTokens()
    public var gradients: CraftGradientTokens = VocabGradientTokens()
    public var animations: CraftAnimationTokens = CraftDefaultAnimationTokens()
    
    public init() {}
}
```

### 5.3 Step 3: Root Injection
In `VocabCraftApp.swift`:
```swift
WindowGroup {
    RootContentView()
        .craftTheme(VocabTheme())
}
```

### 5.4 Step 4: Incremental Screen Refactoring (Zero Downtime)
1. **Settings Screen:** Replace ad-hoc rows in `SettingsView.swift` with `CraftListRow`, `CraftStepper`, `CraftToggle`.
2. **Homepage & Search:** Replace action buttons, bento cards, and search bar with `CraftCard`, `CraftSearchBar`, `CraftButton`.
3. **Vocabulary & Vault:** Adopt `CraftFilterChip`, `CraftProgressBar`, `CraftEmptyState`.
4. **Phase 2 Components:** Implement specialized drill/quiz/roadmap components as needed.

---

## 6. Verification & Testing Plan

### 6.1 Automated Unit Tests
- `CraftUIKitTests`:
  - Token conformance tests (colors, typography, spacing).
  - Environment injection tests (verifying default theme fallback and custom theme overrides).
  - Component state tests (button loading state, textfield focus/error bindings).

### 6.2 Visual Verification via `CraftCatalogView`
- Interactive catalog view previewable in Xcode Previews and runnable as a test harness.
- Live theme-switching toggle (Default Slate Theme <-> VocabCraft Theme <-> Dark/Light Mode).
- Interactive validation of buttons, inputs, cards, toasts, and steppers.
