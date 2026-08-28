import Testing
@testable import VocabCraftApp
import XCTest

@MainActor
final class ReflexBlitzViewModelTests: XCTestCase {
    private var mockSpeech: MockContinuousReflexSpeechService!
    private var mockTTS: MockTextToSpeechService!
    private var mockSRS: MockEvaluateSRSUseCase!
    private var mockSound: MockSoundEffectService!
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
        mockSound = MockSoundEffectService()

        viewModel = ReflexBlitzViewModel(
            words: sampleWords,
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS,
            soundEffectService: mockSound
        )
    }

    override func tearDown() {
        viewModel = nil
        mockSpeech = nil
        mockTTS = nil
        mockSRS = nil
        mockSound = nil
        super.tearDown()
    }

    // MARK: - Initial State & Mode Selection

    func testInitialPhaseIsModeSelection() {
        XCTAssertEqual(viewModel.phase, .modeSelection)
        XCTAssertEqual(viewModel.selectedMode, .speaking)
        XCTAssertEqual(viewModel.cardPhase, .activeCountdown)
        XCTAssertEqual(viewModel.words.count, 3)
        XCTAssertEqual(viewModel.currentWordIndex, 0)
        XCTAssertEqual(viewModel.progressFraction, 0.0)
    }

    func testModeSelectionStartsCountdown() {
        viewModel.selectMode(.multipleChoice)
        XCTAssertEqual(viewModel.selectedMode, .multipleChoice)
        XCTAssertEqual(viewModel.phase, .countdown)
        XCTAssertEqual(viewModel.countdownCount, 3)
    }

    // MARK: - Multiple Choice Modality

    func testMultipleChoiceCorrectOptionTransitionsToReviewed() {
        viewModel.selectMode(.multipleChoice)
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.phase, .drilling)
        XCTAssertEqual(viewModel.currentOptions.count, 4)

        guard let correctOption = viewModel.currentOptions.first(where: { $0.isCorrect }) else {
            XCTFail("No correct option found")
            return
        }
        XCTAssertEqual(correctOption.text, "ephemeral")

        viewModel.simulateElapsedTime(ms: 1200)
        viewModel.selectOption(correctOption)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.selectedOption, "ephemeral")
            XCTAssertEqual(result.responseTimeMs, 1200)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        XCTAssertEqual(viewModel.comboStreak, 1)
        XCTAssertEqual(viewModel.maxComboStreak, 1)
        XCTAssertEqual(mockSound.playSuccessChimeCallCount, 1)
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.attempts.first?.lemma, "ephemeral")
        XCTAssertEqual(viewModel.attempts.first?.isCorrect, true)
        XCTAssertEqual(viewModel.attempts.first?.responseTimeMs, 1200)
    }

    func testMultipleChoiceIncorrectOptionTransitionsToReviewed() {
        viewModel.selectMode(.multipleChoice)
        viewModel.beginSessionDirectly()
        viewModel.comboStreak = 3
        viewModel.maxComboStreak = 3

        guard let incorrectOption = viewModel.currentOptions.first(where: { !$0.isCorrect }) else {
            XCTFail("No incorrect option found")
            return
        }

        viewModel.simulateElapsedTime(ms: 2000)
        viewModel.selectOption(incorrectOption)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertFalse(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.selectedOption, incorrectOption.text)
            XCTAssertEqual(result.responseTimeMs, 2000)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        XCTAssertEqual(viewModel.comboStreak, 0)
        XCTAssertEqual(viewModel.maxComboStreak, 3)
        XCTAssertEqual(mockSound.playSuccessChimeCallCount, 0)
        XCTAssertEqual(mockSound.playIncorrectChimeCallCount, 1)
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.attempts.first?.isCorrect, false)
        XCTAssertEqual(viewModel.attempts.first?.responseTimeMs, 2000)
    }

    func testIncorrectOptionTriggersIncorrectChime() {
        viewModel.selectMode(.multipleChoice)
        viewModel.beginSessionDirectly()
        guard let wrongOption = viewModel.currentOptions.first(where: { !$0.isCorrect }) else {
            XCTFail("No wrong option found")
            return
        }
        viewModel.selectOption(wrongOption)
        XCTAssertEqual(mockSound.playIncorrectChimeCallCount, 1)
    }

    // MARK: - Typing Modality

    func testTypingModeCorrectSubmissionTransitionsToReviewed() {
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.phase, .drilling)
        XCTAssertEqual(viewModel.cardPhase, .activeCountdown)

        viewModel.simulateElapsedTime(ms: 1800)
        viewModel.submitTypingAnswer(viewModel.currentWord!.lemma)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.typedText, "ephemeral")
            XCTAssertEqual(result.responseTimeMs, 1800)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        XCTAssertEqual(viewModel.comboStreak, 1)
        XCTAssertEqual(mockSound.playSuccessChimeCallCount, 1)
    }

    func testTypingModeCaseAndWhitespaceInsensitiveMatch() {
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()
        viewModel.submitTypingAnswer("   EPHEMERAL  \n")

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
    }

    func testTypingModeIncorrectSubmissionDoesNotTransitionActivePhase() {
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()
        viewModel.submitTypingAnswer("wrongword")

        XCTAssertEqual(viewModel.cardPhase, .activeCountdown, "Incorrect typing input should allow user to retry before timeout")
        XCTAssertEqual(viewModel.attempts.count, 0)
    }

    // MARK: - Listening Modality

    func testListeningModeAutoSpeaksAndGeneratesDefinitionOptions() {
        viewModel.selectMode(.listening)
        viewModel.beginSessionDirectly()

        XCTAssertEqual(mockTTS.lastSpokenText, "ephemeral", "Listening mode must auto-speak target lemma on load")
        XCTAssertEqual(viewModel.currentOptions.count, 4)

        guard let correctOption = viewModel.currentOptions.first(where: { $0.isCorrect }) else {
            XCTFail("No correct option found")
            return
        }
        XCTAssertEqual(correctOption.text, "Phù du, ngắn ngủi")

        viewModel.selectOption(correctOption)
        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertEqual(result.selectedOption, "Phù du, ngắn ngủi")
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
    }

    func testListeningModeTimeoutDoesNotSpeakAgain() {
        viewModel.selectMode(.listening)
        viewModel.beginSessionDirectly()
        // Initial speak count is 1 for listening mode opening
        XCTAssertEqual(mockTTS.speakCallCount, 1)

        viewModel.handleTimeout()
        // Speak count should STILL be 1 (not 2)
        XCTAssertEqual(mockTTS.speakCallCount, 1, "Listening mode timeout should not re-speak the lemma")
    }

    func testAttemptsHistoryTracksCorrectAndIncorrectOrder() {
        viewModel.selectMode(.multipleChoice)
        viewModel.beginSessionDirectly()

        // Word 0: Correct
        let correctOpt = viewModel.currentOptions.first(where: { $0.isCorrect })!
        viewModel.selectOption(correctOpt)
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertTrue(viewModel.attempts[0].isCorrect)

        // Word 1: Timeout
        viewModel.advanceToNextWord()
        viewModel.handleTimeout()
        XCTAssertEqual(viewModel.attempts.count, 2)
        XCTAssertFalse(viewModel.attempts[1].isCorrect)
    }

    // MARK: - Speaking Modality

    func testSpeakingModeSpokenMatchTransitionsToReviewedAndPausesListening() {
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()
        XCTAssertFalse(mockSpeech.isRecognitionMuted)

        viewModel.simulateElapsedTime(ms: 1500)
        mockSpeech.simulateTranscript("ephemeral")

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.recognizedSpoken, "ephemeral")
            XCTAssertEqual(result.responseTimeMs, 1500)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        XCTAssertTrue(mockSpeech.isRecognitionMuted, "Speech listening must pause during review state")
        XCTAssertEqual(mockSound.playSuccessChimeCallCount, 1)
        XCTAssertEqual(viewModel.comboStreak, 1)
    }

    func testSpokenMatchCaseInsensitivityAndWhitespaceTrimming() {
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()
        viewModel.handleSpokenMatch("  EPHEMERAL\n")

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
        XCTAssertEqual(viewModel.comboStreak, 1)
    }

    func testRepeatedMatchIgnoredWhenCurrentAttemptAlreadyCorrect() {
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()
        viewModel.handleSpokenMatch("ephemeral")
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.comboStreak, 1)

        // Second match on same attempt while reviewed
        viewModel.handleSpokenMatch("ephemeral")
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.comboStreak, 1)
    }

    // MARK: - Timeout & Review Pause Handling

    func testTimeoutTransitionsToReviewedAndSpeaksLemma() {
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()
        viewModel.comboStreak = 4
        viewModel.maxComboStreak = 4

        viewModel.handleTimeout()

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertFalse(result.isCorrect)
            XCTAssertTrue(result.isTimeout)
            XCTAssertEqual(result.responseTimeMs, 6000)
        } else {
            XCTFail("Expected cardPhase to be .reviewed on timeout")
        }

        XCTAssertEqual(viewModel.comboStreak, 0)
        XCTAssertEqual(viewModel.maxComboStreak, 4)
        XCTAssertTrue(mockSpeech.isRecognitionMuted, "Speech recognition must pause during review state")
        XCTAssertEqual(mockTTS.lastSpokenText, "ephemeral", "Target word must be spoken on timeout")
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.attempts.first?.isCorrect, false)
        XCTAssertEqual(viewModel.attempts.first?.responseTimeMs, 6000)
        XCTAssertEqual(mockSound.playIncorrectChimeCallCount, 1)
    }

    func testTimeoutTriggersIncorrectChime() {
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()
        viewModel.handleTimeout()
        XCTAssertEqual(mockSound.playIncorrectChimeCallCount, 1)
    }

    func testSimulateElapsedTimeAtModeLimitTriggersTimeout() {
        viewModel.selectMode(.multipleChoice) // 4.5s limit
        viewModel.beginSessionDirectly()

        viewModel.simulateElapsedTime(ms: 4500)
        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isTimeout)
            XCTAssertEqual(result.responseTimeMs, 4500)
        } else {
            XCTFail("Expected timeout at 4500ms in multiple choice mode")
        }
    }

    // MARK: - Navigation & Advance

    func testAdvanceToNextWordLoadsNextWordAndResetsCardPhase() {
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.currentWordIndex, 0)

        viewModel.submitTypingAnswer(viewModel.currentWord!.lemma)
        XCTAssertEqual(viewModel.currentWordIndex, 0, "Should remain on current word in review state until advanceToNextWord is called")

        viewModel.advanceToNextWord()
        XCTAssertEqual(viewModel.currentWordIndex, 1)
        XCTAssertEqual(viewModel.cardPhase, .activeCountdown)
        XCTAssertEqual(viewModel.currentWord?.lemma, "vital")
        XCTAssertEqual(viewModel.elapsedTimeMs, 0)
    }

    func testAdvanceToNextWordOnLastWordFinishesSession() {
        viewModel.selectMode(.multipleChoice)
        viewModel.beginSessionDirectly()

        viewModel.loadWordForTesting(at: 2)
        guard let correct = viewModel.currentOptions.first(where: { $0.isCorrect }) else {
            XCTFail("No correct option found")
            return
        }
        viewModel.selectOption(correct)

        viewModel.advanceToNextWord()
        XCTAssertEqual(viewModel.phase, .summary)
        XCTAssertFalse(mockSpeech.isSessionActive)
        XCTAssertNotNil(viewModel.sessionSummary)
        XCTAssertEqual(viewModel.sessionSummary?.totalWords, 1)
        XCTAssertEqual(viewModel.sessionSummary?.correctWords, 1)
    }

    func testConsecutiveMatchesAcrossWordsBuildComboStreak() {
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()

        // Word 1
        viewModel.submitTypingAnswer("ephemeral")
        XCTAssertEqual(viewModel.comboStreak, 1)
        viewModel.advanceToNextWord()

        // Word 2
        viewModel.submitTypingAnswer("vital")
        XCTAssertEqual(viewModel.comboStreak, 2)
        XCTAssertEqual(viewModel.maxComboStreak, 2)
        viewModel.advanceToNextWord()

        // Word 3 times out
        viewModel.handleTimeout()
        XCTAssertEqual(viewModel.comboStreak, 0)
        XCTAssertEqual(viewModel.maxComboStreak, 2)
    }

    func testReDrillWeakWordsPreservesSelectedMode() {
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()

        // Word 1: Correct
        viewModel.submitTypingAnswer("ephemeral")
        viewModel.advanceToNextWord()

        // Word 2: Timeout (weak)
        viewModel.handleTimeout()
        viewModel.advanceToNextWord()

        // Word 3: Correct
        viewModel.submitTypingAnswer("serendipity")
        viewModel.advanceToNextWord()

        XCTAssertEqual(viewModel.phase, .summary)
        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.count, 1)
        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.first?.wordId, 2)

        viewModel.reDrillWeakWords()

        XCTAssertEqual(viewModel.words.count, 1)
        XCTAssertEqual(viewModel.words.first?.id, 2)
        XCTAssertEqual(viewModel.words.first?.lemma, "vital")
        XCTAssertEqual(viewModel.selectedMode, .typing)
        XCTAssertEqual(viewModel.phase, .countdown)
    }

    // MARK: - Dynamic Timers, Hints & Progress

    func testFractionRemainingAcrossDifferentModes() {
        // 1. Speaking (6.0s)
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()
        viewModel.simulateElapsedTime(ms: 0)
        XCTAssertEqual(viewModel.fractionRemaining, 1.0, accuracy: 0.001)
        viewModel.simulateElapsedTime(ms: 3000)
        XCTAssertEqual(viewModel.fractionRemaining, 0.5, accuracy: 0.001)
        viewModel.simulateElapsedTime(ms: 6000)
        XCTAssertEqual(viewModel.fractionRemaining, 0.0, accuracy: 0.001)

        // 2. Multiple Choice (4.5s)
        viewModel.selectMode(.multipleChoice)
        viewModel.beginSessionDirectly()
        viewModel.simulateElapsedTime(ms: 0)
        XCTAssertEqual(viewModel.fractionRemaining, 1.0, accuracy: 0.001)
        viewModel.simulateElapsedTime(ms: 2250)
        XCTAssertEqual(viewModel.fractionRemaining, 0.5, accuracy: 0.001)

        // 3. Typing (7.5s)
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()
        viewModel.simulateElapsedTime(ms: 0)
        XCTAssertEqual(viewModel.fractionRemaining, 1.0, accuracy: 0.001)
        viewModel.simulateElapsedTime(ms: 3750)
        XCTAssertEqual(viewModel.fractionRemaining, 0.5, accuracy: 0.001)
    }

    func testHintTimingForSpeakingAndTyping() {
        // Speaking: Hint at 3.5s
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()
        XCTAssertFalse(viewModel.showHint)
        viewModel.simulateElapsedTime(ms: 3499)
        XCTAssertFalse(viewModel.showHint)
        viewModel.simulateElapsedTime(ms: 3500)
        XCTAssertTrue(viewModel.showHint)

        // Typing: Hint at 4.5s
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()
        XCTAssertFalse(viewModel.showHint)
        viewModel.simulateElapsedTime(ms: 4499)
        XCTAssertFalse(viewModel.showHint)
        viewModel.simulateElapsedTime(ms: 4500)
        XCTAssertTrue(viewModel.showHint)
    }

    func testTimerStagesAcrossIntervals() {
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()

        viewModel.simulateElapsedTime(ms: 0)
        XCTAssertEqual(viewModel.timerStage, .steady)

        viewModel.simulateElapsedTime(ms: 3499)
        XCTAssertEqual(viewModel.timerStage, .steady)

        viewModel.simulateElapsedTime(ms: 3500)
        XCTAssertEqual(viewModel.timerStage, .warning)

        viewModel.simulateElapsedTime(ms: 4999)
        XCTAssertEqual(viewModel.timerStage, .warning)

        viewModel.simulateElapsedTime(ms: 5000)
        XCTAssertEqual(viewModel.timerStage, .urgent)

        viewModel.simulateElapsedTime(ms: 6000)
        XCTAssertEqual(viewModel.timerStage, .urgent)
    }

    func testProgressFraction() {
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.progressFraction, 0.0)

        viewModel.loadWordForTesting(at: 1)
        XCTAssertEqual(viewModel.progressFraction, 1.0 / 3.0, accuracy: 0.001)

        viewModel.loadWordForTesting(at: 2)
        XCTAssertEqual(viewModel.progressFraction, 2.0 / 3.0, accuracy: 0.001)
    }

    // MARK: - Audio & Helpers

    func testSpeakLemmaInvokesTTSService() {
        mockTTS.lastSpokenText = nil
        mockTTS.isSpeaking = false

        viewModel.speakLemma("serendipity")
        XCTAssertTrue(mockTTS.isSpeaking)
        XCTAssertEqual(mockTTS.lastSpokenText, "serendipity")
    }

    func testSpeakCurrentWordSpeaksActiveLemma() {
        viewModel.beginSessionDirectly()
        mockTTS.lastSpokenText = nil

        viewModel.speakCurrentWord()
        XCTAssertEqual(mockTTS.lastSpokenText, "ephemeral")

        viewModel.loadWordForTesting(at: 1)
        viewModel.speakCurrentWord()
        XCTAssertEqual(mockTTS.lastSpokenText, "vital")
    }

    func testCancelSessionStopsServices() {
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()
        XCTAssertTrue(mockSpeech.isSessionActive)

        viewModel.cancelSession()
        XCTAssertFalse(mockSpeech.isSessionActive)
        XCTAssertFalse(mockTTS.isSpeaking)
    }

    func testLiveTranscriptUpdatesPropagatedAndResetOnNextWord() {
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()
        mockSpeech.simulateTranscript("Speaking some words...")
        XCTAssertEqual(viewModel.liveTranscript, "Speaking some words...")

        viewModel.advanceToNextWord()
        XCTAssertEqual(viewModel.liveTranscript, "", "liveTranscript should reset to empty upon loading next word")
    }

    func testAttemptsAndSummaryContainRichWordMetadata() {
        let richWords = [
            ReflexBlitzWordItem(
                id: 101,
                lemma: "meticulous",
                pos: "adj.",
                ipa: "/məˈtɪk.jə.ləs/",
                definitionVi: "Tỉ mỉ, cẩn thận",
                exampleSentenceEn: "She is meticulous about detail.",
                exampleSentenceVi: "Cô ấy tỉ mỉ về từng chi tiết."
            ),
            ReflexBlitzWordItem(
                id: 102,
                lemma: "resilient",
                pos: "adj.",
                ipa: "/rɪˈzɪl.jənt/",
                definitionVi: "Kiên cường",
                exampleSentenceEn: "They are resilient.",
                exampleSentenceVi: "Họ rất kiên cường."
            )
        ]

        let richVM = ReflexBlitzViewModel(
            words: richWords,
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )

        richVM.selectMode(.typing)
        richVM.beginSessionDirectly()

        // 1. Spoken/typed match on word 0
        richVM.submitTypingAnswer("meticulous")
        XCTAssertEqual(richVM.attempts.count, 1)
        let firstAttempt = richVM.attempts[0]
        XCTAssertEqual(firstAttempt.wordId, 101)
        XCTAssertEqual(firstAttempt.lemma, "meticulous")
        XCTAssertEqual(firstAttempt.pos, "adj.")
        XCTAssertEqual(firstAttempt.ipa, "/məˈtɪk.jə.ləs/")
        XCTAssertEqual(firstAttempt.definitionVi, "Tỉ mỉ, cẩn thận")

        // 2. Timeout on word 1 (Weak word)
        richVM.advanceToNextWord()
        richVM.handleTimeout()
        XCTAssertEqual(richVM.attempts.count, 2)
        let secondAttempt = richVM.attempts[1]
        XCTAssertEqual(secondAttempt.wordId, 102)
        XCTAssertEqual(secondAttempt.lemma, "resilient")
        XCTAssertEqual(secondAttempt.pos, "adj.")
        XCTAssertEqual(secondAttempt.ipa, "/rɪˈzɪl.jənt/")
        XCTAssertEqual(secondAttempt.definitionVi, "Kiên cường")

        // 3. Summary weak words contain metadata
        richVM.advanceToNextWord()
        guard let summary = richVM.sessionSummary else {
            XCTFail("Expected session summary to exist")
            return
        }

        XCTAssertEqual(summary.weakWordAttempts.count, 1)
        let weakAttempt = summary.weakWordAttempts[0]
        XCTAssertEqual(weakAttempt.wordId, 102)
        XCTAssertEqual(weakAttempt.lemma, "resilient")
        XCTAssertEqual(weakAttempt.pos, "adj.")
        XCTAssertEqual(weakAttempt.ipa, "/rɪˈzɪl.jənt/")
        XCTAssertEqual(weakAttempt.definitionVi, "Kiên cường")
    }
}

// MARK: - Swift Testing 4 Modalities Feedback Suite

@Suite("Reflex Blitz 4 Modalities Feedback Tests")
struct ReflexBlitzViewModelFeedbackTests {
    @Test("Speaking and Typing allow Skip; MC and Listening trigger instant feedback on choice")
    @MainActor
    func testModalityInteractions() {
        let viewModel = ReflexBlitzViewModel()
        let sampleWord = ReflexBlitzWordItem(id: 1, lemma: "capital", ipa: "/kæp/", definitionVi: "thủ đô", clozeSentenceEn: "Tokyo is a [capital].", clozeSentenceVi: "Tokyo là thủ đô.")
        viewModel.startDrillSession(mode: .speaking, words: [sampleWord])

        // Initially feedback is not presented
        #expect(viewModel.isFeedbackPresented == false)

        // Skip in Speaking should transition to reviewed with feedback
        viewModel.handleTimeout()
        #expect(viewModel.isFeedbackPresented == true)

        // Multiple Choice selection
        viewModel.startDrillSession(mode: .multipleChoice, words: [sampleWord])
        #expect(viewModel.isFeedbackPresented == false)
        let opt = ReflexBlitzOption(id: "1", text: "capital", isCorrect: true)
        viewModel.selectOption(opt)
        #expect(viewModel.isFeedbackPresented == true)
        #expect(viewModel.currentAttemptIsCorrect == true)
    }

    @Test("Typing submission triggers feedback presentation and case-insensitive check")
    @MainActor
    func testTypingFeedbackInteractions() {
        let viewModel = ReflexBlitzViewModel()
        let sampleWord = ReflexBlitzWordItem(id: 2, lemma: "eloquent", ipa: "/ˈel.ə.kwənt/", definitionVi: "Hùng biện", clozeSentenceEn: "He is [eloquent].", clozeSentenceVi: "Anh ấy rất hùng biện.")
        viewModel.startDrillSession(mode: .typing, words: [sampleWord])

        #expect(viewModel.isFeedbackPresented == false)

        // Incorrect typing should NOT trigger feedback immediately (lets user retry before timeout)
        viewModel.submitTypingAnswer("wrong")
        #expect(viewModel.isFeedbackPresented == false)

        // Correct typing triggers feedback
        viewModel.submitTypingAnswer("  ELOQUENT \n")
        #expect(viewModel.isFeedbackPresented == true)
        #expect(viewModel.currentAttemptIsCorrect == true)
    }

    @Test("Listening mode auto-speaks lemma and option selection triggers feedback")
    @MainActor
    func testListeningFeedbackInteractions() {
        let mockSpeech = MockContinuousReflexSpeechService()
        let mockTTS = MockTextToSpeechService()
        let mockSRS = MockEvaluateSRSUseCase()
        let sampleWord = ReflexBlitzWordItem(id: 3, lemma: "resilient", ipa: "/rɪˈzɪl.jənt/", definitionVi: "Kiên cường", clozeSentenceEn: "They are [resilient].", clozeSentenceVi: "Họ kiên cường.")

        let viewModel = ReflexBlitzViewModel(
            words: [sampleWord],
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )
        viewModel.startDrillSession(mode: .listening, words: [sampleWord])

        #expect(mockTTS.lastSpokenText == "resilient")
        #expect(viewModel.isFeedbackPresented == false)

        let correctOpt = viewModel.currentOptions.first(where: { $0.isCorrect })!
        viewModel.selectOption(correctOpt)
        #expect(viewModel.isFeedbackPresented == true)
        #expect(viewModel.currentAttemptIsCorrect == true)
    }

    @Test("Advancing to next word resets isFeedbackPresented to false")
    @MainActor
    func testAdvanceResetsFeedbackState() {
        let viewModel = ReflexBlitzViewModel()
        let word1 = ReflexBlitzWordItem(id: 1, lemma: "first", definitionVi: "thứ nhất")
        let word2 = ReflexBlitzWordItem(id: 2, lemma: "second", definitionVi: "thứ hai")
        viewModel.startDrillSession(mode: .typing, words: [word1, word2])

        viewModel.submitTypingAnswer("first")
        #expect(viewModel.isFeedbackPresented == true)

        viewModel.advanceToNextWord()
        #expect(viewModel.isFeedbackPresented == false)
        #expect(viewModel.currentWordIndex == 1)
        #expect(viewModel.currentWord?.lemma == "second")
    }
}
