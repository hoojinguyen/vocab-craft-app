import Foundation
import SwiftData

public protocol StageProgressRepositoryProtocol: Sendable {
    @MainActor func fetchStageProgress(stageId: String) async throws -> UserStageProgressData?
    @MainActor func fetchCompletedStageIds(deckId: String) async throws -> Set<String>
    @MainActor func fetchAllStageProgress() async throws -> [UserStageProgressData]
    @MainActor func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int, progressFraction: Double) async throws
    @MainActor func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int) async throws
}

extension StageProgressRepositoryProtocol {
    @MainActor
    public func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int) async throws {
        try await saveStageProgress(
            stageId: stageId,
            deckId: deckId,
            isCompleted: isCompleted,
            score: score,
            progressFraction: isCompleted ? 1.0 : 0.0
        )
    }
}

#if canImport(SwiftDataMacros)
public final class StageProgressRepositoryImpl: StageProgressRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext?

    public init(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }

    @MainActor
    public func fetchStageProgress(stageId: String) async throws -> UserStageProgressData? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserStageProgress>(
            predicate: #Predicate { $0.stageId == stageId }
        )
        return try context.fetch(descriptor).first?.toData()
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
    public func fetchAllStageProgress() async throws -> [UserStageProgressData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<UserStageProgress>()
        return try context.fetch(descriptor).map { $0.toData() }
    }

    @MainActor
    public func saveStageProgress(
        stageId: String,
        deckId: String,
        isCompleted: Bool,
        score: Int,
        progressFraction: Double
    ) async throws {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<UserStageProgress>(
            predicate: #Predicate { $0.stageId == stageId }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.isCompleted = isCompleted
            existing.score = score
            existing.progressFraction = progressFraction
            existing.completedAt = Date()
        } else {
            let record = UserStageProgress(
                stageId: stageId,
                deckId: deckId,
                isCompleted: isCompleted,
                score: score,
                progressFraction: progressFraction,
                completedAt: Date()
            )
            context.insert(record)
        }
        try context.save()
    }
}
#else
public final class StageProgressRepositoryImpl: StageProgressRepositoryProtocol, @unchecked Sendable {
    private var records: [String: UserStageProgressData] = [:]

    public init(modelContext: Any? = nil) {}

    @MainActor
    public func fetchStageProgress(stageId: String) async throws -> UserStageProgressData? {
        records[stageId]
    }

    @MainActor
    public func fetchCompletedStageIds(deckId: String) async throws -> Set<String> {
        Set(records.values.filter { $0.deckId == deckId && $0.isCompleted }.map(\.stageId))
    }

    @MainActor
    public func fetchAllStageProgress() async throws -> [UserStageProgressData] {
        Array(records.values)
    }

    @MainActor
    public func saveStageProgress(
        stageId: String,
        deckId: String,
        isCompleted: Bool,
        score: Int,
        progressFraction: Double
    ) async throws {
        let record = UserStageProgressData(
            stageId: stageId,
            deckId: deckId,
            isCompleted: isCompleted,
            score: score,
            progressFraction: progressFraction,
            completedAt: Date()
        )
        records[stageId] = record
    }
}
#endif

public final class MockStageProgressRepository: StageProgressRepositoryProtocol, @unchecked Sendable {
    private var records: [String: UserStageProgressData] = [:]
    @MainActor public private(set) var saveCallCount: Int = 0
    public var delayNanoseconds: UInt64 = 0

    public init(records: [String: UserStageProgressData] = [:]) {
        self.records = records
    }

    @MainActor
    public func fetchStageProgress(stageId: String) async throws -> UserStageProgressData? {
        records[stageId]
    }

    @MainActor
    public func fetchCompletedStageIds(deckId: String) async throws -> Set<String> {
        let completed = records.values.filter { $0.deckId == deckId && $0.isCompleted }
        return Set(completed.map(\.stageId))
    }

    @MainActor
    public func fetchAllStageProgress() async throws -> [UserStageProgressData] {
        Array(records.values)
    }

    @MainActor
    public func saveStageProgress(
        stageId: String,
        deckId: String,
        isCompleted: Bool,
        score: Int,
        progressFraction: Double
    ) async throws {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        saveCallCount += 1
        let record = UserStageProgressData(
            stageId: stageId,
            deckId: deckId,
            isCompleted: isCompleted,
            score: score,
            progressFraction: progressFraction,
            completedAt: Date()
        )
        records[stageId] = record
    }
}
