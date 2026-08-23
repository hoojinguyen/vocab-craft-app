import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftStreakComponentTests: XCTestCase {
    // MARK: - CraftStreakBadgeSize Tests

    func testCraftStreakBadgeSizeProperties() {
        XCTAssertEqual(CraftStreakBadgeSize.allCases, [.sm, .md])

        XCTAssertEqual(CraftStreakBadgeSize.sm.height, 32)
        XCTAssertEqual(CraftStreakBadgeSize.sm.iconSize, 13)
        XCTAssertEqual(CraftStreakBadgeSize.sm.horizontalPadding, 10)

        XCTAssertEqual(CraftStreakBadgeSize.md.height, 40)
        XCTAssertEqual(CraftStreakBadgeSize.md.iconSize, 16)
        XCTAssertEqual(CraftStreakBadgeSize.md.horizontalPadding, 14)
    }

    // MARK: - CraftStreakBadge Initialization & Body Tests

    func testCraftStreakBadgeInitialization() {
        let badge = CraftStreakBadge(
            count: 14,
            tier: .blaze,
            isCompletedToday: true,
            size: .sm
        )
        XCTAssertNotNil(badge.body)
        XCTAssertEqual(badge.count, 14)
        XCTAssertEqual(badge.tier, .blaze)
        XCTAssertTrue(badge.isCompletedToday)
        XCTAssertEqual(badge.size, .sm)
        XCTAssertNil(badge.onTap)
    }

    func testCraftStreakBadgeDefaultTierDerivation() {
        let starterBadge = CraftStreakBadge(count: 3)
        XCTAssertEqual(starterBadge.tier, .starter)
        XCTAssertFalse(starterBadge.isCompletedToday)
        XCTAssertEqual(starterBadge.size, .md)
        XCTAssertNotNil(starterBadge.body)

        let blazeBadge = CraftStreakBadge(count: 10)
        XCTAssertEqual(blazeBadge.tier, .blaze)
        XCTAssertNotNil(blazeBadge.body)

        let legendaryBadge = CraftStreakBadge(count: 35)
        XCTAssertEqual(legendaryBadge.tier, .legendary)
        XCTAssertNotNil(legendaryBadge.body)
    }

    func testCraftStreakBadgeTiersAndSizesRendering() {
        for tier in CraftStreakTier.allCases {
            for size in CraftStreakBadgeSize.allCases {
                for isCompleted in [true, false] {
                    let badge = CraftStreakBadge(
                        count: 21,
                        tier: tier,
                        isCompletedToday: isCompleted,
                        size: size
                    )
                    XCTAssertEqual(badge.tier, tier)
                    XCTAssertEqual(badge.size, size)
                    XCTAssertEqual(badge.isCompletedToday, isCompleted)
                    XCTAssertNotNil(badge.body)
                }
            }
        }
    }

    func testCraftStreakBadgeWithTapAction() {
        var didTap = false
        let badge = CraftStreakBadge(
            count: 5,
            tier: .starter,
            isCompletedToday: false,
            size: .sm
        ) {
            didTap = true
        }

        XCTAssertNotNil(badge.body)
        XCTAssertNotNil(badge.onTap)
        badge.onTap?()
        XCTAssertTrue(didTap)
    }

    func testCraftStreakBadgeCustomAccessibility() {
        let customLabel = "Custom streak label"
        let customHint = "Custom streak hint"
        let badge = CraftStreakBadge(
            count: 100,
            tier: .legendary,
            isCompletedToday: true,
            size: .md,
            accessibilityLabel: customLabel,
            accessibilityHint: customHint
        ) { }

        XCTAssertEqual(badge.customAccessibilityLabel, customLabel)
        XCTAssertEqual(badge.customAccessibilityHint, customHint)
        XCTAssertNotNil(badge.body)
    }
}
