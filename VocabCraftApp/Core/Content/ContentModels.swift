import Foundation

// MARK: - Enums

public enum EntryKind: String, Codable, Sendable, CaseIterable {
    case word
    case phrasalVerb = "phrasal_verb"
    case phrase
    case idiom
}

public enum PartOfSpeech: String, Codable, Sendable, CaseIterable {
    case noun, verb, adjective, adverb, pronoun
    case determiner, preposition, conjunction, interjection
    case numeral, particle, other
}

// swiftlint:disable identifier_name
public enum CEFRLevel: String, Codable, Sendable, CaseIterable, Comparable {
    case a1 = "A1", a2 = "A2", b1 = "B1", b2 = "B2", c1 = "C1", c2 = "C2"

    private var rank: Int {
        switch self {
        case .a1: return 1
        case .a2: return 2
        case .b1: return 3
        case .b2: return 4
        case .c1: return 5
        case .c2: return 6
        }
    }

    public static func < (lhs: CEFRLevel, rhs: CEFRLevel) -> Bool {
        lhs.rank < rhs.rank
    }
}

public enum Accent: String, Codable, Sendable, CaseIterable {
    case us, uk
}
// swiftlint:enable identifier_name

public enum ReviewDecision: String, Codable, Sendable {
    case approved, rejected
}

public enum RightsBasis: String, Codable, Sendable {
    case original, licensed, permission
    case publicDomain = "public_domain"
}

// MARK: - Dataset Snapshot Models

public struct EntrySnapshot: Codable, Hashable, Sendable, Identifiable {
    public let id: EntryID
    public let headword: String
    public let lookupKey: String
    public let entryKind: EntryKind
    public let revision: Int

    enum CodingKeys: String, CodingKey {
        case id, headword, revision
        case lookupKey = "lookup_key"
        case entryKind = "entry_kind"
    }

    public init(id: EntryID, headword: String, lookupKey: String, entryKind: EntryKind, revision: Int = 1) {
        self.id = id
        self.headword = headword
        self.lookupKey = lookupKey
        self.entryKind = entryKind
        self.revision = revision
    }
}

public struct SenseSnapshot: Codable, Hashable, Sendable, Identifiable {
    public let id: SenseID
    public let entryID: EntryID
    public let partOfSpeech: PartOfSpeech
    public let definitionEN: String
    public let definitionVI: String
    public let cefrLevel: CEFRLevel
    public let usageNoteEN: String?
    public let usageNoteVI: String?
    public let sortOrder: Int
    public let revision: Int

    enum CodingKeys: String, CodingKey {
        case id, revision
        case entryID = "entry_id"
        case partOfSpeech = "part_of_speech"
        case definitionEN = "definition_en"
        case definitionVI = "definition_vi"
        case cefrLevel = "cefr_level"
        case usageNoteEN = "usage_note_en"
        case usageNoteVI = "usage_note_vi"
        case sortOrder = "sort_order"
    }

    public init(
        id: SenseID, entryID: EntryID, partOfSpeech: PartOfSpeech,
        definitionEN: String, definitionVI: String, cefrLevel: CEFRLevel,
        usageNoteEN: String? = nil, usageNoteVI: String? = nil,
        sortOrder: Int = 0, revision: Int = 1
    ) {
        self.id = id
        self.entryID = entryID
        self.partOfSpeech = partOfSpeech
        self.definitionEN = definitionEN
        self.definitionVI = definitionVI
        self.cefrLevel = cefrLevel
        self.usageNoteEN = usageNoteEN
        self.usageNoteVI = usageNoteVI
        self.sortOrder = sortOrder
        self.revision = revision
    }
}

public struct PronunciationSnapshot: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let entryID: EntryID
    public let senseID: SenseID?
    public let accent: Accent
    public let ipa: String
    public let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, accent, ipa
        case entryID = "entry_id"
        case senseID = "sense_id"
        case sortOrder = "sort_order"
    }

    public init(
        id: String, entryID: EntryID, senseID: SenseID? = nil,
        accent: Accent, ipa: String, sortOrder: Int = 0
    ) {
        self.id = id
        self.entryID = entryID
        self.senseID = senseID
        self.accent = accent
        self.ipa = ipa
        self.sortOrder = sortOrder
    }
}

public struct ExampleSnapshot: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let senseID: SenseID
    public let textEN: String
    public let textVI: String
    public var textEn: String { textEN }
    public var textVi: String { textVI }
    public let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case senseID = "sense_id"
        case textEN = "text_en"
        case textVI = "text_vi"
        case sortOrder = "sort_order"
    }

    public init(id: String, senseID: SenseID, textEN: String, textVI: String, sortOrder: Int = 0) {
        self.id = id
        self.senseID = senseID
        self.textEN = textEN
        self.textVI = textVI
        self.sortOrder = sortOrder
    }
}

public struct CollocationSnapshot: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let senseID: SenseID
    public let textEN: String
    public let textVI: String
    public let exampleID: String?
    public let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case senseID = "sense_id"
        case textEN = "text_en"
        case textVI = "text_vi"
        case exampleID = "example_id"
        case sortOrder = "sort_order"
    }

    public init(
        id: String, senseID: SenseID, textEN: String,
        textVI: String, exampleID: String? = nil, sortOrder: Int = 0
    ) {
        self.id = id
        self.senseID = senseID
        self.textEN = textEN
        self.textVI = textVI
        self.exampleID = exampleID
        self.sortOrder = sortOrder
    }
}

public struct DeckSnapshot: Codable, Hashable, Sendable, Identifiable {
    public let id: DeckID
    public let titleEN: String
    public let titleVI: String
    public let descriptionEN: String?
    public let descriptionVI: String?
    public let iconKey: String
    public let themeKey: String
    public let sortOrder: Int
    public let revision: Int

    enum CodingKeys: String, CodingKey {
        case id, revision
        case titleEN = "title_en"
        case titleVI = "title_vi"
        case descriptionEN = "description_en"
        case descriptionVI = "description_vi"
        case iconKey = "icon_key"
        case themeKey = "theme_key"
        case sortOrder = "sort_order"
    }

    public init(
        id: DeckID, titleEN: String, titleVI: String,
        descriptionEN: String? = nil, descriptionVI: String? = nil,
        iconKey: String, themeKey: String, sortOrder: Int = 0, revision: Int = 1
    ) {
        self.id = id
        self.titleEN = titleEN
        self.titleVI = titleVI
        self.descriptionEN = descriptionEN
        self.descriptionVI = descriptionVI
        self.iconKey = iconKey
        self.themeKey = themeKey
        self.sortOrder = sortOrder
        self.revision = revision
    }
}

public struct LessonSnapshot: Codable, Hashable, Sendable, Identifiable {
    public let id: LessonID
    public let deckID: DeckID
    public let titleEN: String
    public let titleVI: String
    public let iconKey: String
    public let sortOrder: Int
    public let revision: Int

    enum CodingKeys: String, CodingKey {
        case id, revision
        case deckID = "deck_id"
        case titleEN = "title_en"
        case titleVI = "title_vi"
        case iconKey = "icon_key"
        case sortOrder = "sort_order"
    }

    public init(
        id: LessonID, deckID: DeckID, titleEN: String,
        titleVI: String, iconKey: String, sortOrder: Int = 0, revision: Int = 1
    ) {
        self.id = id
        self.deckID = deckID
        self.titleEN = titleEN
        self.titleVI = titleVI
        self.iconKey = iconKey
        self.sortOrder = sortOrder
        self.revision = revision
    }
}

public struct LessonSenseSnapshot: Codable, Hashable, Sendable {
    public let lessonID: LessonID
    public let senseID: SenseID
    public let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case lessonID = "lesson_id"
        case senseID = "sense_id"
        case sortOrder = "sort_order"
    }

    public init(lessonID: LessonID, senseID: SenseID, sortOrder: Int = 0) {
        self.lessonID = lessonID
        self.senseID = senseID
        self.sortOrder = sortOrder
    }
}

public struct AttributionSnapshot: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let text: String
    public let sourceURL: String?
    public let licenseIdentifier: String?

    enum CodingKeys: String, CodingKey {
        case id, text
        case sourceURL = "source_url"
        case licenseIdentifier = "license_identifier"
    }
}

public struct SenseAttributionSnapshot: Codable, Hashable, Sendable {
    public let senseID: SenseID
    public let attributionID: String

    enum CodingKeys: String, CodingKey {
        case senseID = "sense_id"
        case attributionID = "attribution_id"
    }
}

public struct RetiredSenseSnapshot: Codable, Hashable, Sendable {
    public let senseID: SenseID
    public let retiredInVersion: Int

    enum CodingKeys: String, CodingKey {
        case senseID = "sense_id"
        case retiredInVersion = "retired_in_version"
    }
}

public struct ContentReviewSnapshot: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let entityType: String
    public let entityID: String
    public let revision: Int
    public let decision: ReviewDecision
    public let reviewerID: String
    public let reviewedAt: String
    public let note: String?

    enum CodingKeys: String, CodingKey {
        case id, revision, decision, note
        case entityType = "entity_type"
        case entityID = "entity_id"
        case reviewerID = "reviewer_id"
        case reviewedAt = "reviewed_at"
    }
}

public struct ContentSourceSnapshot: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let sourceName: String
    public let sourceURL: String?
    public let attributionText: String
    public let rightsBasis: RightsBasis
    public let licenseIdentifier: String?
    public let retrievedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceName = "source_name"
        case sourceURL = "source_url"
        case attributionText = "attribution_text"
        case rightsBasis = "rights_basis"
        case licenseIdentifier = "license_identifier"
        case retrievedAt = "retrieved_at"
    }
}

public struct ContentSourceLinkSnapshot: Codable, Hashable, Sendable {
    public let sourceID: String
    public let entityType: String
    public let entityID: String
    public let revision: Int
    public let locator: String?

    enum CodingKeys: String, CodingKey {
        case locator, revision
        case sourceID = "source_id"
        case entityType = "entity_type"
        case entityID = "entity_id"
    }
}

public struct DatasetSnapshot: Codable, Hashable, Sendable {
    public let datasetSchemaVersion: Int
    public let contentVersion: Int
    public let publishedAt: String
    public let contentLanguage: String
    public let explanationLanguage: String
    public let entries: [EntrySnapshot]
    public let senses: [SenseSnapshot]
    public let pronunciations: [PronunciationSnapshot]
    public let examples: [ExampleSnapshot]
    public let collocations: [CollocationSnapshot]
    public let decks: [DeckSnapshot]
    public let lessons: [LessonSnapshot]
    public let lessonSenses: [LessonSenseSnapshot]
    public let attributions: [AttributionSnapshot]
    public let senseAttributions: [SenseAttributionSnapshot]
    public let retiredSenses: [RetiredSenseSnapshot]
    public let reviews: [ContentReviewSnapshot]?
    public let sources: [ContentSourceSnapshot]?
    public let sourceLinks: [ContentSourceLinkSnapshot]?

    enum CodingKeys: String, CodingKey {
        case entries, senses, pronunciations, examples, collocations, decks, lessons, attributions, reviews, sources
        case datasetSchemaVersion = "dataset_schema_version"
        case contentVersion = "content_version"
        case publishedAt = "published_at"
        case contentLanguage = "content_language"
        case explanationLanguage = "explanation_language"
        case lessonSenses = "lesson_senses"
        case senseAttributions = "sense_attributions"
        case retiredSenses = "retired_senses"
        case contentReviews = "content_reviews"
        case contentSources = "content_sources"
        case sourceLinks = "source_links"
        case contentSourceLinks = "content_source_links"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        datasetSchemaVersion = try container.decode(Int.self, forKey: .datasetSchemaVersion)
        contentVersion = try container.decode(Int.self, forKey: .contentVersion)
        publishedAt = try container.decode(String.self, forKey: .publishedAt)
        contentLanguage = try container.decodeIfPresent(String.self, forKey: .contentLanguage) ?? "en"
        explanationLanguage = try container.decodeIfPresent(String.self, forKey: .explanationLanguage) ?? "vi"
        entries = try container.decode([EntrySnapshot].self, forKey: .entries)
        senses = try container.decode([SenseSnapshot].self, forKey: .senses)
        pronunciations = try container.decode([PronunciationSnapshot].self, forKey: .pronunciations)
        examples = try container.decode([ExampleSnapshot].self, forKey: .examples)
        collocations = try container.decode([CollocationSnapshot].self, forKey: .collocations)
        decks = try container.decode([DeckSnapshot].self, forKey: .decks)
        lessons = try container.decode([LessonSnapshot].self, forKey: .lessons)
        lessonSenses = try container.decode([LessonSenseSnapshot].self, forKey: .lessonSenses)
        attributions = try container.decode([AttributionSnapshot].self, forKey: .attributions)
        senseAttributions = try container.decode([SenseAttributionSnapshot].self, forKey: .senseAttributions)
        retiredSenses = try container.decode([RetiredSenseSnapshot].self, forKey: .retiredSenses)
        let decodedReviews = try container.decodeIfPresent([ContentReviewSnapshot].self, forKey: .reviews)
        let fallbackReviews = try container.decodeIfPresent([ContentReviewSnapshot].self, forKey: .contentReviews)
        reviews = decodedReviews ?? fallbackReviews
        let decodedSources = try container.decodeIfPresent([ContentSourceSnapshot].self, forKey: .sources)
        let fallbackSources = try container.decodeIfPresent([ContentSourceSnapshot].self, forKey: .contentSources)
        sources = decodedSources ?? fallbackSources
        let decodedLinks = try container.decodeIfPresent([ContentSourceLinkSnapshot].self, forKey: .sourceLinks)
        let fallbackLinks = try container.decodeIfPresent([ContentSourceLinkSnapshot].self, forKey: .contentSourceLinks)
        sourceLinks = decodedLinks ?? fallbackLinks
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(datasetSchemaVersion, forKey: .datasetSchemaVersion)
        try container.encode(contentVersion, forKey: .contentVersion)
        try container.encode(publishedAt, forKey: .publishedAt)
        try container.encode(contentLanguage, forKey: .contentLanguage)
        try container.encode(explanationLanguage, forKey: .explanationLanguage)
        try container.encode(entries, forKey: .entries)
        try container.encode(senses, forKey: .senses)
        try container.encode(pronunciations, forKey: .pronunciations)
        try container.encode(examples, forKey: .examples)
        try container.encode(collocations, forKey: .collocations)
        try container.encode(decks, forKey: .decks)
        try container.encode(lessons, forKey: .lessons)
        try container.encode(lessonSenses, forKey: .lessonSenses)
        try container.encode(attributions, forKey: .attributions)
        try container.encode(senseAttributions, forKey: .senseAttributions)
        try container.encode(retiredSenses, forKey: .retiredSenses)
        try container.encodeIfPresent(reviews, forKey: .reviews)
        try container.encodeIfPresent(sources, forKey: .sources)
        try container.encodeIfPresent(sourceLinks, forKey: .sourceLinks)
    }
}

// MARK: - Domain Content Models

public struct SenseSummary: Codable, Hashable, Sendable, Identifiable {
    public var id: SenseID { senseID }
    public let senseID: SenseID
    public let entryID: EntryID
    public let headword: String
    public let entryKind: EntryKind
    public let partOfSpeech: PartOfSpeech
    public let definitionEN: String
    public let definitionVI: String
    public var definitionEn: String { definitionEN }
    public var definitionVi: String { definitionVI }
    public let cefrLevel: CEFRLevel
    public let ipa: String?
    public let sortOrder: Int
    public let revision: Int

    enum CodingKeys: String, CodingKey {
        case headword, ipa, revision
        case senseID = "sense_id"
        case entryID = "entry_id"
        case entryKind = "entry_kind"
        case partOfSpeech = "part_of_speech"
        case definitionEN = "definition_en"
        case definitionVI = "definition_vi"
        case cefrLevel = "cefr_level"
        case sortOrder = "sort_order"
    }

    public init(
        senseID: SenseID, entryID: EntryID, headword: String,
        entryKind: EntryKind, partOfSpeech: PartOfSpeech,
        definitionEN: String, definitionVI: String, cefrLevel: CEFRLevel,
        ipa: String? = nil, sortOrder: Int = 0, revision: Int = 1
    ) {
        self.senseID = senseID
        self.entryID = entryID
        self.headword = headword
        self.entryKind = entryKind
        self.partOfSpeech = partOfSpeech
        self.definitionEN = definitionEN
        self.definitionVI = definitionVI
        self.cefrLevel = cefrLevel
        self.ipa = ipa
        self.sortOrder = sortOrder
        self.revision = revision
    }
}

/// Detailed sense model for learning screens and full detail views.
/// NOTE: SenseDetail MUST NOT own `lessonId` or `stageId`.
public struct SenseDetail: Codable, Hashable, Sendable, Identifiable {
    public let id: SenseID
    public var senseID: SenseID { id }
    public let entryID: EntryID
    public let headword: String
    public let entryKind: EntryKind
    public let partOfSpeech: PartOfSpeech
    public let definitionEN: String
    public let definitionVI: String
    public var definitionEn: String { definitionEN }
    public var definitionVi: String { definitionVI }
    public let cefrLevel: CEFRLevel
    public let usageNoteEN: String?
    public let usageNoteVI: String?
    public var usageNoteEn: String? { usageNoteEN }
    public var usageNoteVi: String? { usageNoteVI }
    public let ipa: String?
    public let pronunciations: [PronunciationSnapshot]
    public let examples: [ExampleSnapshot]
    public let collocations: [CollocationSnapshot]
    public let attributions: [AttributionSnapshot]
    public let sortOrder: Int
    public let revision: Int

    enum CodingKeys: String, CodingKey {
        case id, headword, ipa, pronunciations, examples, collocations, attributions, revision
        case entryID = "entry_id"
        case entryKind = "entry_kind"
        case partOfSpeech = "part_of_speech"
        case definitionEN = "definition_en"
        case definitionVI = "definition_vi"
        case cefrLevel = "cefr_level"
        case usageNoteEN = "usage_note_en"
        case usageNoteVI = "usage_note_vi"
        case sortOrder = "sort_order"
    }

    public init(
        id: SenseID, entryID: EntryID, headword: String,
        entryKind: EntryKind, partOfSpeech: PartOfSpeech,
        definitionEN: String, definitionVI: String, cefrLevel: CEFRLevel,
        usageNoteEN: String? = nil, usageNoteVI: String? = nil, ipa: String? = nil,
        pronunciations: [PronunciationSnapshot] = [], examples: [ExampleSnapshot] = [],
        collocations: [CollocationSnapshot] = [], attributions: [AttributionSnapshot] = [],
        sortOrder: Int = 0, revision: Int = 1
    ) {
        self.id = id
        self.entryID = entryID
        self.headword = headword
        self.entryKind = entryKind
        self.partOfSpeech = partOfSpeech
        self.definitionEN = definitionEN
        self.definitionVI = definitionVI
        self.cefrLevel = cefrLevel
        self.usageNoteEN = usageNoteEN
        self.usageNoteVI = usageNoteVI
        self.ipa = ipa
        self.pronunciations = pronunciations
        self.examples = examples
        self.collocations = collocations
        self.attributions = attributions
        self.sortOrder = sortOrder
        self.revision = revision
    }
}

public struct EntryDetail: Codable, Hashable, Sendable, Identifiable {
    public let id: EntryID
    public let headword: String
    public let lookupKey: String
    public let entryKind: EntryKind
    public let revision: Int
    public let senses: [SenseSummary]
    public let pronunciations: [PronunciationSnapshot]

    enum CodingKeys: String, CodingKey {
        case id, headword, revision, senses, pronunciations
        case lookupKey = "lookup_key"
        case entryKind = "entry_kind"
    }

    public init(
        id: EntryID, headword: String, lookupKey: String,
        entryKind: EntryKind, revision: Int = 1,
        senses: [SenseSummary] = [], pronunciations: [PronunciationSnapshot] = []
    ) {
        self.id = id
        self.headword = headword
        self.lookupKey = lookupKey
        self.entryKind = entryKind
        self.revision = revision
        self.senses = senses
        self.pronunciations = pronunciations
    }
}

public struct LessonDetail: Codable, Hashable, Sendable, Identifiable {
    public let id: LessonID
    public let deckID: DeckID
    public let titleEN: String
    public let titleVI: String
    public var titleEn: String { titleEN }
    public var titleVi: String { titleVI }
    public let iconKey: String
    public let sortOrder: Int
    public let revision: Int
    public let senses: [SenseSummary]

    enum CodingKeys: String, CodingKey {
        case id, revision, senses
        case deckID = "deck_id"
        case titleEN = "title_en"
        case titleVI = "title_vi"
        case iconKey = "icon_key"
        case sortOrder = "sort_order"
    }

    public init(
        id: LessonID, deckID: DeckID, titleEN: String,
        titleVI: String, iconKey: String, sortOrder: Int = 0,
        revision: Int = 1, senses: [SenseSummary] = []
    ) {
        self.id = id
        self.deckID = deckID
        self.titleEN = titleEN
        self.titleVI = titleVI
        self.iconKey = iconKey
        self.sortOrder = sortOrder
        self.revision = revision
        self.senses = senses
    }
}

public struct DeckSummary: Codable, Hashable, Sendable, Identifiable {
    public let id: DeckID
    public let titleEN: String
    public let titleVI: String
    public var titleEn: String { titleEN }
    public var titleVi: String { titleVI }
    public let descriptionEN: String?
    public let descriptionVI: String?
    public var descriptionEn: String? { descriptionEN }
    public var descriptionVi: String? { descriptionVI }
    public let iconKey: String
    public let themeKey: String
    public let sortOrder: Int
    public let revision: Int
    public let cefrLevels: [CEFRLevel]

    enum CodingKeys: String, CodingKey {
        case id, revision
        case titleEN = "title_en"
        case titleVI = "title_vi"
        case descriptionEN = "description_en"
        case descriptionVI = "description_vi"
        case iconKey = "icon_key"
        case themeKey = "theme_key"
        case sortOrder = "sort_order"
        case cefrLevels = "cefr_levels"
    }

    public init(
        id: DeckID, titleEN: String, titleVI: String,
        descriptionEN: String? = nil, descriptionVI: String? = nil,
        iconKey: String, themeKey: String, sortOrder: Int = 0,
        revision: Int = 1, cefrLevels: [CEFRLevel] = []
    ) {
        self.id = id
        self.titleEN = titleEN
        self.titleVI = titleVI
        self.descriptionEN = descriptionEN
        self.descriptionVI = descriptionVI
        self.iconKey = iconKey
        self.themeKey = themeKey
        self.sortOrder = sortOrder
        self.revision = revision
        self.cefrLevels = cefrLevels
    }
}
