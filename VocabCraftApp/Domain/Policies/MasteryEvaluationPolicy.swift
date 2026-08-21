import Foundation

public struct MasteryEvaluationResult: Sendable, Equatable {
    public let newStreak: Int
    public let newPracticedModes: Set<ReflexBlitzMode>
    public let isMastered: Bool

    public init(newStreak: Int, newPracticedModes: Set<ReflexBlitzMode>, isMastered: Bool) {
        self.newStreak = newStreak
        self.newPracticedModes = newPracticedModes
        self.isMastered = isMastered
    }
}

public struct MasteryEvaluationPolicy: Sendable {
    public static let requiredStreakForMastery = 3
    public static let requiredDistinctModesForMastery = 2

    public static func evaluate(
        currentStreak: Int,
        practicedModes: Set<ReflexBlitzMode>,
        isCorrect: Bool,
        currentMode: ReflexBlitzMode
    ) -> MasteryEvaluationResult {
        if !isCorrect {
            return MasteryEvaluationResult(newStreak: 0, newPracticedModes: [], isMastered: false)
        }

        let newStreak = currentStreak + 1
        var newModes = practicedModes
        newModes.insert(currentMode)

        let isMastered = (newStreak >= requiredStreakForMastery) &&
                         (newModes.count >= requiredDistinctModesForMastery)

        return MasteryEvaluationResult(newStreak: newStreak, newPracticedModes: newModes, isMastered: isMastered)
    }
}
