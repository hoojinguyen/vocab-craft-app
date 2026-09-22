import Foundation

public enum ScenarioTopic: String, Codable, Sendable, CaseIterable {
    case dining
    case travel
    case workplace
    case dailyLife
    case interview
}

public enum ScenarioDifficulty: String, Codable, Sendable, CaseIterable {
    case beginner
    case intermediate
    case advanced
}

public struct RoleplayScenario: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let titleKey: String
    public let descriptionKey: String
    public let topic: ScenarioTopic
    public let difficulty: ScenarioDifficulty
    public let characterName: String
    public let characterRole: String
    public let userRole: String
    public let initialGreeting: String
    public let targetWordIds: [String]
    public let iconSymbol: String

    public init(
        id: String,
        titleKey: String,
        descriptionKey: String,
        topic: ScenarioTopic,
        difficulty: ScenarioDifficulty,
        characterName: String,
        characterRole: String,
        userRole: String,
        initialGreeting: String,
        targetWordIds: [String],
        iconSymbol: String
    ) {
        self.id = id
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
        self.topic = topic
        self.difficulty = difficulty
        self.characterName = characterName
        self.characterRole = characterRole
        self.userRole = userRole
        self.initialGreeting = initialGreeting
        self.targetWordIds = targetWordIds
        self.iconSymbol = iconSymbol
    }
}
