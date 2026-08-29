import CraftUIKit
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("ReflexOtherModes Tests")
struct ReflexOtherModesTests {
    @Test("Instantiates SpeakingModeView with live transcript and callbacks")
    func testSpeakingModeView() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        var switchedToKeyboard = false
        let speakingView = ReflexSpeakingModeView(
            word: item,
            liveTranscript: "habit",
            elapsedTimeMs: 1200,
            showHint: true,
            onSwitchToKeyboard: {
                switchedToKeyboard = true
            }
        )
        #expect(speakingView.word.lemma == "habit")
        #expect(speakingView.liveTranscript == "habit")
        #expect(speakingView.elapsedTimeMs == 1200)
        #expect(speakingView.showHint == true)
        speakingView.onSwitchToKeyboard?()
        #expect(switchedToKeyboard == true)
    }

    @Test("Instantiates TypingModeView with binding and submit callback")
    func testTypingModeView() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        var text = "hab"
        var submitted = false
        let typingBinding = Binding(get: { text }, set: { text = $0 })
        let typingView = ReflexTypingModeView(
            word: item,
            typingText: typingBinding,
            showHint: true,
            onSubmit: {
                submitted = true
            }
        )
        #expect(typingView.word.lemma == "habit")
        #expect(typingView.typingText == "hab")
        #expect(typingView.showHint == true)
        typingBinding.wrappedValue = "habit"
        #expect(typingView.typingText == "habit")
        typingView.onSubmit?()
        #expect(submitted == true)
    }

    @Test("Instantiates ListeningModeView with options, audio replay, and choice selection")
    func testListeningModeView() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let correctOpt = ReflexBlitzOption(id: "opt-1", text: "thói quen", isCorrect: true)
        let wrongOpt = ReflexBlitzOption(id: "opt-2", text: "cải thiện", isCorrect: false)
        let otherOpt = ReflexBlitzOption(id: "opt-3", text: "tập trung", isCorrect: false)
        let options = [correctOpt, wrongOpt, otherOpt]

        var audioPlayed = false
        var selectedOption: ReflexBlitzOption?

        let activeView = ReflexListeningModeView(
            word: item,
            options: options,
            elapsedTimeMs: 500,
            isReviewed: false,
            onPlayAudio: {
                audioPlayed = true
            },
            onSelectOption: { opt in
                selectedOption = opt
            }
        )

        #expect(activeView.options.count == 3)
        #expect(activeView.elapsedTimeMs == 500)
        #expect(activeView.isReviewed == false)
        #expect(activeView.choiceState(for: correctOpt) == .idle)
        #expect(activeView.choiceState(for: wrongOpt) == .idle)

        activeView.onPlayAudio?()
        #expect(audioPlayed == true)

        activeView.onSelectOption?(correctOpt)
        #expect(selectedOption?.id == "opt-1")

        let reviewedView = ReflexListeningModeView(
            word: item,
            options: options,
            elapsedTimeMs: 1500,
            isReviewed: true,
            selectedOptionText: "cải thiện",
            onPlayAudio: nil,
            onSelectOption: nil
        )

        #expect(reviewedView.isReviewed == true)
        #expect(reviewedView.choiceState(for: correctOpt) == .correct)
        #expect(reviewedView.choiceState(for: wrongOpt) == .wrong)
        #expect(reviewedView.choiceState(for: otherOpt) == .disabled)
    }
}
