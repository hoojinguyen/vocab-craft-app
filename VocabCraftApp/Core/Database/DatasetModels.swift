import Foundation

public struct WordRecord: Identifiable, Sendable {
    public let id: Int64
    public let lemma: String
    public let pos: String?
    public let ipaUs: String?
    public let cefrLevel: String?
    public let definitionEn: String?
    public let definitionVi: String?
    public let example: String?

    public init(
        id: Int64,
        lemma: String,
        pos: String? = nil,
        ipaUs: String? = nil,
        cefrLevel: String? = nil,
        definitionEn: String? = nil,
        definitionVi: String? = nil,
        example: String? = nil
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.ipaUs = ipaUs
        self.cefrLevel = cefrLevel
        self.definitionEn = definitionEn
        self.definitionVi = definitionVi
        self.example = example
    }
}

public struct ReflexDrillRecord: Identifiable, Sendable {
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
