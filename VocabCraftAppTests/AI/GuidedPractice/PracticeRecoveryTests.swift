import Foundation
import SwiftData
import Testing
@testable import VocabCraftApp

// MARK: - Test Doubles

private final class RecoveryTestRepository: PracticeRepositoryProtocol, @unchecked Sendable {
    var persistedSession: PracticeSession?
    var persistedTurns: [PracticeTurn] = []
    var persistedExposures: [SupportExposure] = []
    var persistedEvidence: [WordUseEvidence] = []
    var persistedProgress: [CommunicationProgress] = []
    var pendingIntents: [PracticePresentationIntent] = []
    var revisions: [(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint)] = []
    var callEvents: [String] = []

    var shouldFailCommit = false
    var shouldFailRevise = false
    var onCommit: (@Sendable (PracticeCommit) async -> Void)?

    func create(_ session: PracticeSession) async throws {
        callEvents.append("create")
        persistedSession = session
    }

    func loadSession(id: UUID) async throws -> PracticeSessionSnapshot? {
        callEvents.append("loadSession")
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
        callEvents.append("savePendingTurn")
        persistedTurns.append(turn)
        if var current = persistedSession {
            current = PracticeSession(
                id: current.id,
                missionSnapshot: current.missionSnapshot,
                status: current.status,
                startedAt: current.startedAt,
                completedAt: current.completedAt,
                checkpoint: checkpoint,
                revision: current.revision,
                initialInputMode: current.initialInputMode,
                policyVersion: current.policyVersion
            )
            persistedSession = current
        }
    }

    func commit(_ value: PracticeCommit) async throws -> PracticeSessionSnapshot {
        callEvents.append("commit")
        if shouldFailCommit {
            throw PracticeFailure(code: .storage, message: "Injected commit failure")
        }
        if let turn = value.turn {
            if let index = persistedTurns.firstIndex(where: { $0.id == turn.id }) {
                persistedTurns[index] = turn
            } else {
                persistedTurns.append(turn)
            }
        }
        if let assessment = value.assessment {
            persistedEvidence.append(contentsOf: assessment.evidence)
        }
        if var current = persistedSession {
            current = PracticeSession(
                id: current.id,
                missionSnapshot: current.missionSnapshot,
                status: current.status,
                startedAt: current.startedAt,
                completedAt: current.completedAt,
                checkpoint: value.checkpoint,
                revision: current.revision,
                initialInputMode: current.initialInputMode,
                policyVersion: current.policyVersion
            )
            persistedSession = current
        }
        await onCommit?(value)
        guard let snapshot = try await loadSession(id: value.sessionId) else {
            throw PracticeFailure(code: .storage, message: "Session missing")
        }
        return snapshot
    }

    func preparePresentation(_ intent: PracticePresentationIntent, expectedRevision: Int) async throws {
        callEvents.append("preparePresentation")
        pendingIntents.append(intent)
    }

    func confirmPresentation(id: UUID, exposure: SupportExposure, expectedRevision: Int) async throws {
        callEvents.append("confirmPresentation")
        pendingIntents.removeAll { $0.id == id }
        persistedExposures.append(exposure)
    }

    func revise(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint) async throws -> Int {
        callEvents.append("revise")
        if shouldFailRevise {
            throw PracticeFailure(code: .storage, message: "Injected revise failure")
        }
        let nextRev = expectedRevision + 1
        if var current = persistedSession {
            current = PracticeSession(
                id: current.id,
                missionSnapshot: current.missionSnapshot,
                status: current.status,
                startedAt: current.startedAt,
                completedAt: current.completedAt,
                checkpoint: checkpoint,
                revision: nextRev,
                initialInputMode: current.initialInputMode,
                policyVersion: current.policyVersion
            )
            persistedSession = current
        }
        revisions.append((sessionId, expectedRevision, checkpoint))
        return nextRev
    }

    func finalize(sessionId: UUID, completion: PracticeCompletion, expectedRevision: Int) async throws -> PracticeSummary {
        callEvents.append("finalize")
        let status: PracticeSessionStatus = (completion == .completed) ? .completed : .partial
        return PracticeSummary(
            sessionId: sessionId,
            status: status,
            objectiveResults: persistedSession?.checkpoint.objectiveResults ?? [],
            perWordProgress: persistedProgress,
            evidenceIds: persistedEvidence.map(\.id),
            persisted: true
        )
    }

    func deleteSession(id: UUID) async throws {
        callEvents.append("deleteSession")
        persistedSession = nil
        persistedTurns.removeAll()
        persistedEvidence.removeAll()
        persistedExposures.removeAll()
        pendingIntents.removeAll()
    }

    func deleteAllPractice() async throws {
        try await deleteSession(id: UUID())
    }

    func resetAllLearningProgress() async throws {
        try await deleteAllPractice()
    }
}

private final class RecoveryTestAI: PracticeAIProtocol, @unchecked Sendable {
    var requests: [PracticeAIRequest] = []
    var providerIdentity: String = "recovery-ai-provider"
    var onRespond: (@Sendable (PracticeAIRequest) async throws -> Void)?

    init(providerIdentity: String = "recovery-ai-provider") {
        self.providerIdentity = providerIdentity
    }

    func capability() async -> PracticeCapability {
        PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: true,
            canCaptureSpeech: true,
            canPlaySpeech: true,
            providerIdentity: providerIdentity
        )
    }

    func respond(to request: PracticeAIRequest) async throws -> PracticeAIResponse {
        requests.append(request)
        if let onRespond {
            try await onRespond(request)
        }
        let wordId = request.mission.targetWordIds.first ?? 101
        let text = request.acceptedTurns.last?.acceptedText ?? "I want coffee"
        return PracticeAIResponse(
            characterReply: "Here is your coffee!",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: wordId,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: text.contains("coffee") ? "coffee" : nil
                )
            ],
            coachFeedback: nil,
            hintCandidate: nil
        )
    }
}

private final class RecoveryTestSpeech: PracticeSpeechProtocol, @unchecked Sendable {
    var stopCallCount: Int = 0
    var captureContinuation: AsyncThrowingStream<PracticeSpeechEvent, Error>.Continuation?

    func capability() -> PracticeCapability {
        PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: true,
            canCaptureSpeech: true,
            canPlaySpeech: true,
            providerIdentity: "recovery-speech-test"
        )
    }

    func capture(locale: String) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        AsyncThrowingStream { continuation in
            self.captureContinuation = continuation
        }
    }

    func play(text: String, voice: VoiceConfiguration) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.playbackStarted)
            continuation.yield(.playbackFinished)
            continuation.finish()
        }
    }

    func stop() async {
        stopCallCount += 1
        captureContinuation?.finish()
        captureContinuation = nil
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

@Suite("Practice Recovery & Safe State Mutation Tests")
@MainActor
struct PracticeRecoveryTests {
    // MARK: - Test 1: App background / pause stops audio and does not auto-activate mic on resume

    @Test("App background / pause stops audio and preserves checkpoint; resume does NOT auto-activate mic")
    func backgroundOrPauseStopsAudioAndPreservesCheckpointResumeDoesNotAutoActivateMic() async throws {
        let repo = RecoveryTestRepository()
        let aiProvider = RecoveryTestAI()
        let speech = RecoveryTestSpeech()
        let clock = ManualPracticeClock(initialDate: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = PracticeSessionCoordinator(
            repository: repo,
            ai: aiProvider,
            speech: speech,
            clock: clock
        )

        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)
        #expect(coordinator.state == .awaitingLearner)

        await coordinator.startCapture()
        #expect(coordinator.state == .capturing)

        await coordinator.pause()
        #expect(coordinator.state == .paused)
        #expect(speech.stopCallCount >= 1)

        guard let session = coordinator.session else {
            Issue.record("Session must be active")
            return
        }

        await coordinator.resume(sessionId: session.id)
        #expect(coordinator.state == .awaitingLearner)
        #expect(coordinator.activeTurnText.isEmpty)
    }

    // MARK: - Test 2: Crash after pending turn restores exactly one user turn; retryPendingTurn completes

    @Test("Crash after pending turn restores exactly one user turn; retryPendingTurn completes AI evaluation and commits")
    func crashAfterPendingTurnRestoresExactlyOneUserTurnAndRetryPendingTurnCompletes() async throws {
        let repo = RecoveryTestRepository()
        let aiProvider = RecoveryTestAI()
        let speech = RecoveryTestSpeech()
        let clock = ManualPracticeClock(initialDate: Date(timeIntervalSince1970: 1_700_000_000))
        let mission = try PracticeFixtures.mission(wordIds: [101])

        let pendingTurnId = UUID()
        let pendingTurn = PracticeTurn(
            id: pendingTurnId,
            sessionId: UUID(),
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I want coffee",
            acceptedText: "I want coffee",
            transcriptStatus: .final,
            generationStatus: .pending,
            requestId: "req_crash_1",
            sessionRevision: 1,
            timestamp: clock.now()
        )
        let checkpoint = PracticeCheckpoint(
            pendingTurnId: pendingTurnId,
            requestId: "req_crash_1",
            presentationIntents: [],
            exposureUncertainWordIds: [],
            currentSupportLevel: .none,
            objectiveResults: [PracticeObjectiveResult(objectiveId: "order_food", intentVerdict: .notYet, opportunityObserved: false)],
            difficultyOutcomes: []
        )
        let session = PracticeSession(
            id: pendingTurn.sessionId,
            missionSnapshot: mission,
            status: .inProgress,
            startedAt: clock.now(),
            completedAt: nil,
            checkpoint: checkpoint,
            revision: 1,
            initialInputMode: .voice,
            policyVersion: 1
        )
        repo.persistedSession = session
        repo.persistedTurns = [pendingTurn]

        let newCoordinator = PracticeSessionCoordinator(
            repository: repo,
            ai: aiProvider,
            speech: speech,
            clock: clock
        )

        await newCoordinator.resume(sessionId: session.id)
        #expect(newCoordinator.state == .awaitingLearner)
        #expect(newCoordinator.turns.count == 1)
        #expect(newCoordinator.turns.first?.generationStatus == .pending)

        await newCoordinator.retryPendingTurn()

        #expect(newCoordinator.turns.count == 1)
        #expect(newCoordinator.turns.first?.generationStatus == .succeeded)
        #expect(newCoordinator.state == .awaitingLearner)
        #expect(repo.callEvents.contains("commit"))
    }

    // MARK: - Test 3: retrySave retries commit when previous save failed

    @Test("retrySave retries commit when previous save failed")
    func retrySaveRetriesCommitWhenPreviousSaveFailed() async throws {
        let repo = RecoveryTestRepository()
        let aiProvider = RecoveryTestAI()
        let speech = RecoveryTestSpeech()
        let clock = ManualPracticeClock(initialDate: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = PracticeSessionCoordinator(
            repository: repo,
            ai: aiProvider,
            speech: speech,
            clock: clock
        )

        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        repo.shouldFailCommit = true
        await coordinator.submit(text: "I want coffee", mode: .voice)

        #expect(coordinator.state == .recoverableError)
        #expect(coordinator.failure != nil)
        #expect(coordinator.lastFailedCommit != nil)

        repo.shouldFailCommit = false
        await coordinator.retrySave()

        #expect(coordinator.state == .awaitingLearner)
        #expect(coordinator.failure == nil)
        #expect(coordinator.lastFailedCommit == nil)
        #expect(coordinator.turns.first?.generationStatus == .succeeded)
    }

    // MARK: - Test 4: replaceTranscript replaces text, supersedes older evidence and excludes from voice progress

    @Test("replaceTranscript replaces text, sets mode editedTranscript, supersedes older evidence, and excludes from voice progress")
    func replaceTranscriptReplacesTextSetsEditedModeSupersedesOlderEvidenceAndExcludesFromVoiceProgress() async throws {
        let container = try PracticeTestStorage.createContainer()
        _ = try PracticeTestStorage.seedBaselineSRS(in: container, wordId: 101)
        let repository = PracticeModelActor(modelContainer: container)

        let aiProvider = RecoveryTestAI()
        let speech = RecoveryTestSpeech()
        let clock = ManualPracticeClock(initialDate: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = PracticeSessionCoordinator(
            repository: repository,
            ai: aiProvider,
            speech: speech,
            clock: clock
        )

        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        await coordinator.submit(text: "I want coffee", mode: .voice)
        #expect(coordinator.turns.count == 1)
        let originalTurnId = coordinator.turns[0].id

        let initialEvidence = try await repository.evidence()
        #expect(initialEvidence.count == 1)
        #expect(initialEvidence[0].inputMode == .voice)
        #expect(initialEvidence[0].status == .valid)

        let initialProgress = try await repository.progress()
        let voiceProgBefore = initialProgress.first { $0.wordId == 101 && $0.inputMode == .voice }
        #expect(voiceProgBefore != nil)

        await coordinator.replaceTranscript(turnId: originalTurnId, text: "I would like a coffee")

        #expect(coordinator.turns.count == 1)
        let updatedTurn = coordinator.turns[0]
        #expect(updatedTurn.acceptedText == "I would like a coffee")
        #expect(updatedTurn.inputMode == .editedTranscript)
        #expect(updatedTurn.transcriptStatus == .edited)

        let allEvidence = try await repository.evidence()
        let voiceEvidence = allEvidence.filter { $0.inputMode == .voice }
        let editedEvidence = allEvidence.filter { $0.inputMode == .editedTranscript }

        #expect(voiceEvidence.allSatisfy { $0.status == .superseded })
        #expect(editedEvidence.count == 1)
        #expect(editedEvidence[0].status == .valid)

        let updatedProgress = try await repository.progress()
        let voiceProgAfter = updatedProgress.first { $0.wordId == 101 && $0.inputMode == .voice }
        #expect(voiceProgAfter?.independentEvidenceIds.contains(editedEvidence[0].id) == false)
    }

    // MARK: - Test 5: switchProvider invalidates active token, bumps revision, and rejects late callback

    @Test("switchProvider invalidates active token, bumps revision, and rejects late callback from previous provider")
    func switchProviderInvalidatesActiveTokenBumpsRevisionAndRejectsLateCallback() async throws {
        let repo = RecoveryTestRepository()
        let aiProviderA = RecoveryTestAI(providerIdentity: "provider-A")
        let aiProviderB = RecoveryTestAI(providerIdentity: "provider-B")
        let speech = RecoveryTestSpeech()
        let clock = ManualPracticeClock(initialDate: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = PracticeSessionCoordinator(
            repository: repo,
            ai: aiProviderA,
            speech: speech,
            clock: clock
        )

        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)
        guard let session = coordinator.session else {
            Issue.record("Session should exist")
            return
        }
        let initialRevision = session.revision

        let providerASuspended = AsyncBarrier()
        let providerAResumed = AsyncBarrier()
        aiProviderA.onRespond = { _ in
            providerASuspended.isSet = true
            while !providerAResumed.isSet {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }

        let submitTask = Task { @MainActor in
            await coordinator.submit(text: "I want coffee", mode: .voice)
        }

        while !providerASuspended.isSet {
            try await Task.sleep(nanoseconds: 5_000_000)
        }

        await coordinator.switchProvider(to: aiProviderB)

        #expect(coordinator.session?.revision == initialRevision + 1)
        #expect(coordinator.activeOperationToken == nil)

        providerAResumed.isSet = true
        await submitTask.value

        let committedEvidence = try await repo.evidence()
        #expect(committedEvidence.allSatisfy { $0.providerIdentity != "provider-A" })
    }
}
