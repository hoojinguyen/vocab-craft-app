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
    public var streakDays: Int
    public var dailyWordsLearned: Int
    public var dailyWordsGoal: Int
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

    private let fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol?

    public init(
        fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        userName: String = "Hooji N.",
        streakDays: Int = 14,
        dailyWordsLearned: Int = 8,
        dailyWordsGoal: Int = 10,
        unreadNotifications: Bool = false,
        sections: [LessonSection] = []
    ) {
        self.fetchLearningPathUseCase = fetchLearningPathUseCase
        self.ttsService = ttsService
        self.userName = userName
        self.streakDays = streakDays
        self.dailyWordsLearned = dailyWordsLearned
        self.dailyWordsGoal = dailyWordsGoal
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
}
