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

        for word in words {
            let candidateModes: [ReflexMode]
            let lowest = word.modeStats.lowestSuccessModes
            if lowest.isEmpty {
                candidateModes = allModes
            } else {
                candidateModes = lowest
            }

            // Score candidate modes based on usage balance, consecutive runs, and deterministic order
            var bestMode: ReflexMode = candidateModes[0]
            var lowestScore = Int.max

            for mode in candidateModes {
                let usage = modeCounts[mode] ?? 0
                let consecutivePenalty: Int
                let lastMode = assignedModes.last
                let secondLastMode = assignedModes.count >= 2 ? assignedModes[assignedModes.count - 2] : nil

                if lastMode == mode && secondLastMode == mode {
                    consecutivePenalty = 10
                } else if lastMode == mode {
                    consecutivePenalty = 1
                } else {
                    consecutivePenalty = 0
                }

                let modeOrder = allModes.firstIndex(of: mode) ?? 0
                let score = (usage * 100) + (consecutivePenalty * 200) + modeOrder

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

            let options: [ReflexBlitzOption]
            if assignedMode == .multipleChoice || assignedMode == .listening {
                options = ReflexDistractorGenerator.generateOptions(
                    mode: assignedMode,
                    target: word,
                    pool: words
                )
            } else {
                options = []
            }

            let correctIndex = options.firstIndex(where: { $0.isCorrect }) ?? 0
            let incorrectOptions = options.filter { !$0.isCorrect }
            let eliminatedId = incorrectOptions.randomElement()?.id

            let clozeStages = ReflexHintMaskGenerator.generateStages(
                lemma: word.lemma,
                sentenceEn: word.exampleSentenceEn,
                pos: word.cleanPos
            )

            let hintBadgeText: String
            switch clozeStages.strategy {
            case .middleCluster(let cluster, _):
                hintBadgeText = "...\(cluster)... • \(word.cleanPos)"
            case .prefix(let count):
                let prefixStr = String(word.lemma.prefix(count))
                hintBadgeText = "\(prefixStr)... • \(word.cleanPos)"
            case .suffix(let count):
                let suffixStr = String(word.lemma.suffix(count))
                hintBadgeText = "...\(suffixStr) • \(word.cleanPos)"
            case .consonantScaffold, .shortWordPrefix, .shortWordSuffix:
                hintBadgeText = "\(word.cleanInitialLetterHint)"
            }

            let planItemId = "\(assignedMode.rawValue)-practice-\(index)-\(word.id)"

            let planItem = ReflexDrillPlanItem(
                id: planItemId,
                word: word,
                assignedMode: assignedMode,
                options: options,
                correctOptionIndex: correctIndex,
                eliminatedOptionId: eliminatedId,
                clozeStages: clozeStages,
                hintBadgeText: hintBadgeText
            )
            items.append(planItem)
        }

        return ReflexDrillSessionPlan(mode: .multipleChoice, items: items)
    }
}
