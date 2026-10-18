import Foundation

public struct TopicDeckDTO: Identifiable, Sendable, Equatable, Codable {
    public let id: String
    public let titleEn: String
    public let titleVi: String
    public let descriptionEn: String?
    public let descriptionVi: String?
    public let iconName: String
    public let themeKey: String
    public let cefrLevel: String
    public let sortOrder: Int
    public let stages: [SubTopicStageDTO]

    public var badgeColorHex: String { themeKey }

    public var title: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? Locale.current.identifier
        if languageCode.hasPrefix("vi") {
            return titleVi.isEmpty ? titleEn : titleVi
        }
        return titleEn.isEmpty ? titleVi : titleEn
    }

    public var descriptionText: String? {
        let languageCode = Locale.current.language.languageCode?.identifier ?? Locale.current.identifier
        if languageCode.hasPrefix("vi") {
            return descriptionVi ?? descriptionEn
        }
        return descriptionEn ?? descriptionVi
    }

    public init(
        id: String,
        titleEn: String,
        titleVi: String = "",
        descriptionEn: String? = nil,
        descriptionVi: String? = nil,
        iconName: String,
        themeKey: String = "",
        badgeColorHex: String? = nil,
        cefrLevel: String,
        sortOrder: Int,
        stages: [SubTopicStageDTO] = []
    ) {
        self.id = id
        self.titleEn = titleEn
        self.titleVi = titleVi
        self.descriptionEn = descriptionEn
        self.descriptionVi = descriptionVi
        self.iconName = iconName
        self.themeKey = badgeColorHex ?? themeKey
        self.cefrLevel = cefrLevel
        self.sortOrder = sortOrder
        self.stages = stages
    }

    public init(
        id: String,
        title: String,
        iconName: String,
        themeKey: String = "",
        badgeColorHex: String? = nil,
        cefrLevel: String,
        sortOrder: Int,
        stages: [SubTopicStageDTO] = []
    ) {
        self.init(
            id: id,
            titleEn: title,
            titleVi: title,
            descriptionEn: nil,
            descriptionVi: nil,
            iconName: iconName,
            themeKey: themeKey,
            badgeColorHex: badgeColorHex,
            cefrLevel: cefrLevel,
            sortOrder: sortOrder,
            stages: stages
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, title, titleEn, titleVi, descriptionEn, descriptionVi, iconName, themeKey, badgeColorHex, cefrLevel, sortOrder, stages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        if let titleEnDecoded = try container.decodeIfPresent(String.self, forKey: .titleEn) {
            self.titleEn = titleEnDecoded
        } else if let legacyTitle = try container.decodeIfPresent(String.self, forKey: .title) {
            self.titleEn = legacyTitle
        } else {
            self.titleEn = ""
        }
        self.titleVi = try container.decodeIfPresent(String.self, forKey: .titleVi)
            ?? (try container.decodeIfPresent(String.self, forKey: .title) ?? "")
        self.descriptionEn = try container.decodeIfPresent(String.self, forKey: .descriptionEn)
        self.descriptionVi = try container.decodeIfPresent(String.self, forKey: .descriptionVi)
        self.iconName = try container.decode(String.self, forKey: .iconName)

        if let theme = try container.decodeIfPresent(String.self, forKey: .themeKey) {
            self.themeKey = theme
        } else if let legacyColor = try container.decodeIfPresent(String.self, forKey: .badgeColorHex) {
            self.themeKey = legacyColor
        } else {
            self.themeKey = ""
        }

        self.cefrLevel = try container.decode(String.self, forKey: .cefrLevel)
        self.sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        self.stages = try container.decodeIfPresent([SubTopicStageDTO].self, forKey: .stages) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(titleEn, forKey: .titleEn)
        try container.encode(titleVi, forKey: .titleVi)
        try container.encodeIfPresent(descriptionEn, forKey: .descriptionEn)
        try container.encodeIfPresent(descriptionVi, forKey: .descriptionVi)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(themeKey, forKey: .themeKey)
        try container.encode(cefrLevel, forKey: .cefrLevel)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(stages, forKey: .stages)
    }
}

public struct SubTopicStageDTO: Identifiable, Sendable, Equatable, Codable {
    public let id: String
    public let deckId: String
    public let titleEn: String
    public let titleVi: String
    public let iconName: String
    public let sortOrder: Int
    public let words: [TopicWordDTO]

    public var title: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? Locale.current.identifier
        if languageCode.hasPrefix("vi") {
            return titleVi.isEmpty ? titleEn : titleVi
        }
        return titleEn.isEmpty ? titleVi : titleEn
    }

    public init(
        id: String,
        deckId: String,
        titleEn: String,
        titleVi: String = "",
        iconName: String,
        sortOrder: Int,
        words: [TopicWordDTO] = []
    ) {
        self.id = id
        self.deckId = deckId
        self.titleEn = titleEn
        self.titleVi = titleVi
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.words = words
    }

    public init(
        id: String,
        deckId: String,
        title: String,
        iconName: String,
        sortOrder: Int,
        words: [TopicWordDTO] = []
    ) {
        self.init(
            id: id,
            deckId: deckId,
            titleEn: title,
            titleVi: title,
            iconName: iconName,
            sortOrder: sortOrder,
            words: words
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, deckId, title, titleEn, titleVi, iconName, sortOrder, words
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.deckId = try container.decode(String.self, forKey: .deckId)
        if let titleEnDecoded = try container.decodeIfPresent(String.self, forKey: .titleEn) {
            self.titleEn = titleEnDecoded
        } else if let legacyTitle = try container.decodeIfPresent(String.self, forKey: .title) {
            self.titleEn = legacyTitle
        } else {
            self.titleEn = ""
        }
        self.titleVi = try container.decodeIfPresent(String.self, forKey: .titleVi)
            ?? (try container.decodeIfPresent(String.self, forKey: .title) ?? "")
        self.iconName = try container.decode(String.self, forKey: .iconName)
        self.sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        self.words = try container.decodeIfPresent([TopicWordDTO].self, forKey: .words) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(deckId, forKey: .deckId)
        try container.encode(title, forKey: .title)
        try container.encode(titleEn, forKey: .titleEn)
        try container.encode(titleVi, forKey: .titleVi)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(words, forKey: .words)
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

public struct LearningPathDTO: Identifiable, Sendable, Equatable, Codable {
    public let id: String
    public let code: String
    public let titleEn: String
    public let titleVi: String
    public let descriptionEn: String?
    public let descriptionVi: String?
    public let goalCategory: String
    public let targetLevelMin: String
    public let targetLevelMax: String
    public let iconKey: String
    public let themeKey: String
    public let sortOrder: Int

    public init(
        id: String,
        code: String,
        titleEn: String,
        titleVi: String,
        descriptionEn: String? = nil,
        descriptionVi: String? = nil,
        goalCategory: String,
        targetLevelMin: String,
        targetLevelMax: String,
        iconKey: String,
        themeKey: String,
        sortOrder: Int
    ) {
        self.id = id
        self.code = code
        self.titleEn = titleEn
        self.titleVi = titleVi
        self.descriptionEn = descriptionEn
        self.descriptionVi = descriptionVi
        self.goalCategory = goalCategory
        self.targetLevelMin = targetLevelMin
        self.targetLevelMax = targetLevelMax
        self.iconKey = iconKey
        self.themeKey = themeKey
        self.sortOrder = sortOrder
    }

    public static let defaultCuratedPaths: [LearningPathDTO] = [
        LearningPathDTO(
            id: "7147ba7e-0728-471d-97af-f3e2262a6d23",
            code: "essential-english-mastery",
            titleEn: "Core Curriculum: Comprehensive English for Communication & Academics",
            titleVi: "Lộ Trình Cốt Lõi: Tiếng Anh Giao Tiếp & Học Thuật Toàn Diện",
            descriptionEn: "Complete mastery across all essential grammar and vocabulary from A1 to C2.",
            descriptionVi: "Toàn diện ngữ pháp và từ vựng cốt lõi từ căn bản đến nâng cao A1 đến C2.",
            goalCategory: "general",
            targetLevelMin: "A1",
            targetLevelMax: "C2",
            iconKey: "compass",
            themeKey: "ocean_blue",
            sortOrder: 0
        ),
        LearningPathDTO(
            id: "c11e8a24-9b2f-4e67-881a-637dc44d3201",
            code: "daily-life-travel",
            titleEn: "Everyday Life & Travel Fluency",
            titleVi: "Giao Tiếp Đời Sống & Du Lịch Thực Tế",
            descriptionEn: "Essential conversational fluency for travel, dining, shopping, and everyday situations.",
            descriptionVi: "Giao tiếp trôi chảy tự tin khi đi du lịch, ăn uống, mua sắm và đời sống thường ngày.",
            goalCategory: "travel",
            targetLevelMin: "A1",
            targetLevelMax: "B1",
            iconKey: "airplane.departure",
            themeKey: "forest_green",
            sortOrder: 1
        ),
        LearningPathDTO(
            id: "d22f9b35-0c30-4f78-992b-748ed55e4312",
            code: "business-career",
            titleEn: "Business & Workplace Excellence",
            titleVi: "Tiếng Anh Công Sở & Phát Triển Sự Nghiệp",
            descriptionEn: "Professional vocabulary for meetings, negotiations, presentations, and leadership.",
            descriptionVi: "Từ vựng chuyên nghiệp phục vụ hội họp, đàm phán, thuyết trình và phát triển sự nghiệp.",
            goalCategory: "business",
            targetLevelMin: "B1",
            targetLevelMax: "B2",
            iconKey: "briefcase.fill",
            themeKey: "ocean_blue",
            sortOrder: 2
        ),
        LearningPathDTO(
            id: "e33a0c46-1d41-4089-aa3c-859fe66f5423",
            code: "academic-research",
            titleEn: "Academic Mastery & Critical Inquiries",
            titleVi: "Tiếng Anh Học Thuật & Nghiên Cứu Chuyên Sâu",
            descriptionEn: "Advanced lexicon and rhetoric for university research, thesis writing, and debates.",
            descriptionVi: "Vốn từ học thuật chuyên sâu phục vụ nghiên cứu, viết luận và tư duy phản biện.",
            goalCategory: "academic",
            targetLevelMin: "B2",
            targetLevelMax: "C2",
            iconKey: "graduationcap.fill",
            themeKey: "royal_purple",
            sortOrder: 3
        )
    ]
}

public protocol VocabularyDataSourceProtocol: Sendable {
    func fetchTopicDecks() async throws -> [TopicDeckDTO]
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO]
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO]
    func searchWords(query: String) async throws -> [TopicWordDTO]
    func fetchWordById(id: Int64) async throws -> TopicWordDTO?
    func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO]
    func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO]
    func fetchLearningPaths() async throws -> [LearningPathDTO]
    func fetchTopicDecks(for pathId: String) async throws -> [TopicDeckDTO]
}

public extension VocabularyDataSourceProtocol {
    func fetchLearningPaths() async throws -> [LearningPathDTO] {
        LearningPathDTO.defaultCuratedPaths
    }

    func fetchTopicDecks(for pathId: String) async throws -> [TopicDeckDTO] {
        try await fetchTopicDecks()
    }

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
