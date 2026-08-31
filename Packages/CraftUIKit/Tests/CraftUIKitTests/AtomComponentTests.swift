@testable import CraftUIKit
import SwiftUI
#if canImport(XCTest)
import XCTest
#endif

final class AtomComponentTests: XCTestCase {
    // MARK: - CraftBadge Tests

    func testBadgeInit() {
        let badge = CraftBadge("PRO", iconName: "star.fill", variant: .solid, tone: .primary, size: .sm)
        XCTAssertEqual(badge.title, "PRO")
        XCTAssertEqual(badge.iconName, "star.fill")
        XCTAssertEqual(badge.variant, .solid)
        XCTAssertEqual(badge.tone, .primary)
        XCTAssertEqual(badge.size, .sm)
        XCTAssertEqual(badge.shape, .capsule)
        XCTAssertNil(badge.style)
        XCTAssertNil(badge.customTint)
    }

    func testBadgeDefaults() {
        let defaultBadge = CraftBadge("Badge")
        XCTAssertEqual(defaultBadge.title, "Badge")
        XCTAssertNil(defaultBadge.iconName)
        XCTAssertEqual(defaultBadge.variant, .subtle)
        XCTAssertEqual(defaultBadge.tone, .primary)
        XCTAssertEqual(defaultBadge.size, .md)
        XCTAssertEqual(defaultBadge.shape, .capsule)
        XCTAssertNil(defaultBadge.style)
        XCTAssertNil(defaultBadge.customTint)
    }

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

    func testBadgeLocalizedAndVerbatim() {
        let localizedBadge = CraftBadge(LocalizedStringKey("badge_new"), iconName: "sparkles", variant: .solid)
        XCTAssertNil(localizedBadge.title)
        XCTAssertEqual(localizedBadge.iconName, "sparkles")
        XCTAssertNotNil(localizedBadge.body)

        let localizedSymbolBadge = CraftBadge(LocalizedStringKey("badge_new"), symbol: .sparkles, variant: .solid)
        XCTAssertNil(localizedSymbolBadge.title)
        XCTAssertEqual(localizedSymbolBadge.symbol, .sparkles)
        XCTAssertEqual(localizedSymbolBadge.iconName, "sparkles")
        XCTAssertNotNil(localizedSymbolBadge.body)

        let verbatimBadge = CraftBadge(verbatim: "LEVEL 5", variant: .outline, tone: .warning, size: .sm)
        XCTAssertEqual(verbatimBadge.title, "LEVEL 5")
        XCTAssertEqual(verbatimBadge.tone, .warning)
        XCTAssertNotNil(verbatimBadge.body)

        let verbatimSymbolBadge = CraftBadge(verbatim: "STREAK", symbol: .streak, variant: .solid, tone: .warning, size: .sm)
        XCTAssertEqual(verbatimSymbolBadge.title, "STREAK")
        XCTAssertEqual(verbatimSymbolBadge.symbol, .streak)
        XCTAssertEqual(verbatimSymbolBadge.iconName, "flame.fill")
        XCTAssertEqual(verbatimSymbolBadge.tone, .warning)
        XCTAssertNotNil(verbatimSymbolBadge.body)
    }

    func testBadgeVariantsAndTones() {
        for variant in CraftBadgeVariant.allCases {
            for tone in CraftBadgeTone.allCases {
                for size in CraftBadgeSize.allCases {
                    let badge = CraftBadge("Test", variant: variant, tone: tone, size: size)
                    XCTAssertEqual(badge.variant, variant)
                    XCTAssertEqual(badge.tone, tone)
                    XCTAssertEqual(badge.size, size)
                    XCTAssertNotNil(badge.body)
                }
            }
        }
    }

    func testBadgeSurfaceStyles() {
        for surfaceStyle in CraftSurfaceStyle.allCases {
            let badge = CraftBadge("Status", symbol: .sparkles, tone: .primary, style: surfaceStyle)
            XCTAssertEqual(badge.style, surfaceStyle)
            XCTAssertNotNil(badge.body)
        }
    }

    func testBadgeShapes() {
        let capsuleBadge = CraftBadge("Capsule", shape: .capsule)
        XCTAssertEqual(capsuleBadge.shape, .capsule)
        XCTAssertNotNil(capsuleBadge.body)

        let roundedBadge = CraftBadge("Rounded", shape: .roundedRectangle(radius: 8))
        XCTAssertEqual(roundedBadge.shape, .roundedRectangle(radius: 8))
        XCTAssertNotNil(roundedBadge.body)
    }

    func testBadgeCustomTint() {
        let customBadge = CraftBadge("Custom", customTint: .indigo)
        XCTAssertEqual(customBadge.customTint, .indigo)
        XCTAssertEqual(customBadge.effectiveToneColor, .indigo)
        XCTAssertNotNil(customBadge.body)
    }

    func testBadgeCombinations() {
        let complexBadge = CraftBadge(
            verbatim: "PREMIUM",
            symbol: .streak,
            variant: .solid,
            tone: .warning,
            size: .sm,
            style: .glass,
            shape: .roundedRectangle(radius: 6),
            customTint: .orange
        )
        XCTAssertEqual(complexBadge.title, "PREMIUM")
        XCTAssertEqual(complexBadge.symbol, .streak)
        XCTAssertEqual(complexBadge.style, .glass)
        XCTAssertEqual(complexBadge.shape, .roundedRectangle(radius: 6))
        XCTAssertEqual(complexBadge.customTint, .orange)
        XCTAssertNotNil(complexBadge.body)
    }

    // MARK: - CraftIcon & CraftIconSize Tests

    func testCraftSymbolCasesAndRawValues() {
        XCTAssertEqual(CraftSymbol.home.rawValue, "house")
        XCTAssertEqual(CraftSymbol.homeFill.rawValue, "house.fill")
        XCTAssertEqual(CraftSymbol.study.rawValue, "character.book.closed")
        XCTAssertEqual(CraftSymbol.booksFill.rawValue, "books.vertical.fill")
        XCTAssertEqual(CraftSymbol.search.rawValue, "magnifyingglass")
        XCTAssertEqual(CraftSymbol.profileFill.rawValue, "person.crop.circle.fill")
        XCTAssertEqual(CraftSymbol.settingsFill.rawValue, "gearshape.fill")
        XCTAssertEqual(CraftSymbol.checkmarkCircle.rawValue, "checkmark.circle.fill")
        XCTAssertEqual(CraftSymbol.wrongCircle.rawValue, "xmark.circle.fill")
        XCTAssertEqual(CraftSymbol.sparkles.rawValue, "sparkles")
        XCTAssertEqual(CraftSymbol.streak.rawValue, "flame.fill")
        XCTAssertFalse(CraftSymbol.allCases.isEmpty)
    }

    func testIconSizeTokens() {
        XCTAssertEqual(CraftIconSize.sm.pointSize, 14)
        XCTAssertEqual(CraftIconSize.md.pointSize, 18)
        XCTAssertEqual(CraftIconSize.lg.pointSize, 24)
        XCTAssertEqual(CraftIconSize.xl.pointSize, 32)
    }

    func testIconInit() {
        let icon = CraftIcon("star.fill", size: .lg, color: .yellow, accessibilityLabel: "Favorite")
        XCTAssertEqual(icon.name, "star.fill")
        XCTAssertEqual(icon.size, .lg)
        XCTAssertEqual(icon.color, .yellow)
        XCTAssertEqual(icon.accessibilityLabel, "Favorite")
        XCTAssertNotNil(icon.body)
    }

    func testIconDefaults() {
        let defaultIcon = CraftIcon("sparkles")
        XCTAssertEqual(defaultIcon.name, "sparkles")
        XCTAssertEqual(defaultIcon.size, .md)
        XCTAssertEqual(defaultIcon.renderingMode, .hierarchical)
        XCTAssertEqual(defaultIcon.weight, .semibold)
        XCTAssertNil(defaultIcon.color)
        XCTAssertNil(defaultIcon.accessibilityLabel)
    }

    func testCraftIconWithSymbolAndRenderingMode() {
        let icon = CraftIcon(.study, size: .lg, color: .orange, renderingMode: .hierarchical, weight: .bold, accessibilityLabel: "Study Deck")
        XCTAssertEqual(icon.name, "character.book.closed")
        XCTAssertEqual(icon.symbol, .study)
        XCTAssertEqual(icon.size, .lg)
        XCTAssertEqual(icon.color, .orange)
        XCTAssertEqual(icon.renderingMode, .hierarchical)
        XCTAssertEqual(icon.weight, .bold)
        XCTAssertEqual(icon.accessibilityLabel, "Study Deck")
        XCTAssertNotNil(icon.body)
    }

    func testCraftIconRenderingModes() {
        for mode in [CraftIconRenderingMode.hierarchical, .monochrome, .multicolor] {
            let icon = CraftIcon("star.fill", renderingMode: mode)
            XCTAssertEqual(icon.renderingMode, mode)
            XCTAssertNotNil(icon.body)
        }
    }

    // MARK: - CraftIconButton Tests

    func testIconButtonInit() {
        var actionExecuted = false
        let button = CraftIconButton(
            iconName: "xmark",
            size: .md,
            shape: .circle,
            variant: .subtle,
            accessibilityLabel: "Close"
        ) {
            actionExecuted = true
        }

        XCTAssertEqual(button.iconName, "xmark")
        XCTAssertEqual(button.size, .md)
        XCTAssertEqual(button.shape, .circle)
        XCTAssertEqual(button.variant, .subtle)
        XCTAssertEqual(button.accessibilityLabel, "Close")
        XCTAssertEqual(button.minTouchTarget, 44)
        XCTAssertNil(button.style)
        XCTAssertNil(button.customTint)
        XCTAssertNotNil(button.body)

        button.action()
        XCTAssertTrue(actionExecuted)
    }

    func testIconButtonWithCraftSymbol() {
        var tapped = false
        let btn = CraftIconButton(
            symbol: .bookmark,
            size: .lg,
            shape: .square,
            variant: .filled,
            accessibilityLabel: "Save Bookmark"
        ) {
            tapped = true
        }
        XCTAssertEqual(btn.iconName, "bookmark")
        XCTAssertEqual(btn.symbol, .bookmark)
        XCTAssertEqual(btn.size, .lg)
        XCTAssertEqual(btn.shape, .square)
        XCTAssertNotNil(btn.body)
        btn.action()
        XCTAssertTrue(tapped)
    }
    func testIconButtonDangerVariant() {
        let btn = CraftIconButton(
            iconName: "trash.fill",
            variant: .danger,
            accessibilityLabel: "Delete"
        ) {}
        XCTAssertEqual(btn.variant, .danger)
        XCTAssertEqual(CraftIconButtonVariant.allCases.contains(.danger), true)
    }

    func testIconButtonStyleInstantiation() {
        let style = CraftIconButtonStyle(
            size: .md,
            shape: .circle,
            variant: .subtle,
            style: .tactile3D,
            customTint: nil,
            isSelected: false,
            isLoading: false
        )
        XCTAssertEqual(style.size, .md)
        XCTAssertEqual(style.shape, .circle)
        XCTAssertEqual(style.variant, .subtle)
        XCTAssertEqual(style.style, .tactile3D)
        XCTAssertFalse(style.isSelected)
        XCTAssertFalse(style.isLoading)
    }

    func testIconButtonSelectedAndLoadingStates() {
        let selectedBtn = CraftIconButton(
            symbol: .favoriteFill,
            isSelected: true,
            accessibilityLabel: "Favorited"
        ) {}
        XCTAssertTrue(selectedBtn.isSelected)
        XCTAssertFalse(selectedBtn.isLoading)
        XCTAssertEqual(selectedBtn.accessibilityLabel, "Favorited")
        XCTAssertNotNil(selectedBtn.body)

        let loadingBtn = CraftIconButton(
            iconName: "arrow.clockwise",
            isLoading: true,
            accessibilityLabel: "Refreshing",
            accessibilityHint: "Fetches latest data"
        ) {}
        XCTAssertTrue(loadingBtn.isLoading)
        XCTAssertEqual(loadingBtn.accessibilityHint, "Fetches latest data")
        XCTAssertNotNil(loadingBtn.body)
    }

    func testIconButtonLocalizedStringKeyInit() {
        let localizedBtn = CraftIconButton(
            symbol: .settings,
            accessibilityLabelKey: "craft.settings",
            accessibilityHint: "Opens settings"
        ) {}
        XCTAssertEqual(localizedBtn.accessibilityLabelKey, "craft.settings")
        XCTAssertNotNil(localizedBtn.body)
    }

    func testIconButtonShapesAndVariants() {
        for shape in CraftIconButtonShape.allCases {
            for variant in CraftIconButtonVariant.allCases {
                for size in CraftIconSize.allCases {
                    let btn = CraftIconButton(
                        iconName: "plus",
                        size: size,
                        shape: shape,
                        variant: variant,
                        accessibilityLabel: "Add item"
                    ) {}
                    XCTAssertEqual(btn.shape, shape)
                    XCTAssertEqual(btn.variant, variant)
                    XCTAssertEqual(btn.size, size)
                    XCTAssertEqual(btn.accessibilityLabel, "Add item")
                    XCTAssertNotNil(btn.body)
                }
            }
        }
    }

    func testIconButtonSurfaceStyles() {
        for surfaceStyle in CraftSurfaceStyle.allCases {
            let btn = CraftIconButton(
                symbol: .sparkles,
                shape: .roundedRectangle(radius: 12),
                style: surfaceStyle,
                customTint: .cyan,
                accessibilityLabel: "Sparkle"
            ) {}
            XCTAssertEqual(btn.style, surfaceStyle)
            XCTAssertEqual(btn.shape, .roundedRectangle(radius: 12))
            XCTAssertEqual(btn.customTint, .cyan)
            XCTAssertEqual(btn.effectiveTint, .cyan)
            XCTAssertNotNil(btn.body)
        }
    }

    func testIconButtonTouchTarget() {
        let btn = CraftIconButton(
            iconName: "heart.fill",
            size: .sm,
            accessibilityLabel: "Favorite"
        ) {}
        XCTAssertEqual(btn.minTouchTarget, 44)
    }

    func testIconButtonFilledWithCustomTintHasTextInverseForeground() {
        let btn = CraftIconButton(
            symbol: .audio,
            variant: .filled,
            customTint: .orange,
            accessibilityLabel: "Audio"
        ) {}
        XCTAssertEqual(btn.variant, .filled)
        XCTAssertEqual(btn.customTint, .orange)
        XCTAssertNotNil(btn.body)
    }

    // MARK: - CraftDivider Tests

    func testDividerInit() {
        let horizontalDivider = CraftDivider(axis: .horizontal, thickness: 1.0)
        XCTAssertEqual(horizontalDivider.axis, .horizontal)
        XCTAssertEqual(horizontalDivider.thickness, 1.0)
        XCTAssertEqual(horizontalDivider.customThickness, 1.0)
        XCTAssertEqual(horizontalDivider.style, .solid)
        XCTAssertNotNil(horizontalDivider.body)

        let verticalDivider = CraftDivider(axis: .vertical, color: .gray, thickness: 2.0)
        XCTAssertEqual(verticalDivider.axis, .vertical)
        XCTAssertEqual(verticalDivider.thickness, 2.0)
        XCTAssertEqual(verticalDivider.customThickness, 2.0)
        XCTAssertEqual(verticalDivider.color, .gray)
        XCTAssertEqual(verticalDivider.style, .solid)
        XCTAssertNotNil(verticalDivider.body)
    }

    func testDividerDefaults() {
        let defaultDivider = CraftDivider()
        XCTAssertEqual(defaultDivider.axis, .horizontal)
        XCTAssertNil(defaultDivider.thickness)
        XCTAssertNil(defaultDivider.customThickness)
        XCTAssertNil(defaultDivider.color)
        XCTAssertEqual(defaultDivider.style, .solid)
        XCTAssertNotNil(defaultDivider.body)
    }

    func testDividerStyles() {
        let solidDivider = CraftDivider(style: .solid)
        XCTAssertEqual(solidDivider.style, .solid)
        XCTAssertNotNil(solidDivider.body)

        let dashedDivider = CraftDivider(axis: .horizontal, color: .blue, thickness: 2, style: .dashed(dash: 8, gap: 4))
        XCTAssertEqual(dashedDivider.style, .dashed(dash: 8, gap: 4))
        XCTAssertNotNil(dashedDivider.body)

        let gradient = LinearGradient(colors: [.red, .blue], startPoint: .leading, endPoint: .trailing)
        let gradientDivider = CraftDivider(style: .gradient(gradient))
        XCTAssertEqual(gradientDivider.style, .gradient(gradient))
        XCTAssertNotNil(gradientDivider.body)
    }

    func testDividerStyleEquality() {
        XCTAssertEqual(CraftDividerStyle.solid, CraftDividerStyle.solid)
        XCTAssertEqual(CraftDividerStyle.dashed(dash: 6, gap: 3), CraftDividerStyle.dashed(dash: 6, gap: 3))
        XCTAssertNotEqual(CraftDividerStyle.solid, CraftDividerStyle.dashed(dash: 6, gap: 3))
        XCTAssertNotEqual(CraftDividerStyle.dashed(dash: 6, gap: 3), CraftDividerStyle.dashed(dash: 4, gap: 2))

        let gradient1 = LinearGradient(colors: [.red, .blue], startPoint: .leading, endPoint: .trailing)
        let gradient2 = LinearGradient(colors: [.red, .blue], startPoint: .leading, endPoint: .trailing)
        XCTAssertEqual(CraftDividerStyle.gradient(gradient1), CraftDividerStyle.gradient(gradient2))
    }

    // MARK: - CraftSpinner Tests

    func testSpinnerInit() {
        let spinner = CraftSpinner(size: .md, color: .blue, lineWidth: 3.0)
        XCTAssertEqual(spinner.size, .md)
        XCTAssertEqual(spinner.color, .blue)
        XCTAssertEqual(spinner.lineWidth, 3.0)
        XCTAssertNotNil(spinner.body)
    }

    func testSpinnerDefaultLineWidths() {
        let smSpinner = CraftSpinner(size: .sm)
        XCTAssertEqual(smSpinner.lineWidth, 2.0)

        let mdSpinner = CraftSpinner(size: .md)
        XCTAssertEqual(mdSpinner.lineWidth, 2.5)

        let lgSpinner = CraftSpinner(size: .lg)
        XCTAssertEqual(lgSpinner.lineWidth, 3.0)

        let xlSpinner = CraftSpinner(size: .xl)
        XCTAssertEqual(xlSpinner.lineWidth, 4.0)
    }

    func testSpinnerCustomLineWidth() {
        let customSpinner = CraftSpinner(size: .sm, lineWidth: 5.0)
        XCTAssertEqual(customSpinner.lineWidth, 5.0)
        XCTAssertNotNil(customSpinner.body)
    }

    // MARK: - CraftText Tests

    func testCraftTextInit() {
        let text = CraftText(
            "Welcome to Craft",
            style: .titleLarge,
            color: .primary,
            lineLimit: 2,
            textAlignment: .center,
            tracking: 1.2,
            lineSpacing: 4.0
        )
        XCTAssertEqual(text.text, "Welcome to Craft")
        XCTAssertEqual(text.style, .titleLarge)
        XCTAssertEqual(text.color, .primary)
        XCTAssertEqual(text.lineLimit, 2)
        XCTAssertEqual(text.textAlignment, .center)
        XCTAssertEqual(text.tracking, 1.2)
        XCTAssertEqual(text.lineSpacing, 4.0)
        XCTAssertNotNil(text.body)
    }

    func testCraftTextLocalizationAndVerbatim() {
        let keyText = CraftText(LocalizedStringKey("welcome_message"), style: .headline, tracking: 0.5, lineSpacing: 2)
        XCTAssertNil(keyText.text)
        XCTAssertEqual(keyText.style, .headline)
        XCTAssertEqual(keyText.tracking, 0.5)
        XCTAssertEqual(keyText.lineSpacing, 2)
        XCTAssertNotNil(keyText.body)

        let verbatimText = CraftText(verbatim: "Hello World", style: .bodyLarge, color: .blue, tracking: 1.0)
        XCTAssertEqual(verbatimText.text, "Hello World")
        XCTAssertEqual(verbatimText.style, .bodyLarge)
        XCTAssertEqual(verbatimText.color, .blue)
        XCTAssertEqual(verbatimText.tracking, 1.0)
        XCTAssertNotNil(verbatimText.body)
    }

    func testCraftTextAttributedString() throws {
        var attributed = AttributedString("Rich Attributed Text")
        attributed.font = .system(size: 16, weight: .bold)

        let text = CraftText(
            attributed,
            style: .bodyMedium,
            color: .purple,
            lineLimit: 3,
            textAlignment: .trailing,
            tracking: 0.8,
            lineSpacing: 6.0
        )

        XCTAssertEqual(text.text, "Rich Attributed Text")
        XCTAssertEqual(text.attributedString, attributed)
        XCTAssertEqual(text.style, .bodyMedium)
        XCTAssertEqual(text.color, .purple)
        XCTAssertEqual(text.lineLimit, 3)
        XCTAssertEqual(text.textAlignment, .trailing)
        XCTAssertEqual(text.tracking, 0.8)
        XCTAssertEqual(text.lineSpacing, 6.0)
        XCTAssertNotNil(text.body)

        let markdown = try AttributedString(markdown: "Learn **bold** and *italic* words with [docs](https://craft.ui)")
        let markdownText = CraftText(markdown, style: .bodySerif)
        XCTAssertEqual(markdownText.attributedString, markdown)
        XCTAssertNotNil(markdownText.body)
    }

    func testDomainTypographyStyles() {
        let serifTitle = CraftText("Serendipity", style: .displaySerif)
        XCTAssertEqual(serifTitle.style, .displaySerif)
        XCTAssertNotNil(serifTitle.body)

        let phoneticText = CraftText("/ˌser.ənˈdɪp.ə.ti/", style: .phonetic)
        XCTAssertEqual(phoneticText.style, .phonetic)
        XCTAssertNotNil(phoneticText.body)

        let bodyEditorial = CraftText("Sample passage", style: .bodySerif)
        XCTAssertEqual(bodyEditorial.style, .bodySerif)
        XCTAssertNotNil(bodyEditorial.body)

        let scoreMetric = CraftText("10,000 XP", style: .metricRounded)
        XCTAssertEqual(scoreMetric.style, .metricRounded)
        XCTAssertNotNil(scoreMetric.body)
    }

    // MARK: - View Modifiers Application Tests

    func testModifiersCompileAndApply() {
        let view = Text("Hello")
            .craftPressEffect(scale: 0.95, hapticFeedback: false)
            .craftShimmer(isActive: true, duration: 2.0, bounce: true)
            .craftTypography(.headline)

        XCTAssertNotNil(view)
    }

    func testShimmerInactiveState() {
        let view = Text("Inactive Shimmer")
            .craftShimmer(isActive: false)

        XCTAssertNotNil(view)
    }

    func testCraftDividerDashedShapeRendering() {
        let divider = CraftDivider(axis: .horizontal, style: .dashed(dash: 4, gap: 2))
        XCTAssertNotNil(divider.body)

        let verticalDivider = CraftDivider(axis: .vertical, style: .dashed(dash: 6, gap: 3))
        XCTAssertNotNil(verticalDivider.body)
    }

    func testCraftSpinnerRenderingAndBody() {
        let spinner = CraftSpinner(size: .md, color: .blue, lineWidth: 3)
        XCTAssertNotNil(spinner.body)
    }

    func testCraftStreakBadgePulsingAndBody() {
        let badge = CraftStreakBadge(count: 5, isCompletedToday: false)
        XCTAssertNotNil(badge.body)
        let completedBadge = CraftStreakBadge(count: 7, isCompletedToday: true)
        XCTAssertNotNil(completedBadge.body)
    }

    func testCraftStreakBadgeAccessibilityLocalization() {
        // Tiers
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_starter"), "Starter Streak")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_starter", language: "vi"), "Chuỗi khởi đầu")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_blaze"), "Blaze Streak")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_blaze", language: "vi"), "Chuỗi rực lửa")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_legendary"), "Legendary Streak")
        XCTAssertEqual(CraftLocalized.string("craft.streak.tier_legendary", language: "vi"), "Chuỗi huyền thoại")

        // Statuses
        XCTAssertEqual(CraftLocalized.string("craft.streak.today_completed"), "Completed for today")
        XCTAssertEqual(CraftLocalized.string("craft.streak.today_completed", language: "vi"), "Hôm nay đã hoàn thành")
        XCTAssertEqual(CraftLocalized.string("craft.streak.today_pending"), "Pending completion for today")
        XCTAssertEqual(CraftLocalized.string("craft.streak.today_pending", language: "vi"), "Hôm nay chưa hoàn thành")

        // Formatted Badge & Hint
        let badgeEN = CraftLocalized.format("craft.streak.badge_a11y_format", 7, "Blaze", "Completed for today")
        XCTAssertEqual(badgeEN, "7-day study streak, Blaze tier. Completed for today")
        let badgeVI = CraftLocalized.format("craft.streak.badge_a11y_format", language: "vi", 7, "Rực lửa", "Hôm nay đã hoàn thành")
        XCTAssertEqual(badgeVI, "Chuỗi 7 ngày học liên tiếp, Cấp độ Rực lửa. Hôm nay đã hoàn thành")

        XCTAssertEqual(CraftLocalized.string("craft.streak.badge_a11y_hint"), "Double tap to view streak details.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.badge_a11y_hint", language: "vi"), "Chạm hai lần để xem chi tiết chuỗi ngày.")
    }

    // MARK: - CraftPulsingAuraRing Tests

    func testCraftPulsingAuraRingInit() {
        let ring = CraftPulsingAuraRing(color: .orange, size: 36, lineWidth: 3.0)
        XCTAssertEqual(ring.color, .orange)
        XCTAssertEqual(ring.size, 36)
        XCTAssertEqual(ring.lineWidth, 3.0)
        XCTAssertNotNil(ring.body)
    }

    func testCraftPulsingAuraRingDefaults() {
        let ring = CraftPulsingAuraRing(color: .blue)
        XCTAssertEqual(ring.color, .blue)
        XCTAssertEqual(ring.size, 28)
        XCTAssertEqual(ring.lineWidth, 2.5)
        XCTAssertNotNil(ring.body)
    }
}
