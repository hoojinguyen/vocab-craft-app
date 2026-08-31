import Foundation
import Observation

/// ViewModel managing the user's personal vault items, categorized filters, search, and bookmark actions.
@MainActor
@Observable
public final class PersonalVaultViewModel {
    public private(set) var words: [PersonalWord] = []
    public private(set) var vaultWords: [VaultWordItem] = []
    public private(set) var metrics: PersonalVaultMetrics = PersonalVaultMetrics()
    public private(set) var selectedFilter: PersonalVaultFilter = .all
    public private(set) var vaultTabFilter: VaultTabFilter = .notMastered
    public private(set) var selectedWordIds: Set<Int64> = []
    public private(set) var searchQuery: String = ""
    public private(set) var isLoading: Bool = false
    public private(set) var errorMessage: String?

    public var selectedWordForDetail: VaultWordItem?
    public var isPresentingReviewSession: Bool = false
    public private(set) var reviewWords: [VaultWordItem] = []

    public var isSpeakingAudio: Bool {
        ttsService?.isSpeaking ?? false
    }

    private let fetchVaultUseCase: FetchPersonalVaultUseCaseProtocol?
    private let toggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol?
    private let smartSelector: SmartVaultWordSelectorProtocol

    public init(
        fetchVaultUseCase: FetchPersonalVaultUseCaseProtocol? = nil,
        toggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        smartSelector: SmartVaultWordSelectorProtocol = SmartVaultWordSelector(),
        mockWords: [VaultWordItem] = []
    ) {
        self.fetchVaultUseCase = fetchVaultUseCase
        self.toggleBookmarkUseCase = toggleBookmarkUseCase
        self.ttsService = ttsService
        self.smartSelector = smartSelector
        self.vaultWords = mockWords
    }

    public var selectedWords: [VaultWordItem] {
        vaultWords.filter { selectedWordIds.contains($0.id) }
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            let effectiveQuery = query.isEmpty ? nil : query

            if let fetchVaultUseCase {
                let result = try await fetchVaultUseCase.execute(
                    filter: selectedFilter,
                    searchQuery: effectiveQuery
                )
                words = result.words
                metrics = result.metrics

                vaultWords = try await fetchVaultUseCase.fetchVaultWords(
                    filter: vaultTabFilter,
                    searchQuery: effectiveQuery
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func selectWordForDetail(_ word: VaultWordItem?) {
        selectedWordForDetail = word
    }

    public func dismissWordDetail() {
        selectedWordForDetail = nil
    }

    @discardableResult
    public func prepareReviewWords() -> [VaultWordItem] {
        let targetWords: [VaultWordItem]
        switch vaultTabFilter {
        case .notMastered:
            targetWords = vaultWords
                .filter { !$0.isMastered }
                .sorted { $0.correctStreak < $1.correctStreak }
        case .mastered:
            targetWords = vaultWords
                .filter(\.isMastered)
        case .bookmarked:
            targetWords = vaultWords
                .filter(\.isBookmarked)
        }
        let selected = Array(targetWords.prefix(15))
        self.reviewWords = selected
        return selected
    }

    public func toggleWordSelection(id: Int64) {
        if selectedWordIds.contains(id) {
            selectedWordIds.remove(id)
        } else {
            selectedWordIds.insert(id)
        }
    }

    public func selectAll() {
        selectedWordIds = Set(vaultWords.map(\.id))
    }

    public func deselectAll() {
        selectedWordIds.removeAll()
    }

    @discardableResult
    public func smartPickWords(targetCount: Int = 10) -> [VaultWordItem] {
        let picked = smartSelector.selectWords(from: vaultWords, targetCount: targetCount)
        selectedWordIds = Set(picked.map(\.id))
        return picked
    }

    public func setVaultFilter(_ filter: VaultTabFilter) {
        vaultTabFilter = filter
        Task { await loadData() }
    }

    public func setFilter(_ filter: PersonalVaultFilter) {
        selectedFilter = filter
        Task { await loadData() }
    }

    public func setSearchQuery(_ query: String) {
        searchQuery = query
        Task { await loadData() }
    }

    public func toggleBookmark(wordId: Int64) async {
        var didSucceed = false
        if let toggleBookmarkUseCase {
            do {
                _ = try await toggleBookmarkUseCase.execute(wordId: wordId)
                await loadData()
                didSucceed = true
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            // In-memory fallback if toggleBookmarkUseCase is not injected
            if let idx = vaultWords.firstIndex(where: { $0.id == wordId }) {
                let item = vaultWords[idx]
                let updated = VaultWordItem(
                    id: item.id,
                    lemma: item.lemma,
                    pos: item.pos,
                    phonetic: item.phonetic,
                    definitionVi: item.definitionVi,
                    exampleSentenceEn: item.exampleSentenceEn,
                    exampleSentenceVi: item.exampleSentenceVi,
                    cefrLevel: item.cefrLevel,
                    isMastered: item.isMastered,
                    isBookmarked: !item.isBookmarked,
                    correctStreak: item.correctStreak,
                    practicedModes: item.practicedModes,
                    lastPracticedAt: item.lastPracticedAt
                )
                vaultWords[idx] = updated
                didSucceed = true
            }
        }

        if didSucceed, let current = selectedWordForDetail, current.id == wordId {
            selectedWordForDetail = VaultWordItem(
                id: current.id,
                lemma: current.lemma,
                pos: current.pos,
                phonetic: current.phonetic,
                definitionVi: current.definitionVi,
                exampleSentenceEn: current.exampleSentenceEn,
                exampleSentenceVi: current.exampleSentenceVi,
                cefrLevel: current.cefrLevel,
                isMastered: current.isMastered,
                isBookmarked: !current.isBookmarked,
                correctStreak: current.correctStreak,
                practicedModes: current.practicedModes,
                lastPracticedAt: current.lastPracticedAt
            )
        }
    }

    public func playAudio(for word: PersonalWord) {
        ttsService?.speak(text: word.lemma)
    }

    public func playAudio(for word: VaultWordItem) {
        ttsService?.speak(text: word.lemma)
    }
}
