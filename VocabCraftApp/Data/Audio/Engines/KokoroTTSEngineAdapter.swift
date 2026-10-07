import Foundation

public final class KokoroTTSEngineAdapter: TTSEngineProtocol, @unchecked Sendable {
    public let engineName: String = "Kokoro Neural TTS"
    private let underlyingEngine: KokoroTTSEngine?
    private let isReadyProvider: (@Sendable () -> Bool)?

    public var isReady: Bool {
        if let provider = isReadyProvider {
            return provider()
        }
        if Thread.isMainThread {
            return MainActor.assumeIsolated { underlyingEngine?.isReady ?? false }
        } else {
            return DispatchQueue.main.sync { underlyingEngine?.isReady ?? false }
        }
    }

    public init(
        underlyingEngine: KokoroTTSEngine? = nil,
        isReadyProvider: (@Sendable () -> Bool)? = nil
    ) {
        self.underlyingEngine = underlyingEngine
        self.isReadyProvider = isReadyProvider
    }

    public func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {
        guard isReady, let engine = underlyingEngine else {
            throw AIPackError.ttsFailed(packName: "Kokoro", underlyingMessage: "Model is not loaded")
        }
        let persona: VoicePersona = voice.gender == .male ? .friendlyMale : .friendlyFemale
        try await engine.synthesizeAndPlay(text: text, persona: persona)
    }

    public func stop() {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                underlyingEngine?.stop()
            }
        } else {
            Task { @MainActor in
                self.underlyingEngine?.stop()
            }
        }
    }
}
