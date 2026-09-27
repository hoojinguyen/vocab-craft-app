import Foundation

public final class CompleteRoleplaySessionUseCase: Sendable {
    private let userSettingsStore: UserSettingsStore?
    private let userProgressRepository: (any UserProgressRepositoryProtocol)?

    public init(
        userSettingsStore: UserSettingsStore? = nil,
        userProgressRepository: (any UserProgressRepositoryProtocol)? = nil
    ) {
        self.userSettingsStore = userSettingsStore
        self.userProgressRepository = userProgressRepository
    }

    public func execute(
        scenarioId: String,
        totalTurns: Int,
        targetWordsAttempted: [String],
        targetWordsMastered: [String],
        refinements: [SentenceRefinementPair]
    ) async -> RoleplaySessionSummary {
        let uniqueAttempted = Set(targetWordsAttempted)
        let uniqueMastered = Set(targetWordsMastered)

        let targetRatio = uniqueAttempted.isEmpty ? 1.0 : Double(uniqueMastered.count) / Double(uniqueAttempted.count)
        let fluencyScore = min(100, Int(round((targetRatio * 60.0) + min(40.0, Double(totalTurns) * 8.0))))
        let xpEarned = max(10, (uniqueMastered.count * 15) + (totalTurns * 5))

        if let userSettingsStore {
            await MainActor.run {
                userSettingsStore.todayWordsLearned += uniqueMastered.count
            }
        }

        return RoleplaySessionSummary(
            scenarioId: scenarioId,
            totalTurns: totalTurns,
            targetWordsAttempted: Array(uniqueAttempted).sorted(),
            targetWordsMastered: Array(uniqueMastered).sorted(),
            fluencyScore: fluencyScore,
            xpEarned: xpEarned,
            refinements: refinements
        )
    }

    public func execute(
        scenario: RoleplayScenario,
        messages: [RoleplayMessage],
        masteredWords: Set<String>
    ) async -> RoleplaySessionSummary {
        let totalTurns = messages.filter { $0.sender == .user }.count
        var refinements: [SentenceRefinementPair] = []
        for (index, msg) in messages.enumerated() {
            if case .character = msg.sender, let suggestion = msg.refinementSuggestion {
                let userSentence = (index > 0 && messages[index - 1].sender == .user) ? messages[index - 1].text : ""
                refinements.append(SentenceRefinementPair(
                    originalUserSentence: userSentence,
                    refinedNativeSentence: suggestion
                ))
            } else if msg.sender == .user, let suggestion = msg.refinementSuggestion {
                refinements.append(SentenceRefinementPair(
                    originalUserSentence: msg.text,
                    refinedNativeSentence: suggestion
                ))
            }
        }

        return await execute(
            scenarioId: scenario.id,
            totalTurns: totalTurns,
            targetWordsAttempted: scenario.targetWordIds,
            targetWordsMastered: Array(masteredWords),
            refinements: refinements
        )
    }
}
