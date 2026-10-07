import Foundation

public struct OfflineAIPack: AIPackProtocol {
    public let identifier: AIPackIdentifier = .offlineAI
    public let displayName: String = "Offline AI Pack"
    public let packDescription: String = "High-quality neural models (Kokoro TTS & WhisperKit STT) running fully on-device"

    private let isKokoroReady: @Sendable () -> Bool
    private let isWhisperReady: @Sendable () -> Bool

    public init(
        isKokoroReady: @escaping @Sendable () -> Bool,
        isWhisperReady: @escaping @Sendable () -> Bool
    ) {
        self.isKokoroReady = isKokoroReady
        self.isWhisperReady = isWhisperReady
    }

    public var status: AIPackStatus {
        let kokoro = isKokoroReady()
        let whisper = isWhisperReady()
        if kokoro && whisper {
            return .ready
        }
        return .needsDownload(sizeDescription: "~500MB")
    }

    public var supportedVoices: [VoiceProfile] {
        [
            VoiceProfile(
                id: "kokoro-heart",
                displayName: "Heart (Warm Female)",
                voiceConfig: VoiceConfiguration(gender: .female, style: .friendly),
                sampleText: "Hi! Ready to practice your conversation skills?"
            )
        ]
    }

    public var defaultVoice: VoiceProfile {
        supportedVoices[0]
    }

    public func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
        guard #available(iOS 26, *) else {
            throw .deviceNotSupported(reason: "On-device LLM requires iOS 26+ in Phase 1")
        }
        return AppleFoundationModelLLMProvider()
    }

    public func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        guard isKokoroReady() else {
            throw .downloadRequired(packName: "Kokoro TTS", sizeDescription: "~350MB")
        }
        return KokoroTTSEngineAdapter(isReadyProvider: isKokoroReady)
    }

    public func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        guard isWhisperReady() else {
            throw .downloadRequired(packName: "WhisperKit", sizeDescription: "~150MB")
        }
        return WhisperKitSTTEngineAdapter(isReadyProvider: isWhisperReady)
    }
}
