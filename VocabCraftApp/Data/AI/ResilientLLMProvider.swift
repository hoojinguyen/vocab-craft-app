import Foundation

public final class ResilientLLMProvider: LLMProviderProtocol, Sendable {
    public let providerIdentifier: String = "resilient-llm-router"
    private let primaryProvider: any LLMProviderProtocol
    private let fallbackProvider: any LLMProviderProtocol

    public init(
        primaryProvider: any LLMProviderProtocol,
        fallbackProvider: any LLMProviderProtocol
    ) {
        self.primaryProvider = primaryProvider
        self.fallbackProvider = fallbackProvider
    }

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        do {
            return try await primaryProvider.sendStructuredMessage(
                messages: messages,
                systemPrompt: systemPrompt,
                responseSchema: responseSchema
            )
        } catch {
            return try await fallbackProvider.sendStructuredMessage(
                messages: messages,
                systemPrompt: systemPrompt,
                responseSchema: responseSchema
            )
        }
    }
}
