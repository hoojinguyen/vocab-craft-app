# Design Specification: CraftChoiceCard Modernization, Dynamic Prefix Styles & Liquid Glass Contrast Refinement

**Date:** 2026-08-26  
**Status:** Validated Design (Awaiting User Review Gate)  
**Target:** `CraftUIKit` -> `CraftChoiceCard` (`CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`)  

---

## 1. Overview & Problem Statement

`CraftChoiceCard` is the core interactive multiple-choice and quiz component in `CraftUIKit`. A senior UI/UX design audit across iOS 17–26 design systems identified three critical opportunities for modernization:

1. **Text Contrast & Readability Breakdown**: In active, correct, and wrong states (particularly in `.glass` and tinted modes), saturated background flood fills caused `textSecondary` and `textPrimary` to lose legibility (~1.8:1 contrast ratio, failing WCAG AA). Trailing indicator icons also blended directly into the background color.
2. **"Box-in-a-Box" Visual Clutter**: The prefix badge (e.g. A/B/C/D) was rigidly rendered as a rounded rectangle inside another rounded card container, creating a dated and bulky aesthetic.
3. **Liquid Glass Translucency Degradation**: Saturated opaque color fills undermined Apple's iOS 26 Liquid Glass optical refraction guidelines, turning dynamic translucent glass into flat opaque plastic.

### Design Objectives
- **Adopt Design Approach A**: Retain high-clarity background surfaces (light 6–10% tint wash in Light mode, 14–18% in Dark mode), paired with vivid 2pt semantic border strokes and high-contrast prefix badges.
- **Dynamic Prefix Style System (`CraftChoicePrefixStyle`)**: Introduce `.circle` (new modern default), `.roundedSquare` (soft squircle), `.minimal` (editorial plain text), and `.none` (headless option).
- **Flawless Typography Contrast**: Keep `titleColor` at `theme.colors.textPrimary` and `subtitleColor` at `theme.colors.textSecondary`, guaranteeing WCAG AAA contrast ratios (>7:1 to >12:1).
- **iOS 26 Liquid Glass & Translucent Polish**: Ensure `.glass` style cards maintain optical refraction without nesting redundant glass effects or muddying text layers.
- **100% Backward Compatibility**: Preserve all existing initializers with sensible default parameters (`prefixStyle: .circle`).

---

## 2. Architecture & Public API Specifications

### 2.1 Prefix Style Enumeration

```swift
/// Visual badge styling for choice option prefixes (e.g. A/B/C/D).
public enum CraftChoicePrefixStyle: String, Sendable, CaseIterable {
    /// Elegant circle badge with crisp baseline alignment (Default).
    case circle
    /// Soft squircle badge with subtle corner curvature.
    case roundedSquare
    /// Clean editorial typography with no bounding container or border.
    case minimal
    /// Completely hidden prefix badge (useful for survey and settings checklists).
    case none
}
```

### 2.2 Public Initializers

```swift
public struct CraftChoiceCard: View {
    // String variant
    public init(
        prefix: String? = "A",
        prefixStyle: CraftChoicePrefixStyle = .circle,
        title: String,
        subtitle: String? = nil,
        state: CraftChoiceState = .idle,
        style: CraftSurfaceStyle? = nil,
        action: @escaping () -> Void
    )

    // LocalizedStringKey variant
    public init(
        prefix: LocalizedStringKey? = nil,
        prefixStyle: CraftChoicePrefixStyle = .circle,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        state: CraftChoiceState = .idle,
        style: CraftSurfaceStyle? = nil,
        action: @escaping () -> Void
    )
}
```

---

## 3. Visual & Interaction Specifications

### 3.1 Prefix Badge Presentation Matrix

| Prefix Style | Idle State | Selected State | Correct State | Wrong State | Disabled State |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`.circle`** (32×32) | `surfaceSubtle` fill, `borderDefault` stroke, `textPrimary` ink | `brandPrimary` fill, white ink, subtle shadow | `statusSuccess` fill, white ink, bounce effect | `statusDanger` fill, white ink, shake effect | `surfaceSubtle` fill (0.5 opacity), `textMuted` ink |
| **`.roundedSquare`** (32×32, r: 8) | `surfaceSubtle` fill, `borderDefault` stroke, `textPrimary` ink | `brandPrimary` fill, white ink | `statusSuccess` fill, white ink | `statusDanger` fill, white ink | `surfaceSubtle` fill (0.5 opacity), `textMuted` ink |
| **`.minimal`** | No container, `textSecondary` ink | No container, `brandPrimary` ink (bold) | No container, `statusSuccess` ink (bold) | No container, `statusDanger` ink (bold) | No container, `textMuted` ink |
| **`.none`** | Zero frame width, omitted from layout | Zero frame width, omitted from layout | Zero frame width, omitted from layout | Zero frame width, omitted from layout | Zero frame width, omitted from layout |

### 3.2 Card Surface & State Wash (Approach A)

- **Idle**: Standard surface matching the selected `CraftSurfaceStyle` (`.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`).
- **Selected**: 
  - Background overlay: `.craftDynamic(light: brandPrimary.opacity(0.08), dark: brandPrimary.opacity(0.16))`
  - Border stroke: `brandPrimary` with 2.0pt width
- **Correct**:
  - Background overlay: `.craftDynamic(light: statusSuccess.opacity(0.08), dark: statusSuccess.opacity(0.16))`
  - Border stroke: `statusSuccess` with 2.0pt width
- **Wrong**:
  - Background overlay: `.craftDynamic(light: statusDanger.opacity(0.08), dark: statusDanger.opacity(0.16))`
  - Border stroke: `statusDanger` with 2.0pt width
- **Disabled**:
  - Opacity: 0.6
  - Border stroke: `borderDefault.opacity(0.35)` with 1.5pt width

### 3.3 Typography & Color Inks

- **Title**: `theme.typography.headline` (San Francisco Pro, semibold), `foregroundStyle(theme.colors.textPrimary)` across all interactive states (`textMuted` when `.disabled`).
- **Subtitle**: `theme.typography.bodyMedium` (San Francisco Pro, regular), `foregroundStyle(theme.colors.textSecondary)` across all interactive states (`textMuted` when `.disabled`).
- **Contrast Guarantee**: Text sits on light translucent wash surfaces, maintaining >7:1 (WCAG AAA) contrast in Light and Dark modes.

### 3.4 Trailing Indicator & Motion

- **Correct Answer**: `CraftIcon(.checkmarkCircle, size: .md, color: theme.colors.statusSuccess, renderingMode: .hierarchical)` with `.symbolEffect(.bounce, value: state)` and spring transition `.scale.combined(with: .opacity)`.
- **Wrong Answer**: `CraftIcon(.wrongCircle, size: .md, color: theme.colors.statusDanger, renderingMode: .hierarchical)` with `.symbolEffect(.bounce, value: state)` and `ChoiceShakeEffect(shakes: shakeCount)`.
- **Haptics**:
  - `.sensoryFeedback(.selection, trigger: state == .selected)`
  - `.sensoryFeedback(.success, trigger: state == .correct)`
  - `.sensoryFeedback(.error, trigger: state == .wrong)`
  - `.sensoryFeedback(.impact(weight: .light), trigger: isPressed)`

### 3.5 Liquid Glass iOS 26 Implementation & Fallback

```swift
@ViewBuilder
private var cardBackground: some View {
    ZStack {
        switch style {
        case .glass:
            if #available(iOS 26, macOS 26, *) {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .fill(theme.colors.surfaceCard)
                } else {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .glassEffect(cardGlassVariant, in: RoundedRectangle(cornerRadius: theme.radii.lg))
                }
            } else {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .fill(theme.colors.surfaceCard)
                } else {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
                }
            }
        case .flat:
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .fill(theme.colors.surfaceSubtle)
        case .elevated:
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .fill(theme.colors.surfaceElevated)
        case .outlined, .tactile3D:
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .fill(theme.colors.surfaceCard)
        }

        if state != .idle && state != .disabled {
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .fill(stateTintOverlay)
        }
    }
}
```

---

## 4. Verification Plan

1. **Swift Package Build & Tests**:
   - `swift test --package-path CraftUIKit`
   - Validate `ControlComponentTests.swift` and `InteractiveCardTests.swift` pass with 100% assertions.
2. **Catalog & Visual Preview Verification**:
   - Update `CraftCatalogView.swift` to demonstrate `CraftChoicePrefixStyle` options (`.circle`, `.roundedSquare`, `.minimal`, `.none`).
   - Validate that text contrast is razor sharp in Light and Dark appearances across all 5 states.
3. **Accessibility Verification**:
   - Ensure VoiceOver traits (`.isButton`, `.isSelected`) and accessibility values match localized strings.
   - Verify `reduceMotion` and `reduceTransparency` fallback branches.
