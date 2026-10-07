import Foundation

public final class WhisperKitSTTEngineAdapter: STTEngineProtocol, @unchecked Sendable {
    public let engineName: String = "WhisperKit On-Device STT"
    private let underlyingEngine: WhisperKitSpeechEngine?
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
        underlyingEngine: WhisperKitSpeechEngine? = nil,
        isReadyProvider: (@Sendable () -> Bool)? = nil
    ) {
        self.underlyingEngine = underlyingEngine
        self.isReadyProvider = isReadyProvider
    }

    public func startRecognition(locale: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard isReady, let engine = underlyingEngine else {
                continuation.finish(
                    throwing: AIPackError.sttFailed(
                        packName: "WhisperKit",
                        underlyingMessage: "Model not downloaded"
                    )
                )
                return
            }
            Task { @MainActor in
                engine.startListening(
                    onResult: { text in continuation.yield(text) },
                    onError: { error in continuation.finish(throwing: error) }
                )
            }
            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    engine.stopListening()
                }
            }
        }
    }

    public func stopRecognition() {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                underlyingEngine?.stopListening()
            }
        } else {
            Task { @MainActor in
                self.underlyingEngine?.stopListening()
            }
        }
    }
}
