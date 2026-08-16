import Foundation

public struct WordRecord: Identifiable, Equatable, Sendable {
    public let id: Int64
    public let lemma: String
    public let pos: String?
    public let ipaUs: String?
    public let cefrLevel: String?
    public let definitionEn: String?
    public let definitionVi: String?
    public let example: String?
    public let collocationEn: String?
    public let collocationVi: String?

    public init(
        id: Int64,
        lemma: String,
        pos: String? = nil,
        ipaUs: String? = nil,
        cefrLevel: String? = nil,
        definitionEn: String? = nil,
        definitionVi: String? = nil,
        example: String? = nil,
        collocationEn: String? = nil,
        collocationVi: String? = nil
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.ipaUs = ipaUs
        self.cefrLevel = cefrLevel
        self.definitionEn = definitionEn
        self.definitionVi = definitionVi
        self.example = example
        self.collocationEn = collocationEn
        self.collocationVi = collocationVi
    }
}

public struct ReflexDrillRecord: Identifiable, Equatable, Sendable {
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

public struct TopicDeckRecord: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let iconName: String
    public let badgeColorHex: String
    public let sortOrder: Int

    public init(id: String, title: String, iconName: String, badgeColorHex: String, sortOrder: Int) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.badgeColorHex = badgeColorHex
        self.sortOrder = sortOrder
    }
}

public struct SubTopicNodeRecord: Identifiable, Equatable, Sendable {
    public let id: String
    public let deckId: String
    public let title: String
    public let iconName: String
    public let sortOrder: Int

    public init(id: String, deckId: String, title: String, iconName: String, sortOrder: Int) {
        self.id = id
        self.deckId = deckId
        self.title = title
        self.iconName = iconName
        self.sortOrder = sortOrder
    }
}
