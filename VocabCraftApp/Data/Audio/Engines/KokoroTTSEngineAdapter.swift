import Foundation

public final class KokoroTTSEngineAdapter: TTSEngineProtocol, @unchecked Sendable {
    public let engineName: String = "Kokoro Neural TTS"
    private let underlyingEngine: (any KokoroAudioSynthesizing)?
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
        underlyingEngine: (any KokoroAudioSynthesizing)? = nil,
        isReadyProvider: (@Sendable () -> Bool)? = nil
    ) {
        self.underlyingEngine = underlyingEngine
        self.isReadyProvider = isReadyProvider
    }

    public func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {
        guard isReady else {
            throw AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")
        }
        guard let engine = underlyingEngine else {
            throw AIPackError.ttsFailed(packName: "Offline AI Pack", underlyingMessage: "Model is not loaded")
        }
        let persona: VoicePersona
        switch (voice.gender, voice.style) {
        case (.female, .expressive):
            persona = .expressiveFemale
        case (.male, .authoritative):
            persona = .authoritativeMale
        case (.male, _):
            persona = .friendlyMale
        case (.female, _):
            persona = .friendlyFemale
        }
        do {
            try await engine.synthesizeAndPlay(text: text, persona: persona)
        } catch let packError as AIPackError {
            throw packError
        } catch {
            throw AIPackError.ttsFailed(packName: "Offline AI Pack", underlyingMessage: error.localizedDescription)
        }
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
