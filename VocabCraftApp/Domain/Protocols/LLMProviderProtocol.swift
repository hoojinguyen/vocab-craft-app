import Foundation

public enum LLMRole: String, Codable, Sendable {
    case user
    case model
    case system
}

public struct LLMChatMessage: Codable, Sendable, Equatable {
    public let role: LLMRole
    public let content: String

    public init(role: LLMRole, content: String) {
        self.role = role
        self.content = content
    }
}

public protocol LLMProviderProtocol: Sendable {
    var providerIdentifier: String { get }
    func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T
}
