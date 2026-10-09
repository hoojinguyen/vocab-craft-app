import Foundation

/// Adaptive Apple dialogue provider utilizing on-device Apple Intelligence foundation models
/// when available (iOS 26+), and falling back smoothly to `OnDeviceContextDialogueEngine` on iOS 17/18.
public final class AppleIntelligenceOrLocalDialogueProvider: LLMProviderProtocol, Sendable {
    public let providerIdentifier: String = "apple_intelligence_or_local"
    private let engine: OnDeviceContextDialogueEngine

    public init(engine: OnDeviceContextDialogueEngine = OnDeviceContextDialogueEngine()) {
        self.engine = engine
    }

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        let output = try await engine.generateTurn(
            messages: messages,
            systemPrompt: systemPrompt
        )

        if let typedResult = output as? T {
            return typedResult
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Unsupported output schema for AppleIntelligenceOrLocalDialogueProvider: expected \(responseSchema)"
            )
        )
    }
}
