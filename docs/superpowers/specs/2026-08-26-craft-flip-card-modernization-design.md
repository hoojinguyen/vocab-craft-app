# CraftFlipCard UI/UX Modernization & 3D Polish Specification

**Document:** `docs/superpowers/specs/2026-08-26-craft-flip-card-modernization-design.md`  
**Date:** 2026-08-26  
**Author:** Antigravity (Senior iOS Design & SwiftUI Architect)  
**Status:** In Review (Design Specification)

---

## 1. Overview & Problem Statement

[`CraftFlipCard`](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift) is a core 3D interactive container in `CraftUIKit`, widely used in flashcards, vocabulary review, quiz cards, and flipped metric cards.

While the existing component introduces innovative specular glare mathematics (`sin(progress * .pi)`) and multi-axis 3D rotation, an audit against **`ios-design-agent-skill`**, **`swiftui-design-skill`**, and **`swiftui-liquid-glass`** revealed 5 key issues:

1. **Ghosting / X-Ray Bleed-Through at 90°**: Standard linear interpolation of `opacity(isFlipped ? 0 : 1)` leaves both front and back faces at `50% opacity` at the rotation midpoint, causing distracting text overlap.
2. **Invisible Specular Glare in Light Mode**: White gradient with `.plusLighter` on white card backgrounds (`#FFFFFF`) evaluates to `White + White = White`, making the specular sheen invisible in Light Mode.
3. **Double-Border Clashing**: Unconditionally drawing a `theme.depths.topHighlight` border over child cards creates doubled strokes when containing `CraftCard(style: .outlined)` or `CraftCard(style: .elevated)`.
4. **Developer Ergonomics & Gesture Friction**: Tap-to-flip requires manual `.onTapGesture` wiring by consumers instead of having a clean default `isTapToFlipEnabled: Bool = true`.
5. **Accessibility & VoiceOver Context**: Action descriptions are static ("Flip card") rather than dynamic ("Flip to front" / "Flip to back") and lack localized announcements.

---

## 2. Core Design Pillars

- **Zero-Ghosting 3D Physics**: True instantaneous back-face culling at the exact mathematical midpoint ($\theta = 90^\circ, \text{progress} = 0.5$).
- **Luminance-Adaptive Specular Lighting**: Rich white glow in Dark Mode; dual-tone highlight with subtle ambient contrast in Light Mode.
- **Flawless Layer Composition**: No double borders, seamless child container integration, and respect for `accessibilityReduceMotion`.
- **First-Class Developer Ergonomics**: One-line usage with built-in tap gesture, full hit-testing shape, and sensory feedback.
- **HIG & WCAG AAA Accessibility**: Dynamic VoiceOver action names, localized string catalogs, and distinct front/back traits.

---

## 3. Detailed Architectural & Technical Design

### 3.1. True Back-Face Culling Engine (`Craft3DFlipModifier`)

Instead of animating separate top-level opacities, we introduce a dedicated `AnimatableModifier`:

```swift
public enum CraftCardSide: Sendable {
    case front
    case back
}

public struct Craft3DFlipModifier: AnimatableModifier {
    public var progress: Double // 0.0 (front resting) -> 1.0 (back resting)
    public let side: CraftCardSide
    public let axis: Axis
    public let perspective: CGFloat
    public let reduceMotion: Bool

    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    public var isVisible: Bool {
        if reduceMotion {
            return side == .front ? progress < 0.5 : progress >= 0.5
        }
        return side == .front ? progress < 0.5 : progress >= 0.5
    }

    public var currentDegrees: Double {
        if reduceMotion { return 0 }
        switch side {
        case .front:
            return progress * 180.0
        case .back:
            return (progress - 1.0) * 180.0
        }
    }

    public var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch axis {
        case .horizontal: return (x: 0, y: 1, z: 0)
        case .vertical: return (x: 1, y: 0, z: 0)
        }
    }

    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .allowsHitTesting(isVisible)
            .rotation3DEffect(
                .degrees(currentDegrees),
                axis: rotationAxis,
                perspective: perspective
            )
    }
}
```

#### Mathematical Proof of Zero-Ghosting:
- For $t \in [0.0, 0.5)$: $\text{Front.opacity} = 1.0$, $\text{Back.opacity} = 0.0$.
- For $t = 0.5$ ($90^\circ$ edge-on to camera): Face switches cleanly with zero thickness overlap.
- For $t \in (0.5, 1.0]$: $\text{Front.opacity} = 0.0$, $\text{Back.opacity} = 1.0$.

---

### 3.2. Luminance-Adaptive Specular Glare (`CraftSpecularGlareModifier`)

Specular glare sweeps across the face with peak intensity at the apex of rotation:

```swift
public struct CraftSpecularGlareModifier: AnimatableModifier {
    public var progress: Double
    public let axis: Axis
    public let cornerRadius: CGFloat
    public let isEnabled: Bool
    public let colorScheme: ColorScheme

    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    public func body(content: Content) -> some View {
        content.overlay {
            if isEnabled {
                GeometryReader { geometry in
                    let size = geometry.size
                    let clamped = max(0, min(progress, 1.0))
                    let glareIntensity = sin(clamped * .pi)

                    if glareIntensity > 0.001 {
                        let beamDimension = max(size.width, size.height) * 1.1
                        let totalSpan = (axis == .horizontal ? size.width : size.height) + beamDimension
                        let offsetPos = (clamped * totalSpan) - (beamDimension * 0.5)

                        glareGradient(intensity: glareIntensity)
                            .frame(
                                width: axis == .horizontal ? beamDimension * 0.55 : size.width * 1.6,
                                height: axis == .horizontal ? size.height * 1.6 : beamDimension * 0.55
                            )
                            .rotationEffect(.degrees(axis == .horizontal ? 25 : 65))
                            .offset(
                                x: axis == .horizontal ? offsetPos - (size.width * 0.2) : 0,
                                y: axis == .vertical ? offsetPos - (size.height * 0.2) : 0
                            )
                            .blendMode(colorScheme == .dark ? .plusLighter : .overlay)
                            .allowsHitTesting(false)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
    }

    @ViewBuilder
    private func glareGradient(intensity: Double) -> some View {
        if colorScheme == .dark {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color.white.opacity(0.12 * intensity), location: 0.25),
                    .init(color: Color.white.opacity(0.45 * intensity), location: 0.50),
                    .init(color: Color.white.opacity(0.12 * intensity), location: 0.75),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color.black.opacity(0.06 * intensity), location: 0.2),
                    .init(color: Color.white.opacity(0.60 * intensity), location: 0.5),
                    .init(color: Color.black.opacity(0.06 * intensity), location: 0.8),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
```

---

### 3.3. Upgraded `CraftFlipCard` API Signature

```swift
public struct CraftFlipCard<Front: View, Back: View>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @Binding public var isFlipped: Bool
    public let axis: Axis
    public let edgeThickness: CGFloat
    public let showSpecularGlare: Bool
    public let showsHighlightBorder: Bool
    public let isTapToFlipEnabled: Bool
    public let cornerRadius: CGFloat
    public let perspective: CGFloat
    public let animation: Animation?
    public let front: Front
    public let back: Back

    public init(
        isFlipped: Binding<Bool>,
        axis: Axis = .horizontal,
        edgeThickness: CGFloat = 2,
        showSpecularGlare: Bool = true,
        showsHighlightBorder: Bool = false,
        isTapToFlipEnabled: Bool = true,
        cornerRadius: CGFloat = 16,
        perspective: CGFloat = 0.45,
        animation: Animation? = nil,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    )
}
```

- **`showsHighlightBorder: Bool = false`**: Defaults to `false` so nested `CraftCard` components retain their own styled borders without duplicate strokes. Can be toggled to `true` when raw views are passed.
- **`isTapToFlipEnabled: Bool = true`**: Entire card surface is tappable by default with full `.contentShape(RoundedRectangle)`.
- **Dynamic Accessibility Action**: Resolves `craft.flipcard.flipToFront` ("Flip to front" / "Lật ra mặt trước") and `craft.flipcard.flipToBack` ("Flip to back" / "Lật ra mặt sau").

---

## 4. Localization Keys (`Localizable.xcstrings`)

| Key | English (`en`) | Vietnamese (`vi`) | Comment |
| :--- | :--- | :--- | :--- |
| `craft.flipcard.flipToBack` | `Flip to back` | `Lật ra mặt sau` | Accessibility action when card is showing front |
| `craft.flipcard.flipToFront` | `Flip to front` | `Lật ra mặt trước` | Accessibility action when card is showing back |
| `craft.flipcard.frontSideA11y` | `Front of card` | `Mặt trước của thẻ` | Accessibility hint/trait for front face |
| `craft.flipcard.backSideA11y` | `Back of card` | `Mặt sau của thẻ` | Accessibility hint/trait for back face |

---

## 5. Verification & Testing Strategy

### 5.1. Unit Tests (`InteractiveCardTests.swift`)
- **Backface Culling Threshold Test**: Verify `Craft3DFlipModifier` opacity is `1.0` for front at $t=0.49$, `0.0` at $t=0.51$, and vice versa for back.
- **Dual Axis Degrees Calculation**: Verify degrees evaluate to $[0 \dots 180^\circ]$ for horizontal and vertical axes.
- **Light/Dark Scheme Specular Glare**: Verify `CraftSpecularGlareModifier` computes valid animatable gradient stops under both `.light` and `.dark` schemes.
- **Tap-to-Flip Gesture**: Verify `isTapToFlipEnabled` correctly triggers state changes.
- **Accessibility Actions**: Verify dynamic action names toggle depending on `isFlipped`.

### 5.2. Visual & Catalog Verification (`CraftCatalogView.swift`)
- Test interactive flipping in both Light & Dark modes in the interactive gallery.
- Verify 3D depth, specular sweep visibility on white cards, and seamless transition without visual ghosting.
- Verify VoiceOver behavior in iOS Simulator.

---

## 6. Self-Review Checklist

- [x] **Placeholder Scan**: No `TODO`, `TBD`, or vague requirements.
- [x] **Internal Consistency**: Mathematical formulas match code implementations.
- [x] **Scope Check**: Tightly scoped to `CraftFlipCard.swift`, `InteractiveCardTests.swift`, `CraftCatalogView.swift`, and `Localizable.xcstrings`.
- [x] **Ambiguity Check**: Clear defaults, unambiguous culling thresholds, full backward compatibility.
