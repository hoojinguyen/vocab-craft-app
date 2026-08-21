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

    private let fetchVaultUseCase: FetchPersonalVaultUseCaseProtocol?
    private let toggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol?

    public init(
        fetchVaultUseCase: FetchPersonalVaultUseCaseProtocol? = nil,
        toggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        mockWords: [VaultWordItem] = []
    ) {
        self.fetchVaultUseCase = fetchVaultUseCase
        self.toggleBookmarkUseCase = toggleBookmarkUseCase
        self.ttsService = ttsService
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
        guard let toggleBookmarkUseCase else { return }
        do {
            _ = try await toggleBookmarkUseCase.execute(wordId: wordId)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func playAudio(for word: PersonalWord) {
        ttsService?.speak(text: word.lemma)
    }

    public func playAudio(for word: VaultWordItem) {
        ttsService?.speak(text: word.lemma)
    }
}
