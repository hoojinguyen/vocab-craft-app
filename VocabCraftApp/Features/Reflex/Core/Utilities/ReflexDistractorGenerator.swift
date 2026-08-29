import Foundation

/// Pure utility for generating distractor options in Multiple Choice and Listening Reflex Drills.
public struct ReflexDistractorGenerator: Sendable {
    /// Generates 4 unique shuffled options (1 correct, 3 distractors) for multiple choice or listening drills.
    public static func generateOptions<T: ReflexDrillable>(
        mode: ReflexMode,
        targetLemma: String,
        targetDefinition: String,
        pool: [T]
    ) -> [ReflexBlitzOption] {
        guard mode == .multipleChoice || mode == .listening else {
            return []
        }

        let isMultipleChoice = mode == .multipleChoice
        let correctText = isMultipleChoice ? targetLemma : targetDefinition

        var distractorCandidates: [String] = []
        var seen = Set<String>([correctText])

        // Add from provided pool first
        for item in pool.shuffled() {
            let text = isMultipleChoice ? item.lemma : item.definitionVi
            if !text.isEmpty && !seen.contains(text) {
                seen.insert(text)
                distractorCandidates.append(text)
                if distractorCandidates.count == 3 { break }
            }
        }

        // If not enough distractors, fallback to default starter words
        if distractorCandidates.count < 3 {
            for item in ReflexBlitzWordItem.defaultStarterWords.shuffled() {
                let text = isMultipleChoice ? item.lemma : item.definitionVi
                if !text.isEmpty && !seen.contains(text) {
                    seen.insert(text)
                    distractorCandidates.append(text)
                    if distractorCandidates.count == 3 { break }
                }
            }
        }

        var options: [ReflexBlitzOption] = [
            ReflexBlitzOption(text: correctText, isCorrect: true)
        ]
        for distractor in distractorCandidates.prefix(3) {
            options.append(ReflexBlitzOption(text: distractor, isCorrect: false))
        }

        return options.shuffled()
    }

    /// Convenience overload for target conforming to ReflexDrillable.
    public static func generateOptions(
        mode: ReflexMode,
        target: some ReflexDrillable,
        pool: [some ReflexDrillable]
    ) -> [ReflexBlitzOption] {
        generateOptions(
            mode: mode,
            targetLemma: target.lemma,
            targetDefinition: target.definitionVi,
            pool: pool
        )
    }
}
