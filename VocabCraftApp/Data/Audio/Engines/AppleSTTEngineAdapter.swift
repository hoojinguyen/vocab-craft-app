import Foundation

public final class AppleSTTEngineAdapter: STTEngineProtocol, @unchecked Sendable {
    public let engineName: String = "Apple Speech Recognition"
    public var isReady: Bool { true }
    private let coordinator: (any AudioSessionCoordinating)?

    private let lock = NSLock()
    private var activeService: SpeechRecognitionService?
    private var activeContinuation: AsyncThrowingStream<String, Error>.Continuation?
    private var sessionID: Int = 0

    public init(coordinator: (any AudioSessionCoordinating)? = nil) {
        self.coordinator = coordinator
    }

    public func startRecognition(locale: String) -> AsyncThrowingStream<String, Error> {
        startRecognition(locale: locale, onAudioLevel: nil)
    }

    public func startRecognition(
        locale: String,
        onAudioLevel: (@Sendable (Float) -> Void)? = nil
    ) -> AsyncThrowingStream<String, Error> {
        stopRecognition()

        return AsyncThrowingStream { continuation in
            let currentSessionID: Int
            lock.lock()
            sessionID += 1
            currentSessionID = sessionID
            activeContinuation = continuation
            lock.unlock()

            continuation.onTermination = { @Sendable [weak self] _ in
                self?.stopRecognition()
            }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.startSessionOnMainActor(
                        locale: locale,
                        sessionID: currentSessionID,
                        continuation: continuation,
                        onAudioLevel: onAudioLevel
                    )
                }
            } else {
                Task { @MainActor [weak self] in
                    self?.startSessionOnMainActor(
                        locale: locale,
                        sessionID: currentSessionID,
                        continuation: continuation,
                        onAudioLevel: onAudioLevel
                    )
                }
            }
        }
    }

    @MainActor
    private func startSessionOnMainActor(
        locale: String,
        sessionID: Int,
        continuation: AsyncThrowingStream<String, Error>.Continuation,
        onAudioLevel: (@Sendable (Float) -> Void)?
    ) {
        lock.lock()
        guard self.sessionID == sessionID else {
            lock.unlock()
            continuation.finish()
            return
        }
        let service: SpeechRecognitionService
        if let coordinator = self.coordinator {
            service = SpeechRecognitionService(locale: locale, audioSessionCoordinator: coordinator)
        } else {
            service = SpeechRecognitionService(locale: locale)
        }
        self.activeService = service
        lock.unlock()

        service.startListening(
            onResult: { text in continuation.yield(text) },
            onAudioLevel: onAudioLevel,
            onError: { error in continuation.finish(throwing: error) }
        )
    }

    public func stopRecognition() {
        let (service, continuation) = lock.withLock { () -> (SpeechRecognitionService?, AsyncThrowingStream<String, Error>.Continuation?) in
            sessionID += 1
            let currentService = activeService
            let currentContinuation = activeContinuation
            activeService = nil
            activeContinuation = nil
            return (currentService, currentContinuation)
        }

        continuation?.finish()

        if let service {
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    service.stopListening()
                }
            } else {
                Task { @MainActor in
                    service.stopListening()
                }
            }
        }
    }
}
