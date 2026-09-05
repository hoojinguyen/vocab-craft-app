import CraftUIKit
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
    public var speechState: CraftSpeechState = .idle
    public var permissionNotice: ReflexPermissionNotice?
    public private(set) var hasPresentedPermissionNotice: Bool = false
    public var isPermissionNoticePresented: Bool {
        get { permissionNotice != nil }
        set {
            if !newValue && permissionNotice != nil {
                dismissPermissionNotice()
            }
        }
    }

    public func dismissPermissionNotice() {
        permissionNotice = nil
        isPermissionNoticePresented = false
        if phase == .drilling && cardPhase == .activeCountdown {
            wordStartTime = Date()
            startStopwatch()
        }
    }
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

    public var currentHandler: ReflexModeHandlerProtocol {
        ReflexModeHandlerFactory.handler(for: selectedMode)
    }

    let speechEngine: ReflexSpeechEngineProtocol
    let ttsService: TextToSpeechProtocol
    let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    let soundEffectService: SoundEffectServiceProtocol

    private var countdownTask: Task<Void, Never>?
    private var hintTasks: [Task<Void, Never>] = []
    private var timeoutTimerTask: Task<Void, Never>?
    private var advanceTask: Task<Void, Never>?
    private var reviewAudioTask: Task<Void, Never>?
    private var speechStartTask: Task<Void, Never>?
    private var wordGeneration: UInt = 0
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
        let limit = currentHandler.timeLimitSeconds * 1000.0
        guard limit > 0 else { return 0 }
        return max(0.0, min(1.0, 1.0 - Double(elapsedTimeMs) / limit))
    }

    public var timerStage: ReflexBlitzTimerStage {
        let limit = currentHandler.timeLimitSeconds * 1000.0
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
        speechStartTask?.cancel()
        speechStartTask = nil
        wordGeneration &+= 1
        for task in hintTasks {
            task.cancel()
        }
        hintTasks.removeAll()
        timeoutTimerTask?.cancel()
        reviewAudioTask?.cancel()
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

// MARK: - Stopwatch & Timer Management

extension ReflexBlitzViewModel {
    private func startStopwatch() {
        cancelActiveTimers()
        scheduleHintTimers()
        scheduleTimeoutTimer()
    }

    private func scheduleHintTimers() {
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

    private func scheduleTimeoutTimer() {
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

// MARK: - Answer Submission & Response Handling

extension ReflexBlitzViewModel {
    public func selectOption(_ option: ReflexBlitzOption) {
        guard phase == .drilling, cardPhase == .activeCountdown, let word = currentWord else { return }
        cancelActiveTimers()

        let isCorrect = currentHandler.validateOption(option)
        currentAttemptIsCorrect = isCorrect
        let responseMs = calculateResponseTimeMs()

        recordAttempt(
            word: word,
            isCorrect: isCorrect,
            responseTimeMs: responseMs,
            selectedOption: option.text,
            typedText: nil,
            recognizedSpoken: nil,
            isTimeout: false
        )

        if currentHandler.shouldSpeakOnReviewFlip {
            ttsService.speak(text: word.lemma, rate: currentHandler.reviewSpeechRate, locale: "en-US")
        }
    }

    public func submitTypingAnswer(_ text: String) {
        guard phase == .drilling, cardPhase == .activeCountdown, let word = currentWord else { return }
        let validation = currentHandler.validateTyping(input: text, targetLemma: word.lemma)
        guard case .evaluated(let isCorrect, let cleanInput) = validation else { return }

        cancelActiveTimers()
        currentAttemptIsCorrect = isCorrect
        let responseMs = calculateResponseTimeMs()

        recordAttempt(
            word: word,
            isCorrect: isCorrect,
            responseTimeMs: responseMs,
            selectedOption: nil,
            typedText: cleanInput,
            recognizedSpoken: nil,
            isTimeout: false
        )

        if currentHandler.shouldSpeakOnReviewFlip {
            scheduleReviewSpeech(for: word.lemma, delayMs: currentHandler.reviewSpeechDelayMs, rate: currentHandler.reviewSpeechRate)
        }
    }

    public func handleSpokenMatch(_ matchedLemma: String) {
        guard phase == .drilling, cardPhase == .activeCountdown, !currentAttemptIsCorrect, let word = currentWord else { return }
        guard currentHandler.validateSpokenMatch(spokenText: matchedLemma, targetLemma: word.lemma) else { return }

        cancelActiveTimers()
        currentAttemptIsCorrect = true
        let responseMs = calculateResponseTimeMs()

        currentHandler.onWordCompleted(speechEngine: speechEngine)

        recordAttempt(
            word: word,
            isCorrect: true,
            responseTimeMs: responseMs,
            selectedOption: nil,
            typedText: nil,
            recognizedSpoken: matchedLemma,
            isTimeout: false
        )

        if currentHandler.shouldSpeakOnReviewFlip {
            scheduleReviewSpeech(for: word.lemma, delayMs: currentHandler.reviewSpeechDelayMs, rate: currentHandler.reviewSpeechRate)
        }
    }

    private func calculateResponseTimeMs() -> Int {
        if elapsedTimeMs > 0 {
            return elapsedTimeMs
        } else if let start = wordStartTime {
            let responseMs = max(0, Int(Date().timeIntervalSince(start) * 1000))
            self.elapsedTimeMs = responseMs
            return responseMs
        } else {
            return 0
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func recordAttempt(
        word: ReflexBlitzWordItem,
        isCorrect: Bool,
        responseTimeMs: Int,
        selectedOption: String?,
        typedText: String?,
        recognizedSpoken: String?,
        isTimeout: Bool
    ) {
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

        let attempt = ReflexBlitzAttempt(
            wordId: word.id,
            lemma: word.lemma,
            pos: word.pos,
            ipa: word.ipa,
            definitionVi: word.definitionVi,
            responseTimeMs: responseTimeMs,
            usedHint: showHint,
            isCorrect: isCorrect
        )
        attempts.append(attempt)

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id),
                isCorrect: isCorrect,
                responseTimeMs: responseTimeMs
            )
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: isCorrect,
                responseTimeMs: responseTimeMs,
                isTimeout: isTimeout,
                selectedOption: selectedOption,
                typedText: typedText,
                recognizedSpoken: recognizedSpoken
            ))
        }
    }

    func scheduleReviewSpeech(for text: String, delayMs: Int, rate: Float) {
        reviewAudioTask?.cancel()
        reviewAudioTask = Task { @MainActor [weak self] in
            if delayMs > 0 {
                try? await Task.sleep(for: .milliseconds(delayMs))
            }
            guard let self, self.cardPhase != .activeCountdown else { return }
            self.ttsService.speak(text: text, rate: rate, locale: "en-US")
        }
    }
}

// MARK: - Reflex Permission Notice

public struct ReflexPermissionNotice: Equatable, Sendable {
    public let title: String
    public let message: String
    public let settingsActionTitle: String
    public let dismissActionTitle: String

    public init(
        title: String = AppStrings.Lesson.permissionTitleText,
        message: String = AppStrings.Lesson.permissionMessageText,
        settingsActionTitle: String = AppStrings.Lesson.permissionSettingsActionText,
        dismissActionTitle: String = AppStrings.Lesson.permissionDismissActionText
    ) {
        self.title = title
        self.message = message
        self.settingsActionTitle = settingsActionTitle
        self.dismissActionTitle = dismissActionTitle
    }
}
