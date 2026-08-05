import Foundation

public struct WordItem: Identifiable, Equatable, Sendable {
    public let id: Int64
    public let lemma: String
    public let phonetic: String
    public let pos: String
    public let definition: String
    public let exampleSentenceEn: String
    public let exampleSentenceVi: String
    public let cefrLevel: String
    public var masteryLevel: Int
    public var nextReviewDate: Date

    public init(
        id: Int64,
        lemma: String,
        phonetic: String,
        pos: String,
        definition: String,
        exampleSentenceEn: String,
        exampleSentenceVi: String,
        cefrLevel: String,
        masteryLevel: Int,
        nextReviewDate: Date = Date()
    ) {
        self.id = id
        self.lemma = lemma
        self.phonetic = phonetic
        self.pos = pos
        self.definition = definition
        self.exampleSentenceEn = exampleSentenceEn
        self.exampleSentenceVi = exampleSentenceVi
        self.cefrLevel = cefrLevel
        self.masteryLevel = masteryLevel
        self.nextReviewDate = nextReviewDate
    }

    public static let mockData: [WordItem] = [
        WordItem(
            id: 1,
            lemma: "Ephemeral",
            phonetic: "/ɪˈfem.ər.əl/",
            pos: "adj.",
            definition: "Phù du, chóng phai, kéo dài trong thời gian ngắn",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Sự nổi tiếng của cô ấy chỉ kéo dài ngắn ngủi.",
            cefrLevel: "B2",
            masteryLevel: 4
        ),
        WordItem(
            id: 2,
            lemma: "Resilience",
            phonetic: "/rɪˈzɪl.jəns/",
            pos: "n.",
            definition: "Khả năng phục hồi, tính kiên cường",
            exampleSentenceEn: "Courage and resilience are essential for victory.",
            exampleSentenceVi: "Lòng dũng cảm và sự kiên cường là cần thiết để chiến thắng.",
            cefrLevel: "C1",
            masteryLevel: 5
        ),
        WordItem(
            id: 3,
            lemma: "Meticulous",
            phonetic: "/məˈtɪk.jə.ləs/",
            pos: "adj.",
            definition: "Tỉ mỉ, cẩn thận từng chi tiết",
            exampleSentenceEn: "He paid meticulous attention to detail.",
            exampleSentenceVi: "Anh ấy chú ý tỉ mỉ đến từng chi tiết.",
            cefrLevel: "B2",
            masteryLevel: 2
        )
    ]
}
