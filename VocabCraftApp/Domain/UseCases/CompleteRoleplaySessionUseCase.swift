import Foundation

public final class CompleteRoleplaySessionUseCase: Sendable {
    public init() {}

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
}
