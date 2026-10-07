import AVFoundation
import Foundation

public final class AppleTTSEngineAdapter: TTSEngineProtocol, @unchecked Sendable {
    public let engineName: String = "Apple Enhanced TTS"
    public var isReady: Bool { true }
    private let engine: AppleEnhancedTTSEngine

    public init(engine: AppleEnhancedTTSEngine? = nil) {
        if let engine {
            self.engine = engine
        } else if Thread.isMainThread {
            self.engine = MainActor.assumeIsolated { AppleEnhancedTTSEngine() }
        } else {
            self.engine = DispatchQueue.main.sync { AppleEnhancedTTSEngine() }
        }
    }

    public func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {
        let voiceId = AppleVoiceSelector.selectVoice(
            locale: voice.locale,
            gender: voice.gender == .male ? .male : .female
        )?.identifier

        await engine.speakAsync(
            text: text,
            rate: 0.5,
            locale: voice.locale,
            persona: nil,
            voiceIdentifier: voiceId,
            pitch: 1.0
        )
    }

    public func stop() {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                engine.stop()
            }
        } else {
            Task { @MainActor in
                self.engine.stop()
            }
        }
    }
}
