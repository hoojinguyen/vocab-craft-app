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
    public let starterSuggestions: [String]

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
        iconSymbol: String,
        starterSuggestions: [String] = []
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
        self.starterSuggestions = starterSuggestions
    }

    enum CodingKeys: String, CodingKey {
        case id, titleKey, descriptionKey, topic, difficulty
        case characterName, characterRole, userRole, initialGreeting
        case targetWordIds, iconSymbol, starterSuggestions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.titleKey = try container.decode(String.self, forKey: .titleKey)
        self.descriptionKey = try container.decode(String.self, forKey: .descriptionKey)
        self.topic = try container.decode(ScenarioTopic.self, forKey: .topic)
        self.difficulty = try container.decode(ScenarioDifficulty.self, forKey: .difficulty)
        self.characterName = try container.decode(String.self, forKey: .characterName)
        self.characterRole = try container.decode(String.self, forKey: .characterRole)
        self.userRole = try container.decode(String.self, forKey: .userRole)
        self.initialGreeting = try container.decode(String.self, forKey: .initialGreeting)
        self.targetWordIds = try container.decodeIfPresent([String].self, forKey: .targetWordIds) ?? []
        self.iconSymbol = try container.decode(String.self, forKey: .iconSymbol)
        self.starterSuggestions = try container.decodeIfPresent([String].self, forKey: .starterSuggestions) ?? []
    }

    /// Maps the scenario character to a suitable natural voice persona.
    public var voicePersona: VoicePersona {
        let name = characterName.lowercased()
        if name.contains("alex") || name.contains("david") || name.contains("mr.") {
            return .friendlyMale
        }
        return .friendlyFemale
    }
}
