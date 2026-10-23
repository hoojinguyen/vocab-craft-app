import Foundation
import Testing
@testable import VocabCraftApp

@Suite("WidgetDeckStore")
struct WidgetDeckStoreTests {
    private func makeStore() -> WidgetDeckStore {
        WidgetDeckStore(directoryURL: FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true))
    }

    private func makeDeck(version: Int = WidgetDeck.currentVersion) -> WidgetDeck {
        WidgetDeck(
            version: version,
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            pathId: "path-1",
            cards: [
                WidgetCard(wordId: 1, lemma: "apple", ipa: "/ˈæp.əl/", definitionVi: "quả táo", exampleEn: "An apple a day.", source: .due),
                WidgetCard(wordId: 2, lemma: "book", ipa: "/bʊk/", definitionVi: "quyển sách", exampleEn: "Read a book.", source: .recent)
            ]
        )
    }

    @Test func deckRoundTrips() throws {
        let store = makeStore()
        let deck = makeDeck()
        try store.saveDeck(deck)
        #expect(store.loadDeck() == deck)
    }

    @Test func missingDeckReturnsNil() {
        #expect(makeStore().loadDeck() == nil)
    }

    @Test func corruptDeckReturnsNil() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: dir.appendingPathComponent("widget_deck.json"))
        #expect(WidgetDeckStore(directoryURL: dir).loadDeck() == nil)
    }

    @Test func wrongVersionReturnsNil() throws {
        let store = makeStore()
        try store.saveDeck(makeDeck(version: 99))
        #expect(store.loadDeck() == nil)
    }

    @Test func interactionDefaultsToEmpty() throws {
        let store = makeStore()
        #expect(store.loadInteraction() == .empty)
        let state = WidgetInteractionState(revealedWordId: 7, revealedAt: Date(timeIntervalSince1970: 1_700_000_000))
        try store.saveInteraction(state)
        #expect(store.loadInteraction().revealedWordId == 7)
    }
}
