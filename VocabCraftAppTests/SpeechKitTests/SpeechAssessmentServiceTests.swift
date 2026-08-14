import XCTest
@testable import VocabCraftApp

// MARK: - Mock Speech Recognition Engine

final class MockSpeechRecognitionEngine: SpeechRecognitionEngineProtocol, @unchecked Sendable {
    var isRecording: Bool = false
    var requestAuthResult: Bool = true
    var contextualPhrasesPassed: [String] = []

    var onPartialResultHandler: (@Sendable (String) -> Void)?
    var onFinalResultHandler: (@Sendable (String) -> Void)?
    var onErrorHandler: (@Sendable (Error) -> Void)?

    var startCallCount: Int = 0
    var stopCallCount: Int = 0
    var shouldThrowOnStart: Error?

    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        completion(requestAuthResult)
    }

    func start(
        contextualPhrases: [String],
        onPartialResult: @escaping @Sendable (String) -> Void,
        onFinalResult: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws {
        if let error = shouldThrowOnStart {
            throw error
        }
        startCallCount += 1
        isRecording = true
        contextualPhrasesPassed = contextualPhrases
        onPartialResultHandler = onPartialResult
        onFinalResultHandler = onFinalResult
        onErrorHandler = onError
    }

    func stop() {
        stopCallCount += 1
        isRecording = false
    }

    func simulatePartialResult(_ text: String) {
        onPartialResultHandler?(text)
    }

    func simulateFinalResult(_ text: String) {
        onFinalResultHandler?(text)
    }

    func simulateError(_ error: Error) {
        onErrorHandler?(error)
    }
}

// MARK: - SpeechAssessmentService Tests

@MainActor
final class SpeechAssessmentServiceTests: XCTestCase {

    var mockEngine: MockSpeechRecognitionEngine!
    var service: SpeechAssessmentService!

    override func setUp() {
        super.setUp()
        mockEngine = MockSpeechRecognitionEngine()
        service = SpeechAssessmentService(
            recognitionEngine: mockEngine,
            silenceDuration: .milliseconds(80)
        )
    }

    override func tearDown() {
        service.stopAssessing()
        mockEngine = nil
        service = nil
        super.tearDown()
    }

    func testStartAssessing_emptyTargetSentence_triggersEmptyTargetSentenceError() async {
        let expectation = expectation(description: "Error received for empty target")
        var receivedError: Error?

        service.startAssessing(
            targetSentence: "   ",
            onError: { error in
                receivedError = error
                expectation.fulfill()
            }
        )

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError as? SpeechKitError, .emptyTargetSentence)
        XCTAssertFalse(service.isListening)
        XCTAssertEqual(mockEngine.startCallCount, 0)
    }

    func testStartAssessing_setsIsListeningAndConfiguresContextualPhrases() {
        let target = "The quick brown fox jumps over the lazy dog"
        let contextual = ["fox", "quick"]

        service.startAssessing(
            targetSentence: target,
            contextualPhrases: contextual
        )

        XCTAssertTrue(service.isListening)
        XCTAssertTrue(mockEngine.isRecording)
        XCTAssertEqual(mockEngine.startCallCount, 1)
        // Verifies contextual phrases include vocabulary and target sentence
        XCTAssertTrue(mockEngine.contextualPhrasesPassed.contains("fox"))
        XCTAssertTrue(mockEngine.contextualPhrasesPassed.contains("quick"))
        XCTAssertTrue(mockEngine.contextualPhrasesPassed.contains(target))
    }

    func testPartialResult_belowThreshold_emitsProgress_doesNotComplete() async {
        let target = "A black dog jumps over the fence."
        let progressExpectation = expectation(description: "Progress callback received")
        var progressResult: SpeechEvaluationResult?
        var didComplete = false

        service.startAssessing(
            targetSentence: target,
            toleranceThreshold: 0.75,
            onProgress: { result in
                progressResult = result
                progressExpectation.fulfill()
            },
            onCompletion: { _ in
                didComplete = true
            }
        )

        // Partial speech with low score (only "a black")
        mockEngine.simulatePartialResult("a black")

        await fulfillment(of: [progressExpectation], timeout: 1.0)

        XCTAssertNotNil(progressResult)
        XCTAssertFalse(progressResult!.isPassed)
        XCTAssertLessThan(progressResult!.overallScore, 75.0)
        XCTAssertFalse(didComplete)
        XCTAssertTrue(service.isListening)
        XCTAssertEqual(service.currentEvaluation?.spokenText, "a black")
    }

    func testPartialResult_reachesThreshold_instantReflexTrigger_completesImmediately() async {
        let target = "A black dog jumps over the fence."
        let completionExpectation = expectation(description: "Instant reflex completion received")
        var completionResult: SpeechEvaluationResult?

        service.startAssessing(
            targetSentence: target,
            toleranceThreshold: 0.75,
            onCompletion: { result in
                completionResult = result
                completionExpectation.fulfill()
            }
        )

        // Spoken text matching exact target -> 100% score >= 75%
        mockEngine.simulatePartialResult("a black dog jumps over the fence")

        await fulfillment(of: [completionExpectation], timeout: 1.0)

        XCTAssertNotNil(completionResult)
        XCTAssertTrue(completionResult!.isPassed)
        XCTAssertEqual(completionResult!.overallScore, 100.0, accuracy: 1e-6)
        XCTAssertFalse(service.isListening)
        XCTAssertEqual(mockEngine.stopCallCount, 1)
    }

    func testAccentTolerance_instantPassWithMinorInflections() async {
        let target = "A black dog jumps over the fence."
        let completionExpectation = expectation(description: "Accent tolerant pass completed")
        var completionResult: SpeechEvaluationResult?

        service.startAssessing(
            targetSentence: target,
            toleranceThreshold: 0.75,
            onCompletion: { result in
                completionResult = result
                completionExpectation.fulfill()
            }
        )

        // Spoken with missing "s" on jumps and missing article "the" (~82.8% score >= 75%)
        mockEngine.simulatePartialResult("a black dog jump over fence")

        await fulfillment(of: [completionExpectation], timeout: 1.0)

        XCTAssertNotNil(completionResult)
        XCTAssertTrue(completionResult!.isPassed)
        XCTAssertGreaterThanOrEqual(completionResult!.overallScore, 75.0)
        XCTAssertFalse(service.isListening)
    }

    func testSilenceTimeout_stopsAndEmitsFinalEvaluation() async {
        let target = "I would like a cup of coffee please."
        let completionExpectation = expectation(description: "Silence auto-stop completion")
        var completionResult: SpeechEvaluationResult?

        service.startAssessing(
            targetSentence: target,
            toleranceThreshold: 0.75,
            onCompletion: { result in
                completionResult = result
                completionExpectation.fulfill()
            }
        )

        // Spoken partial text (< 75%)
        mockEngine.simulatePartialResult("i would like a cup")

        // Wait for silence detector (80ms + buffer) to trigger
        await fulfillment(of: [completionExpectation], timeout: 1.0)

        XCTAssertNotNil(completionResult)
        XCTAssertFalse(completionResult!.isPassed)
        XCTAssertFalse(service.isListening)
        XCTAssertEqual(mockEngine.stopCallCount, 1)
        XCTAssertEqual(completionResult?.spokenText, "i would like a cup")
    }

    func testStopAssessing_manuallyStopsListeningAndEngine() {
        service.startAssessing(targetSentence: "Hello world")
        XCTAssertTrue(service.isListening)
        XCTAssertTrue(mockEngine.isRecording)

        service.stopAssessing()

        XCTAssertFalse(service.isListening)
        XCTAssertEqual(mockEngine.stopCallCount, 1)
    }

    func testEngineError_forwardsToOnErrorAndStopsListening() async {
        let errorExpectation = expectation(description: "Engine error forwarded")
        var receivedError: Error?

        service.startAssessing(
            targetSentence: "Hello world",
            onError: { error in
                receivedError = error
                errorExpectation.fulfill()
            }
        )

        mockEngine.simulateError(SpeechKitError.recognizerUnavailable)

        await fulfillment(of: [errorExpectation], timeout: 1.0)

        XCTAssertEqual(receivedError as? SpeechKitError, .recognizerUnavailable)
        XCTAssertFalse(service.isListening)
        XCTAssertEqual(mockEngine.stopCallCount, 1)
    }
}
