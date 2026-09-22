import CraftUIKit
import Foundation

// MARK: - Stopwatch & Timer Management
extension ReflexBlitzViewModel {
    func startStopwatch() {
        cancelActiveTimers()
        scheduleHintTimers()
        scheduleTimeoutTimer()
    }

    func scheduleHintTimers(offsetMs: Int = 0) {
        let handler = currentHandler
        for milestone in handler.hintMilestones where milestone.delayMs > offsetMs {
            let delay = milestone.delayMs - offsetMs
            let task = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(delay))
                guard !Task.isCancelled, let self, self.phase == .drilling, !self.isPaused, self.cardPhase == .activeCountdown, let word = self.currentWord else { return }
                self.hintStage = max(self.hintStage, milestone.stage)
                handler.onHintStageReached(stage: milestone.stage, word: word, ttsService: self.ttsService)
            }
            hintTasks.append(task)
        }
    }

    func scheduleTimeoutTimer(remainingSeconds: Double? = nil) {
        let limitSeconds = remainingSeconds ?? currentHandler.timeLimitSeconds
        timeoutTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(limitSeconds))
            guard !Task.isCancelled, let self, self.phase == .drilling, !self.isPaused, self.cardPhase == .activeCountdown else { return }

            if self.selectedMode == .speaking {
                // Grace period: stop mic input but let recognition pipeline
                // process in-flight audio buffers.
                self.speechEngine.finalizeWordAudio()
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled, self.phase == .drilling, !self.isPaused, self.cardPhase == .activeCountdown else { return }
            }

            self.handleTimeout()
        }
    }

    public func pauseCurrentDrill() {
        guard phase == .drilling, cardPhase == .activeCountdown, !isPaused else { return }
        isPaused = true
        cancelActiveTimers()
        if let start = wordStartTime {
            let elapsed = Int(Date().timeIntervalSince(start) * 1000)
            elapsedTimeMs = min(Int(currentHandler.timeLimitSeconds * 1000), elapsedTimeMs + elapsed)
        }
        wordStartTime = nil
        if selectedMode == .speaking {
            speechEngine.endWord()
            speechState = .idle
        }
    }

    public func resumeCurrentDrill() {
        guard phase == .drilling, cardPhase == .activeCountdown, isPaused else { return }
        isPaused = false
        let totalLimitMs = Int(currentHandler.timeLimitSeconds * 1000)
        let remainingMs = max(500, totalLimitMs - elapsedTimeMs)
        let remainingSeconds = Double(remainingMs) / 1000.0

        wordStartTime = Date().addingTimeInterval(-Double(elapsedTimeMs) / 1000.0)

        cancelActiveTimers()
        scheduleHintTimers(offsetMs: elapsedTimeMs)
        scheduleTimeoutTimer(remainingSeconds: remainingSeconds)

        if selectedMode == .speaking, let currentWord {
            speechState = .preparing
            let currentGeneration = wordGeneration
            let targetLemma = currentWord.lemma
            let contextualPhrases = [currentWord.lemma, currentWord.exampleSentenceEn]

            if !speechEngine.isSessionActive {
                let allPhrases = words.map(\.lemma)
                speechEngine.startSession(contextualPhrases: allPhrases, lazy: true)
            }

            speechStartTask = Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await self.speechEngine.startListening(
                        targetLemma: targetLemma,
                        contextualPhrases: contextualPhrases
                    )
                    try Task.checkCancellation()
                    guard self.wordGeneration == currentGeneration,
                          self.phase == .drilling,
                          !self.isPaused,
                          case .activeCountdown = self.cardPhase else {
                        if self.speechState == .preparing && self.wordGeneration == currentGeneration {
                            self.speechState = .idle
                        }
                        return
                    }
                    self.speechState = .listening()
                } catch {
                    if self.wordGeneration == currentGeneration {
                        self.speechState = .idle
                    }
                }
            }
        }
    }

    public func speakLemma(_ lemma: String) {
        ttsService.speak(text: lemma, rate: 1.0, locale: "en-US")
    }

    public func speakCurrentWord() {
        guard let word = currentWord else { return }
        speakLemma(word.lemma)
    }

    public func simulateElapsedTime(ms: Int) {
        self.elapsedTimeMs = ms
        let computed = currentHandler.hintStage(forElapsedTimeMs: ms)
        if computed > self.hintStage {
            self.hintStage = computed
        }
        let limitMs = Int(currentHandler.timeLimitSeconds * 1000)
        if ms >= limitMs && phase == .drilling && cardPhase == .activeCountdown {
            handleTimeout()
        }
    }
}
