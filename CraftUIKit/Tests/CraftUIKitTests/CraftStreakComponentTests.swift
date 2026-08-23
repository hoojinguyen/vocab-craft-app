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

    // MARK: - CraftStreakCard Tests

    func testCraftStreakCardRendering() {
        let mockDays: [CraftStreakDay] = [
            .init(id: "1", weekdaySymbol: "T2", status: .completed),
            .init(id: "2", weekdaySymbol: "T3", status: .completed),
            .init(id: "3", weekdaySymbol: "T4", status: .frozen),
            .init(id: "4", weekdaySymbol: "T5", status: .pending, isToday: true),
            .init(id: "5", weekdaySymbol: "T6", status: .upcoming),
            .init(id: "6", weekdaySymbol: "T7", status: .upcoming),
            .init(id: "7", weekdaySymbol: "CN", status: .upcoming)
        ]
        let streakData = CraftStreakData(
            currentStreak: 14,
            bestStreak: 30,
            freezeTokens: 2,
            maxFreezeTokens: 3,
            nextMilestoneDays: 21,
            isCompletedToday: false,
            weekDays: mockDays
        )
        let card = CraftStreakCard(data: streakData)
        XCTAssertNotNil(card.body)
        XCTAssertEqual(card.data.currentStreak, 14)
        XCTAssertEqual(card.data.bestStreak, 30)
        XCTAssertEqual(card.data.freezeTokens, 2)
        XCTAssertEqual(card.data.maxFreezeTokens, 3)
        XCTAssertEqual(card.data.nextMilestoneDays, 21)
        XCTAssertEqual(card.data.weekDays.count, 7)
    }

    func testCraftStreakCardTapCallbacks() {
        var didTapFreeze = false
        var didTapMilestone = false

        let streakData = CraftStreakData(
            currentStreak: 7,
            bestStreak: 14,
            freezeTokens: 1,
            maxFreezeTokens: 2,
            nextMilestoneDays: 14
        )

        let card = CraftStreakCard(
            data: streakData,
            onFreezeTap: { didTapFreeze = true },
            onMilestoneTap: { didTapMilestone = true }
        )

        XCTAssertNotNil(card.body)
        XCTAssertNotNil(card.onFreezeTap)
        XCTAssertNotNil(card.onMilestoneTap)

        card.onFreezeTap?()
        XCTAssertTrue(didTapFreeze)

        card.onMilestoneTap?()
        XCTAssertTrue(didTapMilestone)
    }

    func testCraftStreakCardAllTiersAndStatuses() {
        let allStatuses: [CraftStreakDayStatus] = [.completed, .pending, .frozen, .missed, .upcoming]
        let days = allStatuses.enumerated().map { idx, status in
            CraftStreakDay(id: "\(idx)", weekdaySymbol: "D\(idx)", status: status, isToday: status == .pending)
        }

        let tiersToTest: [Int] = [3, 14, 45] // starter, blaze, legendary
        for streakCount in tiersToTest {
            let data = CraftStreakData(
                currentStreak: streakCount,
                bestStreak: 60,
                freezeTokens: 3,
                maxFreezeTokens: 3,
                nextMilestoneDays: streakCount + 7,
                isCompletedToday: streakCount % 2 == 0,
                weekDays: days
            )

            let card = CraftStreakCard(data: data)
            XCTAssertNotNil(card.body)
            XCTAssertEqual(card.data.tier, CraftStreakTier.tier(for: streakCount))
        }
    }

    func testCraftStreakCardCustomAccessibility() {
        let customLabel = "Custom streak card label"
        let customHint = "Custom streak card hint"
        let streakData = CraftStreakData(currentStreak: 5, bestStreak: 10)

        let card = CraftStreakCard(
            data: streakData,
            accessibilityLabel: customLabel,
            accessibilityHint: customHint
        )

        XCTAssertEqual(card.customAccessibilityLabel, customLabel)
        XCTAssertEqual(card.customAccessibilityHint, customHint)
        XCTAssertNotNil(card.body)
    }
}
