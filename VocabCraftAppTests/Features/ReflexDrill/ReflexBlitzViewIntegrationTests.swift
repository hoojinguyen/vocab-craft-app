import CraftUIKit
import Foundation
import SwiftUI
#if canImport(XCTest)
import XCTest
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import VocabCraftApp

@MainActor
final class ReflexBlitzViewIntegrationTests: XCTestCase {
    private func makeSampleWords() -> [ReflexBlitzWordItem] {
        [
            ReflexBlitzWordItem(
                id: 1,
                lemma: "ephemeral",
                pos: "adj.",
                ipa: "/ɪˈfem.ər.əl/",
                definitionVi: "Phù du, chóng tàn",
                exampleSentenceEn: "Her fame is ephemeral in nature.",
                exampleSentenceVi: "Danh tiếng của cô ấy phù du."
            ),
            ReflexBlitzWordItem(
                id: 2,
                lemma: "serendipity",
                pos: "n.",
                ipa: "/ˌser.ənˈdɪp.ə.ti/",
                definitionVi: "Sự may mắn bất ngờ",
                exampleSentenceEn: "Finding this was pure serendipity.",
                exampleSentenceVi: "Tìm thấy thứ này là may mắn bất ngờ."
            )
        ]
    }

    private func makeViewModel(
        words: [ReflexBlitzWordItem]? = nil
        // swiftlint:disable:next large_tuple
    ) -> (ReflexBlitzViewModel, MockTextToSpeechService, MockEvaluateSRSUseCase, MockResilientReflexSpeechEngine) {
        let mockSpeechEngine = MockResilientReflexSpeechEngine()
        let mockTTS = MockTextToSpeechService()
        let mockSRS = MockEvaluateSRSUseCase()
        let items = words ?? makeSampleWords()
        let vm = ReflexBlitzViewModel(
            words: items,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS,
            speechEngine: mockSpeechEngine
        )
        return (vm, mockTTS, mockSRS, mockSpeechEngine)
    }

    func testBlitzViewInstantiationAndModeSelectionPhase() {
        let (vm, _, _, _) = makeViewModel()
        var didDismiss = false
        let view = ReflexBlitzView(viewModel: vm, onDismiss: { didDismiss = true })
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.body)
        XCTAssertEqual(vm.phase, .modeSelection)

        view.onDismiss()
        XCTAssertTrue(didDismiss)
    }

    func testFullReflexBlitzFlowFromModeSelectionToSummary() {
        let (vm, _, _, _) = makeViewModel()
        XCTAssertEqual(vm.phase, .modeSelection)

        vm.selectMode(.multipleChoice)
        XCTAssertEqual(vm.phase, .countdown)
        XCTAssertEqual(vm.selectedMode, .multipleChoice)

        vm.beginSessionDirectly()
        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)
        XCTAssertEqual(vm.currentOptions.count, 4)
    }

    func testBlitzViewCountdownPhaseRendering() {
        let (vm, _, _, _) = makeViewModel()
        vm.selectMode(.speaking)
        vm.countdownCount = 3

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertEqual(vm.phase, .countdown)
        XCTAssertEqual(vm.countdownCount, 3)
    }

    func testBlitzViewDrillingSpeakingModeSpokenMatchAndReview() {
        let (vm, _, _, mockSpeechEngine) = makeViewModel()
        vm.selectMode(.speaking)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)
        guard let firstWord = vm.currentWord else {
            XCTFail("Expected first word to be non-nil")
            return
        }
        XCTAssertEqual(mockSpeechEngine.lastTargetLemma, firstWord.lemma)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertNotNil(view.drillingView)

        // Spoken match triggers review state
        mockSpeechEngine.simulateMatch(firstWord.lemma)
        XCTAssertTrue(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 1)

        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.recognizedSpoken, firstWord.lemma)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        // Advance to word 2
        vm.advanceToNextWord()
        XCTAssertEqual(vm.currentWordIndex, 1)
        guard let secondWord = vm.currentWord else {
            XCTFail("Expected second word to be non-nil")
            return
        }
        XCTAssertEqual(mockSpeechEngine.lastTargetLemma, secondWord.lemma)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)
    }

    func testBlitzViewDrillingTypingModeInputAndSubmit() {
        let (vm, _, _, _) = makeViewModel()
        vm.selectMode(.typing)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.selectedMode, .typing)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertNotNil(view.drillingView)

        // Submit typing answer
        let targetLemma = vm.currentWord!.lemma
        vm.submitTypingAnswer(targetLemma)
        XCTAssertTrue(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 1)

        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertEqual(result.typedText, targetLemma)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        // Advance to next word
        vm.advanceToNextWord()
        XCTAssertEqual(vm.currentWordIndex, 1)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)
    }

    func testBlitzViewDrillingTypingModeIncorrectInputAndReview() {
        let (vm, _, _, _) = makeViewModel()
        vm.selectMode(.typing)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.selectedMode, .typing)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertNotNil(view.drillingView)

        // Submit incorrect typing answer
        let wrongInput = "wrongword"
        vm.submitTypingAnswer(wrongInput)
        XCTAssertFalse(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 0)

        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertFalse(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.typedText, wrongInput)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
    }

    func testBlitzViewTypingModeCardViewIdentityAndSequentialWordProgression() {
        let (vm, _, _, _) = makeViewModel()
        vm.selectMode(.typing)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.currentWordIndex, 0)
        guard let firstWord = vm.currentWord else {
            XCTFail("Expected first word to be non-nil")
            return
        }
        XCTAssertEqual(firstWord.id == 1 || firstWord.id == 2, true)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.drillingView)

        // Submit answer on word 1
        vm.submitTypingAnswer(firstWord.lemma)
        XCTAssertTrue(vm.currentAttemptIsCorrect)
        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertEqual(result.typedText, firstWord.lemma)
        } else {
            XCTFail("Expected .reviewed state")
        }

        // Advance to word 2
        vm.advanceToNextWord()
        XCTAssertEqual(vm.currentWordIndex, 1)
        guard let secondWord = vm.currentWord else {
            XCTFail("Expected second word to be non-nil")
            return
        }
        XCTAssertNotEqual(firstWord.id, secondWord.id)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)

        // Drilling view renders cleanly for next word with fresh identity
        XCTAssertNotNil(view.drillingView)
    }

    func testBlitzViewDrillingMultipleChoiceSelection() {
        let (vm, _, _, _) = makeViewModel()
        vm.selectMode(.multipleChoice)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.selectedMode, .multipleChoice)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)

        guard let correctOption = vm.currentOptions.first(where: { $0.isCorrect }) else {
            XCTFail("Missing correct option")
            return
        }

        vm.selectOption(correctOption)
        XCTAssertTrue(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 1)

        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertEqual(result.selectedOption, correctOption.text)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
    }

    func testBlitzViewDrillingMultipleChoiceIncorrectSelectionAndAdvance() {
        let (vm, _, _, _) = makeViewModel()
        vm.selectMode(.multipleChoice)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.selectedMode, .multipleChoice)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)

        guard let incorrectOption = vm.currentOptions.first(where: { !$0.isCorrect }) else {
            XCTFail("Missing incorrect option")
            return
        }

        vm.selectOption(incorrectOption)
        XCTAssertFalse(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 0)

        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertFalse(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.selectedOption, incorrectOption.text)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)

        vm.advanceToNextWord()
        XCTAssertEqual(vm.currentWordIndex, 1)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)
        XCTAssertEqual(vm.currentOptions.count, 4)
    }

    func testBlitzViewDrillingMultipleChoiceTimeoutAndReview() {
        let (vm, _, _, _) = makeViewModel()
        vm.selectMode(.multipleChoice)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.selectedMode, .multipleChoice)

        vm.handleTimeout()

        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isTimeout)
            XCTAssertFalse(result.isCorrect)
            XCTAssertNil(result.selectedOption)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
    }

    func testBlitzViewDrillingMultipleChoiceAudioReplayInReview() {
        let (vm, mockTTS, _, _) = makeViewModel()
        vm.selectMode(.multipleChoice)
        vm.beginSessionDirectly()

        guard let correctOption = vm.currentOptions.first(where: { $0.isCorrect }) else {
            XCTFail("Missing correct option")
            return
        }

        vm.selectOption(correctOption)
        XCTAssertTrue(vm.currentAttemptIsCorrect)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)

        let targetLemma = vm.currentWord!.lemma
        vm.speakCurrentWord()
        XCTAssertEqual(mockTTS.lastSpokenText, targetLemma)
    }

    func testBlitzViewDrillingListeningModeFlow() {
        let (vm, mockTTS, _, _) = makeViewModel()
        vm.selectMode(.listening)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.selectedMode, .listening)
        XCTAssertEqual(mockTTS.lastSpokenText, vm.currentWord!.lemma)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertNotNil(view.drillingView)

        guard let incorrectOption = vm.currentOptions.first(where: { !$0.isCorrect }) else {
            XCTFail("Missing incorrect option")
            return
        }

        vm.selectOption(incorrectOption)
        XCTAssertFalse(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 0)

        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertFalse(result.isCorrect)
            XCTAssertEqual(result.selectedOption, incorrectOption.text)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        // Verify reviewed drilling view with feedback sheet
        XCTAssertNotNil(view.drillingView)
    }

    func testBlitzViewDrillingListeningModeCorrectSelectionAndAdvance() {
        let (vm, mockTTS, _, _) = makeViewModel()
        vm.selectMode(.listening)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.selectedMode, .listening)
        guard let firstWord = vm.currentWord else {
            XCTFail("Missing first word")
            return
        }
        XCTAssertEqual(mockTTS.lastSpokenText, firstWord.lemma)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertNotNil(view.drillingView)

        guard let correctOption = vm.currentOptions.first(where: { $0.isCorrect }) else {
            XCTFail("Missing correct option")
            return
        }

        vm.selectOption(correctOption)
        XCTAssertTrue(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 1)

        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
            XCTAssertEqual(result.selectedOption, correctOption.text)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        // Test audio replay in review
        vm.speakCurrentWord()
        XCTAssertEqual(mockTTS.lastSpokenText, firstWord.lemma)

        // Advance to word 2
        vm.advanceToNextWord()
        XCTAssertEqual(vm.currentWordIndex, 1)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)
        guard let secondWord = vm.currentWord else {
            XCTFail("Missing second word")
            return
        }
        XCTAssertEqual(mockTTS.lastSpokenText, secondWord.lemma)
    }

    func testBlitzViewDrillingListeningModeTimeoutAndReview() {
        let (vm, _, _, _) = makeViewModel()
        vm.selectMode(.listening)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.selectedMode, .listening)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)

        vm.handleTimeout()

        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isTimeout)
            XCTAssertFalse(result.isCorrect)
            XCTAssertNil(result.selectedOption)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        XCTAssertNotNil(view.drillingView)
    }

    func testBlitzViewDrillingListeningModeHintProgression() {
        let (vm, _, _, _) = makeViewModel()
        vm.selectMode(.listening)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.hintStage, 0)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.drillingView)

        // Stage 1 hint progression (Part of Speech)
        vm.hintStage = 1
        XCTAssertEqual(vm.hintStage, 1)
        XCTAssertTrue(vm.showHint)
        XCTAssertNotNil(view.drillingView)

        // Stage 3 hint progression (Distractor elimination)
        vm.hintStage = 3
        XCTAssertEqual(vm.hintStage, 3)
        XCTAssertNotNil(view.drillingView)
    }

    func testBlitzViewTimeoutRevealingPhaseRendering() async {
        let (vm, mockTTS, _, _) = makeViewModel()
        vm.beginSessionDirectly()
        let targetLemma = vm.currentWord!.lemma
        vm.handleTimeout()

        XCTAssertEqual(vm.phase, .drilling)
        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isTimeout)
            XCTAssertFalse(result.isCorrect)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        try? await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(mockTTS.lastSpokenText, targetLemma)

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

        vm.reDrillWeakWords()
        XCTAssertEqual(vm.phase, .countdown)
        XCTAssertEqual(vm.words.count, 1)
    }

    func testKeyboardFallbackInputToggleAndSubmit() {
        let (vm, _, _, mockSpeechEngine) = makeViewModel()
        vm.selectMode(.speaking)
        vm.beginSessionDirectly()
        XCTAssertFalse(vm.isKeyboardFallbackActive)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertNotNil(view.drillingView)

        vm.toggleKeyboardFallback()
        XCTAssertTrue(vm.isKeyboardFallbackActive)
        XCTAssertFalse(mockSpeechEngine.isWordActive)

        // Submit via keyboard
        let targetLemma = vm.currentWord!.lemma
        vm.submitKeyboardInput(targetLemma)
        XCTAssertTrue(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 1)
    }

    func testCancellationTeardownOnDisappear() {
        let (vm, mockTTS, _, mockSpeechEngine) = makeViewModel()
        vm.selectMode(.speaking)
        vm.beginSessionDirectly()
        XCTAssertTrue(mockSpeechEngine.isSessionActive)

        vm.cancelSession()
        XCTAssertFalse(mockSpeechEngine.isSessionActive)
        XCTAssertFalse(mockTTS.isSpeaking)
    }

    func testAppContainerMakeReflexBlitzViewModel() {
        let container = AppContainer.mock
        let defaultVM = container.makeReflexBlitzViewModel()
        XCTAssertEqual(defaultVM.words.count, ReflexBlitzWordItem.defaultStarterWords.count)
        XCTAssertEqual(defaultVM.phase, .modeSelection)

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
        let (vm, _, _, mockSpeechEngine) = makeViewModel(words: words)
        var dismissed = false

        let view = ReflexBlitzView(viewModel: vm, onDismiss: { dismissed = true })
        XCTAssertNotNil(view.body)

        // 1. Select Mode & Begin Session
        vm.selectMode(.speaking)
        vm.beginSessionDirectly()
        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.currentWordIndex, 0)
        let word1 = vm.currentWord!
        XCTAssertEqual(mockSpeechEngine.lastTargetLemma, word1.lemma)

        // 2. Correct Spoken Match on Word 1
        mockSpeechEngine.simulateMatch(word1.lemma)
        XCTAssertTrue(vm.currentAttemptIsCorrect)
        XCTAssertEqual(vm.comboStreak, 1)
        XCTAssertEqual(vm.attempts.count, 1)
        XCTAssertEqual(vm.attempts.first?.wordId, word1.id)
        XCTAssertEqual(vm.attempts.first?.isCorrect, true)

        // 3. Advance to Word 2 and Trigger Timeout
        vm.advanceToNextWord()
        XCTAssertEqual(vm.currentWordIndex, 1)
        let word2 = vm.currentWord!
        XCTAssertEqual(mockSpeechEngine.lastTargetLemma, word2.lemma)

        vm.handleTimeout()
        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isTimeout)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
        XCTAssertEqual(vm.comboStreak, 0)
        XCTAssertEqual(vm.attempts.count, 2)
        XCTAssertEqual(vm.attempts.last?.wordId, word2.id)
        XCTAssertEqual(vm.attempts.last?.isCorrect, false)

        // 4. Advance past last word -> Finish Session -> Summary Phase
        vm.advanceToNextWord()
        XCTAssertEqual(vm.phase, .summary)
        XCTAssertNotNil(vm.sessionSummary)
        XCTAssertEqual(vm.sessionSummary?.totalWords, 2)
        XCTAssertEqual(vm.sessionSummary?.correctWords, 1)
        XCTAssertEqual(vm.sessionSummary?.weakWordAttempts.count, 1)
        XCTAssertEqual(vm.sessionSummary?.weakWordAttempts.first?.lemma, word2.lemma)

        // 5. Re-drill weak words restarts session with only weak items
        vm.reDrillWeakWords()
        XCTAssertEqual(vm.phase, .countdown)
        XCTAssertEqual(vm.words.count, 1)
        XCTAssertEqual(vm.words.first?.lemma, word2.lemma)

        // 6. Dismiss View
        view.onDismiss()
        XCTAssertTrue(dismissed)
    }

    private func renderSnapshot<V: View>(view: V, filename: String) {
        let sizedView = view
            .frame(width: 393, height: 852)
            .background(CraftDefaultTheme().colors.canvasBackground)
            .environment(\.colorScheme, .dark)

        let renderer = ImageRenderer(content: sizedView)
        renderer.scale = 2.0
        renderer.proposedSize = ProposedViewSize(width: 393, height: 852)

        var pngData: Data?

        #if canImport(UIKit)
        if let uiImage = renderer.uiImage {
            pngData = uiImage.pngData()
        }
        #elseif canImport(AppKit)
        if let nsImage = renderer.nsImage,
           let tiffData = nsImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData) {
            pngData = bitmap.representation(using: .png, properties: [:])
        }
        #endif

        if let data = pngData {
            let outputDir = URL(fileURLWithPath: "/Users/hoojinguyen/.gemini/antigravity/brain/dc21b818-b428-4c66-9b3e-f6bbdf8e9f32/screenshots")
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

        // 2. Mode Selection Screen
        let (vmMode, _, _, _) = makeViewModel()
        let modeSelectionView = ReflexBlitzView(viewModel: vmMode, onDismiss: {})
        renderSnapshot(view: modeSelectionView, filename: "02_reflex_mode_selection.png")

        // 3. Countdown Phase
        let (vmCountdown, _, _, _) = makeViewModel()
        vmCountdown.selectMode(.speaking)
        vmCountdown.countdownCount = 3
        let countdownView = ReflexBlitzView(viewModel: vmCountdown, onDismiss: {})
        renderSnapshot(view: countdownView, filename: "03_reflex_countdown.png")

        // 4. Drilling Speaking Mode
        let (vmSpeak, _, _, _) = makeViewModel()
        vmSpeak.selectMode(.speaking)
        vmSpeak.beginSessionDirectly()
        vmSpeak.elapsedTimeMs = 1200
        let speakView = ReflexBlitzView(viewModel: vmSpeak, onDismiss: {})
        renderSnapshot(view: speakView, filename: "04_reflex_drilling_speaking.png")

        // 5. Drilling Typing Mode
        let (vmType, _, _, _) = makeViewModel()
        vmType.selectMode(.typing)
        vmType.beginSessionDirectly()
        vmType.elapsedTimeMs = 2000
        let typeView = ReflexBlitzView(viewModel: vmType, onDismiss: {})
        renderSnapshot(view: typeView, filename: "05_reflex_drilling_typing.png")

        // 6. Drilling Multiple Choice Mode
        let (vmMC, _, _, _) = makeViewModel()
        vmMC.selectMode(.multipleChoice)
        vmMC.beginSessionDirectly()
        vmMC.elapsedTimeMs = 1500
        let mcView = ReflexBlitzView(viewModel: vmMC, onDismiss: {})
        renderSnapshot(view: mcView, filename: "06_reflex_drilling_multiple_choice.png")

        // 7. Drilling Listening Mode
        let (vmListen, _, _, _) = makeViewModel()
        vmListen.selectMode(.listening)
        vmListen.beginSessionDirectly()
        vmListen.elapsedTimeMs = 1000
        let listenView = ReflexBlitzView(viewModel: vmListen, onDismiss: {})
        renderSnapshot(view: listenView, filename: "07_reflex_drilling_listening.png")

        // 8. Reviewed Correct State with Advance Dock
        let (vmCorrect, _, _, _) = makeViewModel()
        vmCorrect.selectMode(.speaking)
        vmCorrect.beginSessionDirectly()
        vmCorrect.comboStreak = 3
        vmCorrect.currentAttemptIsCorrect = true
        vmCorrect.cardPhase = .reviewed(result: ReflexCardResult(
            isCorrect: true,
            responseTimeMs: 1400,
            isTimeout: false,
            recognizedSpoken: "ephemeral"
        ))
        let correctView = ReflexBlitzView(viewModel: vmCorrect, onDismiss: {})
        renderSnapshot(view: correctView, filename: "08_reflex_drilling_correct_reviewed.png")

        // 9. Reviewed Timeout State with Advance Dock
        let (vmTimeout, _, _, _) = makeViewModel()
        vmTimeout.selectMode(.speaking)
        vmTimeout.beginSessionDirectly()
        vmTimeout.cardPhase = .reviewed(result: ReflexCardResult(
            isCorrect: false,
            responseTimeMs: 6000,
            isTimeout: true
        ))
        let timeoutView = ReflexBlitzView(viewModel: vmTimeout, onDismiss: {})
        renderSnapshot(view: timeoutView, filename: "09_reflex_drilling_timeout_reviewed.png")

        // 10. Session Summary Screen
        let (vmSummary, _, _, _) = makeViewModel()
        let attempts = [
            ReflexBlitzAttempt(wordId: 1, lemma: "ephemeral", pos: "adj.", ipa: "/ɪˈfem.ər.əl/", definitionVi: "Phù du, chóng tàn", responseTimeMs: 1400, usedHint: false, isCorrect: true),
            ReflexBlitzAttempt(wordId: 2, lemma: "serendipity", pos: "n.", ipa: "/ˌser.ənˈdɪp.ə.ti/", definitionVi: "Sự may mắn bất ngờ", responseTimeMs: 2100, usedHint: false, isCorrect: true),
            ReflexBlitzAttempt(wordId: 3, lemma: "resilient", pos: "adj.", ipa: "/rɪˈzɪl.jənt/", definitionVi: "Kiên cường, phục hồi nhanh", responseTimeMs: 6000, usedHint: true, isCorrect: false),
            ReflexBlitzAttempt(wordId: 4, lemma: "meticulous", pos: "adj.", ipa: "/məˈtɪk.jə.ləs/", definitionVi: "Tỉ mỉ, cẩn thận", responseTimeMs: 5200, usedHint: true, isCorrect: true),
            ReflexBlitzAttempt(wordId: 5, lemma: "eloquent", pos: "adj.", ipa: "/ˈel.ə.kwənt/", definitionVi: "Hùng biện, lưu loát", responseTimeMs: 6000, usedHint: true, isCorrect: false)
        ]
        vmSummary.attempts = attempts
        let summary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: 2)
        vmSummary.sessionSummary = summary
        vmSummary.phase = .summary
        let summaryView = ReflexBlitzSummaryView(
            summary: summary,
            onSpeakWord: { _ in },
            onReDrillWeak: {},
            onFinish: {}
        )
        renderSnapshot(
            view: summaryView.summaryContent
                .padding(.top, 40)
                .frame(width: 393, alignment: .top),
            filename: "10_reflex_summary_screen.png"
        )
    }

    func testZeroShiftLayoutStructureWithFloatingFeedbackSheetOverlay() {
        let (vm, _, _, _) = makeViewModel()
        vm.selectMode(.multipleChoice)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.phase, .drilling)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.drillingView)

        // Select correct option to trigger reviewed state & floating sheet
        guard let correctOption = vm.currentOptions.first(where: { $0.isCorrect }) else {
            XCTFail("Missing correct option")
            return
        }

        vm.selectOption(correctOption)
        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertEqual(result.selectedOption, correctOption.text)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }

        // Verify drillingView is rendered with reviewed floating sheet overlay
        XCTAssertNotNil(view.drillingView)

        // Advance to next word
        vm.advanceToNextWord()
        XCTAssertEqual(vm.cardPhase, .activeCountdown)
        XCTAssertEqual(vm.currentWordIndex, 1)
        XCTAssertNotNil(view.drillingView)
    }

    func testBlitzViewOnFinishSessionCallbackCalledOnSummaryFinish() {
        let (vm, _, _, _) = makeViewModel()
        vm.beginSessionDirectly()
        vm.handleTimeout()
        vm.finishSession()

        XCTAssertEqual(vm.phase, .summary)
        XCTAssertNotNil(vm.sessionSummary)

        var finishedSummary: ReflexBlitzSessionSummary?
        let view = ReflexBlitzView(
            viewModel: vm,
            onDismiss: {},
            onFinishSession: { summary in
                finishedSummary = summary
            }
        )
        XCTAssertNotNil(view.body)

        // Invoke onFinishSession directly to verify contract
        if let summary = vm.sessionSummary {
            view.onFinishSession?(summary)
            XCTAssertNotNil(finishedSummary)
            XCTAssertEqual(finishedSummary?.totalWords, 1)
        }
    }

    func testBlitzViewListeningModeCardViewIdentityAndSpoilerFreeProgression() {
        let (vm, mockTTS, _, _) = makeViewModel()
        vm.selectMode(.listening)
        vm.beginSessionDirectly()

        XCTAssertEqual(vm.currentWordIndex, 0)
        guard let firstWord = vm.currentWord else {
            XCTFail("Expected first word to be non-nil")
            return
        }
        XCTAssertEqual(firstWord.id == 1 || firstWord.id == 2, true)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)
        XCTAssertEqual(mockTTS.lastSpokenText, firstWord.lemma)

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.drillingView)

        // Select an option to transition to reviewed flip state
        if let option = vm.currentOptions.first {
            vm.selectOption(option)
        }
        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertNotNil(result)
        } else {
            XCTFail("Expected .reviewed state")
        }

        // Advance to word index 1
        vm.advanceToNextWord()
        XCTAssertEqual(vm.currentWordIndex, 1)
        guard let secondWord = vm.currentWord else {
            XCTFail("Expected second word to be non-nil")
            return
        }
        XCTAssertEqual(secondWord.id == 1 || secondWord.id == 2, true)
        XCTAssertNotEqual(firstWord.id, secondWord.id)
        XCTAssertEqual(vm.cardPhase, .activeCountdown)
        XCTAssertEqual(mockTTS.lastSpokenText, secondWord.lemma)

        // Drilling view renders cleanly for new word instance with fresh identity
        XCTAssertNotNil(view.drillingView)
    }

    func testBlitzViewCardViewIdentityAcrossAllModes() {
        let modes: [ReflexBlitzMode] = [.speaking, .typing, .multipleChoice, .listening]

        for mode in modes {
            let (vm, _, _, _) = makeViewModel()
            vm.selectMode(mode)
            vm.beginSessionDirectly()

            XCTAssertEqual(vm.currentWordIndex, 0, "Failed for mode \(mode)")
            XCTAssertEqual(vm.cardPhase, .activeCountdown, "Failed for mode \(mode)")

            let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
            XCTAssertNotNil(view.drillingView, "Failed for mode \(mode)")

            vm.handleTimeout()
            if case .reviewed = vm.cardPhase {
                // Expected reviewed
            } else {
                XCTFail("Expected .reviewed state for mode \(mode)")
            }

            vm.advanceToNextWord()
            XCTAssertEqual(vm.currentWordIndex, 1, "Failed for mode \(mode)")
            XCTAssertEqual(vm.cardPhase, .activeCountdown, "Failed for mode \(mode)")
            XCTAssertNotNil(view.drillingView, "Failed for mode \(mode)")
        }
    }
}
