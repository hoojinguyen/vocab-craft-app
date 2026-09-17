import CraftUIKit
import Foundation

// MARK: - Session & Word Preparation
extension ReflexBlitzViewModel {
    public func selectMode(_ mode: ReflexBlitzMode) {
        self.selectedMode = mode
        startCountdown()
    }

    public func startDrillSession(mode: ReflexBlitzMode, words: [ReflexBlitzWordItem]? = nil) {
        cancelAllTasks()
        phase = .countdown
        if let words, !words.isEmpty {
            self.words = words
        }
        self.selectedMode = mode
        let plan = ReflexDrillPlanGenerator.generatePlan(words: self.words, mode: mode)
        self.sessionPlan = plan
        if !plan.items.isEmpty {
            self.words = plan.items.compactMap { $0.word as? ReflexBlitzWordItem }
        }
        beginSessionDirectly()
    }

    public func skip() {
        handleTimeout()
    }

    public func startCountdown() {
        cancelAllTasks()
        phase = .countdown

        let plan = ReflexDrillPlanGenerator.generatePlan(words: words, mode: selectedMode)
        self.sessionPlan = plan
        if !plan.items.isEmpty {
            self.words = plan.items.compactMap { $0.word as? ReflexBlitzWordItem }
        }

        countdownCount = 3
        if selectedMode == .speaking {
            let contextualPhrases = words.map(\.lemma)
            speechEngine.startSession(contextualPhrases: contextualPhrases, lazy: true)
        }

        countdownTask = Task { @MainActor [weak self] in
            for i in stride(from: 3, through: 1, by: -1) {
                guard let self, !Task.isCancelled else { return }
                self.countdownCount = i
                try? await Task.sleep(for: .seconds(1))
            }
            guard let self, !Task.isCancelled else { return }
            self.beginDrilling()
        }
    }

    public func beginSessionDirectly() {
        countdownTask?.cancel()
        cancelActiveTimers()
        phase = .countdown
        if sessionPlan == nil || sessionPlan?.items.count != words.count || sessionPlan?.mode != selectedMode {
            let plan = ReflexDrillPlanGenerator.generatePlan(words: words, mode: selectedMode)
            self.sessionPlan = plan
            if !plan.items.isEmpty {
                self.words = plan.items.compactMap { $0.word as? ReflexBlitzWordItem }
            }
        }
        if selectedMode == .speaking {
            let contextualPhrases = words.map(\.lemma)
            speechEngine.startSession(contextualPhrases: contextualPhrases, lazy: true)
        }
        beginDrilling()
    }

    func beginDrilling() {
        phase = .drilling
        currentWordIndex = 0
        comboStreak = 0
        maxComboStreak = 0
        attempts = []
        loadWord(at: 0)
    }

    func loadWord(at index: Int) {
        advanceTask?.cancel()
        cancelActiveTimers()
        guard index < words.count else {
            finishSession()
            return
        }
        currentWordIndex = index
        let word = words[index]
        hintStage = 0
        currentAttemptIsCorrect = false
        cardPhase = .activeCountdown
        elapsedTimeMs = 0
        typingInput = ""
        liveTranscript = ""
        wordStartTime = nil
        phase = .drilling

        if let plan = sessionPlan, index >= 0 && index < plan.items.count {
            self.currentPlanItem = plan.items[index]
        } else {
            self.currentPlanItem = nil
        }

        let prep = currentHandler.prepareWord(
            word: word,
            allWords: words,
            planItem: currentPlanItem,
            ttsService: ttsService,
            speechEngine: speechEngine,
            isKeyboardFallback: false
        )

        self.currentOptions = prep.options
        self.currentClozeStages = prep.clozeStages
        self.currentEliminatedOptionId = prep.eliminatedOptionId
        self.currentHintBadgeText = prep.hintBadgeText

        if selectedMode == .speaking {
            self.speechState = .preparing
            let currentGeneration = self.wordGeneration
            let targetLemma = word.lemma
            let contextualPhrases = [word.lemma, word.exampleSentenceEn]

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
                          self.currentWordIndex == index,
                          self.phase == .drilling,
                          case .activeCountdown = self.cardPhase else {
                        if self.speechState == .preparing && self.wordGeneration == currentGeneration {
                            self.speechState = .idle
                        }
                        return
                    }
                    self.speechState = .listening()
                    if !self.isPermissionNoticePresented {
                        self.wordStartTime = Date()
                        self.startStopwatch()
                    }
                } catch is CancellationError {
                    if self.wordGeneration == currentGeneration && self.speechState == .preparing {
                        self.speechState = .idle
                    }
                } catch let error as SpeechCaptureError where error == .speechRecognitionDenied || error == .microphoneDenied {
                    guard self.wordGeneration == currentGeneration else { return }
                    self.handlePermissionDenied()
                } catch {
                    if self.wordGeneration == currentGeneration {
                        self.speechState = .idle
                        self.handleTimeout()
                    }
                }
            }
        } else {
            self.speechState = .idle
            if !isPermissionNoticePresented {
                self.wordStartTime = Date()
                startStopwatch()
            }
        }
    }

    public func handlePermissionDenied() {
        cancelActiveTimers()
        speechEngine.stopSession()
        speechState = .unavailable
        selectedMode = .typing
        if !hasPresentedPermissionNotice {
            hasPresentedPermissionNotice = true
            permissionNotice = ReflexPermissionNotice()
        }
        if let word = currentWord {
            let prep = currentHandler.prepareWord(
                word: word,
                allWords: words,
                planItem: currentPlanItem,
                ttsService: ttsService,
                speechEngine: speechEngine,
                isKeyboardFallback: true
            )
            self.currentOptions = prep.options
            self.currentClozeStages = prep.clozeStages
            self.currentEliminatedOptionId = prep.eliminatedOptionId
            self.currentHintBadgeText = prep.hintBadgeText
            if !isPermissionNoticePresented {
                self.wordStartTime = Date()
                startStopwatch()
            }
        }
    }

    public func loadWordForTesting(at index: Int) {
        loadWord(at: index)
    }
}
