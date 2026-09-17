import AVFoundation
import Foundation
import Speech

// MARK: - Word Lifecycle & Audio Capture
extension ResilientReflexSpeechEngine {
    func activateWordCapture(targetLemma: String, contextualPhrases: [String]) throws {
        if isWordActive {
            endWord()
        }
        let token = UUID()
        currentWordSessionToken = token
        currentTargetLemma = targetLemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        liveTranscript = ""
        hasReportedFirstRecognitionResult = false
        isWordActive = true

        #if !targetEnvironment(simulator) && !os(macOS)
        guard let recognizer = resolveSpeechRecognizer(), recognizer.isAvailable else {
            isWordActive = false
            onError?(SpeechCaptureError.recognizerUnavailable)
            throw SpeechCaptureError.recognizerUnavailable
        }

        startRecognitionRequest(
            targetLemma: currentTargetLemma,
            contextualPhrases: contextualPhrases,
            sessionToken: token
        )
        #endif
    }

    public func startListening(targetLemma: String, contextualPhrases: [String]) async throws {
        guard isSessionActive else {
            throw SpeechCaptureError.cancelled
        }

        wordGeneration &+= 1
        let generation = wordGeneration
        activeStartTask?.cancel()

        let task = Task { [weak self] in
            guard let self else { throw SpeechCaptureError.cancelled }
            try await self.performStartListening(
                targetLemma: targetLemma,
                contextualPhrases: contextualPhrases,
                generation: generation
            )
        }
        self.activeStartTask = task

        do {
            try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
            if self.wordGeneration == generation {
                self.activeStartTask = nil
            }
        } catch {
            if self.wordGeneration == generation {
                self.activeStartTask = nil
            }
            throw error
        }
    }

    private func performStartListening(
        targetLemma: String,
        contextualPhrases: [String],
        generation: UInt
    ) async throws {
        if let audioLifecycleTask {
            await audioLifecycleTask.value
        }

        var acquiredLease: AudioSessionLease?
        do {
            try await checkPermissions(generation: generation)
            acquiredLease = try await acquireDuplexLease(generation: generation)
            try ensureCurrentAndActive(generation: generation)
            try await prepareAndResumeAudio(relay: bufferRelay)
            try ensureCurrentAndActive(generation: generation)

            let oldLease = self.activeLease
            self.activeLease = acquiredLease
            if let oldLease, oldLease != acquiredLease {
                await audioSessionCoordinator?.release(oldLease)
            }

            try ensureCurrentAndActive(generation: generation)

            isEngineReady = true
            isListeningPaused = false
            bufferRelay.unmute()

            try activateWordCapture(targetLemma: targetLemma, contextualPhrases: contextualPhrases)
        } catch {
            let isStale = (self.wordGeneration != generation)
            let coordinator = audioSessionCoordinator
            if !isStale {
                isEngineReady = false
                bufferRelay.mute()
                let lease = self.activeLease ?? acquiredLease
                let extraLease = (acquiredLease != lease) ? acquiredLease : nil
                self.activeLease = nil
                enqueueAudioTransition { controller in
                    await controller.teardown()
                    if let lease { await coordinator?.release(lease) }
                    if let extraLease { await coordinator?.release(extraLease) }
                }
            } else if let acquiredLease, acquiredLease != self.activeLease {
                enqueueAudioTransition { _ in
                    await coordinator?.release(acquiredLease)
                }
            }
            throw error
        }
    }

    func ensureCurrentAndActive(generation: UInt) throws {
        guard isSessionActive, !Task.isCancelled, self.wordGeneration == generation else {
            throw SpeechCaptureError.cancelled
        }
    }

    func checkPermissions(generation: UInt) async throws {
        try ensureCurrentAndActive(generation: generation)
        guard await authorizer.requestSpeechAuthorization() else {
            throw SpeechCaptureError.speechRecognitionDenied
        }
        try ensureCurrentAndActive(generation: generation)
        guard await authorizer.requestMicrophoneAuthorization() else {
            throw SpeechCaptureError.microphoneDenied
        }
        try ensureCurrentAndActive(generation: generation)
    }

    func acquireDuplexLease(generation: UInt) async throws -> AudioSessionLease? {
        guard let coordinator = audioSessionCoordinator else { return nil }
        do {
            return try await coordinator.acquire(.duplexSpeech)
        } catch {
            if error is CancellationError { throw SpeechCaptureError.cancelled }
            throw SpeechCaptureError.audioSessionActivationFailed
        }
    }

    func prepareAndResumeAudio(relay: AudioBufferRelay) async throws {
        do {
            try await audioController.prepare(relay: relay)
            try await audioController.resume()
        } catch {
            if error is CancellationError { throw SpeechCaptureError.cancelled }
            onError?(error)
            throw SpeechCaptureError.enginePreparationFailed
        }
    }

    @available(*, deprecated, message: "Use startListening(targetLemma:contextualPhrases:) instead")
    public func beginWord(targetLemma: String, contextualPhrases: [String]) {
        guard isSessionActive else {
            LessonPerformanceDiagnostics.event("SpeechWordBeginIgnored", detail: "sessionInactive")
            return
        }
        LessonPerformanceDiagnostics.event("SpeechWordBegin", detail: "engineReady=\(isEngineReady) sessionActive=\(isSessionActive)")
        if isWordActive {
            endWord()
        }
        isListeningPaused = false
        let token = UUID()
        currentWordSessionToken = token
        currentTargetLemma = targetLemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        liveTranscript = ""
        hasReportedFirstRecognitionResult = false
        isWordActive = true

        #if targetEnvironment(simulator) || os(macOS)
        // Simulator: no real recognition, test via simulateTranscript
        #else
        startRecognitionRequest(targetLemma: currentTargetLemma, contextualPhrases: contextualPhrases, sessionToken: token)
        #endif
    }

    public func endWord() {
        currentWordSessionToken = UUID() // Invalidate current token

        bufferRelay.detachAndEnd()
        activeTask?.cancel()
        activeRequest = nil
        activeTask = nil
        isWordActive = false
    }

    public func finalizeWordAudio() {
        // Signal end of audio input but keep recognition task alive
        // so in-flight buffers can still be processed during grace period.
        bufferRelay.detachAndEnd()
    }

    // MARK: - Simulator support
    public func simulateTranscript(_ text: String) {
        guard isWordActive else { return }
        liveTranscript = text
        onTranscriptUpdate?(text)

        if !currentTargetLemma.isEmpty,
           ReflexSpeechMatcher.isReflexMatch(spokenText: text, targetLemma: currentTargetLemma) {
            onMatchDetected?(currentTargetLemma)
        }
    }
}
