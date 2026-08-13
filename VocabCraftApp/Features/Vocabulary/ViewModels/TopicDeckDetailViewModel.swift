import SwiftUI

@MainActor
@Observable
public final class TopicDeckDetailViewModel {
    public var nodes: [SubTopicNode] = []
    public var isLoading: Bool = false

    private let deckId: String
    private let repository: VocabularyRepositoryProtocol

    public init(deckId: String, repository: VocabularyRepositoryProtocol) {
        self.deckId = deckId
        self.repository = repository
    }

    public func loadDeck() async {
        isLoading = true
        defer { isLoading = false }
        do {
            self.nodes = try await repository.fetchTopicDeckDetails(deckId: deckId)
        } catch {
            print("Failed to load topic deck details for deck \(deckId): \(error)")
        }
    }
}
