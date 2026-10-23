import Foundation
#if canImport(SwiftDataMacros) || canImport(SwiftData)
import SwiftData
import Testing
@testable import VocabCraftApp
#if SWIFT_PACKAGE
@testable import VocabCraftWidgetExtension
#endif

@MainActor
@Suite("Widget Intents")
struct WidgetIntentsTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeStore() -> WidgetDeckStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("widget-intents-\(UUID().uuidString)", isDirectory: true)
        return WidgetDeckStore(directoryURL: directory)
    }

    private func makeContainer() throws -> ModelContainer {
        try SharedAppGroupContainer.createContainer(inMemory: true)
    }

    private func card(_ id: Int64) -> WidgetCard {
        WidgetCard(wordId: id, lemma: "w\(id)", ipa: "", definitionVi: "d", exampleEn: "e", source: .due)
    }

    @discardableResult
    private func insertRow(_ id: Int64, nextReview: Date, in context: ModelContext) throws -> UserWordProgress {
        let row = UserWordProgress(
            wordId: id,
            masteryLevel: 1,
            easeFactor: 2.5,
            intervalDays: 1,
            nextReviewDate: nextReview,
            lastReviewDate: now.addingTimeInterval(-86_400),
            totalReviews: 4
        )
        context.insert(row)
        try context.save()
        return row
    }

    @Test("revealStoresWordAndTime")
    func revealStoresWordAndTime() throws {
        let store = makeStore()

        try RevealCardIntent(wordId: 5).perform(store: store, now: now)

        #expect(store.loadInteraction() == .init(revealedWordId: 5, revealedAt: now))
    }

    @Test("gradeClearsInteractionOnSuccess")
    func gradeClearsInteractionOnSuccess() throws {
        let store = makeStore()
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        let row = try insertRow(5, nextReview: now.addingTimeInterval(-60), in: context)
        try RevealCardIntent(wordId: 5).perform(store: store, now: now.addingTimeInterval(-3))

        try GradeCardIntent(wordId: 5, remembered: true).perform(store: store, context: context, now: now)

        #expect(store.loadInteraction() == .empty)
        #expect(row.totalReviews == 5)
        #expect(row.lastReviewDate == now)
    }

    @Test("gradeKeepsInteractionWhenRejected")
    func gradeKeepsInteractionWhenRejected() throws {
        let store = makeStore()
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        let context = container.mainContext
        let row = try insertRow(5, nextReview: now.addingTimeInterval(-60), in: context)
        try RevealCardIntent(wordId: 5).perform(store: store, now: now.addingTimeInterval(-3))

        try GradeCardIntent(wordId: 6, remembered: true).perform(store: store, context: context, now: now)

        #expect(store.loadInteraction().revealedWordId == 5)
        #expect(row.totalReviews == 4)
        #expect(row.masteryLevel == 1)
        #expect(row.nextReviewDate == now.addingTimeInterval(-60))
    }

    @Test("providerTimelineUsesDeckAndDueRows")
    func providerTimelineUsesDeckAndDueRows() throws {
        let store = makeStore()
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        try insertRow(2, nextReview: now.addingTimeInterval(-60), in: container.mainContext)
        try store.saveDeck(WidgetDeck(generatedAt: now, pathId: nil, cards: [card(1), card(2)]))

        let provider = VocabWidgetProvider(store: store, container: container)
        let timeline = provider.makeTimeline(now: now)

        #expect(timeline.entries.count == 1)
        #expect(timeline.entries.first?.card?.wordId == 2)
        #expect(timeline.entries.first?.mode == .flashcardFront)
        #expect(timeline.entries.first?.dueCount == 1)
    }

    @Test("providerClearsStaleRevealState")
    func providerClearsStaleRevealState() throws {
        let store = makeStore()
        let container = try makeContainer()
        defer { withExtendedLifetime(container) {} }
        try insertRow(2, nextReview: now.addingTimeInterval(86_400), in: container.mainContext)
        try store.saveDeck(WidgetDeck(generatedAt: now, pathId: nil, cards: [card(1), card(2)]))
        try store.saveInteraction(WidgetInteractionState(revealedWordId: 2, revealedAt: now.addingTimeInterval(-3)))

        let provider = VocabWidgetProvider(store: store, container: container)
        let timeline = provider.makeTimeline(now: now)

        #expect(timeline.entries.first?.mode != .flashcardBack)
        #expect(store.loadInteraction() == .empty)
    }

    @Test("providerWithoutContainerTreatsNothingDue")
    func providerWithoutContainerTreatsNothingDue() throws {
        let store = makeStore()
        try store.saveDeck(WidgetDeck(generatedAt: now, pathId: nil, cards: [card(1), card(2)]))

        let provider = VocabWidgetProvider(store: store, container: nil)
        let timeline = provider.makeTimeline(now: now)

        #expect(timeline.entries.first?.mode == .passive)
        #expect(timeline.entries.first?.dueCount == 0)
    }

    @Test("providerWithoutContainerKeepsStoredReveal")
    func providerWithoutContainerKeepsStoredReveal() throws {
        let store = makeStore()
        try store.saveDeck(WidgetDeck(generatedAt: now, pathId: nil, cards: [card(1), card(2)]))
        let reveal = WidgetInteractionState(revealedWordId: 1, revealedAt: now.addingTimeInterval(-5))
        try store.saveInteraction(reveal)

        let provider = VocabWidgetProvider(store: store, container: nil)
        let timeline = provider.makeTimeline(now: now)

        #expect(store.loadInteraction() == reveal)
        #expect(timeline.policy == .after(now.addingTimeInterval(300)))
    }

    @Test("providerWithoutDeckReturnsPlaceholder")
    func providerWithoutDeckReturnsPlaceholder() {
        let provider = VocabWidgetProvider(store: makeStore(), container: nil)

        let timeline = provider.makeTimeline(now: now)

        #expect(timeline.entries == [.placeholder(at: now)])
    }

    @Test("sharedContainerIsAvailable")
    func sharedContainerIsAvailable() {
        #expect(WidgetContainerHolder.sharedContainer != nil)
    }
}
#endif
