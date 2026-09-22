import Foundation

/// Deterministic mock LLM provider for unit tests, Xcode previews, and offline scenarios.
public final class MockLLMProvider: LLMProviderProtocol, @unchecked Sendable {
    public let providerIdentifier: String = "mock"
    public var shouldThrowError: Bool = false
    public var mockTurnOutput: RoleplayTurnOutput?

    /// Initializes a mock LLM provider with optional preconfigured turn output.
    ///
    /// - Parameter mockTurnOutput: Preconfigured structured output to return, or nil for default fallback.
    public init(mockTurnOutput: RoleplayTurnOutput? = nil) {
        self.mockTurnOutput = mockTurnOutput
    }

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        if shouldThrowError {
            throw URLError(.cannotConnectToHost)
        }

        if let output = mockTurnOutput as? T {
            return output
        }

        // Default mock if none provided
        let defaultOutput = RoleplayTurnOutput(
            characterReply: "That sounds wonderful! Let me assist you with that.",
            targetWordsUsed: [],
            refinementSuggestion: nil,
            pedagogicalNote: "Keep going!"
        )

        if let defaultAsT = defaultOutput as? T {
            return defaultAsT
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Unsupported mock schema")
        )
    }
}
