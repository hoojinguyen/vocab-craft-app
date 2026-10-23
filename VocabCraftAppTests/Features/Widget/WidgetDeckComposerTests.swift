import Foundation
import Testing
@testable import VocabCraftApp

@Suite("WidgetDeckComposer")
struct WidgetDeckComposerTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func word(_ id: Int64) -> TopicWordDTO {
        TopicWordDTO(
            id: id,
            stageId: "stage",
            lemma: "word\(id)",
            phonetic: "/w\(id)/",
            pos: "noun",
            cefrLevel: "A1",
            definitionVi: "nghia \(id)",
            definitionEn: "meaning \(id)",
            exampleEn: "Example \(id).",
            exampleVi: "Vi du \(id)."
        )
    }

    private func words(_ range: ClosedRange<Int64>) -> [TopicWordDTO] {
        range.map(word)
    }

    private func compose(
        due: [TopicWordDTO] = [],
        recent: [TopicWordDTO] = [],
        upcoming: [TopicWordDTO] = []
    ) -> WidgetDeck {
        WidgetDeckComposer.compose(due: due, recent: recent, upcoming: upcoming, pathId: "path", now: now)
    }

    @Test("cards carry path id and word fields")
    func cardsCarryPathIdAndWordFields() throws {
        let source = TopicWordDTO(
            id: 42,
            stageId: "stage",
            lemma: "serendipity",
            phonetic: "/ˌser.ənˈdɪp.ə.ti/",
            pos: "noun",
            cefrLevel: "C1",
            definitionVi: "su tinh co may man",
            definitionEn: "a happy accident",
            exampleEn: "Finding it was pure serendipity.",
            exampleVi: "Tim thay no that may man."
        )

        let deck = WidgetDeckComposer.compose(due: [source], recent: [], upcoming: [], pathId: "path-7", now: now)

        #expect(deck.pathId == "path-7")
        #expect(deck.version == WidgetDeck.currentVersion)
        let card = try #require(deck.cards.first)
        #expect(card.wordId == 42)
        #expect(card.lemma == "serendipity")
        #expect(card.ipa == "/ˌser.ənˈdɪp.ə.ti/")
        #expect(card.definitionVi == "su tinh co may man")
        #expect(card.exampleEn == "Finding it was pure serendipity.")
        #expect(card.source == .due)
    }

    @Test("due words come first")
    func dueWordsComeFirst() {
        let deck = compose(due: [word(1), word(2)], recent: [word(3)], upcoming: [word(4)])
        #expect(deck.cards.map(\.wordId) == [1, 2, 3, 4])
        #expect(deck.cards.map(\.source) == [.due, .due, .recent, .upcoming])
    }

    @Test("remainder splits sixty forty")
    func splitsRemainderSixtyForty() {
        let deck = compose(recent: words(100...149), upcoming: words(200...249))
        #expect(deck.cards.count == 36)
        #expect(deck.cards.filter { $0.source == .recent }.count == 22)
        #expect(deck.cards.filter { $0.source == .upcoming }.count == 14)
    }

    @Test("sources are interleaved")
    func interleavesSources() {
        let deck = compose(recent: words(100...149), upcoming: words(200...249))
        #expect(deck.cards.prefix(5).map(\.source) == [.recent, .recent, .upcoming, .recent, .upcoming])
    }

    @Test("upcoming backfills when recent is short")
    func backfillsWhenRecentShort() {
        let deck = compose(recent: [word(1), word(2)], upcoming: words(100...149))
        #expect(deck.cards.count == 36)
        #expect(deck.cards.filter { $0.source == .recent }.count == 2)
        #expect(deck.cards.filter { $0.source == .upcoming }.count == 34)
    }

    @Test("new learner uses upcoming only")
    func newLearnerUsesUpcomingOnly() {
        let deck = compose(upcoming: words(1...6))
        #expect(deck.cards.count == 6)
        #expect(deck.cards.allSatisfy { $0.source == .upcoming })
    }

    @Test("deduplicates across sources")
    func deduplicatesAcrossSources() {
        let deck = compose(due: [word(1)], recent: [word(1), word(2)], upcoming: [word(2), word(3)])
        #expect(deck.cards.map(\.wordId) == [1, 2, 3])
    }

    @Test("caps due at max cards")
    func capsDueAtMaxCards() {
        let deck = compose(due: words(1...40))
        #expect(deck.cards.count == 36)
        #expect(deck.cards.allSatisfy { $0.source == .due })
    }

    @Test("empty inputs give empty deck")
    func emptyInputsGiveEmptyDeck() {
        let deck = compose()
        #expect(deck.cards.isEmpty)
        #expect(deck.version == WidgetDeck.currentVersion)
        #expect(deck.generatedAt == now)
    }
}
