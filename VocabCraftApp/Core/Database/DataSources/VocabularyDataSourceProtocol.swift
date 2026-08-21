import Foundation

public struct TopicDeckDTO: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let iconName: String
    public let badgeColorHex: String
    public let cefrLevel: String
    public let sortOrder: Int

    public init(id: String, title: String, iconName: String, badgeColorHex: String, cefrLevel: String, sortOrder: Int) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.badgeColorHex = badgeColorHex
        self.cefrLevel = cefrLevel
        self.sortOrder = sortOrder
    }
}

public struct SubTopicStageDTO: Identifiable, Sendable, Equatable {
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

public struct TopicWordDTO: Identifiable, Sendable, Equatable {
    public let id: Int64
    public let stageId: String
    public let lemma: String
    public let phonetic: String
    public let pos: String
    public let cefrLevel: String
    public let definitionVi: String
    public let definitionEn: String
    public let exampleEn: String
    public let exampleVi: String

    public init(
        id: Int64,
        stageId: String,
        lemma: String,
        phonetic: String,
        pos: String,
        cefrLevel: String,
        definitionVi: String,
        definitionEn: String,
        exampleEn: String,
        exampleVi: String
    ) {
        self.id = id
        self.stageId = stageId
        self.lemma = lemma
        self.phonetic = phonetic
        self.pos = pos
        self.cefrLevel = cefrLevel
        self.definitionVi = definitionVi
        self.definitionEn = definitionEn
        self.exampleEn = exampleEn
        self.exampleVi = exampleVi
    }
}

public protocol VocabularyDataSourceProtocol: Sendable {
    func fetchTopicDecks() async throws -> [TopicDeckDTO]
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO]
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO]
    func searchWords(query: String) async throws -> [TopicWordDTO]
    func fetchWordById(id: Int64) async throws -> TopicWordDTO?
}
