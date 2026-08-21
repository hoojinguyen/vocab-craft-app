import Foundation
import Observation

/// ViewModel managing the sequential subtopic stages and roadmap state for a specific topic deck.
@MainActor
@Observable
public final class TopicRoadmapViewModel {
    public let deckId: String
    public private(set) var stages: [SubTopicStage] = []
    public private(set) var isLoading: Bool = false
    public private(set) var errorMessage: String?

    private let fetchDeckRoadmapUseCase: FetchDeckRoadmapUseCaseProtocol

    public init(
        deckId: String,
        fetchDeckRoadmapUseCase: FetchDeckRoadmapUseCaseProtocol
    ) {
        self.deckId = deckId
        self.fetchDeckRoadmapUseCase = fetchDeckRoadmapUseCase
    }

    public func loadRoadmap() async {
        isLoading = true
        errorMessage = nil
        do {
            stages = try await fetchDeckRoadmapUseCase.execute(deckId: deckId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
