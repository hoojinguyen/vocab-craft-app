import Foundation
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif
import WidgetKit

public enum WidgetEntryMode: Equatable, Sendable {
    case placeholder, passive, flashcardFront, flashcardBack
}

public struct VocabWidgetEntry: TimelineEntry, Equatable, Sendable {
    public let date: Date
    public let card: WidgetCard?
    public let mode: WidgetEntryMode
    public let dueCount: Int
    /// Words practiced since the start of the current day (learned or reviewed).
    public let practicedToday: Int

    public init(date: Date, card: WidgetCard?, mode: WidgetEntryMode, dueCount: Int, practicedToday: Int = 0) {
        self.date = date
        self.card = card
        self.mode = mode
        self.dueCount = dueCount
        self.practicedToday = practicedToday
    }

    public static func placeholder(at date: Date) -> VocabWidgetEntry {
        VocabWidgetEntry(date: date, card: nil, mode: .placeholder, dueCount: 0)
    }
}

public enum WidgetReloadPlan: Equatable, Sendable {
    case atEnd
    case after(Date)
}

public enum WidgetTimelineBuilder {
    public static let rotationInterval: TimeInterval = 300
    public static let maxEntries = 36
    static let placeholderRetry: TimeInterval = 3600
    public static let flashcardRefresh: TimeInterval = 3600

    public static func build(
        deck: WidgetDeck?,
        dueWordIds: Set<Int64>,
        nextDueDate: Date?,
        interaction: WidgetInteractionState,
        practicedToday: Int = 0,
        now: Date
    ) -> (entries: [VocabWidgetEntry], reload: WidgetReloadPlan) {
        guard let deck, !deck.cards.isEmpty else {
            return ([.placeholder(at: now)], .after(now.addingTimeInterval(placeholderRetry)))
        }

        let dueCards = deck.cards.filter { dueWordIds.contains($0.wordId) }
        if let first = dueCards.first {
            let mode: WidgetEntryMode = interaction.revealedWordId == first.wordId ? .flashcardBack : .flashcardFront
            let entry = VocabWidgetEntry(
                date: now,
                card: first,
                mode: mode,
                dueCount: dueCards.count,
                practicedToday: practicedToday
            )
            return ([entry], .after(now.addingTimeInterval(flashcardRefresh)))
        }

        let cards = deck.cards
        let slot = Int(now.timeIntervalSince1970 / rotationInterval)
        var entries: [VocabWidgetEntry] = []
        let cap = nextDueDate.flatMap { $0 > now ? $0 : nil }
        var dropped = false
        for i in 0..<maxEntries {
            let date = i == 0 ? now : Date(timeIntervalSince1970: Double(slot + i) * rotationInterval)
            if let cap, date >= cap {
                dropped = true
                break
            }
            entries.append(
                VocabWidgetEntry(
                    date: date,
                    card: cards[(slot + i) % cards.count],
                    mode: .passive,
                    dueCount: 0,
                    practicedToday: practicedToday
                )
            )
        }
        if dropped, let cap {
            return (entries, .after(cap))
        }
        return (entries, .atEnd)
    }
}
