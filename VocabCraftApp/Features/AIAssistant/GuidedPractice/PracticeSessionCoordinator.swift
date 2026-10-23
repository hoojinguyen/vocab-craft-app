import Foundation
import Observation

/// Primary single owner of guided practice session state, transactions, and ongoing operations.
@Observable
@MainActor
public final class PracticeSessionCoordinator {
    // MARK: - Observable State

    public private(set) var state: PracticeSessionState = .preparing
    public private(set) var session: PracticeSession?
    public private(set) var turns: [PracticeTurn] = []
    public private(set) var exposures: [SupportExposure] = []
    public private(set) var currentSupport: PracticeSupportLevel = .none
    public private(set) var currentInputMode: PracticeInputMode = .voice
    public private(set) var summary: PracticeSummary?
    public private(set) var failure: PracticeFailure?
    public var activeTurnText: String = ""
    public private(set) var characterReply: String = ""
    public private(set) var coachFeedback: String?
    public private(set) var activeOperationToken: PracticeOperationToken?

    // MARK: - Injected Dependencies

    public let repository: any PracticeRepositoryProtocol
    // swiftlint:disable:next identifier_name
    public let ai: any PracticeAIProtocol
    public let speech: any PracticeSpeechProtocol
    public let clock: any PracticeClock
    public let policy: PracticePolicyConfiguration

    private let validator: AssessPracticeTurnUseCase
    private let supportPolicy: SupportPolicy
    private let difficultyPolicy: PracticeDifficultyPolicy

    // MARK: - Task Handles

    private var captureTask: Task<Void, Never>?
    private var playbackTask: Task<Void, Never>?

    // MARK: - Initializer

    public init(
        repository: any PracticeRepositoryProtocol,
        // swiftlint:disable:next identifier_name
        ai: any PracticeAIProtocol,
        speech: any PracticeSpeechProtocol,
        clock: any PracticeClock,
        policy: PracticePolicyConfiguration = .v1,
        supportPolicy: SupportPolicy = SupportPolicy(),
        difficultyPolicy: PracticeDifficultyPolicy = PracticeDifficultyPolicy()
    ) {
        self.repository = repository
        self.ai = ai
        self.speech = speech
        self.clock = clock
        self.policy = policy
        self.supportPolicy = supportPolicy
        self.difficultyPolicy = difficultyPolicy
        self.validator = AssessPracticeTurnUseCase(supportPolicy: supportPolicy)
    }

    // MARK: - Session Lifecycle

    /// Begins a new guided practice session with the specified mission and initial input modality.
    public func start(mission: PracticeMission, mode: PracticeInputMode = .voice) async {
        await stopActiveAudio()
        resetState(mode: mode)

        let initialCheckpoint = PracticeCheckpoint(
            pendingTurnId: nil,
            requestId: nil,
            presentationIntents: [],
            exposureUncertainWordIds: [],
            currentSupportLevel: .none,
            objectiveResults: mission.objectiveIds.map {
                PracticeObjectiveResult(objectiveId: $0, intentVerdict: .notYet, opportunityObserved: false)
            },
            difficultyOutcomes: []
        )

        let newSession = PracticeSession(
            id: UUID(),
            missionSnapshot: mission,
            status: .inProgress,
            startedAt: clock.now(),
            completedAt: nil,
            checkpoint: initialCheckpoint,
            revision: 1,
            initialInputMode: mode,
            policyVersion: policy.version
        )

        do {
            try await repository.create(newSession)
            self.session = newSession
            self.state = .awaitingLearner
        } catch {
            setFailure(error, code: .storage)
        }
    }

    /// Resumes an existing practice session from repository snapshot.
    public func resume(sessionId: UUID) async {
        await stopActiveAudio()
        self.failure = nil
        self.summary = nil
        self.state = .preparing
        do {
            guard let snapshot = try await repository.loadSession(id: sessionId) else {
                throw PracticeFailure(code: .storage, message: "Session \(sessionId) not found")
            }
            syncFromSnapshot(snapshot)
            switch snapshot.session.status {
            case .completed:
                self.state = .completed
            case .partial:
                self.state = .partial
            case .abandoned:
                self.state = .recoverableError
            case .inProgress:
                self.state = .awaitingLearner
            }
        } catch {
            setFailure(error, code: .storage)
        }
    }

    /// Synchronizes in-memory coordinator properties with a persisted snapshot.
    public func syncFromSnapshot(_ snapshot: PracticeSessionSnapshot) {
        self.session = snapshot.session
        self.turns = snapshot.turns
        self.exposures = snapshot.exposures
        self.currentSupport = snapshot.session.checkpoint.currentSupportLevel
        self.currentInputMode = snapshot.session.initialInputMode
    }

    // MARK: - Turn Execution & Commits

    /// Submits learner utterance, coordinates pending checkpoint durability, queries AI, and commits evaluation.
    public func submit(text: String, mode: PracticeInputMode) async {
        guard let session = self.session,
              state != .processing,
              state != .saving,
              state != .completed,
              state != .partial else {
            return
        }

        self.state = .processing
        self.failure = nil

        let requestId = UUID().uuidString
        let token = PracticeOperationToken(sessionId: session.id, requestId: requestId, revision: session.revision)
        self.activeOperationToken = token

        let learnerTurn = makeLearnerTurn(text: text, mode: mode, requestId: requestId, session: session)
        guard await persistPendingTurn(learnerTurn, requestId: requestId, session: session, token: token) else { return }

        let aiCapability = await ai.capability()
        guard self.activeOperationToken == token else { return }

        let aiRequest = PracticeAIRequest(
            mission: session.missionSnapshot,
            acceptedTurns: Array((self.turns + [learnerTurn]).suffix(8)),
            supportBudget: self.currentSupport,
            providerIdentity: aiCapability.providerIdentity
        )

        guard let aiResponse = await queryAI(request: aiRequest, token: token) else { return }
        guard let assessment = validateAssessmentSafely(
            aiResponse: aiResponse,
            request: aiRequest,
            learnerTurn: learnerTurn,
            token: token,
            canAssessUsage: aiCapability.canAssessUsage
        ) else { return }

        guard await commitTurn(learnerTurn: learnerTurn, aiResponse: aiResponse, assessment: assessment, token: token) else { return }

        await playCharacterSpeechIfSupported(reply: aiResponse.characterReply, token: token)
        await handleCoachFeedback(coachFeedback: aiResponse.coachFeedback, token: token)
    }

    // MARK: - Speech & Audio Controls

    /// Initiates speech recognition capture and streams transcripts into activeTurnText.
    public func startCapture() async {
        guard state == .awaitingLearner else { return }
        self.state = .capturing
        self.activeTurnText = ""

        captureTask?.cancel()
        let stream = speech.capture(locale: "en-US")
        captureTask = Task { [weak self] in
            do {
                for try await event in stream {
                    guard !Task.isCancelled, let self else { break }
                    if case .transcript(let text, _) = event {
                        self.activeTurnText = text
                    }
                }
            } catch {
                self?.setFailure(error, code: .audio)
            }
        }
    }

    /// Stops audio capture and submits the transcribed utterance as a voice turn.
    public func finishCapture() async {
        guard state == .capturing else { return }
        captureTask?.cancel()
        captureTask = nil
        await speech.stop()
        let textToSubmit = activeTurnText
        await submit(text: textToSubmit, mode: .voice)
    }

    /// Pauses audio activity and puts the session state into .paused.
    public func pause() async {
        await stopActiveAudio()
        self.activeOperationToken = nil
        self.state = .paused
    }

    /// Switches the active input modality without mutating past turns or initial session input mode.
    public func switchInput(to mode: PracticeInputMode) async {
        guard currentInputMode != mode else { return }
        await stopActiveAudio()
        self.activeOperationToken = nil

        if let session = self.session {
            if let newRev = try? await repository.revise(
                sessionId: session.id,
                expectedRevision: session.revision,
                checkpoint: session.checkpoint
            ) {
                self.session = PracticeSession(
                    id: session.id,
                    missionSnapshot: session.missionSnapshot,
                    status: session.status,
                    startedAt: session.startedAt,
                    completedAt: session.completedAt,
                    checkpoint: session.checkpoint,
                    revision: newRev,
                    initialInputMode: session.initialInputMode,
                    policyVersion: session.policyVersion
                )
            }
        }

        self.currentInputMode = mode
        if state == .capturing {
            self.state = .awaitingLearner
        }
    }

    // MARK: - Finalization

    /// Finalizes the practice session as completed or partial, returning a summary report.
    @discardableResult
    public func finish(_ completion: PracticeCompletion) async -> PracticeSummary? {
        if let existingSummary = self.summary {
            return existingSummary
        }
        guard let session = self.session else { return nil }

        await stopActiveAudio()
        self.activeOperationToken = nil
        self.state = .saving

        do {
            let finalSummary = try await repository.finalize(
                sessionId: session.id,
                completion: completion,
                expectedRevision: session.revision
            )
            self.summary = finalSummary
            self.state = (completion == .completed) ? .completed : .partial
            return finalSummary
        } catch {
            setFailure(error, code: .storage)
            return nil
        }
    }
}

// MARK: - Private Processing Helpers

extension PracticeSessionCoordinator {
    private func resetState(mode: PracticeInputMode) {
        self.failure = nil
        self.summary = nil
        self.activeTurnText = ""
        self.characterReply = ""
        self.coachFeedback = nil
        self.currentInputMode = mode
        self.currentSupport = .none
        self.turns = []
        self.exposures = []
        self.state = .preparing
    }

    private func makeLearnerTurn(
        text: String,
        mode: PracticeInputMode,
        requestId: String,
        session: PracticeSession
    ) -> PracticeTurn {
        let nextSequence = (turns.map(\.sequence).max() ?? 0) + 1
        return PracticeTurn(
            id: UUID(),
            sessionId: session.id,
            sequence: nextSequence,
            speaker: .learner,
            inputMode: mode,
            originalText: text,
            acceptedText: text,
            transcriptStatus: mode == .voice ? .final : .notApplicable,
            generationStatus: .pending,
            requestId: requestId,
            sessionRevision: session.revision,
            timestamp: clock.now()
        )
    }

    private func persistPendingTurn(
        _ turn: PracticeTurn,
        requestId: String,
        session: PracticeSession,
        token: PracticeOperationToken
    ) async -> Bool {
        let pendingCheckpoint = PracticeCheckpoint(
            pendingTurnId: turn.id,
            requestId: requestId,
            presentationIntents: session.checkpoint.presentationIntents,
            exposureUncertainWordIds: session.checkpoint.exposureUncertainWordIds,
            currentSupportLevel: self.currentSupport,
            objectiveResults: session.checkpoint.objectiveResults,
            difficultyOutcomes: session.checkpoint.difficultyOutcomes
        )

        do {
            try await repository.savePendingTurn(turn, checkpoint: pendingCheckpoint, expectedRevision: session.revision)
        } catch {
            guard self.activeOperationToken == token else { return false }
            setFailure(error, code: .storage)
            return false
        }

        return self.activeOperationToken == token
    }

    private func queryAI(
        request: PracticeAIRequest,
        token: PracticeOperationToken
    ) async -> PracticeAIResponse? {
        do {
            let response = try await ai.respond(to: request)
            guard self.activeOperationToken == token else { return nil }
            return response
        } catch {
            guard self.activeOperationToken == token else { return nil }
            setFailure(error, code: .network)
            return nil
        }
    }

    private func validateAssessmentSafely(
        aiResponse: PracticeAIResponse,
        request: PracticeAIRequest,
        learnerTurn: PracticeTurn,
        token: PracticeOperationToken,
        canAssessUsage: Bool
    ) -> PracticeAssessment? {
        guard canAssessUsage else {
            return PracticeAssessment(evidence: [], objectiveResults: [], response: aiResponse)
        }

        let uncertainWordIds = self.session?.checkpoint.exposureUncertainWordIds ?? []
        do {
            return try validator.validate(
                response: aiResponse,
                request: request,
                turn: learnerTurn,
                exposures: self.exposures,
                uncertainWordIds: uncertainWordIds
            )
        } catch {
            guard self.activeOperationToken == token else { return nil }
            setFailure(error, code: .domainValidation)
            return nil
        }
    }

    private func commitTurn(
        learnerTurn: PracticeTurn,
        aiResponse: PracticeAIResponse,
        assessment: PracticeAssessment,
        token: PracticeOperationToken
    ) async -> Bool {
        guard let session = self.session else { return false }
        let completedTurn = PracticeTurn(
            id: learnerTurn.id,
            sessionId: learnerTurn.sessionId,
            sequence: learnerTurn.sequence,
            speaker: .learner,
            inputMode: learnerTurn.inputMode,
            originalText: learnerTurn.originalText,
            acceptedText: learnerTurn.acceptedText,
            transcriptStatus: learnerTurn.transcriptStatus,
            generationStatus: .succeeded,
            requestId: learnerTurn.requestId,
            sessionRevision: learnerTurn.sessionRevision,
            timestamp: learnerTurn.timestamp
        )

        var updatedObjectiveResults = session.checkpoint.objectiveResults
        for newResult in assessment.objectiveResults {
            if let index = updatedObjectiveResults.firstIndex(where: { $0.objectiveId == newResult.objectiveId }) {
                updatedObjectiveResults[index] = newResult
            } else {
                updatedObjectiveResults.append(newResult)
            }
        }

        let nextCheckpoint = PracticeCheckpoint(
            pendingTurnId: nil,
            requestId: token.requestId,
            presentationIntents: session.checkpoint.presentationIntents,
            exposureUncertainWordIds: session.checkpoint.exposureUncertainWordIds,
            currentSupportLevel: self.currentSupport,
            objectiveResults: updatedObjectiveResults,
            difficultyOutcomes: session.checkpoint.difficultyOutcomes
        )

        let commitPayload = PracticeCommit(
            sessionId: session.id,
            expectedRevision: session.revision,
            turn: completedTurn,
            assessment: assessment,
            checkpoint: nextCheckpoint
        )

        do {
            let snapshot = try await repository.commit(commitPayload)
            guard self.activeOperationToken == token else { return false }
            self.session = snapshot.session
            self.turns = snapshot.turns
            self.exposures = snapshot.exposures
            self.characterReply = aiResponse.characterReply
            self.coachFeedback = aiResponse.coachFeedback
            self.activeTurnText = ""
            return true
        } catch {
            guard self.activeOperationToken == token else { return false }
            setFailure(error, code: .storage)
            return false
        }
    }

    private func playCharacterSpeechIfSupported(reply: String, token: PracticeOperationToken) async {
        guard self.activeOperationToken == token else { return }
        let speechCapability = speech.capability()
        guard speechCapability.canPlaySpeech, !reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        self.state = .playingCharacter
        let voice = VoiceConfiguration(gender: .female, style: .friendly)
        let stream = speech.play(text: reply, voice: voice)
        do {
            for try await event in stream {
                guard self.activeOperationToken == token else {
                    await speech.stop()
                    return
                }
                if case .playbackFinished = event { break }
            }
        } catch {
            // Audio error non-fatal to session progress
        }
    }

    private func handleCoachFeedback(coachFeedback: String?, token: PracticeOperationToken) async {
        guard self.activeOperationToken == token else { return }
        if let feedback = coachFeedback, !feedback.isEmpty {
            self.state = .coaching
            await Task.yield()
            guard self.activeOperationToken == token else { return }
            self.state = .awaitingLearner
        } else {
            self.state = .awaitingLearner
        }
    }

    private func setFailure(_ error: Error, code: PracticeFailure.Code) {
        self.state = .recoverableError
        self.failure = (error as? PracticeFailure) ?? PracticeFailure(
            code: code,
            message: error.localizedDescription
        )
    }

    private func stopActiveAudio() async {
        captureTask?.cancel()
        captureTask = nil
        playbackTask?.cancel()
        playbackTask = nil
        await speech.stop()
    }
}
