import Foundation

public struct ReflexDrillItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let lemma: String
    public let ipa: String
    public let definitionVi: String
    public let clozeSentenceEn: String
    public let clozeSentenceVi: String
    public let mistakeCount: Int
    public let needsReview: Bool
    public let isMastered: Bool
    public let consecutiveCorrectStreak: Int
    public let lastReviewDate: Date?
    public let nextReviewDate: Date?

    // Legacy fields for backward compatibility
    public let drillType: String
    public let promptText: String
    public let correctAnswer: String
    public let distractors: [String]
    public let targetTimeMs: Int
    public let sentenceTextEn: String?

    public init(
        id: String,
        lemma: String = "",
        ipa: String = "",
        definitionVi: String = "",
        clozeSentenceEn: String = "",
        clozeSentenceVi: String = "",
        mistakeCount: Int = 0,
        needsReview: Bool = false,
        isMastered: Bool = false,
        consecutiveCorrectStreak: Int = 0,
        lastReviewDate: Date? = nil,
        nextReviewDate: Date? = nil,
        drillType: String = "speed",
        promptText: String = "",
        correctAnswer: String = "",
        distractors: [String] = [],
        targetTimeMs: Int = 2500,
        sentenceTextEn: String? = nil
    ) {
        self.id = id
        self.lemma = lemma.isEmpty ? correctAnswer : lemma
        self.ipa = ipa
        self.definitionVi = definitionVi.isEmpty ? promptText : definitionVi
        self.clozeSentenceEn = clozeSentenceEn.isEmpty ? (sentenceTextEn ?? "") : clozeSentenceEn
        self.clozeSentenceVi = clozeSentenceVi
        self.mistakeCount = mistakeCount
        self.needsReview = needsReview
        self.isMastered = isMastered
        self.consecutiveCorrectStreak = consecutiveCorrectStreak
        self.lastReviewDate = lastReviewDate
        self.nextReviewDate = nextReviewDate
        self.drillType = drillType
        self.promptText = promptText.isEmpty ? definitionVi : promptText
        self.correctAnswer = correctAnswer.isEmpty ? (lemma.isEmpty ? promptText : lemma) : correctAnswer
        self.distractors = distractors
        self.targetTimeMs = targetTimeMs
        self.sentenceTextEn = sentenceTextEn ?? (clozeSentenceEn.isEmpty ? nil : clozeSentenceEn)
    }

    public init(
        id: Int64,
        drillType: String,
        promptText: String,
        correctAnswer: String,
        distractors: [String],
        targetTimeMs: Int,
        sentenceTextEn: String? = nil
    ) {
        self.init(
            id: String(id),
            lemma: correctAnswer,
            ipa: "",
            definitionVi: promptText,
            clozeSentenceEn: sentenceTextEn ?? "",
            clozeSentenceVi: "",
            mistakeCount: 0,
            needsReview: false,
            isMastered: false,
            consecutiveCorrectStreak: 0,
            lastReviewDate: nil,
            nextReviewDate: nil,
            drillType: drillType,
            promptText: promptText,
            correctAnswer: correctAnswer,
            distractors: distractors,
            targetTimeMs: targetTimeMs,
            sentenceTextEn: sentenceTextEn
        )
    }
}

extension ReflexDrillItem: ReflexDrillable {
    public var pos: String { "word" }
    public var exampleSentenceEn: String { clozeSentenceEn }
    public var exampleSentenceVi: String { clozeSentenceVi }
    public var cefrLevel: String { "B2" }
    public var audioResourceUrl: String? { nil }
}
