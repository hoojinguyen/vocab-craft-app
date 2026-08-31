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

        var items: [ReflexDrillPlanItem] = []

        for (index, word) in words.enumerated() {
            let planItemId: String
            if let identifiable = word as? (any Identifiable) {
                planItemId = "\(mode.rawValue)-plan-\(index)-\(identifiable.id)"
            } else {
                planItemId = "\(mode.rawValue)-plan-\(index)-\(word.lemma)"
            }

            let planItem = ReflexDrillPlanItemBuilder.buildItem(
                id: planItemId,
                word: word,
                assignedMode: mode,
                distractorPool: words
            )
            items.append(planItem)
        }

        return ReflexDrillSessionPlan(mode: mode, items: items)
    }
}
