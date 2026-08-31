import Foundation

/// Protocol for generating an upfront immutable drill session plan for Practice sessions.
public protocol PracticeDrillPlanGeneratorProtocol: Sendable {
    func generatePlan(from words: [VaultWordItem]) -> ReflexDrillSessionPlan
}

/// Generates balanced 4-modality drill plans prioritizing the weakest modality for each word.
public struct PracticeDrillPlanGenerator: PracticeDrillPlanGeneratorProtocol, Sendable {
    public init() {}

    public func generatePlan(from words: [VaultWordItem]) -> ReflexDrillSessionPlan {
        guard !words.isEmpty else {
            return ReflexDrillSessionPlan(mode: .multipleChoice, items: [])
        }

        var assignedModes: [ReflexMode] = []
        var modeCounts: [ReflexMode: Int] = [
            .speaking: 0,
            .typing: 0,
            .multipleChoice: 0,
            .listening: 0
        ]

        let allModes = ReflexMode.allCases
        let targetQuotaPerMode = max(1, (words.count + allModes.count - 1) / allModes.count)

        for word in words {
            let lowest = word.modeStats.lowestSuccessModes
            let lowestSet = Set(lowest)

            // Score all 4 modes: prioritize weakest modality while enforcing session quota and avoiding consecutive runs
            var bestMode: ReflexMode = lowest.first ?? .multipleChoice
            var lowestScore = Int.max

            for (index, mode) in allModes.enumerated() {
                let usage = modeCounts[mode, default: 0]
                let isWeakest = lowestSet.contains(mode)
                let weakestBonus = isWeakest ? 0 : 500

                let consecutivePenalty: Int
                let lastMode = assignedModes.last
                let secondLastMode = assignedModes.count >= 2 ? assignedModes[assignedModes.count - 2] : nil

                if lastMode == mode && secondLastMode == mode {
                    consecutivePenalty = 2000 // Strictly discourage 3 in a row
                } else if lastMode == mode {
                    consecutivePenalty = 150
                } else {
                    consecutivePenalty = 0
                }

                let quotaPenalty = max(0, usage - targetQuotaPerMode) * 300
                let usageScore = usage * 100
                let score = weakestBonus + usageScore + quotaPenalty + consecutivePenalty + index

                if score < lowestScore {
                    lowestScore = score
                    bestMode = mode
                }
            }

            assignedModes.append(bestMode)
            modeCounts[bestMode, default: 0] += 1
        }

        var items: [ReflexDrillPlanItem] = []

        for (index, word) in words.enumerated() {
            let assignedMode = assignedModes[index]
            let planItemId = "\(assignedMode.rawValue)-practice-\(index)-\(word.id)"

            let planItem = ReflexDrillPlanItemBuilder.buildItem(
                id: planItemId,
                word: word,
                assignedMode: assignedMode,
                distractorPool: words
            )
            items.append(planItem)
        }

        return ReflexDrillSessionPlan(mode: .multipleChoice, items: items)
    }
}
