import Foundation

/// Represents a single interactive exercise within a lesson session.
public struct LessonExerciseItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let word: TopicWordDTO
    public let senseDetail: SenseDetail?
    public let senseID: SenseID?
    public let assignedMode: ReflexBlitzMode
    public let options: [ReflexBlitzOption]
    public let clozeStages: ReflexClozeStageSet
    public let attemptCount: Int
    public let isRequeued: Bool

    public var lemma: String {
        senseDetail?.headword ?? word.lemma
    }

    public var exampleEn: String {
        senseDetail?.examples.first?.textEN ?? word.exampleEn
    }

    public var exampleVi: String {
        senseDetail?.examples.first?.textVI ?? word.exampleVi
    }

    public var pos: String {
        senseDetail?.partOfSpeech.rawValue ?? word.pos
    }

    public init(
        id: String,
        word: TopicWordDTO,
        assignedMode: ReflexBlitzMode,
        options: [ReflexBlitzOption] = [],
        clozeStages: ReflexClozeStageSet? = nil,
        attemptCount: Int = 1,
        isRequeued: Bool = false
    ) {
        self.id = id
        self.word = word
        self.senseDetail = nil
        self.senseID = nil
        self.assignedMode = assignedMode
        self.options = options
        self.clozeStages = clozeStages ?? ReflexHintMaskGenerator.generateStages(
            lemma: word.lemma,
            sentenceEn: word.exampleEn,
            pos: word.pos
        )
        self.attemptCount = attemptCount
        self.isRequeued = isRequeued
    }

    public init(
        id: String,
        word: TopicWordDTO,
        senseDetail: SenseDetail?,
        assignedMode: ReflexBlitzMode,
        options: [ReflexBlitzOption] = [],
        clozeStages: ReflexClozeStageSet? = nil,
        attemptCount: Int = 1,
        isRequeued: Bool = false
    ) {
        self.id = id
        self.word = word
        self.senseDetail = senseDetail
        self.senseID = senseDetail?.id
        self.assignedMode = assignedMode
        self.options = options
        let targetLemma = senseDetail?.headword ?? word.lemma
        let targetSentence = senseDetail?.examples.first?.textEN ?? word.exampleEn
        let targetPos = senseDetail?.partOfSpeech.rawValue ?? word.pos
        self.clozeStages = clozeStages ?? ReflexHintMaskGenerator.generateStages(
            lemma: targetLemma,
            sentenceEn: targetSentence,
            pos: targetPos
        )
        self.attemptCount = attemptCount
        self.isRequeued = isRequeued
    }

    public init(
        id: String,
        sense: SenseDetail,
        assignedMode: ReflexBlitzMode,
        options: [ReflexBlitzOption] = [],
        clozeStages: ReflexClozeStageSet? = nil,
        attemptCount: Int = 1,
        isRequeued: Bool = false
    ) {
        self.id = id
        let hashId = Int64(bitPattern: UInt64(truncatingIfNeeded: sense.id.rawValue.hashValue))
        self.word = TopicWordDTO(
            id: hashId,
            stageId: "",
            lemma: sense.headword,
            phonetic: sense.ipa ?? sense.pronunciations.first?.ipa ?? "",
            pos: sense.partOfSpeech.rawValue,
            cefrLevel: sense.cefrLevel.rawValue,
            definitionVi: sense.definitionVI,
            definitionEn: sense.definitionEN,
            exampleEn: sense.examples.first?.textEN ?? "",
            exampleVi: sense.examples.first?.textVI ?? ""
        )
        self.senseDetail = sense
        self.senseID = sense.id
        self.assignedMode = assignedMode
        self.options = options
        let sentenceEn = sense.examples.first?.textEN ?? ""
        self.clozeStages = clozeStages ?? ReflexHintMaskGenerator.generateStages(
            lemma: sense.headword,
            sentenceEn: sentenceEn,
            pos: sense.partOfSpeech.rawValue
        )
        self.attemptCount = attemptCount
        self.isRequeued = isRequeued
    }
}

/// Completion summary and metrics for a completed lesson session.
public struct LessonSummaryModel: Sendable, Equatable {
    public let stageId: String
    public let deckId: String
    public let stars: Int
    public let xpEarned: Int
    public let accuracyFraction: Double
    public let learnedWords: [TopicWordDTO]
    public let weakWordIds: [Int64]

    public init(
        stageId: String,
        deckId: String,
        stars: Int,
        xpEarned: Int,
        accuracyFraction: Double,
        learnedWords: [TopicWordDTO],
        weakWordIds: [Int64]
    ) {
        self.stageId = stageId
        self.deckId = deckId
        self.stars = stars
        self.xpEarned = xpEarned
        self.accuracyFraction = accuracyFraction
        self.learnedWords = learnedWords
        self.weakWordIds = weakWordIds
    }
}

/// A sequential step in the lesson flow.
public enum LessonStep: Identifiable, Sendable, Equatable {
    case discovery(word: TopicWordDTO, index: Int, totalInCycle: Int)
    case senseDiscovery(sense: SenseDetail, index: Int, totalInCycle: Int)
    case exercise(item: LessonExerciseItem)
    case summary(summary: LessonSummaryModel)

    public var id: String {
        switch self {
        case .discovery(let word, let index, _):
            return "discovery-\(word.id)-\(index)"
        case .senseDiscovery(let sense, let index, _):
            return "sense-discovery-\(sense.id.rawValue.uuidString.lowercased())-\(index)"
        case .exercise(let item):
            return "exercise-\(item.id)"
        case .summary(let summary):
            return "summary-\(summary.stageId)"
        }
    }
}
