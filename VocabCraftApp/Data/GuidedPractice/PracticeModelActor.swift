import Foundation
#if canImport(SwiftDataMacros) || canImport(SwiftData)
import SwiftData

/// Persistent, transactional repository actor coordinating guided practice sessions,
/// turn evaluations, support exposures, and communication progress cache.
@ModelActor
public actor PracticeModelActor: PracticeRepositoryProtocol {
    let progressPolicy: CommunicationProgressPolicy = CommunicationProgressPolicy()

    // MARK: - Transaction Helper

    func performTransaction<T>(_ block: () throws -> T) throws -> T {
        do {
            let result = try block()
            try modelContext.save()
            return result
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    // MARK: - Internal Query Helpers

    func findSessionRecord(id: UUID) throws -> SchemaV3.PracticeSessionRecord? {
        var descriptor = FetchDescriptor<SchemaV3.PracticeSessionRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func findActiveSessionRecord() throws -> SchemaV3.PracticeSessionRecord? {
        let inProgressRaw = PracticeSessionStatus.inProgress.rawValue
        var descriptor = FetchDescriptor<SchemaV3.PracticeSessionRecord>(
            predicate: #Predicate { $0.statusRaw == inProgressRaw }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Progress & Evidence Queries

    public func progress() throws -> [CommunicationProgress] {
        let descriptor = FetchDescriptor<SchemaV3.CommunicationProgressRecord>()
        let records = try modelContext.fetch(descriptor)
        return try records.map { try PracticeRecordMapper.toDomain($0) }
    }

    public func evidence() throws -> [WordUseEvidence] {
        let descriptor = FetchDescriptor<SchemaV3.WordUseEvidenceRecord>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let records = try modelContext.fetch(descriptor)
        return try records.map { try PracticeRecordMapper.toDomain($0) }
    }

    // MARK: - Session Lifecycle

    public func activeSession() throws -> PracticeSessionSnapshot? {
        guard let record = try findActiveSessionRecord() else {
            return nil
        }
        return try loadSession(id: record.id)
    }

    public func loadSession(id: UUID) throws -> PracticeSessionSnapshot? {
        guard let sessionRecord = try findSessionRecord(id: id) else {
            return nil
        }
        let session = try PracticeRecordMapper.toDomain(sessionRecord)

        // Turns ordered by sequence
        let turnDesc = FetchDescriptor<SchemaV3.PracticeTurnRecord>(
            predicate: #Predicate { $0.sessionId == id },
            sortBy: [SortDescriptor(\.sequence)]
        )
        let turnRecords = try modelContext.fetch(turnDesc)
        let turns = try turnRecords.map { try PracticeRecordMapper.toDomain($0) }

        // Exposures ordered by presentedAt
        let expDesc = FetchDescriptor<SchemaV3.SupportExposureRecord>(
            predicate: #Predicate { $0.sessionId == id },
            sortBy: [SortDescriptor(\.presentedAt)]
        )
        let expRecords = try modelContext.fetch(expDesc)
        let exposures = try expRecords.map { try PracticeRecordMapper.toDomain($0) }

        // Evidence ordered by timestamp
        let evDesc = FetchDescriptor<SchemaV3.WordUseEvidenceRecord>(
            predicate: #Predicate { $0.sessionId == id },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let evRecords = try modelContext.fetch(evDesc)
        let evidence = try evRecords.map { try PracticeRecordMapper.toDomain($0) }

        // Pending presentation intents
        let pendingStatusRaw = PracticePresentationStatus.pending.rawValue
        let presDesc = FetchDescriptor<SchemaV3.PracticePresentationRecord>(
            predicate: #Predicate { $0.sessionId == id && $0.statusRaw == pendingStatusRaw }
        )
        let presRecords = try modelContext.fetch(presDesc)
        let pendingPresentations = try presRecords.map { try PracticeRecordMapper.toDomain($0) }

        // Progress for relevant words (session target words + evidence words)
        let targetWordIds = Set(session.missionSnapshot.targetWordIds).union(evidence.map(\.wordId))
        var progressList: [CommunicationProgress] = []
        for wordId in targetWordIds {
            let progDesc = FetchDescriptor<SchemaV3.CommunicationProgressRecord>(
                predicate: #Predicate { $0.wordId == wordId }
            )
            let progRecords = try modelContext.fetch(progDesc)
            for progressRecord in progRecords {
                progressList.append(try PracticeRecordMapper.toDomain(progressRecord))
            }
        }

        return PracticeSessionSnapshot(
            session: session,
            turns: turns,
            exposures: exposures,
            evidence: evidence,
            progress: progressList,
            pendingPresentations: pendingPresentations
        )
    }

    public func create(_ session: PracticeSession) throws {
        try performTransaction {
            if session.status == .inProgress {
                if let active = try findActiveSessionRecord() {
                    throw PracticeFailure(
                        code: .domainValidation,
                        message: "An active session already exists (\(active.id)). Only one active session is permitted."
                    )
                }
            }

            if let existing = try findSessionRecord(id: session.id) {
                throw PracticeFailure(
                    code: .domainValidation,
                    message: "Practice session with id \(existing.id) already exists."
                )
            }

            let record = try PracticeRecordMapper.toRecord(session)
            modelContext.insert(record)
        }
    }
}
#else
public actor PracticeModelActor: PracticeRepositoryProtocol {
    public init(modelContainer: Any? = nil) {}
    public func progress() async throws -> [CommunicationProgress] { [] }
    public func evidence() async throws -> [WordUseEvidence] { [] }
    public func activeSession() async throws -> PracticeSessionSnapshot? { nil }
    public func loadSession(id: UUID) async throws -> PracticeSessionSnapshot? { nil }
    public func create(_ session: PracticeSession) async throws {}
    public func savePendingTurn(_ turn: PracticeTurn, checkpoint: PracticeCheckpoint, expectedRevision: Int) async throws {}
    public func commit(_ value: PracticeCommit) async throws -> PracticeSessionSnapshot { PracticeFixtures.sessionSnapshot() }
    public func preparePresentation(_ intent: PracticePresentationIntent, expectedRevision: Int) async throws {}
    public func confirmPresentation(id: UUID, exposure: SupportExposure, expectedRevision: Int) async throws {}
    public func revise(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint) async throws -> Int { expectedRevision + 1 }
    public func finalize(sessionId: UUID, completion: PracticeCompletion, expectedRevision: Int) async throws -> PracticeSummary {
        PracticeSummary(sessionId: sessionId, status: .completed, objectiveResults: [], perWordProgress: [], evidenceIds: [], persisted: true)
    }
    public func deleteSession(id: UUID) async throws {}
    public func deleteAllPractice() async throws {}
    public func resetAllLearningProgress() async throws {}
}
#endif
