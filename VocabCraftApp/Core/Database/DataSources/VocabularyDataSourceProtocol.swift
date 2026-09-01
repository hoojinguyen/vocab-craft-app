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
    func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO]
    func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO]
}

public extension VocabularyDataSourceProtocol {
    func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO] {
        try await withThrowingTaskGroup(of: TopicWordDTO?.self) { group in
            for id in ids {
                group.addTask {
                    try await self.fetchWordById(id: id)
                }
            }
            var results: [TopicWordDTO] = []
            results.reserveCapacity(ids.count)
            for try await word in group {
                if let word {
                    results.append(word)
                }
            }
            return results
        }
    }

    func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO] {
        let decks = try await fetchTopicDecks()
        return try await withThrowingTaskGroup(of: [TopicWordDTO].self) { stageGroup in
            for deck in decks {
                let stages = try await self.fetchSubTopicStages(deckId: deck.id)
                for stage in stages {
                    stageGroup.addTask {
                        try await self.fetchWordsForStage(stageId: stage.id)
                    }
                }
            }
            var map: [Int64: TopicWordDTO] = [:]
            for try await words in stageGroup {
                for word in words {
                    map[word.id] = word
                }
            }
            return map
        }
    }
}
