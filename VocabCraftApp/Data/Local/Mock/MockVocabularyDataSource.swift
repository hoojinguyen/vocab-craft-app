import Foundation

/// Central data provider providing structured mock data for development and testing.
public struct MockVocabularyDataSource: VocabularyDataSourceProtocol, Sendable {
    public static let shared = MockVocabularyDataSource()

    public let mockWords: [Word] = [
        Word(
            id: 1,
            lemma: "Habit",
            pos: "noun",
            ipaUs: "/ˈhæb.ɪt/",
            cefrLevel: "A2",
            definitionEn: "something that you do regularly or often",
            definitionVi: "Thói quen hàng ngày",
            example: "Reading books before bed is a great habit."
        ),
        Word(
            id: 2,
            lemma: "Improve",
            pos: "verb",
            ipaUs: "/ɪmˈpruːv/",
            cefrLevel: "B1",
            definitionEn: "to make something better or become better",
            definitionVi: "Cải thiện, nâng cao kỹ năng",
            example: "Daily practice will help you improve your speaking skills."
        ),
        Word(
            id: 3,
            lemma: "Confident",
            pos: "adjective",
            ipaUs: "/ˈkɑːn.fə.dənt/",
            cefrLevel: "B1",
            definitionEn: "having a feeling of trust and certainty",
            definitionVi: "Tự tin trong giao tiếp",
            example: "She feels very confident when speaking in public."
        )
    ]

    public let mockSuggestedWords: [SuggestedWord] = [
        SuggestedWord(
            id: "s1",
            lemma: "Improve",
            pos: "verb",
            ipaUs: "/ɪmˈpruːv/",
            cefrLevel: "B1",
            definitionVi: "Cải thiện, nâng cao chất lượng hoặc kỹ năng.",
            definitionEn: "To make or become better.",
            example: "Daily practice will help you improve your speaking skills.",
            isBookmarked: false,
            topicTag: "Kỹ năng hàng ngày"
        ),
        SuggestedWord(
            id: "s2",
            lemma: "Focus",
            pos: "verb",
            ipaUs: "/ˈfoʊ.kəs/",
            cefrLevel: "B1",
            definitionVi: "Tập trung sự chú ý vào một việc cụ thể.",
            definitionEn: "To give your full attention to what you are doing.",
            example: "Please turn off the music so I can focus on studying.",
            isBookmarked: true,
            topicTag: "Học tập & Làm việc"
        )
    ]

    public static let mockDecks: [TopicDeckDTO] = [
        TopicDeckDTO(
            id: "deck_daily",
            title: "Giao Tiếp Hằng Ngày",
            iconName: "bubble.left.and.bubble.right.fill",
            badgeColorHex: "#38B2AC",
            cefrLevel: "A2 - B1",
            sortOrder: 1
        ),
        TopicDeckDTO(
            id: "deck_business",
            title: "Công Sở & Kinh Doanh",
            iconName: "briefcase.fill",
            badgeColorHex: "#ED8936",
            cefrLevel: "B1 - B2",
            sortOrder: 2
        )
    ]

    public static let mockStages: [SubTopicStageDTO] = [
        SubTopicStageDTO(
            id: "stage_daily_1",
            deckId: "deck_daily",
            title: "Thói quen & Cảm xúc",
            iconName: "heart.fill",
            sortOrder: 1
        ),
        SubTopicStageDTO(
            id: "stage_daily_2",
            deckId: "deck_daily",
            title: "Giao tiếp & Ứng xử",
            iconName: "person.2.fill",
            sortOrder: 2
        )
    ]

    public static let mockTopicWords: [TopicWordDTO] = [
        TopicWordDTO(
            id: 1,
            stageId: "stage_daily_1",
            lemma: "Resilience",
            phonetic: "/rɪˈzɪl.jəns/",
            pos: "noun",
            cefrLevel: "B2",
            definitionVi: "Khả năng phục hồi, kiên cường",
            definitionEn: "The capacity to recover quickly from difficulties",
            exampleEn: "Her resilience helped her overcome difficulties.",
            exampleVi: "Sự kiên cường giúp cô ấy vượt qua khó khăn."
        ),
        TopicWordDTO(
            id: 2,
            stageId: "stage_daily_1",
            lemma: "Overwhelmed",
            phonetic: "/ˌoʊ.vɚˈwelmd/",
            pos: "adjective",
            cefrLevel: "B1",
            definitionVi: "Bị ngợp, quá tải",
            definitionEn: "Completely overcome by emotions or tasks",
            exampleEn: "He felt overwhelmed by the workload.",
            exampleVi: "Anh ấy cảm thấy quá tải vì khối lượng công việc."
        ),
        TopicWordDTO(
            id: 3,
            stageId: "stage_daily_1",
            lemma: "Spontaneous",
            phonetic: "/spɑːnˈteɪ.ni.əs/",
            pos: "adjective",
            cefrLevel: "B2",
            definitionVi: "Tự phát, ngẫu hứng",
            definitionEn: "Performed or occurring as a result of a sudden impulse",
            exampleEn: "We took a spontaneous road trip.",
            exampleVi: "Chúng tôi đã có một chuyến đi phượt ngẫu hứng."
        )
    ]

    public static func starterWords(forStageId stageId: String? = nil) -> [TopicWordDTO] {
        if let stageId {
            let matching = mockTopicWords.filter { $0.stageId == stageId }
            if !matching.isEmpty { return matching }
        }
        return mockTopicWords
    }

    public init() {}

    // MARK: - VocabularyDataSourceProtocol

    public func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        Self.mockDecks
    }

    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        Self.mockStages.filter { $0.deckId == deckId }
    }

    public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        Self.mockTopicWords.filter { $0.stageId == stageId }
    }

    public func searchWords(query: String) async throws -> [TopicWordDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Self.mockTopicWords }
        return Self.mockTopicWords.filter {
            $0.lemma.localizedCaseInsensitiveContains(trimmed) ||
            $0.definitionVi.localizedCaseInsensitiveContains(trimmed) ||
            $0.definitionEn.localizedCaseInsensitiveContains(trimmed)
        }
    }

    public func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
        Self.mockTopicWords.first { $0.id == id }
    }

    public func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO] {
        guard !ids.isEmpty else { return [] }
        return Self.mockTopicWords.filter { ids.contains($0.id) }
    }

    public func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO] {
        Dictionary(Self.mockTopicWords.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
