import Foundation

public struct VaultWordItem: Identifiable, Sendable, Equatable, ReflexDrillable {
    public let id: Int64
    public let senseID: SenseID?
    public var senseId: SenseID? { senseID }
    public let lemma: String
    public let pos: String
    public let phonetic: String
    public let definitionVi: String
    public let exampleSentenceEn: String
    public let exampleSentenceVi: String
    public let cefrLevel: String

    public let isMastered: Bool
    public let isBookmarked: Bool
    public let correctStreak: Int
    public let practicedModes: Set<ReflexBlitzMode>
    public let lastPracticedAt: Date?
    public let modeStats: ModeSuccessStats

    public init(
        id: Int64,
        senseID: SenseID? = nil,
        lemma: String,
        pos: String,
        phonetic: String = "",
        definitionVi: String,
        exampleSentenceEn: String = "",
        exampleSentenceVi: String = "",
        cefrLevel: String? = nil,
        isMastered: Bool = false,
        isBookmarked: Bool = false,
        correctStreak: Int = 0,
        practicedModes: Set<ReflexBlitzMode> = [],
        lastPracticedAt: Date? = nil,
        modeStats: ModeSuccessStats = ModeSuccessStats()
    ) {
        self.id = id
        self.senseID = senseID
        self.lemma = lemma
        self.pos = pos
        self.phonetic = phonetic
        self.definitionVi = definitionVi
        self.exampleSentenceEn = exampleSentenceEn
        self.exampleSentenceVi = exampleSentenceVi
        self.cefrLevel = cefrLevel ?? ""
        self.isMastered = isMastered
        self.isBookmarked = isBookmarked
        self.correctStreak = correctStreak
        self.practicedModes = practicedModes
        self.lastPracticedAt = lastPracticedAt
        self.modeStats = modeStats
    }

    public init(
        sense: SenseDetail,
        isMastered: Bool = false,
        isBookmarked: Bool = false,
        correctStreak: Int = 0,
        practicedModes: Set<ReflexBlitzMode> = [],
        lastPracticedAt: Date? = nil,
        modeStats: ModeSuccessStats = ModeSuccessStats()
    ) {
        self.id = 0
        self.senseID = sense.id
        self.lemma = sense.headword
        self.pos = sense.partOfSpeech.rawValue
        self.phonetic = sense.ipa ?? ""
        self.definitionVi = sense.definitionVI
        self.exampleSentenceEn = sense.examples.first?.textEN ?? ""
        self.exampleSentenceVi = sense.examples.first?.textVI ?? ""
        self.cefrLevel = sense.cefrLevel.rawValue
        self.isMastered = isMastered
        self.isBookmarked = isBookmarked
        self.correctStreak = correctStreak
        self.practicedModes = practicedModes
        self.lastPracticedAt = lastPracticedAt
        self.modeStats = modeStats
    }

    public var ipa: String { phonetic }
    public var clozeSentenceEn: String {
        ReflexClozeFormatter.formatCloze(sentenceEn: exampleSentenceEn, lemma: lemma)
    }
    public var audioResourceUrl: String? { nil }
}
