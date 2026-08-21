import Foundation
import Observation

/// ViewModel managing the user's personal vault items, categorized filters, search, and bookmark actions.
@MainActor
@Observable
public final class PersonalVaultViewModel {
    public private(set) var words: [PersonalWord] = []
    public private(set) var metrics: PersonalVaultMetrics = PersonalVaultMetrics()
    public private(set) var selectedFilter: PersonalVaultFilter = .all
    public private(set) var searchQuery: String = ""
    public private(set) var isLoading: Bool = false
    public private(set) var errorMessage: String?

    private let fetchVaultUseCase: FetchPersonalVaultUseCaseProtocol
    private let toggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol
    private let ttsService: TextToSpeechProtocol?

    public init(
        fetchVaultUseCase: FetchPersonalVaultUseCaseProtocol,
        toggleBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol,
        ttsService: TextToSpeechProtocol? = nil
    ) {
        self.fetchVaultUseCase = fetchVaultUseCase
        self.toggleBookmarkUseCase = toggleBookmarkUseCase
        self.ttsService = ttsService
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await fetchVaultUseCase.execute(
                filter: selectedFilter,
                searchQuery: searchQuery.isEmpty ? nil : searchQuery
            )
            words = result.words
            metrics = result.metrics
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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
}
