import Foundation
@testable import VocabCraftApp

public final class MockVocabularyRepository: VocabularyRepositoryProtocol, @unchecked Sendable {
    public var mockWords: [Word] = [
        Word(
            id: 1,
            lemma: "Ephemeral",
            pos: "adj.",
            ipaUs: "/ɪˈfem.ər.əl/",
            cefrLevel: "B2",
            definitionEn: "lasting for a very short time",
            definitionVi: "Phù du, ngắn ngủi",
            example: "Her fame proved to be ephemeral."
        ),
        Word(
            id: 2,
            lemma: "Resilience",
            pos: "n.",
            ipaUs: "/rɪˈzɪl.jəns/",
            cefrLevel: "C1",
            definitionEn: "capacity to recover quickly",
            definitionVi: "Tính kiên cường, sự phục hồi",
            example: "Courage and resilience are essential for victory."
        )
    ]

    public init(mockWords: [Word]? = nil) {
        if let words = mockWords {
            self.mockWords = words
        }
    }

    public func fetchWordRecords(limit: Int) async throws -> [Word] {
        return Array(mockWords.prefix(limit))
    }

    public func fetchWord(id: Int64) async throws -> Word? {
        return mockWords.first { $0.id == id }
    }

    public func fetchReflexDrillRecords(cefrLevel: String) async throws -> [ReflexDrillItem] {
        return [
            ReflexDrillItem(
                id: 101,
                drillType: "multiple_choice",
                promptText: "Choose correct meaning for 'Ephemeral'",
                correctAnswer: "Phù du, ngắn ngủi",
                distractors: ["Lâu dài", "Vĩnh cửu", "Kiên cường"],
                targetTimeMs: 3000
            )
        ]
    }

    public func searchWords(query: String) async throws -> [Word] {
        return mockWords.filter { $0.lemma.localizedCaseInsensitiveContains(query) }
    }

    public func fetchSuggestedWords(limit: Int) async throws -> [SuggestedWord] {
        return []
    }
}
