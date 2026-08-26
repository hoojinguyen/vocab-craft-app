# CraftFlipCard Modernization & 3D Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize `CraftFlipCard` in `CraftUIKit` with true mathematical back-face culling (zero-ghosting at 90°), luminance-adaptive specular glare for both Light & Dark modes, built-in tap-to-flip developer ergonomics, double-border coordination, and full dynamic accessibility support.

**Architecture:** Implement an animatable modifier `Craft3DFlipModifier` that calculates continuous 3D rotation degrees and instantaneously culls the non-visible face at $t = 0.5$ (90°). Upgrade `CraftSpecularGlareModifier` to produce dual-tone highlight/ambient-contrast in Light Mode and white glow in Dark Mode. Streamline `CraftFlipCard` API with `isTapToFlipEnabled: Bool = true`, `showsHighlightBorder: Bool = false`, and dynamic VoiceOver action names.

**Tech Stack:** Swift 6.0, SwiftUI, Xcode String Catalogs (`Localizable.xcstrings`), XCTest, CraftUIKit Theme System.

**Spec:** `docs/superpowers/specs/2026-08-26-craft-flip-card-modernization-design.md`

## Global Constraints

- **Swift Version:** Swift 6.0+ strict concurrency compliant (`Sendable` annotations).
- **iOS Deployment Target:** iOS 17.0+.
- **Zero Hardcoded Strings:** All user-facing and accessibility strings must resolve through `CraftLocalized` or String Catalog keys (`craft.flipcard.*`).
- **Zero Ghosting:** Front and back faces must have zero opacity overlap during transition ($t < 0.5 \implies \text{Front}=1, \text{Back}=0$; $t \ge 0.5 \implies \text{Front}=0, \text{Back}=1$).
- **Backward Compatibility:** All existing initializers and parameter names must maintain existing compatibility with sensible defaults.

---

### Task 1: String Catalog Localization Setup

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Test: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Consumes: Xcode String Catalog format.
- Produces: Keys `craft.flipcard.flipToBack`, `craft.flipcard.flipToFront`, `craft.flipcard.frontSideA11y`, `craft.flipcard.backSideA11y`.

- [ ] **Step 1: Write failing localization test in `InteractiveCardTests.swift`**

```swift
func testFlipCardLocalizationKeys() {
    let flipToBackEn = CraftLocalized.string("craft.flipcard.flipToBack")
    let flipToFrontEn = CraftLocalized.string("craft.flipcard.flipToFront")
    let frontA11y = CraftLocalized.string("craft.flipcard.frontSideA11y")
    let backA11y = CraftLocalized.string("craft.flipcard.backSideA11y")

    XCTAssertFalse(flipToBackEn.isEmpty)
    XCTAssertFalse(flipToFrontEn.isEmpty)
    XCTAssertFalse(frontA11y.isEmpty)
    XCTAssertFalse(backA11y.isEmpty)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path CraftUIKit --filter InteractiveCardTests/testFlipCardLocalizationKeys
```
Expected: FAIL (keys not yet found in `Localizable.xcstrings`).

- [ ] **Step 3: Add String Catalog entries to `Localizable.xcstrings`**

Add the following JSON entries to `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`:

```json
    "craft.flipcard.flipToBack" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Flip to back"
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Lật ra mặt sau"
          }
        }
      }
    },
    "craft.flipcard.flipToFront" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Flip to front"
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Lật ra mặt trước"
          }
        }
      }
    },
    "craft.flipcard.frontSideA11y" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Front of card"
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Mặt trước của thẻ"
          }
        }
      }
    },
    "craft.flipcard.backSideA11y" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Back of card"
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Mặt sau của thẻ"
          }
        }
      }
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path CraftUIKit --filter InteractiveCardTests/testFlipCardLocalizationKeys
```
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "feat(craftuikit): add flipcard localization keys to string catalog"
```

---

### Task 2: Implement True Back-Face Culling Engine (`CraftCardSide` & `Craft3DFlipModifier`)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Consumes: `AnimatableModifier`, `Axis`, `reduceMotion`.
- Produces: `CraftCardSide` enum, `Craft3DFlipModifier` struct with exact $t = 0.5$ opacity step function.

- [ ] **Step 1: Write failing unit test for `Craft3DFlipModifier` in `InteractiveCardTests.swift`**

```swift
func test3DFlipModifierCullingAndDegrees() {
    // Front side at resting state (t = 0.0)
    var frontModifier = Craft3DFlipModifier(progress: 0.0, side: .front, axis: .horizontal, perspective: 0.45, reduceMotion: false)
    XCTAssertTrue(frontModifier.isVisible)
    XCTAssertEqual(frontModifier.currentDegrees, 0.0, accuracy: 0.001)

    // Front side just before midpoint (t = 0.49)
    frontModifier.animatableData = 0.49
    XCTAssertTrue(frontModifier.isVisible)
    XCTAssertEqual(frontModifier.currentDegrees, 0.49 * 180.0, accuracy: 0.001)

    // Front side at/past midpoint (t = 0.50, t = 0.80) -> must be hidden
    frontModifier.animatableData = 0.50
    XCTAssertFalse(frontModifier.isVisible)
    frontModifier.animatableData = 0.80
    XCTAssertFalse(frontModifier.isVisible)

    // Back side at resting front state (t = 0.0) -> must be hidden
    var backModifier = Craft3DFlipModifier(progress: 0.0, side: .back, axis: .horizontal, perspective: 0.45, reduceMotion: false)
    XCTAssertFalse(backModifier.isVisible)

    // Back side at/past midpoint (t = 0.50, t = 1.0) -> must be visible
    backModifier.animatableData = 0.50
    XCTAssertTrue(backModifier.isVisible)
    XCTAssertEqual(backModifier.currentDegrees, (0.50 - 1.0) * 180.0, accuracy: 0.001)

    backModifier.animatableData = 1.0
    XCTAssertTrue(backModifier.isVisible)
    XCTAssertEqual(backModifier.currentDegrees, 0.0, accuracy: 0.001)

    // Reduce motion behavior
    let reduceMotionModifier = Craft3DFlipModifier(progress: 0.2, side: .front, axis: .horizontal, perspective: 0.45, reduceMotion: true)
    XCTAssertEqual(reduceMotionModifier.currentDegrees, 0.0)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path CraftUIKit --filter InteractiveCardTests/test3DFlipModifierCullingAndDegrees
```
Expected: FAIL (Cannot find `Craft3DFlipModifier` or `CraftCardSide`).

- [ ] **Step 3: Implement `CraftCardSide` and `Craft3DFlipModifier` in `CraftFlipCard.swift`**

```swift
// MARK: - Card Side & 3D Flip Modifier

/// Identifies the active side of a 3D flip card face.
public enum CraftCardSide: String, Sendable, CaseIterable {
    case front
    case back
}

/// An animatable view modifier providing true mathematical back-face culling and continuous 3D rotation.
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

    public init(
        progress: Double,
        side: CraftCardSide,
        axis: Axis = .horizontal,
        perspective: CGFloat = 0.45,
        reduceMotion: Bool = false
    ) {
        self.progress = progress
        self.side = side
        self.axis = axis
        self.perspective = perspective
        self.reduceMotion = reduceMotion
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

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path CraftUIKit --filter InteractiveCardTests/test3DFlipModifierCullingAndDegrees
```
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "feat(craftuikit): implement zero-ghosting Craft3DFlipModifier"
```

---

### Task 3: Upgrade `CraftSpecularGlareModifier` for Adaptive Dark/Light Mode

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Consumes: `@Environment(\.colorScheme)`, `AnimatableModifier`.
- Produces: Adaptive specular shine gradient supporting `.light` and `.dark` color schemes.

- [ ] **Step 1: Write failing unit test for `CraftSpecularGlareModifier` color scheme adaptation in `InteractiveCardTests.swift`**

```swift
func testSpecularGlareModifierAdaptation() {
    var glareDark = CraftSpecularGlareModifier(progress: 0.5, axis: .horizontal, cornerRadius: 16, isEnabled: true, colorScheme: .dark)
    XCTAssertEqual(glareDark.progress, 0.5)
    XCTAssertEqual(glareDark.colorScheme, .dark)

    glareDark.animatableData = 0.75
    XCTAssertEqual(glareDark.progress, 0.75)

    var glareLight = CraftSpecularGlareModifier(progress: 0.5, axis: .vertical, cornerRadius: 12, isEnabled: true, colorScheme: .light)
    XCTAssertEqual(glareLight.colorScheme, .light)
    XCTAssertEqual(glareLight.axis, .vertical)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path CraftUIKit --filter InteractiveCardTests/testSpecularGlareModifierAdaptation
```
Expected: FAIL.

- [ ] **Step 3: Update `CraftSpecularGlareModifier` in `CraftFlipCard.swift`**

```swift
// MARK: - Specular Glare Modifier

/// An animatable view modifier that sweeps a specular glare reflection gradient across the card surface during 3D rotation,
/// dynamically adapting contrast for Light and Dark color schemes.
public struct CraftSpecularGlareModifier: AnimatableModifier {
    public var progress: Double // 0.0 (front resting) -> 1.0 (back resting)
    public let axis: Axis
    public let cornerRadius: CGFloat
    public let isEnabled: Bool
    public let colorScheme: ColorScheme

    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    public init(
        progress: Double,
        axis: Axis = .horizontal,
        cornerRadius: CGFloat = 16,
        isEnabled: Bool = true,
        colorScheme: ColorScheme = .dark
    ) {
        self.progress = progress
        self.axis = axis
        self.cornerRadius = cornerRadius
        self.isEnabled = isEnabled
        self.colorScheme = colorScheme
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isEnabled {
                    GeometryReader { geometry in
                        let size = geometry.size
                        let clamped = max(0, min(progress, 1.0))
                        // Sinusoidal bell curve peak at progress = 0.5 (90 degrees midpoint of rotation)
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

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path CraftUIKit --filter InteractiveCardTests/testSpecularGlareModifierAdaptation
```
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "feat(craftuikit): make CraftSpecularGlareModifier adaptive to dark and light mode"
```

---

### Task 4: Complete Modernization of `CraftFlipCard` Container

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Consumes: `Craft3DFlipModifier`, `CraftSpecularGlareModifier`, `CraftTheme`, `CraftLocalized`.
- Produces: Modernized `CraftFlipCard` view with `showsHighlightBorder: Bool = false`, `isTapToFlipEnabled: Bool = true`, `perspective: CGFloat = 0.45`, dynamic accessibility actions.

- [ ] **Step 1: Write failing unit test for `CraftFlipCard` upgraded features in `InteractiveCardTests.swift`**

```swift
func testFlipCardModernizedInitializersAndFeatures() {
    var flipped = false
    let binding = Binding(get: { flipped }, set: { flipped = $0 })
    let card = CraftFlipCard(
        isFlipped: binding,
        axis: .horizontal,
        edgeThickness: 3,
        showSpecularGlare: true,
        showsHighlightBorder: false,
        isTapToFlipEnabled: true,
        cornerRadius: 16,
        perspective: 0.45
    ) {
        Text("Front")
    } back: {
        Text("Back")
    }

    XCTAssertFalse(card.isFlipped)
    XCTAssertEqual(card.showsHighlightBorder, false)
    XCTAssertEqual(card.isTapToFlipEnabled, true)
    XCTAssertEqual(card.perspective, 0.45)
    XCTAssertNotNil(card.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path CraftUIKit --filter InteractiveCardTests/testFlipCardModernizedInitializersAndFeatures
```
Expected: FAIL (Extra argument `showsHighlightBorder` or `isTapToFlipEnabled` in call).

- [ ] **Step 3: Update `CraftFlipCard` in `CraftFlipCard.swift`**

```swift
// MARK: - CraftFlipCard Component

/// An interactive 3D container component that flips between a front and back view
/// with double-sided rendering, instantaneous back-face culling (zero ghosting),
/// simulated edge thickness, adaptive specular glare, configurable perspective,
/// built-in tap gestures, custom spring physics, and sensory feedback.
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
    ) {
        self._isFlipped = isFlipped
        self.axis = axis
        self.edgeThickness = edgeThickness
        self.showSpecularGlare = showSpecularGlare
        self.showsHighlightBorder = showsHighlightBorder
        self.isTapToFlipEnabled = isTapToFlipEnabled
        self.cornerRadius = cornerRadius
        self.perspective = perspective
        self.animation = animation
        self.front = front()
        self.back = back()
    }

    public var body: some View {
        let progress = isFlipped ? 1.0 : 0.0
        let effectiveAnimation = animation ?? theme.animations.springSmooth

        ZStack {
            // Front Card Face with zero-ghosting backface culling & glare
            ZStack {
                if edgeThickness > 0 && !reduceMotion {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.colors.borderDefault)
                        .offset(
                            x: axis == .horizontal ? edgeThickness * 0.8 : 0,
                            y: axis == .vertical ? edgeThickness * 0.8 : 0
                        )
                }

                front
                    .overlay {
                        if showsHighlightBorder {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                        }
                    }
                    .modifier(
                        CraftSpecularGlareModifier(
                            progress: progress,
                            axis: axis,
                            cornerRadius: cornerRadius,
                            isEnabled: showSpecularGlare && !reduceMotion,
                            colorScheme: colorScheme
                        )
                    )
            }
            .modifier(
                Craft3DFlipModifier(
                    progress: progress,
                    side: .front,
                    axis: axis,
                    perspective: perspective,
                    reduceMotion: reduceMotion
                )
            )
            .accessibilityHidden(isFlipped)

            // Back Card Face with zero-ghosting backface culling & glare
            ZStack {
                if edgeThickness > 0 && !reduceMotion {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.colors.borderDefault)
                        .offset(
                            x: axis == .horizontal ? -edgeThickness * 0.8 : 0,
                            y: axis == .vertical ? -edgeThickness * 0.8 : 0
                        )
                }

                back
                    .overlay {
                        if showsHighlightBorder {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                        }
                    }
                    .modifier(
                        CraftSpecularGlareModifier(
                            progress: progress,
                            axis: axis,
                            cornerRadius: cornerRadius,
                            isEnabled: showSpecularGlare && !reduceMotion,
                            colorScheme: colorScheme
                        )
                    )
            }
            .modifier(
                Craft3DFlipModifier(
                    progress: progress,
                    side: .back,
                    axis: axis,
                    perspective: perspective,
                    reduceMotion: reduceMotion
                )
            )
            .accessibilityHidden(!isFlipped)
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onTapGesture {
            if isTapToFlipEnabled {
                withAnimation(effectiveAnimation) {
                    isFlipped.toggle()
                }
            }
        }
        .animation(effectiveAnimation, value: isFlipped)
        .sensoryFeedback(.impact(weight: .medium), trigger: isFlipped)
        .accessibilityAction(
            named: CraftLocalized.string(isFlipped ? "craft.flipcard.flipToFront" : "craft.flipcard.flipToBack")
        ) {
            withAnimation(effectiveAnimation) {
                isFlipped.toggle()
            }
        }
        .accessibilityHint(
            CraftLocalized.string(isFlipped ? "craft.flipcard.backSideA11y" : "craft.flipcard.frontSideA11y")
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path CraftUIKit --filter InteractiveCardTests
```
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "feat(craftuikit): modernize CraftFlipCard with zero ghosting and tap-to-flip"
```

---

### Task 5: Catalog Showcase Integration & Full Test Suite Verification

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: All tests in `CraftUIKitTests`

**Interfaces:**
- Consumes: Modernized `CraftFlipCard`.
- Produces: Cleaned up catalog preview without redundant manual `.onTapGesture`.

- [ ] **Step 1: Update `CraftCatalogView.swift` around lines 1570-1610**

Refactor the flip card preview block in `CraftCatalogView.swift` to leverage built-in `isTapToFlipEnabled: true`:

```swift
                    CraftFlipCard(
                        isFlipped: $isCardFlipped,
                        axis: flipAxis,
                        edgeThickness: 3,
                        showSpecularGlare: true,
                        isTapToFlipEnabled: true
                    ) {
                        CraftCard(style: .outlined) {
                            VStack(spacing: theme.spacing.sm) {
                                HStack {
                                    CraftBadge("Vocabulary Card", symbol: .study, variant: .subtle, tone: .primary)
                                    Spacer()
                                    CraftIcon(.audio, size: .sm, color: theme.colors.brandPrimary)
                                }
                                Spacer()
                                CraftText("Ephemeral", style: .displaySerif, color: theme.colors.textPrimary)
                                CraftText("/ɪˈfem.ər.əl/", style: .phonetic, color: theme.colors.textSecondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    CraftIcon(.flip, size: .sm, color: theme.colors.textSecondary)
                                    CraftText("Tap to reveal definition (3D Flip)", style: .caption, color: theme.colors.textSecondary)
                                }
                            }
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                        }
                    } back: {
                        CraftCard(style: .gradient) {
                            VStack(spacing: theme.spacing.sm) {
                                HStack {
                                    CraftBadge("Definition", symbol: .sparkles, variant: .solid, tone: .neutral)
                                    Spacer()
                                    CraftIcon(.sparkles, size: .sm, color: .white)
                                }
                                Spacer()
                                CraftText("Lasting for a very short time; transitory; fleeting.", style: .headline, color: .white)
                                    .multilineTextAlignment(.center)
                                Spacer()
                                HStack(spacing: 4) {
                                    CraftIcon(.flip, size: .sm, color: .white.opacity(0.8))
                                    CraftText("Tap to flip back", style: .caption, color: .white.opacity(0.8))
                                }
                            }
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                        }
                    }
```

- [ ] **Step 2: Run complete package test suite**

Run:
```bash
swift test --package-path CraftUIKit
```
Expected: PASS (All tests pass without errors).

- [ ] **Step 3: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "chore(craftuikit): update CraftCatalogView with modernized CraftFlipCard"
```

---

## Plan Self-Review Checklist

- [x] **Spec Coverage:** All items from spec `2026-08-26-craft-flip-card-modernization-design.md` are covered across Tasks 1-5.
- [x] **Placeholder Scan:** Zero `TODO`, `TBD`, or vague instructions; all code snippets and commands are complete.
- [x] **Type Consistency:** Method and property signatures (`Craft3DFlipModifier`, `CraftCardSide`, `CraftSpecularGlareModifier`, `CraftFlipCard`) are uniform across all tasks.
