import Foundation
import SwiftData

extension UserWordProgress {
    public var practicedModes: Set<ReflexBlitzMode> {
        get {
            guard !practicedModesRaw.isEmpty else { return [] }
            let modes = practicedModesRaw.split(separator: ",").compactMap { ReflexBlitzMode(rawValue: String($0)) }
            return Set(modes)
        }
        set {
            practicedModesRaw = newValue.map(\.rawValue).sorted().joined(separator: ",")
        }
    }
}

public struct UserProgressSummary: Sendable, Equatable {
    public let masteryLevel: Int
    public let isBookmarked: Bool

    public init(masteryLevel: Int, isBookmarked: Bool) {
        self.masteryLevel = masteryLevel
        self.isBookmarked = isBookmarked
    }
}

public struct UserWordProgressData: Sendable, Equatable {
    public let wordId: Int64
    public let cefrLevel: String
    public let masteryLevel: Int
    public let isBookmarked: Bool
    public let easeFactor: Double
    public let intervalDays: Int
    public let nextReviewDate: Date
    public let lastReviewDate: Date
    public let totalReviews: Int
    public let needsReview: Bool
    public let mistakeCount: Int
    public let sourceDeckId: String?
    public let sourceNodeId: String?
    public let consecutiveCorrectStreak: Int
    public let practicedModes: Set<ReflexBlitzMode>
    public let isMastered: Bool
    public let modeStats: ModeSuccessStats

    public init(
        wordId: Int64,
        cefrLevel: String = "A1",
        masteryLevel: Int = 0,
        isBookmarked: Bool = false,
        easeFactor: Double = 2.5,
        intervalDays: Int = 1,
        nextReviewDate: Date = Date(),
        lastReviewDate: Date = Date(),
        totalReviews: Int = 0,
        needsReview: Bool = false,
        mistakeCount: Int = 0,
        sourceDeckId: String? = nil,
        sourceNodeId: String? = nil,
        consecutiveCorrectStreak: Int = 0,
        practicedModes: Set<ReflexBlitzMode> = [],
        isMastered: Bool = false,
        modeStats: ModeSuccessStats = ModeSuccessStats()
    ) {
        self.wordId = wordId
        self.cefrLevel = cefrLevel
        self.masteryLevel = masteryLevel
        self.isBookmarked = isBookmarked
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
        self.totalReviews = totalReviews
        self.needsReview = needsReview
        self.mistakeCount = mistakeCount
        self.sourceDeckId = sourceDeckId
        self.sourceNodeId = sourceNodeId
        self.consecutiveCorrectStreak = consecutiveCorrectStreak
        self.practicedModes = practicedModes
        self.isMastered = isMastered
        self.modeStats = modeStats
    }
}
