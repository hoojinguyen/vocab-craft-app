@testable import VocabCraftApp
import XCTest

@MainActor
final class QuickReflexDrillViewModelTests: XCTestCase {
    private var targetWord: WordItem!
    private var mockSTT: MockSpeechRecognitionService!
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
            exampleSentenceVi: "Sự nổi tiếng của cô ấy chỉ kéo dài ngắn ngủi.",
            cefrLevel: "B2",
            masteryLevel: 2
        )
        mockSTT = MockSpeechRecognitionService()
        mockSRS = RecordingSRSUseCase()
        mockAttempts = RecordingQuickReflexAttemptRepository()
    }

    func testSuccessfulRetrieveThenUseRecordsSRSOnceAndPersistsAttempt() async throws {
        let viewModel = makeViewModel()

        viewModel.submitTypedAnswer("Ephemeral")
        XCTAssertEqual(viewModel.state.phase, .useInSentence)
        viewModel.submitTypedAnswer("The trend is ephemeral.")
        try await viewModel.finish(confidence: .comfortable)

        XCTAssertEqual(mockSRS.recordedCalls.count, 1)
        XCTAssertEqual(mockSRS.recordedCalls.first?.wordId, targetWord.id)
        XCTAssertEqual(mockAttempts.saved.count, 1)
        XCTAssertTrue(mockAttempts.saved[0].retrieveSucceeded)
        XCTAssertTrue(mockAttempts.saved[0].useSucceeded)
    }

    func testRevealAnswerDoesNotRecordSRSAndPersistsAttempt() async throws {
        let viewModel = makeViewModel()

        viewModel.revealAnswer()
        try await viewModel.finish(confidence: .uncertain)

        XCTAssertTrue(mockSRS.recordedCalls.isEmpty)
        XCTAssertEqual(mockAttempts.saved.count, 1)
        XCTAssertFalse(mockAttempts.saved[0].retrieveSucceeded)
    }

    func testSkipDoesNotRecordSRSAndPersistsAttempt() async throws {
        let viewModel = makeViewModel()

        viewModel.skip()
        try await viewModel.finish(confidence: .uncertain)

        XCTAssertTrue(mockSRS.recordedCalls.isEmpty)
        XCTAssertEqual(mockAttempts.saved.count, 1)
    }

    func testHintsProgressWithoutChangingStageOrCorrectness() {
        let viewModel = makeViewModel()

        viewModel.advanceHint()
        viewModel.advanceHint()

        XCTAssertEqual(viewModel.state.visibleHintLevel, 2)
        XCTAssertEqual(viewModel.state.maxHintLevel, 2)
        XCTAssertEqual(viewModel.state.phase, .retrieve)
        XCTAssertFalse(viewModel.state.retrieveSucceeded)
        XCTAssertFalse(viewModel.state.useSucceeded)
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
        XCTAssertEqual(viewModel.state.phase, .retrieve)
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .voice)

        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.phase, .retrieve)
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .typing)
    }

    func testNonmatchingUseSpeechGetsOneRetryThenTypingFallback() {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("ephemeral")
        XCTAssertEqual(viewModel.state.phase, .useInSentence)

        mockSTT.recognizedText = "a sentence without the word"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.phase, .useInSentence)
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .voice)

        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.phase, .useInSentence)
        XCTAssertEqual(viewModel.state.retryCount, 1)
        XCTAssertEqual(viewModel.state.inputMode, .typing)
    }

    func testStaleRecordingCallbackCannotAdvanceUseStage() {
        let viewModel = makeViewModel()

        viewModel.startRecording()
        mockSTT.simulateResult("ephemeral")
        XCTAssertEqual(viewModel.state.phase, .useInSentence)

        mockSTT.simulateResult("A second stale result says ephemeral.")

        XCTAssertEqual(viewModel.state.phase, .useInSentence)
        XCTAssertFalse(viewModel.state.useSucceeded)
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

    func testUseStageAnswerCannotReturnToRetrieve() {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("ephemeral")
        XCTAssertEqual(viewModel.state.phase, .useInSentence)

        viewModel.submitTypedAnswer("This sentence omits the expression")

        XCTAssertEqual(viewModel.state.phase, .result)
        XCTAssertFalse(viewModel.state.useSucceeded)
    }

    func testTransitionToUseStageResetsSpeechRetryAllowance() {
        let viewModel = makeViewModel()
        mockSTT.recognizedText = "not the target"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.retryCount, 1)

        viewModel.submitTypedAnswer("ephemeral")

        XCTAssertEqual(viewModel.state.phase, .useInSentence)
        XCTAssertEqual(viewModel.state.retryCount, 1)

        mockSTT.recognizedText = "a sentence without the target"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        XCTAssertEqual(viewModel.state.retryCount, 2)
        XCTAssertEqual(viewModel.state.inputMode, .voice)
    }

    func testRetrieveRequiresExactNormalizedTargetExpression() {
        let viewModel = makeViewModel()

        viewModel.submitTypedAnswer("The answer is ephemeral")

        XCTAssertEqual(viewModel.state.phase, .retrieve)
        XCTAssertFalse(viewModel.state.retrieveSucceeded)

        viewModel.submitTypedAnswer("EPHEMERAL!")
        XCTAssertEqual(viewModel.state.phase, .useInSentence)
    }

    func testUseStageSkipPersistsDeferredAttemptWithoutSRS() async throws {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("ephemeral")

        viewModel.skip()
        try await viewModel.finish(confidence: .uncertain)

        XCTAssertEqual(mockAttempts.saved.count, 1)
        XCTAssertTrue(mockAttempts.saved[0].retrieveSucceeded)
        XCTAssertFalse(mockAttempts.saved[0].useSucceeded)
        XCTAssertTrue(mockSRS.recordedCalls.isEmpty)
    }

    func testUseStageRevealPersistsDeferredAttemptWithoutSRS() async throws {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("ephemeral")

        viewModel.revealAnswer()
        try await viewModel.finish(confidence: .uncertain)

        XCTAssertEqual(mockAttempts.saved.count, 1)
        XCTAssertTrue(mockAttempts.saved[0].retrieveSucceeded)
        XCTAssertFalse(mockAttempts.saved[0].useSucceeded)
        XCTAssertTrue(mockSRS.recordedCalls.isEmpty)
    }

    func testFinishPersistsRetryTotalAcrossBothStages() async throws {
        let viewModel = makeViewModel()

        mockSTT.recognizedText = "wrong"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        viewModel.submitTypedAnswer("ephemeral")

        mockSTT.recognizedText = "a sentence without the target"
        viewModel.startRecording()
        viewModel.stopRecordingAndEvaluate()
        viewModel.submitTypedAnswer("The trend is ephemeral.")
        try await viewModel.finish(confidence: .comfortable)

        XCTAssertEqual(mockAttempts.saved.first?.retryCount, 2)
    }

    func testSentenceFrameHintPersistsAsHighestHintLevel() async throws {
        let viewModel = makeViewModel()
        viewModel.submitTypedAnswer("ephemeral")

        viewModel.advanceHint()
        viewModel.submitTypedAnswer("The trend is ephemeral.")
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
        XCTAssertEqual(viewModel.state.retrieveTimeMs, 5_000)
        XCTAssertEqual(viewModel.state.visibleHintLevel, 0)
    }

    func testRevealAnswerCarriesTargetExpressionIntoResult() {
        let viewModel = makeViewModel()

        viewModel.revealAnswer()

        XCTAssertEqual(viewModel.state.phase, .result)
        XCTAssertEqual(viewModel.state.revealedTargetExpression, "Ephemeral")
    }

    func testHintTimingUsesTwoRetrieveHintsAndOneUseSentenceFrame() {
        XCTAssertEqual(QuickReflexHintTiming.automaticDelaySeconds(for: .retrieve), [4, 7])
        XCTAssertEqual(QuickReflexHintTiming.automaticDelaySeconds(for: .useInSentence), [5])
    }

    func testFailedPersistenceLeavesResultRetryableUntilFinishSucceeds() async throws {
        let failingAttempts = FailingOnceQuickReflexAttemptRepository()
        let viewModel = makeViewModel(attemptRepository: failingAttempts)
        viewModel.submitTypedAnswer("ephemeral")
        viewModel.submitTypedAnswer("The trend is ephemeral.")

        await XCTAssertThrowsErrorAsync(try await viewModel.finish(confidence: .comfortable))

        XCTAssertEqual(viewModel.state.phase, .result)
        XCTAssertFalse(viewModel.state.isCompleted)
        XCTAssertNil(viewModel.state.srsResult)

        try await viewModel.finish(confidence: .comfortable)

        XCTAssertTrue(viewModel.state.isCompleted)
        XCTAssertEqual(failingAttempts.saveCallCount, 2)
        XCTAssertEqual(mockSRS.recordedCalls.count, 1)
    }

    func testCancellingDuringFinishPreventsPersistingOrRecordingSRS() async throws {
        let suspendedAttempts = SuspendedQuickReflexAttemptRepository()
        let viewModel = makeViewModel(attemptRepository: suspendedAttempts)
        viewModel.submitTypedAnswer("ephemeral")
        viewModel.submitTypedAnswer("The trend is ephemeral.")

        let finishTask = Task { try? await viewModel.finish(confidence: .comfortable) }
        await fulfillment(of: [suspendedAttempts.saveStarted], timeout: 1)

        viewModel.cancel()
        finishTask.cancel()
        suspendedAttempts.resumeSave()
        _ = await finishTask.result

        XCTAssertTrue(viewModel.state.isCancelled)
        XCTAssertFalse(viewModel.state.isCompleted)
        XCTAssertFalse(viewModel.state.isFinishing)
        XCTAssertTrue(suspendedAttempts.persistedAttempts.isEmpty)
        XCTAssertTrue(mockSRS.recordedCalls.isEmpty)
    }

    private func makeViewModel(
        attemptRepository: QuickReflexAttemptRepositoryProtocol? = nil,
        clock: @escaping () -> Date = Date.init
    ) -> QuickReflexDrillViewModel {
        QuickReflexDrillViewModel(
            targetWord: targetWord,
            allWords: [targetWord],
            sttService: mockSTT,
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
        saved.last(where: { $0.wordId == wordId && $0.retrieveSucceeded })
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
