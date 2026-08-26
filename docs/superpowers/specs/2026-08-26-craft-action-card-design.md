# Design Specification: CraftActionCard in CraftUIKit

**Date:** 2026-08-26  
**Status:** Validated Design (Awaiting User Review Gate)  
**Target:** `CraftUIKit` -> `CraftActionCard` (`CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActionCard.swift`)  

---

## 1. Overview & Problem Statement

In the VocabCraft app, high-engagement drill entry points and navigation surfaces rely on **Bento-style Action Cards**—most notably the **Reflex Blitz Mode Selection Modal** (4 cards: Speaking, Typing, Multiple Choice, Listening) and the **Homepage Action Cards Grid** (Reflex Drill & SRS Queue).

Currently, these cards are implemented via custom, ad-hoc SwiftUI views within each feature (e.g., [`ReflexBlitzModeSelectionView.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift) and [`ActionCardsGrid.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift)). This results in:
1. **Code Duplication & Maintenance Burden**: Layout, typography, badges, and gradient borders are redundantly defined.
2. **Missing Surface Style Flexibility**: The existing custom cards cannot dynamically adapt to `CraftSurfaceStyle` (`.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`, `.gradient`), breaking design system uniformity.
3. **Inconsistent Tactile & Liquid Glass Integration**: Gamification 3D press effects and modern Apple Liquid Glass (iOS 26 HIG) are not systematically applied.

### Objectives
- **Standardized `CraftActionCard` Molecule**: Create a reusable, theme-driven Bento action card component in `CraftUIKit`.
- **Full Surface Style Matrix Support**: Support all 6 `CraftSurfaceStyle` variants (`.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`, `.gradient`) responding to the `\.craftSurfaceStyle` environment.
- **Precision Tactile 3D Extrusion**: Adopt the refined mechanical depression model from `CraftChoiceCard` (4pt bottom bevel, top specular highlight, 0.99 spring scale, zero corner distortion).
- **Apple Liquid Glass (iOS 26 HIG)**: Adopt `.glassEffect(.regular.tint(...).interactive())` on iOS 26+ with `.ultraThinMaterial` fallback and full `accessibilityReduceTransparency` support.
- **Drop-in Integration**: Refactor `ReflexBlitzModeSelectionView` and `ActionCardsGrid` to use `CraftActionCard`.
- **Comprehensive Testing & Catalog**: Provide unit tests in `CraftUIKitTests` and an interactive preview in `CraftCatalogView`.

---

## 2. Architecture & Public API Specification

`CraftActionCard` will reside in `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActionCard.swift`.

```swift
import SwiftUI

/// A versatile, theme-driven Bento Action Card component designed for mode selection,
/// practice launchers, and dashboard navigation.
///
/// Supports all 6 `CraftSurfaceStyle` variants (`.outlined`, `.tactile3D`, `.glass`, `.elevated`, `.flat`, `.gradient`),
/// tactile 3D physical extrusion, Apple Liquid Glass (iOS 26), dynamic accent color tinting,
/// badges, icons, accessibility, and haptic feedback.
public struct CraftActionCard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var envSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let subtitleKey: LocalizedStringKey?
    private let rawSubtitle: String?

    public let iconName: String?
    public let symbol: CraftSymbol?
    public let badgeText: String?
    public let badgeKey: LocalizedStringKey?
    public let badgeIcon: String?
    public let accentColor: Color?
    public let explicitStyle: CraftSurfaceStyle?
    public let showChevron: Bool
    public let action: () -> Void

    public var title: String { rawTitle ?? "" }
    public var subtitle: String? { rawSubtitle }

    public var resolvedStyle: CraftSurfaceStyle {
        explicitStyle ?? (envSurfaceStyle != .flat ? envSurfaceStyle : .outlined)
    }

    // MARK: - Initializers

    /// 1. Standard String-based Initializer
    public init(
        title: String,
        subtitle: String? = nil,
        iconName: String? = nil,
        badgeText: String? = nil,
        badgeIcon: String? = "stopwatch.fill",
        accentColor: Color? = nil,
        style: CraftSurfaceStyle? = nil,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.subtitleKey = nil
        self.rawSubtitle = subtitle
        self.iconName = iconName
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.badgeText = badgeText
        self.badgeKey = nil
        self.badgeIcon = badgeIcon
        self.accentColor = accentColor
        self.explicitStyle = style
        self.showChevron = showChevron
        self.action = action
    }

    /// 2. LocalizedStringKey-based Initializer
    public init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        iconName: String? = nil,
        badgeText: String? = nil,
        badgeIcon: String? = "stopwatch.fill",
        accentColor: Color? = nil,
        style: CraftSurfaceStyle? = nil,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.titleKey = title
        self.rawTitle = nil
        self.subtitleKey = subtitle
        self.rawSubtitle = nil
        self.iconName = iconName
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.badgeText = badgeText
        self.badgeKey = nil
        self.badgeIcon = badgeIcon
        self.accentColor = accentColor
        self.explicitStyle = style
        self.showChevron = showChevron
        self.action = action
    }

    /// 3. CraftSymbol-based Initializer
    public init(
        title: String,
        subtitle: String? = nil,
        symbol: CraftSymbol,
        badgeText: String? = nil,
        badgeIcon: String? = "stopwatch.fill",
        accentColor: Color? = nil,
        style: CraftSurfaceStyle? = nil,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.subtitleKey = nil
        self.rawSubtitle = subtitle
        self.iconName = symbol.rawValue
        self.symbol = symbol
        self.badgeText = badgeText
        self.badgeKey = nil
        self.badgeIcon = badgeIcon
        self.accentColor = accentColor
        self.explicitStyle = style
        self.showChevron = showChevron
        self.action = action
    }
}
```

---

## 3. Visual & Surface Style Specifications

### 3.1 Card Layout Structure

```
+-------------------------------------------------------------+
|  [Icon: 26pt]                           [Badge: ⏱️ 6.0s]     |
|                                                             |
|  Title (Bold Rounded Headline)                              |
|  Subtitle description text spanning                         |
|  up to 3 lines cleanly...                                   |
|                                                             |
|                                                   [ > ]     |
+-------------------------------------------------------------+
```

* **Dimensions**: `minHeight: 160pt`, `padding: 18pt`, `cornerRadius: 22pt` (`theme.radii.xl` or continuous curvature).
* **Header Slot**:
  * Leading: `CraftIcon` or `Image(systemName:)` size 26pt, semibold, `.hierarchical` rendering with `accentColor`.
  * Trailing: Optional `CraftBadge(badgeText, iconName: badgeIcon, variant: .subtle, customTint: accentColor, size: .sm)`.
* **Body Slot**:
  * Title: `theme.typography.headline.bold().rounded()`, `textPrimary` color.
  * Subtitle: `theme.typography.caption`, `textSecondary` / `textMuted` color, `lineLimit(3)`, multiline leading alignment.
* **Footer Slot**:
  * Trailing Chevron: `Image(systemName: "chevron.forward").font(.system(size: 12, weight: .bold)).foregroundStyle(effectiveAccent.opacity(0.8))`.

---

### 3.2 6 Surface Styles Visual Matrix

| Style | Background & Tinting | Border & Specular Highlights | Shadows & Press Interaction |
| :--- | :--- | :--- | :--- |
| **`.outlined`** *(Default Bento)* | `theme.colors.surfaceCard` + `accentColor.opacity(0.06)` top-left wash | `LinearGradient(colors: [accentColor.opacity(0.35), Color.white.opacity(0.08)])` stroke (1.0pt) | `theme.shadows.sm`, spring press (scale `0.98`) |
| **`.tactile3D`** | `theme.colors.surfaceCard` (crisp white) + `theme.depths.topHighlight` stroke | `accentColor.opacity(0.35)` stroke + top edge bevel | **4pt bottom extrusion lip** (`borderDefault` + `accentColor.opacity(0.25)`), **4pt mechanical depression**, light haptic, `0.99` scale |
| **`.glass`** *(iOS 26 HIG)* | `.glassEffect(.regular.tint(accentColor).interactive())` / `.ultraThinMaterial` + tint | `theme.glass.borderGradient` with specular edge | Translucent refraction, fallback to opaque `surfaceCard` on `accessibilityReduceTransparency` |
| **`.elevated`** | `theme.colors.surfaceElevated` + subtle `accentColor.opacity(0.04)` | Top-leading specular stroke gradient | Layered shadow (`theme.shadows.md`), spring press (scale `0.98`) |
| **`.flat`** | `theme.colors.surfaceSubtle` + subtle `accentColor.opacity(0.04)` | No stroke | Flat presentation, spring press (scale `0.98`) |
| **`.gradient`** | Linear gradient interpolated from `accentColor` | Translucent subtle white stroke | Inverted white typography and monochrome white icons/badges |

---

### 3.3 Tactile 3D Button Style (`CraftActionCardButtonStyle`)

Following the proven architecture from `CraftChoiceCard`:

```swift
public struct CraftActionCardButtonStyle: ButtonStyle {
    public let style: CraftSurfaceStyle
    public let depth: CGFloat
    public let cornerRadius: CGFloat
    public let accentColor: Color?
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let isTactile = style == .tactile3D
        let effectiveDepth = isTactile ? depth : 0
        let depressOffset = (isPressed && isTactile) ? depth : 0

        ZStack(alignment: .top) {
            // Seamless extruded 3D base layer matching exact corner curvature
            if isTactile {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(bottomLipColor)
                    .offset(y: depth)
            }

            // Top interactive card face
            configuration.label
                .offset(y: depressOffset)
        }
        .padding(.bottom, isTactile ? effectiveDepth : 0)
        .scaleEffect(isPressed && !reduceMotion ? (isTactile ? 0.99 : 0.98) : 1.0)
        .animation(theme.animations.springSnappy, value: isPressed)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in
            pressed
        }
    }

    private var bottomLipColor: Color {
        let baseLip = Color.craftDynamic(light: Color(hex: 0xD1D5DB), dark: Color(hex: 0x374151))
        if let accentColor {
            return baseLip.opacity(0.7).blendMode(.multiply)
        }
        return baseLip
    }
}
```

---

## 4. Accessibility & Platform Support

- **Screen Readers (VoiceOver)**:
  - Container combined with `.accessibilityElement(children: .combine)`.
  - Label: `accessibilityLabel("\(title), \(badgeText != nil ? "\(badgeText!), " : "")\(subtitle ?? "")")`.
  - Hint: `accessibilityHint("Double-tap to select \(title) mode")`.
  - Traits: `.accessibilityAddTraits(.isButton)`.
- **Dynamic Type**: All text elements scale seamlessly with San Francisco Rounded Dynamic Type.
- **Reduce Motion**: All scale transitions and depression offsets disable when `accessibilityReduceMotion` is enabled.
- **Reduce Transparency**: Glass surfaces automatically fall back to opaque solid surfaces when `accessibilityReduceTransparency` is active.

---

## 5. Integration Plan in `VocabCraftApp`

1. **`ReflexBlitzModeSelectionView.swift`**:
   - Replace private `@ViewBuilder private func modeCard(...)` with `CraftActionCard`.
   - Map `item.title`, `item.subtitle`, `item.badgeText`, `item.iconName`, `item.accentColor`.
   - Remove redundant local button styles and custom border drawing.
2. **`ActionCardsGrid.swift`**:
   - Replace local `Button` implementations with `CraftActionCard` for both Reflex Drill Card and SRS Queue Card.
3. **`CraftCatalogView.swift`**:
   - Add a dedicated section under "Containers & Action Cards" showing `CraftActionCard` across all 6 surface styles with light/dark preview.

---

## 6. Verification & Test Plan

### 6.1 Automated Tests (`swift test --package-path CraftUIKit`)
- **Initializer Tests**: Verify String, LocalizedStringKey, and CraftSymbol initializers construct correctly.
- **Surface Resolution Tests**: Verify `.craftSurfaceStyle` environment modifier propagates to `CraftActionCard.resolvedStyle`.
- **Accessibility Tests**: Verify accessibility labels and button traits are accurately combined.

### 6.2 Visual Verification
- Xcode Previews for `CraftActionCard` across 6 Surface Styles.
- Interactive verification in `ReflexBlitzModeSelectionView` on iOS Simulator.
