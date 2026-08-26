import CraftUIKit
import Foundation
import Observation

@Observable
@MainActor
public final class HomepageViewModel {
    public var userName: String
    public var streakDays: Int
    public var dailyGoalProgress: Double
    public var unreadNotifications: Bool
    public var sections: [LessonSection]
    public var selectedNode: LessonNodeModel?
    public var isDetailSheetPresented: Bool
    public var isLoading: Bool
    public var errorMessage: String?

    private let fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol?

    public init(
        fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        userName: String = "Hooji N.",
        streakDays: Int = 14,
        dailyGoalProgress: Double = 0.75,
        unreadNotifications: Bool = false,
        sections: [LessonSection] = []
    ) {
        self.fetchLearningPathUseCase = fetchLearningPathUseCase
        self.ttsService = ttsService
        self.userName = userName
        self.streakDays = streakDays
        self.dailyGoalProgress = dailyGoalProgress
        self.unreadNotifications = unreadNotifications
        self.sections = sections
        self.selectedNode = nil
        self.isDetailSheetPresented = false
        self.isLoading = false
        self.errorMessage = nil
    }

    public func loadLearningPath() async {
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

    // MARK: - Backward Compatibility Helpers (for HomepageView transition)
    public var suggestedWords: [SuggestedWord] = []
    public var currentSuggestedWordIndex: Int = 0
    public var dueCardsCount: Int = 24
    public var totalWords: Int = 1420
    public var retentionPercentage: Double = 0.85

    public struct StateBridge: Equatable {
        public var userName: String
        public var streakDays: Int
        public var dailyGoalProgress: Double
        public var dueCardsCount: Int
        public var totalWords: Int
        public var retentionPercentage: Double
        public var unreadNotifications: Bool

        public init(
            userName: String = "Hooji N.",
            streakDays: Int = 14,
            dailyGoalProgress: Double = 0.75,
            dueCardsCount: Int = 24,
            totalWords: Int = 1420,
            retentionPercentage: Double = 0.85,
            unreadNotifications: Bool = false
        ) {
            self.userName = userName
            self.streakDays = streakDays
            self.dailyGoalProgress = dailyGoalProgress
            self.dueCardsCount = dueCardsCount
            self.totalWords = totalWords
            self.retentionPercentage = retentionPercentage
            self.unreadNotifications = unreadNotifications
        }
    }

    public var state: StateBridge {
        StateBridge(
            userName: userName,
            streakDays: streakDays,
            dailyGoalProgress: dailyGoalProgress,
            dueCardsCount: dueCardsCount,
            totalWords: totalWords,
            retentionPercentage: retentionPercentage,
            unreadNotifications: unreadNotifications
        )
    }

    public func loadData() async {
        await loadLearningPath()
    }

    public func speakSuggestedWord(_ word: SuggestedWord) {
        ttsService?.speak(text: word.lemma)
    }

    public func toggleBookmarkSuggestedWord(id: String) {
        if let index = suggestedWords.firstIndex(where: { $0.id == id }) {
            suggestedWords[index].isBookmarked.toggle()
        }
    }
}

