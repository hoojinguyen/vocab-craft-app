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

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertNotNil(view.drillingView)

        vm.toggleKeyboardFallback()
        XCTAssertTrue(vm.isKeyboardFallbackActive)

        // Submit via keyboard
        vm.submitKeyboardInput("ephemeral")
        XCTAssertTrue(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 1)
    }

    func testDrillingViewRendersConsolidatedCardAndPillControl() {
        let (vm, _, _, _) = makeViewModel()
        vm.beginSessionDirectly()

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.drillingView)
        XCTAssertFalse(vm.isKeyboardFallbackActive)

        // Verify keyboard mode activation alters state
        vm.isKeyboardFallbackActive = true
        XCTAssertTrue(vm.isKeyboardFallbackActive)
        XCTAssertNotNil(view.drillingView)
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

    private func renderSnapshot<V: View>(view: V, filename: String) {
        let sizedView = view
            .frame(width: 393, height: 852)
            .background(Color.vocabCanvas)
            .environment(\.colorScheme, .dark)

        let renderer = ImageRenderer(content: sizedView)
        renderer.scale = 2.0
        renderer.proposedSize = ProposedViewSize(width: 393, height: 852)

        if let image = renderer.uiImage, let data = image.pngData() {
            let outputDir = URL(fileURLWithPath: "/Users/hoojinguyen/.gemini/antigravity/brain/c652ef14-7e40-47b1-81d8-6f055a9343f5/screenshots")
            try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            let fileURL = outputDir.appendingPathComponent(filename)
            try? data.write(to: fileURL)
            print("[Snapshot] Successfully saved with ImageRenderer: \(filename) (size: \(data.count) bytes)")
        } else {
            print("[Snapshot] ImageRenderer failed for \(filename)")
        }
    }

    func testCaptureAllReflexBlitzScreenshots() {
        // 1. Homepage Entry
        let container = AppContainer.mock
        let homeVM = container.makeHomepageViewModel()
        let homeView = HomepageView(viewModel: homeVM)
            .environment(\.appContainer, container)
            .environment(\.appRouter, container.appRouter)
        renderSnapshot(view: homeView, filename: "01_homepage_reflex_entry.png")

        // 2. Countdown Phase
        let (vmCountdown, _, _, _) = makeViewModel()
        vmCountdown.phase = .countdown
        vmCountdown.countdownCount = 3
        let countdownView = ReflexBlitzView(viewModel: vmCountdown, onDismiss: {})
        renderSnapshot(view: countdownView, filename: "02_reflex_countdown.png")

        // 3. Drilling Initial State (Normal listening)
        let (vmDrill, _, _, _) = makeViewModel()
        vmDrill.beginSessionDirectly()
        vmDrill.elapsedTimeMs = 1200
        let drillView = ReflexBlitzView(viewModel: vmDrill, onDismiss: {})
        renderSnapshot(view: drillView, filename: "03_reflex_drilling_initial.png")

        // 4. Drilling Scaffolding Hint Active
        let (vmHint, _, _, _) = makeViewModel()
        vmHint.beginSessionDirectly()
        vmHint.elapsedTimeMs = 4200
        vmHint.showHint = true
        let hintView = ReflexBlitzView(viewModel: vmHint, onDismiss: {})
        renderSnapshot(view: hintView, filename: "04_reflex_drilling_hint.png")

        // 5. Drilling Spoken Correct Match & Combo
        let (vmCorrect, _, _, _) = makeViewModel()
        vmCorrect.beginSessionDirectly()
        vmCorrect.loadWordForTesting(at: 1)
        vmCorrect.comboStreak = 3
        vmCorrect.currentAttemptIsCorrect = true
        vmCorrect.liveTranscript = "Finding this was pure serendipity"
        let correctView = ReflexBlitzView(viewModel: vmCorrect, onDismiss: {})
        renderSnapshot(view: correctView, filename: "05_reflex_drilling_correct_combo.png")

        // 6. Drilling Timeout & Revealing Answer
        let (vmTimeout, _, _, _) = makeViewModel()
        vmTimeout.beginSessionDirectly()
        vmTimeout.loadWordForTesting(at: 0)
        vmTimeout.phase = .timeoutRevealing
        let timeoutView = ReflexBlitzView(viewModel: vmTimeout, onDismiss: {})
        renderSnapshot(view: timeoutView, filename: "06_reflex_drilling_timeout_reveal.png")

        // 7. Drilling Keyboard Fallback Mode
        let (vmKeyb, _, _, _) = makeViewModel()
        vmKeyb.beginSessionDirectly()
        vmKeyb.isKeyboardFallbackActive = true
        let keybView = ReflexBlitzView(viewModel: vmKeyb, onDismiss: {})
        renderSnapshot(view: keybView, filename: "07_reflex_drilling_keyboard_mode.png")

        // 8. Session Summary Screen
        let (vmSummary, _, _, _) = makeViewModel()
        vmSummary.beginSessionDirectly()
        let attempts = [
            ReflexBlitzAttempt(wordId: 1, lemma: "ephemeral", responseTimeMs: 1400, usedHint: false, isCorrect: true),
            ReflexBlitzAttempt(wordId: 2, lemma: "serendipity", responseTimeMs: 2100, usedHint: false, isCorrect: true),
            ReflexBlitzAttempt(wordId: 3, lemma: "resilient", responseTimeMs: 6000, usedHint: true, isCorrect: false),
            ReflexBlitzAttempt(wordId: 4, lemma: "meticulous", responseTimeMs: 5200, usedHint: true, isCorrect: true),
            ReflexBlitzAttempt(wordId: 5, lemma: "eloquent", responseTimeMs: 6000, usedHint: true, isCorrect: false)
        ]
        vmSummary.attempts = attempts
        let summary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: 2)
        vmSummary.sessionSummary = summary
        vmSummary.phase = .summary
        let summaryView = ReflexBlitzSummaryView(
            summary: summary,
            onReDrillWeak: {},
            onFinish: {}
        )
        renderSnapshot(
            view: summaryView.summaryContent
                .padding(.top, 40)
                .frame(width: 393, alignment: .top),
            filename: "08_reflex_summary_screen.png"
        )
    }
}
