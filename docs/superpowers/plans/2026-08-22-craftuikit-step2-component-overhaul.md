# CraftUIKit Step 2: Component Overhaul & Anti-Slop Standardization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul and standardize the remaining core components in `CraftUIKit` (`CraftEmptyState`, `CraftBadge`, `CraftChoiceCard`, `CraftFloatingTabBar`, and `CraftCatalogView`) to eliminate remaining AI-slop patterns, fix contrast issues in Dark Mode/Warning states, introduce layered squircle depth, and adopt `CraftSymbol`.

**Architecture:**
1. Replace single-circle `"sparkles"` empty state with a 3-tier **Layered Squircle Badge** (outer translucent container with smooth continuous corners, inner accent pill, and hierarchical focal icon) and integrate `CraftSymbol` defaults (`.study`, `.search`, `.list`).
2. Fix WCAG AAA contrast failure on `.solid` `.warning` badges by computing dynamic luminance foregrounds (dark ink `#18181B` on amber backgrounds), add 1pt stroke highlight to `.subtle` badges, and render icons with `CraftIcon`.
3. Enhance `CraftChoiceCard` `.selected` state contrast in Dark Mode (increase tint opacity from `0.08` to `0.16` + 2pt border focus), and upgrade status indicators to hierarchical `CraftIcon(.checkmarkCircle)` and `CraftIcon(.wrongCircle)`.
4. Eliminate floating purple gradient FAB cliché in `CraftFloatingTabBar` in favor of an integrated Liquid Glass action button matching iOS 18+ HIG aesthetic.
5. Synchronize `CraftCatalogView` showcase gallery with the new components and run full regression suite.

**Tech Stack:** Swift 5.10+, SwiftUI, SF Symbols 5+, XCTest.

**Spec:** `docs/superpowers/specs/2026-08-22-craftuikit-step2-component-overhaul-design.md`

## Global Constraints

- Platform requirements: iOS 17.0+, macOS 14.0+
- Maintain backward compatibility: all existing initializers taking `String` parameters must continue to compile and work.
- WCAG AA/AAA compliance: minimum 4.5:1 text-to-background contrast ratio across all badge tones and dark mode states.
- Touch target rule: minimum 44×44pt touch area for all interactive elements.

---

## File Structure

- **MODIFY** `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftEmptyState.swift`: Replace single-circle illustration with 3-tier Layered Squircle Badge and add `CraftSymbol` initializers.
- **MODIFY** `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift`: Fix `.warning` contrast bug, add `CraftSymbol` support, and use `CraftIcon`.
- **MODIFY** `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`: Dark Mode `.selected` contrast enhancement and dual-tone hierarchical indicators.
- **MODIFY** `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`: Liquid Glass integrated center action button and `CraftSymbol` support.
- **MODIFY** `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`: Update entire gallery to reflect revamped design tokens and components.
- **MODIFY** `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`: Unit tests for Layered Squircle empty states and symbol inits.
- **MODIFY** `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`: Unit tests for badge contrast and symbol inits.
- **MODIFY** `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`: Unit tests for choice card dark mode contrast and indicators.
- **MODIFY** `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`: Unit tests for floating tab bar and center action.

---

## Tasks

### Task 1: Redesign `CraftEmptyState` (Layered Squircle Badge & `CraftSymbol` Integration)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftEmptyState.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`

**Interfaces:**
- Consumes: `CraftSymbol`, `CraftIcon`, `CraftTheme`
- Produces:
  - `CraftDefaultEmptyStateIllustration.init(symbol: CraftSymbol)` & `CraftDefaultEmptyStateIllustration.init(iconName: String)` with 3-tier layered squircle rendering.
  - `CraftEmptyState.init(symbol: CraftSymbol, title: ..., message: ..., buttonTitle: ..., buttonSymbol: CraftSymbol?, buttonAction: ...)`
  - Preserved backward-compatible string initializers.

- [ ] **Step 1: Write failing test for `CraftEmptyState` with `CraftSymbol` and layered illustration**

Add to `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`:
```swift
    func testEmptyStateWithCraftSymbol() {
        var buttonTapped = false
        let emptyState = CraftEmptyState(
            symbol: .study,
            title: "No Study Cards",
            message: "Create your first vocabulary card to start reviewing.",
            buttonTitle: "Add Word",
            buttonSymbol: .add,
            buttonAction: { buttonTapped = true }
        )

        XCTAssertEqual(emptyState.title, "No Study Cards")
        XCTAssertEqual(emptyState.message, "Create your first vocabulary card to start reviewing.")
        XCTAssertEqual(emptyState.iconName, "character.book.closed")
        XCTAssertEqual(emptyState.buttonTitle, "Add Word")
        XCTAssertEqual(emptyState.buttonIcon, "plus")
        XCTAssertNotNil(emptyState.body)

        emptyState.buttonAction?()
        XCTAssertTrue(buttonTapped)
    }

    func testDefaultEmptyStateIllustrationWithSymbol() {
        let illustration = CraftDefaultEmptyStateIllustration(symbol: .bookmark)
        XCTAssertEqual(illustration.iconName, "bookmark")
        XCTAssertNotNil(illustration.body)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter testEmptyStateWithCraftSymbol` in directory `CraftUIKit`
Expected: FAIL with "cannot find argument 'symbol' in call"

- [ ] **Step 3: Update `CraftEmptyState.swift`**

Replace `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftEmptyState.swift` with:
```swift
import SwiftUI

// MARK: - Default Empty State Illustration

/// A refined 3-tier layered squircle badge illustration with subtle depth for empty state views.
public struct CraftDefaultEmptyStateIllustration: View {
    @Environment(\.craftTheme) private var theme
    public let iconName: String
    public let symbol: CraftSymbol?

    public init(symbol: CraftSymbol = .study) {
        self.symbol = symbol
        self.iconName = symbol.rawValue
    }

    public init(iconName: String = "character.book.closed") {
        self.symbol = CraftSymbol(rawValue: iconName)
        self.iconName = iconName
    }

    public var body: some View {
        ZStack {
            // Layer 1: Outer soft squircle container
            RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                .fill(theme.colors.surfaceSubtle)
                .frame(width: 88, height: 88)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                        .strokeBorder(theme.colors.borderDefault.opacity(0.6), lineWidth: 1)
                )

            // Layer 2: Inner accent pill badge
            RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)
                .fill(theme.colors.brandPrimary.opacity(0.12))
                .frame(width: 56, height: 56)

            // Layer 3: Hierarchical focal icon
            CraftIcon(
                iconName,
                size: .lg,
                color: theme.colors.brandPrimary,
                renderingMode: .hierarchical,
                weight: .bold
            )
        }
        .craftShadow(theme.shadows.sm)
    }
}

// MARK: - CraftEmptyState Component

/// A standardized empty state placeholder view displaying an illustration or icon,
/// header title, descriptive message, and an optional call-to-action button.
public struct CraftEmptyState<Illustration: View>: View {
    @Environment(\.craftTheme) private var theme

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let messageKey: LocalizedStringKey?
    private let rawMessage: String?
    private let buttonTitleKey: LocalizedStringKey?
    private let rawButtonTitle: String?

    public var title: String { rawTitle ?? "" }
    public var message: String? { rawMessage }
    public var buttonTitle: String? { rawButtonTitle }
    public let iconName: String?
    public let buttonIcon: String?
    public let buttonAction: (() -> Void)?
    public let illustration: Illustration

    // MARK: - Generic Initializers (String)

    public init(
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.messageKey = nil
        self.rawMessage = message
        self.iconName = nil
        self.buttonTitleKey = nil
        self.rawButtonTitle = buttonTitle
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = illustration()
    }

    public init(
        iconName: String,
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.messageKey = nil
        self.rawMessage = message
        self.iconName = iconName
        self.buttonTitleKey = nil
        self.rawButtonTitle = buttonTitle
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = illustration()
    }

    // MARK: - Generic Initializers (LocalizedStringKey)

    public init(
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttonTitle: LocalizedStringKey? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.titleKey = title
        self.rawTitle = nil
        self.messageKey = message
        self.rawMessage = nil
        self.iconName = nil
        self.buttonTitleKey = buttonTitle
        self.rawButtonTitle = nil
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = illustration()
    }

    public init(
        iconName: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttonTitle: LocalizedStringKey? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.titleKey = title
        self.rawTitle = nil
        self.messageKey = message
        self.rawMessage = nil
        self.iconName = iconName
        self.buttonTitleKey = buttonTitle
        self.rawButtonTitle = nil
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = illustration()
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Illustration or Icon
            illustration

            // Text copy
            VStack(spacing: theme.spacing.xs) {
                if let titleKey {
                    CraftText(
                        titleKey,
                        style: .titleMedium,
                        color: theme.colors.textPrimary,
                        textAlignment: .center
                    )
                } else if let rawTitle {
                    CraftText(
                        rawTitle,
                        style: .titleMedium,
                        color: theme.colors.textPrimary,
                        textAlignment: .center
                    )
                }

                if let messageKey {
                    CraftText(
                        messageKey,
                        style: .bodyMedium,
                        color: theme.colors.textSecondary,
                        textAlignment: .center
                    )
                } else if let rawMessage, !rawMessage.isEmpty {
                    CraftText(
                        rawMessage,
                        style: .bodyMedium,
                        color: theme.colors.textSecondary,
                        textAlignment: .center
                    )
                }
            }
            .padding(.horizontal, theme.spacing.lg)

            // Primary Action Button
            if let buttonAction {
                if let buttonTitleKey {
                    CraftButton(
                        buttonTitleKey,
                        iconName: buttonIcon,
                        variant: .primary,
                        size: .md,
                        action: buttonAction
                    )
                    .padding(.top, theme.spacing.xs)
                } else if let rawButtonTitle {
                    CraftButton(
                        rawButtonTitle,
                        iconName: buttonIcon,
                        variant: .primary,
                        size: .md,
                        action: buttonAction
                    )
                    .padding(.top, theme.spacing.xs)
                }
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: 500)
    }
}

// MARK: - Convenience Inits with Concrete Default Illustration

public extension CraftEmptyState where Illustration == CraftDefaultEmptyStateIllustration {
    init(
        symbol: CraftSymbol = .study,
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonSymbol: CraftSymbol? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.init(
            iconName: symbol.rawValue,
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            buttonIcon: buttonSymbol?.rawValue,
            buttonAction: buttonAction
        )
    }

    init(
        iconName: String = "character.book.closed",
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.messageKey = nil
        self.rawMessage = message
        self.iconName = iconName
        self.buttonTitleKey = nil
        self.rawButtonTitle = buttonTitle
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = CraftDefaultEmptyStateIllustration(iconName: iconName)
    }

    init(
        symbol: CraftSymbol = .study,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttonTitle: LocalizedStringKey? = nil,
        buttonSymbol: CraftSymbol? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.init(
            iconName: symbol.rawValue,
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            buttonIcon: buttonSymbol?.rawValue,
            buttonAction: buttonAction
        )
    }

    init(
        iconName: String = "character.book.closed",
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttonTitle: LocalizedStringKey? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.titleKey = title
        self.rawTitle = nil
        self.messageKey = message
        self.rawMessage = nil
        self.iconName = iconName
        self.buttonTitleKey = buttonTitle
        self.rawButtonTitle = nil
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = CraftDefaultEmptyStateIllustration(iconName: iconName)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter testEmptyStateWithCraftSymbol`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftEmptyState.swift CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift
git commit -m "feat(craftuikit): redesign CraftEmptyState with layered squircle and CraftSymbol"
```

---

### Task 2: Fix `CraftBadge` Contrast & Border Polish

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`

**Interfaces:**
- Consumes: `CraftSymbol`, `CraftIcon`, `CraftTheme`
- Produces:
  - High-contrast text on solid warning badges (`CraftBadgeTone.warning` with `.solid` uses `Color(hex: 0x18181B)`).
  - `CraftBadge.init(_ title: String, symbol: CraftSymbol?, variant: CraftBadgeVariant, tone: CraftBadgeTone, size: CraftBadgeSize)`
  - Hierarchical icon rendering with `CraftIcon`.

- [ ] **Step 1: Write test for `CraftBadge` with `CraftSymbol` and contrast safety**

Add to `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`:
```swift
    func testBadgeWithCraftSymbol() {
        let badge = CraftBadge("MASTERED", symbol: .mastery, variant: .solid, tone: .success, size: .sm)
        XCTAssertEqual(badge.title, "MASTERED")
        XCTAssertEqual(badge.iconName, "medal.fill")
        XCTAssertEqual(badge.symbol, .mastery)
        XCTAssertEqual(badge.variant, .solid)
        XCTAssertEqual(badge.tone, .success)
        XCTAssertEqual(badge.size, .sm)
        XCTAssertNotNil(badge.body)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter testBadgeWithCraftSymbol` in directory `CraftUIKit`
Expected: FAIL with "cannot find argument 'symbol' in call"

- [ ] **Step 3: Update `CraftBadge.swift`**

Replace `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift` with:
```swift
import SwiftUI

// MARK: - Badge Enums

/// Visual style variants for badges.
public enum CraftBadgeVariant: String, Sendable, CaseIterable {
    case solid
    case subtle
    case outline
}

/// Semantic tone indicating purpose or state of the badge.
public enum CraftBadgeTone: String, Sendable, CaseIterable {
    case primary
    case success
    case warning
    case danger
    case neutral
}

/// Standardized badge size options.
public enum CraftBadgeSize: String, Sendable, CaseIterable {
    case sm
    case md
}

// MARK: - CraftBadge Component

/// A standardized badge and tag component displaying status, categories, or counts
/// with WCAG AAA contrast assurance and hierarchical icon rendering.
public struct CraftBadge: View {
    @Environment(\.craftTheme) private var theme

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let isVerbatim: Bool
    public let iconName: String?
    public let symbol: CraftSymbol?
    public let variant: CraftBadgeVariant
    public let tone: CraftBadgeTone
    public let size: CraftBadgeSize

    public var title: String? {
        rawTitle
    }

    public init(
        _ title: String,
        symbol: CraftSymbol,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = false
        self.symbol = symbol
        self.iconName = symbol.rawValue
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    public init(
        _ title: String,
        iconName: String? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = false
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.iconName = iconName
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    public init(
        _ titleKey: LocalizedStringKey,
        symbol: CraftSymbol? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = titleKey
        self.rawTitle = nil
        self.isVerbatim = false
        self.symbol = symbol
        self.iconName = symbol?.rawValue
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    public init(
        _ titleKey: LocalizedStringKey,
        iconName: String? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = titleKey
        self.rawTitle = nil
        self.isVerbatim = false
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.iconName = iconName
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    public init(
        verbatim title: String,
        symbol: CraftSymbol? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = true
        self.symbol = symbol
        self.iconName = symbol?.rawValue
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    public init(
        verbatim title: String,
        iconName: String? = nil,
        variant: CraftBadgeVariant = .subtle,
        tone: CraftBadgeTone = .primary,
        size: CraftBadgeSize = .md
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.isVerbatim = true
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.iconName = iconName
        self.variant = variant
        self.tone = tone
        self.size = size
    }

    private var toneColor: Color {
        switch tone {
        case .primary:
            return theme.colors.brandPrimary
        case .success:
            return theme.colors.statusSuccess
        case .warning:
            return theme.colors.statusWarning
        case .danger:
            return theme.colors.statusDanger
        case .neutral:
            return theme.colors.textMuted
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .solid:
            // High contrast assurance: Warning (yellow/amber) needs dark ink, not white
            if tone == .warning {
                return Color(hex: 0x18181B)
            }
            return .white
        case .subtle, .outline:
            return toneColor
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .sm: return 6
        case .md: return 8
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .sm: return 2
        case .md: return 4
        }
    }

    private var font: Font {
        switch size {
        case .sm: return theme.typography.caption
        case .md: return theme.typography.label
        }
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let iconName {
                CraftIcon(
                    iconName,
                    size: size == .sm ? .sm : .md,
                    color: foregroundColor,
                    renderingMode: variant == .solid ? .monochrome : .hierarchical,
                    weight: .bold
                )
            }
            if let titleKey {
                Text(titleKey)
                    .font(font)
                    .fontWeight(.semibold)
            } else if let rawTitle {
                if isVerbatim {
                    Text(verbatim: rawTitle)
                        .font(font)
                        .fontWeight(.semibold)
                } else {
                    Text(rawTitle)
                        .font(font)
                        .fontWeight(.semibold)
                }
            }
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(backgroundView)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .solid:
            Capsule().fill(toneColor)
        case .subtle:
            Capsule()
                .fill(toneColor.opacity(0.14))
                .overlay(
                    Capsule()
                        .strokeBorder(toneColor.opacity(0.24), lineWidth: 1)
                )
        case .outline:
            Capsule().strokeBorder(toneColor, lineWidth: 1)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter testBadgeWithCraftSymbol`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift
git commit -m "feat(craftuikit): enhance CraftBadge with WCAG AAA contrast safety and CraftSymbol"
```

---

### Task 3: Polish `CraftChoiceCard` Dark Mode Contrast & Dual-Tone Indicators

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Consumes: `CraftSymbol`, `CraftIcon`, `CraftTheme`
- Produces:
  - Enhanced Dark Mode contrast for `.selected` state (`brandPrimary.opacity(0.16)` + distinct border).
  - Status indicators using `CraftIcon(.checkmarkCircle)` and `CraftIcon(.wrongCircle)`.

- [ ] **Step 1: Write test verifying choice card indicators and state descriptions**

Add to `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`:
```swift
    func testChoiceCardStateIndicators() {
        var tapped = false
        let correctCard = CraftChoiceCard(
            prefix: "A",
            title: "Selected Option",
            state: .correct
        ) {
            tapped = true
        }
        XCTAssertEqual(correctCard.prefix, "A")
        XCTAssertEqual(correctCard.title, "Selected Option")
        XCTAssertEqual(correctCard.state, .correct)
        XCTAssertNotNil(correctCard.body)
        correctCard.action()
        XCTAssertTrue(tapped)
    }
```

- [ ] **Step 2: Update `CraftChoiceCard.swift`**

Modify `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`:
Update `trailingIndicator` and `backgroundColor`:
```swift
    @ViewBuilder
    private var trailingIndicator: some View {
        switch state {
        case .correct:
            CraftIcon(
                .checkmarkCircle,
                size: .lg,
                color: theme.colors.statusSuccess,
                renderingMode: .hierarchical,
                weight: .bold
            )
        case .wrong:
            CraftIcon(
                .wrongCircle,
                size: .lg,
                color: theme.colors.statusDanger,
                renderingMode: .hierarchical,
                weight: .bold
            )
        case .idle, .selected, .disabled:
            EmptyView()
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .idle, .disabled:
            return theme.colors.surfaceCard
        case .selected:
            return theme.colors.brandPrimary.opacity(0.16)
        case .correct:
            return theme.colors.statusSuccess.opacity(0.16)
        case .wrong:
            return theme.colors.statusDanger.opacity(0.16)
        }
    }
```

- [ ] **Step 3: Run test to verify it passes**

Run: `swift test --filter testChoiceCardStateIndicators` in directory `CraftUIKit`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "feat(craftuikit): polish CraftChoiceCard dark mode contrast and indicators"
```

---

### Task 4: Redesign `CraftFloatingTabBar` (Liquid Glass & Refined Action Button)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`

**Interfaces:**
- Consumes: `CraftSymbol`, `CraftIcon`, `CraftTheme`
- Produces:
  - Refined Liquid Glass integrated Center Action button using `theme.colors.brandPrimary` with subtle ambient shadow instead of floating purple gradient circle.
  - Safe area inset responsiveness.

- [ ] **Step 1: Write test for tab bar body rendering and item selection**

Check `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift` for `testFloatingTabBarWithCenterAction`.

- [ ] **Step 2: Update `CraftFloatingTabBar.swift`**

Replace `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift` with:
```swift
import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Tab Item Protocol

/// Contract for navigation tab items used in `CraftFloatingTabBar`.
public protocol CraftTabItemProtocol: Identifiable, Equatable, Sendable where ID: Sendable & Hashable {
    var id: ID { get }
    var title: String { get }
    var symbol: String { get }
}

// MARK: - CraftFloatingTabBar Component

/// A floating liquid-glass navigation bar featuring animated sliding tab indicators,
/// spring transitions, safe area handling, minimum 44pt touch targets, and an integrated tactile action button.
public struct CraftFloatingTabBar<Item: CraftTabItemProtocol>: View {
    @Environment(\.craftTheme) private var theme
    @Namespace private var tabNamespace

    @Binding public var selectedItem: Item
    public let items: [Item]
    public let centerAction: (() -> Void)?
    public let centerSymbol: String
    public let centerTitle: String?

    public init(
        selectedItem: Binding<Item>,
        items: [Item],
        centerAction: (() -> Void)? = nil,
        centerSymbol: String = "plus",
        centerTitle: String? = nil
    ) {
        self._selectedItem = selectedItem
        self.items = items
        self.centerAction = centerAction
        self.centerSymbol = centerSymbol
        self.centerTitle = centerTitle
    }

    private var leadingItems: [Item] {
        let mid = items.count / 2
        return Array(items.prefix(mid))
    }

    private var trailingItems: [Item] {
        let mid = items.count / 2
        return Array(items.suffix(from: mid))
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xs) {
            if let centerAction {
                ForEach(leadingItems) { item in
                    tabButton(for: item)
                }

                centerActionButton(action: centerAction)

                ForEach(trailingItems) { item in
                    tabButton(for: item)
                }
            } else {
                ForEach(items) { item in
                    tabButton(for: item)
                }
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.hairline, lineWidth: 1)
                )
        }
        .craftShadow(theme.shadows.lg)
        .padding(.horizontal, theme.spacing.base)
        .padding(.bottom, theme.spacing.sm)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Tab Item Button

    @ViewBuilder
    private func tabButton(for item: Item) -> some View {
        let isSelected = selectedItem.id == item.id

        Button {
            #if os(iOS)
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
            #endif
            withAnimation(theme.animations.springSnappy) {
                selectedItem = item
            }
        } label: {
            VStack(spacing: 3) {
                CraftIcon(
                    item.symbol,
                    size: .md,
                    color: isSelected ? theme.colors.brandPrimary : theme.colors.textMuted,
                    renderingMode: isSelected ? .hierarchical : .monochrome,
                    weight: isSelected ? .bold : .medium
                )

                Text(item.title)
                    .font(theme.typography.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? theme.colors.brandPrimary : theme.colors.textMuted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.vertical, theme.spacing.xs)
            .padding(.horizontal, theme.spacing.xs)
            .background {
                if isSelected {
                    Capsule()
                        .fill(theme.colors.brandPrimary.opacity(0.12))
                        .matchedGeometryEffect(id: "activeTabIndicator", in: tabNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .craftPressEffect(scale: 0.95)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    // MARK: - Center Action Button

    @ViewBuilder
    private func centerActionButton(action: @escaping () -> Void) -> some View {
        Button {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            #endif
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(theme.colors.brandPrimary)
                    .frame(width: 44, height: 44)
                    .craftShadow(theme.shadows.sm)

                VStack(spacing: 2) {
                    CraftIcon(
                        centerSymbol,
                        size: .md,
                        color: theme.colors.textInverse,
                        renderingMode: .monochrome,
                        weight: .bold
                    )

                    if let centerTitle, !centerTitle.isEmpty {
                        Text(centerTitle)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(theme.colors.textInverse)
                            .lineLimit(1)
                    }
                }
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .craftPressEffect(scale: 0.92)
        .accessibilityLabel(centerTitle ?? "Action")
        .accessibilityAddTraits(.isButton)
    }
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `swift test --filter testFloatingTabBarWithCenterAction` in directory `CraftUIKit`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift
git commit -m "feat(craftuikit): redesign CraftFloatingTabBar with liquid glass and integrated action button"
```

---

### Task 5: Update `CraftCatalogView` Showcase & Full Verification

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: All tests in `CraftUIKit/Tests/CraftUIKitTests/`

**Interfaces:**
- Consumes: All `CraftUIKit` tokens and components
- Produces: Complete interactive design gallery

- [ ] **Step 1: Update `CraftCatalogView.swift`**

Update `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift` to use the new `CraftSymbol` cases, layered empty state illustration, and high-contrast badge showcase.

- [ ] **Step 2: Run complete test suite**

Run: `swift test` in directory `CraftUIKit`
Expected: All 138+ tests PASS with 0 failures.

- [ ] **Step 3: Verify clean build**

Run: `swift build` in directory `CraftUIKit`
Expected: Build complete with 0 errors.

- [ ] **Step 4: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "feat(craftuikit): update CraftCatalogView design showcase with Step 2 components"
```
