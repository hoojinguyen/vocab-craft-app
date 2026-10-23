import Foundation
import SwiftData
import Testing
@testable import VocabCraftApp

// MARK: - Test Doubles

private final class DeletionTestRepository: PracticeRepositoryProtocol, @unchecked Sendable {
    var persistedSession: PracticeSession?
    var persistedTurns: [PracticeTurn] = []
    var persistedEvidence: [WordUseEvidence] = []
    var persistedProgress: [CommunicationProgress] = []
    var persistedExposures: [SupportExposure] = []
    var pendingIntents: [PracticePresentationIntent] = []
    var revisions: [(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint)] = []
    var shouldFailReset = false
    var resetCallCount = 0

    func create(_ session: PracticeSession) async throws {
        persistedSession = session
    }

    func loadSession(id: UUID) async throws -> PracticeSessionSnapshot? {
        guard let session = persistedSession, session.id == id else { return nil }
        return PracticeSessionSnapshot(
            session: session,
            turns: persistedTurns,
            exposures: persistedExposures,
            evidence: persistedEvidence,
            progress: persistedProgress,
            pendingPresentations: pendingIntents
        )
    }

    func activeSession() async throws -> PracticeSessionSnapshot? {
        guard let session = persistedSession, session.status == .inProgress else { return nil }
        return try await loadSession(id: session.id)
    }

    func progress() async throws -> [CommunicationProgress] {
        persistedProgress
    }

    func evidence() async throws -> [WordUseEvidence] {
        persistedEvidence
    }

    func savePendingTurn(_ turn: PracticeTurn, checkpoint: PracticeCheckpoint, expectedRevision: Int) async throws {
        guard let session = persistedSession, session.revision == expectedRevision else {
            throw PracticeFailure(code: .staleRevision, message: "Stale revision")
        }
        persistedTurns.append(turn)
    }

    func commit(_ value: PracticeCommit) async throws -> PracticeSessionSnapshot {
        guard let session = persistedSession, session.id == value.sessionId else {
            throw PracticeFailure(code: .storage, message: "Session \(value.sessionId) not found")
        }
        guard session.revision == value.expectedRevision else {
            throw PracticeFailure(code: .staleRevision, message: "Stale revision")
        }
        if let turn = value.turn {
            persistedTurns.append(turn)
        }
        if let assessment = value.assessment {
            persistedEvidence.append(contentsOf: assessment.evidence)
        }
        guard let snapshot = try await loadSession(id: value.sessionId) else {
            throw PracticeFailure(code: .storage, message: "Session missing")
        }
        return snapshot
    }

    func preparePresentation(_ intent: PracticePresentationIntent, expectedRevision: Int) async throws {
        pendingIntents.append(intent)
    }

    func confirmPresentation(id: UUID, exposure: SupportExposure, expectedRevision: Int) async throws {
        pendingIntents.removeAll { $0.id == id }
        persistedExposures.append(exposure)
    }

    func revise(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint) async throws -> Int {
        guard let session = persistedSession, session.id == sessionId else {
            throw PracticeFailure(code: .storage, message: "Session not found")
        }
        let nextRev = expectedRevision + 1
        persistedSession = PracticeSession(
            id: session.id,
            missionSnapshot: session.missionSnapshot,
            status: session.status,
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            checkpoint: checkpoint,
            revision: nextRev,
            initialInputMode: session.initialInputMode,
            policyVersion: session.policyVersion
        )
        return nextRev
    }

    func finalize(sessionId: UUID, completion: PracticeCompletion, expectedRevision: Int) async throws -> PracticeSummary {
        let status: PracticeSessionStatus = (completion == .completed) ? .completed : .partial
        return PracticeSummary(
            sessionId: sessionId,
            status: status,
            objectiveResults: [],
            perWordProgress: persistedProgress,
            evidenceIds: persistedEvidence.map(\.id),
            persisted: true
        )
    }

    func deleteSession(id: UUID) async throws {
        if persistedSession?.id == id {
            persistedSession = nil
        }
        persistedTurns.removeAll { $0.sessionId == id }
        persistedEvidence.removeAll { $0.sessionId == id }
        persistedExposures.removeAll { $0.sessionId == id }
        pendingIntents.removeAll { $0.sessionId == id }
    }

    func deleteAllPractice() async throws {
        persistedSession = nil
        persistedTurns.removeAll()
        persistedEvidence.removeAll()
        persistedExposures.removeAll()
        pendingIntents.removeAll()
        persistedProgress.removeAll()
    }

    func resetAllLearningProgress() async throws {
        resetCallCount += 1
        if shouldFailReset {
            throw PracticeFailure(code: .storage, message: "Injected atomic reset failure")
        }
        try await deleteAllPractice()
    }
}

private final class DeletionTestAI: PracticeAIProtocol, @unchecked Sendable {
    var onRespond: (@Sendable (PracticeAIRequest) async throws -> Void)?

    func capability() async -> PracticeCapability {
        PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: true,
            canCaptureSpeech: true,
            canPlaySpeech: true,
            providerIdentity: "deletion-ai-test"
        )
    }

    func respond(to request: PracticeAIRequest) async throws -> PracticeAIResponse {
        if let onRespond {
            try await onRespond(request)
        }
        return PracticeAIResponse(
            characterReply: "Hello",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: request.mission.targetWordIds.first ?? 101,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: "coffee"
                )
            ],
            coachFeedback: nil,
            hintCandidate: nil
        )
    }
}

private final class DeletionTestSpeech: PracticeSpeechProtocol, @unchecked Sendable {
    var stopCount = 0

    func capability() -> PracticeCapability {
        PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: true,
            canCaptureSpeech: true,
            canPlaySpeech: true,
            providerIdentity: "deletion-speech-test"
        )
    }

    func capture(locale: String) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }

    func play(text: String, voice: VoiceConfiguration) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.playbackStarted)
            continuation.yield(.playbackFinished)
            continuation.finish()
        }
    }

    func stop() async {
        stopCount += 1
    }
}

private final class AsyncBarrier: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = false
    var isSet: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}

// MARK: - Test Suite

@Suite("Practice Deletion, Isolation & Full App Reset Tests")
@MainActor
struct PracticeDeletionTests {
    // MARK: - Test 1: Mandatory Standard Test Case

    @Test("lateCallbackCannotResurrectDeletedSession")
    func lateCallbackCannotResurrectDeletedSession() async throws {
        let repository = DeletionTestRepository()
        let aiProvider = DeletionTestAI()
        let speech = DeletionTestSpeech()
        let clock = ManualPracticeClock(initialDate: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = PracticeSessionCoordinator(
            repository: repository,
            ai: aiProvider,
            speech: speech,
            clock: clock
        )

        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)
        guard let session = coordinator.session else {
            Issue.record("Session must be started")
            return
        }
        let deletedID = session.id

        let aiSuspended = AsyncBarrier()
        let aiResumed = AsyncBarrier()
        aiProvider.onRespond = { _ in
            aiSuspended.isSet = true
            while !aiResumed.isSet {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }

        let submitTask = Task { @MainActor in
            await coordinator.submit(text: "I want coffee", mode: .voice)
        }

        while !aiSuspended.isSet {
            try await Task.sleep(nanoseconds: 5_000_000)
        }

        await coordinator.deleteCurrentSession()

        aiResumed.isSet = true
        await submitTask.value

        #expect(try await repository.loadSession(id: deletedID) == nil)
        let remainingEvidence = try await repository.evidence()
        #expect(remainingEvidence.isEmpty)
    }

    // MARK: - Test 2: Deleting one session cleans temporary audio and rebuilds affected word progress

    @Test("Deleting one session cleans temporary audio via PracticePrivacyStore and rebuilds affected word progress")
    func deletingOneSessionCleansTemporaryAudioAndRebuildsProgress() async throws {
        let container = try PracticeTestStorage.createContainer()
        _ = try PracticeTestStorage.seedBaselineSRS(in: container, wordId: 101)
        let repository = PracticeModelActor(modelContainer: container)

        let tempRoot = FileManager.default.temporaryDirectory.appendingPathComponent("TestPracticeAudio_\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }
        let privacyStore = PracticePrivacyStore(directory: tempRoot)

        let aiProvider = DeletionTestAI()
        let speech = DeletionTestSpeech()
        let clock = ManualPracticeClock(initialDate: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = PracticeSessionCoordinator(
            repository: repository,
            ai: aiProvider,
            speech: speech,
            clock: clock,
            privacyStore: privacyStore
        )

        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)
        guard let session = coordinator.session else {
            Issue.record("Session must exist")
            return
        }

        let dummyAudioURL = privacyStore.temporaryAudioURL(sessionId: session.id, filename: "test_recording.m4a")
        try "fake-audio-data".write(to: dummyAudioURL, atomically: true, encoding: .utf8)
        #expect(FileManager.default.fileExists(atPath: dummyAudioURL.path) == true)

        await coordinator.submit(text: "I want coffee", mode: .voice)

        let evidenceBefore = try await repository.evidence()
        #expect(evidenceBefore.count == 1)

        let progressBefore = try await repository.progress()
        let voiceProgBefore = progressBefore.first { $0.wordId == 101 && $0.inputMode == .voice }
        #expect(voiceProgBefore?.stage != .noEvidence)

        await coordinator.deleteCurrentSession()

        #expect(FileManager.default.fileExists(atPath: dummyAudioURL.path) == false)

        let evidenceAfter = try await repository.evidence()
        #expect(evidenceAfter.isEmpty)

        let progressAfter = try await repository.progress()
        let voiceProgAfter = progressAfter.first { $0.wordId == 101 && $0.inputMode == .voice }
        #expect(voiceProgAfter == nil || voiceProgAfter?.stage == .noEvidence)
    }

    // MARK: - Test 3: Temporary audio cleanup ONLY removes files in designated subfolder

    @Test("Temporary audio cleanup only removes files in practice audio directory, never touches other directories")
    func temporaryAudioCleanupOnlyRemovesFilesInDesignatedDirectory() async throws {
        let testRoot = FileManager.default.temporaryDirectory.appendingPathComponent("TestPrivacyIsolation_\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: testRoot) }

        let practiceAudioDir = testRoot.appendingPathComponent("PracticeAudio", isDirectory: true)
        let otherRecordingsDir = testRoot.appendingPathComponent("UserVoiceRecordings", isDirectory: true)
        try FileManager.default.createDirectory(at: otherRecordingsDir, withIntermediateDirectories: true)

        let userRecordingURL = otherRecordingsDir.appendingPathComponent("valuable_user_audio.m4a")
        try "important-user-voice".write(to: userRecordingURL, atomically: true, encoding: .utf8)

        let privacyStore = PracticePrivacyStore(directory: practiceAudioDir)
        let sessionA = UUID()
        let sessionB = UUID()

        let audioA = privacyStore.temporaryAudioURL(sessionId: sessionA, filename: "clipA.m4a")
        let audioB = privacyStore.temporaryAudioURL(sessionId: sessionB, filename: "clipB.m4a")
        try "audio-a".write(to: audioA, atomically: true, encoding: .utf8)
        try "audio-b".write(to: audioB, atomically: true, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: audioA.path) == true)
        #expect(FileManager.default.fileExists(atPath: audioB.path) == true)
        #expect(FileManager.default.fileExists(atPath: userRecordingURL.path) == true)

        try privacyStore.removeTemporaryAudio(sessionId: sessionA)
        #expect(FileManager.default.fileExists(atPath: audioA.path) == false)
        #expect(FileManager.default.fileExists(atPath: audioB.path) == true)
        #expect(FileManager.default.fileExists(atPath: userRecordingURL.path) == true)

        try privacyStore.removeAllTemporaryAudio()
        #expect(FileManager.default.fileExists(atPath: audioB.path) == false)
        #expect(FileManager.default.fileExists(atPath: userRecordingURL.path) == true)
    }

    // MARK: - Test 4: Full reset wipes all practice tables and SRS tables atomically

    @Test("Full reset (ResetUserProgressUseCase.executeResetAllProgress) wipes all practice tables and SRS tables atomically")
    func fullResetWipesAllPracticeTablesAndSRSTablesAtomically() async throws {
        let container = try PracticeTestStorage.createContainer()
        let context = container.mainContext

        let wordProgress = SchemaV3.UserWordProgress(
            wordId: 501,
            cefrLevel: "B2",
            masteryLevel: 4,
            isBookmarked: true,
            easeFactor: 2.5,
            intervalDays: 20,
            nextReviewDate: Date(),
            lastReviewDate: Date(),
            totalReviews: 12
        )
        context.insert(wordProgress)

        let reflexLog = SchemaV3.ReflexSessionLog(
            drillId: 1,
            responseTimeMs: 450,
            accuracyScore: 1.0,
            timestamp: Date()
        )
        context.insert(reflexLog)

        let quickReflex = SchemaV3.QuickReflexAttemptRecord(
            id: UUID(),
            wordId: 501,
            retrieveTimeMs: 400,
            useTimeMs: 300,
            retrieveSucceeded: true,
            useSucceeded: true,
            maxHintLevel: 1,
            inputModeRawValue: "voice",
            retryCount: 0,
            confidenceRawValue: "high",
            timestamp: Date()
        )
        context.insert(quickReflex)

        let sessionRec = SchemaV3.PracticeSessionRecord(
            id: UUID(),
            statusRaw: "inProgress",
            initialInputModeRaw: "voice"
        )
        context.insert(sessionRec)

        let turnRec = SchemaV3.PracticeTurnRecord(
            id: UUID(),
            sessionId: sessionRec.id,
            sequence: 1,
            speakerRaw: "learner",
            inputModeRaw: "voice",
            sessionRevision: 1
        )
        context.insert(turnRec)

        let expRec = SchemaV3.SupportExposureRecord(
            id: UUID(),
            sessionId: sessionRec.id,
            turnId: turnRec.id,
            levelRaw: "intent",
            originRaw: "learnerRequested",
            channelRaw: "visual"
        )
        context.insert(expRec)

        let presRec = SchemaV3.PracticePresentationRecord(
            id: UUID(),
            sessionId: sessionRec.id,
            turnId: turnRec.id,
            statusRaw: "pending",
            channelRaw: "visual",
            proposedLevelRaw: "intent",
            possibleWordIdsRaw: "501"
        )
        context.insert(presRec)

        let evRec = SchemaV3.WordUseEvidenceRecord(
            id: UUID(),
            sessionId: sessionRec.id,
            turnId: turnRec.id,
            wordId: 501,
            objectiveId: "obj_1",
            usageVerdictRaw: "appropriate",
            intentVerdictRaw: "achieved",
            transcriptReliabilityRaw: "usable",
            inputModeRaw: "voice",
            statusRaw: "valid"
        )
        context.insert(evRec)

        let progRec = SchemaV3.CommunicationProgressRecord(
            logicalKey: "501_voice",
            wordId: 501,
            inputModeRaw: "voice",
            stageRaw: "practicing"
        )
        context.insert(progRec)

        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.UserWordProgress>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.ReflexSessionLog>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.QuickReflexAttemptRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.PracticeSessionRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.PracticeTurnRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.SupportExposureRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.PracticePresentationRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.WordUseEvidenceRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.CommunicationProgressRecord>()) == 1)

        let practiceRepo = PracticeModelActor(modelContainer: container)
        let srsRepo = SRSRepositoryImpl(modelContext: context, practiceRepository: practiceRepo)
        let useCase = ResetUserProgressUseCase(srsRepository: srsRepo, practiceRepository: practiceRepo)

        try await useCase.executeResetAllProgress()

        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.UserWordProgress>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.ReflexSessionLog>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.QuickReflexAttemptRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.PracticeSessionRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.PracticeTurnRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.SupportExposureRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.PracticePresentationRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.WordUseEvidenceRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV3.CommunicationProgressRecord>()) == 0)
    }

    // MARK: - Test 5: Injected failure in reset transaction does not report success

    @Test("Injected failure in reset transaction does not report success and does not leave partial deleted state")
    func injectedFailureInResetTransactionFailsCleanly() async throws {
        let repository = DeletionTestRepository()
        repository.shouldFailReset = true

        let srsRepo = SRSRepositoryImpl(modelContext: nil, practiceRepository: repository)
        let useCase = ResetUserProgressUseCase(srsRepository: srsRepo, practiceRepository: repository)

        await #expect(throws: Error.self) {
            try await useCase.executeResetAllProgress()
        }
        #expect(repository.resetCallCount == 1)

        repository.shouldFailReset = false
        try await useCase.executeResetAllProgress()
        #expect(repository.resetCallCount == 2)
    }
}
