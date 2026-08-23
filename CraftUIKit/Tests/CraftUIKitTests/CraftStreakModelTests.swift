import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftStreakModelTests: XCTestCase {
    // MARK: - CraftStreakTier Tests

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

    // MARK: - CraftStreakDayStatus Tests

    func testStreakDayStatusCasesAndRawValues() {
        XCTAssertEqual(CraftStreakDayStatus.allCases, [.completed, .pending, .frozen, .missed, .upcoming])
        XCTAssertEqual(CraftStreakDayStatus.completed.rawValue, "completed")
        XCTAssertEqual(CraftStreakDayStatus.pending.rawValue, "pending")
        XCTAssertEqual(CraftStreakDayStatus.frozen.rawValue, "frozen")
        XCTAssertEqual(CraftStreakDayStatus.missed.rawValue, "missed")
        XCTAssertEqual(CraftStreakDayStatus.upcoming.rawValue, "upcoming")
    }

    // MARK: - CraftStreakDay Tests

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

    // MARK: - CraftStreakData Tests

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
}
