@testable import VocabCraftApp
import XCTest

@MainActor
final class ReflexBlitzViewModelTests: XCTestCase {
    private var mockSpeech: MockContinuousReflexSpeechService!
    private var mockTTS: MockTextToSpeechService!
    private var mockSRS: MockEvaluateSRSUseCase!
    private var viewModel: ReflexBlitzViewModel!

    private let sampleWords = [
        ReflexBlitzWordItem(
            id: 1,
            lemma: "ephemeral",
            pos: "adj.",
            definitionVi: "Phù du, ngắn ngủi",
            exampleSentenceEn: "Fame is ephemeral in this modern era",
            exampleSentenceVi: "Danh tiếng thì phù du trong thời hiện đại"
        ),
        ReflexBlitzWordItem(
            id: 2,
            lemma: "vital",
            pos: "adj.",
            definitionVi: "Quan trọng, sống còn",
            exampleSentenceEn: "Water is vital for all living things",
            exampleSentenceVi: "Nước là sống còn cho mọi sinh vật"
        ),
        ReflexBlitzWordItem(
            id: 3,
            lemma: "serendipity",
            pos: "n.",
            definitionVi: "Sự tình cờ may mắn",
            exampleSentenceEn: "Finding that book was pure serendipity",
            exampleSentenceVi: "Tìm thấy cuốn sách đó là sự tình cờ may mắn thuần túy"
        )
    ]

    override func setUp() {
        super.setUp()
        mockSpeech = MockContinuousReflexSpeechService()
        mockTTS = MockTextToSpeechService()
        mockSRS = MockEvaluateSRSUseCase()

        viewModel = ReflexBlitzViewModel(
            words: sampleWords,
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )
    }

    override func tearDown() {
        viewModel = nil
        mockSpeech = nil
        mockTTS = nil
        mockSRS = nil
        super.tearDown()
    }

    func testInitialCountdownPhase() {
        XCTAssertEqual(viewModel.phase, .countdown)
        XCTAssertEqual(viewModel.countdownCount, 3)
        XCTAssertEqual(viewModel.words.count, 3)
        XCTAssertEqual(viewModel.currentWordIndex, 0)
        XCTAssertEqual(viewModel.progressFraction, 0.0)
    }

    func testStartDrillingAndAutoAdvanceOnCorrectMatch() async {
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.phase, .drilling)
        XCTAssertEqual(viewModel.currentWordIndex, 0)
        XCTAssertEqual(viewModel.currentWord?.lemma, "ephemeral")
        XCTAssertTrue(mockSpeech.isSessionActive)

        // Simulate correct speech recognition
        mockSpeech.simulateTranscript("ephemeral")

        XCTAssertTrue(viewModel.currentAttemptIsCorrect)
        XCTAssertEqual(viewModel.comboStreak, 1)
        XCTAssertEqual(viewModel.maxComboStreak, 1)
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.attempts.first?.lemma, "ephemeral")
        XCTAssertTrue(viewModel.attempts.first?.isCorrect ?? false)
    }

    func testHintRevealsAt3500ms() {
        viewModel.beginSessionDirectly()
        XCTAssertFalse(viewModel.showHint)

        viewModel.simulateElapsedTime(ms: 3600)
        XCTAssertTrue(viewModel.showHint)
    }

    func testSimulateElapsedTimeAt6000TriggersTimeout() {
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.phase, .drilling)

        viewModel.simulateElapsedTime(ms: 6000)
        XCTAssertEqual(viewModel.phase, .timeoutRevealing)
        XCTAssertEqual(viewModel.comboStreak, 0)
        XCTAssertEqual(mockTTS.lastSpokenText, "ephemeral")
    }

    func testTimeoutTriggersRevealTTSAndResetsCombo() {
        viewModel.beginSessionDirectly()
        viewModel.comboStreak = 4
        viewModel.maxComboStreak = 4

        viewModel.handleTimeout()

        XCTAssertEqual(viewModel.phase, .timeoutRevealing)
        XCTAssertEqual(viewModel.comboStreak, 0)
        XCTAssertEqual(viewModel.maxComboStreak, 4)
        XCTAssertEqual(mockTTS.lastSpokenText, "ephemeral")
        XCTAssertTrue(mockTTS.isSpeaking)
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertFalse(viewModel.attempts.first?.isCorrect ?? true)
        XCTAssertEqual(viewModel.attempts.first?.responseTimeMs, 6000)
    }

    func testConsecutiveMatchesBuildComboStreak() {
        viewModel.beginSessionDirectly()

        // Match word 1
        mockSpeech.simulateTranscript("ephemeral")
        XCTAssertEqual(viewModel.comboStreak, 1)
        XCTAssertEqual(viewModel.maxComboStreak, 1)

        // Advance to word 2 manually / simulate
        viewModel.handleSpokenMatch("vital") // Not active word yet since index is 0, so should be ignored
        XCTAssertEqual(viewModel.comboStreak, 1)

        viewModel.loadWordForTesting(at: 1)
        mockSpeech.simulateTranscript("The answer is vital today")
        XCTAssertEqual(viewModel.comboStreak, 2)
        XCTAssertEqual(viewModel.maxComboStreak, 2)

        // Word 3 times out -> combo reset
        viewModel.loadWordForTesting(at: 2)
        viewModel.handleTimeout()
        XCTAssertEqual(viewModel.comboStreak, 0)
        XCTAssertEqual(viewModel.maxComboStreak, 2)
    }

    func testSpokenMatchCaseInsensitivityAndWhitespaceTrimming() {
        viewModel.beginSessionDirectly()
        viewModel.handleSpokenMatch("  EPHEMERAL\n")

        XCTAssertTrue(viewModel.currentAttemptIsCorrect)
        XCTAssertEqual(viewModel.comboStreak, 1)
    }

    func testLiveTranscriptUpdatesPropagated() {
        viewModel.beginSessionDirectly()
        mockSpeech.simulateTranscript("Speaking some words...")

        XCTAssertEqual(viewModel.liveTranscript, "Speaking some words...")
    }

    func testKeyboardFallbackSubmission() {
        viewModel.beginSessionDirectly()
        viewModel.toggleKeyboardFallback()
        XCTAssertTrue(viewModel.isKeyboardFallbackActive)

        // Incorrect keyboard input
        viewModel.submitKeyboardInput("wrongword")
        XCTAssertFalse(viewModel.currentAttemptIsCorrect)
        XCTAssertEqual(viewModel.comboStreak, 0)

        // Correct keyboard input
        viewModel.submitKeyboardInput("  Ephemeral  ")
        XCTAssertTrue(viewModel.currentAttemptIsCorrect)
        XCTAssertEqual(viewModel.comboStreak, 1)
    }

    func testFinishSessionGeneratesSummary() {
        viewModel.beginSessionDirectly()

        // Attempt 1: Correct
        viewModel.handleSpokenMatch("ephemeral")

        // Attempt 2: Timeout
        viewModel.loadWordForTesting(at: 1)
        viewModel.handleTimeout()

        viewModel.finishSession()

        XCTAssertEqual(viewModel.phase, .summary)
        XCTAssertFalse(mockSpeech.isSessionActive)
        XCTAssertNotNil(viewModel.sessionSummary)
        XCTAssertEqual(viewModel.sessionSummary?.totalWords, 2)
        XCTAssertEqual(viewModel.sessionSummary?.correctWords, 1)
        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.count, 1)
        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.first?.lemma, "vital")
    }

    func testReDrillWeakWordsResetsSessionWithOnlyWeakWords() {
        viewModel.beginSessionDirectly()

        // Word 1: Correct
        viewModel.handleSpokenMatch("ephemeral")

        // Word 2: Timeout (weak)
        viewModel.loadWordForTesting(at: 1)
        viewModel.handleTimeout()

        // Word 3: Correct
        viewModel.loadWordForTesting(at: 2)
        viewModel.handleSpokenMatch("serendipity")

        viewModel.finishSession()

        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.count, 1)
        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.first?.wordId, 2)

        viewModel.reDrillWeakWords()

        XCTAssertEqual(viewModel.words.count, 1)
        XCTAssertEqual(viewModel.words.first?.id, 2)
        XCTAssertEqual(viewModel.words.first?.lemma, "vital")
        XCTAssertEqual(viewModel.phase, .countdown)
    }

    func testProgressFraction() {
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.progressFraction, 0.0)

        viewModel.loadWordForTesting(at: 1)
        XCTAssertEqual(viewModel.progressFraction, 1.0 / 3.0, accuracy: 0.001)

        viewModel.loadWordForTesting(at: 2)
        XCTAssertEqual(viewModel.progressFraction, 2.0 / 3.0, accuracy: 0.001)

        let emptyVM = ReflexBlitzViewModel(
            words: [],
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )
        XCTAssertEqual(emptyVM.progressFraction, 0.0)
        XCTAssertNil(emptyVM.currentWord)
    }

    func testCancelSessionStopsServices() {
        viewModel.beginSessionDirectly()
        XCTAssertTrue(mockSpeech.isSessionActive)

        viewModel.cancelSession()
        XCTAssertFalse(mockSpeech.isSessionActive)
        XCTAssertFalse(mockTTS.isSpeaking)
    }

    func testStartCountdownInitializesSession() {
        viewModel.startCountdown()
        XCTAssertEqual(viewModel.phase, .countdown)
        XCTAssertEqual(viewModel.countdownCount, 3)
        XCTAssertTrue(mockSpeech.isSessionActive)
    }
}
