import Foundation
import Observation

/// Observable state for the two-stage productive-recall quick reflex drill.
public struct QuickReflexDrillState: Equatable, Sendable {
    public var phase: QuickReflexPhase = .retrieve
    public var inputMode: QuickReflexInputMode = .voice
    public var visibleHintLevel = 0
    public var maxHintLevel = 0
    public var retryCount = 0
    public var retrieveSucceeded = false
    public var useSucceeded = false
    public var retrieveTimeMs = 0
    public var useTimeMs = 0
    public var isCompleted = false
    public var isCancelled = false
    public var isFinishing = false
    public var isPaused = false
    public var isDeferredAttempt = false
    public var revealedTargetExpression: String?
    public var showsSentenceFrame = false
    public var errorMessage: String?

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
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol?
    private let attemptRepository: QuickReflexAttemptRepositoryProtocol
    private let clock: () -> Date
    private var activePhaseStartedAt: Date
    private var elapsedBeforePauseMs = 0
    // Task handles are only mutated on the main actor, but must be cancelled synchronously at teardown.
    private nonisolated(unsafe) var hintTasks: [Task<Void, Never>] = []
    private var recordingSession = 0
    private var lifecycleSession = 0
    private var hasPersistedAttempt = false
    private var stageRetryCount = 0
    /// The sentence-frame hint follows the retrieve stage's levels one and two.
    private let sentenceFrameHintLevel = 3

    public var isListening: Bool { sttService.isListening }
    public var recognizedText: String { sttService.recognizedText }

    public init(
        targetWord: WordItem,
        allWords: [WordItem],
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil,
        speechAssessmentService _: SpeechAssessmentProtocol? = nil,
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
        self.evaluateSRSUseCase = evaluateSRSUseCase
        self.attemptRepository = attemptRepository ?? QuickReflexAttemptRepositoryImpl()
        self.clock = clock
        self.activePhaseStartedAt = clock()
        scheduleHints()
    }

    deinit {
        hintTasks.forEach { $0.cancel() }
        let stt = sttService
        let tts = ttsService
        Task { @MainActor in
            stt.stopListening()
            tts.stop()
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
        if isListening {
            stopRecordingAndEvaluate()
        } else {
            startRecording()
        }
    }

    public func submitTypedAnswer(_ answer: String) {
        submit(answer, mode: .typing)
    }

    /// Excludes inactive app time from the current phase and prevents background hint delivery.
    public func pause() {
        guard canAnswerCurrentPhase, !state.isPaused else { return }
        elapsedBeforePauseMs += liveElapsedTimeMs()
        state.isPaused = true
        stopListeningAndTimers()
    }

    /// Continues the existing phase from its paused elapsed time and restarts hint delays fresh.
    public func resume() {
        guard !state.isCancelled, !state.isCompleted, state.phase != .result, state.isPaused else { return }
        activePhaseStartedAt = clock()
        state.isPaused = false
        scheduleHints()
    }

    /// Shows the next staged hint. Timers call this at 4 and 7 seconds; it never ends a stage.
    public func advanceHint() {
        guard canAnswerCurrentPhase else { return }
        if state.phase == .useInSentence {
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
        // Persistence is an explicit critical section: once it begins, cancellation is rejected
        // so a completed external write cannot be left without its corresponding completion flow.
        guard !state.isFinishing else { return }
        lifecycleSession += 1
        stopListeningAndTimers()
        state.isCancelled = true
    }

    /// Persists exactly one completed attempt and records SRS only after successful retrieval.
    public func finish(confidence: QuickReflexConfidence) async throws {
        guard state.phase == .result, !state.isCancelled, !state.isCompleted, !state.isFinishing else { return }
        state.isFinishing = true
        defer { state.isFinishing = false }

        let session = lifecycleSession

        let attempt = QuickReflexAttempt(
            wordId: targetWord.id,
            retrieveTimeMs: state.retrieveTimeMs,
            useTimeMs: state.useTimeMs,
            retrieveSucceeded: state.retrieveSucceeded,
            useSucceeded: state.useSucceeded,
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

        if state.retrieveSucceeded, !state.isDeferredAttempt, let evaluateSRSUseCase, state.srsResult == nil {
            guard isActiveFinish(session) else { return }
            state.srsResult = try await evaluateSRSUseCase.recordReview(
                wordId: targetWord.id,
                isCorrect: true,
                responseTimeMs: state.retrieveTimeMs
            )
        }

        stopListeningAndTimers()
        state.isCorrect = state.retrieveSucceeded && state.useSucceeded
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
        !state.isCancelled && !state.isCompleted && !state.isPaused && state.phase != .result
    }

    private func isActiveFinish(_ session: Int) -> Bool {
        session == lifecycleSession && !state.isCancelled
    }

    private var currentPrompt: QuickReflexStagePrompt {
        state.phase == .useInSentence ? prompts.use : prompts.retrieve
    }

    private func matchesCurrentPhase(response: String) -> Bool {
        switch state.phase {
        case .retrieve:
            TargetExpressionMatcher.matchesExactly(response: response, expression: currentPrompt.targetExpression)
        case .useInSentence:
            TargetExpressionMatcher.contains(response: response, expression: currentPrompt.targetExpression)
        case .result:
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
        case .retrieve:
            state.retrieveSucceeded = isCorrect
            state.retrieveTimeMs = elapsed
            guard isCorrect else { return }
            state.phase = .useInSentence
            beginPhase()
        case .useInSentence:
            state.useSucceeded = isCorrect
            state.useTimeMs = elapsed
            state.phase = .result
            hintTasks.forEach { $0.cancel() }
            hintTasks.removeAll()
        case .result:
            return
        }
    }

    private func completeWithoutSuccessfulRetrieval() {
        guard canAnswerCurrentPhase else { return }
        state.isDeferredAttempt = true
        stopCurrentRecording()
        if state.phase == .retrieve {
            state.retrieveSucceeded = false
            state.retrieveTimeMs = elapsedTimeMs()
        } else {
            state.useSucceeded = false
            state.useTimeMs = elapsedTimeMs()
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
        case .retrieve:
            hintTasks = QuickReflexHintTiming.remainingDelaySeconds(
                for: .retrieve,
                activeElapsedSeconds: activeElapsedSeconds
            ).enumerated().map { index, seconds in
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(seconds))
                    guard !Task.isCancelled else { return }
                    self?.showHint(level: index + 1)
                }
            }
        case .useInSentence:
            hintTasks = QuickReflexHintTiming.remainingDelaySeconds(
                for: .useInSentence,
                activeElapsedSeconds: activeElapsedSeconds
            ).map { seconds in
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(seconds))
                    guard !Task.isCancelled else { return }
                    self?.showSentenceFrame()
                }
            }
        case .result:
            hintTasks = []
        }
    }

    private func showSentenceFrame() {
        guard canAnswerCurrentPhase,
              state.phase == .useInSentence,
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
        hintTasks.forEach { $0.cancel() }
        hintTasks.removeAll()
    }

    private func stopCurrentRecording() {
        recordingSession += 1
        sttService.stopListening()
    }
}
