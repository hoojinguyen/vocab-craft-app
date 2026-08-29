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

        guard let correctOption = viewModel.currentOptions.first(where: { $0.isCorrect }),
              let targetLemma = viewModel.currentWord?.lemma else {
            XCTFail("No correct option or target lemma found")
            return
        }
        XCTAssertEqual(correctOption.text, targetLemma)

        viewModel.simulateElapsedTime(ms: 1200)
        viewModel.selectOption(correctOption)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.selectedOption, targetLemma)
            XCTAssertEqual(result.responseTimeMs, 1200)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        XCTAssertEqual(viewModel.comboStreak, 1)
        XCTAssertEqual(viewModel.maxComboStreak, 1)
        XCTAssertEqual(mockSound.playSuccessChimeCallCount, 1)
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.attempts.first?.lemma, targetLemma)
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

        let targetLemma = viewModel.currentWord!.lemma
        viewModel.simulateElapsedTime(ms: 1800)
        viewModel.submitTypingAnswer(targetLemma)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.typedText, targetLemma)
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
        let targetLemma = viewModel.currentWord!.lemma
        viewModel.submitTypingAnswer("   \(targetLemma.uppercased())  \n")

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
    }

    func testTypingModeEmptySubmissionDoesNotTransitionActivePhase() {
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()
        viewModel.submitTypingAnswer("   \n")

        XCTAssertEqual(viewModel.cardPhase, .activeCountdown, "Empty typing input should be ignored")
        XCTAssertEqual(viewModel.attempts.count, 0)
    }

    func testTypingModeIncorrectSubmissionTransitionsToReviewed() {
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()
        viewModel.submitTypingAnswer("wrongword")

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertFalse(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.typedText, "wrongword")
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
        XCTAssertEqual(viewModel.comboStreak, 0)
        XCTAssertEqual(mockSound.playIncorrectChimeCallCount, 1)
        XCTAssertEqual(mockTTS.lastSpokenText, viewModel.currentWord?.lemma)
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertFalse(viewModel.attempts[0].isCorrect)
    }

    // MARK: - Listening Modality

    func testListeningModeAutoSpeaksAndGeneratesDefinitionOptions() {
        viewModel.selectMode(.listening)
        viewModel.beginSessionDirectly()

        guard let targetWord = viewModel.currentWord else {
            XCTFail("No target word found")
            return
        }

        XCTAssertEqual(mockTTS.lastSpokenText, targetWord.lemma, "Listening mode must auto-speak target lemma on load")
        XCTAssertEqual(viewModel.currentOptions.count, 4)

        guard let correctOption = viewModel.currentOptions.first(where: { $0.isCorrect }) else {
            XCTFail("No correct option found")
            return
        }
        XCTAssertEqual(correctOption.text, targetWord.definitionVi)

        viewModel.selectOption(correctOption)
        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertEqual(result.selectedOption, targetWord.definitionVi)
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

        guard let targetLemma = viewModel.currentWord?.lemma else {
            XCTFail("No target lemma found")
            return
        }

        viewModel.simulateElapsedTime(ms: 1500)
        mockSpeech.simulateTranscript(targetLemma)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.recognizedSpoken, targetLemma)
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
        guard let targetLemma = viewModel.currentWord?.lemma else {
            XCTFail("No target lemma found")
            return
        }
        viewModel.handleSpokenMatch("  \(targetLemma.uppercased())\n")

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
        guard let targetLemma = viewModel.currentWord?.lemma else {
            XCTFail("No target lemma found")
            return
        }
        viewModel.handleSpokenMatch(targetLemma)
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.comboStreak, 1)

        // Second match on same attempt while reviewed
        viewModel.handleSpokenMatch(targetLemma)
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.comboStreak, 1)
    }

    // MARK: - Timeout & Review Pause Handling

    func testTimeoutTransitionsToReviewedAndSpeaksLemma() {
        viewModel.selectMode(.speaking)
        viewModel.beginSessionDirectly()
        viewModel.comboStreak = 4
        viewModel.maxComboStreak = 4

        guard let targetLemma = viewModel.currentWord?.lemma else {
            XCTFail("No target lemma found")
            return
        }

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
        XCTAssertEqual(mockTTS.lastSpokenText, targetLemma, "Target word must be spoken on timeout")
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

        guard let targetLemma = viewModel.currentWord?.lemma else {
            XCTFail("No current word found")
            return
        }

        viewModel.submitTypingAnswer(targetLemma)
        XCTAssertEqual(viewModel.currentWordIndex, 0, "Should remain on current word in review state until advanceToNextWord is called")

        viewModel.advanceToNextWord()
        XCTAssertEqual(viewModel.currentWordIndex, 1)
        XCTAssertEqual(viewModel.cardPhase, .activeCountdown)
        XCTAssertNotNil(viewModel.currentWord)
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
        guard let word1Lemma = viewModel.currentWord?.lemma else { XCTFail("No word 1"); return }
        viewModel.submitTypingAnswer(word1Lemma)
        XCTAssertEqual(viewModel.comboStreak, 1)
        viewModel.advanceToNextWord()

        // Word 2
        guard let word2Lemma = viewModel.currentWord?.lemma else { XCTFail("No word 2"); return }
        viewModel.submitTypingAnswer(word2Lemma)
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
        guard let word1Lemma = viewModel.currentWord?.lemma else { XCTFail("No word 1"); return }
        viewModel.submitTypingAnswer(word1Lemma)
        viewModel.advanceToNextWord()

        // Word 2: Timeout (weak)
        guard let weakWord = viewModel.currentWord else { XCTFail("No word 2"); return }
        viewModel.handleTimeout()
        viewModel.advanceToNextWord()

        // Word 3: Correct
        guard let word3Lemma = viewModel.currentWord?.lemma else { XCTFail("No word 3"); return }
        viewModel.submitTypingAnswer(word3Lemma)
        viewModel.advanceToNextWord()

        XCTAssertEqual(viewModel.phase, .summary)
        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.count, 1)
        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.first?.wordId, weakWord.id)

        viewModel.reDrillWeakWords()

        XCTAssertEqual(viewModel.words.count, 1)
        XCTAssertEqual(viewModel.words.first?.id, weakWord.id)
        XCTAssertEqual(viewModel.words.first?.lemma, weakWord.lemma)
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

    func testProgressiveHintTimingForMultipleChoice() {
        viewModel.selectMode(.multipleChoice)
        viewModel.beginSessionDirectly()

        // Stage 0: Initial state
        XCTAssertEqual(viewModel.hintStage, 0)
        XCTAssertFalse(viewModel.showHint)

        // Before Stage 1 (1.6s)
        viewModel.simulateElapsedTime(ms: 1599)
        XCTAssertEqual(viewModel.hintStage, 0)
        XCTAssertFalse(viewModel.showHint)

        // Stage 1 (>= 1.6s): POS badge
        viewModel.simulateElapsedTime(ms: 1600)
        XCTAssertEqual(viewModel.hintStage, 1)
        XCTAssertTrue(viewModel.showHint)

        // Before Stage 2 (2.5s)
        viewModel.simulateElapsedTime(ms: 2499)
        XCTAssertEqual(viewModel.hintStage, 1)

        // Stage 2 (>= 2.5s): Cloze letter reveal
        viewModel.simulateElapsedTime(ms: 2500)
        XCTAssertEqual(viewModel.hintStage, 2)
        XCTAssertTrue(viewModel.showHint)

        // Before Stage 3 (3.4s)
        viewModel.simulateElapsedTime(ms: 3399)
        XCTAssertEqual(viewModel.hintStage, 2)

        // Stage 3 (>= 3.4s): Eliminate option
        viewModel.simulateElapsedTime(ms: 3400)
        XCTAssertEqual(viewModel.hintStage, 3)
        XCTAssertTrue(viewModel.showHint)
    }

    func testLoadWordResetsHintStage() {
        viewModel.selectMode(.multipleChoice)
        viewModel.beginSessionDirectly()
        viewModel.simulateElapsedTime(ms: 3400)
        XCTAssertEqual(viewModel.hintStage, 3)

        viewModel.loadWordForTesting(at: 1)
        XCTAssertEqual(viewModel.hintStage, 0)
        XCTAssertFalse(viewModel.showHint)
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

        let word0Lemma = viewModel.currentWord?.lemma
        viewModel.speakCurrentWord()
        XCTAssertEqual(mockTTS.lastSpokenText, word0Lemma)

        viewModel.loadWordForTesting(at: 1)
        let word1Lemma = viewModel.currentWord?.lemma
        viewModel.speakCurrentWord()
        XCTAssertEqual(mockTTS.lastSpokenText, word1Lemma)
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
        let firstWord = richVM.currentWord!
        richVM.submitTypingAnswer(firstWord.lemma)
        XCTAssertEqual(richVM.attempts.count, 1)
        let firstAttempt = richVM.attempts[0]
        XCTAssertEqual(firstAttempt.wordId, firstWord.id)
        XCTAssertEqual(firstAttempt.lemma, firstWord.lemma)
        XCTAssertEqual(firstAttempt.pos, firstWord.pos)
        XCTAssertEqual(firstAttempt.ipa, firstWord.ipa)
        XCTAssertEqual(firstAttempt.definitionVi, firstWord.definitionVi)

        // 2. Timeout on word 1 (Weak word)
        richVM.advanceToNextWord()
        let secondWord = richVM.currentWord!
        richVM.handleTimeout()
        XCTAssertEqual(richVM.attempts.count, 2)
        let secondAttempt = richVM.attempts[1]
        XCTAssertEqual(secondAttempt.wordId, secondWord.id)
        XCTAssertEqual(secondAttempt.lemma, secondWord.lemma)
        XCTAssertEqual(secondAttempt.pos, secondWord.pos)
        XCTAssertEqual(secondAttempt.ipa, secondWord.ipa)
        XCTAssertEqual(secondAttempt.definitionVi, secondWord.definitionVi)

        // 3. Summary weak words contain metadata
        richVM.advanceToNextWord()
        guard let summary = richVM.sessionSummary else {
            XCTFail("Expected session summary to exist")
            return
        }

        XCTAssertEqual(summary.weakWordAttempts.count, 1)
        let weakAttempt = summary.weakWordAttempts[0]
        XCTAssertEqual(weakAttempt.wordId, secondWord.id)
        XCTAssertEqual(weakAttempt.lemma, secondWord.lemma)
        XCTAssertEqual(weakAttempt.pos, secondWord.pos)
        XCTAssertEqual(weakAttempt.ipa, secondWord.ipa)
        XCTAssertEqual(weakAttempt.definitionVi, secondWord.definitionVi)
    }

    // MARK: - Zero-Shift Layout & Animated CardPhase Transitions

    func testSelectOptionTransitionsCardPhaseToReviewed() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)

        guard let correctOption = viewModel.currentOptions.first(where: { $0.isCorrect }) else {
            XCTFail("No correct option found")
            return
        }

        viewModel.selectOption(correctOption)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertEqual(result.selectedOption, correctOption.text)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
    }

    func testSubmitTypingAnswerTransitionsCardPhaseToReviewed() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .typing)
        guard let currentLemma = viewModel.currentWord?.lemma else {
            XCTFail("No current word")
            return
        }

        viewModel.submitTypingAnswer(currentLemma)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertEqual(result.typedText, currentLemma)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
    }

    func testHandleSpokenMatchTransitionsCardPhaseToReviewed() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .speaking)
        guard let currentLemma = viewModel.currentWord?.lemma else {
            XCTFail("No current word")
            return
        }

        viewModel.handleSpokenMatch(currentLemma)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertEqual(result.recognizedSpoken, currentLemma)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
    }

    func testHandleTimeoutTransitionsCardPhaseToReviewed() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)

        viewModel.handleTimeout()

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertFalse(result.isCorrect)
            XCTAssertTrue(result.isTimeout)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
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

    @Test("Typing submission handles empty, correct, and incorrect inputs")
    @MainActor
    func testTypingSubmission() async {
        let sampleWord = ReflexBlitzWordItem(
            id: 1, lemma: "apple", pos: "n.", ipa: "/ˈæpl/",
            definitionVi: "quả táo", exampleSentenceEn: "I eat an apple.",
            exampleSentenceVi: "Tôi ăn một quả táo.", level: "A1"
        )
        let viewModel = ReflexBlitzViewModel(words: [sampleWord])
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()

        // Empty string should be ignored
        viewModel.submitTypingAnswer("   ")
        #expect(viewModel.cardPhase == .activeCountdown)

        // Incorrect string should transition to reviewed with isCorrect = false
        viewModel.submitTypingAnswer("aple")
        if case .reviewed(let result) = viewModel.cardPhase {
            #expect(result.isCorrect == false)
            #expect(result.typedText == "aple")
        } else {
            Issue.record("Expected reviewed phase on incorrect typing")
        }
    }

    @Test("Typing submission triggers feedback presentation and case-insensitive check")
    @MainActor
    func testTypingFeedbackInteractions() {
        let viewModel = ReflexBlitzViewModel()
        let sampleWord = ReflexBlitzWordItem(id: 2, lemma: "eloquent", ipa: "/ˈel.ə.kwənt/", definitionVi: "Hùng biện", clozeSentenceEn: "He is [eloquent].", clozeSentenceVi: "Anh ấy rất hùng biện.")
        viewModel.startDrillSession(mode: .typing, words: [sampleWord])

        #expect(viewModel.isFeedbackPresented == false)

        // Empty typing should NOT trigger feedback
        viewModel.submitTypingAnswer("   ")
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

        guard let firstWord = viewModel.currentWord else {
            Issue.record("No first word")
            return
        }

        viewModel.submitTypingAnswer(firstWord.lemma)
        #expect(viewModel.isFeedbackPresented == true)

        viewModel.advanceToNextWord()
        #expect(viewModel.isFeedbackPresented == false)
        #expect(viewModel.currentWordIndex == 1)
        #expect(viewModel.currentWord != nil)
    }
}

// MARK: - Pre-generation & Hint Scaffolding Tests

@Suite("Reflex Blitz ViewModel Pre-generation Tests")
struct ReflexBlitzViewModelPreGenerationTests {
    @Test("startDrillSession initializes sessionPlan and loads first plan item without runtime delay")
    @MainActor
    func testSessionPlanInitialization() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)
        #expect(viewModel.sessionPlan != nil)
        #expect(viewModel.sessionPlan?.items.count == ReflexBlitzWordItem.defaultStarterWords.count)
        #expect(viewModel.currentPlanItem != nil)
        #expect(viewModel.currentOptions.count == 4)
    }

    @Test("Hint stages progress from 0 -> 1 -> 2 -> 3 with simulated elapsed time")
    @MainActor
    func testProgressiveHintStages() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)

        viewModel.simulateElapsedTime(ms: 0)
        #expect(viewModel.hintStage == 0)

        viewModel.simulateElapsedTime(ms: 1700)
        #expect(viewModel.hintStage == 1)

        viewModel.simulateElapsedTime(ms: 2600)
        #expect(viewModel.hintStage == 2)

        viewModel.simulateElapsedTime(ms: 3500)
        #expect(viewModel.hintStage == 3)
    }

    @Test("loadWord binds planItem options, clozeStages, eliminatedOptionId, and hintBadgeText")
    @MainActor
    func testLoadWordBindsPlanItemProperties() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)

        #expect(viewModel.currentPlanItem != nil)
        #expect(viewModel.currentClozeStages != nil)
        #expect(viewModel.currentEliminatedOptionId != nil)
        #expect(!viewModel.currentHintBadgeText.isEmpty)
        #expect(viewModel.currentOptions == viewModel.currentPlanItem?.options)
    }
}
