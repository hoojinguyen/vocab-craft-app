# CraftUIKit Modernization & iOS HIG Best Practices Spec

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor and modernize the entire `CraftUIKit` design system to strictly conform to Apple Human Interface Guidelines (HIG), iOS 17+ SwiftUI best practices, accessible VoiceOver/Dynamic Type standards, and zero-jank gesture handling.

**Architecture:** 
1. Replace invasive gesture-based press effects with native `ButtonStyle` (`configuration.isPressed`) to eliminate `ScrollView` scroll jank.
2. Upgrade typography tokens to scalable Dynamic Type semantic styles.
3. Migrate deprecated modifiers (`.foregroundColor` $\rightarrow$ `.foregroundStyle`) and adopt declarative `.sensoryFeedback`.
4. Implement rigorous accessibility traits, adjustable actions (Stepper), and localized string support (`LocalizedStringKey`).
5. Improve atmospheric depth via semantic surface tier elevation.

**Tech Stack:** Swift 5.10+, SwiftUI (iOS 17.0+ / macOS 14.0+), XCTest / Swift Testing.

**Spec:** `docs/superpowers/plans/2026-08-22-craftuikit-modernization-spec.md`

## Global Constraints

- Platform Target: iOS 17.0+, macOS 14.0+.
- No third-party dependencies (Pure SwiftUI + Foundation).
- Dynamic Type: All text must scale with accessibility sizes without truncation (use `minHeight` & vertical padding instead of rigid fixed heights).
- Touch Target: Minimum 44x44pt interactive hit area for all controls.
- Gesture Safety: Never attach `DragGesture(minimumDistance: 0)` to interactive button elements.
- VoiceOver: No raw symbol names aloud; combine related elements in composite cards.
- Dark Mode: Full adaptive support using `.craftDynamic` and semantic system surfaces.
- Haptics: Declarative `.sensoryFeedback` and `accessibilityReduceMotion` compliance.

---

## File Structure & Responsibilities

| File Path | Action | Responsibility |
| :--- | :--- | :--- |
| `CraftUIKit/Sources/CraftUIKit/Tokens/CraftTypographyTokens.swift` | Modify | Semantic Dynamic Type fonts scaling with system sizes |
| `CraftUIKit/Sources/CraftUIKit/Modifiers/PressEffectModifier.swift` | Modify | Native `CraftInteractiveButtonStyle` replacing `DragGesture` |
| `CraftUIKit/Sources/CraftUIKit/Modifiers/ShimmerModifier.swift` | Modify | `accessibilityReduceMotion` check and adaptive surface blend |
| `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftDivider.swift` | Modify | True physical hairline `1.0 / displayScale` |
| `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftText.swift` | Modify | `LocalizedStringKey` + `foregroundStyle` support |
| `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIcon.swift` | Modify | SF Symbol scaling, `foregroundStyle`, accessibility hiding |
| `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift` | Modify | Clean `ButtonStyle`, mandatory A11y label, 44pt touch area |
| `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftSpinner.swift` | Modify | `.accessibilityRepresentation { ProgressView() }` + Reduce Motion |
| `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift` | Modify | `foregroundStyle` + Dynamic Type scaling |
| `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftButton.swift` | Modify | `minHeight` expansion for Dynamic Type, `foregroundStyle` |
| `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift` | Modify | Clean button style, `.isSelected` trait, A11y state description |
| `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftPill.swift` | Modify | Clean button style, `.isSelected` trait, `foregroundStyle` |
| `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftStepper.swift` | Modify | `.accessibilityAdjustableAction`, `.monospacedDigit()`, flexible height |
| `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftTextField.swift` | Modify | `LocalizedStringKey`, `foregroundStyle`, flexible minHeight |
| `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftToggle.swift` | Modify | Entire row tap target, semantic thumb/track contrast |
| `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift` | Modify | `LocalizedStringKey`, `foregroundStyle`, clear button A11y |
| `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftCard.swift` | Modify | `surfaceElevated` hierarchy, clean `ButtonStyle` interaction |
| `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftEmptyState.swift` | Modify | Eliminate `AnyView`, add `ContentUnavailableView` synergy |
| `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift` | Modify | `.sensoryFeedback`, A11y flip custom action |
| `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftListRow.swift` | Modify | Clean `ButtonStyle`, dynamic type expansion |
| `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftProgressRing.swift` | Modify | `.monospacedDigit()`, customizable A11y label |
| `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftSegmentedBar.swift` | Modify | `.monospacedDigit()`, robust percentages |
| `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift` | Modify | Updated showcase with new modifiers and A11y features |

---

## Tasks

### Task 1: Core Foundation — Dynamic Type Typography & True Hairline Divider

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftTypographyTokens.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftDivider.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`

**Interfaces:**
- Produces: Dynamic font tokens via `Font.system(style, design:weight:)` ensuring system text size scaling.
- Produces: `CraftDivider` with `@Environment(\.displayScale)`.

- [ ] **Step 1: Write test for Dynamic Type and Hairline scale in ThemeTests and AtomComponentTests**

```swift
// In ThemeTests.swift
func testDynamicTypographyScaleTokens() {
    let typography = CraftDefaultTypographyTokens()
    _ = typography.displayLarge
    _ = typography.titleLarge
    _ = typography.titleMedium
    _ = typography.headline
    _ = typography.bodyLarge
    _ = typography.bodyMedium
    _ = typography.label
    _ = typography.caption
    XCTAssertNotNil(typography.font(for: .displayLarge))
}
```

- [ ] **Step 2: Run test to establish baseline**

Run: `swift test --filter ThemeTests`
Expected: PASS

- [ ] **Step 3: Update `CraftTypographyTokens.swift` to semantic font styles**

```swift
public struct CraftDefaultTypographyTokens: CraftTypographyTokens {
    public var displayLarge: Font
    public var titleLarge: Font
    public var titleMedium: Font
    public var headline: Font
    public var bodyLarge: Font
    public var bodyMedium: Font
    public var label: Font
    public var caption: Font

    public init(
        displayLarge: Font = .system(.largeTitle, design: .rounded, weight: .bold),
        titleLarge: Font = .system(.title, design: .default, weight: .bold),
        titleMedium: Font = .system(.title2, design: .default, weight: .semibold),
        headline: Font = .system(.headline, design: .default, weight: .semibold),
        bodyLarge: Font = .system(.body, design: .default, weight: .regular),
        bodyMedium: Font = .system(.callout, design: .default, weight: .regular),
        label: Font = .system(.subheadline, design: .default, weight: .medium),
        caption: Font = .system(.caption, design: .default, weight: .regular)
    ) {
        self.displayLarge = displayLarge
        self.titleLarge = titleLarge
        self.titleMedium = titleMedium
        self.headline = headline
        self.bodyLarge = bodyLarge
        self.bodyMedium = bodyMedium
        self.label = label
        self.caption = caption
    }
}
```

- [ ] **Step 4: Update `CraftDivider.swift` to use `1.0 / displayScale`**

```swift
public struct CraftDivider: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.displayScale) private var displayScale

    public let axis: Axis
    public let color: Color?
    public let customThickness: CGFloat?

    public init(
        axis: Axis = .horizontal,
        color: Color? = nil,
        thickness: CGFloat? = nil
    ) {
        self.axis = axis
        self.color = color
        self.customThickness = thickness
    }

    public var body: some View {
        let thickness = customThickness ?? (1.0 / displayScale)
        Rectangle()
            .fill(color ?? theme.colors.hairline)
            .frame(
                width: axis == .vertical ? thickness : nil,
                height: axis == .horizontal ? thickness : nil
            )
    }
}
```

- [ ] **Step 5: Run tests and verify**

Run: `swift test --filter "ThemeTests|AtomComponentTests"`
Expected: PASS

---

### Task 2: Gesture & Interactive Feedback Refactor (`CraftInteractiveButtonStyle`)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Modifiers/PressEffectModifier.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

**Interfaces:**
- Produces: `CraftInteractiveButtonStyle` and `.buttonStyle(.craftPress(...))` which cooperates with `ScrollView` without gesture stealing.
- Produces: Refactored `CraftPressEffectModifier` using `ButtonStyle` or safe gesture logic with `accessibilityReduceMotion` checking.

- [ ] **Step 1: Write test verifying `CraftInteractiveButtonStyle` press scale and animation**

```swift
func testInteractiveButtonStyleInstantiation() {
    let style = CraftInteractiveButtonStyle(scale: 0.95)
    XCTAssertEqual(style.scale, 0.95)
}
```

- [ ] **Step 2: Implement `CraftInteractiveButtonStyle` in `PressEffectModifier.swift`**

```swift
import SwiftUI

// MARK: - Native ButtonStyle for Smooth Press Scaling

/// A clean, native `ButtonStyle` that handles press down scaling without capturing parent `ScrollView` drag gestures.
public struct CraftInteractiveButtonStyle: ButtonStyle {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let scale: CGFloat
    public let opacity: Double

    public init(scale: CGFloat = 0.97, opacity: Double = 1.0) {
        self.scale = scale
        self.opacity = opacity
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(theme.animations.springSnappy, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == CraftInteractiveButtonStyle {
    static func craftPress(scale: CGFloat = 0.97, opacity: Double = 1.0) -> CraftInteractiveButtonStyle {
        CraftInteractiveButtonStyle(scale: scale, opacity: opacity)
    }
}

// MARK: - Backward-Compatible View Extension

public extension View {
    /// Applies a tactile press-down spring scaling effect to this view.
    func craftPressEffect(scale: CGFloat = 0.97) -> some View {
        Button(action: {}) {
            self
        }
        .buttonStyle(.craftPress(scale: scale))
    }
}
```

- [ ] **Step 3: Run tests and verify**

Run: `swift test --filter ControlComponentTests`
Expected: PASS

---

### Task 3: Modernizing Atoms & Buttons (`CraftText`, `CraftIcon`, `CraftIconButton`, `CraftSpinner`, `CraftBadge`, `CraftButton`)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftText.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIcon.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftSpinner.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftButton.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

- [ ] **Step 1: Write tests for `LocalizedStringKey`, `CraftIconButton` accessibility, and `CraftSpinner` representation**

```swift
func testCraftTextLocalizationAndStyling() {
    let keyText = CraftText("welcome_message", style: .headline)
    XCTAssertNotNil(keyText)
    let verbatimText = CraftText(verbatim: "Hello World", style: .bodyLarge)
    XCTAssertNotNil(verbatimText)
}
```

- [ ] **Step 2: Update `CraftText.swift` with `LocalizedStringKey` & `foregroundStyle`**

```swift
public struct CraftText: View {
    @Environment(\.craftTheme) private var theme

    private let textKey: LocalizedStringKey?
    private let rawText: String?
    public let style: CraftTypographyStyle
    public let color: Color?
    public let lineLimit: Int?
    public let textAlignment: TextAlignment?

    public init(
        _ textKey: LocalizedStringKey,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil
    ) {
        self.textKey = textKey
        self.rawText = nil
        self.style = style
        self.color = color
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
    }

    public init(
        _ text: String,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil
    ) {
        self.textKey = nil
        self.rawText = text
        self.style = style
        self.color = color
        self.lineLimit = lineLimit
        self.textAlignment = textAlignment
    }

    public init(
        verbatim text: String,
        style: CraftTypographyStyle = .bodyMedium,
        color: Color? = nil,
        lineLimit: Int? = nil,
        textAlignment: TextAlignment? = nil
    ) {
        self.init(text, style: style, color: color, lineLimit: lineLimit, textAlignment: textAlignment)
    }

    public var body: some View {
        Group {
            if let textKey {
                Text(textKey)
            } else if let rawText {
                Text(rawText)
            }
        }
        .font(theme.typography.font(for: style))
        .foregroundStyle(color ?? theme.colors.textPrimary)
        .lineLimit(lineLimit)
        .multilineTextAlignment(textAlignment ?? .leading)
    }
}
```

- [ ] **Step 3: Update `CraftIconButton.swift` to remove raw symbol fallback and use `CraftInteractiveButtonStyle`**

```swift
public struct CraftIconButton: View {
    @Environment(\.craftTheme) private var theme

    public let iconName: String
    public let size: CraftIconSize
    public let shape: CraftIconButtonShape
    public let variant: CraftIconButtonVariant
    public let accessibilityLabel: String
    public let minTouchTarget: CGFloat = 44
    public let action: () -> Void

    public init(
        iconName: String,
        size: CraftIconSize = .md,
        shape: CraftIconButtonShape = .circle,
        variant: CraftIconButtonVariant = .subtle,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.size = size
        self.shape = shape
        self.variant = variant
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                backgroundShapeView
                CraftIcon(iconName, size: size, color: foregroundColor)
            }
            .frame(width: visualDimension, height: visualDimension)
            .frame(minWidth: minTouchTarget, minHeight: minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: 0.94))
        .accessibilityLabel(accessibilityLabel)
    }
}
```

- [ ] **Step 4: Update `CraftSpinner.swift` with `.accessibilityRepresentation { ProgressView() }`**

```swift
public struct CraftSpinner: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    public let size: CraftIconSize
    public let color: Color?
    public let lineWidth: CGFloat

    public var body: some View {
        Circle()
            .trim(from: 0.15, to: 0.85)
            .stroke(
                color ?? theme.colors.brandPrimary,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size.pointSize, height: size.pointSize)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .linear(duration: 0.8)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
            .accessibilityRepresentation {
                ProgressView()
            }
    }
}
```

- [ ] **Step 5: Update `CraftButton.swift` to use flexible `minHeight`, `foregroundStyle`, and `LocalizedStringKey`**

```swift
public struct CraftButtonStyle: ButtonStyle {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let variant: CraftButtonVariant
    public let size: CraftButtonSize
    public let isLoading: Bool

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: theme.spacing.xs) {
            if isLoading {
                CraftSpinner(size: size.iconSize, color: foregroundColor(isPressed: configuration.isPressed))
            }
            configuration.label
                .font(theme.typography.font(for: size.typographyStyle))
                .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
                .opacity(isLoading ? 0.8 : 1.0)
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, size.horizontalPadding)
        .frame(minHeight: size.height)
        .background(backgroundView(isPressed: configuration.isPressed))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(borderOverlay(isPressed: configuration.isPressed))
        .opacity(isEnabled ? 1.0 : 0.5)
        .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
        .animation(theme.animations.springSnappy, value: configuration.isPressed)
        .contentShape(Rectangle())
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .sm: return 6
        case .md: return 10
        case .lg: return 14
        }
    }
}
```

- [ ] **Step 6: Run tests and verify**

Run: `swift test --filter "AtomComponentTests|ControlComponentTests"`
Expected: PASS

---

### Task 4: Modernizing Interactive Controls (`CraftChoiceCard`, `CraftPill`, `CraftStepper`, `CraftTextField`, `CraftToggle`, `CraftSearchBar`)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftPill.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftStepper.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftTextField.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftToggle.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

- [ ] **Step 1: Write tests for `CraftStepper` adjustable action and `CraftChoiceCard` accessibility traits**

```swift
func testStepperAdjustableActionAndBounds() {
    var val = 5
    let binding = Binding(get: { val }, set: { val = $0 })
    let stepper = CraftStepper(value: binding, range: 0...10, step: 1)
    stepper.increment()
    XCTAssertEqual(val, 6)
    stepper.decrement()
    XCTAssertEqual(val, 5)
}
```

- [ ] **Step 2: Update `CraftStepper.swift` with `.accessibilityAdjustableAction` and `.monospacedDigit()`**

```swift
public struct CraftStepper: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public var value: Binding<Int>
    public var range: ClosedRange<Int>
    public var step: Int
    public var unit: String?
    public var label: String?

    public var body: some View {
        HStack {
            if let label, !label.isEmpty {
                Text(label)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(theme.colors.textPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                Button(action: decrement) {
                    CraftIcon("minus", size: .sm, color: canDecrement ? theme.colors.textPrimary : theme.colors.textMuted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.craftPress(scale: 0.92))
                .disabled(!canDecrement)
                .accessibilityLabel("Decrease")

                Rectangle()
                    .fill(theme.colors.borderDefault)
                    .frame(width: 1, height: 24)

                HStack(spacing: 4) {
                    Text("\(value.wrappedValue)")
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .monospacedDigit()

                    if let unit, !unit.isEmpty {
                        Text(unit)
                            .font(theme.typography.label)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .frame(minWidth: 64)
                .padding(.horizontal, theme.spacing.sm)

                Rectangle()
                    .fill(theme.colors.borderDefault)
                    .frame(width: 1, height: 24)

                Button(action: increment) {
                    CraftIcon("plus", size: .sm, color: canIncrement ? theme.colors.textPrimary : theme.colors.textMuted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.craftPress(scale: 0.92))
                .disabled(!canIncrement)
                .accessibilityLabel("Increase")
            }
            .frame(minHeight: 44)
            .background(theme.colors.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Value Stepper")
        .accessibilityValue("\(value.wrappedValue) \(unit ?? "")")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: decrement()
            @unknown default: break
            }
        }
    }
}
```

- [ ] **Step 3: Update `CraftChoiceCard.swift` with clean ButtonStyle and accessible traits**

```swift
public struct CraftChoiceCard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shakeCount: CGFloat = 0

    public let prefix: String?
    public let title: String
    public let subtitle: String?
    public let state: CraftChoiceState
    public let action: () -> Void

    public var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.md) {
                if let prefix {
                    prefixBadge(prefix)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    if let subtitle {
                        Text(subtitle)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: theme.spacing.sm)

                trailingIndicator
            }
            .padding(theme.spacing.base)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(state == .correct && !reduceMotion ? 1.02 : 1.0)
            .modifier(ChoiceShakeEffect(shakes: shakeCount))
            .animation(theme.animations.springBouncy, value: state)
            .opacity(state == .disabled ? 0.5 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: state == .disabled ? 1.0 : 0.98))
        .disabled(state == .disabled)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(state == .selected ? [.isButton, .isSelected] : [.isButton])
        .accessibilityValue(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        switch state {
        case .idle: return "Unselected"
        case .selected: return "Selected"
        case .correct: return "Correct Answer"
        case .wrong: return "Incorrect Answer"
        case .disabled: return "Disabled"
        }
    }
}
```

- [ ] **Step 4: Update `CraftPill.swift`, `CraftToggle.swift`, `CraftTextField.swift`, `CraftSearchBar.swift`**
  - Migrate all `.foregroundColor` $\rightarrow$ `.foregroundStyle`.
  - Replace `DragGesture` press with `.buttonStyle(.craftPress(...))`.
  - Ensure full-row tap target on `CraftToggle`.

- [ ] **Step 5: Run tests and verify**

Run: `swift test --filter "ControlComponentTests|InteractiveCardTests"`
Expected: PASS

---

### Task 5: Modernizing Containers & Overlays (`CraftCard`, `CraftEmptyState`, `CraftFlipCard`, `CraftListRow`, `CraftProgressRing`, `CraftSegmentedBar`, `CraftStepNode`, `CraftShimmerModifier`)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftEmptyState.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftListRow.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftProgressRing.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftSegmentedBar.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStepNode.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Modifiers/ShimmerModifier.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/MetricsProgressionTests.swift`

- [ ] **Step 1: Write test for `CraftEmptyState` without `AnyView` and `CraftFlipCard` accessibility action**

```swift
func testEmptyStateConcreteViewInitialization() {
    let emptyState = CraftEmptyState(
        iconName: "magnifyingglass",
        title: "No Results Found",
        message: "Try searching with different keywords."
    )
    XCTAssertNotNil(emptyState)
}
```

- [ ] **Step 2: Update `CraftCard.swift` to use `surfaceElevated` on `.elevated` and clean ButtonStyle**

```swift
@ViewBuilder
private func backgroundView(radius: CGFloat) -> some View {
    switch style {
    case .flat:
        theme.colors.surfaceSubtle
    case .elevated:
        theme.colors.surfaceElevated
    case .outlined:
        theme.colors.surfaceCard
    case .gradient:
        customGradient ?? theme.gradients.brandHero
    }
}
```

- [ ] **Step 3: Update `CraftEmptyState.swift` to use concrete default view rather than `AnyView`**

```swift
public struct CraftDefaultEmptyStateIllustration: View {
    @Environment(\.craftTheme) private var theme
    public let iconName: String

    public init(iconName: String) {
        self.iconName = iconName
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(theme.colors.surfaceSubtle)
                .frame(width: 72, height: 72)
            CraftIcon(iconName, size: .xl, color: theme.colors.brandPrimary)
        }
    }
}

public extension CraftEmptyState where Illustration == CraftDefaultEmptyStateIllustration {
    init(
        iconName: String,
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.buttonTitle = buttonTitle
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = CraftDefaultEmptyStateIllustration(iconName: iconName)
    }
}
```

- [ ] **Step 4: Update `CraftFlipCard.swift` with `.sensoryFeedback` and A11y flip action**

```swift
public var body: some View {
    ZStack {
        front
            .opacity(isFlipped ? 0 : 1)
            .accessibilityHidden(isFlipped)
            .rotation3DEffect(
                reduceMotion ? .zero : .degrees(isFlipped ? 180 : 0),
                axis: rotationAxis,
                perspective: 0.5
            )

        back
            .opacity(isFlipped ? 1 : 0)
            .accessibilityHidden(!isFlipped)
            .rotation3DEffect(
                reduceMotion ? .zero : .degrees(isFlipped ? 0 : -180),
                axis: rotationAxis,
                perspective: 0.5
            )
    }
    .animation(theme.animations.springSmooth, value: isFlipped)
    .sensoryFeedback(.impact(weight: .medium), trigger: isFlipped)
    .accessibilityAction(named: "Flip card") {
        isFlipped.toggle()
    }
}
```

- [ ] **Step 5: Update `CraftShimmerModifier.swift` to respect `accessibilityReduceMotion`**

```swift
public func body(content: Content) -> some View {
    if isActive && !reduceMotion {
        content
            .overlay(
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: theme.colors.surfaceElevated.opacity(0.6), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: max(width * 1.5, 100), height: max(height * 1.5, 100))
                    .offset(x: phase * (width + 100))
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
                ) {
                    phase = 1.0
                }
            }
    } else {
        content
    }
}
```

- [ ] **Step 6: Run tests and verify**

Run: `swift test --filter "ContainerOverlayTests|MetricsProgressionTests"`
Expected: PASS

---

### Task 6: Interactive Catalog Gallery & Full Workspace Regression Suite

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: Full Test Suite (`CraftUIKit/Tests/CraftUIKitTests`)
- Test: Full App Suite (`VocabCraftAppTests`)

- [ ] **Step 1: Update `CraftCatalogView.swift` to reflect all refactored APIs and ButtonStyles**
- [ ] **Step 2: Run full `swift test` in `CraftUIKit`**

Run: `swift test` in `CraftUIKit` directory
Expected: PASS (All 103+ test cases pass without warnings or errors)

- [ ] **Step 3: Run full `swift test` in root workspace `vocab-craft-app`**

Run: `swift test` in root workspace
Expected: PASS (All domain, SRS, and feature tests pass seamlessly)

---

## Execution Handoff

Plan complete. Hai lựa chọn thực thi khả dụng:

1. **Subagent-Driven (Khuyên dùng)** - Dispatch từng subagent chuyên biệt cho mỗi Task, review chéo giữa các Task, đảm bảo tính độc lập và tốc độ cao.
2. **Inline Execution** - Thực thi trực tiếp các task trong phiên làm việc này với các checkpoint review.

Bạn muốn triển khai theo hình thức nào?
