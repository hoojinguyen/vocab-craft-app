import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

#if canImport(SwiftDataMacros) || canImport(SwiftData)
@MainActor
public final class SRSRepositoryImpl: SRSRepositoryProtocol {
    private let modelContext: ModelContext?
    private let practiceRepository: (any PracticeRepositoryProtocol)?

    public init(
        modelContext: ModelContext? = nil,
        practiceRepository: (any PracticeRepositoryProtocol)? = nil
    ) {
        self.modelContext = modelContext
        self.practiceRepository = practiceRepository
    }

    public func getProgress(wordId: Int64) async throws -> SRSProgressItem? {
        guard let context = modelContext else { return nil }
        var fetchDescriptor = FetchDescriptor<UserWordProgress>(
            predicate: #Predicate { $0.wordId == wordId }
        )
        fetchDescriptor.fetchLimit = 1
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
        var fetchDescriptor = FetchDescriptor<UserWordProgress>(
            predicate: #Predicate { $0.wordId == targetId }
        )
        fetchDescriptor.fetchLimit = 1
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

    public func resetAllProgress() async throws {
        if let practiceRepository {
            try await practiceRepository.resetAllLearningProgress()
            return
        }
        guard let context = modelContext else { return }
        try context.delete(model: UserWordProgress.self)
        try context.delete(model: ReflexSessionLog.self)
        try context.delete(model: QuickReflexAttemptRecord.self)
        try context.save()
    }
}
#else
@MainActor
public final class SRSRepositoryImpl: SRSRepositoryProtocol {
    private var records: [Int64: SRSProgressItem] = [:]
    private let practiceRepository: (any PracticeRepositoryProtocol)?

    public init(
        modelContext: Any? = nil,
        practiceRepository: (any PracticeRepositoryProtocol)? = nil
    ) {
        self.practiceRepository = practiceRepository
    }

    public func getProgress(wordId: Int64) async throws -> SRSProgressItem? {
        records[wordId]
    }

    public func saveProgress(_ item: SRSProgressItem) async throws {
        records[item.wordId] = item
    }

    public func logReflexSession(drillId: Int64, responseTimeMs: Int, accuracyScore: Double) async throws {}

    public func resetAllProgress() async throws {
        if let practiceRepository {
            try await practiceRepository.resetAllLearningProgress()
        }
        records.removeAll()
    }
}
#endif
