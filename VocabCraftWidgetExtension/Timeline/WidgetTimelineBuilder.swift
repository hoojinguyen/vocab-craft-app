import Foundation
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif
import WidgetKit

public enum WidgetEntryMode: Equatable, Sendable {
    case placeholder, passive, flashcardFront, flashcardBack
}

public struct VocabWidgetEntry: TimelineEntry, Equatable {
    public let date: Date
    public let card: WidgetCard?
    public let mode: WidgetEntryMode
    public let dueCount: Int

    public init(date: Date, card: WidgetCard?, mode: WidgetEntryMode, dueCount: Int) {
        self.date = date
        self.card = card
        self.mode = mode
        self.dueCount = dueCount
    }

    public static func placeholder(at date: Date) -> VocabWidgetEntry {
        VocabWidgetEntry(date: date, card: nil, mode: .placeholder, dueCount: 0)
    }
}

public enum WidgetReloadPlan: Equatable, Sendable {
    case atEnd
    case after(Date)
    case never
}

public enum WidgetTimelineBuilder {
    public static let rotationInterval: TimeInterval = 300
    public static let maxEntries = 36
    static let placeholderRetry: TimeInterval = 3600

    public static func build(
        deck: WidgetDeck?,
        dueWordIds: Set<Int64>,
        nextDueDate: Date?,
        interaction: WidgetInteractionState,
        now: Date
    ) -> (entries: [VocabWidgetEntry], reload: WidgetReloadPlan) {
        guard let deck, !deck.cards.isEmpty else {
            return ([.placeholder(at: now)], .after(now.addingTimeInterval(placeholderRetry)))
        }

        let dueCards = deck.cards.filter { dueWordIds.contains($0.wordId) }
        if let first = dueCards.first {
            let mode: WidgetEntryMode = interaction.revealedWordId == first.wordId ? .flashcardBack : .flashcardFront
            let entry = VocabWidgetEntry(date: now, card: first, mode: mode, dueCount: dueCards.count)
            return ([entry], .never)
        }

        let cards = deck.cards
        let slot = Int(now.timeIntervalSince1970 / rotationInterval)
        var entries: [VocabWidgetEntry] = []
        var dropped = false
        for i in 0..<maxEntries {
            let date = i == 0 ? now : Date(timeIntervalSince1970: Double(slot + i) * rotationInterval)
            if i > 0, let nextDueDate, date >= nextDueDate {
                dropped = true
                break
            }
            entries.append(
                VocabWidgetEntry(date: date, card: cards[(slot + i) % cards.count], mode: .passive, dueCount: 0)
            )
        }
        if dropped, let nextDueDate {
            return (entries, .after(nextDueDate))
        }
        return (entries, .atEnd)
    }
}
