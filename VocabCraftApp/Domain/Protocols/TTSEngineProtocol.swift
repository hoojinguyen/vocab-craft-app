import Foundation

public protocol TTSEngineProtocol: Sendable {
    var engineName: String { get }
    var isReady: Bool { get }
    func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws
    func stop()
}

public protocol PlaybackReportingTTSEngineProtocol: TTSEngineProtocol {
    func synthesizeAndPlay(
        text: String,
        voice: VoiceConfiguration,
        onPlaybackStarted: @escaping @Sendable () -> Void
    ) async throws
}

public extension PlaybackReportingTTSEngineProtocol {
    func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {
        try await synthesizeAndPlay(text: text, voice: voice, onPlaybackStarted: {})
    }
}

public extension TTSEngineProtocol {
    func synthesizeAndPlay(
        text: String,
        voice: VoiceConfiguration,
        onPlaybackStarted: @escaping @Sendable () -> Void
    ) async throws {
        if let reporting = self as? any PlaybackReportingTTSEngineProtocol {
            try await reporting.synthesizeAndPlay(text: text, voice: voice, onPlaybackStarted: onPlaybackStarted)
        } else {
            try await synthesizeAndPlay(text: text, voice: voice)
        }
    }
}
