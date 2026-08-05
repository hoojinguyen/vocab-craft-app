import Foundation

/// Entity representing a daily recommended vocabulary word.
public struct SuggestedWord: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let lemma: String
    public let pos: String
    public let ipaUs: String
    public let cefrLevel: String
    public let definitionVi: String
    public let definitionEn: String
    public let example: String
    public var isBookmarked: Bool
    public let topicTag: String

    public init(
        id: String,
        lemma: String,
        pos: String = "noun",
        ipaUs: String,
        cefrLevel: String,
        definitionVi: String,
        definitionEn: String,
        example: String,
        isBookmarked: Bool = false,
        topicTag: String = "Từ vựng nổi bật"
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.ipaUs = ipaUs
        self.cefrLevel = cefrLevel
        self.definitionVi = definitionVi
        self.definitionEn = definitionEn
        self.example = example
        self.isBookmarked = isBookmarked
        self.topicTag = topicTag
    }
}

extension SuggestedWord {
    public static let sampleWords: [SuggestedWord] = [
        SuggestedWord(
            id: "s1",
            lemma: "Resilience",
            pos: "noun",
            ipaUs: "/rɪˈzɪl.jəns/",
            cefrLevel: "C1",
            definitionVi: "Khả năng phục hồi nhanh chóng sau khó khăn, sự kiên cường.",
            definitionEn: "The capacity to recover quickly from difficulties; toughness.",
            example: "Her resilience in facing challenges inspired the entire team.",
            isBookmarked: false,
            topicTag: "Mindset & Tư duy"
        ),
        SuggestedWord(
            id: "s2",
            lemma: "Serendipity",
            pos: "noun",
            ipaUs: "/ˌser.ənˈdɪp.ə.ti/",
            cefrLevel: "C2",
            definitionVi: "Sự tình cờ may mắn phát hiện ra những điều thú vị.",
            definitionEn: "The occurrence of events by chance in a happy or beneficial way.",
            example: "Finding this rare book was pure serendipity.",
            isBookmarked: true,
            topicTag: "Từ vựng nâng cao"
        ),
        SuggestedWord(
            id: "s3",
            lemma: "Ubiquitous",
            pos: "adjective",
            ipaUs: "/juːˈbɪk.wə.t̬əs/",
            cefrLevel: "C1",
            definitionVi: "Có mặt ở khắp mọi nơi, phổ biến rộng rãi.",
            definitionEn: "Present, appearing, or found everywhere.",
            example: "Smartphones have become ubiquitous in modern society.",
            isBookmarked: false,
            topicTag: "Công nghệ & Đời sống"
        ),
        SuggestedWord(
            id: "s4",
            lemma: "Eloquent",
            pos: "adjective",
            ipaUs: "/ˈel.ə.kwənt/",
            cefrLevel: "B2",
            definitionVi: "Hùng hồn, lưu loát và có sức thuyết phục cao.",
            definitionEn: "Fluent or persuasive in speaking or writing.",
            example: "She gave an eloquent speech that moved the audience.",
            isBookmarked: false,
            topicTag: "Giao tiếp & Thuyết trình"
        ),
        SuggestedWord(
            id: "s5",
            lemma: "Meticulous",
            pos: "adjective",
            ipaUs: "/məˈtɪk.jə.ləs/",
            cefrLevel: "C1",
            definitionVi: "Tỉ mỉ, cẩn thận từng chi tiết nhỏ.",
            definitionEn: "Showing great attention to detail; very careful and precise.",
            example: "He took meticulous notes during the research project.",
            isBookmarked: false,
            topicTag: "Thói quen làm việc"
        ),
        SuggestedWord(
            id: "s6",
            lemma: "Pragmatic",
            pos: "adjective",
            ipaUs: "/præɡˈmæt̬.ɪk/",
            cefrLevel: "B2",
            definitionVi: "Thực tế, giải quyết vấn đề dựa trên thực tiễn.",
            definitionEn: "Dealing with things sensibly and realistically in a practical way.",
            example: "We need a pragmatic approach to solve this engineering issue.",
            isBookmarked: false,
            topicTag: "Chiến lược & Kinh doanh"
        )
    ]
}
