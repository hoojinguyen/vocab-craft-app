import Foundation

public struct AppleDefaultPack: AIPackProtocol {
    public let identifier: AIPackIdentifier = .appleDefault
    public let displayName: String = "Apple Default"
    public let packDescription: String = "Built-in Apple system components (AVSpeech & Speech Recognition)"

    public var status: AIPackStatus {
        .ready
    }

    public var supportedVoices: [VoiceProfile] {
        [
            VoiceProfile(
                id: "apple-default-female",
                displayName: "Samantha (Natural Female)",
                voiceConfig: VoiceConfiguration(gender: .female, style: .friendly),
                sampleText: "Hello, I am your Apple study partner."
            )
        ]
    }

    public var defaultVoice: VoiceProfile {
        supportedVoices[0]
    }

    public init() {}

    public func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
        AppleIntelligenceOrLocalDialogueProvider()
    }

    public func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        AppleTTSEngineAdapter()
    }

    public func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        AppleSTTEngineAdapter()
    }
}
