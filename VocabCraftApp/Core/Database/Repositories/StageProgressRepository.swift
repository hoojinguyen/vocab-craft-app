import Foundation
import SwiftData

public protocol StageProgressRepositoryProtocol: Sendable {
    @MainActor func fetchStageProgress(stageId: String) async throws -> UserStageProgress?
    @MainActor func fetchCompletedStageIds(deckId: String) async throws -> Set<String>
    @MainActor func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int) async throws
}

public final class StageProgressRepositoryImpl: StageProgressRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext?

    public init(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }

    @MainActor
    public func fetchStageProgress(stageId: String) async throws -> UserStageProgress? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserStageProgress>(
            predicate: #Predicate { $0.stageId == stageId }
        )
        return try context.fetch(descriptor).first
    }

    @MainActor
    public func fetchCompletedStageIds(deckId: String) async throws -> Set<String> {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<UserStageProgress>(
            predicate: #Predicate { $0.deckId == deckId && $0.isCompleted }
        )
        let list = try context.fetch(descriptor)
        return Set(list.map(\.stageId))
    }

    @MainActor
    public func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int) async throws {
        guard let context = modelContext else { return }
        if let existing = try await fetchStageProgress(stageId: stageId) {
            existing.isCompleted = isCompleted
            existing.score = score
            existing.completedAt = Date()
        } else {
            let record = UserStageProgress(stageId: stageId, deckId: deckId, isCompleted: isCompleted, score: score, completedAt: Date())
            context.insert(record)
        }
        try context.save()
    }
}
