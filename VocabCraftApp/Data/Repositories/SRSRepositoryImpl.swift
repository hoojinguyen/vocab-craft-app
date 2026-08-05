import Foundation
import SwiftData

@MainActor
public final class SRSRepositoryImpl: SRSRepositoryProtocol {
    private let modelContext: ModelContext?

    public init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    public func getProgress(wordId: Int64) async throws -> SRSProgressItem? {
        guard let context = modelContext else { return nil }
        let fetchDescriptor = FetchDescriptor<UserWordProgress>(
            predicate: #Predicate { $0.wordId == wordId }
        )
        let results = try context.fetch(fetchDescriptor)
        guard let entity = results.first else { return nil }
        return SRSProgressItem(
            wordId: entity.wordId,
            masteryLevel: entity.masteryLevel,
            easeFactor: entity.easeFactor,
            intervalDays: entity.intervalDays,
            nextReviewDate: entity.nextReviewDate,
            lastReviewDate: entity.lastReviewDate,
            totalReviews: entity.totalReviews
        )
    }

    public func saveProgress(_ item: SRSProgressItem) async throws {
        guard let context = modelContext else { return }
        let targetId = item.wordId
        let fetchDescriptor = FetchDescriptor<UserWordProgress>(
            predicate: #Predicate { $0.wordId == targetId }
        )
        let results = try context.fetch(fetchDescriptor)

        if let existing = results.first {
            existing.masteryLevel = item.masteryLevel
            existing.easeFactor = item.easeFactor
            existing.intervalDays = item.intervalDays
            existing.nextReviewDate = item.nextReviewDate
            existing.lastReviewDate = item.lastReviewDate
            existing.totalReviews = item.totalReviews
        } else {
            let newEntity = UserWordProgress(
                wordId: item.wordId,
                masteryLevel: item.masteryLevel,
                easeFactor: item.easeFactor,
                intervalDays: item.intervalDays,
                nextReviewDate: item.nextReviewDate,
                lastReviewDate: item.lastReviewDate,
                totalReviews: item.totalReviews
            )
            context.insert(newEntity)
        }
        try context.save()
    }

    public func logReflexSession(drillId: Int64, responseTimeMs: Int, accuracyScore: Double) async throws {
        guard let context = modelContext else { return }
        let log = ReflexSessionLog(
            drillId: drillId,
            responseTimeMs: responseTimeMs,
            accuracyScore: accuracyScore,
            timestamp: Date()
        )
        context.insert(log)
        try context.save()
    }
}
