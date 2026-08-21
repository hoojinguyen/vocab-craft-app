import Foundation

public struct WordChallengeQuestion: Identifiable, Sendable, Equatable {
    public let id: String
    public let wordId: Int64
    public let prompt: String
    public let hintPhonetic: String
    public let correctAnswer: String
    public let options: [String]
    public let exampleSentence: String

    public init(id: String = UUID().uuidString, wordId: Int64, prompt: String, hintPhonetic: String, correctAnswer: String, options: [String], exampleSentence: String) {
        self.id = id
        self.wordId = wordId
        self.prompt = prompt
        self.hintPhonetic = hintPhonetic
        self.correctAnswer = correctAnswer
        self.options = options
        self.exampleSentence = exampleSentence
    }
}

public struct WordChallengeResult: Sendable, Equatable {
    public let wordId: Int64
    public let isCorrect: Bool
    public let timeTakenMs: Int

    public init(wordId: Int64, isCorrect: Bool, timeTakenMs: Int) {
        self.wordId = wordId
        self.isCorrect = isCorrect
        self.timeTakenMs = timeTakenMs
    }
}

public struct StageCompletionSummary: Sendable, Equatable {
    public let stageId: String
    public let totalQuestions: Int
    public let correctCount: Int
    public let xpEarned: Int
    public let weakWordIds: [Int64]

    public init(stageId: String, totalQuestions: Int, correctCount: Int, xpEarned: Int, weakWordIds: [Int64]) {
        self.stageId = stageId
        self.totalQuestions = totalQuestions
        self.correctCount = correctCount
        self.xpEarned = xpEarned
        self.weakWordIds = weakWordIds
    }
}
