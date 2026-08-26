import CraftUIKit
import Foundation

/// Pure Swift mapper that transforms topic deck DTOs and user progress into CraftUIKit `LessonSection` models with linear progression.
public struct LearningPathDataMapper: Sendable {

    /// Maps topic decks, subtopic stages, words, and user progress into learning path sections.
    /// - Parameters:
    ///   - decks: Topic deck DTOs representing the top-level learning units.
    ///   - stages: Subtopic stage DTOs representing individual lesson nodes.
    ///   - words: Vocabulary word DTOs grouped into stages.
    ///   - progressList: Persisted user progress records for stages and checkpoints.
    /// - Returns: An array of configured `LessonSection` models ready for presentation.
    public static func map(
        decks: [TopicDeckDTO],
        stages: [SubTopicStageDTO],
        words: [TopicWordDTO],
        progressList: [UserStageProgress]
    ) -> [LessonSection] {
        guard !decks.isEmpty else { return [] }

        // 1. Build lookup dictionaries
        let progressMap = Dictionary(progressList.map { ($0.stageId, $0) }, uniquingKeysWith: { first, _ in first })
        let wordsByStage = Dictionary(grouping: words, by: \.stageId)
        let stagesByDeck = Dictionary(grouping: stages, by: \.deckId)

        // 2. Sort decks by sortOrder
        let sortedDecks = decks.sorted { $0.sortOrder < $1.sortOrder }

        var hasFoundActive = false
        var sections: [LessonSection] = []

        for (deckIndex, deck) in sortedDecks.enumerated() {
            let deckStages = (stagesByDeck[deck.id] ?? []).sorted { $0.sortOrder < $1.sortOrder }

            var sectionNodes: [LessonNodeModel] = []

            // Map standard lesson nodes
            for stage in deckStages {
                let stageWords = wordsByStage[stage.id] ?? []
                let wordCount = stageWords.count
                let estimatedMinutes = max(1, Int(ceil(Double(wordCount) * 0.3)))
                let progress = progressMap[stage.id]

                let state: LessonNodeState
                let stars: Int?
                let nodeProgress: Double?

                if let progress = progress, progress.isCompleted {
                    state = .completed
                    stars = calculateStars(from: progress.score)
                    nodeProgress = nil
                } else if !hasFoundActive {
                    if let progress = progress, progress.progressFraction > 0.0 {
                        state = .inProgress
                        nodeProgress = progress.progressFraction
                    } else {
                        state = .active
                        nodeProgress = nil
                    }
                    stars = nil
                    hasFoundActive = true
                } else {
                    state = .locked
                    stars = nil
                    nodeProgress = nil
                }

                let node = LessonNodeModel(
                    id: stage.id,
                    title: stage.title,
                    subtitle: AppStrings.Home.wordsDuration(words: wordCount, minutes: estimatedMinutes),
                    iconName: stage.iconName.isEmpty ? "book.fill" : stage.iconName,
                    state: state,
                    kind: .standard,
                    progress: nodeProgress,
                    xpReward: 25,
                    estimatedMinutes: estimatedMinutes,
                    stars: stars,
                    badgeCount: nil,
                    badgeText: nil,
                    objectives: [
                        AppStrings.Home.objective1(words: wordCount),
                        AppStrings.Home.objective2Text,
                        AppStrings.Home.objective3Text
                    ],
                    objectiveKeys: [
                        "app.home.node.objective_1_format",
                        "app.home.node.objective_2",
                        "app.home.node.objective_3"
                    ]
                )
                sectionNodes.append(node)
            }

            // Append 1 checkpoint exam node per deck
            let deckWordCount = deckStages.reduce(0) { total, stage in
                total + (wordsByStage[stage.id]?.count ?? 0)
            }
            let checkpointEstimatedMinutes = max(3, Int(ceil(Double(deckWordCount) * 0.2)))
            let checkpointId = "checkpoint_\(deck.id)"
            let checkpointProgress = progressMap[checkpointId]

            let allStandardCompleted = sectionNodes.allSatisfy { $0.state == .completed }

            let checkpointState: LessonNodeState
            let checkpointStars: Int?
            let checkpointNodeProgress: Double?

            if let checkpointProgress = checkpointProgress, checkpointProgress.isCompleted {
                checkpointState = .completed
                checkpointStars = calculateStars(from: checkpointProgress.score)
                checkpointNodeProgress = nil
            } else if allStandardCompleted && !hasFoundActive {
                if let checkpointProgress = checkpointProgress, checkpointProgress.progressFraction > 0.0 {
                    checkpointState = .inProgress
                    checkpointNodeProgress = checkpointProgress.progressFraction
                } else {
                    checkpointState = .active
                    checkpointNodeProgress = nil
                }
                checkpointStars = nil
                hasFoundActive = true
            } else {
                checkpointState = .locked
                checkpointStars = nil
                checkpointNodeProgress = nil
            }

            let checkpointNode = LessonNodeModel(
                id: checkpointId,
                title: AppStrings.Home.checkpointTitleText,
                subtitle: AppStrings.Home.checkpointSubtitleText,
                iconName: "crown.fill",
                state: checkpointState,
                kind: .checkpoint,
                progress: checkpointNodeProgress,
                xpReward: 80,
                estimatedMinutes: checkpointEstimatedMinutes,
                stars: checkpointStars,
                badgeCount: nil,
                badgeText: nil,
                objectives: [
                    AppStrings.Home.checkpointObjective1(words: deckWordCount),
                    AppStrings.Home.checkpointObjective2Text
                ],
                objectiveKeys: [
                    "app.home.node.checkpoint_objective_1_format",
                    "app.home.node.checkpoint_objective_2"
                ]
            )
            sectionNodes.append(checkpointNode)

            // Compute section progression metrics
            let completedCount = sectionNodes.filter { $0.state == .completed }.count
            let totalCount = sectionNodes.count
            let progressText = "\(completedCount)/\(totalCount)"
            let progressValue = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0

            let section = LessonSection(
                id: deck.id,
                title: AppStrings.Home.unitTitle(number: deckIndex + 1, title: deck.title),
                subtitle: deck.cefrLevel,
                level: deck.cefrLevel,
                progressText: progressText,
                progressValue: progressValue,
                bannerIcon: deck.iconName,
                nodes: sectionNodes,
                winding: .standard,
                connectorStyle: .dashed,
                rowPattern: .standard
            )
            sections.append(section)
        }

        return sections
    }

    private static func calculateStars(from score: Int) -> Int {
        guard score > 0 else { return 3 }
        if score <= 3 {
            return min(3, max(1, score))
        }
        if score >= 95 {
            return 3
        } else if score >= 80 {
            return 2
        } else {
            return 1
        }
    }
}
