import Foundation

public struct MasteryEvaluationPolicy: Sendable {
    public static let requiredStreakForMastery = 3
    public static let requiredDistinctModesForMastery = 2

    public static func evaluate(
        currentStreak: Int,
        practicedModes: Set<ReflexBlitzMode>,
        isCorrect: Bool,
        currentMode: ReflexBlitzMode
    ) -> (newStreak: Int, newPracticedModes: Set<ReflexBlitzMode>, isMastered: Bool) {
        if !isCorrect {
            return (newStreak: 0, newPracticedModes: [], isMastered: false)
        }

        let newStreak = currentStreak + 1
        var newModes = practicedModes
        newModes.insert(currentMode)

        let isMastered = (newStreak >= requiredStreakForMastery) &&
                         (newModes.count >= requiredDistinctModesForMastery)

        return (newStreak: newStreak, newPracticedModes: newModes, isMastered: isMastered)
    }
}
