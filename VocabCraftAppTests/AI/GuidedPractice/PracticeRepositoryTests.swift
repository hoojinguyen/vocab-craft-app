import Foundation
import SwiftData
import Testing
@testable import VocabCraftApp

@Suite("Practice Repository Atomicity, Idempotency & Rebuild Tests")
@MainActor
struct PracticeRepositoryTests {
    private struct SRSState: Equatable {
        let wordId: Int64
        let cefrLevel: String
        let masteryLevel: Int
        let easeFactor: Double
        let intervalDays: Int
        let nextReviewDate: Date
        let totalReviews: Int
        let mistakeCount: Int
        let sourceDeckId: String?
    }

    private func createTestContainer(storeURL: URL? = nil) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV3.self)
        if let storeURL {
            let config = ModelConfiguration(schema: schema, url: storeURL)
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [config])
        } else {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }

    private func seedBaselineSRS(in container: ModelContainer, wordId: Int64 = 101) throws -> SRSState {
        let baselineDate = Date(timeIntervalSince1970: 1_700_000_000)
        let srsWord = SchemaV3.UserWordProgress(
            wordId: wordId,
            cefrLevel: "B1",
            masteryLevel: 3,
            isBookmarked: true,
            easeFactor: 2.45,
            intervalDays: 14,
            nextReviewDate: baselineDate,
            lastReviewDate: baselineDate,
            totalReviews: 8,
            needsReview: false,
            mistakeCount: 2,
            sourceDeckId: "deck_culinary_art",
            sourceNodeId: "node_dining_01"
        )
        container.mainContext.insert(srsWord)
        try container.mainContext.save()

        return SRSState(
            wordId: srsWord.wordId,
            cefrLevel: srsWord.cefrLevel,
            masteryLevel: srsWord.masteryLevel,
            easeFactor: srsWord.easeFactor,
            intervalDays: srsWord.intervalDays,
            nextReviewDate: srsWord.nextReviewDate,
            totalReviews: srsWord.totalReviews,
            mistakeCount: srsWord.mistakeCount,
            sourceDeckId: srsWord.sourceDeckId
        )
    }

    private func fetchSRSState(in container: ModelContainer, wordId: Int64 = 101) throws -> SRSState? {
        let descriptor = FetchDescriptor<SchemaV3.UserWordProgress>(
            predicate: #Predicate { $0.wordId == wordId }
        )
        guard let item = try container.mainContext.fetch(descriptor).first else {
            return nil
        }
        return SRSState(
            wordId: item.wordId,
            cefrLevel: item.cefrLevel,
            masteryLevel: item.masteryLevel,
            easeFactor: item.easeFactor,
            intervalDays: item.intervalDays,
            nextReviewDate: item.nextReviewDate,
            totalReviews: item.totalReviews,
            mistakeCount: item.mistakeCount,
            sourceDeckId: item.sourceDeckId
        )
    }

    // MARK: - Mandatory Standard Test Case

    @Test("repeatedCommitDoesNotDuplicateEvidence satisfies standard idempotency & SRS isolation")
    func repeatedCommitDoesNotDuplicateEvidence() async throws {
        let container = try createTestContainer()
        let srsBefore = try seedBaselineSRS(in: container, wordId: 101)

        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let session = PracticeFixtures.session(id: sessionId, mission: mission, revision: 1)
        try await repository.create(session)

        let turnId = UUID(uuidString: "22222222-3333-4444-5555-666666666666")!
        let turn = PracticeTurn(
            id: turnId,
            sessionId: sessionId,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I would like to see the menu please",
            acceptedText: "I would like to see the menu please",
            transcriptStatus: .final,
            generationStatus: .succeeded,
            requestId: "req-001",
            sessionRevision: 1,
            timestamp: PracticeFixtures.baseDate
        )

        let evidenceId = UUID(uuidString: "33333333-4444-5555-6666-777777777777")!
        let evidence = WordUseEvidence(
            id: evidenceId,
            sessionId: sessionId,
            turnId: turnId,
            wordId: 101,
            objectiveId: "order_food",
            usageVerdict: .appropriate,
            intentVerdict: .achieved,
            transcriptReliability: .usable,
            supportExposureIds: [],
            primed: false,
            contextFamily: .dining,
            inputMode: .voice,
            quotedSpan: "the menu",
            assessmentVersion: 1,
            providerIdentity: "test_evaluator",
            status: .valid,
            timestamp: PracticeFixtures.baseDate,
            turnRevision: 1,
            opportunityId: "opp-01"
        )

        let assessment = PracticeAssessment(
            evidence: [evidence],
            objectiveResults: [
                PracticeObjectiveResult(
                    objectiveId: "order_food",
                    intentVerdict: .achieved,
                    opportunityObserved: true
                )
            ],
            response: PracticeAIResponse(
                characterReply: "Sure, here is our menu!",
                objectiveAssessments: [
                    PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
                ],
                wordAssessments: [
                    PracticeWordAssessment(wordId: 101, objectiveId: "order_food", usageVerdict: .appropriate, quotedSpan: "the menu")
                ]
            )
        )

        let checkpoint = PracticeCheckpoint(
            pendingTurnId: nil,
            requestId: "req-001",
            presentationIntents: [],
            exposureUncertainWordIds: [],
            currentSupportLevel: .none,
            objectiveResults: assessment.objectiveResults,
            difficultyOutcomes: []
        )

        let commit = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: turn,
            assessment: assessment,
            checkpoint: checkpoint
        )

        // First commit
        let afterFirst = try await repository.commit(commit)
        #expect(afterFirst.evidence.count == 1)
        #expect(afterFirst.turns.count == 1)
        #expect(afterFirst.progress.count == 1)

        // Second repeated commit (idempotent retry)
        let afterRetry = try await repository.commit(commit)

        // Mandatory Assertions from Brief
        #expect(afterRetry.evidence == afterFirst.evidence)

        let srsAfter = try fetchSRSState(in: container, wordId: 101)
        #expect(srsAfter == srsBefore)

        // Additional idempotency verifications
        #expect(afterRetry.turns.count == 1)
        #expect(afterRetry.progress.count == 1)
        #expect(afterRetry.progress.first?.stage == afterFirst.progress.first?.stage)
    }

    // MARK: - Stale Revision Rejection

    @Test("staleRevision is rejected for mutations with mismatched revision")
    func staleRevisionIsRejected() async throws {
        let container = try createTestContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID()
        let session = PracticeFixtures.session(id: sessionId, revision: 1)
        try await repository.create(session)

        let turn = PracticeTurn(
            id: UUID(),
            sessionId: sessionId,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "Hello",
            acceptedText: "Hello",
            requestId: "req-1",
            sessionRevision: 1,
            timestamp: Date()
        )

        // Attempting to save turn with expectedRevision 99 must fail
        await #expect(throws: PracticeFailure.self) {
            try await repository.savePendingTurn(turn, checkpoint: PracticeCheckpoint(), expectedRevision: 99)
        }

        // Attempting to revise with expectedRevision 99 must fail
        await #expect(throws: PracticeFailure.self) {
            _ = try await repository.revise(sessionId: sessionId, expectedRevision: 99, checkpoint: PracticeCheckpoint())
        }

        // Attempting to commit with expectedRevision 99 must fail
        let commit = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 99,
            turn: turn,
            assessment: nil,
            checkpoint: PracticeCheckpoint()
        )
        await #expect(throws: PracticeFailure.self) {
            _ = try await repository.commit(commit)
        }

        // Attempting to finalize with expectedRevision 99 must fail
        await #expect(throws: PracticeFailure.self) {
            _ = try await repository.finalize(sessionId: sessionId, completion: .completed, expectedRevision: 99)
        }
    }

    // MARK: - Single Active Session Limit

    @Test("only one active session inProgress is permitted")
    func singleActiveSessionEnforced() async throws {
        let container = try createTestContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let session1 = PracticeFixtures.session(id: UUID(), revision: 1)
        try await repository.create(session1)

        let active = try await repository.activeSession()
        #expect(active?.session.id == session1.id)

        // Creating a second in-progress session must fail
        let session2 = PracticeFixtures.session(id: UUID(), revision: 1)
        await #expect(throws: PracticeFailure.self) {
            try await repository.create(session2)
        }

        // Finalizing session 1 allows session 2 to be created
        _ = try await repository.finalize(sessionId: session1.id, completion: .completed, expectedRevision: 1)
        let activeAfterFinalize = try await repository.activeSession()
        #expect(activeAfterFinalize == nil)

        // Now session 2 can be created
        try await repository.create(session2)
        let newActive = try await repository.activeSession()
        #expect(newActive?.session.id == session2.id)
    }

    // MARK: - Superseding Older Turn Revisions

    @Test("turn revision supersedes previous evidence while keeping valid count unique")
    func turnRevisionSupersedesOldEvidence() async throws {
        let container = try createTestContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID()
        let session = PracticeFixtures.session(id: sessionId, revision: 1)
        try await repository.create(session)

        let turnId = UUID()
        let wordId: Int64 = 202

        // Turn Revision 1: initial evidence
        let turn1 = PracticeTurn(
            id: turnId,
            sessionId: sessionId,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I like apple",
            acceptedText: "I like apple",
            requestId: "req-1",
            sessionRevision: 1,
            timestamp: Date()
        )
        let evidence1 = WordUseEvidence(
            id: UUID(),
            sessionId: sessionId,
            turnId: turnId,
            wordId: wordId,
            objectiveId: "express_preference",
            usageVerdict: .appropriate,
            intentVerdict: .achieved,
            transcriptReliability: .usable,
            contextFamily: .dining,
            inputMode: .voice,
            quotedSpan: "apple",
            assessmentVersion: 1,
            status: .valid,
            timestamp: Date(),
            turnRevision: 1
        )
        let commit1 = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: turn1,
            assessment: PracticeAssessment(evidence: [evidence1], objectiveResults: [], response: PracticeAIResponse(characterReply: "Nice")),
            checkpoint: PracticeCheckpoint()
        )
        _ = try await repository.commit(commit1)

        let evidenceAfter1 = try await repository.evidence()
        #expect(evidenceAfter1.count == 1)
        #expect(evidenceAfter1.first?.status == .valid)
        #expect(evidenceAfter1.first?.turnRevision == 1)

        // Turn Revision 2: edited transcript or reassessment supersedes turnRevision 1
        let turn2 = PracticeTurn(
            id: turnId,
            sessionId: sessionId,
            sequence: 1,
            speaker: .learner,
            inputMode: .editedTranscript,
            originalText: "I like apple",
            acceptedText: "I really like fresh apple",
            requestId: "req-2",
            sessionRevision: 1,
            timestamp: Date().addingTimeInterval(5)
        )
        let evidence2 = WordUseEvidence(
            id: UUID(),
            sessionId: sessionId,
            turnId: turnId,
            wordId: wordId,
            objectiveId: "express_preference",
            usageVerdict: .appropriate,
            intentVerdict: .achieved,
            transcriptReliability: .usable,
            contextFamily: .dining,
            inputMode: .voice,
            quotedSpan: "fresh apple",
            assessmentVersion: 1,
            status: .valid,
            timestamp: Date().addingTimeInterval(5),
            turnRevision: 2
        )
        let commit2 = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: turn2,
            assessment: PracticeAssessment(evidence: [evidence2], objectiveResults: [], response: PracticeAIResponse(characterReply: "Great")),
            checkpoint: PracticeCheckpoint()
        )
        _ = try await repository.commit(commit2)

        let allEvidence = try await repository.evidence()
        #expect(allEvidence.count == 2)

        let superseded = allEvidence.first { $0.id == evidence1.id }
        let valid = allEvidence.first { $0.id == evidence2.id }
        #expect(superseded?.status == .superseded)
        #expect(valid?.status == .valid)
    }

    // MARK: - Two-Phase Durable Presentation Intent

    @Test("presentation intent prepare and confirm workflow")
    func presentationTwoPhaseDurableWorkflow() async throws {
        let container = try createTestContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID()
        let session = PracticeFixtures.session(id: sessionId, revision: 1)
        try await repository.create(session)

        let intentId = UUID()
        let intent = PracticePresentationIntent(
            id: intentId,
            sessionId: sessionId,
            turnId: nil,
            content: "You could order the special today",
            channel: .visual,
            possibleWordIds: [101, 102],
            proposedLevel: .lexical,
            status: .pending
        )

        // Phase 1: Prepare
        try await repository.preparePresentation(intent, expectedRevision: 1)

        let snapshotAfterPrepare = try await repository.loadSession(id: sessionId)
        #expect(snapshotAfterPrepare?.pendingPresentations.count == 1)
        #expect(snapshotAfterPrepare?.pendingPresentations.first?.id == intentId)
        #expect(snapshotAfterPrepare?.exposures.isEmpty == true)

        // Phase 2: Confirm
        let exposureId = UUID()
        let exposure = SupportExposure(
            id: exposureId,
            sessionId: sessionId,
            turnId: nil,
            wordIds: [101, 102],
            level: .lexical,
            origin: .coachSuggested,
            contentSnapshot: intent.content,
            presentedAt: Date(),
            channel: .visual
        )
        try await repository.confirmPresentation(id: intentId, exposure: exposure, expectedRevision: 1)

        let snapshotAfterConfirm = try await repository.loadSession(id: sessionId)
        #expect(snapshotAfterConfirm?.pendingPresentations.isEmpty == true)
        #expect(snapshotAfterConfirm?.exposures.count == 1)
        #expect(snapshotAfterConfirm?.exposures.first?.id == exposureId)
    }

    // MARK: - Revise & Finalize Persisted

    @Test("revise increments revision and finalize sets persisted=true only after save")
    func reviseAndFinalizeWorkflow() async throws {
        let container = try createTestContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID()
        let session = PracticeFixtures.session(id: sessionId, revision: 1)
        try await repository.create(session)

        let newCheckpoint = PracticeCheckpoint(
            pendingTurnId: nil,
            requestId: "revised-req",
            presentationIntents: [],
            exposureUncertainWordIds: [],
            currentSupportLevel: .frame,
            objectiveResults: [],
            difficultyOutcomes: []
        )
        let newRev = try await repository.revise(sessionId: sessionId, expectedRevision: 1, checkpoint: newCheckpoint)
        #expect(newRev == 2)

        let updated = try await repository.loadSession(id: sessionId)
        #expect(updated?.session.revision == 2)
        #expect(updated?.session.checkpoint.currentSupportLevel == .frame)

        let summary = try await repository.finalize(sessionId: sessionId, completion: .completed, expectedRevision: 2)
        #expect(summary.persisted == true)
        #expect(summary.status == .completed)

        let finalized = try await repository.loadSession(id: sessionId)
        #expect(finalized?.session.status == .completed)
        #expect(finalized?.session.completedAt != nil)
    }

    // MARK: - Deletion & Progress Rebuild

    @Test("deleteSession removes session records and rebuilds affected word progress")
    func deleteSessionRebuildsProgress() async throws {
        let container = try createTestContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let sessionId = UUID()
        let wordId: Int64 = 303
        let mission = try PracticeFixtures.mission(wordIds: [wordId])
        let session = PracticeFixtures.session(id: sessionId, mission: mission, revision: 1)
        try await repository.create(session)

        let turnId = UUID()
        let evidence = PracticeFixtures.evidence(sessionId: sessionId, wordId: wordId, turnId: turnId)
        let commit = PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: PracticeTurn(id: turnId, sessionId: sessionId, sequence: 1, speaker: .learner, inputMode: .voice, originalText: "hi", acceptedText: "hi", requestId: "r", timestamp: Date()),
            assessment: PracticeAssessment(evidence: [evidence], objectiveResults: [], response: PracticeAIResponse(characterReply: "hi")),
            checkpoint: PracticeCheckpoint()
        )
        _ = try await repository.commit(commit)

        let progressBefore = try await repository.progress()
        #expect(progressBefore.first { $0.wordId == wordId }?.stage == .practicing)

        // Delete session
        try await repository.deleteSession(id: sessionId)

        let loaded = try await repository.loadSession(id: sessionId)
        #expect(loaded == nil)

        let evidenceRemaining = try await repository.evidence()
        #expect(evidenceRemaining.isEmpty)

        let progressAfter = try await repository.progress()
        let wordProgress = progressAfter.first { $0.wordId == wordId }
        #expect(wordProgress == nil || wordProgress?.stage == .noEvidence)
    }

    // MARK: - Reopen Store On Disk

    @Test("reopening store retains snapshot and preserves idempotency")
    func reopenStoreRetainsSnapshotsAndIdempotency() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storeURL = tempDir.appendingPathComponent("reopen_test.sqlite")
        let sessionId = UUID()
        let turnId = UUID()

        // Phase 1: Create and commit in container 1
        do {
            let container1 = try createTestContainer(storeURL: storeURL)
            let repo1 = PracticeModelActor(modelContainer: container1)

            let mission = try PracticeFixtures.mission(wordIds: [101])
            let session = PracticeFixtures.session(id: sessionId, mission: mission, revision: 1)
            try await repo1.create(session)

            let turn = PracticeTurn(
                id: turnId,
                sessionId: sessionId,
                sequence: 1,
                speaker: .learner,
                inputMode: .voice,
                originalText: "menu",
                acceptedText: "menu",
                requestId: "r1",
                timestamp: Date()
            )
            let evidence = PracticeFixtures.evidence(sessionId: sessionId, wordId: 101, turnId: turnId)
            let commit = PracticeCommit(
                sessionId: sessionId,
                expectedRevision: 1,
                turn: turn,
                assessment: PracticeAssessment(
                    evidence: [evidence],
                    objectiveResults: [],
                    response: PracticeAIResponse(characterReply: "ok")
                ),
                checkpoint: PracticeCheckpoint()
            )

            _ = try await repo1.commit(commit)
        }

        // Phase 2: Open in brand new container 2 from the same disk file
        do {
            let container2 = try createTestContainer(storeURL: storeURL)
            let repo2 = PracticeModelActor(modelContainer: container2)

            let snapshot = try await repo2.loadSession(id: sessionId)
            #expect(snapshot != nil)
            #expect(snapshot?.session.id == sessionId)
            #expect(snapshot?.turns.count == 1)
            #expect(snapshot?.evidence.count == 1)

            // Re-commit must be idempotent
            let turn = PracticeTurn(
                id: turnId,
                sessionId: sessionId,
                sequence: 1,
                speaker: .learner,
                inputMode: .voice,
                originalText: "menu",
                acceptedText: "menu",
                requestId: "r1",
                timestamp: Date()
            )
            let evidence = PracticeFixtures.evidence(sessionId: sessionId, wordId: 101, turnId: turnId)
            let commit = PracticeCommit(
                sessionId: sessionId,
                expectedRevision: 1,
                turn: turn,
                assessment: PracticeAssessment(
                    evidence: [evidence],
                    objectiveResults: [],
                    response: PracticeAIResponse(characterReply: "ok")
                ),
                checkpoint: PracticeCheckpoint()
            )

            let afterRecommit = try await repo2.commit(commit)
            #expect(afterRecommit.evidence.count == 1)
            #expect(afterRecommit.turns.count == 1)
        }
    }

    // MARK: - Bulk Deletion & Reset Contracts

    @Test("deleteAllPractice deletes all practice entities while keeping SRS untouched")
    func deleteAllPracticeLeavesSRSIntact() async throws {
        let container = try createTestContainer()
        let srsBefore = try seedBaselineSRS(in: container, wordId: 101)
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
        let srsAfter = try fetchSRSState(in: container, wordId: 101)
        #expect(srsAfter == srsBefore)
    }

    @Test("resetAllLearningProgress deletes SRS, reflex and all practice entities")
    func resetAllLearningProgressDeletesBothSRSAndPractice() async throws {
        let container = try createTestContainer()
        _ = try seedBaselineSRS(in: container, wordId: 101)
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
        let srsAfter = try fetchSRSState(in: container, wordId: 101)
        #expect(srsAfter == nil)
    }

    @Test("unsupported formatVersion throws typed PracticePayloadError")
    func unsupportedPayloadFormatVersionFailsWithTypedError() async throws {
        let container = try createTestContainer()
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
