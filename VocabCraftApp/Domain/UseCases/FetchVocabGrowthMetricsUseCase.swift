import Foundation

/// Metric models and protocol for calculating vocabulary growth index (VGI) and retention analytics.
public protocol FetchVocabGrowthMetricsUseCaseProtocol: Sendable {
    func execute() async throws -> VocabGrowthSnapshot
    func execute(at date: Date) async throws -> VocabGrowthSnapshot
}

public extension FetchVocabGrowthMetricsUseCaseProtocol {
    func execute() async throws -> VocabGrowthSnapshot {
        try await execute(at: Date())
    }
}

/// Statistics and target benchmark progress for a specific CEFR proficiency level.
public struct CEFRLevelStat: Sendable, Equatable, Identifiable {
    public var id: String { cefrLevel }
    public let cefrLevel: String
    public let acquiredCount: Int
    public let targetStandardCount: Int

    public var masteryPercentage: Double {
        guard targetStandardCount > 0 else { return 0.0 }
        return min(1.0, Double(acquiredCount) / Double(targetStandardCount))
    }

    public init(
        cefrLevel: String,
        acquiredCount: Int,
        targetStandardCount: Int
    ) {
        self.cefrLevel = cefrLevel
        self.acquiredCount = acquiredCount
        self.targetStandardCount = targetStandardCount
    }
}

/// Consolidated snapshot of user vocabulary metrics across CEFR levels and depth tiers.
public struct VocabGrowthSnapshot: Sendable, Equatable {
    public let totalWordsAcquired: Int
    public let masteredWordsCount: Int
    public let consolidatingWordsCount: Int
    public let newWordsCount: Int
    public let estimatedRetentionRate: Double
    public let cefrDistribution: [CEFRLevelStat]

    public init(
        totalWordsAcquired: Int,
        masteredWordsCount: Int,
        consolidatingWordsCount: Int,
        newWordsCount: Int,
        estimatedRetentionRate: Double,
        cefrDistribution: [CEFRLevelStat]
    ) {
        self.totalWordsAcquired = totalWordsAcquired
        self.masteredWordsCount = masteredWordsCount
        self.consolidatingWordsCount = consolidatingWordsCount
        self.newWordsCount = newWordsCount
        self.estimatedRetentionRate = estimatedRetentionRate
        self.cefrDistribution = cefrDistribution
    }
}

/// Use case calculating vocabulary growth metrics, CEFR ladder distributions,
/// and Ebbinghaus memory retention decay curves across user progress records.
public final class FetchVocabGrowthMetricsUseCase: FetchVocabGrowthMetricsUseCaseProtocol, Sendable {
    public static let standardCEFRLevels: [String] = ["A1", "A2", "B1", "B2", "C1", "C2"]
    public static let standardTargetCounts: [String: Int] = [
        "A1": 500,
        "A2": 600,
        "B1": 800,
        "B2": 1000,
        "C1": 1200,
        "C2": 1500
    ]

    private let progressRepo: any UserProgressRepositoryProtocol
    private let dataSource: VocabularyDataSourceProtocol?

    public init(
        progressRepo: any UserProgressRepositoryProtocol,
        dataSource: VocabularyDataSourceProtocol? = nil
    ) {
        self.progressRepo = progressRepo
        self.dataSource = dataSource
    }

    public func execute(at now: Date) async throws -> VocabGrowthSnapshot {
        let allProgress = try await progressRepo.fetchAllProgress()

        guard !allProgress.isEmpty else {
            let emptyDistribution = Self.standardCEFRLevels.map { level in
                CEFRLevelStat(
                    cefrLevel: level,
                    acquiredCount: 0,
                    targetStandardCount: Self.standardTargetCounts[level] ?? 500
                )
            }
            return VocabGrowthSnapshot(
                totalWordsAcquired: 0,
                masteredWordsCount: 0,
                consolidatingWordsCount: 0,
                newWordsCount: 0,
                estimatedRetentionRate: 1.0,
                cefrDistribution: emptyDistribution
            )
        }

        // Depth tiers: Level 1: Encountered, Level 2-3: Consolidating, Level 4-5: Mastered
        let masteredWordsCount = allProgress.filter { $0.masteryLevel >= 4 }.count
        let consolidatingWordsCount = allProgress.filter { (2...3).contains($0.masteryLevel) }.count
        let newWordsCount = allProgress.filter { $0.masteryLevel <= 1 }.count
        let totalWordsAcquired = allProgress.count

        // Group by CEFR level
        var cefrCounts: [String: Int] = [:]
        for progress in allProgress {
            let normalizedLevel = progress.cefrLevel.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let levelKey = Self.standardCEFRLevels.contains(normalizedLevel) ? normalizedLevel : "A1"
            cefrCounts[levelKey, default: 0] += 1
        }

        let cefrDistribution = Self.standardCEFRLevels.map { level in
            CEFRLevelStat(
                cefrLevel: level,
                acquiredCount: cefrCounts[level] ?? 0,
                targetStandardCount: Self.standardTargetCounts[level] ?? 500
            )
        }

        // Retention Decay Model: R = (1/N) * sum(e^(-max(0, t)/S))
        // t_i: days elapsed since lastReviewDate
        // S_i: intervalDays * (easeFactor / 2.5)
        var totalRetentionSum: Double = 0.0
        for progress in allProgress {
            let elapsedSeconds = max(0.0, now.timeIntervalSince(progress.lastReviewDate))
            let tDays = elapsedSeconds / 86400.0

            let easeFactor = max(1.3, progress.easeFactor)
            let intervalDays = max(1, progress.intervalDays)
            let sStability = max(1.0, Double(intervalDays) * (easeFactor / 2.5))

            let wordRetention = exp(-tDays / sStability)
            totalRetentionSum += wordRetention
        }

        let rawRetention = totalRetentionSum / Double(allProgress.count)
        let estimatedRetentionRate = min(1.0, max(0.0, rawRetention))

        return VocabGrowthSnapshot(
            totalWordsAcquired: totalWordsAcquired,
            masteredWordsCount: masteredWordsCount,
            consolidatingWordsCount: consolidatingWordsCount,
            newWordsCount: newWordsCount,
            estimatedRetentionRate: estimatedRetentionRate,
            cefrDistribution: cefrDistribution
        )
    }
}
