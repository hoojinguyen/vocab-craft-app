@testable import VocabCraftApp
import XCTest

@MainActor
final class MockSpeechAssessmentServiceForViewModel: SpeechAssessmentProtocol {
    var isListening: Bool = false
    var currentEvaluation: SpeechEvaluationResult?

    var didStartAssessing = false
    var didStopAssessing = false
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
        self.didStartAssessing = true
        self.isListening = true
        self.targetSentence = targetSentence
        self.toleranceThreshold = toleranceThreshold
        self.contextualPhrases = contextualPhrases
        self.onProgressHandler = onProgress
        self.onCompletionHandler = onCompletion
        self.onErrorHandler = onError
    }

    func stopAssessing() {
        self.didStopAssessing = true
        self.isListening = false
    }

    func simulateProgress(_ result: SpeechEvaluationResult) {
        self.currentEvaluation = result
        self.onProgressHandler?(result)
    }

    func simulateCompletion(_ result: SpeechEvaluationResult) {
        self.currentEvaluation = result
        self.isListening = false
        self.onCompletionHandler?(result)
    }

    func simulateError(_ error: Error) {
        self.isListening = false
        self.onErrorHandler?(error)
    }
}

@MainActor
final class ReflexDrillViewModelSpeechTests: XCTestCase {
    private var mockSpeechAssessment: MockSpeechAssessmentServiceForViewModel!
    private var mockTTS: MockTextToSpeechService!
    private var mockSTT: MockSpeechRecognitionService!
    private var mockFetchUseCase: MockFetchVocabularyUseCase!
    private var mockSRSUseCase: MockEvaluateSRSUseCase!
    private var viewModel: ReflexDrillViewModel!

    override func setUp() {
        super.setUp()
        mockSpeechAssessment = MockSpeechAssessmentServiceForViewModel()
        mockTTS = MockTextToSpeechService()
        mockSTT = MockSpeechRecognitionService()
        mockFetchUseCase = MockFetchVocabularyUseCase()
        mockSRSUseCase = MockEvaluateSRSUseCase()

        viewModel = ReflexDrillViewModel(
            fetchVocabularyUseCase: mockFetchUseCase,
            evaluateSRSUseCase: mockSRSUseCase,
            ttsService: mockTTS,
            sttService: mockSTT,
            speechAssessmentService: mockSpeechAssessment,
            cefrLevel: "B1"
        )
        viewModel.setupSampleDrill()
    }

    override func tearDown() {
        viewModel = nil
        mockSpeechAssessment = nil
        mockTTS = nil
        mockSTT = nil
        mockFetchUseCase = nil
        mockSRSUseCase = nil
        super.tearDown()
    }

    func testInitializationWithMockAssessmentService() {
        XCTAssertFalse(viewModel.isListening)
        XCTAssertNil(viewModel.speechEvaluationResult)
        XCTAssertEqual(viewModel.recognizedText, "")
        XCTAssertNotNil(viewModel.state.drill)
        XCTAssertEqual(viewModel.state.drill?.correctAnswer, "A black dog jumps over the fence")
    }

    func testMicrophoneTapStartsSpeechAssessment() {
        viewModel.handleMicTap()

        XCTAssertTrue(mockSpeechAssessment.didStartAssessing)
        XCTAssertTrue(viewModel.isListening)
        XCTAssertEqual(mockSpeechAssessment.targetSentence, "A black dog jumps over the fence")
        XCTAssertTrue(mockSpeechAssessment.contextualPhrases.contains("A black dog jumps over the fence"))
        XCTAssertFalse(viewModel.state.isEvaluated)
    }

    func testToggleListeningStartsAndStopsAssessment() {
        viewModel.toggleListening()
        XCTAssertTrue(viewModel.isListening)

        viewModel.toggleListening()
        XCTAssertFalse(viewModel.isListening)
        XCTAssertTrue(mockSpeechAssessment.didStopAssessing)
    }

    func testProgressUpdateUpdatesRecognizedTextAndEvaluationResult() {
        viewModel.startListening()

        let partialResult = SpeechEvaluationResult(
            targetSentence: "A black dog jumps over the fence",
            spokenText: "A black dog",
            tokens: [
                WordTokenResult(id: 0, targetWord: "A", spokenWord: "a", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 1, targetWord: "black", spokenWord: "black", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 2, targetWord: "dog", spokenWord: "dog", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 3, targetWord: "jumps", spokenWord: nil, status: .missing, similarityScore: 0.0),
                WordTokenResult(id: 4, targetWord: "over", spokenWord: nil, status: .missing, similarityScore: 0.0),
                WordTokenResult(id: 5, targetWord: "the", spokenWord: nil, status: .missing, similarityScore: 0.0),
                WordTokenResult(id: 6, targetWord: "fence", spokenWord: nil, status: .missing, similarityScore: 0.0)
            ],
            overallScore: 0.42,
            isPassed: false,
            durationMs: 900
        )

        mockSpeechAssessment.simulateProgress(partialResult)

        XCTAssertEqual(viewModel.recognizedText, "A black dog")
        XCTAssertEqual(viewModel.speechEvaluationResult?.overallScore, 0.42)
        XCTAssertEqual(viewModel.speechEvaluationResult?.tokens.count, 7)
        XCTAssertFalse(viewModel.state.isEvaluated)
    }

    func testPassingEvaluationImmediatelyCompletesDrillCard() {
        viewModel.startListening()
        viewModel.startDrillTimer()

        let passingResult = SpeechEvaluationResult(
            targetSentence: "A black dog jumps over the fence",
            spokenText: "A black dog jumps over the fence",
            tokens: [
                WordTokenResult(id: 0, targetWord: "A", spokenWord: "a", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 1, targetWord: "black", spokenWord: "black", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 2, targetWord: "dog", spokenWord: "dog", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 3, targetWord: "jumps", spokenWord: "jumps", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 4, targetWord: "over", spokenWord: "over", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 5, targetWord: "the", spokenWord: "the", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 6, targetWord: "fence", spokenWord: "fence", status: .exactMatch, similarityScore: 1.0)
            ],
            overallScore: 1.0,
            isPassed: true,
            durationMs: 1450
        )

        mockSpeechAssessment.simulateCompletion(passingResult)

        XCTAssertTrue(viewModel.state.isEvaluated)
        XCTAssertTrue(viewModel.state.isCorrect)
        XCTAssertTrue(viewModel.state.triggerSparkle)
        XCTAssertEqual(viewModel.state.currentMastery, 1)
        XCTAssertNotNil(viewModel.state.srsResult)
    }

    func testSilenceTimeoutOrFailedSpeech_triggersEvaluationAndShowsFeedback() {
        viewModel.startVoiceRecognition()
        XCTAssertTrue(viewModel.isListening)

        let failedResult = SpeechEvaluationResult(
            targetSentence: "A black dog jumps over the fence",
            spokenText: "A red cat",
            tokens: [],
            overallScore: 20.0,
            isPassed: false,
            durationMs: 2500
        )
        mockSpeechAssessment.simulateCompletion(failedResult)

        XCTAssertFalse(viewModel.isListening)
        XCTAssertTrue(viewModel.state.isEvaluated)
        XCTAssertFalse(viewModel.state.isCorrect)
        XCTAssertFalse(viewModel.state.feedbackText.isEmpty)
    }

    func testMicrophoneTapWhileListeningManuallyStopsAndEvaluates() {
        viewModel.startListening()

        let partialResult = SpeechEvaluationResult(
            targetSentence: "A black dog jumps over the fence",
            spokenText: "A black dog jumps",
            tokens: [
                WordTokenResult(id: 0, targetWord: "A", spokenWord: "a", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 1, targetWord: "black", spokenWord: "black", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 2, targetWord: "dog", spokenWord: "dog", status: .exactMatch, similarityScore: 1.0),
                WordTokenResult(id: 3, targetWord: "jumps", spokenWord: "jumps", status: .exactMatch, similarityScore: 1.0)
            ],
            overallScore: 0.57,
            isPassed: false,
            durationMs: 1200
        )
        mockSpeechAssessment.simulateProgress(partialResult)

        // User taps mic to manually submit speech
        viewModel.handleMicTap()

        XCTAssertFalse(viewModel.isListening)
        XCTAssertTrue(viewModel.state.isEvaluated)
    }

    func testSpeechKitErrorPresentsAlert() {
        viewModel.startListening()

        mockSpeechAssessment.simulateError(SpeechKitError.microphoneNotAuthorized)

        XCTAssertFalse(viewModel.isListening)
        XCTAssertTrue(viewModel.state.showErrorAlert)
        XCTAssertEqual(viewModel.state.errorMessage, SpeechKitError.microphoneNotAuthorized.errorDescription)
    }
}
