import Foundation

public struct GeminiCloudPack: AIPackProtocol {
    public let identifier: AIPackIdentifier = .geminiCloud
    public let displayName: String = "Gemini Cloud Pack"
    public let packDescription: String = "Google Gemini neural intelligence and expressive Studio voices"

    private let settingsStore: UserSettingsStore

    public init(settingsStore: UserSettingsStore) {
        self.settingsStore = settingsStore
    }

    private var isApiKeyConfigured: Bool {
        if Thread.isMainThread {
            return MainActor.assumeIsolated { settingsStore.isGeminiApiKeyConfigured }
        } else {
            return DispatchQueue.main.sync { settingsStore.isGeminiApiKeyConfigured }
        }
    }

    private var currentApiKey: String {
        if Thread.isMainThread {
            return MainActor.assumeIsolated { settingsStore.geminiApiKey }
        } else {
            return DispatchQueue.main.sync { settingsStore.geminiApiKey }
        }
    }

    public var status: AIPackStatus {
        guard isApiKeyConfigured else {
            return .needsApiKey(providerName: "Google Gemini")
        }
        return .ready
    }

    public var supportedVoices: [VoiceProfile] {
        [
            VoiceProfile(
                id: "gemini-aoede",
                displayName: "Aoede (Friendly Female)",
                voiceConfig: VoiceConfiguration(gender: .female, style: .friendly),
                sampleText: "Hello there! Let's practice English together today."
            ),
            VoiceProfile(
                id: "gemini-puck",
                displayName: "Puck (Friendly Male)",
                voiceConfig: VoiceConfiguration(gender: .male, style: .friendly),
                sampleText: "Hey! Ready to dive into this scenario?"
            )
        ]
    }

    public var defaultVoice: VoiceProfile {
        supportedVoices[0]
    }

    public func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
        let key = currentApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw .apiKeyRequired(providerName: "Google Gemini") }
        return GeminiLLMProvider(apiKey: key)
    }

    public func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        let key = currentApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw .apiKeyRequired(providerName: "Google Gemini") }
        return GeminiTTSEngineAdapter(apiKey: key)
    }

    public func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        AppleSTTEngineAdapter()
    }
}
