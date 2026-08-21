import Foundation

public struct ReflexDrillItem: Identifiable, Equatable, Sendable {
    public let id: Int64
    public let drillType: String
    public let promptText: String
    public let correctAnswer: String
    public let distractors: [String]
    public let targetTimeMs: Int
    public let sentenceTextEn: String?

    public init(
        id: Int64,
        drillType: String,
        promptText: String,
        correctAnswer: String,
        distractors: [String],
        targetTimeMs: Int,
        sentenceTextEn: String? = nil
    ) {
        self.id = id
        self.drillType = drillType
        self.promptText = promptText
        self.correctAnswer = correctAnswer
        self.distractors = distractors
        self.targetTimeMs = targetTimeMs
        self.sentenceTextEn = sentenceTextEn
    }
}
