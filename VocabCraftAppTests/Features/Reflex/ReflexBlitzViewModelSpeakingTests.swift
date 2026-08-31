@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class ReflexBlitzViewModelSpeakingTests: XCTestCase {
    private var mockSpeechEngine: MockResilientReflexSpeechEngine!
    private var mockTTS: MockTextToSpeechService!
    private var mockSRS: MockEvaluateSRSUseCase!
    private var mockSound: MockSoundEffectService!
    private var viewModel: ReflexBlitzViewModel!

    private let sampleWords = [
        ReflexBlitzWordItem(
            id: 1, lemma: "ephemeral", pos: "adj.",
            definitionVi: "Phù du", exampleSentenceEn: "Fame is ephemeral",
            exampleSentenceVi: "Danh tiếng thì phù du"
        ),
        ReflexBlitzWordItem(
            id: 2, lemma: "vital", pos: "adj.",
            definitionVi: "Quan trọng", exampleSentenceEn: "Water is vital",
            exampleSentenceVi: "Nước là sống còn"
        )
    ]

    override func setUp() {
        super.setUp()
        mockSpeechEngine = MockResilientReflexSpeechEngine()
        mockTTS = MockTextToSpeechService()
        mockSRS = MockEvaluateSRSUseCase()
        mockSound = MockSoundEffectService()

        viewModel = ReflexBlitzViewModel(
            words: sampleWords,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS,
            soundEffectService: mockSound,
            speechEngine: mockSpeechEngine
        )
    }

    override func tearDown() {
        viewModel = nil
        mockSpeechEngine = nil
        mockTTS = nil
        mockSRS = nil
        mockSound = nil
        super.tearDown()
    }

    // MARK: - Session Lifecycle

    func testSpeakingMode_startCountdown_startsEngine() {
        viewModel.selectMode(.speaking)
        XCTAssertTrue(mockSpeechEngine.isSessionActive)
        XCTAssertEqual(mockSpeechEngine.startSessionCallCount, 1)
    }

    func testSpeakingMode_beginDrilling_callsBeginWord() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        XCTAssertEqual(mockSpeechEngine.beginWordCallCount, 1)
        XCTAssertEqual(mockSpeechEngine.lastTargetLemma, "ephemeral")
        XCTAssertTrue(mockSpeechEngine.isWordActive)
    }

    // MARK: - Match Detection

    func testSpeakingMode_matchDetected_transitionsToReviewed() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        mockSpeechEngine.simulateMatch("ephemeral")

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
        } else {
            XCTFail("Expected reviewed state")
        }
    }

    func testSpeakingMode_matchDetected_callsEndWord() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        mockSpeechEngine.simulateMatch("ephemeral")
        XCTAssertEqual(mockSpeechEngine.endWordCallCount, 1)
        XCTAssertEqual(mockSpeechEngine.isWordActive, false)
    }

    func testSpeakingMode_matchDetected_playsSuccessChime() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        mockSpeechEngine.simulateMatch("ephemeral")
        XCTAssertTrue(mockSound.successChimePlayed)
    }

    // MARK: - Timeout

    func testSpeakingMode_timeout_transitionsToReviewed() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 6000)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertFalse(result.isCorrect)
            XCTAssertTrue(result.isTimeout)
        } else {
            XCTFail("Expected reviewed state")
        }
    }

    func testSpeakingMode_timeout_callsEndWord() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 6000)
        XCTAssertTrue(mockSpeechEngine.endWordCallCount >= 1)
    }

    // MARK: - Transcript Updates

    func testSpeakingMode_transcriptUpdate_reflectedInViewModel() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        mockSpeechEngine.simulateTranscript("hello world")
        XCTAssertEqual(viewModel.liveTranscript, "hello world")
    }

    // MARK: - Word Transition

    func testSpeakingMode_advanceToNextWord_cyclesBeginEndWord() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        let initialBeginCount = mockSpeechEngine.beginWordCallCount

        mockSpeechEngine.simulateMatch("ephemeral")
        viewModel.advanceToNextWord()

        XCTAssertEqual(mockSpeechEngine.beginWordCallCount, initialBeginCount + 1)
        XCTAssertEqual(mockSpeechEngine.lastTargetLemma, "vital")
    }

    // MARK: - Hint Progression

    func testSpeakingMode_hintStage1_at2500ms() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 2500)
        XCTAssertGreaterThanOrEqual(viewModel.hintStage, 1)
    }

    func testSpeakingMode_hintStage2_at4000ms() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 4000)
        XCTAssertGreaterThanOrEqual(viewModel.hintStage, 2)
    }

    func testSpeakingMode_hintStage3_at5000ms() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 5000)
        XCTAssertGreaterThanOrEqual(viewModel.hintStage, 3)
    }

    // MARK: - Keyboard Fallback & Error Handling

    func testSpeakingMode_speechEngineError_activatesKeyboardFallback() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        XCTAssertFalse(viewModel.isKeyboardFallbackActive)

        let testError = NSError(domain: "test", code: 403, userInfo: nil)
        mockSpeechEngine.simulateError(testError)

        XCTAssertTrue(viewModel.isKeyboardFallbackActive)
    }

    func testSpeakingMode_advanceWithKeyboardFallback_doesNotCallBeginWord() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.toggleKeyboardFallback()
        XCTAssertTrue(viewModel.isKeyboardFallbackActive)

        let countBeforeAdvance = mockSpeechEngine.beginWordCallCount
        viewModel.advanceToNextWord()

        XCTAssertEqual(viewModel.currentWord?.lemma, "vital")
        XCTAssertEqual(mockSpeechEngine.beginWordCallCount, countBeforeAdvance)
    }

    func testSpeakingMode_startDrillSession_resetsKeyboardFallback() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.toggleKeyboardFallback()
        XCTAssertTrue(viewModel.isKeyboardFallbackActive)

        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        XCTAssertFalse(viewModel.isKeyboardFallbackActive)
    }

    func testSpeakingMode_cancelSession_duringKeyboardFallback_doesNotCallBeginWord() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.toggleKeyboardFallback()
        XCTAssertTrue(viewModel.isKeyboardFallbackActive)

        let countBeforeCancel = mockSpeechEngine.beginWordCallCount
        viewModel.cancelSession()

        XCTAssertFalse(viewModel.isKeyboardFallbackActive)
        XCTAssertEqual(mockSpeechEngine.beginWordCallCount, countBeforeCancel)
        XCTAssertFalse(mockSpeechEngine.isSessionActive)
    }

    // MARK: - Session End

    func testSpeakingMode_finishSession_stopsEngine() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.finishSession()
        XCTAssertEqual(mockSpeechEngine.stopSessionCallCount, 1)
        XCTAssertFalse(mockSpeechEngine.isSessionActive)
    }
}
