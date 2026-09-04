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
    public var sections: [LessonSection]
    public var selectedNode: LessonNodeModel?
    public var isDetailSheetPresented: Bool
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

    public init(
        fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        userSettings: UserSettingsStore? = nil,
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

    public func loadLearningPath() async {
        refreshDailyProgress()
        guard let useCase = fetchLearningPathUseCase else { return }
        isLoading = true
        errorMessage = nil
        do {
            self.sections = try await useCase.execute()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
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

    public func applyCompletedLesson(stageId: String) {
        var updatedSections = sections
        var foundLocation: (secIdx: Int, nodeIdx: Int)?

        for (sIdx, sec) in updatedSections.enumerated() {
            if let nIdx = sec.nodes.firstIndex(where: { $0.id == stageId }) {
                foundLocation = (sIdx, nIdx)
                break
            }
        }

        guard let (sIdx, nIdx) = foundLocation else { return }

        var completedNode = updatedSections[sIdx].nodes[nIdx]
        completedNode.state = .completed
        updatedSections[sIdx].nodes[nIdx] = completedNode

        if nIdx + 1 < updatedSections[sIdx].nodes.count {
            var nextNode = updatedSections[sIdx].nodes[nIdx + 1]
            if nextNode.state == .locked || nextNode.state == .upcoming {
                nextNode.state = .active
                updatedSections[sIdx].nodes[nIdx + 1] = nextNode
            }
        } else if sIdx + 1 < updatedSections.count, !updatedSections[sIdx + 1].nodes.isEmpty {
            var nextNode = updatedSections[sIdx + 1].nodes[0]
            if nextNode.state == .locked || nextNode.state == .upcoming {
                nextNode.state = .active
                updatedSections[sIdx + 1].nodes[0] = nextNode
            }
        }

        self.sections = updatedSections
        refreshDailyProgress()
    }
}
