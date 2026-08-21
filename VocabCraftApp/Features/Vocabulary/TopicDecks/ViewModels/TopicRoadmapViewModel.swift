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
    public var selectedStage: SubTopicStage?

    private let fetchDeckRoadmapUseCase: FetchDeckRoadmapUseCaseProtocol

    public init(
        deckId: String,
        fetchDeckRoadmapUseCase: FetchDeckRoadmapUseCaseProtocol
    ) {
        self.deckId = deckId
        self.fetchDeckRoadmapUseCase = fetchDeckRoadmapUseCase
    }

    public var activeStage: SubTopicStage? {
        stages.first { $0.state == .active }
    }

    public var totalStagesCount: Int {
        stages.count
    }

    public var completedStagesCount: Int {
        stages.filter { $0.state == .completed }.count
    }

    public var progressPercentage: Double {
        guard !stages.isEmpty else { return 0.0 }
        return Double(completedStagesCount) / Double(stages.count)
    }

    public var totalWordsCount: Int {
        stages.reduce(0) { $0 + $1.words.count }
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

    public func selectStage(_ stage: SubTopicStage?) {
        self.selectedStage = stage
    }

    public func clearSelection() {
        self.selectedStage = nil
    }
}
