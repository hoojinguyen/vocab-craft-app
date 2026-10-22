import Foundation

/// Pure policy determining communicative scenario difficulty and recommended scaffolding adjustments.
public struct PracticeDifficultyPolicy: Sendable {
    private let supportPolicy: SupportPolicy

    public init(supportPolicy: SupportPolicy = SupportPolicy()) {
        self.supportPolicy = supportPolicy
    }

    /// Evaluates pedagogical history and calculates the adapted difficulty and suggested support.
    ///
    /// - Parameters:
    ///   - current: Current scenario difficulty configuration.
    ///   - outcomes: Pedagogical observations across opportunities.
    ///   - currentSuggestedSupport: Active initial support recommendation.
    /// - Returns: Proposed adaptation decision.
    public func next(
        current: PracticeDifficulty,
        outcomes: [PracticeOpportunityOutcome],
        currentSuggestedSupport: PracticeSupportLevel = .none
    ) -> PracticeAdaptationDecision {
        var seenIds = Set<String>()
        var eligibleOutcomes: [PracticeOpportunityOutcome] = []
        for outcome in outcomes where outcome.eligible {
            if seenIds.insert(outcome.opportunityId).inserted {
                eligibleOutcomes.append(outcome)
            }
        }

        guard eligibleOutcomes.count >= 2 else {
            return PracticeAdaptationDecision(
                difficulty: current,
                suggestedSupport: currentSuggestedSupport
            )
        }

        let count = eligibleOutcomes.count
        let lastTwo = (eligibleOutcomes[count - 2], eligibleOutcomes[count - 1])

        if isSuccess(lastTwo.0) && isSuccess(lastTwo.1) {
            let escalatedDifficulty = escalateDifficulty(current: current)
            return PracticeAdaptationDecision(
                difficulty: escalatedDifficulty,
                suggestedSupport: .none
            )
        }

        if isFailure(lastTwo.0) && isFailure(lastTwo.1) {
            return deescalate(current: current, currentSuggestedSupport: currentSuggestedSupport)
        }

        return PracticeAdaptationDecision(
            difficulty: current,
            suggestedSupport: currentSuggestedSupport
        )
    }

    private func isSuccess(_ outcome: PracticeOpportunityOutcome) -> Bool {
        outcome.intentVerdict == .achieved
            && outcome.usageVerdict == .appropriate
            && outcome.supportLevel <= .intent
            && !outcome.primed
    }

    private func isFailure(_ outcome: PracticeOpportunityOutcome) -> Bool {
        guard outcome.intentVerdict != .uncertain && outcome.usageVerdict != .uncertain else {
            return false
        }
        if outcome.intentVerdict == .achieved && outcome.usageVerdict == .notObserved {
            return false
        }
        if outcome.intentVerdict == .achieved && outcome.usageVerdict == .appropriate {
            return false
        }
        return outcome.intentVerdict == .notYet || outcome.usageVerdict == .inappropriate
    }

    private func escalateDifficulty(current: PracticeDifficulty) -> PracticeDifficulty {
        if current.characterDirectness < 2 {
            if let newDiff = try? PracticeDifficulty(
                taskConstraints: current.taskConstraints,
                characterDirectness: current.characterDirectness + 1,
                contextNovelty: current.contextNovelty
            ) {
                return newDiff
            }
        } else if current.taskConstraints < 2 {
            if let newDiff = try? PracticeDifficulty(
                taskConstraints: current.taskConstraints + 1,
                characterDirectness: current.characterDirectness,
                contextNovelty: current.contextNovelty
            ) {
                return newDiff
            }
        } else if current.contextNovelty < 2 {
            if let newDiff = try? PracticeDifficulty(
                taskConstraints: current.taskConstraints,
                characterDirectness: current.characterDirectness,
                contextNovelty: current.contextNovelty + 1
            ) {
                return newDiff
            }
        }
        return current
    }

    private func deescalate(
        current: PracticeDifficulty,
        currentSuggestedSupport: PracticeSupportLevel
    ) -> PracticeAdaptationDecision {
        if current.taskConstraints > 0 {
            if let newDifficulty = try? PracticeDifficulty(
                taskConstraints: current.taskConstraints - 1,
                characterDirectness: current.characterDirectness,
                contextNovelty: current.contextNovelty
            ) {
                return PracticeAdaptationDecision(
                    difficulty: newDifficulty,
                    suggestedSupport: currentSuggestedSupport
                )
            }
        }

        let newSupport = supportPolicy.nextLevel(current: currentSuggestedSupport)
        return PracticeAdaptationDecision(
            difficulty: current,
            suggestedSupport: newSupport
        )
    }
}
