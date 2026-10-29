import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking learned-word picker")
struct SpeakingWordPickerTests {
    @Test func pickerExcludesBookmarkOnlyWordsAndReturnsWeakestResolvableWordsFirst() async throws {
        let progress = [
            progressData(wordId: 1, mastery: 0, bookmarked: true),
            progressData(wordId: 2, mastery: 3, reviews: 5),
            progressData(wordId: 3, mastery: 1, mistakes: 4, reviews: 5),
            progressData(wordId: 4, mastery: 1, mistakes: 1, reviews: 3),
            progressData(wordId: 5, mastery: 0, reviews: 2)
        ]
        let picker = SpeakingWordPicker(
            progressRepository: MockUserProgressRepository(initialData: progress),
            vocabulary: SpeakingVocabularyStub()
        )

        #expect(try await picker.pick().map(\.wordId) == [3, 4, 2])
    }

    @Test func pickerUsesEarlierReviewDateToBreakRemainingTies() async throws {
        let earlier = Date(timeIntervalSince1970: 100)
        let later = Date(timeIntervalSince1970: 200)
        let progress = [
            progressData(wordId: 1, mastery: 1, mistakes: 2, reviews: 1, lastReviewDate: later),
            progressData(wordId: 2, mastery: 1, mistakes: 2, reviews: 1, lastReviewDate: earlier),
            progressData(wordId: 3, mastery: 1, mistakes: 2, reviews: 1, lastReviewDate: Date(timeIntervalSince1970: 300))
        ]
        let picker = SpeakingWordPicker(
            progressRepository: MockUserProgressRepository(initialData: progress),
            vocabulary: SpeakingVocabularyStub()
        )

        #expect(try await picker.pick().map(\.wordId) == [2, 1, 3])
    }

    @Test func pickerHonorsLimitAndReturnsEmptyForNonpositiveLimits() async throws {
        let progress = (1...3).map {
            progressData(wordId: Int64($0), mastery: $0, reviews: 1)
        }
        let picker = SpeakingWordPicker(
            progressRepository: MockUserProgressRepository(initialData: progress),
            vocabulary: SpeakingVocabularyStub()
        )

        #expect(try await picker.pick(limit: 2).count == 2)
        #expect(try await picker.pick(limit: 0).isEmpty)
        #expect(try await picker.pick(limit: -1).isEmpty)
    }

    private func progressData(
        wordId: Int64,
        mastery: Int,
        bookmarked: Bool = false,
        mistakes: Int = 0,
        reviews: Int = 0,
        lastReviewDate: Date = Date(timeIntervalSince1970: 1)
    ) -> UserWordProgressData {
        UserWordProgressData(
            wordId: wordId,
            masteryLevel: mastery,
            isBookmarked: bookmarked,
            lastReviewDate: lastReviewDate,
            totalReviews: reviews,
            mistakeCount: mistakes
        )
    }
}

private struct SpeakingVocabularyStub: VocabularyDataSourceProtocol {
    private let base = MockVocabularyDataSource()
    private let additionalWord = TopicWordDTO(
        id: 4, stageId: "speaking-test", lemma: "practice", phonetic: "", pos: "verb", cefrLevel: "A2",
        definitionVi: "luyện tập", definitionEn: "to do something repeatedly", exampleEn: "", exampleVi: ""
    )

    func fetchTopicDecks() async throws -> [TopicDeckDTO] { try await base.fetchTopicDecks() }
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        try await base.fetchSubTopicStages(deckId: deckId)
    }
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        try await base.fetchWordsForStage(stageId: stageId)
    }
    func searchWords(query: String) async throws -> [TopicWordDTO] { try await base.searchWords(query: query) }
    func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
        if id == additionalWord.id { return additionalWord }
        return try await base.fetchWordById(id: id)
    }
    func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO] {
        let words = MockVocabularyDataSource.mockTopicWords + [additionalWord]
        return words.filter { ids.contains($0.id) }
    }
    func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO] { try await base.fetchAllWordsMap() }
}
