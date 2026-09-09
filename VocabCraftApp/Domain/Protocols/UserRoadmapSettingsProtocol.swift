import Foundation

/// Protocol abstracting user preferences persistence during roadmap initialization.
public protocol UserRoadmapSettingsProtocol: Sendable {
    /// Saves user preferences chosen during onboarding/roadmap initialization.
    ///
    /// - Parameters:
    ///   - deckId: The identifier of the selected goal deck.
    ///   - cefrLevel: The assessed CEFR level.
    ///   - dailyGoalCount: The target daily word goal count.
    ///   - notificationTimeInterval: The daily reminder time interval in seconds from midnight.
    @MainActor
    func saveRoadmapPreferences(
        deckId: String,
        cefrLevel: String,
        dailyGoalCount: Int,
        notificationTimeInterval: Double
    )
}
