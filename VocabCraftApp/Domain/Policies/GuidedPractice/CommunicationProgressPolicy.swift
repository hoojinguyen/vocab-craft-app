import Foundation

/// Pure domain policy deriving communicative competence progress and practice schedules from evidence history.
public struct CommunicationProgressPolicy: Sendable {
    public let configuration: PracticePolicyConfiguration

    public init(configuration: PracticePolicyConfiguration = .v1) {
        self.configuration = configuration
    }

    /// Rebuilds communication progress and next practice scheduling for a specific word and input modality.
    ///
    /// - Parameters:
    ///   - wordId: Unique vocabulary identifier.
    ///   - mode: Modality under evaluation (voice, typed, editedTranscript).
    ///   - evidence: Historical evidence records.
    ///   - now: Current evaluation timestamp.
    /// - Returns: Rebuilt communication progress snapshot.
    public func rebuild(
        wordId: Int64,
        mode: PracticeInputMode,
        evidence: [WordUseEvidence],
        now: Date
    ) -> CommunicationProgress {
        let matchingEvidence = evidence.filter {
            $0.wordId == wordId &&
            $0.inputMode == mode &&
            $0.status == .valid
        }

        guard !matchingEvidence.isEmpty else {
            return makeEmptyProgress(wordId: wordId, mode: mode)
        }

        let sortedEvidence = matchingEvidence.sorted {
            if $0.timestamp != $1.timestamp {
                return $0.timestamp < $1.timestamp
            }
            return $0.id.uuidString < $1.id.uuidString
        }

        let knownEvidence = sortedEvidence.filter { isKnownOutcome($0) }
        guard let latestKnown = knownEvidence.last else {
            return makeEmptyProgress(wordId: wordId, mode: mode)
        }

        var seenSessions = Set<UUID>()
        var eligibleIndependentUses: [WordUseEvidence] = []

        for item in knownEvidence where isIndependentUse(item) {
            if !seenSessions.contains(item.sessionId) {
                seenSessions.insert(item.sessionId)
                eligibleIndependentUses.append(item)
            }
        }

        let stage = determineStage(eligibleIndependentUses: eligibleIndependentUses)
        let lastEligibleUse = eligibleIndependentUses.last?.timestamp
        let lastAttempt = latestKnown.timestamp
        let latestIsIndependent = isIndependentUse(latestKnown)

        let nextPractice = calculateNextPractice(
            stage: stage,
            latestIsIndependent: latestIsIndependent,
            lastAttempt: lastAttempt,
            lastEligibleUse: lastEligibleUse
        )

        let recentOutcome = PracticeOpportunityOutcome(
            wordId: wordId,
            objectiveId: latestKnown.objectiveId,
            success: latestKnown.usageVerdict == .appropriate && latestKnown.intentVerdict == .achieved,
            supportLevel: latestKnown.supportExposureIds.isEmpty ? .none : .lexical,
            primed: latestKnown.primed
        )

        return CommunicationProgress(
            wordId: wordId,
            inputMode: mode,
            stage: stage,
            independentEvidenceIds: eligibleIndependentUses.map(\.id),
            lastIndependentUseAt: lastEligibleUse,
            nextPracticeAt: nextPractice,
            recentOutcome: recentOutcome,
            policyVersion: configuration.version
        )
    }

    private func makeEmptyProgress(wordId: Int64, mode: PracticeInputMode) -> CommunicationProgress {
        CommunicationProgress(
            wordId: wordId,
            inputMode: mode,
            stage: .noEvidence,
            independentEvidenceIds: [],
            lastIndependentUseAt: nil,
            nextPracticeAt: nil,
            recentOutcome: nil,
            policyVersion: configuration.version
        )
    }

    private func isKnownOutcome(_ item: WordUseEvidence) -> Bool {
        guard item.usageVerdict != .uncertain && item.usageVerdict != .notObserved else {
            return false
        }
        guard item.intentVerdict != .uncertain else {
            return false
        }
        if item.inputMode == .voice {
            guard item.transcriptReliability == .usable else {
                return false
            }
        }
        return true
    }

    private func isIndependentUse(_ item: WordUseEvidence) -> Bool {
        guard item.inputMode != .editedTranscript else {
            return false
        }
        guard item.usageVerdict == .appropriate else {
            return false
        }
        guard item.intentVerdict == .achieved else {
            return false
        }
        if item.inputMode == .voice {
            guard item.transcriptReliability == .usable else {
                return false
            }
        }
        guard !item.primed else {
            return false
        }
        guard item.supportExposureIds.isEmpty else {
            return false
        }
        return true
    }

    private func determineStage(eligibleIndependentUses: [WordUseEvidence]) -> CommunicationStage {
        guard eligibleIndependentUses.count >= 2 else {
            return .practicing
        }

        var earlierFamilies = Set<PracticeContextFamily>()
        earlierFamilies.insert(eligibleIndependentUses[0].contextFamily)

        for index in 1..<eligibleIndependentUses.count {
            let candidate = eligibleIndependentUses[index]
            let previous = eligibleIndependentUses[index - 1]
            let elapsed = candidate.timestamp.timeIntervalSince(previous.timestamp)

            if elapsed >= configuration.transferDelay && !earlierFamilies.contains(candidate.contextFamily) {
                return .transferred
            }
            earlierFamilies.insert(candidate.contextFamily)
        }

        return .independentFamiliar
    }

    private func calculateNextPractice(
        stage: CommunicationStage,
        latestIsIndependent: Bool,
        lastAttempt: Date,
        lastEligibleUse: Date?
    ) -> Date {
        let delay: TimeInterval
        let baseDate: Date

        if stage == .practicing || !latestIsIndependent {
            delay = configuration.assistedDelay
            baseDate = lastAttempt
        } else if stage == .transferred {
            delay = configuration.transferredDelay
            baseDate = lastEligibleUse ?? lastAttempt
        } else {
            delay = configuration.familiarDelay
            baseDate = lastEligibleUse ?? lastAttempt
        }

        let scheduled = baseDate.addingTimeInterval(delay)
        let minimumDeadline = lastAttempt.addingTimeInterval(delay)
        return max(scheduled, minimumDeadline)
    }
}
