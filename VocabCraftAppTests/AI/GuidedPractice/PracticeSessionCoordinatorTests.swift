import Foundation
import Testing
@testable import VocabCraftApp

// MARK: - Test Doubles

private final class CoordinatorTestRepository: PracticeRepositoryProtocol, @unchecked Sendable {
    var createdSessions: [PracticeSession] = []
    var savedPendingTurns: [(turn: PracticeTurn, checkpoint: PracticeCheckpoint, expectedRevision: Int)] = []
    var commits: [PracticeCommit] = []
    var revisions: [(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint)] = []
    var finalizations: [(sessionId: UUID, completion: PracticeCompletion, expectedRevision: Int)] = []
    var callEvents: [String] = []

    var persistedTurns: [PracticeTurn] = []
    var persistedEvidence: [WordUseEvidence] = []
    var persistedProgress: [CommunicationProgress] = []
    var persistedSession: PracticeSession?

    var onSavePendingTurn: (@Sendable (PracticeTurn) async -> Void)?
    var onCommit: (@Sendable (PracticeCommit) async -> Void)?

    func create(_ session: PracticeSession) async throws {
        createdSessions.append(session)
        persistedSession = session
        callEvents.append("create")
    }

    func loadSession(id: UUID) async throws -> PracticeSessionSnapshot? {
        guard let session = persistedSession, session.id == id else { return nil }
        return PracticeSessionSnapshot(
            session: session,
            turns: persistedTurns,
            exposures: [],
            evidence: persistedEvidence,
            progress: persistedProgress,
            pendingPresentations: []
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
        savedPendingTurns.append((turn, checkpoint, expectedRevision))
        persistedTurns.append(turn)
        if var currentSession = persistedSession {
            currentSession = PracticeSession(
                id: currentSession.id,
                missionSnapshot: currentSession.missionSnapshot,
                status: currentSession.status,
                startedAt: currentSession.startedAt,
                completedAt: currentSession.completedAt,
                checkpoint: checkpoint,
                revision: currentSession.revision,
                initialInputMode: currentSession.initialInputMode,
                policyVersion: currentSession.policyVersion
            )
            persistedSession = currentSession
        }
        await onSavePendingTurn?(turn)
    }

    func commit(_ value: PracticeCommit) async throws -> PracticeSessionSnapshot {
        callEvents.append("commit")
        commits.append(value)
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
        if var currentSession = persistedSession {
            currentSession = PracticeSession(
                id: currentSession.id,
                missionSnapshot: currentSession.missionSnapshot,
                status: currentSession.status,
                startedAt: currentSession.startedAt,
                completedAt: currentSession.completedAt,
                checkpoint: value.checkpoint,
                revision: currentSession.revision,
                initialInputMode: currentSession.initialInputMode,
                policyVersion: currentSession.policyVersion
            )
            persistedSession = currentSession
        }
        await onCommit?(value)
        guard let snapshot = try await loadSession(id: value.sessionId) else {
            throw PracticeFailure(code: .storage, message: "Session missing")
        }
        return snapshot
    }

    func preparePresentation(_ intent: PracticePresentationIntent, expectedRevision: Int) async throws {
        callEvents.append("preparePresentation")
    }

    func confirmPresentation(id: UUID, exposure: SupportExposure, expectedRevision: Int) async throws {
        callEvents.append("confirmPresentation")
    }

    func revise(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint) async throws -> Int {
        callEvents.append("revise")
        revisions.append((sessionId, expectedRevision, checkpoint))
        let nextRev = expectedRevision + 1
        if var currentSession = persistedSession {
            currentSession = PracticeSession(
                id: currentSession.id,
                missionSnapshot: currentSession.missionSnapshot,
                status: currentSession.status,
                startedAt: currentSession.startedAt,
                completedAt: currentSession.completedAt,
                checkpoint: checkpoint,
                revision: nextRev,
                initialInputMode: currentSession.initialInputMode,
                policyVersion: currentSession.policyVersion
            )
            persistedSession = currentSession
        }
        return nextRev
    }

    func finalize(sessionId: UUID, completion: PracticeCompletion, expectedRevision: Int) async throws -> PracticeSummary {
        callEvents.append("finalize")
        finalizations.append((sessionId, completion, expectedRevision))
        let status: PracticeSessionStatus = completion == .completed ? .completed : .partial
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
        persistedSession = nil
        persistedTurns.removeAll()
        persistedEvidence.removeAll()
    }

    func deleteAllPractice() async throws {
        persistedSession = nil
        persistedTurns.removeAll()
        persistedEvidence.removeAll()
    }

    func resetAllLearningProgress() async throws {
        try await deleteAllPractice()
    }
}

private final class CoordinatorTestAI: PracticeAIProtocol, @unchecked Sendable {
    var requests: [PracticeAIRequest] = []
    var capabilityOverride: PracticeCapability?
    var responseOverride: PracticeAIResponse?
    var onRespond: (@Sendable (PracticeAIRequest) async throws -> Void)?

    func capability() async -> PracticeCapability {
        capabilityOverride ?? PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: true,
            canCaptureSpeech: true,
            canPlaySpeech: true,
            providerIdentity: "test-ai-provider"
        )
    }

    func respond(to request: PracticeAIRequest) async throws -> PracticeAIResponse {
        requests.append(request)
        if let onRespond {
            try await onRespond(request)
        }
        if let responseOverride {
            return responseOverride
        }
        return PracticeAIResponse(
            characterReply: "Hello, welcome to our restaurant!",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: request.mission.targetWordIds.first ?? 101,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: request.acceptedTurns.last?.acceptedText
                )
            ],
            coachFeedback: "Great job ordering food!",
            hintCandidate: nil
        )
    }
}

private final class CoordinatorTestSpeech: PracticeSpeechProtocol, @unchecked Sendable {
    var capabilityOverride: PracticeCapability?
    var captureContinuation: AsyncThrowingStream<PracticeSpeechEvent, Error>.Continuation?
    var playContinuation: AsyncThrowingStream<PracticeSpeechEvent, Error>.Continuation?
    var stopCallCount: Int = 0
    var playedTexts: [String] = []

    func capability() -> PracticeCapability {
        capabilityOverride ?? PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: true,
            canCaptureSpeech: true,
            canPlaySpeech: true,
            providerIdentity: "test-speech-engine"
        )
    }

    func capture(locale: String) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        AsyncThrowingStream { continuation in
            self.captureContinuation = continuation
        }
    }

    func play(text: String, voice: VoiceConfiguration) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        playedTexts.append(text)
        return AsyncThrowingStream { continuation in
            self.playContinuation = continuation
            continuation.yield(.playbackStarted)
            continuation.yield(.playbackFinished)
            continuation.finish()
        }
    }

    func stop() async {
        stopCallCount += 1
        captureContinuation?.finish()
        captureContinuation = nil
        playContinuation?.finish()
        playContinuation = nil
    }
}

// MARK: - Suite

@Suite("Practice Session Coordinator Concurrency, Checkpoints & Turn Transactions")
@MainActor
struct PracticeSessionCoordinatorTests {
    private func makeSUT(
        canAssessUsage: Bool = true,
        canPlaySpeech: Bool = true
    ) -> (
        coordinator: PracticeSessionCoordinator,
        repo: CoordinatorTestRepository,
        aiProvider: CoordinatorTestAI,
        speech: CoordinatorTestSpeech,
        clock: ManualPracticeClock
    ) {
        let repo = CoordinatorTestRepository()
        let aiProvider = CoordinatorTestAI()
        aiProvider.capabilityOverride = PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: canAssessUsage,
            canCaptureSpeech: true,
            canPlaySpeech: canPlaySpeech,
            providerIdentity: "test-provider"
        )
        let speech = CoordinatorTestSpeech()
        speech.capabilityOverride = PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: canAssessUsage,
            canCaptureSpeech: true,
            canPlaySpeech: canPlaySpeech,
            providerIdentity: "test-speech"
        )
        let clock = ManualPracticeClock(initialDate: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = PracticeSessionCoordinator(
            repository: repo,
            ai: aiProvider,
            speech: speech,
            clock: clock,
            policy: .v1
        )
        return (coordinator, repo, aiProvider, speech, clock)
    }

    // MARK: - Mandatory Standard Test Case

    @Test("doubleSubmitUsesOnePendingTurn")
    func doubleSubmitUsesOnePendingTurn() async throws {
        let (coordinator, repo, aiProvider, _, _) = makeSUT()
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        // Block AI response until signalled
        let gate = Gate()
        aiProvider.onRespond = { _ in
            await gate.wait()
        }

        // Fire first submit asynchronously
        let task1 = Task {
            await coordinator.submit(text: "I want pasta", mode: .voice)
        }

        // Yield to allow first submit to reach .processing state
        await Task.yield()

        // Fire second submit while first is still pending in .processing
        let task2 = Task {
            await coordinator.submit(text: "I want pasta again", mode: .voice)
        }

        // Release the gate
        gate.open()

        await task1.value
        await task2.value

        let persistedUserTurns = repo.savedPendingTurns.map(\.turn).filter { $0.speaker == .learner }
        let aiRequestCount = aiProvider.requests.count

        // Mandatory standard assertions:
        #expect(persistedUserTurns.count == 1)
        #expect(aiRequestCount == 1)
    }

    @Test("savePendingTurnOccursBeforeCallingAI")
    func savePendingTurnOccursBeforeCallingAI() async throws {
        let (coordinator, repo, aiProvider, _, _) = makeSUT()
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        final class OrderLog: @unchecked Sendable {
            private let lock = NSLock()
            private var entries: [String] = []

            func append(_ item: String) {
                lock.lock()
                defer { lock.unlock() }
                entries.append(item)
            }

            var items: [String] {
                lock.lock()
                defer { lock.unlock() }
                return entries
            }
        }

        let orderLog = OrderLog()
        repo.onSavePendingTurn = { _ in
            orderLog.append("savePendingTurn")
        }
        aiProvider.onRespond = { _ in
            orderLog.append("aiRespond")
        }

        await coordinator.submit(text: "I want pasta", mode: .voice)

        #expect(orderLog.items == ["savePendingTurn", "aiRespond"])
    }

    @Test("commitOccursBeforeNextTurn")
    func commitOccursBeforeNextTurn() async throws {
        let (coordinator, repo, _, _, _) = makeSUT()
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        await coordinator.submit(text: "I want pasta", mode: .voice)

        #expect(repo.commits.count == 1)
        #expect(coordinator.state == .awaitingLearner)
    }

    @Test("switchInputPreservesOriginalModeAndTurns")
    func switchInputPreservesOriginalModeAndTurns() async throws {
        let (coordinator, repo, _, _, _) = makeSUT()
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        await coordinator.submit(text: "I want pasta", mode: .voice)

        await coordinator.switchInput(to: .typed)

        #expect(coordinator.currentInputMode == .typed)
        #expect(coordinator.session?.initialInputMode == .voice)
        #expect(coordinator.turns.first?.inputMode == .voice)
        #expect(repo.revisions.count == 1)
    }

    @Test("staleOperationTokenRejectsCommit")
    func staleOperationTokenRejectsCommit() async throws {
        let (coordinator, repo, aiProvider, _, _) = makeSUT()
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        let gate = Gate()
        aiProvider.onRespond = { _ in
            await gate.wait()
        }

        let submitTask = Task {
            await coordinator.submit(text: "I want pasta", mode: .voice)
        }

        await Task.yield()

        // Pause while AI is processing -> changes token and state to .paused
        await coordinator.pause()

        // Release AI gate
        gate.open()
        await submitTask.value

        // Rejection: AI response should NOT commit
        #expect(repo.commits.isEmpty)
        #expect(coordinator.state == .paused)
    }

    @Test("promptContainsAtMostEightAcceptedTurns")
    func promptContainsAtMostEightAcceptedTurns() async throws {
        let (coordinator, repo, aiProvider, _, _) = makeSUT()
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        // Prepopulate repo with 10 turns
        var preloadedTurns: [PracticeTurn] = []
        for index in 1...10 {
            preloadedTurns.append(
                PracticeTurn(
                    id: UUID(),
                    sessionId: coordinator.session!.id,
                    sequence: index,
                    speaker: .learner,
                    inputMode: .voice,
                    originalText: "Turn \(index)",
                    acceptedText: "Turn \(index)",
                    requestId: "req-\(index)",
                    timestamp: Date()
                )
            )
        }
        repo.persistedTurns = preloadedTurns
        // Sync coordinator local turns
        let snap = try await repo.loadSession(id: coordinator.session!.id)!
        coordinator.syncFromSnapshot(snap)

        await coordinator.submit(text: "Turn 11", mode: .voice)

        let request = try #require(aiProvider.requests.first)
        #expect(request.acceptedTurns.count == 8)
        #expect(request.acceptedTurns.last?.acceptedText == "Turn 11")
    }

    @Test("partialCompletionDoesNotFailUnattemptedObjectives")
    func partialCompletionDoesNotFailUnattemptedObjectives() async throws {
        let (coordinator, _, _, _, _) = makeSUT()
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        // Objectives in fixture mission are ["order_food", "ask_bill"]
        await coordinator.submit(text: "I want pasta", mode: .voice)

        let summary = await coordinator.finish(.partial)

        let verifiedSummary = try #require(summary)
        #expect(verifiedSummary.status == .partial)
        let askBill = verifiedSummary.objectiveResults.first { $0.objectiveId == "ask_bill" }
        // Should not be marked as a failed observed opportunity
        #expect(askBill?.opportunityObserved == false || askBill?.intentVerdict != .notYet)
    }

    @Test("doubleFinishReturnsIdenticalSummaryAndNoXPWrites")
    func doubleFinishReturnsIdenticalSummaryAndNoXPWrites() async throws {
        let (coordinator, repo, _, _, _) = makeSUT()
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        let summary1 = await coordinator.finish(.completed)
        let summary2 = await coordinator.finish(.completed)

        #expect(summary1 == summary2)
        #expect(repo.finalizations.count == 1)
        #expect(coordinator.state == .completed)
    }

    @Test("canAssessUsageFalseDoesNotFabricateWordEvidence")
    func canAssessUsageFalseDoesNotFabricateWordEvidence() async throws {
        let (coordinator, repo, _, _, _) = makeSUT(canAssessUsage: false)
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        await coordinator.submit(text: "I want pasta", mode: .voice)

        let commit = try #require(repo.commits.first)
        #expect(commit.assessment?.evidence.isEmpty == true)
        #expect(repo.persistedEvidence.isEmpty)
    }

    @Test("committedEvidenceRetainsActiveProviderIdentity")
    func committedEvidenceRetainsActiveProviderIdentity() async throws {
        let (coordinator, repo, _, _, _) = makeSUT(canAssessUsage: true)
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        await coordinator.submit(text: "I want pasta", mode: .voice)

        let committedEvidence = try #require(repo.commits.first?.assessment?.evidence)
        #expect(!committedEvidence.isEmpty)
        #expect(committedEvidence.first?.providerIdentity == "test-provider")
        #expect(repo.persistedEvidence.first?.providerIdentity == "test-provider")
    }

    @Test("voiceCaptureStreamsTranscripts")
    func voiceCaptureStreamsTranscripts() async throws {
        let (coordinator, repo, _, speech, _) = makeSUT()
        let mission = try PracticeFixtures.mission(wordIds: [101])
        await coordinator.start(mission: mission, mode: .voice)

        await coordinator.startCapture()
        #expect(coordinator.state == .capturing)

        speech.captureContinuation?.yield(.transcript(text: "I would like some water", reliability: .usable))
        for _ in 0..<10 {
            await Task.yield()
        }

        #expect(coordinator.activeTurnText == "I would like some water")

        await coordinator.finishCapture()

        #expect(repo.savedPendingTurns.last?.turn.originalText == "I would like some water")
        #expect(repo.savedPendingTurns.last?.turn.inputMode == .voice)
    }
}

// MARK: - Concurrency Test Gate Helper

private final class Gate: @unchecked Sendable {
    private let lock = NSLock()
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            if isOpen {
                lock.unlock()
                continuation.resume()
            } else {
                waiters.append(continuation)
                lock.unlock()
            }
        }
    }

    func open() {
        lock.lock()
        isOpen = true
        let continuations = waiters
        waiters.removeAll()
        lock.unlock()
        for continuation in continuations {
            continuation.resume()
        }
    }
}
