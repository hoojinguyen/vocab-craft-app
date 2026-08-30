import Foundation

/// Pure utility that pre-computes an entire Reflex drill session upfront.
///
/// Pre-computes shuffled word sequences, distractor options (for multiple choice and listening),
/// pre-selected 50/50 distractor eliminations, progressive cloze scaffolding stages, and hint badges.
public struct ReflexDrillPlanGenerator: Sendable {
    /// Generates an immutable session plan for the given words and reflex mode.
    public static func generatePlan(
        words: [some ReflexDrillable],
        mode: ReflexMode
    ) -> ReflexDrillSessionPlan {
        guard !words.isEmpty else {
            return ReflexDrillSessionPlan(mode: mode, items: [])
        }

        let planWords = words
        var items: [ReflexDrillPlanItem] = []

        for (index, word) in planWords.enumerated() {
            let options: [ReflexBlitzOption]
            if mode == .multipleChoice || mode == .listening {
                options = ReflexDistractorGenerator.generateOptions(
                    mode: mode,
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

            let planItemId: String
            if let identifiable = word as? (any Identifiable) {
                planItemId = "\(mode.rawValue)-plan-\(index)-\(identifiable.id)"
            } else {
                planItemId = "\(mode.rawValue)-plan-\(index)-\(word.lemma)"
            }

            let planItem = ReflexDrillPlanItem(
                id: planItemId,
                word: word,
                assignedMode: mode,
                options: options,
                correctOptionIndex: correctIndex,
                eliminatedOptionId: eliminatedId,
                clozeStages: clozeStages,
                hintBadgeText: hintBadgeText
            )
            items.append(planItem)
        }

        return ReflexDrillSessionPlan(mode: mode, items: items)
    }
}
