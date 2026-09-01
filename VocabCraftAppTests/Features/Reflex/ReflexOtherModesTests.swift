import CraftUIKit
import Foundation
import SwiftUI
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("ReflexOtherModes Tests")
struct ReflexOtherModesTests {
    @Test("Instantiates SpeakingModeView with live transcript, cloze stages, and callbacks")
    func testSpeakingModeView() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let stageSet = ReflexHintMaskGenerator.generateStages(
            lemma: item.lemma,
            sentenceEn: item.clozeSentenceEn,
            pos: item.cleanPos
        )
        var audioReplayed = false
        var cantSpeakNowTapped = false
        let speakingView = ReflexSpeakingModeView(
            word: item,
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: true,
            hintStage: 1,
            clozeStages: stageSet,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
            displayedSentence: item.clozeSentenceEn,
            hintBadgeText: item.cleanInitialLetterHint,
            speechState: .listening(),
            liveTranscript: "habit",
            onCantSpeakNow: {
                cantSpeakNowTapped = true
            },
            onReplayAudio: {
                audioReplayed = true
            }
        )
        #expect(speakingView.word.lemma == "habit")
        #expect(speakingView.isReviewed == false)
        #expect(speakingView.isResultCorrect == false)
        #expect(speakingView.isResultTimeout == false)
        #expect(speakingView.liveTranscript == "habit")
        #expect(speakingView.showHint == true)
        #expect(speakingView.hintStage == 1)
        #expect(speakingView.hintBadgeText == item.cleanInitialLetterHint)
        #expect(speakingView.activeClozeParts?.slot == stageSet.lengthMaskedParts.slot)
        #expect(speakingView.speechState == .listening())
        speakingView.onCantSpeakNow?()
        #expect(cantSpeakNowTapped == true)
        speakingView.onReplayAudio?()
        #expect(audioReplayed == true)
    }

    @Test("Instantiates SpeakingModeView in reviewed correct and incorrect states")
    func testSpeakingModeViewReviewedStates() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]

        let correctView = ReflexSpeakingModeView(
            word: item,
            isReviewed: true,
            isResultCorrect: true,
            isResultTimeout: false,
            speechState: .evaluated(overallScore: 100),
            liveTranscript: "habit"
        )
        #expect(correctView.isReviewed == true)
        #expect(correctView.isResultCorrect == true)
        #expect(correctView.isResultTimeout == false)
        #expect(correctView.liveTranscript == "habit")
        #expect(correctView.speechState == .evaluated(overallScore: 100))

        let incorrectView = ReflexSpeakingModeView(
            word: item,
            isReviewed: true,
            isResultCorrect: false,
            isResultTimeout: false,
            speechState: .evaluated(overallScore: 0),
            liveTranscript: "rabbit"
        )
        #expect(incorrectView.isReviewed == true)
        #expect(incorrectView.isResultCorrect == false)
        #expect(incorrectView.isResultTimeout == false)
        #expect(incorrectView.liveTranscript == "rabbit")
        #expect(incorrectView.speechState == .evaluated(overallScore: 0))

        let timeoutView = ReflexSpeakingModeView(
            word: item,
            isReviewed: true,
            isResultCorrect: false,
            isResultTimeout: true,
            speechState: .evaluated(overallScore: 0),
            liveTranscript: ""
        )
        #expect(timeoutView.isReviewed == true)
        #expect(timeoutView.isResultTimeout == true)
        #expect(timeoutView.liveTranscript == "")
    }

    @Test("Instantiates TypingModeView with binding, cloze stages, and submit callback")
    func testTypingModeView() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let stageSet = ReflexHintMaskGenerator.generateStages(
            lemma: item.lemma,
            sentenceEn: item.clozeSentenceEn,
            pos: item.cleanPos
        )
        var text = "hab"
        var submitted = false
        var audioReplayed = false
        let typingBinding = Binding(get: { text }, set: { text = $0 })
        let typingView = ReflexTypingModeView(
            word: item,
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: true,
            hintStage: 2,
            typingText: typingBinding,
            userSubmittedText: nil,
            clozeStages: stageSet,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
            displayedSentence: item.clozeSentenceEn,
            hintBadgeText: item.cleanInitialLetterHint,
            onSubmit: {
                submitted = true
            },
            onReplayAudio: {
                audioReplayed = true
            }
        )
        #expect(typingView.word.lemma == "habit")
        #expect(typingView.typingText == "hab")
        #expect(typingView.isReviewed == false)
        #expect(typingView.isResultCorrect == false)
        #expect(typingView.isResultTimeout == false)
        #expect(typingView.showHint == true)
        #expect(typingView.hintStage == 2)
        #expect(typingView.hintBadgeText == item.cleanInitialLetterHint)
        #expect(typingView.activeClozeParts?.slot == stageSet.patternRevealedParts.slot)
        typingBinding.wrappedValue = "habit"
        #expect(typingView.typingText == "habit")
        typingView.onSubmit?()
        #expect(submitted == true)
        typingView.onReplayAudio?()
        #expect(audioReplayed == true)
    }

    @Test("Instantiates TypingModeView in reviewed correct and incorrect states")
    func testTypingModeViewReviewedStates() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        var text = "habit"
        let binding = Binding(get: { text }, set: { text = $0 })

        let correctView = ReflexTypingModeView(
            word: item,
            isReviewed: true,
            isResultCorrect: true,
            isResultTimeout: false,
            typingText: binding,
            userSubmittedText: "habit"
        )
        #expect(correctView.isReviewed == true)
        #expect(correctView.isResultCorrect == true)
        #expect(correctView.userSubmittedText == "habit")

        let incorrectView = ReflexTypingModeView(
            word: item,
            isReviewed: true,
            isResultCorrect: false,
            isResultTimeout: false,
            typingText: binding,
            userSubmittedText: "habitt"
        )
        #expect(incorrectView.isReviewed == true)
        #expect(incorrectView.isResultCorrect == false)
        #expect(incorrectView.userSubmittedText == "habitt")

        let timeoutView = ReflexTypingModeView(
            word: item,
            isReviewed: true,
            isResultCorrect: false,
            isResultTimeout: true,
            typingText: binding,
            userSubmittedText: nil
        )
        #expect(timeoutView.isReviewed == true)
        #expect(timeoutView.isResultTimeout == true)
        #expect(timeoutView.userSubmittedText == nil)
    }

    @Test("ReflexTypingModeView front face cloze parts and hint stage slots")
    func testTypingModeClozeStages() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let stageSet = ReflexHintMaskGenerator.generateStages(
            lemma: item.lemma,
            sentenceEn: item.clozeSentenceEn,
            pos: item.cleanPos
        )
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        // Stage 0: Initial length mask slot
        let stage0View = ReflexTypingModeView(
            word: item,
            hintStage: 0,
            typingText: binding,
            clozeStages: stageSet
        )
        #expect(stage0View.activeClozeParts?.slot == stageSet.initialParts.slot)

        // Stage 1: Length mask slot
        let stage1View = ReflexTypingModeView(
            word: item,
            hintStage: 1,
            typingText: binding,
            clozeStages: stageSet
        )
        #expect(stage1View.activeClozeParts?.slot == stageSet.lengthMaskedParts.slot)

        // Stage 2: Pattern revealed slot
        let stage2View = ReflexTypingModeView(
            word: item,
            hintStage: 2,
            typingText: binding,
            clozeStages: stageSet
        )
        #expect(stage2View.activeClozeParts?.slot == stageSet.patternRevealedParts.slot)
    }

    @Test("Instantiates ListeningModeView with 3D Flip Card, auto-play, hint stages, and reviewed states")
    func testListeningModeViewFullStates() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let correctOpt = ReflexBlitzOption(id: "opt-1", text: "thói quen", isCorrect: true)
        let wrongOpt = ReflexBlitzOption(id: "opt-2", text: "cải thiện", isCorrect: false)
        let otherOpt = ReflexBlitzOption(id: "opt-3", text: "tập trung", isCorrect: false)
        let options = [correctOpt, wrongOpt, otherOpt]

        var audioPlayed = false
        var audioReplayed = false
        var selectedOption: ReflexBlitzOption?

        // 1. Active Stage 0
        let activeStage0 = ReflexListeningModeView(
            word: item,
            options: options,
            isReviewed: false,
            hintStage: 0,
            eliminatedOptionId: nil,
            onSelectOption: { selectedOption = $0 },
            onPlayAudio: { audioPlayed = true },
            onReplayAudio: { audioReplayed = true }
        )
        #expect(activeStage0.isReviewed == false)
        #expect(activeStage0.choiceState(for: correctOpt) == .idle)
        #expect(activeStage0.choiceState(for: wrongOpt) == .idle)
        #expect(activeStage0.choiceState(for: otherOpt) == .idle)
        activeStage0.onPlayAudio?()
        #expect(audioPlayed == true)
        activeStage0.onReplayAudio?()
        #expect(audioReplayed == true)
        activeStage0.onSelectOption?(correctOpt)
        #expect(selectedOption?.id == "opt-1")

        // 2. Active Stage 1 (POS hint stage, distractor NOT eliminated yet)
        let activeStage1 = ReflexListeningModeView(
            word: item,
            options: options,
            isReviewed: false,
            hintStage: 1,
            eliminatedOptionId: "opt-2"
        )
        #expect(activeStage1.choiceState(for: correctOpt) == .idle)
        #expect(activeStage1.choiceState(for: wrongOpt) == .idle)
        #expect(activeStage1.choiceState(for: otherOpt) == .idle)

        // 3. Active Stage 2 (Distractor eliminated)
        let activeStage2 = ReflexListeningModeView(
            word: item,
            options: options,
            isReviewed: false,
            hintStage: 2,
            eliminatedOptionId: "opt-2"
        )
        #expect(activeStage2.choiceState(for: correctOpt) == .idle)
        #expect(activeStage2.choiceState(for: wrongOpt) == .disabled)
        #expect(activeStage2.choiceState(for: otherOpt) == .idle)

        // 4. Reviewed Correct
        let reviewedCorrect = ReflexListeningModeView(
            word: item,
            options: options,
            isReviewed: true,
            isResultCorrect: true,
            isResultTimeout: false,
            selectedOptionText: "thói quen"
        )
        #expect(reviewedCorrect.isReviewed == true)
        #expect(reviewedCorrect.choiceState(for: correctOpt) == .correct)
        #expect(reviewedCorrect.choiceState(for: wrongOpt) == .disabled)
        #expect(reviewedCorrect.choiceState(for: otherOpt) == .disabled)

        // 5. Reviewed Wrong
        let reviewedWrong = ReflexListeningModeView(
            word: item,
            options: options,
            isReviewed: true,
            isResultCorrect: false,
            isResultTimeout: false,
            selectedOptionText: "cải thiện"
        )
        #expect(reviewedWrong.isReviewed == true)
        #expect(reviewedWrong.choiceState(for: correctOpt) == .correct)
        #expect(reviewedWrong.choiceState(for: wrongOpt) == .wrong)
        #expect(reviewedWrong.choiceState(for: otherOpt) == .disabled)

        // 6. Reviewed Timeout
        let reviewedTimeout = ReflexListeningModeView(
            word: item,
            options: options,
            isReviewed: true,
            isResultCorrect: false,
            isResultTimeout: true,
            selectedOptionText: nil,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
            displayedSentence: item.completedSentenceWithTargetWord
        )
        #expect(reviewedTimeout.isReviewed == true)
        #expect(reviewedTimeout.isResultTimeout == true)
        #expect(reviewedTimeout.choiceState(for: correctOpt) == .correct)
        #expect(reviewedTimeout.choiceState(for: wrongOpt) == .disabled)
        #expect(reviewedTimeout.choiceState(for: otherOpt) == .disabled)
        _ = reviewedTimeout.body

        // 7. Reviewed with clozeParts highlighting
        let reviewedWithHighlight = ReflexListeningModeView(
            word: item,
            options: options,
            isReviewed: true,
            isResultCorrect: true,
            selectedOptionText: "thói quen",
            clozeParts: ClozeSentenceParts(prefix: "Reading is a ", slot: "habit", suffix: "."),
            displayedSentence: "Reading is a habit."
        )
        #expect(reviewedWithHighlight.isReviewed == true)
        #expect(reviewedWithHighlight.isResultCorrect == true)
        #expect(reviewedWithHighlight.clozeParts?.slot == "habit")
        _ = reviewedWithHighlight.body
    }

    @Test("ReflexClozeFormatter extractClozeOrLemmaParts bóc tách chuẩn xác từ mục tiêu từ cả câu thô lẫn câu cloze")
    func testReflexClozeFormatterExtraction() {
        // 1. Template blank
        let templateSentence = "He felt [ _________ ] by the workload."
        let partsFromTemplate = ReflexClozeFormatter.extractClozeOrLemmaParts(sentenceEn: templateSentence, lemma: "overwhelmed")
        #expect(partsFromTemplate != nil)
        #expect(partsFromTemplate?.prefix == "He felt ")
        #expect(partsFromTemplate?.slot == "[ _________ ]")
        #expect(partsFromTemplate?.suffix == " by the workload.")

        // 2. Full sentence with exact lemma
        let fullSentence = "He felt overwhelmed by the workload."
        let partsFromFull = ReflexClozeFormatter.extractClozeOrLemmaParts(sentenceEn: fullSentence, lemma: "overwhelmed")
        #expect(partsFromFull != nil)
        #expect(partsFromFull?.prefix == "He felt ")
        #expect(partsFromFull?.slot == "overwhelmed")
        #expect(partsFromFull?.suffix == " by the workload.")

        // 3. Full sentence with inflected lemma (e.g. lemma "overwhelm" in "He felt overwhelmed by the workload.")
        let partsFromInflected = ReflexClozeFormatter.extractClozeOrLemmaParts(sentenceEn: fullSentence, lemma: "overwhelm")
        #expect(partsFromInflected != nil)
        #expect(partsFromInflected?.prefix == "He felt ")
        #expect(partsFromInflected?.slot == "overwhelmed")
        #expect(partsFromInflected?.suffix == " by the workload.")

        // 4. VaultWordItem clozeSentenceEn creates cloze format
        let vaultWord = VaultWordItem(
            id: 99,
            lemma: "overwhelmed",
            pos: "adj.",
            definitionVi: "Bị ngợp",
            exampleSentenceEn: "He felt overwhelmed by the workload."
        )
        #expect(vaultWord.clozeSentenceEn.contains("[ _________ ]"))
        #expect(vaultWord.clozeSentenceEn == "He felt [ _________ ] by the workload.")
    }

    @Test("ReflexMultipleChoiceModeView render thẻ củng cố với câu ví dụ chỉ highlight từ mục tiêu")
    @MainActor
    func testReflexMultipleChoiceModeViewHighlighting() {
        let vaultWord = VaultWordItem(
            id: 99,
            lemma: "overwhelmed",
            pos: "adj.",
            definitionVi: "Bị ngợp",
            exampleSentenceEn: "He felt overwhelmed by the workload.",
            exampleSentenceVi: "Anh ấy cảm thấy quá tải."
        )
        let item = MixedReflexDrillItem(word: vaultWord, assignedMode: .multipleChoice, isRetry: false)
        let options = [
            ReflexBlitzOption(id: "1", text: "overwhelmed", isCorrect: true),
            ReflexBlitzOption(id: "2", text: "delegation", isCorrect: false)
        ]

        let mcView = ReflexMultipleChoiceModeView(
            word: item,
            options: options,
            isReviewed: true,
            isResultCorrect: true,
            isResultTimeout: false,
            showHint: false,
            hintStage: 0,
            selectedOptionText: "overwhelmed",
            clozeParts: nil,
            displayedSentence: item.completedSentenceWithTargetWord,
            cardBorderColor: .clear
        )

        #expect(mcView.isReviewed == true)
        #expect(mcView.isResultCorrect == true)
        _ = mcView.body
    }
}
#endif
