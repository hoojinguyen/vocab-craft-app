import Foundation
import Observation

/// Observable state for the 3-tier productive-recall quick reflex drill.
public struct QuickReflexDrillState: Equatable, Sendable {
    public var phase: QuickReflexPhase = .recallWord
    public var inputMode: QuickReflexInputMode = .voice
    public var visibleHintLevel = 0
    public var maxHintLevel = 0
    public var retryCount = 0
    public var recallWordSucceeded = false
    public var collocationSucceeded = false
    public var produceSentenceSucceeded = false
    public var recallWordTimeMs = 0
    public var collocationTimeMs = 0
    public var produceSentenceTimeMs = 0
    public var shadowPronunciationScore: Double?
    public var isCompleted = false
    public var isCancelled = false
    public var isFinishing = false
    public var isPaused = false
    public var isDeferredAttempt = false
    public var revealedTargetExpression: String?
    public var showsSentenceFrame = false
    public var errorMessage: String?

    // Backward-compatibility accessors
    public var retrieveSucceeded: Bool {
        get { recallWordSucceeded }
        set { recallWordSucceeded = newValue }
    }
    public var useSucceeded: Bool {
        get { produceSentenceSucceeded }
        set { produceSentenceSucceeded = newValue }
    }
    public var retrieveTimeMs: Int {
        get { recallWordTimeMs }
        set { recallWordTimeMs = newValue }
    }
    public var useTimeMs: Int {
        get { produceSentenceTimeMs }
        set { produceSentenceTimeMs = newValue }
    }

    // These presentation fields keep the unchanged legacy sheet source-compatible
    // until its dedicated presentation task replaces the three-option layout.
    public var steps: [QuickDrillStep] = []
    public var currentStepIndex = 0
    public var elapsedTimeMs = 0
    public var isCorrect = false
    public var srsResult: SRSResult?
    public var triggerSparkle = false
    public var stepSuccessCount = 0
    public var stepRemainingSeconds = 0.0
    public var stepMaxSeconds = 0.0
    public var isSpeedBonus = false
    public var totalSpeedBonusCount = 0
    public var isMicActive = false
    public var recordedSpokenText = ""
    public var isStepEvaluated = false
    public var isStepCorrect = false
    public var selectedOption: String?

    public init() {}
}

@MainActor
@Observable
public final class QuickReflexDrillViewModel {
    public let targetWord: WordItem
    public let allWords: [WordItem]
    public private(set) var prompts: QuickReflexPrompts
    public var state = QuickReflexDrillState()
    public var speechEvaluationResult: SpeechEvaluationResult?

    private let ttsService: TextToSpeechProtocol
    private let sttService: SpeechRecognitionProtocol
    private let speechAssessmentService: SpeechAssessmentProtocol?
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol?
    private let attemptRepository: QuickReflexAttemptRepositoryProtocol
    private let clock: () -> Date
    private var activePhaseStartedAt: Date
    private var elapsedBeforePauseMs = 0
    private var hintTasks: [Task<Void, Never>] = []
    private var recordingSession = 0
    private var lifecycleSession = 0
    private var hasPersistedAttempt = false
    private var stageRetryCount = 0
    /// The sentence-frame hint follows the retrieve stage's levels one and two.
    private let sentenceFrameHintLevel = 3

    public var isListening: Bool {
        if state.phase == .shadowModel, let speechAssessmentService {
            return speechAssessmentService.isListening
        }
        return sttService.isListening
    }

    public var recognizedText: String {
        if state.phase == .shadowModel, let eval = speechEvaluationResult, !eval.spokenText.isEmpty {
            return eval.spokenText
        }
        return sttService.recognizedText
    }

    public var isSpeaking: Bool { ttsService.isSpeaking }

    public init(
        targetWord: WordItem,
        allWords: [WordItem],
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil,
        speechAssessmentService: SpeechAssessmentProtocol? = nil,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol? = nil,
        promptFactory: QuickReflexPromptFactory = QuickReflexPromptFactory(),
        attemptRepository: QuickReflexAttemptRepositoryProtocol? = nil,
        clock: @escaping () -> Date = Date.init
    ) {
        self.targetWord = targetWord
        self.allWords = allWords
        self.prompts = promptFactory.makePrompts(for: targetWord)
        self.ttsService = ttsService ?? TextToSpeechService()
        self.sttService = sttService ?? SpeechRecognitionService()
        self.speechAssessmentService = speechAssessmentService
        self.evaluateSRSUseCase = evaluateSRSUseCase
        self.attemptRepository = attemptRepository ?? QuickReflexAttemptRepositoryImpl()
        self.clock = clock
        self.activePhaseStartedAt = clock()
        scheduleHints()
    }

    deinit {
        let stt = sttService
        let tts = ttsService
        let assessment = speechAssessmentService
        Task { @MainActor in
            stt.stopListening()
            tts.stop()
            assessment?.stopAssessing()
        }
    }

    /// Begins raw speech recognition for the current productive-recall phase.
    public func startRecording() {
        guard canAnswerCurrentPhase, !isListening else { return }
        recordingSession += 1
        let session = recordingSession
        let phase = state.phase
        state.errorMessage = nil
        state.inputMode = .voice
        ttsService.stop()
        sttService.startListening(
            onResult: { [weak self] text in
                guard let self,
                      self.canAnswerCurrentPhase,
                      self.recordingSession == session,
                      self.state.phase == phase else { return }
                guard self.matchesCurrentPhase(response: text) else { return }
                self.submit(text, mode: .voice)
            },
            onError: { [weak self] error in
                guard let self,
                      !self.state.isCancelled,
                      self.recordingSession == session,
                      self.state.phase == phase else { return }
                self.stopCurrentRecording()
                self.state.inputMode = .typing
                self.state.errorMessage = AppStrings.Reflex.quickRecordingError(error.localizedDescription)
            }
        )
    }

    /// Stops listening and evaluates the final raw transcript, allowing one empty retry.
    public func stopRecordingAndEvaluate() {
        guard canAnswerCurrentPhase else { return }
        stopCurrentRecording()
        let answer = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else {
            handleUnclearSpeech()
            return
        }
        guard matchesCurrentPhase(response: answer) else {
            handleUnclearSpeech()
            return
        }
        submit(answer, mode: .voice)
    }

    public func handleMicTap() {
        if state.phase == .shadowModel {
            if isListening {
                stopShadowingAssessment()
            } else {
                startShadowingAssessment()
            }
        } else {
            if isListening {
                stopRecordingAndEvaluate()
            } else {
                startRecording()
            }
        }
    }

    public func submitTypedAnswer(_ answer: String) {
        submit(answer, mode: .typing)
    }

    // MARK: - Shadowing Assessment

    public func startShadowingAssessment() {
        guard state.phase == .shadowModel, let speechAssessmentService else { return }
        ttsService.stop()
        state.errorMessage = nil
        speechAssessmentService.startAssessing(
            targetSentence: prompts.modelSentenceEn,
            toleranceThreshold: 0.75,
            contextualPhrases: [prompts.modelSentenceEn, targetWord.lemma].filter { !$0.isEmpty },
            onProgress: { [weak self] evaluation in
                guard let self else { return }
                self.speechEvaluationResult = evaluation
            },
            onCompletion: { [weak self] evaluation in
                guard let self else { return }
                self.speechEvaluationResult = evaluation
                self.state.shadowPronunciationScore = evaluation.overallScore
            },
            onError: { [weak self] error in
                guard let self else { return }
                self.state.errorMessage = AppStrings.Reflex.quickRecordingError(error.localizedDescription)
            }
        )
    }

    public func stopShadowingAssessment() {
        guard state.phase == .shadowModel, let speechAssessmentService else { return }
        speechAssessmentService.stopAssessing()
        if let evaluation = speechEvaluationResult {
            state.shadowPronunciationScore = evaluation.overallScore
        }
    }

    public func proceedToResult() {
        guard state.phase == .shadowModel else { return }
        speechAssessmentService?.stopAssessing()
        ttsService.stop()
        if let evaluation = speechEvaluationResult, state.shadowPronunciationScore == nil {
            state.shadowPronunciationScore = evaluation.overallScore
        }
        state.phase = .result
    }

    public func speakModelSentence() {
        ttsService.speak(text: prompts.modelSentenceEn)
    }

    /// Excludes inactive app time from the current phase and prevents background hint delivery.
    public func pause() {
        guard (canAnswerCurrentPhase || state.phase == .shadowModel), !state.isPaused else { return }
        elapsedBeforePauseMs += liveElapsedTimeMs()
        state.isPaused = true
        stopListeningAndTimers()
    }

    /// Continues the existing phase from its paused elapsed time and restarts hint delays fresh.
    public func resume() {
        guard !state.isCancelled, !state.isCompleted, state.phase != .result, state.isPaused else { return }
        activePhaseStartedAt = clock()
        state.isPaused = false
        if state.phase != .shadowModel {
            scheduleHints()
        }
    }

    /// Shows the next staged hint. Timers call this at scheduled intervals; it never ends a stage.
    public func advanceHint() {
        guard canAnswerCurrentPhase else { return }
        if state.phase == .produceSentence {
            showSentenceFrame()
            return
        }
        let maximum = currentPrompt.hints.count
        guard state.visibleHintLevel < maximum else { return }
        state.visibleHintLevel += 1
        state.maxHintLevel = max(state.maxHintLevel, state.visibleHintLevel)
    }

    /// Revealing or skipping always ends the attempt without an SRS review.
    public func revealAnswer() {
        guard canAnswerCurrentPhase else { return }
        state.revealedTargetExpression = currentPrompt.targetExpression
        completeWithoutSuccessfulRetrieval()
    }

    public func skip() {
        completeWithoutSuccessfulRetrieval()
    }

    /// Stops all live resources. A cancelled drill is never saved or sent to SRS.
    public func cancel() {
        guard !state.isFinishing else { return }
        lifecycleSession += 1
        stopListeningAndTimers()
        state.isCancelled = true
    }

    /// Persists exactly one completed attempt and records SRS only after successful recall and collocation.
    public func finish(confidence: QuickReflexConfidence) async throws {
        guard state.phase == .result, !state.isCancelled, !state.isCompleted, !state.isFinishing else { return }
        state.isFinishing = true
        defer { state.isFinishing = false }

        let session = lifecycleSession

        let attempt = QuickReflexAttempt(
            wordId: targetWord.id,
            recallWordTimeMs: state.recallWordTimeMs,
            collocationTimeMs: state.collocationTimeMs,
            produceSentenceTimeMs: state.produceSentenceTimeMs,
            recallWordSucceeded: state.recallWordSucceeded,
            collocationSucceeded: state.collocationSucceeded,
            produceSentenceSucceeded: state.produceSentenceSucceeded,
            shadowPronunciationScore: state.shadowPronunciationScore,
            maxHintLevel: state.maxHintLevel,
            inputMode: state.inputMode,
            retryCount: state.retryCount,
            confidence: confidence,
            timestamp: clock()
        )

        if !hasPersistedAttempt {
            try Task.checkCancellation()
            guard isActiveFinish(session) else { return }
            try await attemptRepository.save(attempt)
            hasPersistedAttempt = true
        }

        let isEligibleForSRS = state.recallWordSucceeded && state.collocationSucceeded
        if isEligibleForSRS, !state.isDeferredAttempt, let evaluateSRSUseCase, state.srsResult == nil {
            try Task.checkCancellation()
            guard isActiveFinish(session) else { return }
            state.srsResult = try await evaluateSRSUseCase.recordReview(
                wordId: targetWord.id,
                isCorrect: true,
                responseTimeMs: state.recallWordTimeMs
            )
        }

        stopListeningAndTimers()
        state.isCorrect = isEligibleForSRS && state.produceSentenceSucceeded
        state.triggerSparkle = state.isCorrect
        state.isCompleted = true
    }

    // MARK: - Legacy presentation compatibility

    public func generateSteps() {}
    public func startTimer() {}
    public func speakTargetSentence() { ttsService.speak(text: currentPrompt.targetExpression) }
    public func speakExampleSentence() { ttsService.speak(text: targetWord.exampleSentenceEn) }
    public func submitAnswer(_ answer: String) { submitTypedAnswer(answer) }
    public func nextStep() {}
    public func finishDrill() {
        guard state.phase == .result else { return }
        Task { [weak self] in try? await self?.finish(confidence: .uncertain) }
    }

    private var canAnswerCurrentPhase: Bool {
        !state.isCancelled && !state.isCompleted && !state.isPaused && state.phase != .result && state.phase != .shadowModel
    }

    private func isActiveFinish(_ session: Int) -> Bool {
        session == lifecycleSession && !state.isCancelled
    }

    private var currentPrompt: QuickReflexStagePrompt {
        switch state.phase {
        case .recallWord:
            return prompts.recallWord
        case .recallCollocation:
            return prompts.recallCollocation
        case .produceSentence, .shadowModel, .result:
            return prompts.produceSentence
        }
    }

    private func matchesCurrentPhase(response: String) -> Bool {
        switch state.phase {
        case .recallWord, .recallCollocation:
            TargetExpressionMatcher.matchesExactly(response: response, expression: currentPrompt.targetExpression)
        case .produceSentence:
            TargetExpressionMatcher.contains(response: response, expression: currentPrompt.targetExpression)
        case .shadowModel, .result:
            false
        }
    }

    private func submit(_ answer: String, mode: QuickReflexInputMode) {
        guard canAnswerCurrentPhase else { return }
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAnswer.isEmpty else { return }

        stopCurrentRecording()
        state.inputMode = mode
        state.errorMessage = nil
        state.recordedSpokenText = trimmedAnswer
        let isCorrect = matchesCurrentPhase(response: trimmedAnswer)
        let elapsed = elapsedTimeMs()

        switch state.phase {
        case .recallWord:
            state.recallWordSucceeded = isCorrect
            state.recallWordTimeMs = elapsed
            guard isCorrect else { return }
            state.phase = .recallCollocation
            beginPhase()
        case .recallCollocation:
            state.collocationSucceeded = isCorrect
            state.collocationTimeMs = elapsed
            guard isCorrect else { return }
            state.phase = .produceSentence
            beginPhase()
        case .produceSentence:
            state.produceSentenceSucceeded = isCorrect
            state.produceSentenceTimeMs = elapsed
            state.phase = .shadowModel
            hintTasks.forEach { $0.cancel() }
            hintTasks.removeAll()
            ttsService.speak(text: prompts.modelSentenceEn)
        case .shadowModel, .result:
            return
        }
    }

    private func completeWithoutSuccessfulRetrieval() {
        guard canAnswerCurrentPhase else { return }
        state.isDeferredAttempt = true
        stopCurrentRecording()
        let elapsed = elapsedTimeMs()
        switch state.phase {
        case .recallWord:
            state.recallWordSucceeded = false
            state.recallWordTimeMs = elapsed
        case .recallCollocation:
            state.collocationSucceeded = false
            state.collocationTimeMs = elapsed
        case .produceSentence:
            state.produceSentenceSucceeded = false
            state.produceSentenceTimeMs = elapsed
        case .shadowModel, .result:
            break
        }
        state.phase = .result
        hintTasks.forEach { $0.cancel() }
        hintTasks.removeAll()
    }

    private func handleUnclearSpeech() {
        if stageRetryCount == 0 {
            stageRetryCount = 1
            state.retryCount += 1
            state.inputMode = .voice
            state.errorMessage = AppStrings.Reflex.quickSpeechRetryText
        } else {
            state.inputMode = .typing
            state.errorMessage = AppStrings.Reflex.quickSpeechTypingText
        }
    }

    private func beginPhase() {
        activePhaseStartedAt = clock()
        elapsedBeforePauseMs = 0
        state.visibleHintLevel = 0
        stageRetryCount = 0
        state.showsSentenceFrame = false
        state.errorMessage = nil
        scheduleHints()
    }

    private func scheduleHints() {
        hintTasks.forEach { $0.cancel() }
        let activeElapsedSeconds = Double(elapsedTimeMs()) / 1_000
        switch state.phase {
        case .recallWord, .recallCollocation:
            hintTasks = QuickReflexHintTiming.remainingDelaySeconds(
                for: state.phase,
                activeElapsedSeconds: activeElapsedSeconds
            ).enumerated().map { index, seconds in
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(seconds))
                    guard !Task.isCancelled else { return }
                    self?.showHint(level: index + 1)
                }
            }
        case .produceSentence:
            hintTasks = QuickReflexHintTiming.remainingDelaySeconds(
                for: .produceSentence,
                activeElapsedSeconds: activeElapsedSeconds
            ).map { seconds in
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(seconds))
                    guard !Task.isCancelled else { return }
                    self?.showSentenceFrame()
                }
            }
        case .shadowModel, .result:
            hintTasks = []
        }
    }

    private func showSentenceFrame() {
        guard canAnswerCurrentPhase,
              state.phase == .produceSentence,
              currentPrompt.sentenceFrame != nil else { return }
        state.showsSentenceFrame = true
        state.maxHintLevel = max(state.maxHintLevel, sentenceFrameHintLevel)
    }

    private func showHint(level: Int) {
        guard canAnswerCurrentPhase, level > state.visibleHintLevel else { return }
        let maximum = currentPrompt.hints.count
        state.visibleHintLevel = min(level, maximum)
        state.maxHintLevel = max(state.maxHintLevel, state.visibleHintLevel)
    }

    private func elapsedTimeMs() -> Int {
        elapsedBeforePauseMs + liveElapsedTimeMs()
    }

    private func liveElapsedTimeMs() -> Int {
        Int(clock().timeIntervalSince(activePhaseStartedAt) * 1_000)
    }

    private func stopListeningAndTimers() {
        ttsService.stop()
        stopCurrentRecording()
        speechAssessmentService?.stopAssessing()
        hintTasks.forEach { $0.cancel() }
        hintTasks.removeAll()
    }

    private func stopCurrentRecording() {
        recordingSession += 1
        sttService.stopListening()
    }
}
