import Foundation
import SwiftUI

// MARK: - CraftStreakTier

/// Visual and progression tier of the Streak system.
public enum CraftStreakTier: String, Sendable, CaseIterable, Equatable {
    case starter   // 0 - 6 days (Warm Coral / Base)
    case blaze     // 7 - 29 days (Blazing Flame / Gold)
    case legendary // 30+ days (Legendary Aura / Multicolored)

    /// Evaluates the streak tier based on consecutive days count.
    ///
    /// - Parameter days: Number of consecutive streak days.
    /// - Returns: Corresponding `CraftStreakTier`.
    public static func tier(for days: Int) -> CraftStreakTier {
        switch days {
        case ..<7:
            return .starter
        case 7...29:
            return .blaze
        default:
            return .legendary
        }
    }
}

// MARK: - CraftStreakDayStatus

/// Presentation status for an individual day within the 7-day streak track.
public enum CraftStreakDayStatus: String, Sendable, CaseIterable, Equatable {
    case completed // Daily learning goal achieved
    case pending   // Pending completion for today
    case frozen    // Streak protected by a freeze shield
    case missed    // Day elapsed without meeting the goal
    case upcoming  // Future day in the weekly cycle
}

// MARK: - CraftStreakDay

/// Presentation DTO representing a single day in the weekly streak view.
public struct CraftStreakDay: Identifiable, Sendable, Equatable {
    public let id: String
    public let weekdaySymbol: String
    public let status: CraftStreakDayStatus
    public let isToday: Bool

    public init(
        id: String,
        weekdaySymbol: String,
        status: CraftStreakDayStatus,
        isToday: Bool = false
    ) {
        self.id = id
        self.weekdaySymbol = weekdaySymbol
        self.status = status
        self.isToday = isToday
    }
}

// MARK: - CraftStreakData

/// Presentation DTO aggregating streak status for UI consumption across widgets, cards, and badges.
public struct CraftStreakData: Sendable, Equatable {
    public let currentStreak: Int
    public let bestStreak: Int
    public let freezeTokens: Int
    public let maxFreezeTokens: Int
    public let nextMilestoneDays: Int
    public let isCompletedToday: Bool
    public let weekDays: [CraftStreakDay]
    public let subtitle: String?

    /// Computed visual tier based on current streak count.
    public var tier: CraftStreakTier {
        CraftStreakTier.tier(for: currentStreak)
    }

    /// Normalized milestone progress [0.0, 1.0].
    public var milestoneProgress: Double {
        guard nextMilestoneDays > 0 else { return 1.0 }
        let progress = Double(currentStreak) / Double(nextMilestoneDays)
        return min(max(progress, 0.0), 1.0)
    }

    public init(
        currentStreak: Int,
        bestStreak: Int,
        freezeTokens: Int = 2,
        maxFreezeTokens: Int = 3,
        nextMilestoneDays: Int = 21,
        isCompletedToday: Bool = false,
        weekDays: [CraftStreakDay] = [],
        subtitle: String? = nil
    ) {
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.freezeTokens = freezeTokens
        self.maxFreezeTokens = maxFreezeTokens
        self.nextMilestoneDays = nextMilestoneDays
        self.isCompletedToday = isCompletedToday
        self.weekDays = weekDays
        self.subtitle = subtitle
    }
}
