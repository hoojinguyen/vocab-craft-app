import Foundation
import SwiftUI

// MARK: - CraftActivityTier

/// Visual and progression tier of the activity / streak system.
public enum CraftActivityTier: String, Sendable, CaseIterable, Equatable {
    case starter   // 0 - 6 units (Warm Coral / Base)
    case blaze     // 7 - 29 units (Blazing Flame / Gold)
    case legendary // 30+ units (Legendary Aura / Multicolored)

    /// Evaluates the activity tier based on consecutive days / units count.
    ///
    /// - Parameter value: Number of consecutive activity units or days.
    /// - Returns: Corresponding `CraftActivityTier`.
    public static func tier(for value: Int) -> CraftActivityTier {
        switch value {
        case ..<7:
            return .starter
        case 7...29:
            return .blaze
        default:
            return .legendary
        }
    }
}

// MARK: - CraftActivityDayStatus

/// Presentation status for an individual day within an activity tracker cycle.
public enum CraftActivityDayStatus: String, Sendable, CaseIterable, Equatable {
    case completed // Daily goal achieved
    case pending   // Pending completion for today
    case saved     // Protected by freeze shield / token
    case missed    // Day elapsed without meeting the goal
    case upcoming  // Future day in the cycle
}

// MARK: - CraftActivityDay

/// Presentation DTO representing a single day in the weekly activity cycle.
public struct CraftActivityDay: Identifiable, Sendable, Equatable {
    public let id: String
    public let weekdaySymbol: String
    public let status: CraftActivityDayStatus
    public let isToday: Bool

    public init(
        id: String,
        weekdaySymbol: String,
        status: CraftActivityDayStatus,
        isToday: Bool = false
    ) {
        self.id = id
        self.weekdaySymbol = weekdaySymbol
        self.status = status
        self.isToday = isToday
    }
}

// MARK: - CraftActivityTrackerData

/// Universal presentation DTO aggregating activity, habit, and streak status across dashboard widgets and cards.
public struct CraftActivityTrackerData: Sendable, Equatable {
    public let currentValue: Int
    public let bestRecord: Int
    public let unitKey: String?
    public let unit: String
    public let tier: CraftActivityTier
    public let shieldTokens: Int
    public let maxShieldTokens: Int
    public let nextMilestone: Int
    public let isCompletedToday: Bool
    public let cycleDays: [CraftActivityDay]
    public let subtitle: String?

    /// Normalized milestone progress [0.0, 1.0].
    public var milestoneProgress: Double {
        guard nextMilestone > 0 else { return 1.0 }
        let progress = Double(currentValue) / Double(nextMilestone)
        return min(max(progress, 0.0), 1.0)
    }

    public init(
        currentValue: Int,
        bestRecord: Int,
        unitKey: String? = nil,
        unit: String = "days",
        tier: CraftActivityTier? = nil,
        shieldTokens: Int = 2,
        maxShieldTokens: Int = 3,
        nextMilestone: Int = 21,
        isCompletedToday: Bool = false,
        cycleDays: [CraftActivityDay] = [],
        subtitle: String? = nil
    ) {
        self.currentValue = currentValue
        self.bestRecord = bestRecord
        self.unitKey = unitKey
        self.unit = unit
        self.tier = tier ?? CraftActivityTier.tier(for: currentValue)
        self.shieldTokens = shieldTokens
        self.maxShieldTokens = maxShieldTokens
        self.nextMilestone = nextMilestone
        self.isCompletedToday = isCompletedToday
        self.cycleDays = cycleDays
        self.subtitle = subtitle
    }
}
