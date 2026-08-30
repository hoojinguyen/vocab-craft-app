#if canImport(XCTest)
import XCTest
#endif
import SwiftUI
@testable import CraftUIKit

final class CraftStreakModelTests: XCTestCase {
    // MARK: - CraftStreakTier & CraftActivityTier Tests

    func testStreakTierThresholds() {
        XCTAssertEqual(CraftStreakTier.tier(for: -1), .starter)
        XCTAssertEqual(CraftStreakTier.tier(for: 0), .starter)
        XCTAssertEqual(CraftStreakTier.tier(for: 5), .starter)
        XCTAssertEqual(CraftStreakTier.tier(for: 6), .starter)
        XCTAssertEqual(CraftStreakTier.tier(for: 7), .blaze)
        XCTAssertEqual(CraftStreakTier.tier(for: 14), .blaze)
        XCTAssertEqual(CraftStreakTier.tier(for: 29), .blaze)
        XCTAssertEqual(CraftStreakTier.tier(for: 30), .legendary)
        XCTAssertEqual(CraftStreakTier.tier(for: 100), .legendary)
    }

    func testStreakTierCasesAndRawValues() {
        XCTAssertEqual(CraftStreakTier.allCases, [.starter, .blaze, .legendary])
        XCTAssertEqual(CraftStreakTier.starter.rawValue, "starter")
        XCTAssertEqual(CraftStreakTier.blaze.rawValue, "blaze")
        XCTAssertEqual(CraftStreakTier.legendary.rawValue, "legendary")
    }

    func testActivityTierThresholdsAndCases() {
        XCTAssertEqual(CraftActivityTier.tier(for: 0), .starter)
        XCTAssertEqual(CraftActivityTier.tier(for: 6), .starter)
        XCTAssertEqual(CraftActivityTier.tier(for: 7), .blaze)
        XCTAssertEqual(CraftActivityTier.tier(for: 29), .blaze)
        XCTAssertEqual(CraftActivityTier.tier(for: 30), .legendary)
        XCTAssertEqual(CraftActivityTier.allCases, [.starter, .blaze, .legendary])
    }

    // MARK: - CraftStreakDayStatus & CraftActivityDayStatus Tests

    func testStreakDayStatusCasesAndRawValues() {
        XCTAssertEqual(CraftStreakDayStatus.allCases, [.completed, .pending, .frozen, .missed, .upcoming])
        XCTAssertEqual(CraftStreakDayStatus.completed.rawValue, "completed")
        XCTAssertEqual(CraftStreakDayStatus.pending.rawValue, "pending")
        XCTAssertEqual(CraftStreakDayStatus.frozen.rawValue, "frozen")
        XCTAssertEqual(CraftStreakDayStatus.missed.rawValue, "missed")
        XCTAssertEqual(CraftStreakDayStatus.upcoming.rawValue, "upcoming")
    }

    func testActivityDayStatusCasesAndRawValues() {
        XCTAssertEqual(CraftActivityDayStatus.allCases, [.completed, .pending, .saved, .missed, .upcoming])
        XCTAssertEqual(CraftActivityDayStatus.completed.rawValue, "completed")
        XCTAssertEqual(CraftActivityDayStatus.pending.rawValue, "pending")
        XCTAssertEqual(CraftActivityDayStatus.saved.rawValue, "saved")
        XCTAssertEqual(CraftActivityDayStatus.missed.rawValue, "missed")
        XCTAssertEqual(CraftActivityDayStatus.upcoming.rawValue, "upcoming")
    }

    // MARK: - CraftStreakDay & CraftActivityDay Tests

    func testStreakDayInitialization() {
        let day1 = CraftStreakDay(id: "2026-08-23", weekdaySymbol: "T2", status: .completed, isToday: true)
        XCTAssertEqual(day1.id, "2026-08-23")
        XCTAssertEqual(day1.weekdaySymbol, "T2")
        XCTAssertEqual(day1.status, .completed)
        XCTAssertTrue(day1.isToday)

        let day2 = CraftStreakDay(id: "2026-08-24", weekdaySymbol: "T3", status: .pending)
        XCTAssertEqual(day2.id, "2026-08-24")
        XCTAssertEqual(day2.weekdaySymbol, "T3")
        XCTAssertEqual(day2.status, .pending)
        XCTAssertFalse(day2.isToday)
    }

    func testStreakDayEquality() {
        let dayA = CraftStreakDay(id: "1", weekdaySymbol: "M", status: .completed, isToday: false)
        let dayB = CraftStreakDay(id: "1", weekdaySymbol: "M", status: .completed, isToday: false)
        let dayC = CraftStreakDay(id: "2", weekdaySymbol: "T", status: .completed, isToday: false)

        XCTAssertEqual(dayA, dayB)
        XCTAssertNotEqual(dayA, dayC)
    }

    func testActivityDayInitializationAndEquality() {
        let day1 = CraftActivityDay(id: "d1", weekdaySymbol: "Mon", status: .completed, isToday: true)
        let day2 = CraftActivityDay(id: "d1", weekdaySymbol: "Mon", status: .completed, isToday: true)
        let day3 = CraftActivityDay(id: "d2", weekdaySymbol: "Tue", status: .saved)

        XCTAssertEqual(day1, day2)
        XCTAssertNotEqual(day1, day3)
        XCTAssertEqual(day1.id, "d1")
        XCTAssertEqual(day1.weekdaySymbol, "Mon")
        XCTAssertEqual(day1.status, .completed)
        XCTAssertTrue(day1.isToday)
    }

    // MARK: - CraftStreakData & CraftActivityTrackerData Tests

    func testMilestoneProgressCalculation() {
        let streakData = CraftStreakData(
            currentStreak: 14,
            bestStreak: 20,
            nextMilestoneDays: 20
        )
        XCTAssertEqual(streakData.milestoneProgress, 0.7, accuracy: 0.001)
        XCTAssertEqual(streakData.tier, .blaze)
    }

    func testMilestoneProgressClampingAndEdgeCases() {
        // Exceeds milestone -> clamped to 1.0
        let overCompleted = CraftStreakData(
            currentStreak: 25,
            bestStreak: 25,
            nextMilestoneDays: 20
        )
        XCTAssertEqual(overCompleted.milestoneProgress, 1.0, accuracy: 0.001)

        // Zero milestone days -> fallback to 1.0
        let zeroMilestone = CraftStreakData(
            currentStreak: 5,
            bestStreak: 5,
            nextMilestoneDays: 0
        )
        XCTAssertEqual(zeroMilestone.milestoneProgress, 1.0, accuracy: 0.001)

        // Negative current streak -> clamped to 0.0
        let negativeStreak = CraftStreakData(
            currentStreak: -1,
            bestStreak: 0,
            nextMilestoneDays: 20
        )
        XCTAssertEqual(negativeStreak.milestoneProgress, 0.0, accuracy: 0.001)
    }

    func testStreakDataDefaultValues() {
        let streakData = CraftStreakData(
            currentStreak: 3,
            bestStreak: 5
        )
        XCTAssertEqual(streakData.currentStreak, 3)
        XCTAssertEqual(streakData.bestStreak, 5)
        XCTAssertEqual(streakData.freezeTokens, 2)
        XCTAssertEqual(streakData.maxFreezeTokens, 3)
        XCTAssertEqual(streakData.nextMilestoneDays, 21)
        XCTAssertFalse(streakData.isCompletedToday)
        XCTAssertEqual(streakData.weekDays, [])
        XCTAssertNil(streakData.subtitle)
        XCTAssertEqual(streakData.tier, .starter)
    }

    func testStreakDataCustomValues() {
        let mockDays: [CraftStreakDay] = [
            .init(id: "1", weekdaySymbol: "T2", status: .completed),
            .init(id: "2", weekdaySymbol: "T3", status: .pending, isToday: true)
        ]
        let streakData = CraftStreakData(
            currentStreak: 35,
            bestStreak: 40,
            freezeTokens: 1,
            maxFreezeTokens: 4,
            nextMilestoneDays: 50,
            isCompletedToday: true,
            weekDays: mockDays,
            subtitle: "35-day streak!"
        )
        XCTAssertEqual(streakData.currentStreak, 35)
        XCTAssertEqual(streakData.bestStreak, 40)
        XCTAssertEqual(streakData.freezeTokens, 1)
        XCTAssertEqual(streakData.maxFreezeTokens, 4)
        XCTAssertEqual(streakData.nextMilestoneDays, 50)
        XCTAssertTrue(streakData.isCompletedToday)
        XCTAssertEqual(streakData.weekDays, mockDays)
        XCTAssertEqual(streakData.subtitle, "35-day streak!")
        XCTAssertEqual(streakData.tier, .legendary)
    }

    func testStreakDataEquality() {
        let data1 = CraftStreakData(currentStreak: 7, bestStreak: 10)
        let data2 = CraftStreakData(currentStreak: 7, bestStreak: 10)
        let data3 = CraftStreakData(currentStreak: 8, bestStreak: 10)

        XCTAssertEqual(data1, data2)
        XCTAssertNotEqual(data1, data3)
    }

    func testActivityTrackerDataDefaultsAndCustomValues() {
        let defaultData = CraftActivityTrackerData(
            currentValue: 5,
            bestRecord: 10
        )
        XCTAssertEqual(defaultData.currentValue, 5)
        XCTAssertEqual(defaultData.bestRecord, 10)
        XCTAssertNil(defaultData.unitKey)
        XCTAssertEqual(defaultData.unit, "days")
        XCTAssertEqual(defaultData.tier, .starter)
        XCTAssertEqual(defaultData.shieldTokens, 2)
        XCTAssertEqual(defaultData.maxShieldTokens, 3)
        XCTAssertEqual(defaultData.nextMilestone, 21)
        XCTAssertFalse(defaultData.isCompletedToday)
        XCTAssertEqual(defaultData.cycleDays, [])
        XCTAssertNil(defaultData.subtitle)
        XCTAssertEqual(defaultData.milestoneProgress, 5.0 / 21.0, accuracy: 0.001)

        let customData = CraftActivityTrackerData(
            currentValue: 30,
            bestRecord: 30,
            unitKey: "custom.unit",
            unit: "hours",
            tier: .legendary,
            shieldTokens: 3,
            maxShieldTokens: 5,
            nextMilestone: 50,
            isCompletedToday: true,
            cycleDays: [CraftActivityDay(id: "1", weekdaySymbol: "Mon", status: .completed)],
            subtitle: "30-hour milestone"
        )
        XCTAssertEqual(customData.currentValue, 30)
        XCTAssertEqual(customData.unitKey, "custom.unit")
        XCTAssertEqual(customData.unit, "hours")
        XCTAssertEqual(customData.tier, .legendary)
        XCTAssertEqual(customData.shieldTokens, 3)
        XCTAssertEqual(customData.maxShieldTokens, 5)
        XCTAssertEqual(customData.nextMilestone, 50)
        XCTAssertTrue(customData.isCompletedToday)
        XCTAssertEqual(customData.cycleDays.count, 1)
        XCTAssertEqual(customData.subtitle, "30-hour milestone")
        XCTAssertEqual(customData.milestoneProgress, 0.6, accuracy: 0.001)
    }

    // MARK: - Conversions Between Streak & Activity Models

    func testStreakStatusToActivityStatusConversion() {
        XCTAssertEqual(CraftStreakDayStatus.completed.asActivityStatus, .completed)
        XCTAssertEqual(CraftStreakDayStatus.pending.asActivityStatus, .pending)
        XCTAssertEqual(CraftStreakDayStatus.frozen.asActivityStatus, .saved)
        XCTAssertEqual(CraftStreakDayStatus.missed.asActivityStatus, .missed)
        XCTAssertEqual(CraftStreakDayStatus.upcoming.asActivityStatus, .upcoming)

        XCTAssertEqual(CraftStreakDayStatus(activityStatus: .completed), .completed)
        XCTAssertEqual(CraftStreakDayStatus(activityStatus: .pending), .pending)
        XCTAssertEqual(CraftStreakDayStatus(activityStatus: .saved), .frozen)
        XCTAssertEqual(CraftStreakDayStatus(activityStatus: .missed), .missed)
        XCTAssertEqual(CraftStreakDayStatus(activityStatus: .upcoming), .upcoming)
    }

    func testStreakDayToActivityDayConversion() {
        let streakDay = CraftStreakDay(id: "sd1", weekdaySymbol: "T2", status: .frozen, isToday: true)
        let activityDay = streakDay.asActivityDay

        XCTAssertEqual(activityDay.id, "sd1")
        XCTAssertEqual(activityDay.weekdaySymbol, "T2")
        XCTAssertEqual(activityDay.status, .saved)
        XCTAssertTrue(activityDay.isToday)

        let convertedBack = CraftStreakDay(activityDay: activityDay)
        XCTAssertEqual(convertedBack, streakDay)
    }

    func testStreakDataToActivityTrackerDataConversion() {
        let streakData = CraftStreakData(
            currentStreak: 15,
            bestStreak: 25,
            freezeTokens: 2,
            maxFreezeTokens: 3,
            nextMilestoneDays: 30,
            isCompletedToday: true,
            weekDays: [
                CraftStreakDay(id: "1", weekdaySymbol: "T2", status: .completed),
                CraftStreakDay(id: "2", weekdaySymbol: "T3", status: .frozen)
            ],
            subtitle: "Halfway there!"
        )

        let activityData = streakData.asActivityTrackerData
        XCTAssertEqual(activityData.currentValue, 15)
        XCTAssertEqual(activityData.bestRecord, 25)
        XCTAssertEqual(activityData.shieldTokens, 2)
        XCTAssertEqual(activityData.maxShieldTokens, 3)
        XCTAssertEqual(activityData.nextMilestone, 30)
        XCTAssertTrue(activityData.isCompletedToday)
        XCTAssertEqual(activityData.cycleDays.count, 2)
        XCTAssertEqual(activityData.cycleDays[0].status, .completed)
        XCTAssertEqual(activityData.cycleDays[1].status, .saved)
        XCTAssertEqual(activityData.subtitle, "Halfway there!")
        XCTAssertEqual(activityData.milestoneProgress, 0.5, accuracy: 0.001)
    }

    func testStreakDataAsActivityTrackerDataLocalization() {
        let streakData = CraftStreakData(
            currentStreak: 5,
            bestStreak: 10,
            freezeTokens: 1,
            maxFreezeTokens: 2,
            nextMilestoneDays: 7,
            isCompletedToday: true,
            weekDays: []
        )
        let activity = streakData.asActivityTrackerData
        XCTAssertEqual(activity.unitKey, "craft.common.unit.days_single")
        XCTAssertEqual(activity.unit, CraftLocalized.string("craft.common.unit.days_single"))
    }
}
