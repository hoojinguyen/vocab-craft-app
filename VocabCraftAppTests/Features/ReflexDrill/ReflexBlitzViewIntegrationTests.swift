import SwiftUI
import XCTest
@testable import VocabCraftApp

@MainActor
final class ReflexBlitzViewIntegrationTests: XCTestCase {
    private func makeSampleWords() -> [ReflexBlitzWordItem] {
        [
            ReflexBlitzWordItem(
                id: 1,
                lemma: "ephemeral",
                pos: "adj.",
                definitionVi: "Phù du, chóng tàn",
                exampleSentenceEn: "Her fame is ephemeral in nature.",
                exampleSentenceVi: "Danh tiếng của cô ấy phù du."
            ),
            ReflexBlitzWordItem(
                id: 2,
                lemma: "serendipity",
                pos: "n.",
                definitionVi: "Sự may mắn bất ngờ",
                exampleSentenceEn: "Finding this was pure serendipity.",
                exampleSentenceVi: "Tìm thấy thứ này là may mắn bất ngờ."
            )
        ]
    }

    private func makeViewModel(words: [ReflexBlitzWordItem]? = nil) -> (ReflexBlitzViewModel, MockContinuousReflexSpeechService, MockTextToSpeechService, MockEvaluateSRSUseCase) {
        let mockSpeech = MockContinuousReflexSpeechService()
        let mockTTS = MockTextToSpeechService()
        let mockSRS = MockEvaluateSRSUseCase()
        let items = words ?? makeSampleWords()
        let vm = ReflexBlitzViewModel(
            words: items,
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )
        return (vm, mockSpeech, mockTTS, mockSRS)
    }

    func testBlitzViewInstantiation() {
        let (vm, _, _, _) = makeViewModel()
        var didDismiss = false
        let view = ReflexBlitzView(viewModel: vm, onDismiss: { didDismiss = true })
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.body)

        view.onDismiss()
        XCTAssertTrue(didDismiss)
    }

    func testBlitzViewCountdownPhaseRendering() {
        let (vm, _, _, _) = makeViewModel()
        vm.phase = .countdown
        vm.countdownCount = 3

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertEqual(vm.phase, .countdown)
        XCTAssertEqual(vm.countdownCount, 3)
    }

    func testBlitzViewDrillingPhaseRendering() {
        let (vm, _, _, _) = makeViewModel()
        vm.beginSessionDirectly()
        XCTAssertEqual(vm.phase, .drilling)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertNotNil(vm.currentWord)
        XCTAssertEqual(vm.currentWord?.lemma, "ephemeral")
    }

    func testBlitzViewTimeoutRevealingPhaseRendering() {
        let (vm, _, mockTTS, _) = makeViewModel()
        vm.beginSessionDirectly()
        vm.handleTimeout()

        XCTAssertEqual(vm.phase, .timeoutRevealing)
        XCTAssertTrue(mockTTS.isSpeaking)
        XCTAssertEqual(mockTTS.lastSpokenText, "ephemeral")

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
    }

    func testBlitzViewSummaryPhaseRenderingAndReDrill() {
        let (vm, _, _, _) = makeViewModel()
        vm.beginSessionDirectly()
        vm.handleTimeout()
        vm.finishSession()

        XCTAssertEqual(vm.phase, .summary)
        XCTAssertNotNil(vm.sessionSummary)
        XCTAssertEqual(vm.sessionSummary?.totalWords, 1)
        XCTAssertEqual(vm.sessionSummary?.weakWordAttempts.count, 1)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
    }

    func testKeyboardFallbackInputToggleAndSubmit() {
        let (vm, _, _, _) = makeViewModel()
        vm.beginSessionDirectly()
        XCTAssertFalse(vm.isKeyboardFallbackActive)

        vm.toggleKeyboardFallback()
        XCTAssertTrue(vm.isKeyboardFallbackActive)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)

        // Submit via keyboard
        vm.submitKeyboardInput("ephemeral")
        XCTAssertTrue(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 1)
    }

    func testCancellationTeardownOnDisappear() {
        let (vm, mockSpeech, mockTTS, _) = makeViewModel()
        vm.beginSessionDirectly()
        XCTAssertTrue(mockSpeech.isSessionActive)

        vm.cancelSession()
        XCTAssertFalse(mockSpeech.isSessionActive)
        XCTAssertFalse(mockTTS.isSpeaking)
    }

    func testAppContainerMakeReflexBlitzViewModel() {
        let container = AppContainer.mock
        let defaultVM = container.makeReflexBlitzViewModel()
        XCTAssertEqual(defaultVM.words.count, ReflexBlitzWordItem.defaultStarterWords.count)

        let customWords = [
            ReflexBlitzWordItem(
                id: 99,
                lemma: "luminous",
                pos: "adj.",
                definitionVi: "Tỏa sáng",
                exampleSentenceEn: "The stars are luminous.",
                exampleSentenceVi: "Những ngôi sao tỏa sáng."
            )
        ]
        let customVM = container.makeReflexBlitzViewModel(words: customWords)
        XCTAssertEqual(customVM.words.count, 1)
        XCTAssertEqual(customVM.words.first?.lemma, "luminous")
    }

    func testFullSessionEndToEndFlow() async {
        let words = makeSampleWords()
        let (vm, mockSpeech, _, mockSRS) = makeViewModel(words: words)
        var dismissed = false

        let view = ReflexBlitzView(viewModel: vm, onDismiss: { dismissed = true })
        XCTAssertNotNil(view.body)

        // 1. Begin Session
        vm.beginSessionDirectly()
        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.currentWordIndex, 0)
        XCTAssertEqual(mockSpeech.currentTargetLemma, "ephemeral")

        // 2. Correct Spoken Match on Word 1
        mockSpeech.simulateTranscript("The fame is ephemeral today")
        XCTAssertTrue(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 1)
        XCTAssertEqual(vm.attempts.count, 1)
        XCTAssertEqual(vm.attempts.first?.wordId, 1)
        XCTAssertEqual(vm.attempts.first?.isCorrect, true)

        // 3. Load Word 2 and Trigger Timeout
        vm.loadWordForTesting(at: 1)
        XCTAssertEqual(vm.currentWordIndex, 1)
        XCTAssertEqual(mockSpeech.currentTargetLemma, "serendipity")

        vm.handleTimeout()
        XCTAssertEqual(vm.phase, .timeoutRevealing)
        XCTAssertEqual(vm.comboStreak, 0)
        XCTAssertEqual(vm.attempts.count, 2)
        XCTAssertEqual(vm.attempts.last?.wordId, 2)
        XCTAssertEqual(vm.attempts.last?.isCorrect, false)

        // 4. Finish Session -> Summary Phase
        vm.finishSession()
        XCTAssertEqual(vm.phase, .summary)
        XCTAssertNotNil(vm.sessionSummary)
        XCTAssertEqual(vm.sessionSummary?.totalWords, 2)
        XCTAssertEqual(vm.sessionSummary?.correctWords, 1)
        XCTAssertEqual(vm.sessionSummary?.weakWordAttempts.count, 1)
        XCTAssertEqual(vm.sessionSummary?.weakWordAttempts.first?.lemma, "serendipity")

        // 5. Re-drill weak words restarts session with only weak items
        vm.reDrillWeakWords()
        XCTAssertEqual(vm.phase, .countdown)
        XCTAssertEqual(vm.words.count, 1)
        XCTAssertEqual(vm.words.first?.lemma, "serendipity")

        // 6. Dismiss View
        view.onDismiss()
        XCTAssertTrue(dismissed)
    }
}
