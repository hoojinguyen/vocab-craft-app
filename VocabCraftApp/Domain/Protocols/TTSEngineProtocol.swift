import Foundation

public protocol TTSEngineProtocol: Sendable {
    var engineName: String { get }
    var isReady: Bool { get }
    func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws
    func stop()
}
