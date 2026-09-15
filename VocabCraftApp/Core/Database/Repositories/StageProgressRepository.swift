import Foundation
import SwiftData

@MainActor
public protocol StageProgressRepositoryProtocol: Sendable {
    func fetchStageProgress(stageId: String) async throws -> UserStageProgressData?
    func fetchCompletedStageIds(deckId: String) async throws -> Set<String>
    func fetchAllStageProgress() async throws -> [UserStageProgressData]
    func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int, progressFraction: Double) async throws
    func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int) async throws
}

extension StageProgressRepositoryProtocol {
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

#if canImport(SwiftDataMacros) || canImport(SwiftData)
@MainActor
public final class StageProgressRepositoryImpl: StageProgressRepositoryProtocol {
    private let modelContext: ModelContext?

    public init(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }

    public func fetchStageProgress(stageId: String) async throws -> UserStageProgressData? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserStageProgress>(
            predicate: #Predicate { $0.stageId == stageId }
        )
        return try context.fetch(descriptor).first?.toData()
    }

    public func fetchCompletedStageIds(deckId: String) async throws -> Set<String> {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<UserStageProgress>(
            predicate: #Predicate { $0.deckId == deckId && $0.isCompleted }
        )
        let list = try context.fetch(descriptor)
        return Set(list.map(\.stageId))
    }

    public func fetchAllStageProgress() async throws -> [UserStageProgressData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<UserStageProgress>()
        return try context.fetch(descriptor).map { $0.toData() }
    }

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
@MainActor
public final class StageProgressRepositoryImpl: StageProgressRepositoryProtocol {
    private var records: [String: UserStageProgressData] = [:]

    public init(modelContext: Any? = nil) {}

    public func fetchStageProgress(stageId: String) async throws -> UserStageProgressData? {
        records[stageId]
    }

    public func fetchCompletedStageIds(deckId: String) async throws -> Set<String> {
        Set(records.values.filter { $0.deckId == deckId && $0.isCompleted }.map(\.stageId))
    }

    public func fetchAllStageProgress() async throws -> [UserStageProgressData] {
        Array(records.values)
    }

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

@MainActor
public final class MockStageProgressRepository: StageProgressRepositoryProtocol {
    private var records: [String: UserStageProgressData] = [:]
    public private(set) var saveCallCount: Int = 0
    public var delayNanoseconds: UInt64 = 0

    public init(records: [String: UserStageProgressData] = [:]) {
        self.records = records
    }

    public func fetchStageProgress(stageId: String) async throws -> UserStageProgressData? {
        records[stageId]
    }

    public func fetchCompletedStageIds(deckId: String) async throws -> Set<String> {
        let completed = records.values.filter { $0.deckId == deckId && $0.isCompleted }
        return Set(completed.map(\.stageId))
    }

    public func fetchAllStageProgress() async throws -> [UserStageProgressData] {
        Array(records.values)
    }

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
