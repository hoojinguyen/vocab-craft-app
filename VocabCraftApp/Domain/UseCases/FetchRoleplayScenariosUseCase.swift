import Foundation

public final class FetchRoleplayScenariosUseCase: Sendable {
    public init() {}

    public func execute(userWeakWords: [String] = []) async throws -> [RoleplayScenario] {
        var catalog = RoleplayScenarioCatalog.standardScenarios

        if !userWeakWords.isEmpty {
            // Adaptive Daily Scenario prioritizing weak words
            let adaptiveDaily = RoleplayScenario(
                id: "daily-adaptive",
                titleKey: "app.ai_assistant.scenario.daily.title",
                descriptionKey: "app.ai_assistant.scenario.daily.desc",
                topic: .dailyLife,
                difficulty: .intermediate,
                characterName: "Alex",
                characterRole: "Language Coach",
                userRole: "Learner",
                initialGreeting: "Hi there! Let's practice using your recent vocabulary in a casual chat.",
                targetWordIds: Array(userWeakWords.prefix(3)),
                iconSymbol: "sparkles"
            )
            catalog.insert(adaptiveDaily, at: 0)
        }

        return catalog
    }
}
