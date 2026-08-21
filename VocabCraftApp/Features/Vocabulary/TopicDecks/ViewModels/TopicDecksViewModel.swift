import Foundation
import Observation

/// ViewModel managing the list of curated vocabulary topic decks and aggregate progress.
@MainActor
@Observable
public final class TopicDecksViewModel {
    public private(set) var decks: [TopicDeck] = []
    public private(set) var isLoading: Bool = false
    public private(set) var errorMessage: String?

    private let fetchTopicDecksUseCase: FetchTopicDecksUseCaseProtocol

    public init(fetchTopicDecksUseCase: FetchTopicDecksUseCaseProtocol) {
        self.fetchTopicDecksUseCase = fetchTopicDecksUseCase
    }

    public func loadDecks() async {
        isLoading = true
        errorMessage = nil
        do {
            decks = try await fetchTopicDecksUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
