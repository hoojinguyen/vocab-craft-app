import Foundation

public struct OfflineAIPack: AIPackProtocol {
    public let identifier: AIPackIdentifier = .offlineAI
    public let displayName: String = "Offline AI Pack"
    public let packDescription: String = "High-quality neural models (Kokoro TTS, WhisperKit STT & Llama 3.2 LLM) running fully on-device"

    private let isKokoroReady: @Sendable () -> Bool
    private let isWhisperReady: @Sendable () -> Bool
    private let isLlamaReady: @Sendable () -> Bool
    private let kokoroEngineProvider: (@Sendable () -> KokoroTTSEngine?)?
    private let whisperEngineProvider: (@Sendable () -> WhisperKitSpeechEngine?)?
    private let llmProvider: (@Sendable () -> (any LLMProviderProtocol)?)?
    private let llamaWorkerProvider: (@Sendable () -> LlamaInferenceWorker?)?

    public init(
        isKokoroReady: @escaping @Sendable () -> Bool,
        isWhisperReady: @escaping @Sendable () -> Bool,
        isLlamaReady: (@Sendable () -> Bool)? = nil,
        kokoroEngineProvider: (@Sendable () -> KokoroTTSEngine?)? = nil,
        whisperEngineProvider: (@Sendable () -> WhisperKitSpeechEngine?)? = nil,
        llmProvider: (@Sendable () -> (any LLMProviderProtocol)?)? = nil,
        llamaWorkerProvider: (@Sendable () -> LlamaInferenceWorker?)? = nil
    ) {
        self.isKokoroReady = isKokoroReady
        self.isWhisperReady = isWhisperReady
        self.isLlamaReady = isLlamaReady ?? { false }
        self.kokoroEngineProvider = kokoroEngineProvider
        self.whisperEngineProvider = whisperEngineProvider
        self.llmProvider = llmProvider
        self.llamaWorkerProvider = llamaWorkerProvider
    }

    public var status: AIPackStatus {
        let kokoro = isKokoroReady()
        let whisper = isWhisperReady()
        let llama = isLlamaReady()
        if kokoro && whisper && llama {
            return .ready
        }
        return .needsDownload(sizeDescription: "~975MB")
    }

    public var supportedVoices: [VoiceProfile] {
        [
            VoiceProfile(
                id: "kokoro-nova",
                displayName: "Nova (af_bella)",
                voiceConfig: VoiceConfiguration(gender: .female, style: .friendly),
                sampleText: "Hello! I'm Nova, your AI practice partner."
            ),
            VoiceProfile(
                id: "kokoro-orion",
                displayName: "Orion (am_adam)",
                voiceConfig: VoiceConfiguration(gender: .male, style: .friendly),
                sampleText: "Hey there! Orion here, ready to help you practice."
            ),
            VoiceProfile(
                id: "kokoro-sarah",
                displayName: "Sarah (af_sarah)",
                voiceConfig: VoiceConfiguration(gender: .female, style: .expressive),
                sampleText: "Hi! I'm Sarah, excited to explore new vocabulary with you."
            ),
            VoiceProfile(
                id: "kokoro-michael",
                displayName: "Michael (am_michael)",
                voiceConfig: VoiceConfiguration(gender: .male, style: .authoritative),
                sampleText: "Greetings. Michael here, let's strengthen your language skills."
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
        guard isLlamaReady() else {
            throw .downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB")
        }
        let worker = llamaWorkerProvider?()
        return LlamaLocalLLMProvider(
            worker: worker,
            isReadyProvider: isLlamaReady
        )
    }

    public func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
        guard isKokoroReady() else {
            throw .downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")
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
