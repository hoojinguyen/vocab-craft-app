import CraftUIKit
import Foundation

/// Key identifying a specific completed lesson revision.
public struct LessonCompletionKey: Hashable, Sendable {
    public let lessonID: LessonID
    public let revision: Int

    public init(lessonID: LessonID, revision: Int) {
        self.lessonID = lessonID
        self.revision = revision
    }
}

/// Pure Swift adapter that transforms SQLite content models and journal completions into CraftUIKit `LessonSection` models.
public final class ContentLearningPathAdapter: Sendable {
    private let repository: any ContentRepository
    private let journal: LearningJournal
    private let profileID: ProfileID
    private let stageProgressRepo: StageProgressRepositoryProtocol?

    public init(
        repository: any ContentRepository,
        journal: LearningJournal,
        profileID: ProfileID,
        stageProgressRepo: StageProgressRepositoryProtocol? = nil
    ) {
        self.repository = repository
        self.journal = journal
        self.profileID = profileID
        self.stageProgressRepo = stageProgressRepo
    }

    public func load() async throws -> [LessonSection] {
        _ = try? await journal.ensureDefaultGuestProfile(id: profileID)
        let decks = try await repository.fetchDecks()
        let completions = try await journal.completedLessons(profileID: profileID)
        let completedSet = Set(completions.map {
            LessonCompletionKey(lessonID: $0.lessonID, revision: $0.lessonRevision)
        })
        let stageProgressList = (try? await stageProgressRepo?.fetchAllStageProgress()) ?? []
        let stageProgressMap = Dictionary(stageProgressList.map { ($0.stageId, $0) }, uniquingKeysWith: { first, _ in first })

        var hasFoundActive = false
        var sections: [LessonSection] = []

        for deck in decks {
            let deckUUID = deck.id.rawValue.uuidString.lowercased()
            let lessons = try await repository.fetchLessons(deckID: deck.id)
            var sectionNodes: [LessonNodeModel] = []
            var totalDeckWords = 0

            for lesson in lessons {
                let content = try await repository.fetchLessonContent(lessonID: lesson.id)
                let lessonUUID = lesson.id.rawValue.uuidString.lowercased()
                let completionKey = LessonCompletionKey(lessonID: lesson.id, revision: lesson.revision)
                let isCompleted = completedSet.contains(completionKey) || (stageProgressMap[lessonUUID]?.isCompleted == true)

                let node = buildNode(
                    lesson: lesson,
                    content: content,
                    lessonUUID: lessonUUID,
                    isCompleted: isCompleted,
                    hasFoundActive: &hasFoundActive
                )
                totalDeckWords += content.senses.count
                sectionNodes.append(node)
            }

            let checkpointNode = buildCheckpointNode(
                deckUUID: deckUUID,
                deckWordCount: totalDeckWords,
                sectionNodes: sectionNodes,
                stageProgressMap: stageProgressMap,
                hasFoundActive: &hasFoundActive
            )
            sectionNodes.append(checkpointNode)

            let checkpointProgress = stageProgressMap["checkpoint_\(deckUUID)"]
            let treasureNode = buildTreasureNode(
                deckUUID: deckUUID,
                stageProgressMap: stageProgressMap,
                checkpointProgress: checkpointProgress
            )
            sectionNodes.append(treasureNode)

            promoteUpcomingNode(in: &sectionNodes)
            let section = buildSection(deck: deck, nodes: sectionNodes, totalDeckWords: totalDeckWords)
            sections.append(section)
        }

        return sections
    }

    private func buildNode(
        lesson: LessonDetail,
        content: LessonDetail,
        lessonUUID: String,
        isCompleted: Bool,
        hasFoundActive: inout Bool
    ) -> LessonNodeModel {
        let state: LessonNodeState
        let stars: Int?
        if isCompleted {
            state = .completed
            stars = 3
        } else if !hasFoundActive {
            state = .active
            stars = nil
            hasFoundActive = true
        } else {
            state = .locked
            stars = nil
        }

        let senses = content.senses
        let wordCount = senses.count
        let estimatedMinutes = LessonEconomyPolicy.estimatedMinutes(wordCount: wordCount)
        let previewSubtitle = makePreviewSubtitle(senses: senses, wordCount: wordCount, estimatedMinutes: estimatedMinutes)

        return LessonNodeModel(
            id: lessonUUID,
            title: lesson.titleVI.isEmpty ? lesson.titleEN : lesson.titleVI,
            subtitle: previewSubtitle,
            iconName: Self.mapIconName(lesson.iconKey),
            state: state,
            kind: .standard,
            progress: nil,
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

    private func makePreviewSubtitle(senses: [SenseSummary], wordCount: Int, estimatedMinutes: Int) -> String {
        if senses.isEmpty {
            return AppStrings.Home.wordsDuration(words: wordCount, minutes: estimatedMinutes)
        }
        let preview = senses.prefix(2).map(\.headword).joined(separator: " • ")
        guard !preview.isEmpty else {
            return AppStrings.Home.wordsDuration(words: wordCount, minutes: estimatedMinutes)
        }
        let minutesText = CraftLocalized.format("craft.common.unit.minutes_format", estimatedMinutes)
        return "\(preview) • \(minutesText)"
    }

    private func promoteUpcomingNode(in sectionNodes: inout [LessonNodeModel]) {
        if let activeIdx = sectionNodes.firstIndex(where: { $0.state == .active || $0.state == .inProgress }),
           activeIdx + 1 < sectionNodes.count,
           sectionNodes[activeIdx + 1].state == .locked,
           sectionNodes[activeIdx + 1].kind != .treasureChest {
            var nextNode = sectionNodes[activeIdx + 1]
            nextNode.state = .upcoming
            sectionNodes[activeIdx + 1] = nextNode
        }
    }

    private func buildCheckpointNode(
        deckUUID: String,
        deckWordCount: Int,
        sectionNodes: [LessonNodeModel],
        stageProgressMap: [String: UserStageProgress],
        hasFoundActive: inout Bool
    ) -> LessonNodeModel {
        let checkpointId = "checkpoint_\(deckUUID)"
        let checkpointProgress = stageProgressMap[checkpointId]
        let estimatedMinutes = LessonEconomyPolicy.checkpointEstimatedMinutes(deckWordCount: deckWordCount)
        let allStandardCompleted = sectionNodes.allSatisfy { $0.state == .completed }

        let state: LessonNodeState
        let stars: Int?
        let progress: Double?

        if let checkpointProgress, checkpointProgress.isCompleted {
            state = .completed
            stars = max(1, min(3, checkpointProgress.score))
            progress = nil
        } else if allStandardCompleted && !hasFoundActive {
            if let checkpointProgress, checkpointProgress.progressFraction > 0.0 {
                state = .inProgress
                progress = checkpointProgress.progressFraction
            } else {
                state = .active
                progress = nil
            }
            stars = nil
            hasFoundActive = true
        } else {
            state = .locked
            stars = nil
            progress = nil
        }

        return LessonNodeModel(
            id: checkpointId,
            title: AppStrings.Home.checkpointTitleText,
            subtitle: AppStrings.Home.checkpointSubtitleText,
            iconName: "crown.fill",
            state: state,
            kind: .checkpoint,
            progress: progress,
            xpReward: LessonEconomyPolicy.xpReward(for: .checkpoint),
            estimatedMinutes: estimatedMinutes,
            stars: stars,
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

    private func buildTreasureNode(
        deckUUID: String,
        stageProgressMap: [String: UserStageProgress],
        checkpointProgress: UserStageProgress?
    ) -> LessonNodeModel {
        let treasureId = "treasure_\(deckUUID)"
        let treasureProgress = stageProgressMap[treasureId]
        let state: LessonNodeState
        let stars: Int?

        if let treasureProgress, treasureProgress.isCompleted {
            state = .completed
            stars = max(1, min(3, treasureProgress.score))
        } else if let checkpointProgress, checkpointProgress.isCompleted {
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

    private func buildSection(deck: DeckSummary, nodes: [LessonNodeModel], totalDeckWords: Int) -> LessonSection {
        let progressNodes = nodes.filter { $0.kind != .treasureChest }
        let completedCount = progressNodes.filter { $0.state == .completed }.count
        let totalCount = progressNodes.count
        let progressText = AppStrings.Home.sectionProgress(completed: completedCount, total: totalCount)
        let subtitleText = AppStrings.Home.deckSummary(lessons: totalCount, words: totalDeckWords)
        let hasActive = progressNodes.contains { $0.state == .active || $0.state == .inProgress }
        let effectiveCompleted = Double(completedCount) + (hasActive ? 0.5 : 0.0)
        let progressValue = totalCount > 0 ? min(1.0, effectiveCompleted / Double(totalCount)) : 0.0

        return LessonSection(
            id: deck.id.rawValue.uuidString.lowercased(),
            title: deck.titleVI.isEmpty ? deck.titleEN : deck.titleVI,
            subtitle: subtitleText,
            level: deck.cefrLevels.first?.rawValue ?? "A1",
            progressText: progressText,
            progressValue: progressValue,
            bannerIcon: Self.mapIconName(deck.iconKey),
            nodes: nodes,
            winding: .standard,
            connectorStyle: .dashed,
            rowPattern: .standard
        )
    }

    private static func mapIconName(_ iconKey: String) -> String {
        switch iconKey {
        case "book_open": return "book.fill"
        case "bookmark": return "bookmark.fill"
        case "graduation_cap": return "graduationcap.fill"
        case "plane": return "airplane"
        case "chat": return "bubble.left.and.bubble.right.fill"
        case "sparkles": return "sparkles"
        case "compass": return "safari.fill"
        case "star": return "star.fill"
        default: return iconKey.isEmpty ? "book.fill" : iconKey
        }
    }
}
