import Foundation
import Testing
@testable import VocabCraftApp

@Suite("MixedReflexQueueUseCase & RecordMixedDrillAttempt Tests")
struct MixedReflexQueueUseCaseTests {

    // MARK: - GenerateMixedReflexQueueUseCase Tests

    @Test("Tạo hàng đợi gán ngẫu nhiên 4 mode cho danh sách từ")
    func testGenerateQueue() {
        let useCase = GenerateMixedReflexQueueUseCase()
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung"),
            VaultWordItem(id: 3, lemma: "create", pos: "v.", definitionVi: "Tạo ra")
        ]

        let queue = useCase.generate(from: words)
        #expect(queue.count == 3)
        #expect(queue.map(\.word.id) == [1, 2, 3])
        #expect(queue.allSatisfy { $0.isRetry == false })
    }

    @Test("Requeue từ làm sai chọn mode mới khác mode vừa sai")
    func testRequeueFailedItemDifferentMode() {
        let useCase = GenerateMixedReflexQueueUseCase()
        let word = VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen")
        let failedItem = MixedReflexDrillItem(word: word, assignedMode: .multipleChoice)

        let retryItem = useCase.requeueFailedItem(failedItem)
        #expect(retryItem.word.id == 1)
        #expect(retryItem.isRetry == true)
        #expect(retryItem.assignedMode != .multipleChoice)
    }

    @Test("Requeue nhiều lần luôn đổi sang mode khác với mode hiện tại")
    func testRequeueMultipleTimesAlwaysChangesMode() {
        let useCase = GenerateMixedReflexQueueUseCase()
        let word = VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen")
        for mode in ReflexBlitzMode.allCases {
            let item = MixedReflexDrillItem(word: word, assignedMode: mode)
            let retry = useCase.requeueFailedItem(item)
            #expect(retry.assignedMode != mode)
            #expect(retry.isRetry == true)
        }
    }

    // MARK: - RecordMixedDrillAttemptUseCase Tests

    @Test("Ghi nhận kết quả trả lời đúng lần đầu, tăng streak và thêm mode")
    func testRecordAttemptFirstCorrectAnswer() async throws {
        let mockRepo = MockUserProgressRepository()
        let mockDataSource = SampleVocabularyDataSource()
        let sut = RecordMixedDrillAttemptUseCase(progressRepo: mockRepo, dataSource: mockDataSource)

        let result = try await sut.execute(wordId: 1, mode: .multipleChoice, isCorrect: true)
        #expect(result != nil)
        #expect(result?.id == 1)
        #expect(result?.correctStreak == 1)
        #expect(result?.practicedModes.contains(.multipleChoice) == true)
        #expect(result?.isMastered == false)
    }

    @Test("Đạt điều kiện thành thạo khi streak >= 3 và có >= 2 modes")
    func testRecordAttemptMasteryPromotion() async throws {
        let mockRepo = MockUserProgressRepository(initialData: [
            UserWordProgressData(
                wordId: 1,
                consecutiveCorrectStreak: 2,
                practicedModes: [.multipleChoice]
            )
        ])
        let mockDataSource = SampleVocabularyDataSource()
        let sut = RecordMixedDrillAttemptUseCase(progressRepo: mockRepo, dataSource: mockDataSource)

        let result = try await sut.execute(wordId: 1, mode: .speaking, isCorrect: true)
        #expect(result != nil)
        #expect(result?.correctStreak == 3)
        #expect(result?.practicedModes.contains(.speaking) == true)
        #expect(result?.practicedModes.contains(.multipleChoice) == true)
        #expect(result?.isMastered == true)
    }

    @Test("Trả lời sai lập tức reset streak về 0 và huỷ thành thạo")
    func testRecordAttemptWrongAnswerResetsMastery() async throws {
        let mockRepo = MockUserProgressRepository(initialData: [
            UserWordProgressData(
                wordId: 1,
                consecutiveCorrectStreak: 4,
                practicedModes: [.multipleChoice, .speaking],
                isMastered: true
            )
        ])
        let mockDataSource = SampleVocabularyDataSource()
        let sut = RecordMixedDrillAttemptUseCase(progressRepo: mockRepo, dataSource: mockDataSource)

        let result = try await sut.execute(wordId: 1, mode: .typing, isCorrect: false)
        #expect(result != nil)
        #expect(result?.correctStreak == 0)
        #expect(result?.practicedModes.isEmpty == true)
        #expect(result?.isMastered == false)
    }

    @Test("Từ không tồn tại trong data source trả về nil")
    func testRecordAttemptNonExistentWordReturnsNil() async throws {
        let mockRepo = MockUserProgressRepository()
        let mockDataSource = SampleVocabularyDataSource()
        let sut = RecordMixedDrillAttemptUseCase(progressRepo: mockRepo, dataSource: mockDataSource)

        let result = try await sut.execute(wordId: 999999, mode: .multipleChoice, isCorrect: true)
        #expect(result == nil)
    }

    // MARK: - FetchPersonalVaultUseCase Vault Words Mapping Tests

    @Test("FetchPersonalVaultUseCase hỗ trợ fetchVaultWords theo 3 tab lọc")
    func testFetchVaultWordsTabs() async throws {
        let mockRepo = MockUserProgressRepository(initialData: [
            UserWordProgressData(
                wordId: 1,
                isBookmarked: false,
                consecutiveCorrectStreak: 3,
                practicedModes: [.multipleChoice, .speaking],
                isMastered: true
            ),
            UserWordProgressData(
                wordId: 2,
                isBookmarked: true,
                consecutiveCorrectStreak: 1,
                practicedModes: [.typing],
                isMastered: false
            ),
            UserWordProgressData(
                wordId: 3,
                isBookmarked: true,
                consecutiveCorrectStreak: 3,
                practicedModes: [.multipleChoice, .listening],
                isMastered: true
            )
        ])
        let mockDataSource = SampleVocabularyDataSource()
        let sut = FetchPersonalVaultUseCase(dataSource: mockDataSource, progressRepo: mockRepo)

        let notMastered = try await sut.fetchVaultWords(filter: .notMastered)
        #expect(notMastered.count == 1)
        #expect(notMastered.first?.id == 2)

        let mastered = try await sut.fetchVaultWords(filter: .mastered)
        #expect(mastered.count == 2)

        let bookmarked = try await sut.fetchVaultWords(filter: .bookmarked)
        #expect(bookmarked.count == 2)

        let searched = try await sut.fetchVaultWords(filter: .notMastered, searchQuery: "Overwhelmed")
        #expect(searched.count == 1)
        #expect(searched.first?.id == 2)
    }
}
