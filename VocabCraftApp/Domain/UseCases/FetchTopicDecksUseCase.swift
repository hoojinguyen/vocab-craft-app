import Foundation

/// Protocol for fetching topic decks with word counts and calculated completion percentages.
public protocol FetchTopicDecksUseCaseProtocol: Sendable {
    func execute() async throws -> [TopicDeck]
}

/// Fetches topic decks along with their aggregated word counts and user stage progress.
public final class FetchTopicDecksUseCase: FetchTopicDecksUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol
    private let stageRepo: StageProgressRepositoryProtocol

    public init(
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol
    ) {
        self.dataSource = dataSource
        self.stageRepo = stageRepo
    }

    public func execute() async throws -> [TopicDeck] {
        let deckDTOs = try await dataSource.fetchTopicDecks()
        var topicDecks: [TopicDeck] = []

        for deck in deckDTOs {
            let stages = try await dataSource.fetchSubTopicStages(deckId: deck.id)
            var totalWords = 0
            for stage in stages {
                let words = try await dataSource.fetchWordsForStage(stageId: stage.id)
                totalWords += words.count
            }

            let completedStageIds = try await stageRepo.fetchCompletedStageIds(deckId: deck.id)
            let completionPercentage: Double
            if stages.isEmpty {
                completionPercentage = 0.0
            } else {
                completionPercentage = Double(completedStageIds.count) / Double(stages.count)
            }

            let topicDeck = TopicDeck(
                id: deck.id,
                title: deck.title,
                wordCount: totalWords,
                completionPercentage: completionPercentage,
                badgeColorHex: deck.badgeColorHex,
                iconName: deck.iconName
            )
            topicDecks.append(topicDeck)
        }

        return topicDecks
    }
}
