import Foundation

// MARK: - Session Recovery, Modification & Safe Deletion

extension PracticeSessionCoordinator {
    /// Resumes an existing practice session from repository snapshot.
    ///
    /// Guarantees that audio capture/recording is NOT automatically re-engaged upon resumption.
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

    /// Retries a pending learner turn if one is recorded in the session checkpoint or turns history.
    public func retryPendingTurn() async {
        guard let session = self.session else { return }

        let pendingTurn: PracticeTurn
        if let pendingTurnId = session.checkpoint.pendingTurnId,
           let turn = turns.first(where: { $0.id == pendingTurnId }) {
            pendingTurn = turn
        } else if let lastTurn = turns.last, lastTurn.generationStatus == .pending {
            pendingTurn = lastTurn
        } else {
            return
        }

        await stopActiveAudio()
        self.state = .processing
        self.failure = nil

        let token = PracticeOperationToken(
            sessionId: session.id,
            requestId: pendingTurn.requestId,
            revision: session.revision
        )
        self.activeOperationToken = token

        let aiCapability = await ai.capability()
        guard self.activeOperationToken == token else { return }

        let aiRequest = PracticeAIRequest(
            mission: session.missionSnapshot,
            acceptedTurns: Array(self.turns.suffix(8)),
            supportBudget: self.currentSupport,
            providerIdentity: aiCapability.providerIdentity
        )

        guard let aiResponse = await queryAI(request: aiRequest, token: token) else { return }
        guard let assessment = validateAssessmentSafely(
            aiResponse: aiResponse,
            request: aiRequest,
            learnerTurn: pendingTurn,
            token: token,
            canAssessUsage: aiCapability.canAssessUsage
        ) else { return }

        guard await commitTurn(
            learnerTurn: pendingTurn,
            aiResponse: aiResponse,
            assessment: assessment,
            token: token
        ) else { return }

        await playCharacterSpeechIfSupported(reply: aiResponse.characterReply, token: token)
        await handleCoachFeedback(coachFeedback: aiResponse.coachFeedback, token: token)
    }

    /// Retries committing a previously failed turn commit or save.
    public func retrySave() async {
        if let failedCommit = self.lastFailedCommit {
            self.state = .saving
            self.failure = nil
            do {
                let snapshot = try await repository.commit(failedCommit)
                self.lastFailedCommit = nil
                self.session = snapshot.session
                self.turns = snapshot.turns
                self.exposures = snapshot.exposures
                self.pendingPresentations = snapshot.pendingPresentations
                self.activeTurnText = ""
                self.state = .awaitingLearner
            } catch {
                setFailure(error, code: .storage)
            }
        } else if session?.checkpoint.pendingTurnId != nil || turns.last?.generationStatus == .pending {
            await retryPendingTurn()
        }
    }

    /// Replaces the transcript of a learner turn, superseding older evidence and re-evaluating under `.editedTranscript`.
    public func replaceTranscript(turnId: UUID, text: String) async {
        guard let session = self.session else { return }
        guard let turnIndex = turns.firstIndex(where: { $0.id == turnId && $0.speaker == .learner }) else { return }
        let existingTurn = turns[turnIndex]

        await stopActiveAudio()
        self.failure = nil

        let newRevision: Int
        do {
            newRevision = try await repository.revise(
                sessionId: session.id,
                expectedRevision: session.revision,
                checkpoint: session.checkpoint
            )
            self.session = PracticeSession(
                id: session.id,
                missionSnapshot: session.missionSnapshot,
                status: session.status,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                checkpoint: session.checkpoint,
                revision: newRevision,
                initialInputMode: session.initialInputMode,
                policyVersion: session.policyVersion
            )
        } catch {
            setFailure(error, code: .storage)
            return
        }

        let updatedTurn = PracticeTurn(
            id: existingTurn.id,
            sessionId: existingTurn.sessionId,
            sequence: existingTurn.sequence,
            speaker: .learner,
            inputMode: .editedTranscript,
            originalText: existingTurn.originalText,
            acceptedText: text,
            transcriptStatus: .edited,
            generationStatus: .succeeded,
            requestId: UUID().uuidString,
            sessionRevision: newRevision,
            timestamp: clock.now()
        )
        self.turns[turnIndex] = updatedTurn

        self.state = .processing
        let token = PracticeOperationToken(
            sessionId: session.id,
            requestId: updatedTurn.requestId,
            revision: newRevision
        )
        self.activeOperationToken = token

        let aiCapability = await ai.capability()
        guard self.activeOperationToken == token else { return }

        let aiRequest = PracticeAIRequest(
            mission: session.missionSnapshot,
            acceptedTurns: Array(self.turns.prefix(through: turnIndex)),
            supportBudget: self.currentSupport,
            providerIdentity: aiCapability.providerIdentity
        )

        guard let aiResponse = await queryAI(request: aiRequest, token: token) else { return }
        guard let assessment = validateAssessmentSafely(
            aiResponse: aiResponse,
            request: aiRequest,
            learnerTurn: updatedTurn,
            token: token,
            canAssessUsage: aiCapability.canAssessUsage
        ) else { return }

        guard await commitTurn(
            learnerTurn: updatedTurn,
            aiResponse: aiResponse,
            assessment: assessment,
            token: token
        ) else { return }

        self.state = .awaitingLearner
    }

    /// Switches the active AI provider, bumping revision and invalidating in-flight tasks from the old provider.
    public func switchProvider(to newAI: any PracticeAIProtocol) async {
        await stopActiveAudio()
        self.activeOperationToken = nil
        self.ai = newAI

        guard let session = self.session else { return }
        do {
            let newRevision = try await repository.revise(
                sessionId: session.id,
                expectedRevision: session.revision,
                checkpoint: session.checkpoint
            )
            self.session = PracticeSession(
                id: session.id,
                missionSnapshot: session.missionSnapshot,
                status: session.status,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                checkpoint: session.checkpoint,
                revision: newRevision,
                initialInputMode: session.initialInputMode,
                policyVersion: session.policyVersion
            )
        } catch {
            setFailure(error, code: .storage)
        }
    }

    /// Safely deletes the current practice session, removes temporary audio files, and resets coordinator state.
    public func deleteCurrentSession() async {
        self.activeOperationToken = nil
        await stopActiveAudio()

        if let session = self.session {
            try? privacyStore.removeTemporaryAudio(sessionId: session.id)
            do {
                try await repository.deleteSession(id: session.id)
            } catch {
                setFailure(error, code: .storage)
            }
        }
        resetState()
    }
}
