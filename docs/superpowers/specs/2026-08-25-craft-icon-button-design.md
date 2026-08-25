# Design Document: CraftIconButton Redesign & Capabilities Expansion

- **Author**: Antigravity Design Agent
- **Date**: 2026-08-25
- **Status**: Draft for Review
- **Target File**: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift`
- **Tests**: `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`

---

## 1. Overview & Problem Statement

`CraftIconButton` is an atomic UI component in `CraftUIKit` designed for standalone icon actions (such as Bookmark, Favorite, Share, Delete, Close, and Settings). While it correctly adheres to Apple HIG's 44x44pt touch target minimum, an in-depth UI/UX and architectural audit revealed several critical shortcomings:

1. **Broken 3D Tactile Depression (Critical)**: `CraftIconButton` wraps `craftSurface` inside `Button`'s label with a static `isPressed: false`. When `.style = .tactile3D` is used, the physical 3D depression offset (`depressOffset = resolvedDepth`) never fires on press because the view cannot observe touch state changes.
2. **Missing Disabled State Visual Feedback**: The component ignores `@Environment(\.isEnabled)`. When disabled via `.disabled(true)`, the button visually looks 100% identical to its enabled state, confusing users.
3. **No Haptic Feedback**: Lacks sensory tactile feedback on tap.
4. **Missing Loading State (`isLoading`)**: Unlike `CraftButton`, `CraftIconButton` does not have a native spinner state for asynchronous actions.
5. **Missing Selected / Toggle State (`isSelected`)**: Common icon button use cases (Favorite, Bookmark, Audio Mute) require toggle states with appropriate accessibility traits.
6. **New Variant Needed (`.danger`)**: Destructive actions (Delete, Trash, Cancel) need dedicated semantic styling.
7. **Color & Surface Inconsistencies**: `.ghost` and `.outline` default to `textPrimary` instead of `brandPrimary`, and `.glass` over-tints with opaque theme colors rather than maintaining translucent frosted glass characteristics.

---

## 2. Requirements & Goals

### 2.1 Functional Requirements
- **100% Backwards-Compatible API**: Existing code calling `CraftIconButton(symbol: ...)` or `CraftIconButton(iconName: ...)` must continue to compile and work seamlessly.
- **Physical 3D Press Support**: `.style(.tactile3D)` must animate mechanical bottom depression on press.
- **State Handling**:
  - `isEnabled == false`: Opacity reduced to `0.4`, interactions disabled.
  - `isLoading == true`: Displays `CraftSpinner` matching icon size, interactions disabled.
  - `isSelected == true`: Icon/surface reflects active selection, adds `.accessibilityAddTraits(.isSelected)`.
- **Haptic Feedback**: Triggers `.sensoryFeedback(.impact(weight: .light))` on touch press down.
- **New Variant**: Add `case danger` to `CraftIconButtonVariant`.
- **Accessibility & Localization**: Support `LocalizedStringKey` for `accessibilityLabel`, and optional `accessibilityHint`.

### 2.2 Non-Functional Requirements
- Strictly follow Apple Human Interface Guidelines (HIG) for touch targets (min 44x44pt).
- Respect `accessibilityReduceMotion` (no scaling/unnecessary motion when enabled).
- iOS 17+ / Swift 6 Sendable compliance.

---

## 3. Architecture & Detailed Design

### 3.1 Separation of Concerns: Button vs ButtonStyle

```
┌──────────────────────────────────────────────────────────┐
│                   CraftIconButton (View)                 │
│  - Public API initializers                               │
│  - Guard action execution (!isLoading && isEnabled)     │
│  - Content: CraftSpinner (if loading) or CraftIcon       │
│  - Accessibility attributes & traits                     │
└────────────────────────────┬─────────────────────────────┘
                             │ applies
                             ▼
┌──────────────────────────────────────────────────────────┐
│             CraftIconButtonStyle (ButtonStyle)           │
│  - Reads `configuration.isPressed` and `isEnabled`       │
│  - Renders `craftSurface(..., isPressed: isPressed)`     │
│  - Enforces min 44x44pt hit-test box                     │
│  - Manages spring press scaling and haptic feedback      │
│  - Renders legacy fallback shapes & strokes              │
└──────────────────────────────────────────────────────────┘
```

### 3.2 Public API Specification

```swift
public enum CraftIconButtonShape: Sendable, Equatable {
    case circle
    case square // Rounded square using theme corner radius tokens
    case roundedRectangle(radius: CGFloat)

    public static var allCases: [CraftIconButtonShape] {
        [.circle, .square, .roundedRectangle(radius: 8)]
    }
}

public enum CraftIconButtonVariant: String, Sendable, CaseIterable {
    case filled
    case subtle
    case outline
    case ghost
    case danger
}

public struct CraftIconButtonStyle: ButtonStyle {
    public let size: CraftIconSize
    public let shape: CraftIconButtonShape
    public let variant: CraftIconButtonVariant
    public let style: CraftSurfaceStyle?
    public let customTint: Color?
    public let isSelected: Bool
    public let isLoading: Bool
    ...
}

public struct CraftIconButton: View {
    public let iconName: String
    public let symbol: CraftSymbol?
    public let size: CraftIconSize
    public let shape: CraftIconButtonShape
    public let variant: CraftIconButtonVariant
    public let style: CraftSurfaceStyle?
    public let customTint: Color?
    public let isSelected: Bool
    public let isLoading: Bool
    public let accessibilityHint: String?
    public let action: () -> Void

    // 1. Symbol + String A11y
    public init(
        symbol: CraftSymbol,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        isSelected: Bool = false,
        isLoading: Bool = false,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    )

    // 2. Symbol + LocalizedStringKey A11y
    public init(
        symbol: CraftSymbol,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        isSelected: Bool = false,
        isLoading: Bool = false,
        accessibilityLabelKey: LocalizedStringKey,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    )

    // 3. String iconName + String A11y
    public init(
        iconName: String,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        isSelected: Bool = false,
        isLoading: Bool = false,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    )

    // 4. String iconName + LocalizedStringKey A11y
    public init(
        iconName: String,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        isSelected: Bool = false,
        isLoading: Bool = false,
        accessibilityLabelKey: LocalizedStringKey,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    )
}
```

### 3.3 Visual & Interaction Rules Matrix

| Variant / Style | Foreground Color | Background / Surface Fill | Border / Stroke |
| :--- | :--- | :--- | :--- |
| **.filled** | `textInverse` | `effectiveTint` | None |
| **.subtle** | `isSelected ? textInverse : effectiveTint` | `isSelected ? effectiveTint : effectiveTint.opacity(0.12)` | None |
| **.outline** | `isSelected ? textInverse : effectiveTint` | `isSelected ? effectiveTint : .clear` | `customTint ?? borderDefault` (1.5pt) |
| **.ghost** | `isSelected ? textInverse : effectiveTint` | `isSelected ? effectiveTint : .clear` | None |
| **.danger** | `textInverse` (if filled/selected) or `statusDanger` | `statusDanger` (if filled/selected) or `statusDanger.opacity(0.12)` | `statusDanger` (if outline) |
| **style: .glass** | `customTint ?? brandPrimary` | `.ultraThinMaterial` + subtle tint | Specular glass border gradient |
| **style: .tactile3D** | `customTint ?? brandPrimary` | `surfaceCard` with bottom extrusion bevel | Depresses vertically by `depth` when pressed |

---

## 4. Verification & Testing Strategy

### 4.1 Automated Unit Tests (`AtomComponentTests.swift`)
1. **Instantiation Tests**: Verify all 5 variants (`filled`, `subtle`, `outline`, `ghost`, `danger`) and all 3 shapes (`circle`, `square`, `roundedRectangle`).
2. **State Tests**:
   - `isLoading: true` renders spinner and prevents action invocation.
   - `isSelected: true` includes `.isSelected` accessibility trait.
   - `accessibilityLabel` and `accessibilityHint` correctly populated.
3. **Touch Target Tests**: Visual dimension vs min touch target frame (44pt) verification.

### 4.2 Manual / Visual Preview Inspection
- Verify interactive spring scaling and tactile 3D extrusion in SwiftUI Preview canvas across Light and Dark appearance.
