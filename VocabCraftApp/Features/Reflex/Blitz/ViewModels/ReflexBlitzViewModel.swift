import Foundation
import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
public final class ReflexBlitzViewModel {
    public var phase: ReflexBlitzPhase = .modeSelection
    public var selectedMode: ReflexBlitzMode = .speaking
    public var cardPhase: ReflexCardPhase = .activeCountdown
    public var sessionPlan: ReflexDrillSessionPlan?
    public var currentPlanItem: ReflexDrillPlanItem?
    public var currentClozeStages: ReflexClozeStageSet?
    public var currentEliminatedOptionId: String?
    public var currentHintBadgeText: String = ""
    public var currentOptions: [ReflexBlitzOption] = []
    public var typingInput: String = ""
    public var countdownCount: Int = 3
    public var words: [ReflexBlitzWordItem] = []
    public var currentWordIndex: Int = 0
    public var elapsedTimeMs: Int = 0
    public var hintStage: Int = 0
    public var showHint: Bool { hintStage >= 1 }
    public var comboStreak: Int = 0
    public var maxComboStreak: Int = 0
    public var currentAttemptIsCorrect: Bool = false
    public var liveTranscript: String = ""
    public var sessionSummary: ReflexBlitzSessionSummary?
    public var attempts: [ReflexBlitzAttempt] = []
    public var weeklyPracticedCount: Int = 0
    public var weakWordsCount: Int = 0
    public var averageSpeedSeconds: Double = 0.0

    public var isFeedbackPresented: Bool {
        get {
            if case .reviewed = cardPhase {
                return true
            }
            return false
        }
        set {
            if !newValue && isFeedbackPresented {
                advanceToNextWord()
            }
        }
    }

    let speechEngine: ReflexSpeechEngineProtocol
    let ttsService: TextToSpeechProtocol
    let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    let soundEffectService: SoundEffectServiceProtocol

    private var countdownTask: Task<Void, Never>?
    private var sessionTimerTask: Task<Void, Never>?
    private var hintTimerTask: Task<Void, Never>?
    private var hintStage2Task: Task<Void, Never>?
    private var hintStage3Task: Task<Void, Never>?
    private var timeoutTimerTask: Task<Void, Never>?
    private var advanceTask: Task<Void, Never>?
    public var wordStartTime: Date?

    public var currentWord: ReflexBlitzWordItem? {
        guard currentWordIndex >= 0 && currentWordIndex < words.count else { return nil }
        return words[currentWordIndex]
    }

    public var progressFraction: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(words.count)
    }

    public var fractionRemaining: Double {
        let limit = selectedMode.timeLimitSeconds * 1000.0
        guard limit > 0 else { return 0 }
        return max(0.0, min(1.0, 1.0 - Double(elapsedTimeMs) / limit))
    }

    public var timerStage: ReflexBlitzTimerStage {
        let limit = selectedMode.timeLimitSeconds * 1000.0
        let warningThreshold = limit * (3.5 / 6.0)
        let urgentThreshold = limit * (5.0 / 6.0)
        if Double(elapsedTimeMs) < warningThreshold {
            return .steady
        } else if Double(elapsedTimeMs) < urgentThreshold {
            return .warning
        } else {
            return .urgent
        }
    }

    public convenience init(
        words: [ReflexBlitzWordItem] = ReflexBlitzWordItem.defaultStarterWords,
        weeklyPracticedCount: Int = 0,
        weakWordsCount: Int = 0,
        averageSpeedSeconds: Double = 0.0
    ) {
        self.init(
            words: words,
            weeklyPracticedCount: weeklyPracticedCount,
            weakWordsCount: weakWordsCount,
            averageSpeedSeconds: averageSpeedSeconds,
            ttsService: TextToSpeechService(),
            evaluateSRSUseCase: EvaluateSRSUseCase(srsRepository: SRSRepositoryImpl()),
            soundEffectService: SoundEffectService.shared,
            speechEngine: ResilientReflexSpeechEngine()
        )
    }

    public init(
        words: [ReflexBlitzWordItem] = ReflexBlitzWordItem.defaultStarterWords,
        weeklyPracticedCount: Int = 0,
        weakWordsCount: Int = 0,
        averageSpeedSeconds: Double = 0.0,
        ttsService: TextToSpeechProtocol,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol,
        soundEffectService: SoundEffectServiceProtocol = SoundEffectService.shared,
        speechEngine: ReflexSpeechEngineProtocol? = nil
    ) {
        self.words = words
        self.weeklyPracticedCount = weeklyPracticedCount
        self.weakWordsCount = weakWordsCount
        self.averageSpeedSeconds = averageSpeedSeconds
        self.ttsService = ttsService
        self.evaluateSRSUseCase = evaluateSRSUseCase
        self.soundEffectService = soundEffectService
        self.speechEngine = speechEngine ?? ResilientReflexSpeechEngine()
        setupSpeechEngineBindings()
    }

    private func setupSpeechEngineBindings() {
        speechEngine.onMatchDetected = { [weak self] matched in
            self?.handleSpokenMatch(matched)
        }
        speechEngine.onTranscriptUpdate = { [weak self] transcript in
            self?.liveTranscript = transcript
        }
        speechEngine.onError = { error in
            print("[ReflexBlitzViewModel] Speech engine error: \(error.localizedDescription)")
        }
    }

    func cancelActiveTimers() {
        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()
    }

    func cancelAllTasks() {
        countdownTask?.cancel()
        advanceTask?.cancel()
        cancelActiveTimers()
    }

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
            speechEngine.startSession(contextualPhrases: contextualPhrases)
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
            speechEngine.startSession(contextualPhrases: contextualPhrases)
        }
        beginDrilling()
    }

    private func beginDrilling() {
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
        wordStartTime = Date()
        phase = .drilling

        if let plan = sessionPlan, index >= 0 && index < plan.items.count {
            let planItem = plan.items[index]
            self.currentPlanItem = planItem
            self.currentOptions = planItem.options
            self.currentClozeStages = planItem.clozeStages
            self.currentEliminatedOptionId = planItem.eliminatedOptionId
            self.currentHintBadgeText = planItem.hintBadgeText
        } else {
            self.currentPlanItem = nil
            if selectedMode == .multipleChoice || selectedMode == .listening {
                self.currentOptions = word.generateOptions(mode: selectedMode, allPool: words)
            } else {
                self.currentOptions = []
            }
            self.currentClozeStages = nil
            self.currentEliminatedOptionId = nil
            self.currentHintBadgeText = ""
        }

        if selectedMode == .speaking {
            speechEngine.beginWord(
                targetLemma: word.lemma,
                contextualPhrases: [word.lemma]
            )
        }

        if selectedMode == .listening {
            ttsService.speak(text: word.lemma, rate: 1.0, locale: "en-US")
        }

        startStopwatch()
    }

    public func loadWordForTesting(at index: Int) {
        loadWord(at: index)
    }
}

// MARK: - Stopwatch & Timer Management

extension ReflexBlitzViewModel {
    private func startStopwatch() {
        cancelActiveTimers()
        scheduleHintTimers()
        scheduleTimeoutTimer()
    }

    private func scheduleHintTimers() {
        switch selectedMode {
        case .multipleChoice:
            scheduleMultipleChoiceTimers()
        case .listening:
            scheduleListeningTimers()
        case .typing:
            scheduleTypingTimers()
        case .speaking:
            scheduleSpeakingTimers()
        }
    }

    private func scheduleMultipleChoiceTimers() {
        hintTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(1600))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.hintStage = max(self.hintStage, 1)
        }
        hintStage2Task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(2500))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.hintStage = max(self.hintStage, 2)
        }
        hintStage3Task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(3400))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.hintStage = max(self.hintStage, 3)
        }
    }

    private func scheduleListeningTimers() {
        hintTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(1800))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.hintStage = max(self.hintStage, 1)
            self.speakCurrentWord()
        }
        hintStage2Task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(3000))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.hintStage = max(self.hintStage, 2)
            self.speakCurrentWord()
        }
    }

    private func scheduleTypingTimers() {
        hintTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(2500))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.hintStage = max(self.hintStage, 1)
        }
        hintStage2Task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(4500))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.hintStage = max(self.hintStage, 2)
        }
    }

    private func scheduleSpeakingTimers() {
        hintTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(2500))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.hintStage = max(self.hintStage, 1)
        }
        hintStage2Task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(4000))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.hintStage = max(self.hintStage, 2)
        }
        hintStage3Task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(5000))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.hintStage = max(self.hintStage, 3)
        }
    }

    private func scheduleTimeoutTimer() {
        let limitSeconds = selectedMode.timeLimitSeconds
        timeoutTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(limitSeconds))
            guard !Task.isCancelled, let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }

            if self.selectedMode == .speaking {
                // Grace period: stop mic input but let recognition pipeline
                // process in-flight audio buffers. Words spoken at ~5.3-5.8s
                // have 300-800ms recognition latency that would be lost otherwise.
                self.speechEngine.finalizeWordAudio()
                try? await Task.sleep(for: .milliseconds(500))
                // If match was detected during grace, cardPhase changed → skip timeout
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
        if selectedMode == .multipleChoice {
            if ms >= 1600 { self.hintStage = max(self.hintStage, 1) }
            if ms >= 2500 { self.hintStage = max(self.hintStage, 2) }
            if ms >= 3400 { self.hintStage = max(self.hintStage, 3) }
        } else if selectedMode == .listening {
            if ms >= 1800 { self.hintStage = max(self.hintStage, 1) }
            if ms >= 3000 { self.hintStage = max(self.hintStage, 2) }
        } else if selectedMode == .typing {
            if ms >= 2500 { self.hintStage = max(self.hintStage, 1) }
            if ms >= 4500 { self.hintStage = max(self.hintStage, 2) }
        } else if selectedMode == .speaking {
            if ms >= 5000 {
                self.hintStage = max(self.hintStage, 3)
            } else if ms >= 4000 {
                self.hintStage = max(self.hintStage, 2)
            } else if ms >= 2500 {
                self.hintStage = max(self.hintStage, 1)
            }
        }
        let limitMs = Int(selectedMode.timeLimitSeconds * 1000)
        if ms >= limitMs && phase == .drilling && cardPhase == .activeCountdown {
            handleTimeout()
        }
    }
}

// MARK: - Answer Submission & Response Handling

extension ReflexBlitzViewModel {
    public func selectOption(_ option: ReflexBlitzOption) {
        guard phase == .drilling, cardPhase == .activeCountdown, let word = currentWord else { return }
        cancelActiveTimers()

        let isCorrect = option.isCorrect
        currentAttemptIsCorrect = isCorrect

        if isCorrect {
            soundEffectService.playSuccessChime()
            comboStreak += 1
            if comboStreak > maxComboStreak {
                maxComboStreak = comboStreak
            }
        } else {
            soundEffectService.playIncorrectChime()
            triggerIncorrectHaptic()
            comboStreak = 0
        }

        let responseMs: Int
        if elapsedTimeMs > 0 {
            responseMs = elapsedTimeMs
        } else if let start = wordStartTime {
            responseMs = max(0, Int(Date().timeIntervalSince(start) * 1000))
            self.elapsedTimeMs = responseMs
        } else {
            responseMs = 0
        }

        let attempt = ReflexBlitzAttempt(
            wordId: word.id,
            lemma: word.lemma,
            pos: word.pos,
            ipa: word.ipa,
            definitionVi: word.definitionVi,
            responseTimeMs: responseMs,
            usedHint: showHint,
            isCorrect: isCorrect
        )
        attempts.append(attempt)

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id),
                isCorrect: isCorrect,
                responseTimeMs: responseMs
            )
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: isCorrect,
                responseTimeMs: responseMs,
                isTimeout: false,
                selectedOption: option.text,
                typedText: nil,
                recognizedSpoken: nil
            ))
        }

        if selectedMode != .listening {
            ttsService.speak(text: word.lemma, rate: 1.0, locale: "en-US")
        }
    }

    public func submitTypingAnswer(_ text: String) {
        guard phase == .drilling, cardPhase == .activeCountdown, let word = currentWord else { return }
        let cleanInput = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanInput.isEmpty else { return }

        cancelActiveTimers()
        let isCorrect = cleanInput.lowercased() == word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        currentAttemptIsCorrect = isCorrect

        if isCorrect {
            soundEffectService.playSuccessChime()
            comboStreak += 1
            if comboStreak > maxComboStreak {
                maxComboStreak = comboStreak
            }
        } else {
            soundEffectService.playIncorrectChime()
            triggerIncorrectHaptic()
            comboStreak = 0
        }

        let responseMs: Int
        if elapsedTimeMs > 0 {
            responseMs = elapsedTimeMs
        } else if let start = wordStartTime {
            responseMs = max(0, Int(Date().timeIntervalSince(start) * 1000))
            self.elapsedTimeMs = responseMs
        } else {
            responseMs = 0
        }

        let attempt = ReflexBlitzAttempt(
            wordId: word.id, lemma: word.lemma, pos: word.pos, ipa: word.ipa,
            definitionVi: word.definitionVi, responseTimeMs: responseMs,
            usedHint: showHint, isCorrect: isCorrect
        )
        attempts.append(attempt)

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id), isCorrect: isCorrect, responseTimeMs: responseMs
            )
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: isCorrect, responseTimeMs: responseMs, isTimeout: false,
                selectedOption: nil, typedText: cleanInput, recognizedSpoken: nil
            ))
        }

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self, self.cardPhase != .activeCountdown else { return }
            self.ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")
        }
    }

    public func handleSpokenMatch(_ matchedLemma: String) {
        guard phase == .drilling, cardPhase == .activeCountdown, !currentAttemptIsCorrect, let word = currentWord else { return }
        let cleanMatched = matchedLemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanLemma = word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanMatched == cleanLemma || cleanMatched.contains(cleanLemma) else { return }

        cancelActiveTimers()
        currentAttemptIsCorrect = true
        soundEffectService.playSuccessChime()
        comboStreak += 1
        if comboStreak > maxComboStreak {
            maxComboStreak = comboStreak
        }

        let responseMs: Int
        if elapsedTimeMs > 0 {
            responseMs = elapsedTimeMs
        } else if let start = wordStartTime {
            responseMs = max(0, Int(Date().timeIntervalSince(start) * 1000))
            self.elapsedTimeMs = responseMs
        } else {
            responseMs = 0
        }

        let attempt = ReflexBlitzAttempt(
            wordId: word.id, lemma: word.lemma, pos: word.pos, ipa: word.ipa,
            definitionVi: word.definitionVi, responseTimeMs: responseMs,
            usedHint: showHint, isCorrect: true
        )
        attempts.append(attempt)

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id), isCorrect: true, responseTimeMs: responseMs
            )
        }

        speechEngine.endWord()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: true, responseTimeMs: responseMs, isTimeout: false,
                selectedOption: nil, typedText: nil, recognizedSpoken: matchedLemma
            ))
        }

        // Speak the word after card flip — matching typing/timeout modes
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self, self.cardPhase != .activeCountdown else { return }
            self.ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")
        }
    }
}
