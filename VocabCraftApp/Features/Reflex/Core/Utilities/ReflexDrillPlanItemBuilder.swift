import Foundation

/// Shared builder that pre-computes options, cloze stages, and hint badges for any reflex drill item.
public struct ReflexDrillPlanItemBuilder: Sendable {
    public static func buildItem<T: ReflexDrillable>(
        id: String,
        word: T,
        assignedMode: ReflexMode,
        distractorPool: [some ReflexDrillable]
    ) -> ReflexDrillPlanItem {
        let options: [ReflexBlitzOption]
        if assignedMode == .multipleChoice || assignedMode == .listening {
            options = ReflexDistractorGenerator.generateOptions(
                mode: assignedMode,
                target: word,
                pool: distractorPool
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

        return ReflexDrillPlanItem(
            id: id,
            word: word,
            assignedMode: assignedMode,
            options: options,
            correctOptionIndex: correctIndex,
            eliminatedOptionId: eliminatedId,
            clozeStages: clozeStages,
            hintBadgeText: hintBadgeText
        )
    }
}
