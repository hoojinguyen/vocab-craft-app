import Foundation

/// Central data provider providing structured mock data for development and testing.
public struct MockVocabularyDataSource: Sendable {
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

    public let mockReflexDrills: [ReflexDrillItem] = [
        ReflexDrillItem(
            id: 101,
            drillType: "multiple_choice",
            promptText: "Chọn nghĩa chính xác của 'Ephemeral':",
            correctAnswer: "Phù du, ngắn ngủi",
            distractors: ["Lâu dài", "Vĩnh cửu", "Kiên cường"],
            targetTimeMs: 3000
        ),
        ReflexDrillItem(
            id: 102,
            drillType: "multiple_choice",
            promptText: "Chọn nghĩa chính xác của 'Resilience':",
            correctAnswer: "Sự phục hồi, kiên cường",
            distractors: ["Ngắn ngủi", "Nhân tạo", "Trí tuệ"],
            targetTimeMs: 3000
        )
    ]

    public let mockTopicDecks: [TopicDeck] = [
        TopicDeck(
            id: "tech",
            title: "Công nghệ & Đổi mới",
            wordCount: 30,
            completionPercentage: 0.35,
            badgeColorHex: "#3B82F6",
            iconName: "cpu"
        ),
        TopicDeck(
            id: "business",
            title: "Kinh doanh & Tài chính",
            wordCount: 45,
            completionPercentage: 0.60,
            badgeColorHex: "#10B981",
            iconName: "chart.bar.fill"
        )
    ]

    public func fetchTopicDecksSummary() -> [TopicDeckSummaryRecord] {
        return mockTopicDecks.map { deck in
            TopicDeckSummaryRecord(
                id: deck.id,
                title: deck.title,
                iconName: deck.iconName,
                badgeColorHex: deck.badgeColorHex,
                sortOrder: 1,
                totalWords: deck.wordCount
            )
        }
    }

    public func fetchDeckWordIdsMap() -> [String: [Int64]] {
        return [
            "ielts_academic": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "business_tech": [11, 12, 13, 14, 15]
        ]
    }

    public init() {}
}

