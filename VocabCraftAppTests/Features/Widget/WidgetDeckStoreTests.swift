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

    @Test func interactionKeepsSubSecondPrecision() throws {
        let store = makeStore()
        let revealedAt = Date(timeIntervalSince1970: 1_700_000_000.25)
        try store.saveInteraction(WidgetInteractionState(revealedWordId: 3, revealedAt: revealedAt))

        let loaded = store.loadInteraction()

        #expect(loaded.revealedWordId == 3)
        #expect(abs((loaded.revealedAt?.timeIntervalSince1970 ?? 0) - 1_700_000_000.25) < 0.001)
    }

    @Test func legacyDateWithoutFractionStillDecodes() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let json = #"{"revealedWordId":9,"revealedAt":"2023-11-14T22:13:20Z"}"#
        try Data(json.utf8).write(to: dir.appendingPathComponent("widget_interaction.json"))

        let loaded = WidgetDeckStore(directoryURL: dir).loadInteraction()

        #expect(loaded.revealedWordId == 9)
        #expect(loaded.revealedAt == Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test func partOfSpeechRoundTrips() throws {
        let store = makeStore()
        let deck = WidgetDeck(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            pathId: nil,
            cards: [
                WidgetCard(
                    wordId: 1, lemma: "apple", ipa: "/ap/", definitionVi: "qua tao", exampleEn: "An apple.",
                    source: .due, partOfSpeech: "noun"
                )
            ]
        )
        try store.saveDeck(deck)
        #expect(store.loadDeck()?.cards.first?.partOfSpeech == "noun")
    }

    @Test func versionOneDeckStillLoads() throws {
        let store = makeStore()
        try store.saveDeck(makeDeck(version: 1))
        #expect(store.loadDeck()?.cards.count == 2)
    }

    @Test func versionZeroDeckIsRejected() throws {
        let store = makeStore()
        try store.saveDeck(makeDeck(version: 0))
        #expect(store.loadDeck() == nil)
    }

    @Test func cardWithoutPartOfSpeechKeyDecodes() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let json = """
        {"version":2,"generatedAt":"2023-11-14T22:13:20Z","pathId":null,"cards":[
        {"wordId":1,"lemma":"apple","ipa":"/ap/","definitionVi":"qua tao","exampleEn":"An apple.","source":"due"}]}
        """
        try Data(json.utf8).write(to: dir.appendingPathComponent("widget_deck.json"))

        let card = try #require(WidgetDeckStore(directoryURL: dir).loadDeck()?.cards.first)

        #expect(card.partOfSpeech == nil)
    }
}
