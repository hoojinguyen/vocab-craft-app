import Foundation

public enum WidgetKind {
    public static let vocab = "VocabWidget"
}

public struct WidgetCard: Codable, Sendable, Equatable, Identifiable {
    public enum Source: String, Codable, Sendable {
        case due, recent, upcoming
    }

    public var wordId: Int64
    public var lemma: String
    public var ipa: String
    public var definitionVi: String
    public var exampleEn: String
    public var source: Source
    /// Raw `senses.part_of_speech` value; `nil` when the catalog has none.
    public var partOfSpeech: String?

    public var id: Int64 { wordId }

    public init(
        wordId: Int64,
        lemma: String,
        ipa: String,
        definitionVi: String,
        exampleEn: String,
        source: Source,
        partOfSpeech: String? = nil
    ) {
        self.wordId = wordId
        self.lemma = lemma
        self.ipa = ipa
        self.definitionVi = definitionVi
        self.exampleEn = exampleEn
        self.source = source
        self.partOfSpeech = partOfSpeech
    }
}

public struct WidgetDeck: Codable, Sendable, Equatable {
    public static let currentVersion = 2

    public var version: Int
    public var generatedAt: Date
    public var pathId: String?
    public var cards: [WidgetCard]

    public init(
        version: Int = WidgetDeck.currentVersion,
        generatedAt: Date,
        pathId: String?,
        cards: [WidgetCard]
    ) {
        self.version = version
        self.generatedAt = generatedAt
        self.pathId = pathId
        self.cards = cards
    }
}

public struct WidgetInteractionState: Codable, Sendable, Equatable {
    public var revealedWordId: Int64?
    public var revealedAt: Date?

    public static let empty = WidgetInteractionState(revealedWordId: nil, revealedAt: nil)

    public init(revealedWordId: Int64? = nil, revealedAt: Date? = nil) {
        self.revealedWordId = revealedWordId
        self.revealedAt = revealedAt
    }
}
