import Foundation

public struct OfflineAIPack: AIPackProtocol {
    public let identifier: AIPackIdentifier = .offlineAI
    public let displayName: String = "Offline AI Pack"
    public let packDescription: String = "High-quality neural models (Kokoro TTS & WhisperKit STT) running fully on-device"

    private let isKokoroReady: @Sendable () -> Bool
    private let isWhisperReady: @Sendable () -> Bool
    private let kokoroEngineProvider: (@Sendable () -> KokoroTTSEngine?)?
    private let whisperEngineProvider: (@Sendable () -> WhisperKitSpeechEngine?)?
    private let llmProvider: (@Sendable () -> (any LLMProviderProtocol)?)?

    public init(
        isKokoroReady: @escaping @Sendable () -> Bool,
        isWhisperReady: @escaping @Sendable () -> Bool,
        kokoroEngineProvider: (@Sendable () -> KokoroTTSEngine?)? = nil,
        whisperEngineProvider: (@Sendable () -> WhisperKitSpeechEngine?)? = nil,
        llmProvider: (@Sendable () -> (any LLMProviderProtocol)?)? = nil
    ) {
        self.isKokoroReady = isKokoroReady
        self.isWhisperReady = isWhisperReady
        self.kokoroEngineProvider = kokoroEngineProvider
        self.whisperEngineProvider = whisperEngineProvider
        self.llmProvider = llmProvider
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
        if let custom = llmProvider?() {
            return custom
        }
        return IntelligentMockLLMProvider()
    }

    public func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        guard isKokoroReady() else {
            throw .downloadRequired(packName: "Kokoro TTS", sizeDescription: "~350MB")
        }
        let engine: KokoroTTSEngine?
        if let customProvider = kokoroEngineProvider {
            engine = customProvider()
        } else if Thread.isMainThread {
            engine = MainActor.assumeIsolated { KokoroTTSEngine() }
        } else {
            engine = DispatchQueue.main.sync { KokoroTTSEngine() }
        }
        return KokoroTTSEngineAdapter(underlyingEngine: engine, isReadyProvider: isKokoroReady)
    }

    public func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
        guard isWhisperReady() else {
            throw .downloadRequired(packName: "WhisperKit", sizeDescription: "~150MB")
        }
        let engine: WhisperKitSpeechEngine?
        if let customProvider = whisperEngineProvider {
            engine = customProvider()
        } else if Thread.isMainThread {
            engine = MainActor.assumeIsolated { WhisperKitSpeechEngine() }
        } else {
            engine = DispatchQueue.main.sync { WhisperKitSpeechEngine() }
        }
        return WhisperKitSTTEngineAdapter(underlyingEngine: engine, isReadyProvider: isWhisperReady)
    }
}
