import Foundation

/// Central data provider providing structured mock data for development and testing.
public struct MockVocabularyDataSource: Sendable {
    public static let shared = MockVocabularyDataSource()

    public let mockWords: [Word] = [
        Word(
            id: 1,
            lemma: "Ephemeral",
            pos: "adjective",
            ipaUs: "/ɪˈfem.ər.əl/",
            cefrLevel: "B2",
            definitionEn: "lasting for a very short time",
            definitionVi: "Phù du, ngắn ngủi",
            example: "Her fame proved to be ephemeral."
        ),
        Word(
            id: 2,
            lemma: "Resilience",
            pos: "noun",
            ipaUs: "/rɪˈzɪl.jəns/",
            cefrLevel: "C1",
            definitionEn: "the capacity to recover quickly from difficulties",
            definitionVi: "Tính kiên cường, sự phục hồi",
            example: "Courage and resilience are essential for victory."
        ),
        Word(
            id: 3,
            lemma: "Serendipity",
            pos: "noun",
            ipaUs: "/ˌser.ənˈdɪp.ə.ti/",
            cefrLevel: "C2",
            definitionEn: "finding valuable or agreeable things not sought for",
            definitionVi: "Sự tình cờ may mắn",
            example: "Finding out about the job opening was pure serendipity."
        )
    ]

    public let mockSuggestedWords: [SuggestedWord] = [
        SuggestedWord(
            id: "s1",
            lemma: "Resilience",
            pos: "noun",
            ipaUs: "/rɪˈzɪl.jəns/",
            cefrLevel: "C1",
            definitionVi: "Khả năng phục hồi nhanh chóng sau khó khăn.",
            definitionEn: "The capacity to recover quickly from difficulties; toughness.",
            example: "Her resilience helped her overcome the financial hardship.",
            isBookmarked: false,
            topicTag: "Từ vựng nổi bật"
        ),
        SuggestedWord(
            id: "s2",
            lemma: "Ubiquitous",
            pos: "adjective",
            ipaUs: "/juːˈbɪk.wə.t̬əs/",
            cefrLevel: "C1",
            definitionVi: "Có mặt ở khắp mọi nơi.",
            definitionEn: "Present, appearing, or found everywhere.",
            example: "Smartphones have become ubiquitous in modern society.",
            isBookmarked: true,
            topicTag: "Công nghệ"
        )
    ]

    public let mockReflexDrills: [ReflexDrillRecord] = [
        ReflexDrillRecord(
            id: 101,
            drillType: "multiple_choice",
            promptText: "Chọn nghĩa chính xác của 'Ephemeral':",
            correctAnswer: "Phù du, ngắn ngủi",
            distractors: ["Lâu dài", "Vĩnh cửu", "Kiên cường"],
            targetTimeMs: 3000
        ),
        ReflexDrillRecord(
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
            badgeColor: .blue,
            iconName: "cpu"
        ),
        TopicDeck(
            id: "business",
            title: "Kinh doanh & Tài chính",
            wordCount: 45,
            completionPercentage: 0.60,
            badgeColor: .green,
            iconName: "chart.bar.fill"
        )
    ]


    public init() {}
}
