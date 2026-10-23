import Foundation

// MARK: - Presentation Intent & Assistance Scaffolding

extension PracticeSessionCoordinator {
    /// Durably registers a presentation intent prior to UI rendering or audio playback.
    ///
    /// If persistence fails, returns `nil` to prevent UI from presenting untracked content.
    @discardableResult
    public func preparePresentation(
        content: String,
        channel: PracticePresentationChannel,
        origin: SupportOrigin,
        wordIds: Set<Int64>,
        level: PracticeSupportLevel,
        turnId: UUID? = nil
    ) async -> PracticePresentationIntent? {
        guard let session = self.session else { return nil }

        // Conservative mapping: if wordIds is empty, prime all mission target words.
        let targetWordIds: Set<Int64> = wordIds.isEmpty
            ? Set(session.missionSnapshot.targetWordIds)
            : wordIds

        let currentTurnId = turnId ?? session.checkpoint.pendingTurnId ?? turns.last?.id
        let intent = PracticePresentationIntent(
            id: UUID(),
            sessionId: session.id,
            turnId: currentTurnId,
            content: content,
            channel: channel,
            possibleWordIds: Array(targetWordIds).sorted(),
            proposedLevel: level,
            status: .pending,
            origin: origin
        )

        do {
            try await repository.preparePresentation(intent, expectedRevision: session.revision)
        } catch {
            return nil
        }

        self.pendingPresentations.removeAll { $0.id == intent.id }
        self.pendingPresentations.append(intent)

        var updatedIntents = session.checkpoint.presentationIntents.filter { $0.id != intent.id }
        updatedIntents.append(intent)

        let updatedCheckpoint = PracticeCheckpoint(
            pendingTurnId: session.checkpoint.pendingTurnId,
            requestId: session.checkpoint.requestId,
            presentationIntents: updatedIntents,
            exposureUncertainWordIds: session.checkpoint.exposureUncertainWordIds,
            currentSupportLevel: session.checkpoint.currentSupportLevel,
            objectiveResults: session.checkpoint.objectiveResults,
            difficultyOutcomes: session.checkpoint.difficultyOutcomes
        )

        self.session = PracticeSession(
            id: session.id,
            missionSnapshot: session.missionSnapshot,
            status: session.status,
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            checkpoint: updatedCheckpoint,
            revision: session.revision,
            initialInputMode: session.initialInputMode,
            policyVersion: session.policyVersion
        )

        return intent
    }

    /// Confirms that a previously prepared presentation intent was rendered or played to the learner.
    public func confirmPresented(intentId: UUID, at presentationDate: Date) async {
        guard let session = self.session else { return }
        guard let intent = self.pendingPresentations.first(where: { $0.id == intentId }) ??
              session.checkpoint.presentationIntents.first(where: { $0.id == intentId }) else {
            return
        }

        let exposure = SupportExposure(
            id: UUID(),
            sessionId: session.id,
            turnId: intent.turnId,
            wordIds: intent.possibleWordIds,
            level: intent.proposedLevel,
            origin: intent.origin,
            contentSnapshot: intent.content,
            presentedAt: presentationDate,
            channel: intent.channel
        )

        do {
            try await repository.confirmPresentation(
                id: intentId,
                exposure: exposure,
                expectedRevision: session.revision
            )
            applySuccessfulConfirmation(intentId: intentId, exposure: exposure, session: session)
        } catch {
            await applyFailedConfirmation(intent: intent, session: session)
        }
    }

    private func applySuccessfulConfirmation(intentId: UUID, exposure: SupportExposure, session: PracticeSession) {
        self.exposures.append(exposure)
        self.pendingPresentations.removeAll { $0.id == intentId }

        let remainingIntents = session.checkpoint.presentationIntents.filter { $0.id != intentId }
        let updatedCheckpoint = PracticeCheckpoint(
            pendingTurnId: session.checkpoint.pendingTurnId,
            requestId: session.checkpoint.requestId,
            presentationIntents: remainingIntents,
            exposureUncertainWordIds: session.checkpoint.exposureUncertainWordIds,
            currentSupportLevel: session.checkpoint.currentSupportLevel,
            objectiveResults: session.checkpoint.objectiveResults,
            difficultyOutcomes: session.checkpoint.difficultyOutcomes
        )

        self.session = PracticeSession(
            id: session.id,
            missionSnapshot: session.missionSnapshot,
            status: session.status,
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            checkpoint: updatedCheckpoint,
            revision: session.revision,
            initialInputMode: session.initialInputMode,
            policyVersion: session.policyVersion
        )
    }

    private func applyFailedConfirmation(intent: PracticePresentationIntent, session: PracticeSession) async {
        let updatedUncertain = session.checkpoint.exposureUncertainWordIds.union(intent.possibleWordIds)
        let updatedCheckpoint = PracticeCheckpoint(
            pendingTurnId: session.checkpoint.pendingTurnId,
            requestId: session.checkpoint.requestId,
            presentationIntents: session.checkpoint.presentationIntents,
            exposureUncertainWordIds: updatedUncertain,
            currentSupportLevel: session.checkpoint.currentSupportLevel,
            objectiveResults: session.checkpoint.objectiveResults,
            difficultyOutcomes: session.checkpoint.difficultyOutcomes
        )

        let nextRev = try? await repository.revise(
            sessionId: session.id,
            expectedRevision: session.revision,
            checkpoint: updatedCheckpoint
        )

        self.session = PracticeSession(
            id: session.id,
            missionSnapshot: session.missionSnapshot,
            status: session.status,
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            checkpoint: updatedCheckpoint,
            revision: nextRev ?? session.revision,
            initialInputMode: session.initialInputMode,
            policyVersion: session.policyVersion
        )
    }

    /// Requests communicative scaffolding, applying double-tap protection and tier escalation.
    public func requestHelp(fullModel: Bool = false) async {
        guard !isRequestingHelp else { return }
        isRequestingHelp = true
        defer { isRequestingHelp = false }

        guard let session = self.session else { return }

        let targetLevel = fullModel
            ? .model
            : supportPolicy.nextLevel(current: currentSupport, requestFullModel: false)

        self.currentSupport = targetLevel

        let updatedCheckpoint = PracticeCheckpoint(
            pendingTurnId: session.checkpoint.pendingTurnId,
            requestId: session.checkpoint.requestId,
            presentationIntents: session.checkpoint.presentationIntents,
            exposureUncertainWordIds: session.checkpoint.exposureUncertainWordIds,
            currentSupportLevel: targetLevel,
            objectiveResults: session.checkpoint.objectiveResults,
            difficultyOutcomes: session.checkpoint.difficultyOutcomes
        )

        if let nextRev = try? await repository.revise(
            sessionId: session.id,
            expectedRevision: session.revision,
            checkpoint: updatedCheckpoint
        ) {
            self.session = PracticeSession(
                id: session.id,
                missionSnapshot: session.missionSnapshot,
                status: session.status,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                checkpoint: updatedCheckpoint,
                revision: nextRev,
                initialInputMode: session.initialInputMode,
                policyVersion: session.policyVersion
            )
        } else {
            self.session = PracticeSession(
                id: session.id,
                missionSnapshot: session.missionSnapshot,
                status: session.status,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                checkpoint: updatedCheckpoint,
                revision: session.revision,
                initialInputMode: session.initialInputMode,
                policyVersion: session.policyVersion
            )
        }

        let scaffold = makeScaffolding(for: targetLevel, mission: session.missionSnapshot)
        _ = await preparePresentation(
            content: scaffold.content,
            channel: .visual,
            origin: .learnerRequested,
            wordIds: scaffold.wordIds,
            level: targetLevel
        )
    }

    /// Fades assistance down by one tier following a successful supported attempt.
    public func retryWithLessSupport() async {
        guard let session = self.session else { return }
        let fadedLevel = supportPolicy.retryLevel(afterSuccessful: currentSupport)
        self.currentSupport = fadedLevel

        let updatedCheckpoint = PracticeCheckpoint(
            pendingTurnId: session.checkpoint.pendingTurnId,
            requestId: session.checkpoint.requestId,
            presentationIntents: session.checkpoint.presentationIntents,
            exposureUncertainWordIds: session.checkpoint.exposureUncertainWordIds,
            currentSupportLevel: fadedLevel,
            objectiveResults: session.checkpoint.objectiveResults,
            difficultyOutcomes: session.checkpoint.difficultyOutcomes
        )

        if let nextRev = try? await repository.revise(
            sessionId: session.id,
            expectedRevision: session.revision,
            checkpoint: updatedCheckpoint
        ) {
            self.session = PracticeSession(
                id: session.id,
                missionSnapshot: session.missionSnapshot,
                status: session.status,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                checkpoint: updatedCheckpoint,
                revision: nextRev,
                initialInputMode: session.initialInputMode,
                policyVersion: session.policyVersion
            )
        } else {
            self.session = PracticeSession(
                id: session.id,
                missionSnapshot: session.missionSnapshot,
                status: session.status,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                checkpoint: updatedCheckpoint,
                revision: session.revision,
                initialInputMode: session.initialInputMode,
                policyVersion: session.policyVersion
            )
        }
    }

    // MARK: - Scaffolding Construction & Target Detection Helpers

    internal func findTargetWordIds(in text: String, mission: PracticeMission) -> Set<Int64> {
        let normalized = text.lowercased()
        var matched: Set<Int64> = []
        for snapshot in mission.wordSnapshots {
            let lemma = snapshot.lemma.lowercased()
            if normalized.range(of: "\\b\(lemma)\\b", options: .regularExpression) != nil || normalized.contains(lemma) {
                matched.insert(snapshot.wordId)
            }
        }
        return matched
    }

    private func makeScaffolding(
        for level: PracticeSupportLevel,
        mission: PracticeMission
    ) -> (content: String, wordIds: Set<Int64>) {
        let firstSnapshot = mission.wordSnapshots.first
        let targetLemma = firstSnapshot?.lemma ?? "item"
        let allWordIds = Set(mission.targetWordIds)

        switch level {
        case .none:
            return ("", [])
        case .intent:
            return ("Communicate your goal for this situation.", allWordIds)
        case .lexical:
            let wordIdSet: Set<Int64> = firstSnapshot.map { Set([$0.wordId]) } ?? allWordIds
            return ("Vocabulary hint: \(targetLemma)", wordIdSet)
        case .frame:
            let wordIdSet: Set<Int64> = firstSnapshot.map { Set([$0.wordId]) } ?? allWordIds
            return ("Sentence frame: I would like to ___ [\(targetLemma)]", wordIdSet)
        case .model:
            return ("Model: Could I please have the \(targetLemma)?", allWordIds)
        }
    }
}
