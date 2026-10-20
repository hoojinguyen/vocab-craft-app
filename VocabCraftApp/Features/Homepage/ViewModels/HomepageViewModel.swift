import CraftUIKit
import Foundation
import Observation

/// View model driving the gamified Minimal Zen Learning Path on the Homepage.
///
/// Features:
/// - `@Observable` and `@MainActor` isolation.
/// - Dynamic `dailyGoalProgress` computation derived from `dailyWordsLearned` and `dailyWordsGoal`.
/// - Asynchronous learning path loading via `FetchLearningPathUseCaseProtocol`.
/// - Node tap handling and detail modal lifecycle presentation.
@Observable
@MainActor
public final class HomepageViewModel {
    public var userName: String
    private var _streakDays: Int
    private var _dailyWordsLearned: Int
    private var _dailyWordsGoal: Int

    public var streakDays: Int {
        get { userSettings?.currentStreak ?? _streakDays }
        set {
            _streakDays = newValue
            userSettings?.currentStreak = newValue
        }
    }

    public var dailyWordsLearned: Int {
        get { userSettings?.todayWordsLearned ?? _dailyWordsLearned }
        set {
            _dailyWordsLearned = newValue
            userSettings?.todayWordsLearned = newValue
        }
    }

    public var dailyWordsGoal: Int {
        get { userSettings?.dailyGoalCount ?? _dailyWordsGoal }
        set {
            _dailyWordsGoal = newValue
            userSettings?.dailyGoalCount = newValue
        }
    }

    public var unreadNotifications: Bool
    public private(set) var activeLearningPath: LearningPathDTO?
    public var sections: [LessonSection]
    public var selectedNode: LessonNodeModel?
    public var isDetailSheetPresented: Bool
    public var activeMilestoneDelta: MilestoneLexicalDelta?
    public var isLoading: Bool
    public var errorMessage: String?

    public var dailyGoalProgress: Double {
        guard dailyWordsGoal > 0 else { return 0.0 }
        return Double(dailyWordsLearned) / Double(dailyWordsGoal)
    }

    public var currentDeckTitle: String? {
        guard let first = sections.first else { return nil }
        if let level = first.level, !level.isEmpty {
            return "\(level) • \(first.title)"
        }
        return first.title
    }

    public var currentDeckSubtitle: String? {
        if let active = sections.flatMap(\.nodes).first(where: { $0.state == .active || $0.state == .inProgress }) {
            return active.title
        }
        return sections.first?.nodes.first?.title
    }

    private let fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol?
    private let userSettings: UserSettingsStore?
    private let claimTreasureRewardUseCase: ClaimTreasureRewardUseCaseProtocol?
    private let fastTrackUnitUseCase: FastTrackUnitUseCaseProtocol?

    public init(
        fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        userSettings: UserSettingsStore? = nil,
        claimTreasureRewardUseCase: ClaimTreasureRewardUseCaseProtocol? = nil,
        fastTrackUnitUseCase: FastTrackUnitUseCaseProtocol? = nil,
        activeLearningPath: LearningPathDTO? = nil,
        userName: String = "Hooji N.",
        streakDays: Int = 14,
        dailyWordsLearned: Int = 8,
        dailyWordsGoal: Int = 10,
        unreadNotifications: Bool = false,
        sections: [LessonSection] = []
    ) {
        self.fetchLearningPathUseCase = fetchLearningPathUseCase
        self.ttsService = ttsService
        self.userSettings = userSettings
        self.claimTreasureRewardUseCase = claimTreasureRewardUseCase
        self.fastTrackUnitUseCase = fastTrackUnitUseCase
        self.activeLearningPath = activeLearningPath
        self.userName = userName
        self._streakDays = userSettings?.currentStreak ?? streakDays
        self._dailyWordsLearned = userSettings?.todayWordsLearned ?? dailyWordsLearned
        self._dailyWordsGoal = userSettings?.dailyGoalCount ?? dailyWordsGoal
        self.unreadNotifications = unreadNotifications
        self.sections = sections
        self.selectedNode = nil
        self.isDetailSheetPresented = false
        self.isLoading = false
        self.errorMessage = nil
    }

    public func refreshDailyProgress() {
        if let userSettings {
            self._streakDays = userSettings.currentStreak
            self._dailyWordsLearned = userSettings.todayWordsLearned
            self._dailyWordsGoal = userSettings.dailyGoalCount
        }
    }

    public func loadLearningPath(forceRefresh: Bool = false) async {
        refreshDailyProgress()
        guard let useCase = fetchLearningPathUseCase else { return }
        isLoading = true
        errorMessage = nil
        do {
            let curriculum = try await useCase.execute(pathId: userSettings?.selectedLearningPathId, forceRefresh: forceRefresh)
            self.activeLearningPath = curriculum.activePath
            self.sections = LearningPathDataMapper.map(curriculum: curriculum)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func switchLearningPath(to pathId: String) async {
        userSettings?.saveLearningPathPreference(pathId: pathId)
        await loadLearningPath(forceRefresh: true)
    }

    public func handleNodeTap(_ node: LessonNodeModel) {
        guard node.state != .locked else { return }
        self.selectedNode = node
        self.isDetailSheetPresented = true
    }

    public func dismissDetailSheet() {
        self.isDetailSheetPresented = false
        self.selectedNode = nil
    }

    public func dismissMilestoneDelta() {
        self.activeMilestoneDelta = nil
    }

    public func triggerMilestoneDelta(
        for deckId: String,
        summary: LessonSummaryModel? = nil,
        newWordsCount: Int? = nil
    ) {
        let section = sections.first(where: { $0.id == deckId })
        let unitTitle = section?.title ?? deckId
        let cefrLevel = section?.level ?? "A1"
        let fallbackWordsCount = 15
        let wordsCount: Int = {
            if let newWordsCount { return newWordsCount }
            if let summaryWords = summary?.learnedWords, !summaryWords.isEmpty {
                return summaryWords.count
            }
            return fallbackWordsCount
        }()
        let masteredCount = (summary?.learnedWords.count ?? 0) > 0 ? (summary?.learnedWords.count ?? 0) : 8
        let words = summary?.learnedWords.map(\.lemma) ?? []
        let accuracy = summary?.accuracyFraction ?? 0.95

        self.activeMilestoneDelta = MilestoneLexicalDelta(
            unitId: deckId,
            unitTitle: unitTitle,
            cefrLevel: cefrLevel,
            newWordsAdded: wordsCount,
            wordsMastered: masteredCount,
            avgResponseTimeMs: 1200,
            accuracyRate: accuracy,
            acquiredWords: words,
            cefrProgressCurrent: 240,
            cefrProgressTarget: 800
        )
    }

    public func handleLessonFinished(summary: LessonSummaryModel) {
        applyCompletedLesson(stageId: summary.stageId)
        if summary.isUnitCheckpoint {
            triggerMilestoneDelta(for: summary.deckId, summary: summary)
        }
    }

    public func resolvedDeckId(for node: LessonNodeModel) -> String {
        if node.id.hasPrefix("treasure_") {
            return String(node.id.dropFirst("treasure_".count))
        }
        if node.id.hasPrefix("checkpoint_") {
            return String(node.id.dropFirst("checkpoint_".count))
        }
        return sections.first(where: { sec in sec.nodes.contains(where: { $0.id == node.id }) })?.id ?? ""
    }

    @discardableResult
    public func claimTreasure(node: LessonNodeModel, autoTriggerMilestone: Bool = false) async throws -> TreasureRewardResult {
        let deckId = resolvedDeckId(for: node)
        let result: TreasureRewardResult
        if let useCase = claimTreasureRewardUseCase {
            result = try await useCase.execute(deckId: deckId)
        } else {
            result = TreasureRewardResult(
                stageId: node.id,
                deckId: deckId,
                xpEarned: LessonEconomyPolicy.treasureXP,
                isAlreadyClaimed: false
            )
        }
        applyCompletedLesson(stageId: node.id)
        if autoTriggerMilestone && !result.isAlreadyClaimed {
            triggerMilestoneDelta(for: deckId)
        }
        return result
    }

    @discardableResult
    public func fastTrackUnit(deckId: String, score: Double) async throws -> FastTrackResult {
        guard let useCase = fastTrackUnitUseCase else {
            let isSuccess = score >= FastTrackUnitUseCase.passingThreshold
            if isSuccess {
                applyCompletedLesson(stageId: "checkpoint_\(deckId)")
            }
            return FastTrackResult(
                deckId: deckId,
                isSuccess: isSuccess,
                scorePercentage: score,
                completedStageIds: isSuccess ? ["checkpoint_\(deckId)"] : [],
                ingestedWordCount: 0
            )
        }
        let result = try await useCase.execute(deckId: deckId, scorePercentage: score)
        if result.isSuccess {
            await loadLearningPath(forceRefresh: true)
        }
        return result
    }

    public func applyCompletedLesson(stageId: String) {
        var updatedSections = sections
        guard let (sIdx, nIdx) = findNodeLocation(for: stageId, in: updatedSections) else { return }

        var completedNode = updatedSections[sIdx].nodes[nIdx]
        completedNode.state = .completed
        updatedSections[sIdx].nodes[nIdx] = completedNode

        switch completedNode.kind {
        case .checkpoint:
            handleCheckpointCompletion(sIdx: sIdx, nIdx: nIdx, in: &updatedSections)
        case .treasureChest:
            break
        default:
            handleStandardNodeCompletion(sIdx: sIdx, nIdx: nIdx, in: &updatedSections)
        }

        updateSectionProgress(at: sIdx, in: &updatedSections)
        self.sections = updatedSections
        refreshDailyProgress()
    }

    private func findNodeLocation(for stageId: String, in sections: [LessonSection]) -> (sIdx: Int, nIdx: Int)? {
        for (sIdx, sec) in sections.enumerated() {
            if let nIdx = sec.nodes.firstIndex(where: { $0.id == stageId }) {
                return (sIdx, nIdx)
            }
        }
        return nil
    }

    private func handleCheckpointCompletion(sIdx: Int, nIdx: Int, in sections: inout [LessonSection]) {
        if nIdx + 1 < sections[sIdx].nodes.count && sections[sIdx].nodes[nIdx + 1].kind == .treasureChest {
            var treasureNode = sections[sIdx].nodes[nIdx + 1]
            if treasureNode.state != .completed {
                treasureNode.state = .bonus
                treasureNode.badgeText = "HOT"
                sections[sIdx].nodes[nIdx + 1] = treasureNode
            }
        }
        unlockNextSection(after: sIdx, in: &sections)
    }

    private func handleStandardNodeCompletion(sIdx: Int, nIdx: Int, in sections: inout [LessonSection]) {
        if nIdx + 1 < sections[sIdx].nodes.count {
            var nextNode = sections[sIdx].nodes[nIdx + 1]
            if nextNode.state == .locked || nextNode.state == .upcoming {
                nextNode.state = .active
                sections[sIdx].nodes[nIdx + 1] = nextNode
            }
            if nIdx + 2 < sections[sIdx].nodes.count && sections[sIdx].nodes[nIdx + 2].state == .locked {
                sections[sIdx].nodes[nIdx + 2].state = .upcoming
            }
        } else {
            unlockNextSection(after: sIdx, in: &sections)
        }
    }

    private func unlockNextSection(after sIdx: Int, in sections: inout [LessonSection]) {
        guard sIdx + 1 < sections.count, !sections[sIdx + 1].nodes.isEmpty else { return }
        var nextSectionFirstNode = sections[sIdx + 1].nodes[0]
        if nextSectionFirstNode.state == .locked || nextSectionFirstNode.state == .upcoming {
            nextSectionFirstNode.state = .active
            sections[sIdx + 1].nodes[0] = nextSectionFirstNode
        }
        if sections[sIdx + 1].nodes.count > 1 && sections[sIdx + 1].nodes[1].state == .locked {
            sections[sIdx + 1].nodes[1].state = .upcoming
        }
        updateSectionProgress(at: sIdx + 1, in: &sections)
    }

    private func updateSectionProgress(at index: Int, in sections: inout [LessonSection]) {
        guard index >= 0 && index < sections.count else { return }
        let section = sections[index]
        let relevantNodes = section.nodes.filter { $0.kind != .treasureChest }
        let countNodes = relevantNodes.isEmpty ? section.nodes : relevantNodes
        let totalCount = countNodes.count
        guard totalCount > 0 else { return }

        let completedCount = countNodes.filter { $0.state == .completed }.count
        let hasActive = countNodes.contains { $0.state == .active || $0.state == .inProgress || $0.state == .bonus }
        let effectiveCompleted = Double(completedCount) + (hasActive ? 0.5 : 0.0)
        let newProgressValue = min(1.0, effectiveCompleted / Double(totalCount))
        let newProgressText = AppStrings.Home.sectionProgress(completed: completedCount, total: totalCount)

        sections[index].progressValue = newProgressValue
        sections[index].progressText = newProgressText
    }
}
