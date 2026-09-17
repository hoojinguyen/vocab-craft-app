import AVFoundation
import Foundation
import Speech

// MARK: - Recognition Request Management
extension ResilientReflexSpeechEngine {
    #if !targetEnvironment(simulator) && !os(macOS)
    func buildRecognitionRequest(
        targetLemma: String,
        contextualPhrases: [String]
    ) -> SFSpeechAudioBufferRecognitionRequest {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .search

        var biasedPhrases = (sessionContextualPhrases + contextualPhrases).flatMap { phrase -> [String] in
            let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.split(separator: " ").count <= 2 else { return [] }
            return [trimmed]
        }
        if !biasedPhrases.contains(targetLemma) { biasedPhrases.append(targetLemma) }
        request.contextualStrings = Array(Set(biasedPhrases))

        #if os(iOS)
        if #available(iOS 16.0, *) {
            request.addsPunctuation = false
        }
        #endif

        return request
    }

    func handleRecognitionTaskError(
        _ error: Error,
        targetLemma: String,
        contextualPhrases: [String],
        sessionToken: UUID
    ) {
        guard isWordActive, currentWordSessionToken == sessionToken else { return }

        let nsError = error as NSError
        // 216 = cancelled (normal), 1110 = timeout (60s limit)
        if nsError.code == 1110 {
            // 60s limit hit — safely re-open recognition request only if word & session remain active
            guard self.isSessionActive, self.isEngineReady, self.isWordActive,
                  self.currentWordSessionToken == sessionToken else { return }
            self.bufferRelay.detachAndEnd()
            self.activeTask?.cancel()
            self.activeTask = nil
            self.activeRequest = nil
            #if targetEnvironment(simulator) || os(macOS)
            // Simulator stub
            #else
            self.startRecognitionRequest(
                targetLemma: targetLemma,
                contextualPhrases: contextualPhrases,
                sessionToken: sessionToken
            )
            #endif
        } else if nsError.code != 216 && nsError.code != 203 && nsError.code != 301 {
            self.onError?(error)
        }
    }

    func startRecognitionRequest(
        targetLemma: String,
        contextualPhrases: [String],
        sessionToken: UUID
    ) {
        guard let recognizer = resolveSpeechRecognizer(), recognizer.isAvailable else {
            onError?(SpeechCaptureError.recognizerUnavailable)
            return
        }

        let request = buildRecognitionRequest(
            targetLemma: targetLemma,
            contextualPhrases: contextualPhrases
        )

        self.activeRequest = request
        self.bufferRelay.setRequest(request)

        // Reset throttle timestamp for new word
        throttleLock.lock()
        lastDispatchTime = 0
        throttleLock.unlock()

        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            // Error handling — always dispatch immediately
            if let error {
                LessonPerformanceDiagnostics.error("speech.recognition", error: error)
                Task { @MainActor [weak self] in
                    self?.handleRecognitionTaskError(
                        error,
                        targetLemma: targetLemma,
                        contextualPhrases: contextualPhrases,
                        sessionToken: sessionToken
                    )
                }
                return
            }

            guard let result else { return }
            let spoken = result.bestTranscription.formattedString

            Task { @MainActor [weak self] in
                guard let self,
                      self.isWordActive,
                      self.currentWordSessionToken == sessionToken,
                      !self.hasReportedFirstRecognitionResult else { return }
                self.hasReportedFirstRecognitionResult = true
                LessonPerformanceDiagnostics.event("SpeechFirstRecognitionResult")
            }

            // Check match first — always dispatch match detection immediately
            let isMatch = ReflexSpeechMatcher.isReflexMatch(
                spokenText: spoken,
                targetLemma: targetLemma
            )

            if isMatch {
                // Match found — dispatch immediately, bypass throttle
                Task { @MainActor [weak self] in
                    guard let self,
                          self.isWordActive,
                          self.currentWordSessionToken == sessionToken else { return }
                    self.liveTranscript = spoken
                    self.onTranscriptUpdate?(spoken)
                    self.onMatchDetected?(targetLemma)
                }
                return
            }

            // Throttle non-match partial results to reduce MainActor pressure.
            // SFSpeechRecognizer fires 30-50 callbacks/sec; we cap UI updates at ~7/sec.
            let isFinal = result.isFinal
            let now = CFAbsoluteTimeGetCurrent()
            self.throttleLock.lock()
            let elapsed = now - self.lastDispatchTime
            let shouldDispatch = isFinal || (elapsed >= self.throttleInterval)
            if shouldDispatch {
                self.lastDispatchTime = now
            }
            self.throttleLock.unlock()

            guard shouldDispatch else { return }

            Task { @MainActor [weak self] in
                guard let self,
                      self.isWordActive,
                      self.currentWordSessionToken == sessionToken else { return }
                self.liveTranscript = spoken
                self.onTranscriptUpdate?(spoken)
            }
        }

        self.activeTask = task
    }
    #endif
}
