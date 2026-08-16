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
    private var hintTasks: [Task<Void, Never>] = []
    private var recordingSession = 0

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
        let stt = sttService
        Task { @MainActor in
            stt.stopListening()
        }
    }

    /// Begins raw speech recognition for the current productive-recall phase.
    public func startRecording() {
        guard !state.isCancelled, !state.isCompleted, state.phase != .result, !isListening else { return }
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
                let target = self.currentPrompt.targetExpression
                guard TargetExpressionMatcher.contains(response: text, expression: target) else { return }
                self.submit(text, mode: .voice)
            },
            onError: { [weak self] error in
                guard let self,
                      !self.state.isCancelled,
                      self.recordingSession == session,
                      self.state.phase == phase else { return }
                self.stopCurrentRecording()
                self.state.inputMode = .typing
                self.state.errorMessage = "Không thể thu âm: \(error.localizedDescription). Hãy nhập câu trả lời."
            }
        )
    }

    /// Stops listening and evaluates the final raw transcript, allowing one empty retry.
    public func stopRecordingAndEvaluate() {
        guard !state.isCancelled, !state.isCompleted, state.phase != .result else { return }
        stopCurrentRecording()
        let answer = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else {
            handleUnclearSpeech()
            return
        }
        guard TargetExpressionMatcher.contains(response: answer, expression: currentPrompt.targetExpression) else {
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

    /// Shows the next staged hint. Timers call this at 4 and 7 seconds; it never ends a stage.
    public func advanceHint() {
        guard canAnswerCurrentPhase else { return }
        let maximum = currentPrompt.hints.count
        guard state.visibleHintLevel < maximum else { return }
        state.visibleHintLevel += 1
        state.maxHintLevel = max(state.maxHintLevel, state.visibleHintLevel)
    }

    /// Revealing or skipping always ends the attempt without an SRS review.
    public func revealAnswer() {
        completeWithoutSuccessfulRetrieval()
    }

    public func skip() {
        completeWithoutSuccessfulRetrieval()
    }

    /// Stops all live resources. A cancelled drill is never saved or sent to SRS.
    public func cancel() {
        stopListeningAndTimers()
        state.isCancelled = true
    }

    /// Persists exactly one completed attempt and records SRS only after successful retrieval.
    public func finish(confidence: QuickReflexConfidence) async throws {
        guard state.phase == .result, !state.isCancelled, !state.isCompleted else { return }

        state.isCompleted = true
        stopListeningAndTimers()
        state.isCorrect = state.retrieveSucceeded && state.useSucceeded
        state.triggerSparkle = state.isCorrect

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
        try await attemptRepository.save(attempt)

        guard state.retrieveSucceeded else { return }
        if let evaluateSRSUseCase {
            state.srsResult = try await evaluateSRSUseCase.recordReview(
                wordId: targetWord.id,
                isCorrect: true,
                responseTimeMs: state.retrieveTimeMs
            )
        }
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
        !state.isCancelled && !state.isCompleted && state.phase != .result
    }

    private var currentPrompt: QuickReflexStagePrompt {
        state.phase == .useInSentence ? prompts.use : prompts.retrieve
    }

    private func submit(_ answer: String, mode: QuickReflexInputMode) {
        guard canAnswerCurrentPhase else { return }
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAnswer.isEmpty else { return }

        stopCurrentRecording()
        state.inputMode = mode
        state.errorMessage = nil
        state.recordedSpokenText = trimmedAnswer
        let isCorrect = TargetExpressionMatcher.contains(
            response: trimmedAnswer,
            expression: currentPrompt.targetExpression
        )
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
        if state.retryCount == 0 {
            state.retryCount = 1
            state.inputMode = .voice
            state.errorMessage = "Chưa nghe thấy câu trả lời. Hãy thử lại một lần."
        } else {
            state.inputMode = .typing
            state.errorMessage = "Chưa nghe thấy câu trả lời. Hãy nhập câu trả lời."
        }
    }

    private func beginPhase() {
        activePhaseStartedAt = clock()
        state.visibleHintLevel = 0
        state.errorMessage = nil
        scheduleHints()
    }

    private func scheduleHints() {
        hintTasks.forEach { $0.cancel() }
        hintTasks = [4, 7].enumerated().map { index, seconds in
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(seconds))
                guard !Task.isCancelled else { return }
                self?.showHint(level: index + 1)
            }
        }
    }

    private func showHint(level: Int) {
        guard canAnswerCurrentPhase, level > state.visibleHintLevel else { return }
        let maximum = currentPrompt.hints.count
        state.visibleHintLevel = min(level, maximum)
        state.maxHintLevel = max(state.maxHintLevel, state.visibleHintLevel)
    }

    private func elapsedTimeMs() -> Int {
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
