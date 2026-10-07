import Foundation

public final class AppleSTTEngineAdapter: STTEngineProtocol, @unchecked Sendable {
    public let engineName: String = "Apple Speech Recognition"
    public var isReady: Bool { true }
    private let coordinator: (any AudioSessionCoordinating)?

    public init(coordinator: (any AudioSessionCoordinating)? = nil) {
        self.coordinator = coordinator
    }

    public func startRecognition(locale: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                let service: SpeechRecognitionService
                if let coordinator = self.coordinator {
                    service = SpeechRecognitionService(locale: locale, audioSessionCoordinator: coordinator)
                } else {
                    service = SpeechRecognitionService(locale: locale)
                }
                service.startListening(
                    onResult: { text in continuation.yield(text) },
                    onError: { error in continuation.finish(throwing: error) }
                )
                continuation.onTermination = { @Sendable _ in
                    Task { @MainActor in
                        service.stopListening()
                    }
                }
            }
        }
    }

    public func stopRecognition() {}
}
