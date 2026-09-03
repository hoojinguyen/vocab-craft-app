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

        let progressMap = Dictionary(progressList.map { ($0.stageId, $0) }, uniquingKeysWith: { first, _ in first })
        let wordsByStage = Dictionary(grouping: words, by: \.stageId)
        let stagesByDeck = Dictionary(grouping: stages, by: \.deckId)
        let sortedDecks = decks.sorted { $0.sortOrder < $1.sortOrder }

        var hasFoundActive = false
        var sections: [LessonSection] = []

        for (deckIndex, deck) in sortedDecks.enumerated() {
            let deckStages = (stagesByDeck[deck.id] ?? []).sorted { $0.sortOrder < $1.sortOrder }
            var sectionNodes: [LessonNodeModel] = []

            for stage in deckStages {
                let stageWords = wordsByStage[stage.id] ?? []
                let progress = progressMap[stage.id]
                let node = buildStandardNode(stage: stage, words: stageWords, progress: progress, hasFoundActive: &hasFoundActive)
                sectionNodes.append(node)
            }

            let deckWordCount = deckStages.reduce(0) { total, stage in
                total + (wordsByStage[stage.id]?.count ?? 0)
            }
            let checkpointNode = buildCheckpointNode(
                deck: deck,
                deckWordCount: deckWordCount,
                sectionNodes: sectionNodes,
                progressMap: progressMap,
                hasFoundActive: &hasFoundActive
            )
            sectionNodes.append(checkpointNode)

            let treasureNode = buildTreasureNode(
                deck: deck,
                progressMap: progressMap,
                hasFoundActive: &hasFoundActive
            )
            sectionNodes.append(treasureNode)

            // Promote immediate next locked node after active/inProgress to upcoming for curiosity gap
            if let activeIdx = sectionNodes.firstIndex(where: { $0.state == .active || $0.state == .inProgress || $0.state == .bonus }),
               activeIdx + 1 < sectionNodes.count,
               sectionNodes[activeIdx + 1].state == .locked {
                sectionNodes[activeIdx + 1] = withState(sectionNodes[activeIdx + 1], state: .upcoming)
            }

            let section = buildSection(deck: deck, deckIndex: deckIndex, nodes: sectionNodes)
            sections.append(section)
        }

        return sections
    }

    private static func withState(_ node: LessonNodeModel, state: LessonNodeState) -> LessonNodeModel {
        LessonNodeModel(
            id: node.id,
            title: node.title,
            subtitle: node.subtitle,
            iconName: node.iconName,
            state: state,
            kind: node.kind,
            progress: node.progress,
            xpReward: node.xpReward,
            estimatedMinutes: node.estimatedMinutes,
            stars: node.stars,
            badgeCount: node.badgeCount,
            badgeText: node.badgeText,
            objectives: node.objectives,
            objectiveKeys: node.objectiveKeys
        )
    }

    private static func buildStandardNode(
        stage: SubTopicStageDTO,
        words: [TopicWordDTO],
        progress: UserStageProgress?,
        hasFoundActive: inout Bool
    ) -> LessonNodeModel {
        let wordCount = words.count
        let estimatedMinutes = LessonEconomyPolicy.estimatedMinutes(wordCount: wordCount)

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

        let previewSubtitle: String = {
            if words.isEmpty { return AppStrings.Home.wordsDuration(words: wordCount, minutes: estimatedMinutes) }
            let preview = words.prefix(2).map(\.lemma).joined(separator: " • ")
            guard !preview.isEmpty else { return AppStrings.Home.wordsDuration(words: wordCount, minutes: estimatedMinutes) }
            // Use CraftUIKit localization for duration units
            let minutesText = CraftLocalized.format("craft.common.unit.minutes_format", estimatedMinutes)
            return "\(preview) • \(minutesText)"
        }()

        return LessonNodeModel(
            id: stage.id,
            title: cleanStageTitle(stage.title),
            subtitle: previewSubtitle,
            iconName: stage.iconName.isEmpty ? "book.fill" : stage.iconName,
            state: state,
            kind: .standard,
            progress: nodeProgress,
            xpReward: LessonEconomyPolicy.xpReward(for: .standard),
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
    }

    private static func buildCheckpointNode(
        deck: TopicDeckDTO,
        deckWordCount: Int,
        sectionNodes: [LessonNodeModel],
        progressMap: [String: UserStageProgress],
        hasFoundActive: inout Bool
    ) -> LessonNodeModel {
        let checkpointId = "checkpoint_\(deck.id)"
        let checkpointProgress = progressMap[checkpointId]
        let checkpointEstimatedMinutes = LessonEconomyPolicy.checkpointEstimatedMinutes(deckWordCount: deckWordCount)
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

        return LessonNodeModel(
            id: checkpointId,
            title: AppStrings.Home.checkpointTitleText,
            subtitle: AppStrings.Home.checkpointSubtitleText,
            iconName: "crown.fill",
            state: checkpointState,
            kind: .checkpoint,
            progress: checkpointNodeProgress,
            xpReward: LessonEconomyPolicy.xpReward(for: .checkpoint),
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
    }

    private static func buildTreasureNode(
        deck: TopicDeckDTO,
        progressMap: [String: UserStageProgress],
        hasFoundActive: inout Bool
    ) -> LessonNodeModel {
        let treasureId = "treasure_\(deck.id)"
        let treasureProgress = progressMap[treasureId]
        let state: LessonNodeState
        let stars: Int?
        if let progress = treasureProgress, progress.isCompleted {
            state = .completed
            stars = calculateStars(from: progress.score)
        } else if let checkpointProgress = progressMap["checkpoint_\(deck.id)"],
                  checkpointProgress.isCompleted {
            // Treasure is bonus, does not consume hasFoundActive — next unit can still be active
            state = .bonus
            stars = nil
        } else {
            state = .locked
            stars = nil
        }

        return LessonNodeModel(
            id: treasureId,
            title: AppStrings.Home.treasureTitleText,
            subtitle: AppStrings.Home.treasureSubtitleText,
            iconName: "gift.fill",
            state: state,
            kind: .treasureChest,
            progress: nil,
            xpReward: LessonEconomyPolicy.xpReward(for: .treasureChest),
            estimatedMinutes: 1,
            stars: stars,
            badgeCount: nil,
            badgeText: state == .bonus ? "HOT" : nil,
            objectives: [
                String(localized: "app.home.node.treasure_objective_1", defaultValue: "Mở rương để nhận 150 XP", bundle: .module),
                String(localized: "app.home.node.treasure_objective_2", defaultValue: "Hoàn thành Unit để mở khóa", bundle: .module)
            ],
            objectiveKeys: [
                "app.home.node.treasure_objective_1",
                "app.home.node.treasure_objective_2"
            ]
        )
    }

    private static func buildSection(
        deck: TopicDeckDTO,
        deckIndex: Int,
        nodes: [LessonNodeModel]
    ) -> LessonSection {
        // Exclude treasureChest from progress denominator (bonus, not required)
        let progressNodes = nodes.filter { $0.kind != .treasureChest }
        let completedCount = progressNodes.filter { $0.state == .completed }.count
        let totalCount = progressNodes.count
        let progressText = AppStrings.Home.sectionProgress(completed: completedCount, total: totalCount)
        // Honest progress: active/inProgress/bonus counts as 0.5, so bar is not flat 0 when learner started
        let hasActive = progressNodes.contains { $0.state == .active || $0.state == .inProgress || $0.state == .bonus }
        let effectiveCompleted = Double(completedCount) + (hasActive ? 0.5 : 0.0)
        let progressValue = totalCount > 0 ? min(1.0, effectiveCompleted / Double(totalCount)) : 0.0

        return LessonSection(
            id: deck.id,
            title: deck.title,
            subtitle: nil,
            level: deck.cefrLevel,
            progressText: progressText,
            progressValue: progressValue,
            bannerIcon: deck.iconName,
            nodes: nodes,
            winding: .standard,
            connectorStyle: .dashed,
            rowPattern: .standard
        )
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

    private static func cleanStageTitle(_ title: String) -> String {
        let pattern = #"^Chặng\s+\d+:\s*"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: title.utf16.count)
            return regex.stringByReplacingMatches(in: title, options: [], range: range, withTemplate: "")
        }
        return title
    }
}
