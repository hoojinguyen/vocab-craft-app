@testable import VocabCraftApp
import XCTest

@MainActor
final class QuickReflexDrillViewModelTests: XCTestCase {
    private var targetWord: WordItem!
    private var mockSTT: MockSpeechRecognitionService!
    private var mockTTS: RecordingQuickReflexTTS!
    private var mockSpeechAssessment: MockSpeechAssessmentForQuickReflex!
    private var mockSRS: RecordingSRSUseCase!
    private var mockAttempts: RecordingQuickReflexAttemptRepository!

    override func setUp() {
        super.setUp()
        targetWord = WordItem(
            id: 1,
            lemma: "Ephemeral",
            phonetic: "/ɪˈfem.ər.əl/",
            pos: "adj.",
            definition: "Phù du, chóng phai",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Sự nổi tiếng của cô ấy chỉ kéo dài ngắn nguôi.",
            cefrLevel: "B2",
            masteryLevel: 2,
            collocationEn: "ephemeral fame"
        )
        mockSTT = MockSpeechRecognitionService()
        mockTTS = RecordingQuickReflexTTS()
        mockSpeechAssessment = MockSpeechAssessmentForQuickReflex()
        mockSRS = RecordingSRSUseCase()
        mockAttempts = RecordingQuickReflexAttemptRepository()
    }

    func testFullLadderProgressesThroughAllStagesAndRecordsSRS() async throws {
        let viewModel = makeViewModel()

        // Stage 1: Recall Word
        XCTAssertEqual(viewModel.state.phase, .recallWord)
        viewModel.submitTypedAnswer("Ephemeral")
        XCTAssertEqual(viewModel.state.phase, .recallCollocation)
        XCTAssertTrue(viewModel.state.recallWordSucceeded)

        // Stage 2: Recall Collocation
        viewModel.submitTypedAnswer("ephemeral fame")
        XCTAssertEqual(viewModel.state.phase, .produceSentence)
        XCTAssertTrue(viewModel.state.collocationSucceeded)

        // Stage 3: Sentence Production -> Shadow Model
        viewModel.submitTypedAnswer("Her fame was ephemeral.")
        XCTAssertEqual(viewModel.state.phase, .shadowModel)
        XCTAssertTrue(viewModel.state.produceSentenceSucceeded)
        XCTAssertEqual(mockTTS.spokenTexts.last, viewModel.prompts.modelSentenceEn)

        // Shadowing action / proceed to result
        viewModel.proceedToResult()
        XCTAssertEqual(viewModel.state.phase, .result)

        try await viewModel.finish(confidence: .comfortable)
        XCTAssertEqual(mockSRS.recordedCalls.count, 1)
        XCTAssertEqual(mockSRS.recordedCalls.first?.wordId, targetWord.id)
        XCTAssertEqual(mockAttempts.saved.count, 1)
        XCTAssertTrue(mockAttempts.saved[0].recallWordSucceeded)
        XCTAssertTrue(mockAttempts.saved[0].collocationSucceeded)
        XCTAssertTrue(mockAttempts.saved[0].produceSentenceSucceeded)
    }

    func testShadowingInvokesSpeechAssessment() {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("Ephemeral")
        viewModel.submitTypedAnswer("ephemeral fame")
        viewModel.submitTypedAnswer("Her fame was ephemeral.")
        XCTAssertEqual(viewModel.state.phase, .shadowModel)

        viewModel.startShadowingAssessment()
        XCTAssertTrue(mockSpeechAssessment.isListening)
        XCTAssertEqual(mockSpeechAssessment.targetSentence, viewModel.prompts.modelSentenceEn)
    }

    func testShadowingCompletionRecordsPronunciationScore() async throws {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("Ephemeral")
        viewModel.submitTypedAnswer("ephemeral fame")
        viewModel.submitTypedAnswer("Her fame was ephemeral.")

        viewModel.startShadowingAssessment()
        let evaluation = SpeechEvaluationResult(
            targetSentence: "Her fame proved to be ephemeral.",
            spokenText: "Her fame proved to be ephemeral.",
            tokens: [],
            overallScore: 88.0,
            isPassed: true,
            durationMs: 2100
        )
        mockSpeechAssessment.simulateCompletion(result: evaluation)

        XCTAssertEqual(viewModel.state.shadowPronunciationScore, 88.0)
        XCTAssertEqual(viewModel.speechEvaluationResult?.overallScore, 88.0)

        viewModel.proceedToResult()
        try await viewModel.finish(confidence: .comfortable)

        XCTAssertEqual(mockAttempts.saved.count, 1)
        XCTAssertEqual(mockAttempts.saved[0].shadowPronunciationScore, 88.0)
    }

    func testRevealAnswerDoesNotRecordSRSAndPersistsAttempt() async throws {
        let viewModel = makeViewModel()

        viewModel.revealAnswer()
        try await viewModel.finish(confidence: .uncertain)

        XCTAssertTrue(mockSRS.recordedCalls.isEmpty)
        XCTAssertEqual(mockAttempts.saved.count, 1)
        XCTAssertFalse(mockAttempts.saved[0].recallWordSucceeded)
    }

    func testSkipInStage1DoesNotRecordSRSAndPersistsAttempt() async throws {
        let viewModel = makeViewModel()

        viewModel.skip()
        try await viewModel.finish(confidence: .uncertain)

        XCTAssertTrue(mockSRS.recordedCalls.isEmpty)
        XCTAssertEqual(mockAttempts.saved.count, 1)
        XCTAssertFalse(mockAttempts.saved[0].recallWordSucceeded)
    }

    func testSkipInStage2DoesNotRecordSRS() async throws {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("Ephemeral")
        XCTAssertEqual(viewModel.state.phase, .recallCollocation)

        viewModel.skip()
        try await viewModel.finish(confidence: .uncertain)

        XCTAssertTrue(mockSRS.recordedCalls.isEmpty)
        XCTAssertEqual(mockAttempts.saved.count, 1)
        XCTAssertTrue(mockAttempts.saved[0].recallWordSucceeded)
        XCTAssertFalse(mockAttempts.saved[0].collocationSucceeded)
    }

    func testStage3SentenceFailureStillRecordsSRSIfStages1And2Succeeded() async throws {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("Ephemeral")
        viewModel.submitTypedAnswer("ephemeral fame")
        viewModel.submitTypedAnswer("A sentence without the target word.")

        XCTAssertEqual(viewModel.state.phase, .shadowModel)
        XCTAssertFalse(viewModel.state.produceSentenceSucceeded)

        viewModel.proceedToResult()
        try await viewModel.finish(confidence: .comfortable)

        XCTAssertEqual(mockSRS.recordedCalls.count, 1)
        XCTAssertEqual(mockAttempts.saved.count, 1)
        XCTAssertTrue(mockAttempts.saved[0].recallWordSucceeded)
        XCTAssertTrue(mockAttempts.saved[0].collocationSucceeded)
        XCTAssertFalse(mockAttempts.saved[0].produceSentenceSucceeded)
    }

    func testHintsProgressWithoutChangingStageOrCorrectness() {
        let viewModel = makeViewModel()

        viewModel.advanceHint()
        viewModel.advanceHint()

        XCTAssertEqual(viewModel.state.visibleHintLevel, 2)
        XCTAssertEqual(viewModel.state.maxHintLevel, 2)
        XCTAssertEqual(viewModel.state.phase, .recallWord)
        XCTAssertFalse(viewModel.state.recallWordSucceeded)
        XCTAssertFalse(viewModel.state.collocationSucceeded)
    }

    func testSpeechErrorSwitchesToTyping() {
        let viewModel = makeViewModel()

        viewModel.startRecording()
        mockSTT.simulateError(SpeechRecognitionError.notAuthorized)

        XCTAssertEqual(viewModel.state.inputMode, .typing)
        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertFalse(mockSTT.isListening)
    }

    func testEmptySpeechGetsOneRetryThenTypingFallback() {
        let viewModel = makeViewModel()

        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .voice)

        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .typing)
    }

    func testNonmatchingRetrieveSpeechGetsOneRetryThenTypingFallback() {
        let viewModel = makeViewModel()

        mockSTT.recognizedText = "a different answer"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.phase, .recallWord)
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .voice)

        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.phase, .recallWord)
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .typing)
    }

    func testNonmatchingCollocationSpeechGetsOneRetryThenTypingFallback() {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("ephemeral")
        XCTAssertEqual(viewModel.state.phase, .recallCollocation)

        mockSTT.recognizedText = "wrong collocation"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.phase, .recallCollocation)
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .voice)

        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.phase, .recallCollocation)
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .typing)
    }

    func testNonmatchingUseSpeechGetsOneRetryThenTypingFallback() {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("ephemeral")
        viewModel.submitTypedAnswer("ephemeral fame")
        XCTAssertEqual(viewModel.state.phase, .produceSentence)

        mockSTT.recognizedText = "a sentence without the word"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.phase, .produceSentence)
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .voice)

        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.phase, .produceSentence)
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .typing)
    }

    func testStaleRecordingCallbackCannotAdvanceStage() {
        let viewModel = makeViewModel()

        viewModel.startRecording()
        mockSTT.simulateResult("ephemeral")
        XCTAssertEqual(viewModel.state.phase, .recallCollocation)

        mockSTT.simulateResult("A second stale result says ephemeral.")

        XCTAssertEqual(viewModel.state.phase, .recallCollocation)
        XCTAssertFalse(viewModel.state.collocationSucceeded)
    }

    func testCancelStopsListeningAndDoesNotPersist() async throws {
        let viewModel = makeViewModel()
        viewModel.startRecording()

        viewModel.cancel()
        try await viewModel.finish(confidence: .comfortable)

        XCTAssertTrue(viewModel.state.isCancelled)
        XCTAssertFalse(mockSTT.isListening)
        XCTAssertTrue(mockAttempts.saved.isEmpty)
        XCTAssertTrue(mockSRS.recordedCalls.isEmpty)
    }

    func testTransitionToCollocationStageResetsSpeechRetryAllowance() {
        let viewModel = makeViewModel()
        mockSTT.recognizedText = "not the target"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.retryCount, 1)

        viewModel.submitTypedAnswer("ephemeral")

        XCTAssertEqual(viewModel.state.phase, .recallCollocation)
        XCTAssertEqual(viewModel.state.retryCount, 1)

        mockSTT.recognizedText = "wrong collocation"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.retryCount, 2)
        XCTAssertEqual(viewModel.state.inputMode, .voice)
    }

    func testRetrieveRequiresExactNormalizedTargetExpression() {
        let viewModel = makeViewModel()

        viewModel.submitTypedAnswer("The answer is ephemeral")

        XCTAssertEqual(viewModel.state.phase, .recallWord)
        XCTAssertFalse(viewModel.state.recallWordSucceeded)

        viewModel.submitTypedAnswer("EPHEMERAL!")
        XCTAssertEqual(viewModel.state.phase, .recallCollocation)
    }

    func testCollocationRequiresExactNormalizedTargetExpression() {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("ephemeral")
        XCTAssertEqual(viewModel.state.phase, .recallCollocation)

        viewModel.submitTypedAnswer("something else")
        XCTAssertEqual(viewModel.state.phase, .recallCollocation)
        XCTAssertFalse(viewModel.state.collocationSucceeded)

        viewModel.submitTypedAnswer("Ephemeral Fame!")
        XCTAssertEqual(viewModel.state.phase, .produceSentence)
        XCTAssertTrue(viewModel.state.collocationSucceeded)
    }

    func testFinishPersistsRetryTotalAcrossAllStages() async throws {
        let viewModel = makeViewModel()

        mockSTT.recognizedText = "wrong"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        viewModel.submitTypedAnswer("ephemeral")

        mockSTT.recognizedText = "wrong collocation"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        viewModel.submitTypedAnswer("ephemeral fame")

        mockSTT.recognizedText = "a sentence without the target"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        viewModel.submitTypedAnswer("The trend is ephemeral.")
        viewModel.proceedToResult()
        try await viewModel.finish(confidence: .comfortable)

        XCTAssertEqual(mockAttempts.saved.first?.retryCount, 3)
    }

    func testSentenceFrameHintPersistsAsHighestHintLevel() async throws {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("ephemeral")
        viewModel.submitTypedAnswer("ephemeral fame")

        viewModel.advanceHint()
        viewModel.submitTypedAnswer("The trend is ephemeral.")
        viewModel.proceedToResult()
        try await viewModel.finish(confidence: .comfortable)

        XCTAssertEqual(mockAttempts.saved.first?.maxHintLevel, 3)
    }

    func testPauseAndResumeExcludesInactiveTimeAndKeepsHintsHidden() {
        let clock = MutableClock()
        let viewModel = makeViewModel(clock: { clock.now })
        clock.advance(by: 2)

        viewModel.pause()
        XCTAssertTrue(viewModel.state.isPaused)
        XCTAssertEqual(viewModel.state.visibleHintLevel, 0)

        clock.advance(by: 60)
        viewModel.resume()
        clock.advance(by: 3)
        viewModel.submitTypedAnswer("ephemeral")

        XCTAssertFalse(viewModel.state.isPaused)
        XCTAssertEqual(viewModel.state.recallWordTimeMs, 5_000)
        XCTAssertEqual(viewModel.state.visibleHintLevel, 0)
    }

    func testRevealAnswerCarriesTargetExpressionIntoResult() {
        let viewModel = makeViewModel()

        viewModel.revealAnswer()

        XCTAssertEqual(viewModel.state.phase, .result)
        XCTAssertEqual(viewModel.state.revealedTargetExpression, "Ephemeral")
    }

    func testHintTimingUses3TierTimings() {
        XCTAssertEqual(QuickReflexHintTiming.automaticDelaySeconds(for: .recallWord), [3, 6])
        XCTAssertEqual(QuickReflexHintTiming.automaticDelaySeconds(for: .recallCollocation), [4])
        XCTAssertEqual(QuickReflexHintTiming.automaticDelaySeconds(for: .produceSentence), [5])
        XCTAssertEqual(QuickReflexHintTiming.automaticDelaySeconds(for: .shadowModel), [])
        XCTAssertEqual(QuickReflexHintTiming.automaticDelaySeconds(for: .result), [])
    }

    func testResumedHintsKeepOriginalActiveTimeDeadlines() {
        XCTAssertEqual(QuickReflexHintTiming.remainingDelaySeconds(for: .recallWord, activeElapsedSeconds: 1), [2, 5])
        XCTAssertEqual(QuickReflexHintTiming.remainingDelaySeconds(for: .recallWord, activeElapsedSeconds: 3), [0, 3])
        XCTAssertEqual(QuickReflexHintTiming.remainingDelaySeconds(for: .recallWord, activeElapsedSeconds: 6), [0, 0])
        XCTAssertEqual(QuickReflexHintTiming.remainingDelaySeconds(for: .recallCollocation, activeElapsedSeconds: 2), [2])
        XCTAssertEqual(QuickReflexHintTiming.remainingDelaySeconds(for: .produceSentence, activeElapsedSeconds: 3), [2])
        XCTAssertEqual(QuickReflexHintTiming.remainingDelaySeconds(for: .produceSentence, activeElapsedSeconds: 5), [0])
    }

    func testFailedPersistenceLeavesResultRetryableUntilFinishSucceeds() async throws {
        let failingAttempts = FailingOnceQuickReflexAttemptRepository()
        let viewModel = makeViewModel(attemptRepository: failingAttempts)
        viewModel.submitTypedAnswer("ephemeral")
        viewModel.submitTypedAnswer("ephemeral fame")
        viewModel.submitTypedAnswer("The trend is ephemeral.")
        viewModel.proceedToResult()

        await XCTAssertThrowsErrorAsync(try await viewModel.finish(confidence: .comfortable))

        XCTAssertEqual(viewModel.state.phase, .result)
        XCTAssertFalse(viewModel.state.isCompleted)
        XCTAssertNil(viewModel.state.srsResult)

        try await viewModel.finish(confidence: .comfortable)

        XCTAssertTrue(viewModel.state.isCompleted)
        XCTAssertEqual(failingAttempts.saveCallCount, 2)
        XCTAssertEqual(mockSRS.recordedCalls.count, 1)
    }

    func testCancelDuringFinishIsRejectedOncePersistenceCriticalSectionBegins() async throws {
        let suspendedAttempts = SuspendedQuickReflexAttemptRepository()
        let viewModel = makeViewModel(attemptRepository: suspendedAttempts)
        viewModel.submitTypedAnswer("ephemeral")
        viewModel.submitTypedAnswer("ephemeral fame")
        viewModel.submitTypedAnswer("The trend is ephemeral.")
        viewModel.proceedToResult()

        let finishTask = Task { try? await viewModel.finish(confidence: .comfortable) }
        await fulfillment(of: [suspendedAttempts.saveStarted], timeout: 1)

        viewModel.cancel()
        suspendedAttempts.resumeSave()
        _ = await finishTask.result

        XCTAssertFalse(viewModel.state.isCancelled)
        XCTAssertTrue(viewModel.state.isCompleted)
        XCTAssertFalse(viewModel.state.isFinishing)
        XCTAssertEqual(suspendedAttempts.persistedAttempts.count, 1)
        XCTAssertEqual(mockSRS.recordedCalls.count, 1)
    }

    private func makeViewModel(
        attemptRepository: QuickReflexAttemptRepositoryProtocol? = nil,
        clock: @escaping () -> Date = Date.init
    ) -> QuickReflexDrillViewModel {
        QuickReflexDrillViewModel(
            targetWord: targetWord,
            allWords: [targetWord],
            ttsService: mockTTS,
            sttService: mockSTT,
            speechAssessmentService: mockSpeechAssessment,
            evaluateSRSUseCase: mockSRS,
            attemptRepository: attemptRepository ?? mockAttempts,
            clock: clock
        )
    }
}

private final class MutableClock {
    private(set) var date = Date(timeIntervalSinceReferenceDate: 0)
    var now: Date { date }

    func advance(by seconds: TimeInterval) {
        date.addTimeInterval(seconds)
    }
}

private final class RecordingQuickReflexTTS: TextToSpeechProtocol {
    private(set) var spokenTexts: [String] = []
    var isSpeaking: Bool = false

    func speak(text: String, rate: Float, locale: String) {
        spokenTexts.append(text)
        isSpeaking = true
    }

    func stop() {
        isSpeaking = false
    }
}

private final class MockSpeechAssessmentForQuickReflex: SpeechAssessmentProtocol {
    var isListening: Bool = false
    var currentEvaluation: SpeechEvaluationResult?
    var targetSentence: String?
    var toleranceThreshold: Double?
    var contextualPhrases: [String] = []
    var onProgressHandler: ((SpeechEvaluationResult) -> Void)?
    var onCompletionHandler: ((SpeechEvaluationResult) -> Void)?
    var onErrorHandler: ((Error) -> Void)?

    func startAssessing(
        targetSentence: String,
        toleranceThreshold: Double,
        contextualPhrases: [String],
        onProgress: @escaping (SpeechEvaluationResult) -> Void,
        onCompletion: @escaping (SpeechEvaluationResult) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.isListening = true
        self.targetSentence = targetSentence
        self.toleranceThreshold = toleranceThreshold
        self.contextualPhrases = contextualPhrases
        self.onProgressHandler = onProgress
        self.onCompletionHandler = onCompletion
        self.onErrorHandler = onError
    }

    func stopAssessing() {
        self.isListening = false
    }

    func simulateProgress(result: SpeechEvaluationResult) {
        self.currentEvaluation = result
        self.onProgressHandler?(result)
    }

    func simulateCompletion(result: SpeechEvaluationResult) {
        self.isListening = false
        self.currentEvaluation = result
        self.onCompletionHandler?(result)
    }

    func simulateError(error: Error) {
        self.isListening = false
        self.onErrorHandler?(error)
    }
}

private final class RecordingSRSUseCase: EvaluateSRSUseCaseProtocol {
    struct RecordedCall: Equatable {
        let wordId: Int64
        let isCorrect: Bool
        let responseTimeMs: Int
    }

    private(set) var recordedCalls: [RecordedCall] = []

    func evaluateResponse(currentMastery: Int, easeFactor: Double, isCorrect: Bool, responseTimeMs: Int) -> SRSResult {
        SRSResult(nextMastery: currentMastery + 1, easeFactor: easeFactor, intervalDays: 1)
    }

    func recordReview(wordId: Int64, isCorrect: Bool, responseTimeMs: Int) async throws -> SRSResult {
        recordedCalls.append(RecordedCall(wordId: wordId, isCorrect: isCorrect, responseTimeMs: responseTimeMs))
        return evaluateResponse(currentMastery: 0, easeFactor: 2.5, isCorrect: isCorrect, responseTimeMs: responseTimeMs)
    }
}

private final class RecordingQuickReflexAttemptRepository: QuickReflexAttemptRepositoryProtocol {
    private(set) var saved: [QuickReflexAttempt] = []

    func save(_ attempt: QuickReflexAttempt) async throws {
        saved.append(attempt)
    }

    func mostRecentSuccessfulAttempt(for wordId: Int64) async throws -> QuickReflexAttempt? {
        saved.last(where: { $0.wordId == wordId && $0.recallWordSucceeded })
    }
}

private final class FailingOnceQuickReflexAttemptRepository: QuickReflexAttemptRepositoryProtocol {
    private(set) var saveCallCount = 0

    func save(_: QuickReflexAttempt) async throws {
        saveCallCount += 1
        if saveCallCount == 1 {
            throw TestPersistenceError.unavailable
        }
    }

    func mostRecentSuccessfulAttempt(for _: Int64) async throws -> QuickReflexAttempt? {
        nil
    }

    private enum TestPersistenceError: Error {
        case unavailable
    }
}

private final class SuspendedQuickReflexAttemptRepository: QuickReflexAttemptRepositoryProtocol {
    let saveStarted = XCTestExpectation(description: "save started")
    private var saveContinuation: CheckedContinuation<Void, Never>?
    private(set) var persistedAttempts: [QuickReflexAttempt] = []

    func save(_ attempt: QuickReflexAttempt) async throws {
        saveStarted.fulfill()
        await withCheckedContinuation { continuation in
            saveContinuation = continuation
        }
        guard !Task.isCancelled else { return }
        persistedAttempts.append(attempt)
    }

    func mostRecentSuccessfulAttempt(for _: Int64) async throws -> QuickReflexAttempt? {
        nil
    }

    func resumeSave() {
        saveContinuation?.resume()
        saveContinuation = nil
    }
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected an error to be thrown", file: file, line: line)
    } catch {}
}
