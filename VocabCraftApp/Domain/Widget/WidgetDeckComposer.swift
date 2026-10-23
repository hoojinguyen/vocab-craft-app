import Foundation

public enum WidgetDeckComposer {
    static let maxCards = 36
    static let recentShare = 0.6

    /// Inputs are already ordered by priority. Due words come first, then the
    /// remaining slots are filled by interleaving recent and upcoming words
    /// (about 60/40), backfilling from whichever source still has words.
    static func compose(
        due: [TopicWordDTO],
        recent: [TopicWordDTO],
        upcoming: [TopicWordDTO],
        pathId: String?,
        now: Date
    ) -> WidgetDeck {
        var seen = Set<Int64>()
        var cards: [WidgetCard] = []

        func unseen(_ words: [TopicWordDTO]) -> [TopicWordDTO] {
            var result: [TopicWordDTO] = []
            for word in words where seen.insert(word.id).inserted {
                result.append(word)
            }
            return result
        }

        for word in unseen(due).prefix(maxCards) {
            cards.append(card(word, source: .due))
        }

        let slots = maxCards - cards.count
        let recentTarget = Int((Double(slots) * recentShare).rounded())
        var recentQueue = unseen(recent)[...]
        var upcomingQueue = unseen(upcoming)[...]
        var takenRecent = 0
        var taken = 0

        while cards.count < maxCards && (!recentQueue.isEmpty || !upcomingQueue.isEmpty) {
            let wantRecent = takenRecent < recentTarget
                && Double(takenRecent) < Double(taken + 1) * recentShare
            if (wantRecent && !recentQueue.isEmpty) || upcomingQueue.isEmpty {
                cards.append(card(recentQueue.removeFirst(), source: .recent))
                takenRecent += 1
            } else {
                cards.append(card(upcomingQueue.removeFirst(), source: .upcoming))
            }
            taken += 1
        }

        return WidgetDeck(generatedAt: now, pathId: pathId, cards: cards)
    }

    private static func card(_ word: TopicWordDTO, source: WidgetCard.Source) -> WidgetCard {
        WidgetCard(
            wordId: word.id,
            lemma: word.lemma,
            ipa: word.phonetic,
            definitionVi: word.definitionVi,
            exampleEn: word.exampleEn,
            source: source
        )
    }
}
