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

    // MARK: - CraftStreakCelebrationSheet Tests

    func testCraftStreakCelebrationSheetRendering() {
        let sheet = CraftStreakCelebrationSheet(
            currentStreak: 14,
            previousStreak: 13,
            weekDays: [],
            onContinue: {}
        )
        XCTAssertNotNil(sheet.body)
        XCTAssertEqual(sheet.currentStreak, 14)
        XCTAssertEqual(sheet.previousStreak, 13)
        XCTAssertEqual(sheet.tier, .blaze)
        XCTAssertTrue(sheet.weekDays.isEmpty)
    }

    func testCraftStreakCelebrationSheetWithWeekDays() {
        let mockDays: [CraftStreakDay] = [
            .init(id: "1", weekdaySymbol: "T2", status: .completed),
            .init(id: "2", weekdaySymbol: "T3", status: .completed),
            .init(id: "3", weekdaySymbol: "T4", status: .completed),
            .init(id: "4", weekdaySymbol: "T5", status: .completed, isToday: true),
            .init(id: "5", weekdaySymbol: "T6", status: .upcoming),
            .init(id: "6", weekdaySymbol: "T7", status: .upcoming),
            .init(id: "7", weekdaySymbol: "CN", status: .upcoming)
        ]
        let sheet = CraftStreakCelebrationSheet(
            currentStreak: 4,
            previousStreak: 3,
            weekDays: mockDays,
            onContinue: {}
        )
        XCTAssertNotNil(sheet.body)
        XCTAssertEqual(sheet.weekDays.count, 7)
        XCTAssertEqual(sheet.tier, .starter)
    }

    func testCraftStreakCelebrationSheetContinueCallback() {
        var didContinue = false
        let sheet = CraftStreakCelebrationSheet(
            currentStreak: 30,
            previousStreak: 29,
            weekDays: [],
            onContinue: {
                didContinue = true
            }
        )
        XCTAssertNotNil(sheet.body)
        XCTAssertEqual(sheet.tier, .legendary)
        sheet.onContinue()
        XCTAssertTrue(didContinue)
    }

    func testCraftStreakCelebrationSheetMilestones() {
        let milestone7 = CraftStreakCelebrationSheet(
            currentStreak: 7,
            previousStreak: 6,
            onContinue: {}
        )
        XCTAssertEqual(milestone7.tier, .blaze)
        XCTAssertTrue(milestone7.isMilestone)

        let milestone30 = CraftStreakCelebrationSheet(
            currentStreak: 30,
            previousStreak: 29,
            onContinue: {}
        )
        XCTAssertEqual(milestone30.tier, .legendary)
        XCTAssertTrue(milestone30.isMilestone)

        let regularDay = CraftStreakCelebrationSheet(
            currentStreak: 8,
            previousStreak: 7,
            onContinue: {}
        )
        XCTAssertFalse(regularDay.isMilestone)
    }

    func testCraftStreakCelebrationSheetCustomAccessibility() {
        let customLabel = "Custom celebration label"
        let customHint = "Custom celebration hint"
        let sheet = CraftStreakCelebrationSheet(
            currentStreak: 10,
            previousStreak: 9,
            accessibilityLabel: customLabel,
            accessibilityHint: customHint,
            onContinue: {}
        )
        XCTAssertEqual(sheet.customAccessibilityLabel, customLabel)
        XCTAssertEqual(sheet.customAccessibilityHint, customHint)
        XCTAssertNotNil(sheet.body)
    }

    // MARK: - 3D Tactile & Bento Dashboard Integration Tests

    func testCraftStreakCardTactile3DStyle() {
        let streakData = CraftStreakData(
            currentStreak: 21,
            bestStreak: 45,
            freezeTokens: 2,
            maxFreezeTokens: 3,
            nextMilestoneDays: 30,
            isCompletedToday: true
        )
        let tactileCard = CraftStreakCard(data: streakData, cardStyle: .tactile3D)
        XCTAssertEqual(tactileCard.cardStyle, .tactile3D)
        XCTAssertNotNil(tactileCard.body)
    }

    func testCraftStreakCardDayNodeStatusesComprehensive() {
        let days: [CraftStreakDay] = [
            .init(id: "1", weekdaySymbol: "T2", status: .completed, isToday: false),
            .init(id: "2", weekdaySymbol: "T3", status: .frozen, isToday: false),
            .init(id: "3", weekdaySymbol: "T4", status: .missed, isToday: false),
            .init(id: "4", weekdaySymbol: "T5", status: .pending, isToday: true),
            .init(id: "5", weekdaySymbol: "T6", status: .upcoming, isToday: false),
            .init(id: "6", weekdaySymbol: "T7", status: .upcoming, isToday: false),
            .init(id: "7", weekdaySymbol: "CN", status: .upcoming, isToday: false)
        ]
        let data = CraftStreakData(
            currentStreak: 12,
            bestStreak: 20,
            freezeTokens: 1,
            maxFreezeTokens: 3,
            nextMilestoneDays: 14,
            isCompletedToday: false,
            weekDays: days
        )
        let card = CraftStreakCard(data: data)
        XCTAssertNotNil(card.body)
        XCTAssertEqual(card.data.weekDays.count, 7)
        XCTAssertEqual(card.data.weekDays[0].status, .completed)
        XCTAssertEqual(card.data.weekDays[1].status, .frozen)
        XCTAssertEqual(card.data.weekDays[2].status, .missed)
        XCTAssertEqual(card.data.weekDays[3].status, .pending)
        XCTAssertTrue(card.data.weekDays[3].isToday)
        XCTAssertEqual(card.data.weekDays[4].status, .upcoming)
    }

    func testCraftStreakCelebrationSheetAllMilestoneBranches() {
        let milestones = [7, 14, 21, 30, 50, 60, 90, 100, 180, 365, 150]
        for m in milestones {
            let sheet = CraftStreakCelebrationSheet(
                currentStreak: m,
                previousStreak: m - 1,
                onContinue: {}
            )
            XCTAssertTrue(sheet.isMilestone, "Streak \(m) should be recognized as a milestone")
        }

        // Tier change milestone (e.g. from 6 starter to 7 blaze, or 29 blaze to 30 legendary)
        let tierChangeSheet = CraftStreakCelebrationSheet(
            currentStreak: 7,
            previousStreak: 6,
            onContinue: {}
        )
        XCTAssertTrue(tierChangeSheet.isMilestone)
    }


    // MARK: - Task 6: CraftActivityTrackerCard & CraftCelebrationSheet Tests

    func testCraftActivityTrackerCardRenderingAndTiers() {
        let statuses: [CraftActivityDayStatus] = [.completed, .pending, .saved, .missed, .upcoming]
        let days = statuses.enumerated().map { idx, status in
            CraftActivityDay(id: "\(idx)", weekdaySymbol: "D\(idx)", status: status, isToday: status == .pending)
        }

        let activityData = CraftActivityTrackerData(
            currentValue: 14,
            bestRecord: 25,
            unitKey: "craft.streak.daysUnit",
            unit: "days",
            tier: .blaze,
            shieldTokens: 2,
            maxShieldTokens: 3,
            nextMilestone: 21,
            isCompletedToday: false,
            cycleDays: days
        )

        let card = CraftActivityTrackerCard(data: activityData)
        XCTAssertNotNil(card.body)
        XCTAssertEqual(card.data.currentValue, 14)
        XCTAssertEqual(card.data.bestRecord, 25)
        XCTAssertEqual(card.data.tier, .blaze)
        XCTAssertEqual(card.data.shieldTokens, 2)
        XCTAssertEqual(card.data.maxShieldTokens, 3)
        XCTAssertEqual(card.data.cycleDays.count, 5)
    }

    func testCraftActivityTrackerCardTapCallbacks() {
        var didTapShield = false
        var didTapMilestone = false

        let data = CraftActivityTrackerData(
            currentValue: 7,
            bestRecord: 14,
            shieldTokens: 1,
            maxShieldTokens: 2,
            nextMilestone: 14
        )

        let card = CraftActivityTrackerCard(
            data: data,
            onShieldTap: { didTapShield = true },
            onMilestoneTap: { didTapMilestone = true }
        )

        XCTAssertNotNil(card.body)
        XCTAssertNotNil(card.onShieldTap)
        XCTAssertNotNil(card.onMilestoneTap)

        card.onShieldTap?()
        XCTAssertTrue(didTapShield)

        card.onMilestoneTap?()
        XCTAssertTrue(didTapMilestone)
    }

    func testCraftActivityTrackerCardStyles() {
        let data = CraftActivityTrackerData(
            currentValue: 10,
            bestRecord: 20
        )

        for style in CraftCardStyle.allCases {
            let card = CraftActivityTrackerCard(data: data, cardStyle: style)
            XCTAssertEqual(card.cardStyle, style)
            XCTAssertNotNil(card.body)
        }
    }

    func testCraftActivityTrackerCardCustomAccessibility() {
        let customLabel = "Custom activity card label"
        let customHint = "Custom activity card hint"
        let data = CraftActivityTrackerData(currentValue: 8, bestRecord: 12)

        let card = CraftActivityTrackerCard(
            data: data,
            accessibilityLabel: customLabel,
            accessibilityHint: customHint
        )

        XCTAssertEqual(card.customAccessibilityLabel, customLabel)
        XCTAssertEqual(card.customAccessibilityHint, customHint)
        XCTAssertNotNil(card.body)
    }

    func testCraftCelebrationSheetRenderingAndMilestoneDetection() {
        let sheetMilestone = CraftCelebrationSheet(
            currentValue: 30,
            previousValue: 29,
            unitKey: "craft.streak.daysUnit",
            unit: "days",
            cycleDays: [CraftActivityDay(id: "1", weekdaySymbol: "Mon", status: .completed)],
            onContinue: {}
        )

        XCTAssertNotNil(sheetMilestone.body)
        XCTAssertEqual(sheetMilestone.currentValue, 30)
        XCTAssertEqual(sheetMilestone.previousValue, 29)
        XCTAssertEqual(sheetMilestone.tier, .legendary)
        XCTAssertTrue(sheetMilestone.isMilestone)
        XCTAssertEqual(sheetMilestone.cycleDays.count, 1)

        let sheetRegular = CraftCelebrationSheet(
            currentValue: 8,
            previousValue: 7,
            onContinue: {}
        )
        XCTAssertFalse(sheetRegular.isMilestone)
        XCTAssertEqual(sheetRegular.tier, .blaze)
    }

    func testCraftCelebrationSheetContinueCallback() {
        var didContinue = false
        let sheet = CraftCelebrationSheet(
            currentValue: 10,
            previousValue: 9,
            onContinue: {
                didContinue = true
            }
        )

        XCTAssertNotNil(sheet.body)
        sheet.onContinue()
        XCTAssertTrue(didContinue)
    }

    func testCraftCelebrationSheetCustomAccessibility() {
        let customLabel = "Custom universal celebration label"
        let customHint = "Custom universal celebration hint"
        let sheet = CraftCelebrationSheet(
            currentValue: 14,
            previousValue: 13,
            accessibilityLabel: customLabel,
            accessibilityHint: customHint,
            onContinue: {}
        )

        XCTAssertEqual(sheet.customAccessibilityLabel, customLabel)
        XCTAssertEqual(sheet.customAccessibilityHint, customHint)
        XCTAssertNotNil(sheet.body)
    }

}
