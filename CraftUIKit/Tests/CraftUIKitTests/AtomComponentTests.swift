import XCTest
import SwiftUI
@testable import CraftUIKit

final class AtomComponentTests: XCTestCase {

    // MARK: - CraftBadge Tests

    func testBadgeInit() {
        let badge = CraftBadge("PRO", iconName: "star.fill", variant: .solid, tone: .primary, size: .sm)
        XCTAssertEqual(badge.title, "PRO")
        XCTAssertEqual(badge.iconName, "star.fill")
        XCTAssertEqual(badge.variant, .solid)
        XCTAssertEqual(badge.tone, .primary)
        XCTAssertEqual(badge.size, .sm)
    }

    func testBadgeDefaults() {
        let defaultBadge = CraftBadge("Badge")
        XCTAssertEqual(defaultBadge.title, "Badge")
        XCTAssertNil(defaultBadge.iconName)
        XCTAssertEqual(defaultBadge.variant, .subtle)
        XCTAssertEqual(defaultBadge.tone, .primary)
        XCTAssertEqual(defaultBadge.size, .md)
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

    // MARK: - CraftIcon & CraftIconSize Tests

    func testIconSizeTokens() {
        XCTAssertEqual(CraftIconSize.sm.pointSize, 14)
        XCTAssertEqual(CraftIconSize.md.pointSize, 18)
        XCTAssertEqual(CraftIconSize.lg.pointSize, 24)
        XCTAssertEqual(CraftIconSize.xl.pointSize, 32)
    }

    func testIconInit() {
        let icon = CraftIcon("star.fill", size: .lg, color: .yellow)
        XCTAssertEqual(icon.name, "star.fill")
        XCTAssertEqual(icon.size, .lg)
        XCTAssertEqual(icon.color, .yellow)
        XCTAssertNotNil(icon.body)
    }

    func testIconDefaults() {
        let defaultIcon = CraftIcon("sparkles")
        XCTAssertEqual(defaultIcon.name, "sparkles")
        XCTAssertEqual(defaultIcon.size, .md)
        XCTAssertNil(defaultIcon.color)
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
        XCTAssertNotNil(button.body)

        button.action()
        XCTAssertTrue(actionExecuted)
    }

    func testIconButtonShapesAndVariants() {
        for shape in CraftIconButtonShape.allCases {
            for variant in CraftIconButtonVariant.allCases {
                for size in CraftIconSize.allCases {
                    let btn = CraftIconButton(
                        iconName: "plus",
                        size: size,
                        shape: shape,
                        variant: variant
                    ) {}
                    XCTAssertEqual(btn.shape, shape)
                    XCTAssertEqual(btn.variant, variant)
                    XCTAssertEqual(btn.size, size)
                    XCTAssertNotNil(btn.body)
                }
            }
        }
    }

    // MARK: - CraftDivider Tests

    func testDividerInit() {
        let horizontalDivider = CraftDivider(axis: .horizontal, thickness: 1.0)
        XCTAssertEqual(horizontalDivider.axis, .horizontal)
        XCTAssertEqual(horizontalDivider.thickness, 1.0)
        XCTAssertEqual(horizontalDivider.customThickness, 1.0)
        XCTAssertNotNil(horizontalDivider.body)

        let verticalDivider = CraftDivider(axis: .vertical, color: .gray, thickness: 2.0)
        XCTAssertEqual(verticalDivider.axis, .vertical)
        XCTAssertEqual(verticalDivider.thickness, 2.0)
        XCTAssertEqual(verticalDivider.customThickness, 2.0)
        XCTAssertEqual(verticalDivider.color, .gray)
        XCTAssertNotNil(verticalDivider.body)
    }

    func testDividerDefaults() {
        let defaultDivider = CraftDivider()
        XCTAssertEqual(defaultDivider.axis, .horizontal)
        XCTAssertNil(defaultDivider.thickness)
        XCTAssertNil(defaultDivider.customThickness)
        XCTAssertNil(defaultDivider.color)
        XCTAssertNotNil(defaultDivider.body)
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

    // MARK: - CraftText Tests

    func testCraftTextInit() {
        let text = CraftText(
            "Welcome to Craft",
            style: .titleLarge,
            color: .primary,
            lineLimit: 2,
            textAlignment: .center
        )
        XCTAssertEqual(text.text, "Welcome to Craft")
        XCTAssertEqual(text.style, .titleLarge)
        XCTAssertEqual(text.color, .primary)
        XCTAssertEqual(text.lineLimit, 2)
        XCTAssertEqual(text.textAlignment, .center)
        XCTAssertNotNil(text.body)
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
}
