# Design Specification: CraftSearchBar UI/UX Evolution, Performance Optimization & Full-Spectrum Surface Styles

**Date:** 2026-08-26  
**Status:** Validated Design (Awaiting User Review Gate)  
**Target:** `CraftUIKit` -> `CraftSearchBar` (`CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift`)  

---

## 1. Overview & Problem Statement

`CraftSearchBar` is a foundational control in `CraftUIKit` used for search queries, content filtering, and dictionary lookups. A senior UI/UX, design system, and performance audit using `ios-design-agent-skill`, `swiftui-design-skill`, and `swiftui-performance` identified 5 critical bottlenecks and enhancement areas:

1. **Focus Lag & Animation Invalidation Storm**:
   - Compounding double `.animation(theme.animations.springSnappy, value: isFocused)` on both inner and outer `HStack` containers triggered multiple simultaneous spring transactions on focus change.
   - Dynamic `.shadow(color: ..., radius: ...)` recalculation during spring transitions forced continuous GPU offscreen blur passes.
   - Inserting the Cancel button via horizontal container resizing collided directly with iOS software keyboard presentation, leading to visible frame drops (hitches) on 120Hz ProMotion displays.
2. **Hit-Testing Dead Zones**:
   - `padding(.horizontal, theme.spacing.base)` and icon leading areas lacked `.contentShape(Rectangle())` tap interception, creating unresponsive dead zones where taps failed to focus the `TextField`.
3. **Limited Surface Style Spectrum**:
   - `CraftSearchBarStyle` was restricted to `.standard`, `.recessed`, `.glass`, lacking integration with CraftUIKit's 5 core surface styles (`.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`).
4. **Lack of Ergonomic Sizing**:
   - Fixed 44pt height with no compact (`sm` 36pt) or hero (`lg` 52pt) options for toolbars, sheets, or explore screens.
5. **Missing Sensory Feedback & Micro-Interactions**:
   - Clear (X) and Cancel actions lacked haptic confirmation (`.sensoryFeedback`), SF Symbol search icon lacked state-driven bounce animation, and Clear button lacked smooth entry/exit transitions.

### Design Objectives
- **Zero-Lag Focus & Responsive Gestures**: Single-transaction spring animation, full-container tap interception, static/precalculated elevation shadow, and optimized search keyboard traits.
- **Full-Spectrum Surface Styles**: Expand `CraftSearchBarStyle` to support all 7 variants (`standard`, `flat`, `elevated`, `outlined`, `recessed`, `tactile3D`, `glass`) with automatic fallback to `Environment(\.craftSurfaceStyle)`.
- **Three Ergonomic Sizing Tiers (`CraftSearchBarSize`)**:
  - `.sm` (36pt height, 14pt typography, `.sm` icons, 10pt horizontal padding): For compact filter headers and dense toolbars.
  - `.md` (44pt height, 16pt typography, `.md` icons, 12pt horizontal padding): Standard search input (Default).
  - `.lg` (52pt height, 17pt typography, `.md` icons, 16pt horizontal padding): Prominent hero search in Explore/Home views.
- **Sensory & Visual Polish**:
  - SF Symbol `.bounce` effect on focus activation and query submit.
  - Haptic `.sensoryFeedback(.impact(weight: .light))` on Clear and Cancel actions.
  - Smooth scale & opacity transition for Clear button.
  - Asymmetric smooth transition for Cancel button.
  - Optional `isLoading` state displaying a themed `CraftSpinner`.
  - Apple HIG compliant 44x44pt minimum touch target bounds for action buttons.
- **100% Backward Compatibility**: Preserve all existing initializers with sensible default parameters.

---

## 2. Architecture & Public API Specifications

### 2.1 Style & Size Enumerations

```swift
/// Visual style variants for CraftSearchBar supporting CraftUIKit's full surface spectrum.
public enum CraftSearchBarStyle: String, Sendable, CaseIterable {
    case standard
    case flat
    case elevated
    case outlined
    case recessed
    case tactile3D
    case glass

    public var surfaceStyle: CraftSurfaceStyle {
        switch self {
        case .standard, .flat: return .flat
        case .elevated: return .elevated
        case .outlined: return .outlined
        case .recessed: return .flat
        case .tactile3D: return .tactile3D
        case .glass: return .glass
        }
    }
}

/// Sizing tiers for CraftSearchBar.
public enum CraftSearchBarSize: String, Sendable, CaseIterable {
    case sm
    case md
    case lg

    public var height: CGFloat {
        switch self {
        case .sm: return 36
        case .md: return 44
        case .lg: return 52
        }
    }

    public var iconSize: CraftIconSize {
        switch self {
        case .sm: return .sm
        case .md: return .md
        case .lg: return .md
        }
    }

    public var horizontalPadding: CGFloat {
        switch self {
        case .sm: return 10
        case .md: return 12
        case .lg: return 16
        }
    }
}
```

### 2.2 Public Component & Initializers

```swift
public struct CraftSearchBar: View {
    public var text: Binding<String>
    public let placeholder: String
    public let size: CraftSearchBarSize
    public let style: CraftSearchBarStyle
    public let shape: CraftSearchBarShape
    public let customTint: Color?
    public let customGradient: LinearGradient?
    public let trailingIcon: String?
    public let trailingAction: (() -> Void)?
    public let isLoading: Bool
    public let onCancel: (() -> Void)?
    public let onSubmit: (() -> Void)?

    // 1. String placeholder initializer (Default)
    public init(
        text: Binding<String>,
        placeholder: String = CraftLocalized.string("craft.search.placeholder"),
        size: CraftSearchBarSize = .md,
        style: CraftSearchBarStyle = .standard,
        shape: CraftSearchBarShape = .capsule,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        isLoading: Bool = false,
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    )

    // 2. LocalizedStringKey placeholder initializer
    public init(
        text: Binding<String>,
        placeholder: LocalizedStringKey,
        size: CraftSearchBarSize = .md,
        style: CraftSearchBarStyle = .standard,
        shape: CraftSearchBarShape = .capsule,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        isLoading: Bool = false,
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    )
}
```

---

## 3. Visual & Interaction Specifications

### 3.1 Style Presentation Matrix

| Style | Background Surface | Border Stroke (Unfocused) | Border Stroke (Focused) | Shadow / Depth |
| :--- | :--- | :--- | :--- | :--- |
| **`.standard` / `.flat`** | `theme.colors.surfaceSubtle` | `theme.colors.borderDefault` (1.0pt) | `theme.colors.borderFocus` (1.5pt) | None |
| **`.elevated`** | `theme.colors.surfaceElevated` | Top specular gradient (1.0pt) | `theme.colors.borderFocus` (1.5pt) | `theme.shadows.sm` |
| **`.outlined`** | `theme.colors.surfaceCard` | `theme.colors.borderDefault` (1.0pt) | `theme.colors.borderFocus` (1.5pt) | None |
| **`.recessed`** | `theme.colors.surfaceSubtle` + Top inner gradient (`Color.black.opacity(0.12)`) | `theme.colors.hairline` (1.0pt) | `theme.colors.borderFocus` (1.5pt) | Inset shadow feel |
| **`.tactile3D`** | `theme.colors.surfaceCard` | 3D specular gradient stroke | `theme.colors.borderFocus` (1.5pt) | 2pt bottom extrusion bevel |
| **`.glass`** | `.ultraThinMaterial` + tint overlay (`theme.glass.tintOpacity`) | `theme.glass.borderGradient` + top specular | `theme.colors.borderFocus` (1.5pt) | Specular glass glow |

### 3.2 Performance & Gesture Architecture

1. **Elimination of Compounding Animations**:
   - Remove `.animation(theme.animations.springSnappy, value: isFocused)` from the inner input pill.
   - Apply a single `.animation(theme.animations.springSnappy, value: isFocused)` to the root `HStack`.
2. **Container Tap Interception**:
   ```swift
   .contentShape(Rectangle())
   .onTapGesture {
       if !isFocused {
           isFocused = true
       }
   }
   ```
3. **Optimized Search Keyboard Modifiers**:
   ```swift
   .autocorrectionDisabled()
   .textInputAutocapitalization(.never)
   .submitLabel(.search)
   ```
4. **Cancel Button Asymmetric Transition**:
   ```swift
   .transition(
       .asymmetric(
           insertion: .move(edge: .trailing).combined(with: .opacity),
           removal: .opacity
       )
   )
   ```
5. **Clear Button Smooth Scale Transition**:
   ```swift
   if !text.wrappedValue.isEmpty && !isLoading {
       Button(action: {
           text.wrappedValue = ""
           clearTrigger.toggle()
       }) {
           CraftIcon(.wrongCircle, size: .sm, color: theme.colors.textMuted)
               .frame(width: 28, height: 28)
               .contentShape(Rectangle())
       }
       .buttonStyle(.plain)
       .frame(minWidth: 44, minHeight: 44)
       .transition(.scale(scale: 0.8).combined(with: .opacity))
       .sensoryFeedback(.impact(weight: .light), trigger: clearTrigger)
       .accessibilityLabel(CraftLocalized.string("craft.search.clear_a11y"))
   }
   ```

### 3.3 Micro-Interactions & Haptics

- **Search Icon Motion**: `CraftIcon(.search, size: size.iconSize, color: isFocused ? theme.colors.borderFocus : theme.colors.textMuted).symbolEffect(.bounce, value: isFocused)`
- **Loading Spinner**: When `isLoading` is true, display `CraftSpinner(size: size.iconSize, color: theme.colors.brandPrimary)` in place of or beside the leading/trailing action slot.
- **Haptic Triggers**:
  - Tapping Clear Button: `.sensoryFeedback(.impact(weight: .light), trigger: clearTrigger)`
  - Tapping Cancel Button: `.sensoryFeedback(.selection, trigger: cancelTrigger)`

---

## 4. Verification Plan

1. **Swift Package Build & Tests**:
   - `swift test --package-path CraftUIKit`
   - Validate `ControlComponentTests.swift` passes with 100% assertions across all 7 style cases (`standard`, `flat`, `elevated`, `outlined`, `recessed`, `tactile3D`, `glass`), all 3 size cases (`sm`, `md`, `lg`), `isLoading` state, custom tints/gradients, and localization.
2. **Catalog & Visual Preview Verification**:
   - Update `CraftCatalogView.swift` Controls section to feature interactive Style, Size, and Loading pickers.
   - Run `CatalogViewTests.swift` to ensure snapshot and navigation stability.
3. **Accessibility Verification**:
   - Ensure VoiceOver labels for Clear (`craft.search.clear_a11y`), Trailing Action (`craft.search.trailing_action_a11y`), and Cancel buttons.
   - Verify 44x44pt minimum touch target compliance.
   - Verify `reduceMotion` compatibility.
