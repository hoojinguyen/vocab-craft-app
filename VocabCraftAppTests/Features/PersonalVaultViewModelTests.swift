import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("PersonalVaultViewModel Tests")
struct PersonalVaultViewModelTests {
    @Test("Toggle word selection, Select All, and Deselect All")
    @MainActor
    func testSelectionManagement() async {
        let mockWords = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung")
        ]

        let vm = PersonalVaultViewModel(mockWords: mockWords)
        #expect(vm.selectedWordIds.isEmpty)
        #expect(vm.selectedWords.isEmpty)

        // Toggle select word 1
        vm.toggleWordSelection(id: 1)
        #expect(vm.selectedWordIds.contains(1))
        #expect(vm.selectedWords.count == 1)
        #expect(vm.selectedWords.first?.id == 1)

        // Toggle deselect word 1
        vm.toggleWordSelection(id: 1)
        #expect(vm.selectedWordIds.isEmpty)
        #expect(vm.selectedWords.isEmpty)

        // Select all
        vm.selectAll()
        #expect(vm.selectedWordIds.count == 2)
        #expect(vm.selectedWordIds.contains(1))
        #expect(vm.selectedWordIds.contains(2))
        #expect(vm.selectedWords.count == 2)

        // Deselect all
        vm.deselectAll()
        #expect(vm.selectedWordIds.isEmpty)
        #expect(vm.selectedWords.isEmpty)
    }

    @Test("Switches 3-tab VaultTabFilter correctly")
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

    @Test("Loads vaultWords from FetchPersonalVaultUseCase according to filter")
    @MainActor
    func testLoadVaultWordsFromUseCase() async {
        let mockWords = [
            VaultWordItem(id: 10, lemma: "resilience", pos: "n.", definitionVi: "Khả năng phục hồi", isMastered: false),
            VaultWordItem(id: 20, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện", isMastered: true)
        ]
        let mockUseCase = MockFetchPersonalVaultUseCase(vaultWords: mockWords)
        let vm = PersonalVaultViewModel(fetchVaultUseCase: mockUseCase)

        #expect(vm.vaultWords.isEmpty)

        // Default .notMastered -> only returns resilience
        await vm.loadData()
        #expect(vm.vaultWords.count == 1)
        #expect(vm.vaultWords.first?.id == 10)
        #expect(vm.vaultWords.first?.lemma == "resilience")

        // Switch to .mastered -> only returns eloquent
        vm.setVaultFilter(.mastered)
        await vm.loadData()
        #expect(vm.vaultWords.count == 1)
        #expect(vm.vaultWords.first?.id == 20)
        #expect(vm.vaultWords.first?.lemma == "eloquent")
    }

    @Test("Search and filter vaultWords via query")
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

    @Test("Prepares review words matching active tab")
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

        // 1. Tab .notMastered: Pick max 15 unmastered words, prioritizing lowest streak
        vm.setVaultFilter(.notMastered)
        let unmasteredReview = vm.prepareReviewWords()
        #expect(unmasteredReview.count == 15)
        #expect(unmasteredReview.allSatisfy { !$0.isMastered })
        #expect(vm.reviewWords.count == 15)
        #expect(vm.reviewWords == unmasteredReview)
        if unmasteredReview.count >= 2 {
            #expect(unmasteredReview[0].correctStreak <= unmasteredReview[1].correctStreak)
        }

        // 2. Tab .bookmarked: Pick bookmarked words
        vm.setVaultFilter(.bookmarked)
        let bookmarkedReview = vm.prepareReviewWords()
        #expect(!bookmarkedReview.isEmpty)
        #expect(bookmarkedReview.allSatisfy { $0.isBookmarked })
        #expect(vm.reviewWords == bookmarkedReview)

        // 3. Tab .mastered: Pick mastered words
        vm.setVaultFilter(.mastered)
        let masteredReview = vm.prepareReviewWords()
        #expect(!masteredReview.isEmpty)
        #expect(masteredReview.allSatisfy { $0.isMastered })
        #expect(vm.reviewWords == masteredReview)
    }

    @Test("Select and dismiss vocabulary detail sheet")
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

    @Test("Pronounce VaultWordItem through TextToSpeech")
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

    @Test("Toggle bookmark automatically refreshes vaultWords and metrics")
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

    @Test("Smart Pick selects prioritized words and updates selectedWordIds")
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

    @Test("Smart Pick respects active vaultTabFilter")
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

    @Test("Smart Pick uses dailyGoalCount from UserSettingsStore as default value")
    @MainActor
    func testSmartPickWordsDefaultsToDailyGoalCount() async {
        let store = UserSettingsStore()
        store.dailyGoalCount = 3

        let words = (1...10).map { id in
            VaultWordItem(id: Int64(id), lemma: "word\(id)", pos: "n", definitionVi: "definition \(id)")
        }

        let vm = PersonalVaultViewModel(
            smartSelector: PrefixSmartSelector(),
            userSettingsStore: store,
            mockWords: words
        )

        // Without targetCount argument, must select exactly 3 words per dailyGoalCount
        let picks = vm.smartPickWords()
        #expect(picks.count == 3)
        #expect(vm.selectedWordIds.count == 3)
    }

    @Test("Generation tracking ignores stale out-of-order response")
    @MainActor
    func testGenerationTrackingIgnoresStaleResponse() async {
        let word1 = VaultWordItem(id: 1, lemma: "first", pos: "n.", definitionVi: "thứ nhất")
        let word2 = VaultWordItem(id: 2, lemma: "second", pos: "n.", definitionVi: "thứ hai")

        let slowStream = AsyncStream<Void>.makeStream()
        let mockUseCase = MockFetchPersonalVaultUseCase()

        var callCount = 0
        mockUseCase.onFetchSnapshot = { _, _, _ in
            callCount += 1
            if callCount == 1 {
                for await _ in slowStream.stream {
                    break
                }
                return PersonalVaultSnapshot(
                    metrics: PersonalVaultMetrics(totalWords: 1),
                    personalWords: [],
                    vaultWords: [word1]
                )
            } else {
                return PersonalVaultSnapshot(
                    metrics: PersonalVaultMetrics(totalWords: 1),
                    personalWords: [],
                    vaultWords: [word2]
                )
            }
        }

        let vm = PersonalVaultViewModel(fetchVaultUseCase: mockUseCase)

        // Launch Request 1 (not cancelled, pauses inside onFetchSnapshot)
        let task1 = Task { @MainActor in
            await vm.loadData()
        }

        // Allow task1 to start and wait on slowStream
        try? await Task.sleep(nanoseconds: 20_000_000)

        // Fire Request 2 (completes immediately with word2)
        await vm.loadData()

        #expect(vm.vaultWords.map(\.id) == [2])

        // Resume Request 1 and await completion
        slowStream.continuation.yield()
        _ = await task1.result

        // Stale response from Request 1 should be ignored by generation tracking
        #expect(vm.vaultWords.map(\.id) == [2])
    }

    @Test("Task cancellation prevents stale state assignment")
    @MainActor
    func testTaskCancellationPreventsStaleStateAssignment() async {
        let word = VaultWordItem(id: 99, lemma: "test", pos: "n.", definitionVi: "kiểm tra")
        let pauseStream = AsyncStream<Void>.makeStream()
        let mockUseCase = MockFetchPersonalVaultUseCase()

        mockUseCase.onFetchSnapshot = { _, _, _ in
            for await _ in pauseStream.stream {
                break
            }
            return PersonalVaultSnapshot(
                metrics: PersonalVaultMetrics(totalWords: 1),
                personalWords: [],
                vaultWords: [word]
            )
        }

        let vm = PersonalVaultViewModel(fetchVaultUseCase: mockUseCase)

        let task = Task { @MainActor in
            await vm.loadData()
        }

        try? await Task.sleep(nanoseconds: 20_000_000)
        task.cancel()
        pauseStream.continuation.yield()
        _ = await task.result

        #expect(vm.vaultWords.isEmpty)
    }
    @Test("Optimistic bookmark toggle updates in-memory state and metrics instantly before background persistence completes")
    @MainActor
    func testOptimisticBookmarkToggleUpdatesInstantlyBeforePersistenceResolves() async {
        let word = VaultWordItem(id: 10, lemma: "momentum", pos: "n.", definitionVi: "Đà phát triển", isBookmarked: false)
        let personalWord = PersonalWord(
            id: 10,
            lemma: "momentum",
            phonetic: "/məˈmentəm/",
            pos: "n.",
            cefrLevel: "B2",
            definitionVi: "Đà phát triển",
            definitionEn: "force or speed of movement",
            exampleEn: "Gain momentum",
            exampleVi: "Tạo đà",
            isBookmarked: false
        )

        let pauseStream = AsyncStream<Void>.makeStream()
        let mockUseCase = MockFetchPersonalVaultUseCase()
        mockUseCase.onFetchSnapshot = { _, _, _ in
            PersonalVaultSnapshot(
                metrics: PersonalVaultMetrics(totalWords: 1, bookmarkedCount: 0),
                personalWords: [personalWord],
                vaultWords: [word]
            )
        }

        let mockBookmarkUseCase = MockToggleBookmarkUseCase()
        mockBookmarkUseCase.onExecute = { _ in
            for await _ in pauseStream.stream {
                break
            }
            return true
        }

        let vm = PersonalVaultViewModel(
            fetchVaultUseCase: mockUseCase,
            toggleBookmarkUseCase: mockBookmarkUseCase
        )

        await vm.loadData()
        #expect(vm.vaultWords.first?.isBookmarked == false)
        #expect(vm.words.first?.isBookmarked == false)
        #expect(vm.metrics.bookmarkedCount == 0)

        // Launch bookmark toggle in background Task
        let toggleTask = Task { @MainActor in
            await vm.toggleBookmark(wordId: 10)
        }

        // Allow toggleBookmark to start executing up to the await point
        try? await Task.sleep(nanoseconds: 20_000_000)

        // Verify optimistic update happened before persistence resolved
        #expect(vm.vaultWords.first(where: { $0.id == 10 })?.isBookmarked == true)
        #expect(vm.words.first(where: { $0.id == 10 })?.isBookmarked == true)
        #expect(vm.metrics.bookmarkedCount == 1)

        // Let background persistence finish
        pauseStream.continuation.yield()
        _ = await toggleTask.result

        // Verify state remains consistent and no errors
        #expect(vm.vaultWords.first(where: { $0.id == 10 })?.isBookmarked == true)
        #expect(vm.words.first(where: { $0.id == 10 })?.isBookmarked == true)
        #expect(vm.metrics.bookmarkedCount == 1)
        #expect(vm.errorMessage == nil)
    }

    @Test("Bookmark toggle rolls back in-memory state and metrics when persistence fails")
    @MainActor
    func testBookmarkToggleRollbackOnError() async {
        let word1 = VaultWordItem(id: 1, lemma: "serene", pos: "adj.", definitionVi: "Thanh bình", isBookmarked: false)
        let personalWord1 = PersonalWord(
            id: 1,
            lemma: "serene",
            phonetic: "/səˈriːn/",
            pos: "adj.",
            cefrLevel: "C1",
            definitionVi: "Thanh bình",
            definitionEn: "calm, peaceful",
            exampleEn: "A serene lake",
            exampleVi: "Hồ thanh bình",
            isBookmarked: false
        )

        let mockUseCase = MockFetchPersonalVaultUseCase()
        mockUseCase.onFetchSnapshot = { _, _, _ in
            PersonalVaultSnapshot(
                metrics: PersonalVaultMetrics(totalWords: 1, bookmarkedCount: 0),
                personalWords: [personalWord1],
                vaultWords: [word1]
            )
        }

        struct DummyNetworkError: LocalizedError {
            var errorDescription: String? { "Persistence failed" }
        }

        let pauseStream = AsyncStream<Void>.makeStream()
        let mockBookmarkUseCase = MockToggleBookmarkUseCase()
        mockBookmarkUseCase.onExecute = { _ in
            for await _ in pauseStream.stream {
                break
            }
            throw DummyNetworkError()
        }

        let vm = PersonalVaultViewModel(
            fetchVaultUseCase: mockUseCase,
            toggleBookmarkUseCase: mockBookmarkUseCase
        )

        await vm.loadData()
        vm.selectWordForDetail(word1)
        #expect(vm.vaultWords.first?.isBookmarked == false)
        #expect(vm.words.first?.isBookmarked == false)
        #expect(vm.metrics.bookmarkedCount == 0)
        #expect(vm.selectedWordForDetail?.isBookmarked == false)

        // Launch bookmark toggle (false -> optimistically true -> persistence throws -> rollback to false)
        let toggleTask = Task { @MainActor in
            await vm.toggleBookmark(wordId: 1)
        }

        // Allow task to reach await persistence
        try? await Task.sleep(nanoseconds: 20_000_000)

        // Verify optimistic flip occurred before failure
        #expect(vm.vaultWords.first(where: { $0.id == 1 })?.isBookmarked == true)
        #expect(vm.words.first(where: { $0.id == 1 })?.isBookmarked == true)
        #expect(vm.metrics.bookmarkedCount == 1)
        #expect(vm.selectedWordForDetail?.isBookmarked == true)

        // Unblock stream and allow failure to throw
        pauseStream.continuation.yield()
        _ = await toggleTask.result

        // Verify complete rollback
        #expect(vm.vaultWords.first(where: { $0.id == 1 })?.isBookmarked == false)
        #expect(vm.words.first(where: { $0.id == 1 })?.isBookmarked == false)
        #expect(vm.metrics.bookmarkedCount == 0)
        #expect(vm.selectedWordForDetail?.isBookmarked == false)
        #expect(vm.errorMessage == "Persistence failed")
    }

    @Test("Bookmark un-toggle rolls back in-memory state and metrics when persistence fails")
    @MainActor
    func testBookmarkUntoggleRollbackOnError() async {
        let word2 = VaultWordItem(id: 2, lemma: "lucid", pos: "adj.", definitionVi: "Rõ ràng", isBookmarked: true)
        let personalWord2 = PersonalWord(
            id: 2,
            lemma: "lucid",
            phonetic: "/ˈluːsɪd/",
            pos: "adj.",
            cefrLevel: "B2",
            definitionVi: "Rõ ràng",
            definitionEn: "expressed clearly",
            exampleEn: "A lucid explanation",
            exampleVi: "Lời giải thích rõ ràng",
            isBookmarked: true
        )

        let mockUseCase = MockFetchPersonalVaultUseCase()
        mockUseCase.onFetchSnapshot = { _, _, _ in
            PersonalVaultSnapshot(
                metrics: PersonalVaultMetrics(totalWords: 1, bookmarkedCount: 1),
                personalWords: [personalWord2],
                vaultWords: [word2]
            )
        }

        struct DummyNetworkError: LocalizedError {
            var errorDescription: String? { "Persistence failed" }
        }

        let pauseStream = AsyncStream<Void>.makeStream()
        let mockBookmarkUseCase = MockToggleBookmarkUseCase()
        mockBookmarkUseCase.onExecute = { _ in
            for await _ in pauseStream.stream {
                break
            }
            throw DummyNetworkError()
        }

        let vm = PersonalVaultViewModel(
            fetchVaultUseCase: mockUseCase,
            toggleBookmarkUseCase: mockBookmarkUseCase
        )

        await vm.loadData()
        vm.selectWordForDetail(word2)
        #expect(vm.vaultWords.first?.isBookmarked == true)
        #expect(vm.words.first?.isBookmarked == true)
        #expect(vm.metrics.bookmarkedCount == 1)
        #expect(vm.selectedWordForDetail?.isBookmarked == true)

        // Launch bookmark un-toggle (true -> optimistically false -> persistence throws -> rollback to true)
        let toggleTask = Task { @MainActor in
            await vm.toggleBookmark(wordId: 2)
        }

        // Allow task to reach await persistence
        try? await Task.sleep(nanoseconds: 20_000_000)

        // Verify optimistic flip occurred before failure
        #expect(vm.vaultWords.first(where: { $0.id == 2 })?.isBookmarked == false)
        #expect(vm.words.first(where: { $0.id == 2 })?.isBookmarked == false)
        #expect(vm.metrics.bookmarkedCount == 0)
        #expect(vm.selectedWordForDetail?.isBookmarked == false)

        // Unblock stream and allow failure to throw
        pauseStream.continuation.yield()
        _ = await toggleTask.result

        // Verify complete rollback
        #expect(vm.vaultWords.first(where: { $0.id == 2 })?.isBookmarked == true)
        #expect(vm.words.first(where: { $0.id == 2 })?.isBookmarked == true)
        #expect(vm.metrics.bookmarkedCount == 1)
        #expect(vm.selectedWordForDetail?.isBookmarked == true)
        #expect(vm.errorMessage == "Persistence failed")
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
    var onFetchSnapshot: ((PersonalVaultFilter, VaultTabFilter, String?) async -> PersonalVaultSnapshot?)?

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

    func fetchVaultSnapshot(
        personalFilter: PersonalVaultFilter,
        vaultFilter: VaultTabFilter,
        searchQuery: String?
    ) async throws -> PersonalVaultSnapshot {
        if let onFetchSnapshot, let custom = await onFetchSnapshot(personalFilter, vaultFilter, searchQuery) {
            return custom
        }
        let execResult = try await execute(filter: personalFilter, searchQuery: searchQuery)
        let words = try await fetchVaultWords(filter: vaultFilter, searchQuery: searchQuery)
        return PersonalVaultSnapshot(
            metrics: execResult.metrics,
            personalWords: execResult.words,
            vaultWords: words
        )
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
    private let mockUseCase: MockFetchPersonalVaultUseCase?
    var executedWordIds: [Int64] = []
    var errorToThrow: (any Error)?
    var onExecute: ((Int64) async throws -> Bool)?

    init(mockUseCase: MockFetchPersonalVaultUseCase? = nil) {
        self.mockUseCase = mockUseCase
    }

    func execute(wordId: Int64) async throws -> Bool {
        executedWordIds.append(wordId)
        if let onExecute {
            return try await onExecute(wordId)
        }
        if let errorToThrow {
            throw errorToThrow
        }
        mockUseCase?.toggleBookmark(wordId: wordId)
        return true
    }
}
#endif
