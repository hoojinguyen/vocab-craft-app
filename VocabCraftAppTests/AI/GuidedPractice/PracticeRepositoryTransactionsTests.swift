import Foundation
import SwiftData
import Testing
@testable import VocabCraftApp

@Suite("Practice Repository Transactions, Concurrency & Rollback Tests")
@MainActor
struct PracticeRepositoryTransactionsTests {
    // MARK: - Cross-Turn Superseding Isolation (Issue 1)

    @Test("cross-turn evidence is not superseded by subsequent turns with higher revisions")
    func crossTurnEvidenceNotSuperseded() async throws {
        let container = try PracticeTestStorage.createContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let session = PracticeFixtures.session(id: sessionId, mission: mission, revision: 1)
        try await repository.create(session)

        // Turn 1 committed with turnRevision 1
        let turn1Id = UUID(uuidString: "22222222-3333-4444-5555-666666666666")!
        let turn1 = PracticeTurn(
            id: turn1Id,
            sessionId: sessionId,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I want pasta",
            acceptedText: "I want pasta",
            requestId: "req-t1",
            sessionRevision: 1,
            timestamp: Date()
        )
        let evidence1 = PracticeFixtures.evidenceWithVersions(
            sessionId: sessionId,
            turnId: turn1Id,
            wordId: 101,
            turnRevision: 1,
            assessmentVersion: 1
        )
        let commit1 = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: turn1,
            assessment: PracticeAssessment(evidence: [evidence1], objectiveResults: [], response: PracticeAIResponse(characterReply: "Sure")),
            checkpoint: PracticeCheckpoint()
        )
        _ = try await repository.commit(commit1)

        // Turn 2 committed with turnRevision 2 (a different turn in the same session)
        let turn2Id = UUID(uuidString: "33333333-4444-5555-6666-777777777777")!
        let turn2 = PracticeTurn(
            id: turn2Id,
            sessionId: sessionId,
            sequence: 2,
            speaker: .learner,
            inputMode: .voice,
            originalText: "The pasta is tasty",
            acceptedText: "The pasta is tasty",
            requestId: "req-t2",
            sessionRevision: 1,
            timestamp: Date().addingTimeInterval(5)
        )
        let evidence2 = PracticeFixtures.evidenceWithVersions(
            sessionId: sessionId,
            turnId: turn2Id,
            wordId: 101,
            turnRevision: 2,
            assessmentVersion: 1
        )
        let commit2 = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: turn2,
            assessment: PracticeAssessment(evidence: [evidence2], objectiveResults: [], response: PracticeAIResponse(characterReply: "Glad to hear")),
            checkpoint: PracticeCheckpoint()
        )
        let snapshot2 = try await repository.commit(commit2)

        // Both Turn 1 and Turn 2 evidence MUST remain valid because they belong to different turns
        let validEvidence = snapshot2.evidence.filter { $0.status == PracticeEvidenceStatus.valid }
        #expect(validEvidence.count == 2)
        #expect(validEvidence.contains(where: { $0.turnId == turn1Id && $0.status == PracticeEvidenceStatus.valid }))
        #expect(validEvidence.contains(where: { $0.turnId == turn2Id && $0.status == PracticeEvidenceStatus.valid }))
    }

    // MARK: - Single Valid Assessment Per TurnRevision/Word (Issue 2)

    @Test("incremented assessmentVersion supersedes older version for same turnRevision")
    func assessmentVersionSupersedesOlderVersion() async throws {
        let container = try PracticeTestStorage.createContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID()
        let session = PracticeFixtures.session(id: sessionId, revision: 1)
        try await repository.create(session)

        let turnId = UUID()
        let turn = PracticeTurn(
            id: turnId,
            sessionId: sessionId,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I like apple",
            acceptedText: "I like apple",
            requestId: "req-eval",
            sessionRevision: 1,
            timestamp: Date()
        )

        // Version 1 of assessment
        let evidenceV1 = PracticeFixtures.evidenceWithVersions(
            sessionId: sessionId,
            turnId: turnId,
            wordId: 101,
            turnRevision: 1,
            assessmentVersion: 1
        )
        let commit1 = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: turn,
            assessment: PracticeAssessment(evidence: [evidenceV1], objectiveResults: [], response: PracticeAIResponse(characterReply: "Good")),
            checkpoint: PracticeCheckpoint()
        )
        _ = try await repository.commit(commit1)

        // Version 2 of assessment (re-evaluated for same turn and turnRevision)
        let evidenceV2 = PracticeFixtures.evidenceWithVersions(
            sessionId: sessionId,
            turnId: turnId,
            wordId: 101,
            turnRevision: 1,
            assessmentVersion: 2
        )
        let commit2 = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: turn,
            assessment: PracticeAssessment(evidence: [evidenceV2], objectiveResults: [], response: PracticeAIResponse(characterReply: "Excellent")),
            checkpoint: PracticeCheckpoint()
        )
        let snapshot = try await repository.commit(commit2)

        // Total evidence is 2, exactly ONE is valid (v2), and v1 is superseded
        #expect(snapshot.evidence.count == 2)
        let validEvidence = snapshot.evidence.filter { $0.status == PracticeEvidenceStatus.valid }
        let supersededEvidence = snapshot.evidence.filter { $0.status == PracticeEvidenceStatus.superseded }
        #expect(validEvidence.count == 1)
        #expect(validEvidence.first?.assessmentVersion == 2)
        #expect(supersededEvidence.count == 1)
        #expect(supersededEvidence.first?.assessmentVersion == 1)
    }

    // MARK: - Transaction Rollback Verification (Issue 3)

    @Test("transaction failure rolls back all uncommitted mutations cleanly leaving store unmodified")
    func transactionFailureRollbackLeavesStoreUnmodified() async throws {
        let container = try PracticeTestStorage.createContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID()
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let session = PracticeFixtures.session(id: sessionId, mission: mission, revision: 1)
        try await repository.create(session)

        // Inject simulated failure before commit save
        await repository.setTransactionFailureHook {
            throw PracticeFailure(code: .storage, message: "Simulated atomic rollback error")
        }

        let turnId = UUID()
        let turn = PracticeTurn(
            id: turnId,
            sessionId: sessionId,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I want pasta",
            acceptedText: "I want pasta",
            requestId: "req-err",
            sessionRevision: 1,
            timestamp: Date()
        )
        let evidence = PracticeFixtures.evidenceWithVersions(
            sessionId: sessionId,
            turnId: turnId,
            wordId: 101,
            turnRevision: 1,
            assessmentVersion: 1
        )
        let commit = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: turn,
            assessment: PracticeAssessment(evidence: [evidence], objectiveResults: [], response: PracticeAIResponse(characterReply: "Err")),
            checkpoint: PracticeCheckpoint()
        )

        // Commit MUST fail with PracticeFailure
        await #expect(throws: PracticeFailure.self) {
            _ = try await repository.commit(commit)
        }

        // Verify store remains completely unmodified
        let snapshot = try await repository.loadSession(id: sessionId)
        #expect(snapshot?.turns.isEmpty == true)
        #expect(snapshot?.evidence.isEmpty == true)
        #expect(snapshot?.progress.isEmpty == true)
        let allEvidence = try await repository.evidence()
        #expect(allEvidence.isEmpty)
        let allProgress = try await repository.progress()
        #expect(allProgress.isEmpty)

        // Clear failure hook and verify that subsequent clean commit succeeds
        await repository.setTransactionFailureHook(nil)
        let successfulSnapshot = try await repository.commit(commit)
        #expect(successfulSnapshot.turns.count == 1)
        #expect(successfulSnapshot.evidence.count == 1)
        #expect(successfulSnapshot.progress.count == 1)
    }

    // MARK: - Bulk Deletion & Reset Contracts

    @Test("deleteAllPractice deletes all practice entities while keeping SRS untouched")
    func deleteAllPracticeLeavesSRSIntact() async throws {
        let container = try PracticeTestStorage.createContainer()
        let srsBefore = try PracticeTestStorage.seedBaselineSRS(in: container, wordId: 101)
        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID()
        let session = PracticeFixtures.session(id: sessionId, revision: 1)
        try await repository.create(session)

        let turnId = UUID()
        let evidence = PracticeFixtures.evidence(sessionId: sessionId, wordId: 101, turnId: turnId)
        let commit = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: PracticeTurn(id: turnId, sessionId: sessionId, sequence: 1, speaker: .learner, inputMode: .voice, originalText: "hi", acceptedText: "hi", requestId: "r", timestamp: Date()),
            assessment: PracticeAssessment(evidence: [evidence], objectiveResults: [], response: PracticeAIResponse(characterReply: "hi")),
            checkpoint: PracticeCheckpoint()
        )
        _ = try await repository.commit(commit)

        #expect((try await repository.evidence()).count == 1)
        #expect((try await repository.loadSession(id: sessionId)) != nil)

        // Delete all practice
        try await repository.deleteAllPractice()

        #expect((try await repository.evidence()).isEmpty)
        #expect((try await repository.progress()).isEmpty)
        #expect((try await repository.loadSession(id: sessionId)) == nil)
        #expect((try await repository.activeSession()) == nil)

        // Verify SRS data is 100% intact
        let srsAfter = try PracticeTestStorage.fetchSRSState(in: container, wordId: 101)
        #expect(srsAfter == srsBefore)
    }

    @Test("resetAllLearningProgress deletes SRS, reflex and all practice entities")
    func resetAllLearningProgressDeletesBothSRSAndPractice() async throws {
        let container = try PracticeTestStorage.createContainer()
        _ = try PracticeTestStorage.seedBaselineSRS(in: container, wordId: 101)
        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID()
        let session = PracticeFixtures.session(id: sessionId, revision: 1)
        try await repository.create(session)

        let turnId = UUID()
        let evidence = PracticeFixtures.evidence(sessionId: sessionId, wordId: 101, turnId: turnId)
        let commit = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: PracticeTurn(id: turnId, sessionId: sessionId, sequence: 1, speaker: .learner, inputMode: .voice, originalText: "hi", acceptedText: "hi", requestId: "r", timestamp: Date()),
            assessment: PracticeAssessment(evidence: [evidence], objectiveResults: [], response: PracticeAIResponse(characterReply: "hi")),
            checkpoint: PracticeCheckpoint()
        )
        _ = try await repository.commit(commit)

        // Reset all learning progress
        try await repository.resetAllLearningProgress()

        #expect((try await repository.evidence()).isEmpty)
        #expect((try await repository.progress()).isEmpty)
        #expect((try await repository.loadSession(id: sessionId)) == nil)

        // SRS word progress must be wiped
        let srsAfter = try PracticeTestStorage.fetchSRSState(in: container, wordId: 101)
        #expect(srsAfter == nil)
    }

    @Test("unsupported formatVersion throws typed PracticePayloadError")
    func unsupportedPayloadFormatVersionFailsWithTypedError() async throws {
        let container = try PracticeTestStorage.createContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let corruptedSessionId = UUID()
        let corruptedRecord = SchemaV3.PracticeSessionRecord(
            id: corruptedSessionId,
            revision: 1,
            statusRaw: "inProgress",
            initialInputModeRaw: "voice",
            policyVersion: 1,
            startedAt: Date(),
            completedAt: nil,
            payloadJSON: Data([0xDE, 0xAD]),
            formatVersion: 99
        )
        container.mainContext.insert(corruptedRecord)
        try container.mainContext.save()

        await #expect(throws: PracticePayloadError.self) {
            _ = try await repository.loadSession(id: corruptedSessionId)
        }
    }
}
