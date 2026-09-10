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
    public var vaultTabFilter: VaultTabFilter = .notMastered
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

    private var currentRequestId: UInt64 = 0
    private var isRunningSearchTask = false
    private var searchTask: Task<Void, Never>?

    private let fetchVaultUseCase: FetchPersonalVaultUseCaseProtocol?
    private let toggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol?
    private let smartSelector: SmartVaultWordSelectorProtocol
    public let userSettingsStore: UserSettingsStore?
    private var pendingBookmarkMutations: [Int64: (isBookmarked: Bool, timestamp: Date)] = [:]

    public init(
        fetchVaultUseCase: FetchPersonalVaultUseCaseProtocol? = nil,
        toggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        smartSelector: SmartVaultWordSelectorProtocol = SmartVaultWordSelector(),
        userSettingsStore: UserSettingsStore? = nil,
        mockWords: [VaultWordItem] = []
    ) {
        self.fetchVaultUseCase = fetchVaultUseCase
        self.toggleBookmarkUseCase = toggleBookmarkUseCase
        self.ttsService = ttsService
        self.smartSelector = smartSelector
        self.userSettingsStore = userSettingsStore
        self.vaultWords = mockWords
    }

    public var selectedWords: [VaultWordItem] {
        vaultWords.filter { selectedWordIds.contains($0.id) }
    }

    public func loadData() async {
        guard !Task.isCancelled else { return }
        if !isRunningSearchTask {
            searchTask?.cancel()
            searchTask = nil
        }
        guard !Task.isCancelled else { return }
        currentRequestId &+= 1
        let requestId = currentRequestId
        let loadStartTime = Date()
        isLoading = true
        errorMessage = nil

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveQuery = query.isEmpty ? nil : query
        do {
            if let fetchVaultUseCase {
                let snapshot = try await fetchVaultUseCase.fetchVaultSnapshot(
                    personalFilter: selectedFilter,
                    vaultFilter: vaultTabFilter,
                    searchQuery: effectiveQuery
                )
                guard currentRequestId == requestId && !Task.isCancelled else { return }

                var resolvedVaultWords = snapshot.vaultWords
                var resolvedPersonalWords = snapshot.personalWords
                var bookmarkedDelta = 0

                let recentMutations = pendingBookmarkMutations.filter { $0.value.timestamp >= loadStartTime }
                for (wordId, mutation) in recentMutations {
                    if let idx = resolvedVaultWords.firstIndex(where: { $0.id == wordId }) {
                        let old = resolvedVaultWords[idx].isBookmarked
                        if old != mutation.isBookmarked {
                            resolvedVaultWords[idx] = updatingBookmarkState(for: resolvedVaultWords[idx], isBookmarked: mutation.isBookmarked)
                            bookmarkedDelta += mutation.isBookmarked ? 1 : -1
                        }
                    }
                    if let pIdx = resolvedPersonalWords.firstIndex(where: { $0.id == wordId }) {
                        resolvedPersonalWords[pIdx].isBookmarked = mutation.isBookmarked
                    }
                    if let current = selectedWordForDetail, current.id == wordId {
                        selectedWordForDetail = updatingBookmarkState(for: current, isBookmarked: mutation.isBookmarked)
                    }
                }

                let newBookmarkedCount = max(0, snapshot.metrics.bookmarkedCount + bookmarkedDelta)
                let resolvedMetrics = PersonalVaultMetrics(
                    totalWords: snapshot.metrics.totalWords,
                    needsReviewCount: snapshot.metrics.needsReviewCount,
                    masteredCount: snapshot.metrics.masteredCount,
                    bookmarkedCount: newBookmarkedCount,
                    unmasteredCount: snapshot.metrics.unmasteredCount
                )

                words = resolvedPersonalWords
                metrics = resolvedMetrics
                vaultWords = resolvedVaultWords
            }
        } catch {
            guard currentRequestId == requestId && !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
        guard currentRequestId == requestId && !Task.isCancelled else { return }
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
    public func smartPickWords(targetCount: Int? = nil) -> [VaultWordItem] {
        let effectiveTarget = targetCount ?? userSettingsStore?.dailyGoalCount ?? 10
        let pool: [VaultWordItem]
        switch vaultTabFilter {
        case .notMastered:
            pool = vaultWords.filter { !$0.isMastered }
        case .mastered:
            pool = vaultWords.filter(\.isMastered)
        case .bookmarked:
            pool = vaultWords.filter(\.isBookmarked)
        }
        let picked = smartSelector.selectWords(from: pool, targetCount: effectiveTarget)
        selectedWordIds = Set(picked.map(\.id))
        return picked
    }

    public func setVaultFilter(_ filter: VaultTabFilter) {
        vaultTabFilter = filter
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard !Task.isCancelled else { return }
            guard let self else { return }
            self.isRunningSearchTask = true
            defer { self.isRunningSearchTask = false }
            await self.loadData()
        }
    }

    public func setFilter(_ filter: PersonalVaultFilter) {
        selectedFilter = filter
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard !Task.isCancelled else { return }
            guard let self else { return }
            self.isRunningSearchTask = true
            defer { self.isRunningSearchTask = false }
            await self.loadData()
        }
    }

    public func setSearchQuery(_ query: String) {
        searchQuery = query
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard !Task.isCancelled else { return }
            guard let self else { return }
            self.isRunningSearchTask = true
            defer { self.isRunningSearchTask = false }
            await self.loadData()
        }
    }

    public func toggleBookmark(wordId: Int64) async {
        let vaultIndex = vaultWords.firstIndex(where: { $0.id == wordId })
        let personalIndex = words.firstIndex(where: { $0.id == wordId })

        let previousState: Bool
        if let vaultIndex {
            previousState = vaultWords[vaultIndex].isBookmarked
        } else if let personalIndex {
            previousState = words[personalIndex].isBookmarked
        } else if let current = selectedWordForDetail, current.id == wordId {
            previousState = current.isBookmarked
        } else {
            if let toggleBookmarkUseCase {
                do {
                    _ = try await toggleBookmarkUseCase.execute(wordId: wordId)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            return
        }

        let newState = !previousState

        // 1. Optimistic in-memory updates
        pendingBookmarkMutations[wordId] = (newState, Date())
        applyBookmarkState(newState, for: wordId)
        let optimisticCount = newState ? metrics.bookmarkedCount + 1 : max(0, metrics.bookmarkedCount - 1)
        metrics = updatingBookmarkedCount(to: optimisticCount)

        // 2. Background persistence
        if let toggleBookmarkUseCase {
            do {
                _ = try await toggleBookmarkUseCase.execute(wordId: wordId)
            } catch {
                // 3. Rollback on error
                pendingBookmarkMutations[wordId] = (previousState, Date())
                applyBookmarkState(previousState, for: wordId)
                let revertedCount = previousState ? metrics.bookmarkedCount + 1 : max(0, metrics.bookmarkedCount - 1)
                metrics = updatingBookmarkedCount(to: revertedCount)
                errorMessage = error.localizedDescription
            }
        }
    }

    private func applyBookmarkState(_ isBookmarked: Bool, for wordId: Int64) {
        if let idx = vaultWords.firstIndex(where: { $0.id == wordId }) {
            vaultWords[idx] = updatingBookmarkState(for: vaultWords[idx], isBookmarked: isBookmarked)
        }
        if let pIdx = words.firstIndex(where: { $0.id == wordId }) {
            words[pIdx].isBookmarked = isBookmarked
        }
        if let current = selectedWordForDetail, current.id == wordId {
            selectedWordForDetail = updatingBookmarkState(for: current, isBookmarked: isBookmarked)
        }
    }

    private func updatingBookmarkState(for item: VaultWordItem, isBookmarked: Bool) -> VaultWordItem {
        VaultWordItem(
            id: item.id,
            lemma: item.lemma,
            pos: item.pos,
            phonetic: item.phonetic,
            definitionVi: item.definitionVi,
            exampleSentenceEn: item.exampleSentenceEn,
            exampleSentenceVi: item.exampleSentenceVi,
            cefrLevel: item.cefrLevel,
            isMastered: item.isMastered,
            isBookmarked: isBookmarked,
            correctStreak: item.correctStreak,
            practicedModes: item.practicedModes,
            lastPracticedAt: item.lastPracticedAt,
            modeStats: item.modeStats
        )
    }

    private func updatingBookmarkedCount(to count: Int) -> PersonalVaultMetrics {
        PersonalVaultMetrics(
            totalWords: metrics.totalWords,
            needsReviewCount: metrics.needsReviewCount,
            masteredCount: metrics.masteredCount,
            bookmarkedCount: count,
            unmasteredCount: metrics.unmasteredCount
        )
    }

    public func playAudio(for word: PersonalWord) {
        ttsService?.speak(text: word.lemma)
    }

    public func playAudio(for word: VaultWordItem) {
        ttsService?.speak(text: word.lemma)
    }
}
