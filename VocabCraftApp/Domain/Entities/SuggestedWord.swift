import Foundation

/// Entity representing a daily recommended vocabulary word.
public struct SuggestedWord: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public var lemma: String
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

#if DEBUG
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
        )
    ]
}
#endif
