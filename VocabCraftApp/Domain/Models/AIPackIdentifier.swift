import Foundation

public enum AIPackIdentifier: String, Codable, Sendable, CaseIterable {
    case appleDefault
    case offlineAI
    case geminiCloud
    case groqCloud
    case openAICloud
}
