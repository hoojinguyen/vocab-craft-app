import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("PersonalVaultViewModel Tests")
struct PersonalVaultViewModelTests {
    @Test("Toggle chọn từng từ và Chọn tất cả, Bỏ chọn tất cả")
    @MainActor
    func testSelectionManagement() async {
        let mockWords = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung")
        ]

        let vm = PersonalVaultViewModel(mockWords: mockWords)
        #expect(vm.selectedWordIds.isEmpty)
        #expect(vm.selectedWords.isEmpty)

        // Toggle chọn từ 1
        vm.toggleWordSelection(id: 1)
        #expect(vm.selectedWordIds.contains(1))
        #expect(vm.selectedWords.count == 1)
        #expect(vm.selectedWords.first?.id == 1)

        // Toggle bỏ chọn từ 1
        vm.toggleWordSelection(id: 1)
        #expect(vm.selectedWordIds.isEmpty)
        #expect(vm.selectedWords.isEmpty)

        // Chọn tất cả
        vm.selectAll()
        #expect(vm.selectedWordIds.count == 2)
        #expect(vm.selectedWordIds.contains(1))
        #expect(vm.selectedWordIds.contains(2))
        #expect(vm.selectedWords.count == 2)

        // Bỏ chọn tất cả
        vm.deselectAll()
        #expect(vm.selectedWordIds.isEmpty)
        #expect(vm.selectedWords.isEmpty)
    }

    @Test("Chuyển đổi bộ lọc 3 tabs VaultTabFilter")
    @MainActor
    func testVaultTabFilterChanges() async {
        let vm = PersonalVaultViewModel()
        #expect(vm.vaultTabFilter == .notMastered)

        vm.setVaultFilter(.mastered)
        #expect(vm.vaultTabFilter == .mastered)

        vm.setVaultFilter(.bookmarked)
        #expect(vm.vaultTabFilter == .bookmarked)

        vm.setVaultFilter(.notMastered)
        #expect(vm.vaultTabFilter == .notMastered)
    }

    @Test("Tải dữ liệu vaultWords từ FetchPersonalVaultUseCase theo bộ lọc")
    @MainActor
    func testLoadVaultWordsFromUseCase() async {
        let mockWords = [
            VaultWordItem(id: 10, lemma: "resilience", pos: "n.", definitionVi: "Khả năng phục hồi", isMastered: false),
            VaultWordItem(id: 20, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện", isMastered: true)
        ]
        let mockUseCase = MockFetchPersonalVaultUseCase(vaultWords: mockWords)
        let vm = PersonalVaultViewModel(fetchVaultUseCase: mockUseCase)

        #expect(vm.vaultWords.isEmpty)

        // Mặc định .notMastered -> chỉ trả về resilience
        await vm.loadData()
        #expect(vm.vaultWords.count == 1)
        #expect(vm.vaultWords.first?.id == 10)
        #expect(vm.vaultWords.first?.lemma == "resilience")

        // Chuyển sang .mastered -> chỉ trả về eloquent
        vm.setVaultFilter(.mastered)
        await vm.loadData()
        #expect(vm.vaultWords.count == 1)
        #expect(vm.vaultWords.first?.id == 20)
        #expect(vm.vaultWords.first?.lemma == "eloquent")
    }

    @Test("Tìm kiếm và lọc vaultWords qua query")
    @MainActor
    func testSearchQueryWithVaultWords() async {
        let mockWords = [
            VaultWordItem(id: 1, lemma: "adaptable", pos: "adj.", definitionVi: "Thích nghi", isMastered: false),
            VaultWordItem(id: 2, lemma: "diligent", pos: "adj.", definitionVi: "Chăm chỉ", isMastered: false)
        ]
        let mockUseCase = MockFetchPersonalVaultUseCase(vaultWords: mockWords)
        let vm = PersonalVaultViewModel(fetchVaultUseCase: mockUseCase)

        vm.setSearchQuery("adapt")
        #expect(vm.searchQuery == "adapt")

        await vm.loadData()
        #expect(vm.vaultWords.count == 1)
        #expect(vm.vaultWords.first?.lemma == "adaptable")
    }

    @Test("Chuẩn bị danh sách từ ôn luyện theo tab hiện tại")
    @MainActor
    func testPrepareReviewWordsMatchesActiveTab() async {
        var mockWords: [VaultWordItem] = []
        for i in 1...20 {
            mockWords.append(
                VaultWordItem(
                    id: Int64(i),
                    lemma: "word_\(i)",
                    pos: "n.",
                    definitionVi: "Nghĩa \(i)",
                    isMastered: i > 16,
                    isBookmarked: i % 2 == 0,
                    correctStreak: 20 - i
                )
            )
        }

        let vm = PersonalVaultViewModel(mockWords: mockWords)
        #expect(vm.reviewWords.isEmpty)

        // 1. Tab .notMastered: Lấy tối đa 15 từ chưa thuộc, ưu tiên streak thấp
        vm.setVaultFilter(.notMastered)
        let unmasteredReview = vm.prepareReviewWords()
        #expect(unmasteredReview.count == 15)
        #expect(unmasteredReview.allSatisfy { !$0.isMastered })
        #expect(vm.reviewWords.count == 15)
        #expect(vm.reviewWords == unmasteredReview)
        if unmasteredReview.count >= 2 {
            #expect(unmasteredReview[0].correctStreak <= unmasteredReview[1].correctStreak)
        }

        // 2. Tab .bookmarked: Lấy các từ đã lưu
        vm.setVaultFilter(.bookmarked)
        let bookmarkedReview = vm.prepareReviewWords()
        #expect(!bookmarkedReview.isEmpty)
        #expect(bookmarkedReview.allSatisfy { $0.isBookmarked })
        #expect(vm.reviewWords == bookmarkedReview)

        // 3. Tab .mastered: Lấy các từ đã thuộc
        vm.setVaultFilter(.mastered)
        let masteredReview = vm.prepareReviewWords()
        #expect(!masteredReview.isEmpty)
        #expect(masteredReview.allSatisfy { $0.isMastered })
        #expect(vm.reviewWords == masteredReview)
    }

    @Test("Chọn và đóng sheet chi tiết từ vựng")
    @MainActor
    func testDetailSheetSelection() async {
        let vm = PersonalVaultViewModel()
        #expect(vm.selectedWordForDetail == nil)

        let word = VaultWordItem(id: 42, lemma: "paradigm", pos: "n.", definitionVi: "Mô hình")
        vm.selectWordForDetail(word)
        #expect(vm.selectedWordForDetail?.id == 42)
        #expect(vm.selectedWordForDetail?.lemma == "paradigm")

        vm.dismissWordDetail()
        #expect(vm.selectedWordForDetail == nil)
    }

    @Test("Phát âm từ vựng VaultWordItem qua TextToSpeech")
    @MainActor
    func testPlayAudioForVaultWord() async {
        let mockTTS = MockTTS()
        let vm = PersonalVaultViewModel(ttsService: mockTTS)
        let word = VaultWordItem(id: 1, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện")

        #expect(!vm.isSpeakingAudio)
        mockTTS.isSpeaking = true
        #expect(vm.isSpeakingAudio)

        vm.playAudio(for: word)
        #expect(mockTTS.lastSpokenText == "eloquent")
    }

    @Test("Toggle bookmark tự động làm mới vaultWords và metrics")
    @MainActor
    func testToggleBookmarkRefreshesData() async {
        let word1 = VaultWordItem(id: 1, lemma: "adapt", pos: "v.", definitionVi: "Thích nghi", isBookmarked: false)
        let word2 = VaultWordItem(id: 2, lemma: "brave", pos: "adj.", definitionVi: "Dũng cảm", isBookmarked: true)

        let mockUseCase = MockFetchPersonalVaultUseCase(vaultWords: [word1, word2])
        let mockBookmarkUseCase = MockToggleBookmarkUseCase(mockUseCase: mockUseCase)
        let vm = PersonalVaultViewModel(
            fetchVaultUseCase: mockUseCase,
            toggleBookmarkUseCase: mockBookmarkUseCase
        )

        await vm.loadData()
        #expect(vm.vaultWords.first(where: { $0.id == 1 })?.isBookmarked == false)

        await vm.toggleBookmark(wordId: 1)
        #expect(mockBookmarkUseCase.executedWordIds.contains(1))
        #expect(vm.vaultWords.first(where: { $0.id == 1 })?.isBookmarked == true)
    }

    @Test("Smart Pick chọn các từ vựng ưu tiên và cập nhật selectedWordIds với selector xác định")
    @MainActor
    func testSmartPickWords() async {
        let word1 = VaultWordItem(id: 101, lemma: "weak", pos: "adj", definitionVi: "yếu")
        let word2 = VaultWordItem(id: 102, lemma: "medium", pos: "adj", definitionVi: "vừa")
        let word3 = VaultWordItem(id: 103, lemma: "strong", pos: "adj", definitionVi: "mạnh")

        let vm = PersonalVaultViewModel(
            smartSelector: PrefixSmartSelector(),
            mockWords: [word1, word2, word3]
        )
        #expect(vm.selectedWordIds.isEmpty)

        let picked = vm.smartPickWords(targetCount: 2)
        #expect(picked.count == 2)
        #expect(vm.selectedWordIds.count == 2)
        #expect(vm.selectedWordIds.contains(101))
        #expect(vm.selectedWordIds.contains(102))
        #expect(picked.first?.id == 101)
    }

    @Test("Smart Pick tuân thủ bộ lọc vaultTabFilter")
    @MainActor
    func testSmartPickWordsRespectsTabFilter() async {
        let unmastered = VaultWordItem(id: 1, lemma: "learn", pos: "v", definitionVi: "học", isMastered: false)
        let mastered = VaultWordItem(id: 2, lemma: "master", pos: "v", definitionVi: "thành thạo", isMastered: true)

        let vm = PersonalVaultViewModel(
            smartSelector: PrefixSmartSelector(),
            mockWords: [unmastered, mastered]
        )

        vm.vaultTabFilter = .notMastered
        let unmasteredPicks = vm.smartPickWords(targetCount: 5)
        #expect(unmasteredPicks.count == 1)
        #expect(unmasteredPicks.first?.id == 1)

        vm.vaultTabFilter = .mastered
        let masteredPicks = vm.smartPickWords(targetCount: 5)
        #expect(masteredPicks.count == 1)
        #expect(masteredPicks.first?.id == 2)

        vm.vaultTabFilter = .bookmarked
        let bookmarkedPicks = vm.smartPickWords(targetCount: 5)
        #expect(bookmarkedPicks.isEmpty)
        #expect(vm.selectedWordIds.isEmpty)
    }
}

// MARK: - Test Helpers

private final class PrefixSmartSelector: SmartVaultWordSelectorProtocol, @unchecked Sendable {
    func selectWords(from pool: [VaultWordItem], targetCount: Int) -> [VaultWordItem] {
        Array(pool.prefix(targetCount))
    }
}

@MainActor
private final class MockTTS: TextToSpeechProtocol {
    var lastSpokenText: String?
    var isSpeaking: Bool = false

    func speak(text: String, rate: Float, locale: String) {
        lastSpokenText = text
    }

    func stop() {}
}

private final class MockFetchPersonalVaultUseCase: FetchPersonalVaultUseCaseProtocol, @unchecked Sendable {
    var vaultWords: [VaultWordItem]

    init(vaultWords: [VaultWordItem] = []) {
        self.vaultWords = vaultWords
    }

    func execute(filter: PersonalVaultFilter, searchQuery: String?) async throws -> PersonalVaultResult {
        let total = vaultWords.count
        let mastered = vaultWords.filter(\.isMastered).count
        let bookmarked = vaultWords.filter(\.isBookmarked).count
        let metrics = PersonalVaultMetrics(
            totalWords: total,
            needsReviewCount: 0,
            masteredCount: mastered,
            bookmarkedCount: bookmarked,
            unmasteredCount: total - mastered
        )
        return PersonalVaultResult(words: [], metrics: metrics)
    }

    func fetchVaultWords(filter: VaultTabFilter, searchQuery: String?) async throws -> [VaultWordItem] {
        var filtered = vaultWords
        switch filter {
        case .notMastered:
            filtered = vaultWords.filter { !$0.isMastered }
        case .mastered:
            filtered = vaultWords.filter(\.isMastered)
        case .bookmarked:
            filtered = vaultWords.filter(\.isBookmarked)
        }

        if let query = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            let lower = query.lowercased()
            filtered = filtered.filter {
                $0.lemma.lowercased().contains(lower) ||
                $0.definitionVi.lowercased().contains(lower) ||
                $0.phonetic.lowercased().contains(lower)
            }
        }

        return filtered
    }

    func toggleBookmark(wordId: Int64) {
        if let index = vaultWords.firstIndex(where: { $0.id == wordId }) {
            let old = vaultWords[index]
            vaultWords[index] = VaultWordItem(
                id: old.id,
                lemma: old.lemma,
                pos: old.pos,
                phonetic: old.phonetic,
                definitionVi: old.definitionVi,
                exampleSentenceEn: old.exampleSentenceEn,
                exampleSentenceVi: old.exampleSentenceVi,
                cefrLevel: old.cefrLevel,
                isMastered: old.isMastered,
                isBookmarked: !old.isBookmarked,
                correctStreak: old.correctStreak,
                practicedModes: old.practicedModes,
                lastPracticedAt: old.lastPracticedAt
            )
        }
    }
}

private final class MockToggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol, @unchecked Sendable {
    private let mockUseCase: MockFetchPersonalVaultUseCase
    var executedWordIds: [Int64] = []

    init(mockUseCase: MockFetchPersonalVaultUseCase) {
        self.mockUseCase = mockUseCase
    }

    func execute(wordId: Int64) async throws -> Bool {
        executedWordIds.append(wordId)
        mockUseCase.toggleBookmark(wordId: wordId)
        return true
    }
}
#endif
