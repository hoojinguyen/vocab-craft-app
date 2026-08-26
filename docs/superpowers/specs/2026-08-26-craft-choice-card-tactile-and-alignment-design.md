# Design Specification: CraftChoiceCard Tactile 3D Refinement & Flexible Alignment

**Date:** 2026-08-26  
**Status:** Validated Design (Awaiting User Review Gate)  
**Target:** `CraftUIKit` -> `CraftChoiceCard` (`CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`)  

---

## 1. Overview & Problem Statement

`CraftChoiceCard` is the primary interactive selection and quiz component in `CraftUIKit`. In language learning exercises (such as video listening comprehension, vocabulary drills, and sentence completion), options often consist of short standalone sentences or phrases that benefit from a **centered alignment** and a **gamified 3D tactile pushable surface** (inspired by modern apps like Duolingo, Busuu, and ELSA).

### Identified Issues in Current Implementation
1. **Hardcoded Leading Alignment**: `CraftChoiceCard` hardcodes an `HStack` with `Spacer(minLength: theme.spacing.sm)` and left-aligned text, making it impossible to render clean, centered single-phrase options without prefix badges.
2. **Tactile 3D Geometry Glitch**: `CraftChoiceCardButtonStyle` creates the bottom 3D lip using `.padding(.top, depth)` on a separate `RoundedRectangle`. This shrinks the base container's vertical bounds, shifting its corner radius center and producing mismatched, protruding corners ("wings") at the bottom left and bottom right.
3. **Overwashed Card Face in `.tactile3D`**: When `.selected`, the card face applies `stateTintOverlay` (semi-transparent brand wash) and a semi-transparent white `topHighlightOverlay`. This dilutes the crispness of the pure white card face and washes out the top edge of the vibrant 2pt brand border.
4. **Idle State Flatness**: In `.idle` state, the border and bottom lip use the exact same color token (`borderDefault`), reducing 3D depth perception.

### Objectives
- **Text Alignment Support (`textAlignment: TextAlignment = .leading`)**: Enable seamless switching between `.leading` (default, standard A/B/C/D quiz format) and `.center` (minimalist centered phrase cards for video/audio exercises).
- **Pixel-Perfect 3D Extrusion Geometry**: Replace `.padding(.top, depth)` with `.offset(y: depth)` and exact container padding in `CraftChoiceCardButtonStyle`, ensuring the 3D base layer curvature matches the top card face with zero corner distortion.
- **Crisp High-Contrast Tactile Surface**: Maintain a pure white face (`theme.colors.surfaceCard`) in `.tactile3D` with a vivid 2pt semantic border, removing interfering highlight overlays on colored borders.
- **Enhanced 3D Lip Palette**: Provide high-contrast bottom lip tones for `.idle` (`#D1D5DB` / darker neutral) and `.selected` (`brandSecondary` / shadow tone).
- **100% Backward Compatibility**: Preserve all existing initializers with sensible default parameters (`textAlignment: .leading`).

---

## 2. Architecture & Public API Specifications

### 2.1 Public Initializers with `textAlignment`

```swift
public struct CraftChoiceCard: View {
    public let textAlignment: TextAlignment
    
    // 1. String-based Initializer
    public init(
        prefix: String? = "A",
        prefixStyle: CraftChoicePrefixStyle = .circle,
        title: String,
        subtitle: String? = nil,
        textAlignment: TextAlignment = .leading,
        state: CraftChoiceState = .idle,
        style: CraftSurfaceStyle? = nil,
        showsStatusIndicator: Bool = true,
        correctIconName: String? = nil,
        wrongIconName: String? = nil,
        action: @escaping () -> Void
    )

    // 2. LocalizedStringKey Initializer
    public init(
        prefix: LocalizedStringKey? = nil,
        prefixStyle: CraftChoicePrefixStyle = .circle,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        textAlignment: TextAlignment = .leading,
        state: CraftChoiceState = .idle,
        style: CraftSurfaceStyle? = nil,
        showsStatusIndicator: Bool = true,
        correctIconName: String? = nil,
        wrongIconName: String? = nil,
        action: @escaping () -> Void
    )

    // 3. CraftSymbol Icon Initializer
    public init(
        prefix: String? = "A",
        prefixStyle: CraftChoicePrefixStyle = .circle,
        title: String,
        subtitle: String? = nil,
        textAlignment: TextAlignment = .leading,
        state: CraftChoiceState = .idle,
        style: CraftSurfaceStyle? = nil,
        showsStatusIndicator: Bool = true,
        correctSymbol: CraftSymbol,
        wrongSymbol: CraftSymbol? = nil,
        action: @escaping () -> Void
    )
}
```

---

## 3. Visual, Layout & Geometry Specifications

### 3.1 Card Surface Layout Hierarchy

When `textAlignment == .center`, `prefixStyle == .none` (or `prefix == nil`), and `!showsStatusIndicator`:
- The container renders a single centered `VStack(alignment: .center, spacing: theme.spacing.xxs)` with `.frame(maxWidth: .infinity, alignment: .center)` and `.multilineTextAlignment(.center)`.
- When `textAlignment == .leading` or when prefix/indicators exist, the layout preserves the horizontal `HStack { prefixBadge; textColumn; Spacer(); trailingIndicator }`.

```swift
@ViewBuilder
private var cardSurface: some View {
    let isPureCentered = textAlignment == .center && (prefixStyle == .none || (prefixKey == nil && rawPrefix == nil)) && (!showsStatusIndicator || (state != .correct && state != .wrong))

    Group {
        if isPureCentered {
            VStack(alignment: .center, spacing: theme.spacing.xxs) {
                titleView
                    .multilineTextAlignment(.center)
                if hasSubtitle {
                    subtitleView
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        } else {
            HStack(alignment: hasSubtitle ? .top : .center, spacing: theme.spacing.md) {
                if prefixStyle != .none && (prefixKey != nil || rawPrefix != nil) {
                    prefixBadge
                        .padding(.top, hasSubtitle ? 1 : 0)
                }

                VStack(alignment: textAlignment == .center ? .center : .leading, spacing: theme.spacing.xxs) {
                    titleView
                        .multilineTextAlignment(textAlignment)
                    if hasSubtitle {
                        subtitleView
                            .multilineTextAlignment(textAlignment)
                    }
                }
                .frame(maxWidth: textAlignment == .center ? .infinity : nil, alignment: textAlignment == .center ? .center : .leading)

                if textAlignment != .center {
                    Spacer(minLength: theme.spacing.sm)
                }

                if showsStatusIndicator {
                    trailingIndicator
                        .padding(.top, hasSubtitle ? 2 : 0)
                }
            }
        }
    }
    .padding(theme.spacing.base)
    .frame(maxWidth: .infinity, alignment: textAlignment == .center ? .center : .leading)
    .background(cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
    .overlay(cardBorderOverlay)
    .overlay(topHighlightOverlay)
    .opacity(state == .disabled ? 0.6 : 1.0)
    .frame(minHeight: 44)
    .contentShape(Rectangle())
}
```

### 3.2 Tactile 3D Extrusion Fix in `CraftChoiceCardButtonStyle`

```swift
public struct CraftChoiceCardButtonStyle: ButtonStyle {
    public let state: CraftChoiceState
    public let style: CraftSurfaceStyle
    public let depth: CGFloat
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(state: CraftChoiceState = .idle, style: CraftSurfaceStyle = .tactile3D, depth: CGFloat = 4) {
        self.state = state
        self.style = style
        self.depth = depth
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && state != .disabled
        let isTactile = style == .tactile3D
        let effectiveDepth = isTactile ? depth : 0
        let depressOffset = (isPressed && isTactile) ? depth : 0

        ZStack(alignment: .top) {
            // Seamless extruded 3D base layer matching exact corner curvature
            if state != .disabled && isTactile {
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(bottomLipColor)
                    .offset(y: depth)
            }

            // Top interactive card face
            configuration.label
                .offset(y: depressOffset)
        }
        .padding(.bottom, (state == .disabled || !isTactile) ? 0 : effectiveDepth)
        .scaleEffect(isPressed && !reduceMotion ? 0.99 : 1.0)
        .animation(theme.animations.springSnappy, value: isPressed)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in
            pressed
        }
    }

    private var bottomLipColor: Color {
        switch state {
        case .idle:
            return .craftDynamic(
                light: Color(hex: 0xD1D5DB), // Darker neutral for visible 3D extrusion in light mode
                dark: Color(hex: 0x374151)
            )
        case .selected:
            return theme.colors.brandSecondary
        case .correct:
            return .craftDynamic(
                light: Color(hex: 0x059669), // Darker green bevel
                dark: Color(hex: 0x047857)
            )
        case .wrong:
            return .craftDynamic(
                light: Color(hex: 0xDC2626), // Darker red bevel
                dark: Color(hex: 0xB91C1C)
            )
        case .disabled:
            return .clear
        }
    }
}
```

### 3.3 Card Background & Overlay Refinement in `.tactile3D`

- In `.tactile3D` style, the card background is always `theme.colors.surfaceCard` (crisp white in light mode), avoiding dirty wash overlays that reduce text contrast.
- `topHighlightOverlay` is omitted when `style == .tactile3D && state != .idle` so the 2.0pt semantic border stroke remains razor sharp.

---

## 4. Accessibility & Interaction

- **VoiceOver Traits**: Conforms to `.isButton` and `.isSelected` when `state == .selected`.
- **Dynamic Type**: Fully scales font with San Francisco rounded headlines.
- **Reduce Motion**: Disables depression translation, spring bounce, and shake animations when `UIAccessibility.isReduceMotionEnabled` is active.
- **Haptic Feedback**: Triggers light impact on tactile depression, selection feedback on select, success feedback on correct, error feedback on wrong.

---

## 5. Verification Plan

### 5.1 Automated Tests (`swift test --package-path CraftUIKit`)
- **Alignment Tests**: Verify `CraftChoiceCard` initializes with `.center` and `.leading` alignments.
- **Layout & Structure Tests**: Verify that `prefixStyle: .none` and `showsStatusIndicator: false` with `.center` alignment properly configures without breaking layout.
- **Tactile ButtonStyle Tests**: Verify `CraftChoiceCardButtonStyle` properties, depths, and color mappings across all 5 states.

### 5.2 Visual & Catalog Verification
- Update `CraftChoiceCardPreviewContainer` to showcase:
  1. Standard A/B/C/D tactile cards (Leading).
  2. Minimalist Centered Practice cards (Matching the user's video quiz screenshot).
- Update `CraftCatalogView.swift` component showcase.

---
