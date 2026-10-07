import Foundation

public struct AppleDefaultPack: AIPackProtocol {
    public let identifier: AIPackIdentifier = .appleDefault
    public let displayName: String = "Apple Default"
    public let packDescription: String = "Built-in Apple system components (AVSpeech & Speech Recognition)"

    public var status: AIPackStatus {
        if #available(iOS 26, *) {
            return .ready
        }
        return .unavailable(reason: "Apple Foundation Models requires iOS 26+")
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
        guard #available(iOS 26, *) else {
            throw .deviceNotSupported(reason: "Apple Foundation Models requires iOS 26+")
        }
        return AppleFoundationModelLLMProvider()
    }

    public func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        AppleTTSEngineAdapter()
    }

    public func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        AppleSTTEngineAdapter()
    }
}
