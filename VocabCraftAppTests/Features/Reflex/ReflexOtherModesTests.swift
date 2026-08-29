import CraftUIKit
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("ReflexOtherModes Tests")
struct ReflexOtherModesTests {
    @Test("Instantiates SpeakingModeView with live transcript, cloze stages, and callbacks")
    func testSpeakingModeView() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let stageSet = ReflexHintMaskGenerator.generateStages(
            sentence: item.clozeSentenceEn,
            targetWord: item.lemma
        )
        var switchedToKeyboard = false
        let speakingView = ReflexSpeakingModeView(
            word: item,
            liveTranscript: "habit",
            elapsedTimeMs: 1200,
            showHint: true,
            hintStage: 1,
            clozeStages: stageSet,
            hintBadgeText: "Gợi ý: h • • • •",
            onSwitchToKeyboard: {
                switchedToKeyboard = true
            }
        )
        #expect(speakingView.word.lemma == "habit")
        #expect(speakingView.liveTranscript == "habit")
        #expect(speakingView.elapsedTimeMs == 1200)
        #expect(speakingView.showHint == true)
        #expect(speakingView.hintStage == 1)
        #expect(speakingView.hintBadgeText == "Gợi ý: h • • • •")
        #expect(speakingView.activeClozeParts?.slot == "• • • • •")
        speakingView.onSwitchToKeyboard?()
        #expect(switchedToKeyboard == true)
    }

    @Test("Instantiates TypingModeView with binding, cloze stages, and submit callback")
    func testTypingModeView() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let stageSet = ReflexHintMaskGenerator.generateStages(
            sentence: item.clozeSentenceEn,
            targetWord: item.lemma
        )
        var text = "hab"
        var submitted = false
        let typingBinding = Binding(get: { text }, set: { text = $0 })
        let typingView = ReflexTypingModeView(
            word: item,
            typingText: typingBinding,
            showHint: true,
            hintStage: 2,
            clozeStages: stageSet,
            hintBadgeText: "Gợi ý: h _ _ i t",
            onSubmit: {
                submitted = true
            }
        )
        #expect(typingView.word.lemma == "habit")
        #expect(typingView.typingText == "hab")
        #expect(typingView.showHint == true)
        #expect(typingView.hintStage == 2)
        #expect(typingView.hintBadgeText == "Gợi ý: h _ _ i t")
        #expect(typingView.activeClozeParts?.slot == stageSet.maskedWordString)
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
            hintStage: 3,
            eliminatedOptionId: "opt-2",
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
        #expect(activeView.choiceState(for: wrongOpt) == .disabled)
        #expect(activeView.choiceState(for: otherOpt) == .idle)

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
