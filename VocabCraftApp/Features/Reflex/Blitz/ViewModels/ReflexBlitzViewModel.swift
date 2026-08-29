import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class ReflexBlitzViewModel {
    public var phase: ReflexBlitzPhase = .modeSelection
    public var selectedMode: ReflexBlitzMode = .speaking
    public var cardPhase: ReflexCardPhase = .activeCountdown
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
    public var isKeyboardFallbackActive: Bool = false {
        didSet {
            if isKeyboardFallbackActive {
                continuousSpeechService.pauseListening()
            } else if selectedMode == .speaking && cardPhase == .activeCountdown {
                continuousSpeechService.resumeListening()
            }
        }
    }
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

    private let continuousSpeechService: ContinuousReflexSpeechProtocol
    private let ttsService: TextToSpeechProtocol
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    private let soundEffectService: SoundEffectServiceProtocol

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
            continuousSpeechService: ContinuousReflexSpeechService(),
            ttsService: TextToSpeechService(),
            evaluateSRSUseCase: EvaluateSRSUseCase(srsRepository: SRSRepositoryImpl()),
            soundEffectService: SoundEffectService.shared
        )
    }

    public init(
        words: [ReflexBlitzWordItem] = ReflexBlitzWordItem.defaultStarterWords,
        weeklyPracticedCount: Int = 0,
        weakWordsCount: Int = 0,
        averageSpeedSeconds: Double = 0.0,
        continuousSpeechService: ContinuousReflexSpeechProtocol,
        ttsService: TextToSpeechProtocol,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol,
        soundEffectService: SoundEffectServiceProtocol = SoundEffectService.shared
    ) {
        self.words = words
        self.weeklyPracticedCount = weeklyPracticedCount
        self.weakWordsCount = weakWordsCount
        self.averageSpeedSeconds = averageSpeedSeconds
        self.continuousSpeechService = continuousSpeechService
        self.ttsService = ttsService
        self.evaluateSRSUseCase = evaluateSRSUseCase
        self.soundEffectService = soundEffectService
        setupSpeechServiceBindings()
    }

    private func setupSpeechServiceBindings() {
        continuousSpeechService.onMatchDetected = { [weak self] matched in
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self?.handleSpokenMatch(matched)
                }
            } else {
                Task { @MainActor [weak self] in
                    self?.handleSpokenMatch(matched)
                }
            }
        }

        continuousSpeechService.onTranscriptUpdate = { [weak self] transcript in
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self?.liveTranscript = transcript
                }
            } else {
                Task { @MainActor [weak self] in
                    self?.liveTranscript = transcript
                }
            }
        }

        continuousSpeechService.onError = { [weak self] error in
            print("[ReflexBlitzViewModel] Continuous speech error: \(error.localizedDescription)")
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self?.isKeyboardFallbackActive = true
                }
            } else {
                Task { @MainActor [weak self] in
                    self?.isKeyboardFallbackActive = true
                }
            }
        }
    }

    public func selectMode(_ mode: ReflexBlitzMode) {
        self.selectedMode = mode
        startCountdown()
    }

    public func startDrillSession(mode: ReflexBlitzMode, words: [ReflexBlitzWordItem]? = nil) {
        if let words, !words.isEmpty {
            self.words = words
        }
        self.selectedMode = mode
        beginSessionDirectly()
    }

    public func skip() {
        handleTimeout()
    }

    public func startCountdown() {
        countdownTask?.cancel()
        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()
        advanceTask?.cancel()

        phase = .countdown
        countdownCount = 3
        if selectedMode == .speaking {
            let contextualPhrases = words.flatMap { [$0.lemma, $0.exampleSentenceEn] }
            continuousSpeechService.startSession(contextualPhrases: contextualPhrases)
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
        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()
        if selectedMode == .speaking {
            let contextualPhrases = words.flatMap { [$0.lemma, $0.exampleSentenceEn] }
            continuousSpeechService.startSession(contextualPhrases: contextualPhrases)
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

    private func loadWord(at index: Int) {
        advanceTask?.cancel()
        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()
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

        if selectedMode == .multipleChoice || selectedMode == .listening {
            currentOptions = word.generateOptions(mode: selectedMode, allPool: words)
        } else {
            currentOptions = []
        }

        if selectedMode == .speaking {
            continuousSpeechService.setTargetWord(
                lemma: word.lemma,
                contextualPhrases: [word.exampleSentenceEn]
            )
            if !isKeyboardFallbackActive {
                continuousSpeechService.resumeListening()
            }
        } else {
            continuousSpeechService.pauseListening()
        }

        if selectedMode == .listening {
            ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")
        }

        startStopwatch()
    }

    public func loadWordForTesting(at index: Int) {
        loadWord(at: index)
    }

    private func startStopwatch() {
        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()

        if selectedMode == .multipleChoice {
            hintTimerTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(1600))
                guard let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
                self.hintStage = max(self.hintStage, 1)
            }
            hintStage2Task = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(2500))
                guard let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
                self.hintStage = max(self.hintStage, 2)
            }
            hintStage3Task = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(3400))
                guard let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
                self.hintStage = max(self.hintStage, 3)
            }
        } else {
            let hintSeconds = selectedMode == .typing ? 4.5 : 3.5
            hintTimerTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(hintSeconds))
                guard let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
                self.hintStage = 1
            }
        }

        let limitSeconds = selectedMode.timeLimitSeconds
        timeoutTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(limitSeconds))
            guard let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
            self.handleTimeout()
        }
    }

    public func speakLemma(_ lemma: String) {
        ttsService.speak(text: lemma, rate: 0.5, locale: "en-US")
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
        } else {
            let hintThreshold = selectedMode == .typing ? 4500 : 3500
            if ms >= hintThreshold {
                self.hintStage = 1
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
        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()

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
                selectedOption: option.text, typedText: nil, recognizedSpoken: nil
            ))
        }

        if selectedMode != .listening {
            ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")
        }
    }

    public func submitTypingAnswer(_ text: String) {
        guard phase == .drilling, cardPhase == .activeCountdown, let word = currentWord else { return }
        let cleanInput = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanLemma = word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard cleanInput == cleanLemma else { return }

        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()
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

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: true, responseTimeMs: responseMs, isTimeout: false,
                selectedOption: nil, typedText: word.lemma, recognizedSpoken: nil
            ))
        }
    }

    public func submitKeyboardInput(_ text: String) {
        submitTypingAnswer(text)
    }

    public func handleSpokenMatch(_ matchedLemma: String) {
        guard phase == .drilling, cardPhase == .activeCountdown, !currentAttemptIsCorrect, let word = currentWord else { return }
        let cleanMatched = matchedLemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanLemma = word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanMatched == cleanLemma || cleanMatched.contains(cleanLemma) else { return }

        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()
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

        continuousSpeechService.pauseListening()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: true, responseTimeMs: responseMs, isTimeout: false,
                selectedOption: nil, typedText: nil, recognizedSpoken: matchedLemma
            ))
        }
    }

    public func submitSpeakingResult(isCorrect: Bool, responseTimeMs: Int) {
        guard phase == .drilling, cardPhase == .activeCountdown, let word = currentWord else { return }
        self.elapsedTimeMs = responseTimeMs
        if isCorrect {
            handleSpokenMatch(word.lemma)
        } else {
            handleTimeout()
        }
    }

    public func handleTimeout() {
        guard phase == .drilling, cardPhase == .activeCountdown, let word = currentWord else { return }
        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()
        currentAttemptIsCorrect = false
        comboStreak = 0
        soundEffectService.playIncorrectChime()

        let timeLimitMs = elapsedTimeMs > 0 ? elapsedTimeMs : Int(selectedMode.timeLimitSeconds * 1000)
        self.elapsedTimeMs = timeLimitMs
        let attempt = ReflexBlitzAttempt(
            wordId: word.id, lemma: word.lemma, pos: word.pos, ipa: word.ipa,
            definitionVi: word.definitionVi, responseTimeMs: timeLimitMs,
            usedHint: true, isCorrect: false
        )
        attempts.append(attempt)

        continuousSpeechService.pauseListening()

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id), isCorrect: false, responseTimeMs: timeLimitMs
            )
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: false, responseTimeMs: timeLimitMs, isTimeout: true,
                selectedOption: nil, typedText: nil, recognizedSpoken: nil
            ))
        }

        if selectedMode != .listening {
            ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")
        }
    }
}

// MARK: - Session Control & Deep Link Configuration

extension ReflexBlitzViewModel {
    public func advanceToNextWord() {
        guard phase == .drilling else { return }
        let nextIndex = currentWordIndex + 1
        if nextIndex < words.count {
            loadWord(at: nextIndex)
        } else {
            finishSession()
        }
    }

    public func toggleKeyboardFallback() {
        isKeyboardFallbackActive.toggle()
    }

    public func finishSession() {
        countdownTask?.cancel()
        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()
        advanceTask?.cancel()
        continuousSpeechService.stopSession()
        sessionSummary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: maxComboStreak)
        phase = .summary
    }

    public func reDrillWeakWords() {
        guard let summary = sessionSummary, !summary.weakWordAttempts.isEmpty else { return }
        let weakWordIds = Set(summary.weakWordAttempts.map { $0.wordId })
        let reDrillItems = words.filter { weakWordIds.contains($0.id) }
        guard !reDrillItems.isEmpty else { return }
        self.words = reDrillItems
        startCountdown()
    }

    public func cancelSession() {
        countdownTask?.cancel()
        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()
        advanceTask?.cancel()
        continuousSpeechService.stopSession()
        ttsService.stop()
    }

    public func applyReviewConfig(_ config: ReflexBlitzDeepLinkConfig) {
        countdownTask?.cancel()
        hintTimerTask?.cancel()
        hintStage2Task?.cancel()
        hintStage3Task?.cancel()
        timeoutTimerTask?.cancel()
        sessionTimerTask?.cancel()
        advanceTask?.cancel()

        self.selectedMode = config.mode
        self.phase = config.phase
        self.comboStreak = config.combo
        self.maxComboStreak = max(config.combo, 4)
        self.hintStage = config.showHint ? 1 : 0
        self.currentWordIndex = 0

        if config.phase == .summary {
            let mockAttempts = [
                ReflexBlitzAttempt(wordId: 1, lemma: "habit", pos: "n.", ipa: "/ˈhæb.ɪt/", definitionVi: "Thói quen", responseTimeMs: 1400, usedHint: false, isCorrect: true),
                ReflexBlitzAttempt(wordId: 2, lemma: "improve", pos: "v.", ipa: "/ɪmˈpruːv/", definitionVi: "Cải thiện, nâng cao", responseTimeMs: 2100, usedHint: false, isCorrect: true),
                ReflexBlitzAttempt(wordId: 3, lemma: "focus", pos: "v.", ipa: "/ˈfoʊ.kəs/", definitionVi: "Tập trung", responseTimeMs: 4200, usedHint: true, isCorrect: true),
                ReflexBlitzAttempt(wordId: 7, lemma: "challenge", pos: "n.", ipa: "/ˈtʃæl.ɪndʒ/", definitionVi: "Thử thách", responseTimeMs: 6000, usedHint: true, isCorrect: false)
            ]
            self.sessionSummary = ReflexBlitzSessionSummary.create(from: mockAttempts, maxCombo: config.combo)
            return
        }

        guard let word = currentWord else { return }

        if config.mode == .multipleChoice || config.mode == .listening {
            currentOptions = word.generateOptions(mode: config.mode, allPool: words)
        } else {
            currentOptions = []
        }

        if config.state == "reviewedCorrect" {
            currentAttemptIsCorrect = true
            let correctOpt = currentOptions.first(where: { $0.isCorrect })?.text ?? word.lemma
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: true,
                responseTimeMs: 1400,
                isTimeout: false,
                selectedOption: correctOpt,
                typedText: word.lemma,
                recognizedSpoken: word.lemma
            ))
        } else if config.state == "reviewedIncorrect" {
            currentAttemptIsCorrect = false
            let wrongOpt = currentOptions.first(where: { !$0.isCorrect })?.text ?? "other"
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: 3500,
                isTimeout: false,
                selectedOption: wrongOpt,
                typedText: "habbit",
                recognizedSpoken: "rabbit"
            ))
        } else if config.state == "timeout" {
            currentAttemptIsCorrect = false
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: Int(config.mode.timeLimitSeconds * 1000),
                isTimeout: true,
                selectedOption: nil,
                typedText: nil,
                recognizedSpoken: nil
            ))
        } else {
            cardPhase = .activeCountdown
            elapsedTimeMs = 1200
        }
    }
}
