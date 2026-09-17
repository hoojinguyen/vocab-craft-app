import Foundation

// MARK: - Stopwatch & Timer Management
extension ReflexBlitzViewModel {
    func startStopwatch() {
        cancelActiveTimers()
        scheduleHintTimers()
        scheduleTimeoutTimer()
    }

    func scheduleHintTimers() {
        let handler = currentHandler
        for milestone in handler.hintMilestones {
            let task = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(milestone.delayMs))
                guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown, let word = self.currentWord else { return }
                self.hintStage = max(self.hintStage, milestone.stage)
                handler.onHintStageReached(stage: milestone.stage, word: word, ttsService: self.ttsService)
            }
            hintTasks.append(task)
        }
    }

    func scheduleTimeoutTimer() {
        let limitSeconds = currentHandler.timeLimitSeconds
        timeoutTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(limitSeconds))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }

            if self.selectedMode == .speaking {
                // Grace period: stop mic input but let recognition pipeline
                // process in-flight audio buffers.
                self.speechEngine.finalizeWordAudio()
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            }

            self.handleTimeout()
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
