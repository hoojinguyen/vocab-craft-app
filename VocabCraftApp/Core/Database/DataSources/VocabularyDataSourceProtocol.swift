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

    public static func fallbackStarterWords(stageId: String = "starter") -> [TopicWordDTO] {
        Array(VocabularySampleDataset.words.prefix(3)).map { word in
            TopicWordDTO(
                id: word.id,
                stageId: stageId,
                lemma: word.lemma,
                phonetic: word.phonetic,
                pos: word.pos,
                cefrLevel: word.cefrLevel,
                definitionVi: word.definitionVi,
                definitionEn: word.definitionEn,
                exampleEn: word.exampleEn,
                exampleVi: word.exampleVi
            )
        }
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
        guard !ids.isEmpty else { return [] }
        let idArray = Array(ids)
        let chunkSize = 20
        let chunks = stride(from: 0, to: idArray.count, by: chunkSize).map {
            Array(idArray[$0..<min($0 + chunkSize, idArray.count)])
        }

        return try await withThrowingTaskGroup(of: [TopicWordDTO].self) { group in
            for chunk in chunks {
                group.addTask {
                    var batchResults: [TopicWordDTO] = []
                    batchResults.reserveCapacity(chunk.count)
                    for id in chunk {
                        if let word = try await self.fetchWordById(id: id) {
                            batchResults.append(word)
                        }
                    }
                    return batchResults
                }
            }
            var allResults: [TopicWordDTO] = []
            allResults.reserveCapacity(ids.count)
            for try await batch in group {
                allResults.append(contentsOf: batch)
            }
            return allResults
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
