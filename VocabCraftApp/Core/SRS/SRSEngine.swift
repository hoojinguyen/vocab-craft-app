import Foundation

public struct SRSResult: Equatable, Sendable {
    public let nextMastery: Int
    public let easeFactor: Double
    public let intervalDays: Int

    public init(nextMastery: Int, easeFactor: Double, intervalDays: Int) {
        self.nextMastery = nextMastery
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
    }
}

public struct SRSEngine {
    public static func calculateNextInterval(
        currentMastery: Int,
        easeFactor: Double,
        isCorrect: Bool,
        responseTimeMs: Int
    ) -> SRSResult {
        guard isCorrect else {
            let newEaseFactor = max(1.3, easeFactor - 0.2)
            return SRSResult(nextMastery: 0, easeFactor: newEaseFactor, intervalDays: 1)
        }

        // Quality grade (0-5) based on response speed
        let speedBonus = responseTimeMs < 2500 ? 1 : 0
        let quality = min(5, 4 + speedBonus)

        let qDiff = Double(5 - quality)
        let deltaEF = 0.1 - qDiff * (0.08 + qDiff * 0.02)
        let newEaseFactor = max(1.3, easeFactor + deltaEF)

        let nextMastery = min(5, currentMastery + 1)

        let nextInterval: Int
        switch nextMastery {
        case 1:
            nextInterval = 1
        case 2:
            nextInterval = 6
        default:
            let baseInterval = 6.0
            let multiplier = pow(newEaseFactor, Double(nextMastery - 2))
            nextInterval = Int(round(baseInterval * multiplier))
        }

        return SRSResult(
            nextMastery: nextMastery,
            easeFactor: newEaseFactor,
            intervalDays: nextInterval
        )
    }
}
