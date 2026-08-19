import Foundation
import Observation

public enum ReflexBlitzPhase: Equatable, Sendable {
    case countdown
    case drilling
    case timeoutRevealing
    case summary
}

public enum ReflexBlitzTimerStage: Equatable, Sendable {
    case steady
    case warning
    case urgent
}

@MainActor
@Observable
public final class ReflexBlitzViewModel {
    public var phase: ReflexBlitzPhase = .countdown
    public var countdownCount: Int = 3
    public var words: [ReflexBlitzWordItem] = []
    public var currentWordIndex: Int = 0
    public var elapsedTimeMs: Int = 0
    public var showHint: Bool = false
    public var comboStreak: Int = 0
    public var maxComboStreak: Int = 0
    public var currentAttemptIsCorrect: Bool = false
    public var isKeyboardFallbackActive: Bool = false {
        didSet {
            if isKeyboardFallbackActive {
                continuousSpeechService.pauseListening()
            } else {
                continuousSpeechService.resumeListening()
            }
        }
    }
    public var liveTranscript: String = ""
    public var sessionSummary: ReflexBlitzSessionSummary?
    public var attempts: [ReflexBlitzAttempt] = []

    private let continuousSpeechService: ContinuousReflexSpeechProtocol
    private let ttsService: TextToSpeechProtocol
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    private let soundEffectService: SoundEffectServiceProtocol

    private var countdownTask: Task<Void, Never>?
    private var sessionTimerTask: Task<Void, Never>?
    private var advanceTask: Task<Void, Never>?
    private var wordStartTime: Date?

    public var currentWord: ReflexBlitzWordItem? {
        guard currentWordIndex >= 0 && currentWordIndex < words.count else { return nil }
        return words[currentWordIndex]
    }

    public var progressFraction: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(words.count)
    }

    public var fractionRemaining: Double {
        max(0.0, min(1.0, 1.0 - Double(elapsedTimeMs) / 6000.0))
    }

    public var timerStage: ReflexBlitzTimerStage {
        if elapsedTimeMs < 3500 {
            return .steady
        } else if elapsedTimeMs < 5000 {
            return .warning
        } else {
            return .urgent
        }
    }

    public init(
        words: [ReflexBlitzWordItem],
        continuousSpeechService: ContinuousReflexSpeechProtocol,
        ttsService: TextToSpeechProtocol,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol,
        soundEffectService: SoundEffectServiceProtocol = SoundEffectService.shared
    ) {
        self.words = words
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

    public func startCountdown() {
        countdownTask?.cancel()
        sessionTimerTask?.cancel()
        advanceTask?.cancel()

        phase = .countdown
        countdownCount = 3
        let contextualPhrases = words.flatMap { [$0.lemma, $0.exampleSentenceEn] }
        continuousSpeechService.startSession(contextualPhrases: contextualPhrases)

        countdownTask = Task { @MainActor [weak self] in
            for i in stride(from: 3, through: 1, by: -1) {
                guard let self = self, !Task.isCancelled else { return }
                self.countdownCount = i
                try? await Task.sleep(for: .seconds(1))
            }
            guard let self = self, !Task.isCancelled else { return }
            self.beginDrilling()
        }
    }

    public func beginSessionDirectly() {
        countdownTask?.cancel()
        let contextualPhrases = words.flatMap { [$0.lemma, $0.exampleSentenceEn] }
        continuousSpeechService.startSession(contextualPhrases: contextualPhrases)
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
        guard index < words.count else {
            finishSession()
            return
        }
        currentWordIndex = index
        let word = words[index]
        showHint = false
        currentAttemptIsCorrect = false
        elapsedTimeMs = 0
        liveTranscript = ""
        wordStartTime = Date()
        phase = .drilling

        continuousSpeechService.setTargetWord(
            lemma: word.lemma,
            contextualPhrases: [word.exampleSentenceEn]
        )

        startStopwatch()
    }

    public func loadWordForTesting(at index: Int) {
        loadWord(at: index)
    }

    private func startStopwatch() {
        sessionTimerTask?.cancel()
        sessionTimerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self = self, self.phase == .drilling, let start = self.wordStartTime else { break }
                let elapsed = Int(Date().timeIntervalSince(start) * 1000)
                self.elapsedTimeMs = elapsed

                if elapsed >= 3500 && !self.showHint {
                    self.showHint = true
                }

                if elapsed >= 6000 {
                    self.handleTimeout()
                    break
                }
            }
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
        if ms >= 3500 {
            self.showHint = true
        }
        if ms >= 6000 && phase == .drilling {
            handleTimeout()
        }
    }

    public func handleSpokenMatch(_ matchedLemma: String) {
        guard phase == .drilling, !currentAttemptIsCorrect, let word = currentWord,
              word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == matchedLemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        else { return }

        sessionTimerTask?.cancel()
        currentAttemptIsCorrect = true
        soundEffectService.playSuccessChime()
        comboStreak += 1
        if comboStreak > maxComboStreak {
            maxComboStreak = comboStreak
        }

        let attempt = ReflexBlitzAttempt(
            wordId: word.id,
            lemma: word.lemma,
            pos: word.pos,
            ipa: word.ipa,
            definitionVi: word.definitionVi,
            responseTimeMs: elapsedTimeMs,
            usedHint: showHint,
            isCorrect: true
        )
        attempts.append(attempt)

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id),
                isCorrect: true,
                responseTimeMs: self.elapsedTimeMs
            )
        }

        advanceTask?.cancel()
        advanceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(1000))
            guard let self = self, self.phase == .drilling, !Task.isCancelled else { return }
            self.loadWord(at: self.currentWordIndex + 1)
        }
    }

    public func handleTimeout() {
        guard phase == .drilling, let word = currentWord else { return }
        sessionTimerTask?.cancel()
        phase = .timeoutRevealing
        comboStreak = 0

        let attempt = ReflexBlitzAttempt(
            wordId: word.id,
            lemma: word.lemma,
            pos: word.pos,
            ipa: word.ipa,
            definitionVi: word.definitionVi,
            responseTimeMs: 6000,
            usedHint: true,
            isCorrect: false
        )
        attempts.append(attempt)

        continuousSpeechService.pauseListening()

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id),
                isCorrect: false,
                responseTimeMs: 6000
            )
        }

        advanceTask?.cancel()
        advanceTask = Task { @MainActor [weak self] in
            await self?.ttsService.speakAsync(text: word.lemma, rate: 0.5, locale: "en-US")
            try? await Task.sleep(for: .milliseconds(300))
            guard let self = self, !Task.isCancelled else { return }
            self.continuousSpeechService.resumeListening()
            guard self.phase == .timeoutRevealing else { return }
            self.loadWord(at: self.currentWordIndex + 1)
        }
    }

    public func submitKeyboardInput(_ text: String) {
        guard phase == .drilling, !currentAttemptIsCorrect, let word = currentWord else { return }
        let cleanInput = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanLemma = word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleanInput == cleanLemma {
            handleSpokenMatch(word.lemma)
        }
    }

    public func toggleKeyboardFallback() {
        isKeyboardFallbackActive.toggle()
    }

    public func finishSession() {
        countdownTask?.cancel()
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
        sessionTimerTask?.cancel()
        advanceTask?.cancel()
        continuousSpeechService.stopSession()
        ttsService.stop()
    }
}
