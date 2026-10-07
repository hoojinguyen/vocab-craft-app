import Foundation

public final class GeminiTTSEngineAdapter: TTSEngineProtocol, @unchecked Sendable {
    public let engineName: String = "Gemini Studio TTS"
    private let apiKey: String
    private let underlyingEngine: GeminiAudioSpeechEngine

    public var isReady: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public init(
        apiKey: String,
        underlyingEngine: GeminiAudioSpeechEngine? = nil
    ) {
        self.apiKey = apiKey
        if let underlyingEngine {
            self.underlyingEngine = underlyingEngine
        } else if Thread.isMainThread {
            self.underlyingEngine = MainActor.assumeIsolated { GeminiAudioSpeechEngine() }
        } else {
            self.underlyingEngine = DispatchQueue.main.sync { GeminiAudioSpeechEngine() }
        }
    }

    public func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {
        guard isReady else {
            throw AIPackError.apiKeyRequired(providerName: "Gemini")
        }
        let persona: VoicePersona = voice.gender == .male ? .friendlyMale : .friendlyFemale
        try await underlyingEngine.synthesizeAndPlay(text: text, persona: persona, apiKey: apiKey)
    }

    public func stop() {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                underlyingEngine.stop()
            }
        } else {
            Task { @MainActor in
                self.underlyingEngine.stop()
            }
        }
    }
}
