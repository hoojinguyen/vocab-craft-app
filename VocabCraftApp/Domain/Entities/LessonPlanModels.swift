import Foundation

/// Represents a single interactive exercise within a lesson session.
public struct LessonExerciseItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let word: TopicWordDTO
    public let assignedMode: ReflexBlitzMode
    public let options: [ReflexBlitzOption]
    public let clozeStages: ReflexClozeStageSet
    public let attemptCount: Int
    public let isRequeued: Bool

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
    case exercise(item: LessonExerciseItem)
    case summary(summary: LessonSummaryModel)

    public var id: String {
        switch self {
        case .discovery(let word, let index, _):
            return "discovery-\(word.id)-\(index)"
        case .exercise(let item):
            return "exercise-\(item.id)"
        case .summary(let summary):
            return "summary-\(summary.stageId)"
        }
    }
}
