import Foundation

public protocol AIPackProtocol: Sendable {
    var identifier: AIPackIdentifier { get }
    var displayName: String { get }
    var packDescription: String { get }
    var status: AIPackStatus { get }
    var supportedVoices: [VoiceProfile] { get }
    var defaultVoice: VoiceProfile { get }

    func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol
    func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol
    func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol
}
