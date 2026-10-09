import Foundation

public final class FetchRoleplayScenariosUseCase: Sendable {
    public init() {}

    public func execute(userWeakWords: [String] = []) async throws -> [RoleplayScenario] {
        var catalog = RoleplayScenarioCatalog.standardScenarios

        if !userWeakWords.isEmpty {
            // Adaptive Daily Scenario prioritizing weak words
            let firstWord = userWeakWords.first ?? "vocabulary"
            let secondWord = userWeakWords.count > 1 ? userWeakWords[1] : firstWord
            let starterPrompts = [
                "Hi! I'd like to practice using '\(firstWord)' in our conversation today.",
                "Hello! Could you help me practice using words like '\(secondWord)'?",
                "Hey Alex, I'm ready to practice my recent English vocabulary!"
            ]

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
                iconSymbol: "sparkles",
                starterSuggestions: starterPrompts
            )
            catalog.insert(adaptiveDaily, at: 0)
        }

        return catalog
    }
}
