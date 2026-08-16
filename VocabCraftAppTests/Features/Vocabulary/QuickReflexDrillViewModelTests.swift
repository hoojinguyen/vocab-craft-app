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

    private func makeViewModel() -> QuickReflexDrillViewModel {
        QuickReflexDrillViewModel(
            targetWord: targetWord,
            allWords: [targetWord],
            sttService: mockSTT,
            evaluateSRSUseCase: mockSRS,
            attemptRepository: mockAttempts
        )
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
