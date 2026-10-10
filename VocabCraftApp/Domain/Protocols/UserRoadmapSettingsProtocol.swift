import Foundation

@MainActor
public protocol UserRoadmapSettingsProtocol: Sendable {
    var selectedGoalDeckId: String { get }
    var assessedCefrLevel: String { get }
    var dailyGoalCount: Int { get }
    var notificationTimeInterval: Double { get }
    var selectedLearningPathId: String? { get set }
    func saveRoadmapPreferences(
        deckId: String,
        cefrLevel: String,
        dailyGoalCount: Int,
        notificationTimeInterval: Double
    )
    func saveLearningPathPreference(pathId: String)
}

public extension UserRoadmapSettingsProtocol {
    var selectedGoalDeckId: String { "deck_daily" }
    var assessedCefrLevel: String { "A1" }
    var dailyGoalCount: Int { 15 }
    var notificationTimeInterval: Double { 72000 }
    var selectedLearningPathId: String? {
        get { nil }
        set { _ = newValue }
    }
    func saveLearningPathPreference(pathId: String) {}
}
