import AVFoundation
import Foundation
import SpeechKit

// MARK: - Session Lifecycle
extension ResilientReflexSpeechEngine {
    public func startSession(contextualPhrases: [String], lazy: Bool = false) {
        guard !isSessionActive else { return }
        LessonPerformanceDiagnostics.event("SpeechSessionStart", detail: "lazy=\(lazy)")
        self.sessionContextualPhrases = contextualPhrases
        self.isListeningPaused = false
        self.isSessionActive = true
        self.isEngineReady = false
        subscribeToAudioSessionEvents()

        if !lazy {
            pendingPreparationTask = Task { [weak self] in
                do {
                    try await self?.prepareEngineIfNeeded()
                } catch is CancellationError {
                    // Task cancellation is expected on stopSession
                } catch {
                    Task { @MainActor [weak self] in
                        self?.onError?(error)
                    }
                }
            }
        }
    }

    public func startSession(contextualPhrases: [String]) {
        startSession(contextualPhrases: contextualPhrases, lazy: false)
    }

    public func stopSession() {
        LessonPerformanceDiagnostics.event("SpeechSessionStop")
        eventSubscriptionTask?.cancel()
        eventSubscriptionTask = nil
        pendingPreparationTask?.cancel()
        pendingPreparationTask = nil
        activeStartTask?.cancel()
        activeStartTask = nil
        wordGeneration &+= 1
        isListeningPaused = false
        isSessionActive = false
        isEngineReady = false
        endWord()
        let leaseToRelease = activeLease
        activeLease = nil
        let coordinator = audioSessionCoordinator
        self.sessionReleaseTask = enqueueAudioTransition { controller in
            await controller.teardown()
            if let leaseToRelease { await coordinator?.release(leaseToRelease) }
        }
        sessionContextualPhrases = []
    }

    func subscribeToAudioSessionEvents() {
        eventSubscriptionTask?.cancel()
        guard let coordinator = audioSessionCoordinator else { return }
        let events = coordinator.events
        let task = Task { @MainActor [weak self] in
            for await event in events {
                guard let self, self.isSessionActive else { break }
                switch event {
                case .interruptionBegan:
                    self.pauseListening()
                case .interruptionEnded(let shouldResume):
                    if shouldResume {
                        self.resumeListening()
                    }
                case .mediaServicesReset:
                    self.stopSession()
                    self.onError?(SpeechCaptureError.enginePreparationFailed)
                default:
                    break
                }
            }
        }
        self.eventSubscriptionTask = task
    }

    public func pauseListening() {
        isListeningPaused = true
        pendingPreparationTask?.cancel()
        pendingPreparationTask = nil
        bufferRelay.mute()
        endWord()
        enqueueAudioTransition { controller in await controller.pause() }
    }

    public func resumeListening() {
        isListeningPaused = false
        bufferRelay.unmute()
        if isSessionActive {
            if !isEngineReady {
                pendingPreparationTask?.cancel()
                pendingPreparationTask = Task { [weak self] in
                    do {
                        try await self?.prepareEngineIfNeeded()
                    } catch is CancellationError {
                        // Task cancellation is expected on stopSession
                    } catch {
                        Task { @MainActor [weak self] in
                            self?.onError?(error)
                        }
                    }
                }
            } else {
                enqueueAudioTransition { [weak self] controller in
                    do {
                        try await controller.resume()
                    } catch {
                        Task { @MainActor [weak self] in
                            self?.onError?(error)
                        }
                    }
                }
            }
        }
    }

    @discardableResult
    func enqueueAudioTransition(
        _ operation: @escaping @Sendable (any SpeechAudioEngineControlling) async -> Void
    ) -> Task<Void, Never> {
        let previousTask = audioLifecycleTask
        let controller = audioController
        let transitionTask = Task {
            _ = await previousTask?.value
            await operation(controller)
        }
        audioLifecycleTask = transitionTask
        return transitionTask
    }

    func requestAuthorizationIfNeeded() async throws {
        guard await authorizer.requestSpeechAuthorization() else {
            throw SpeechCaptureError.speechRecognitionDenied
        }
        guard await authorizer.requestMicrophoneAuthorization() else {
            throw SpeechCaptureError.microphoneDenied
        }
    }

    public func prepareEngineIfNeeded() async throws {
        guard isSessionActive else { return }
        if let audioLifecycleTask { await audioLifecycleTask.value }
        guard isSessionActive else { return }
        try await requestAuthorizationIfNeeded()
        guard isSessionActive, !Task.isCancelled else { throw CancellationError() }
        do {
            try await audioController.prepare(relay: bufferRelay)
        } catch {
            if !(error is CancellationError) { onError?(error) }
            throw error
        }
        guard isSessionActive, !Task.isCancelled else {
            isEngineReady = false
            await audioController.teardown()
            if Task.isCancelled { throw CancellationError() }
            return
        }
        isEngineReady = true
        isListeningPaused = false
        bufferRelay.unmute()
    }
}
