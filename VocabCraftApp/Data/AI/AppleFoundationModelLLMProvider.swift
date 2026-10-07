import Foundation

public final class AppleFoundationModelLLMProvider: LLMProviderProtocol, Sendable {
    public let providerIdentifier: String = "apple-foundation-models"

    public init() {}

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        // Foundation Models API gate for iOS 26+
        if #available(iOS 26, *) {
            // When iOS 26 Foundation Models SDK is linked, execute on-device inference here.
            throw AIPackError.deviceNotSupported(reason: "Apple Foundation Models runtime not yet enabled")
        } else {
            throw AIPackError.deviceNotSupported(reason: "Apple Foundation Models requires iOS 26+")
        }
    }
}
