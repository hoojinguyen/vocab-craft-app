import Foundation
import Testing
@testable import VocabCraftApp

@Suite("WidgetTimelineBuilder")
struct WidgetTimelineBuilderTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func card(_ id: Int64) -> WidgetCard {
        WidgetCard(
            wordId: id,
            lemma: "word\(id)",
            ipa: "/w\(id)/",
            definitionVi: "nghia \(id)",
            exampleEn: "Example \(id).",
            source: .recent
        )
    }

    private func deck(_ count: Int) -> WidgetDeck {
        WidgetDeck(
            generatedAt: now,
            pathId: nil,
            cards: (0..<count).map { card(Int64($0 + 1)) }
        )
    }

    private func build(
        _ deck: WidgetDeck?,
        due: Set<Int64> = [],
        nextDue: Date? = nil,
        interaction: WidgetInteractionState = .empty,
        at date: Date? = nil
    ) -> (entries: [VocabWidgetEntry], reload: WidgetReloadPlan) {
        WidgetTimelineBuilder.build(
            deck: deck,
            dueWordIds: due,
            nextDueDate: nextDue,
            interaction: interaction,
            now: date ?? now
        )
    }

    @Test func nilDeckGivesPlaceholder() {
        let result = build(nil)
        #expect(result.entries.count == 1)
        #expect(result.entries[0].mode == .placeholder)
        #expect(result.reload == .after(now.addingTimeInterval(3600)))
    }

    @Test func emptyDeckGivesPlaceholder() {
        let result = build(deck(0))
        #expect(result.entries.count == 1)
        #expect(result.entries[0].mode == .placeholder)
        #expect(result.reload == .after(now.addingTimeInterval(3600)))
    }

    @Test func passiveEntriesFiveMinutesApart() {
        let result = build(deck(3))
        #expect(result.entries.count == 36)
        #expect(result.entries[1].date.timeIntervalSince(result.entries[0].date) == 300)
        #expect(result.reload == .atEnd)
    }

    @Test func rotationContinuesAcrossReloads() {
        let first = build(deck(3))
        let soon = build(deck(3), at: now.addingTimeInterval(120))
        let later = build(deck(3), at: now.addingTimeInterval(300))
        #expect(soon.entries[0].card == first.entries[0].card)
        #expect(later.entries[0].card == first.entries[1].card)
    }

    @Test func shortDeckCycles() {
        let result = build(deck(6))
        #expect(result.entries.count == 36)
        #expect(result.entries.allSatisfy { $0.card != nil })
        #expect(result.entries[6].card == result.entries[0].card)
    }

    @Test func dueWordGivesSingleFlashcard() {
        let result = build(deck(3), due: [2])
        #expect(result.entries.count == 1)
        #expect(result.entries[0].card?.wordId == 2)
        #expect(result.entries[0].mode == .flashcardFront)
        #expect(result.entries[0].dueCount == 1)
        #expect(result.reload == .after(now.addingTimeInterval(3600)))
    }

    @Test func revealStateFlipsOnlyMatchingCard() {
        let revealed = build(deck(3), due: [2], interaction: WidgetInteractionState(revealedWordId: 2, revealedAt: now))
        #expect(revealed.entries[0].mode == .flashcardBack)
        let other = build(deck(3), due: [2], interaction: WidgetInteractionState(revealedWordId: 9, revealedAt: now))
        #expect(other.entries[0].mode == .flashcardFront)
    }

    @Test func allCardsDueStaysInFlashcard() {
        let all = build(deck(3), due: [1, 2, 3])
        #expect(all.entries.count == 1)
        #expect(all.entries[0].dueCount == 3)
        #expect(all.entries[0].mode == .flashcardFront)
        let partial = build(deck(3), due: [2, 3])
        #expect(partial.entries[0].dueCount == 2)
        #expect(partial.entries[0].card?.wordId == 2)
    }

    @Test func passiveCappedAtNextDueDate() {
        let cap = now.addingTimeInterval(1000)
        let result = build(deck(3), nextDue: cap)
        #expect(result.entries.count == 4)
        #expect(result.entries.allSatisfy { $0.date < cap })
        #expect(result.reload == .after(cap))
    }

    @Test func pastNextDueDateIsIgnored() {
        for nextDue in [now.addingTimeInterval(-60), now] {
            let result = build(deck(3), nextDue: nextDue)
            #expect(result.entries.count == 36)
            #expect(result.reload == .atEnd)
        }
    }
}
