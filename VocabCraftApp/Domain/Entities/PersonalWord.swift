import Foundation

public struct PersonalWord: Identifiable, Sendable, Equatable {
    public let id: Int64
    public let senseID: SenseID?
    public var senseId: SenseID? { senseID }
    public let lemma: String
    public let phonetic: String
    public let pos: String
    public let cefrLevel: String
    public let definitionVi: String
    public let definitionEn: String
    public let exampleEn: String
    public let exampleVi: String
    public var masteryLevel: Int
    public var isBookmarked: Bool
    public var needsReview: Bool
    public var mistakeCount: Int
    public var sourceDeckTitle: String?
    public var sourceStageTitle: String?

    public init(
        id: Int64,
        senseID: SenseID? = nil,
        lemma: String,
        phonetic: String,
        pos: String,
        cefrLevel: String,
        definitionVi: String,
        definitionEn: String,
        exampleEn: String,
        exampleVi: String,
        masteryLevel: Int = 0,
        isBookmarked: Bool = false,
        needsReview: Bool = false,
        mistakeCount: Int = 0,
        sourceDeckTitle: String? = nil,
        sourceStageTitle: String? = nil
    ) {
        self.id = id
        self.senseID = senseID
        self.lemma = lemma
        self.phonetic = phonetic
        self.pos = pos
        self.cefrLevel = cefrLevel
        self.definitionVi = definitionVi
        self.definitionEn = definitionEn
        self.exampleEn = exampleEn
        self.exampleVi = exampleVi
        self.masteryLevel = masteryLevel
        self.isBookmarked = isBookmarked
        self.needsReview = needsReview
        self.mistakeCount = mistakeCount
        self.sourceDeckTitle = sourceDeckTitle
        self.sourceStageTitle = sourceStageTitle
    }

    public init(
        sense: SenseDetail,
        masteryLevel: Int = 0,
        isBookmarked: Bool = false,
        needsReview: Bool = false,
        mistakeCount: Int = 0,
        sourceDeckTitle: String? = nil,
        sourceStageTitle: String? = nil
    ) {
        self.id = Int64(bitPattern: UInt64(truncatingIfNeeded: sense.id.rawValue.hashValue))
        self.senseID = sense.id
        self.lemma = sense.headword
        self.phonetic = sense.ipa ?? ""
        self.pos = sense.partOfSpeech.rawValue
        self.cefrLevel = sense.cefrLevel.rawValue
        self.definitionVi = sense.definitionVI
        self.definitionEn = sense.definitionEN
        self.exampleEn = sense.examples.first?.textEN ?? ""
        self.exampleVi = sense.examples.first?.textVI ?? ""
        self.masteryLevel = masteryLevel
        self.isBookmarked = isBookmarked
        self.needsReview = needsReview
        self.mistakeCount = mistakeCount
        self.sourceDeckTitle = sourceDeckTitle
        self.sourceStageTitle = sourceStageTitle
    }
}
