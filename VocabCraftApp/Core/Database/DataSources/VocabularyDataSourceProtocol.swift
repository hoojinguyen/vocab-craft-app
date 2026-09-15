import Foundation

public struct TopicDeckDTO: Identifiable, Sendable, Equatable, Codable {
    public let id: String
    public let title: String
    public let iconName: String
    public let badgeColorHex: String
    public let cefrLevel: String
    public let sortOrder: Int
    public let stages: [SubTopicStageDTO]

    public init(
        id: String,
        title: String,
        iconName: String,
        badgeColorHex: String,
        cefrLevel: String,
        sortOrder: Int,
        stages: [SubTopicStageDTO] = []
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.badgeColorHex = badgeColorHex
        self.cefrLevel = cefrLevel
        self.sortOrder = sortOrder
        self.stages = stages
    }

    enum CodingKeys: String, CodingKey {
        case id, title, iconName, badgeColorHex, cefrLevel, sortOrder, stages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.iconName = try container.decode(String.self, forKey: .iconName)
        self.badgeColorHex = try container.decode(String.self, forKey: .badgeColorHex)
        self.cefrLevel = try container.decode(String.self, forKey: .cefrLevel)
        self.sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        self.stages = try container.decodeIfPresent([SubTopicStageDTO].self, forKey: .stages) ?? []
    }
}

public struct SubTopicStageDTO: Identifiable, Sendable, Equatable, Codable {
    public let id: String
    public let deckId: String
    public let title: String
    public let iconName: String
    public let sortOrder: Int
    public let words: [TopicWordDTO]

    public init(
        id: String,
        deckId: String,
        title: String,
        iconName: String,
        sortOrder: Int,
        words: [TopicWordDTO] = []
    ) {
        self.id = id
        self.deckId = deckId
        self.title = title
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.words = words
    }

    enum CodingKeys: String, CodingKey {
        case id, deckId, title, iconName, sortOrder, words
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.deckId = try container.decode(String.self, forKey: .deckId)
        self.title = try container.decode(String.self, forKey: .title)
        self.iconName = try container.decode(String.self, forKey: .iconName)
        self.sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        self.words = try container.decodeIfPresent([TopicWordDTO].self, forKey: .words) ?? []
    }
}

public struct TopicWordDTO: Identifiable, Sendable, Equatable, Codable {
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

    enum CodingKeys: String, CodingKey {
        case id, stageId, lemma, phonetic, ipaUs, pos, cefrLevel, definitionVi, definitionEn, exampleEn, exampleVi
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.stageId = try container.decodeIfPresent(String.self, forKey: .stageId) ?? ""
        self.lemma = try container.decode(String.self, forKey: .lemma)
        if let phonetic = try container.decodeIfPresent(String.self, forKey: .phonetic) {
            self.phonetic = phonetic
        } else if let ipaUs = try container.decodeIfPresent(String.self, forKey: .ipaUs) {
            self.phonetic = ipaUs
        } else {
            self.phonetic = ""
        }
        self.pos = try container.decode(String.self, forKey: .pos)
        self.cefrLevel = try container.decode(String.self, forKey: .cefrLevel)
        self.definitionVi = try container.decode(String.self, forKey: .definitionVi)
        self.definitionEn = try container.decode(String.self, forKey: .definitionEn)
        self.exampleEn = try container.decode(String.self, forKey: .exampleEn)
        self.exampleVi = try container.decode(String.self, forKey: .exampleVi)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(stageId, forKey: .stageId)
        try container.encode(lemma, forKey: .lemma)
        try container.encode(phonetic, forKey: .phonetic)
        try container.encode(pos, forKey: .pos)
        try container.encode(cefrLevel, forKey: .cefrLevel)
        try container.encode(definitionVi, forKey: .definitionVi)
        try container.encode(definitionEn, forKey: .definitionEn)
        try container.encode(exampleEn, forKey: .exampleEn)
        try container.encode(exampleVi, forKey: .exampleVi)
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
