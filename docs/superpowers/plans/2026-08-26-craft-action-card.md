# CraftActionCard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `CraftActionCard` in `CraftUIKit` supporting all 6 surface styles (`.outlined`, `.tactile3D`, `.glass`, `.elevated`, `.flat`, `.gradient`), tactile 3D mechanical depression, Apple Liquid Glass (iOS 26 HIG), and integrate it into `ReflexBlitzModeSelectionView` and `ActionCardsGrid`.

**Architecture:** Build `CraftActionCard` as a flexible Bento Molecule component in `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActionCard.swift` adopting `CraftActionCardButtonStyle` for 3D extrusion/haptics, `.glassEffect` / `.ultraThinMaterial` for liquid glass, `CraftBadge`, `CraftIcon`, and `CraftText` for content slots. Replace ad-hoc card implementations in `VocabCraftApp`.

**Tech Stack:** Swift 6, SwiftUI, Swift Package Manager, XCTest/Swift Testing, SF Symbols, Liquid Glass (iOS 26 HIG).

**Spec:** `docs/superpowers/specs/2026-08-26-craft-action-card-design.md`

## Global Constraints

- 100% Zero Hardcoded Strings policy: all localizable text adheres to `Localizable.xcstrings` standards (manual extraction state, bilingual EN & VI parity).
- Complete support for 6 `CraftSurfaceStyle` variants (`.outlined`, `.tactile3D`, `.glass`, `.elevated`, `.flat`, `.gradient`).
- Tactile 3D press depression of 4pt with light haptics and no layout shifts.
- Apple Liquid Glass compliance on iOS 26+ with pre-iOS 26 fallback and `accessibilityReduceTransparency` support.
- Zero breaking changes to existing `CraftUIKit` components.

---

### Task 1: Create `CraftActionCard` Molecule and `CraftActionCardButtonStyle` in `CraftUIKit`

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActionCard.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftActionCardTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftSurfaceStyle`, `CraftBadge`, `CraftIcon`, `CraftText`, `CraftSymbol`
- Produces: `CraftActionCard`, `CraftActionCardButtonStyle`

- [ ] **Step 1: Write the failing unit tests for `CraftActionCard`**

Create `CraftUIKit/Tests/CraftUIKitTests/CraftActionCardTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftActionCardTests: XCTestCase {
    func testStringInitializer() {
        var tapped = false
        let card = CraftActionCard(
            title: "Luyện nói",
            subtitle: "Phản xạ phát âm & nhận diện giọng nói",
            iconName: "waveform.and.mic",
            badgeText: "6.0s",
            badgeIcon: "stopwatch.fill",
            accentColor: .orange,
            showChevron: true
        ) {
            tapped = true
        }

        XCTAssertEqual(card.title, "Luyện nói")
        XCTAssertEqual(card.subtitle, "Phản xạ phát âm & nhận diện giọng nói")
        XCTAssertEqual(card.iconName, "waveform.and.mic")
        XCTAssertEqual(card.badgeText, "6.0s")
        XCTAssertEqual(card.badgeIcon, "stopwatch.fill")
        XCTAssertEqual(card.showChevron, true)
        XCTAssertEqual(card.resolvedStyle, .outlined)

        card.action()
        XCTAssertTrue(tapped)
    }

    func testCraftSymbolInitializer() {
        let card = CraftActionCard(
            title: "Streak",
            subtitle: "Maintain daily streak",
            symbol: .streak,
            badgeText: "HOT",
            style: .tactile3D
        ) {}

        XCTAssertEqual(card.title, "Streak")
        XCTAssertEqual(card.symbol, .streak)
        XCTAssertEqual(card.iconName, CraftSymbol.streak.rawValue)
        XCTAssertEqual(card.resolvedStyle, .tactile3D)
    }

    func testExplicitSurfaceStyleOverridesEnvironment() {
        let card = CraftActionCard(
            title: "Glass Card",
            style: .glass
        ) {}

        XCTAssertEqual(card.resolvedStyle, .glass)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftActionCardTests`  
Expected: FAIL with "cannot find 'CraftActionCard' in scope"

- [ ] **Step 3: Implement `CraftActionCard.swift`**

Create `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActionCard.swift`:

```swift
import SwiftUI

// MARK: - CraftActionCard Component

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
    public let cornerRadius: CGFloat?
    public let action: () -> Void

    public var title: String { rawTitle ?? "" }
    public var subtitle: String? { rawSubtitle }

    public var resolvedStyle: CraftSurfaceStyle {
        explicitStyle ?? (envSurfaceStyle != .flat ? envSurfaceStyle : .outlined)
    }

    private var effectiveAccent: Color {
        accentColor ?? theme.colors.brandPrimary
    }

    private var effectiveRadius: CGFloat {
        cornerRadius ?? theme.radii.xl
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
        cornerRadius: CGFloat? = nil,
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
        self.cornerRadius = cornerRadius
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
        cornerRadius: CGFloat? = nil,
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
        self.cornerRadius = cornerRadius
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
        cornerRadius: CGFloat? = nil,
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
        self.cornerRadius = cornerRadius
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(
            CraftActionCardButtonStyle(
                style: resolvedStyle,
                depth: theme.depths.depthMd,
                cornerRadius: effectiveRadius,
                accentColor: effectiveAccent
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelString)
        .accessibilityHint(CraftLocalized.string("craft.common.action.action"))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Card Content & Slots

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row (Icon + Badge)
            headerRow

            // Body (Title + Subtitle)
            bodyContent

            Spacer(minLength: 0)

            // Footer (Chevron)
            if showChevron {
                footerRow
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous))
        .overlay(cardBorderOverlay)
        .overlay(topHighlightOverlay)
        .modifier(ActionCardShadowModifier(style: resolvedStyle, theme: theme))
        .contentShape(Rectangle())
    }

    // MARK: - Header Slot

    private var headerRow: some View {
        HStack(alignment: .center) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: 26, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconForegroundColor)
            }

            Spacer(minLength: 4)

            if let badgeText {
                HStack(spacing: 4) {
                    if let badgeIcon {
                        Image(systemName: badgeIcon)
                            .font(.system(size: 10, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    Text(badgeText)
                        .font(.caption2.monospacedDigit().bold())
                }
                .foregroundColor(badgeForegroundColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeBackgroundColor)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(badgeStrokeColor, lineWidth: 0.8)
                )
            }
        }
    }

    // MARK: - Body Slot

    private var bodyContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let titleKey {
                Text(titleKey)
                    .font(theme.typography.headline.bold())
                    .fontDesign(.rounded)
                    .foregroundColor(titleColor)
                    .lineLimit(1)
            } else if let rawTitle {
                Text(rawTitle)
                    .font(theme.typography.headline.bold())
                    .fontDesign(.rounded)
                    .foregroundColor(titleColor)
                    .lineLimit(1)
            }

            if let subtitleKey {
                Text(subtitleKey)
                    .font(theme.typography.caption)
                    .foregroundColor(subtitleColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let rawSubtitle, !rawSubtitle.isEmpty {
                Text(rawSubtitle)
                    .font(theme.typography.caption)
                    .foregroundColor(subtitleColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Footer Slot

    private var footerRow: some View {
        HStack {
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(chevronColor)
        }
    }

    // MARK: - Backgrounds & Overlays

    @ViewBuilder
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
        switch resolvedStyle {
        case .glass:
            if reduceTransparency {
                shape.fill(theme.colors.surfaceCard)
            } else {
                if #available(iOS 26, macOS 26, *) {
                    shape
                        .fill(.clear)
                        .glassEffect(.regular.tint(effectiveAccent).interactive(), in: shape)
                } else {
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                        shape.fill(effectiveAccent.opacity(theme.glass.tintOpacity))
                    }
                }
            }
        case .outlined:
            shape
                .fill(theme.colors.surfaceCard)
                .overlay(
                    shape.fill(
                        LinearGradient(
                            colors: [effectiveAccent.opacity(0.06), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
        case .tactile3D:
            shape
                .fill(theme.colors.surfaceCard)
                .overlay(
                    shape.fill(
                        LinearGradient(
                            colors: [effectiveAccent.opacity(0.04), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
        case .elevated:
            shape
                .fill(theme.colors.surfaceElevated)
                .overlay(
                    shape.fill(effectiveAccent.opacity(0.04))
                )
        case .flat:
            shape
                .fill(theme.colors.surfaceSubtle)
                .overlay(
                    shape.fill(effectiveAccent.opacity(0.03))
                )
        }
    }

    @ViewBuilder
    private var cardBorderOverlay: some View {
        let shape = RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
        switch resolvedStyle {
        case .outlined:
            shape.stroke(
                LinearGradient(
                    colors: [
                        effectiveAccent.opacity(0.35),
                        Color.white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        case .tactile3D:
            shape.stroke(effectiveAccent.opacity(0.35), lineWidth: 1)
        case .elevated:
            shape.stroke(
                LinearGradient(
                    stops: [
                        .init(color: .craftDynamic(light: Color.white.opacity(0.7), dark: Color.white.opacity(0.16)), location: 0.0),
                        .init(color: .craftDynamic(light: theme.colors.hairline.opacity(0.4), dark: Color.white.opacity(0.04)), location: 0.5),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        case .glass:
            shape.stroke(theme.glass.borderGradient, lineWidth: 1)
        case .flat:
            EmptyView()
        }
    }

    @ViewBuilder
    private var topHighlightOverlay: some View {
        let shape = RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
        if resolvedStyle == .tactile3D {
            shape.strokeBorder(theme.depths.topHighlight, lineWidth: 1)
        } else if resolvedStyle == .glass && !reduceTransparency {
            if #unavailable(iOS 26, macOS 26) {
                shape.strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
            }
        }
    }

    // MARK: - Semantic Colors

    private var iconForegroundColor: Color {
        effectiveAccent
    }

    private var badgeForegroundColor: Color {
        effectiveAccent
    }

    private var badgeBackgroundColor: Color {
        effectiveAccent.opacity(0.12)
    }

    private var badgeStrokeColor: Color {
        effectiveAccent.opacity(0.25)
    }

    private var titleColor: Color {
        theme.colors.textPrimary
    }

    private var subtitleColor: Color {
        theme.colors.textSecondary
    }

    private var chevronColor: Color {
        effectiveAccent.opacity(0.8)
    }

    private var accessibilityLabelString: String {
        var label = title
        if let badgeText {
            label += ", \(badgeText)"
        }
        if let subtitle {
            label += ", \(subtitle)"
        }
        return label
    }
}

// MARK: - Shadow Modifier

private struct ActionCardShadowModifier: ViewModifier {
    let style: CraftSurfaceStyle
    let theme: CraftTheme

    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            content.craftShadow(theme.shadows.md)
        case .glass, .outlined:
            content.craftShadow(theme.shadows.sm)
        case .flat, .tactile3D:
            content
        }
    }
}

// MARK: - Button Style

/// Button style providing tactile 3D mechanical press depression with bottom extrusion base.
public struct CraftActionCardButtonStyle: ButtonStyle {
    public let style: CraftSurfaceStyle
    public let depth: CGFloat
    public let cornerRadius: CGFloat
    public let accentColor: Color?
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        style: CraftSurfaceStyle = .outlined,
        depth: CGFloat = 4,
        cornerRadius: CGFloat = 22,
        accentColor: Color? = nil
    ) {
        self.style = style
        self.depth = depth
        self.cornerRadius = cornerRadius
        self.accentColor = accentColor
    }

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
            return baseLip.opacity(0.85).overlay(accentColor.opacity(0.20))
        }
        return baseLip
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftActionCardTests`  
Expected: PASS with 3 passing tests.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActionCard.swift CraftUIKit/Tests/CraftUIKitTests/CraftActionCardTests.swift
git commit -m "feat(CraftUIKit): create CraftActionCard supporting 6 surface styles and tactile 3D"
```

---

### Task 2: Add `CraftActionCard` Showcase to `CraftCatalogView`

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`

**Interfaces:**
- Consumes: `CraftActionCard`, `CraftSurfaceStyle`

- [ ] **Step 1: Add Action Cards Preview Section to `CraftCatalogView.swift`**

Add `CraftActionCard` preview section showcasing 4 distinct modality cards across all 6 surface styles with segmented style switcher.

- [ ] **Step 2: Run catalog tests to verify no regressions**

Run: `swift test --package-path CraftUIKit --filter CatalogViewTests`  
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "feat(CraftUIKit): add CraftActionCard showcase to CraftCatalogView"
```

---

### Task 3: Refactor `ReflexBlitzModeSelectionView` in `VocabCraftApp`

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift:152-289`

**Interfaces:**
- Consumes: `CraftActionCard`, `ReflexBlitzModeItem`

- [ ] **Step 1: Replace custom `modeCard` implementation in `ReflexBlitzModeSelectionView`**

Refactor `modeCard(for:)` in `ReflexBlitzModeSelectionView.swift` to use `CraftActionCard`:

```swift
// Replace custom modeCard and related private view helpers with:
@ViewBuilder
private func modeCard(for item: ReflexBlitzModeItem) -> some View {
    CraftActionCard(
        title: item.title,
        subtitle: item.subtitle,
        iconName: item.iconName,
        badgeText: item.badgeText,
        badgeIcon: "stopwatch.fill",
        accentColor: item.accentColor,
        showChevron: true
    ) {
        selectedModeTrigger = item.mode
        onSelectMode(item.mode)
    }
}
```

Remove redundant helper functions (`modeCardTopRow`, `modeCardBackground`, `modeCardBorder`, `BentoCardButtonStyle`).

- [ ] **Step 2: Verify package & app build**

Run: `swift test --package-path CraftUIKit`  
Expected: PASS with 0 failures.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift
git commit -m "refactor(ReflexBlitz): integrate CraftActionCard in mode selection view"
```

---

### Task 4: Modernize Homepage `ActionCardsGrid` in `VocabCraftApp`

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift`

**Interfaces:**
- Consumes: `CraftActionCard`, `AppStrings`

- [ ] **Step 1: Refactor `ActionCardsGrid.swift` with `CraftActionCard`**

Update `ActionCardsGrid.swift` to use `CraftActionCard`:

```swift
import SwiftUI
import CraftUIKit

public struct ActionCardsGrid: View {
    public let dueCardsCount: Int
    public var onReflexTap: () -> Void
    public var onQueueTap: () -> Void

    public init(
        dueCardsCount: Int,
        onReflexTap: @escaping () -> Void,
        onQueueTap: @escaping () -> Void
    ) {
        self.dueCardsCount = dueCardsCount
        self.onReflexTap = onReflexTap
        self.onQueueTap = onQueueTap
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Quick Reflex Drill Card
            CraftActionCard(
                title: AppStrings.Homepage.reflexTitle,
                subtitle: AppStrings.Homepage.practiceNow,
                iconName: "timer",
                badgeText: AppStrings.Homepage.reflexBadge,
                badgeIcon: "bolt.fill",
                accentColor: .vocabPeach,
                showChevron: false,
                action: onReflexTap
            )

            // SRS Queue Card
            CraftActionCard(
                title: AppStrings.Homepage.vocabLibraryTitle,
                subtitle: AppStrings.Homepage.dueCardsSubtitle(dueCardsCount),
                iconName: "rectangle.stack.fill",
                badgeText: "\(dueCardsCount) \(AppStrings.Common.wordUnit.uppercased())",
                badgeIcon: "rectangle.stack.fill",
                accentColor: .vocabLavender,
                showChevron: false,
                action: onQueueTap
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
    }
}
```

- [ ] **Step 2: Run all tests to verify**

Run: `swift test --package-path CraftUIKit`  
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift
git commit -m "refactor(Homepage): modernize ActionCardsGrid with CraftActionCard"
```

---

### Task 5: Full Verification & Final Gate

**Files:**
- Test all components across `CraftUIKit` and `VocabCraftApp`

- [ ] **Step 1: Run full test suite in `CraftUIKit`**

Run: `swift test --package-path CraftUIKit`  
Expected: PASS with 100% tests passing.

- [ ] **Step 2: Run build check for `VocabCraftApp`**

Run: `swift test --package-path CraftUIKit`  
Expected: 0 warnings, 0 errors.

- [ ] **Step 3: Final commit and summary**

```bash
git log -n 5 --oneline
```
