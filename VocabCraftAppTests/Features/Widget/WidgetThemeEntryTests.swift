import Foundation
import Testing
@testable import VocabCraftApp

@MainActor
@Suite("Widget theme entries")
struct WidgetThemeEntryTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeStore() -> WidgetDeckStore {
        WidgetDeckStore(
            directoryURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("WidgetThemeEntryTests-\(UUID().uuidString)", isDirectory: true)
        )
    }

    private func deck() -> WidgetDeck {
        WidgetDeck(
            generatedAt: now,
            pathId: nil,
            cards: [
                WidgetCard(wordId: 1, lemma: "apple", ipa: "/ap/", definitionVi: "qua tao", exampleEn: "An apple.", source: .recent),
                WidgetCard(wordId: 2, lemma: "book", ipa: "/bk/", definitionVi: "quyen sach", exampleEn: "A book.", source: .recent)
            ]
        )
    }

    @Test func entriesCarrySavedTheme() throws {
        let store = makeStore()
        try store.saveDeck(deck())
        try store.saveThemePreset(.neoArcade)

        let timeline = VocabWidgetProvider(store: store, container: nil).makeTimeline(now: now)

        #expect(!timeline.entries.isEmpty)
        #expect(timeline.entries.allSatisfy { $0.themePreset == .neoArcade })
    }

    @Test func entriesFallBackToEditorialWithoutSavedTheme() throws {
        let store = makeStore()
        try store.saveDeck(deck())

        let timeline = VocabWidgetProvider(store: store, container: nil).makeTimeline(now: now)

        #expect(timeline.entries.allSatisfy { $0.themePreset == .editorial })
    }
}
