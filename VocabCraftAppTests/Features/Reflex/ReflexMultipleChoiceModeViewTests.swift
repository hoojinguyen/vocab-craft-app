import CraftUIKit
import Foundation
import SwiftUI
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("ReflexMultipleChoiceModeView Tests")
struct ReflexMultipleChoiceModeViewTests {
    @Test("Instantiates ReflexMultipleChoiceModeView in active and unreviewed state")
    func testMultipleChoiceViewActive() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = [
            ReflexBlitzOption(text: "habit", isCorrect: true),
            ReflexBlitzOption(text: "improve", isCorrect: false)
        ]

        let view = ReflexMultipleChoiceModeView(
            word: item,
            options: options,
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: true,
            hintStage: 1,
            selectedOptionText: nil,
            clozeParts: nil,
            displayedSentence: item.clozeSentenceEn,
            cardBorderColor: .clear,
            eliminatedOptionId: nil,
            onSelectOption: nil,
            onReplayAudio: nil
        )

        #expect(view.options.count == 2)
        #expect(view.isReviewed == false)
        #expect(view.showHint == true)
        #expect(view.hintStage == 1)
        #expect(view.choiceState(for: options[0]) == .idle)
        #expect(view.choiceState(for: options[1]) == .idle)
    }

    @Test("Choice state reflects correct, wrong, and disabled in reviewed mode")
    func testMultipleChoiceViewReviewedState() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let correctOpt = ReflexBlitzOption(id: "opt-1", text: "habit", isCorrect: true)
        let wrongOpt = ReflexBlitzOption(id: "opt-2", text: "improve", isCorrect: false)
        let otherOpt = ReflexBlitzOption(id: "opt-3", text: "focus", isCorrect: false)
        let options = [correctOpt, wrongOpt, otherOpt]

        let view = ReflexMultipleChoiceModeView(
            word: item,
            options: options,
            isReviewed: true,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: true,
            hintStage: 0,
            selectedOptionText: "improve",
            clozeParts: nil,
            displayedSentence: item.completedSentenceWithTargetWord,
            cardBorderColor: .clear,
            eliminatedOptionId: nil,
            onSelectOption: nil,
            onReplayAudio: nil
        )

        #expect(view.isReviewed == true)
        #expect(view.choiceState(for: correctOpt) == .correct)
        #expect(view.choiceState(for: wrongOpt) == .wrong)
        #expect(view.choiceState(for: otherOpt) == .disabled)
    }

    @Test("Stage 3 hint disables eliminated distractor in active mode")
    func testMultipleChoiceViewEliminationHint() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let correctOpt = ReflexBlitzOption(id: "opt-1", text: "habit", isCorrect: true)
        let eliminatedOpt = ReflexBlitzOption(id: "opt-2", text: "improve", isCorrect: false)
        let otherOpt = ReflexBlitzOption(id: "opt-3", text: "focus", isCorrect: false)
        let options = [correctOpt, eliminatedOpt, otherOpt]

        let view = ReflexMultipleChoiceModeView(
            word: item,
            options: options,
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: true,
            hintStage: 3,
            selectedOptionText: nil,
            clozeParts: nil,
            displayedSentence: item.clozeSentenceEn,
            cardBorderColor: .clear,
            eliminatedOptionId: "opt-2",
            onSelectOption: nil,
            onReplayAudio: nil
        )

        #expect(view.choiceState(for: correctOpt) == .idle)
        #expect(view.choiceState(for: eliminatedOpt) == .disabled)
        #expect(view.choiceState(for: otherOpt) == .idle)
    }

    @Test("Progressive cloze stages dynamically update activeClozeParts across stages 0, 1, and 2")
    func testClozeStagesMasking() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0] // "habit"
        let stageSet = ReflexHintMaskGenerator.generateStages(
            lemma: item.lemma,
            sentenceEn: item.clozeSentenceEn,
            pos: item.cleanPos
        )

        let stage0View = ReflexMultipleChoiceModeView(
            word: item,
            options: [],
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: false,
            hintStage: 0,
            selectedOptionText: nil,
            clozeStages: stageSet,
            clozeParts: nil,
            displayedSentence: item.clozeSentenceEn,
            cardBorderColor: .clear
        )
        #expect(stage0View.activeClozeParts?.slot == stageSet.initialParts.slot)

        let stage1View = ReflexMultipleChoiceModeView(
            word: item,
            options: [],
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: true,
            hintStage: 1,
            selectedOptionText: nil,
            clozeStages: stageSet,
            clozeParts: nil,
            displayedSentence: item.clozeSentenceEn,
            cardBorderColor: .clear
        )
        #expect(stage1View.activeClozeParts?.slot == stageSet.lengthMaskedParts.slot)

        let stage2View = ReflexMultipleChoiceModeView(
            word: item,
            options: [],
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: true,
            hintStage: 2,
            selectedOptionText: nil,
            clozeStages: stageSet,
            clozeParts: nil,
            displayedSentence: item.clozeSentenceEn,
            cardBorderColor: .clear
        )
        #expect(stage2View.activeClozeParts?.slot == stageSet.patternRevealedParts.slot)
    }

    @Test("ReflexMultipleChoiceModeView renders cleanly with filled target lemma in reviewed state")
    func testMultipleChoiceReviewedBodyRendering() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0] // "habit"
        let parts = ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn)
        let options = [
            ReflexBlitzOption(text: "habit", isCorrect: true),
            ReflexBlitzOption(text: "improve", isCorrect: false)
        ]

        let view = ReflexMultipleChoiceModeView(
            word: item,
            options: options,
            isReviewed: true,
            isResultCorrect: true,
            isResultTimeout: false,
            showHint: false,
            hintStage: 0,
            selectedOptionText: "habit",
            clozeParts: parts,
            displayedSentence: item.completedSentenceWithTargetWord,
            cardBorderColor: .clear,
            onSelectOption: nil,
            onReplayAudio: nil
        )

        #expect(view.isReviewed == true)
        #expect(view.isResultCorrect == true)
        _ = view.body
    }
}
#endif
