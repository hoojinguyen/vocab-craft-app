import CraftUIKit
import Foundation

/// Pure Swift adapter that transforms SQLite content models and journal completions into CraftUIKit `LessonSection` models.
public final class ContentLearningPathAdapter: Sendable {
    private let repository: any ContentRepository
    private let journal: LearningJournal
    private let profileID: ProfileID

    public init(repository: any ContentRepository, journal: LearningJournal, profileID: ProfileID) {
        self.repository = repository
        self.journal = journal
        self.profileID = profileID
    }

    public func load() async throws -> [LessonSection] {
        let decks = try await repository.fetchDecks()
        let completions = try await journal.completedLessons(profileID: profileID)
        let completedSet = Set(completions.map { $0.lessonID.rawValue.uuidString.lowercased() })

        var hasFoundActive = false
        var sections: [LessonSection] = []

        for deck in decks {
            let lessons = try await repository.fetchLessons(deckID: deck.id)
            var sectionNodes: [LessonNodeModel] = []
            var totalDeckWords = 0

            for lesson in lessons {
                let content = try await repository.fetchLessonContent(lessonID: lesson.id)
                let lessonUUID = lesson.id.rawValue.uuidString.lowercased()
                let isCompleted = completedSet.contains(lessonUUID)

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
           sectionNodes[activeIdx + 1].state == .locked {
            var nextNode = sectionNodes[activeIdx + 1]
            nextNode.state = .upcoming
            sectionNodes[activeIdx + 1] = nextNode
        }
    }

    private func buildSection(deck: DeckSummary, nodes: [LessonNodeModel], totalDeckWords: Int) -> LessonSection {
        let completedCount = nodes.filter { $0.state == .completed }.count
        let totalCount = nodes.count
        let progressText = AppStrings.Home.sectionProgress(completed: completedCount, total: totalCount)
        let subtitleText = AppStrings.Home.deckSummary(lessons: totalCount, words: totalDeckWords)
        let hasActive = nodes.contains { $0.state == .active || $0.state == .inProgress }
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
