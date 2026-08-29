import Testing
@testable import VocabCraftApp

@Suite("Reflex Drill Plan Models Tests")
struct ReflexDrillPlanModelsTests {
    @Test("ReflexClozeStageSet holds initial, length masked, and pattern revealed parts")
    func testClozeStageSet() {
        let initial = ClozeSentenceParts(prefix: "She has a ", slot: "[ _________ ]", suffix: " of reading.")
        let lengthMasked = ClozeSentenceParts(prefix: "She has a ", slot: "[ _ _ _ _ _ ]", suffix: " of reading.")
        let revealed = ClozeSentenceParts(prefix: "She has a ", slot: "[ h _ _ _ t ]", suffix: " of reading.")
        let stageSet = ReflexClozeStageSet(
            initialParts: initial,
            lengthMaskedParts: lengthMasked,
            patternRevealedParts: revealed,
            maskedWordString: "h _ _ _ t",
            strategy: .prefix(count: 1)
        )
        #expect(stageSet.maskedWordString == "h _ _ _ t")
        #expect(stageSet.strategy == .prefix(count: 1))
        #expect(stageSet.initialParts == initial)
        #expect(stageSet.lengthMaskedParts == lengthMasked)
        #expect(stageSet.patternRevealedParts == revealed)
    }

    @Test("ReflexDrillPlanItem creates immutable blueprint with options and eliminated distractor")
    func testDrillPlanItem() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = [
            ReflexBlitzOption(text: "habit", isCorrect: true),
            ReflexBlitzOption(text: "focus", isCorrect: false),
            ReflexBlitzOption(text: "create", isCorrect: false),
            ReflexBlitzOption(text: "relax", isCorrect: false)
        ]
        let initial = ClozeSentenceParts(prefix: "She has a ", slot: "[ _________ ]", suffix: " of reading.")
        let stageSet = ReflexClozeStageSet(
            initialParts: initial,
            lengthMaskedParts: initial,
            patternRevealedParts: initial,
            maskedWordString: "h _ _ _ t",
            strategy: .prefix(count: 1)
        )
        let item = ReflexDrillPlanItem(
            id: "plan-1",
            word: word,
            assignedMode: .multipleChoice,
            options: options,
            correctOptionIndex: 0,
            eliminatedOptionId: options[1].id,
            clozeStages: stageSet,
            hintBadgeText: "h... • noun"
        )
        #expect(item.id == "plan-1")
        #expect(item.assignedMode == .multipleChoice)
        #expect(item.options.count == 4)
        #expect(item.correctOptionIndex == 0)
        #expect(item.eliminatedOptionId == options[1].id)
        #expect(item.clozeStages == stageSet)
        #expect(item.hintBadgeText == "h... • noun")
        #expect(item.word.lemma == "habit")

        let identicalItem = ReflexDrillPlanItem(
            id: "plan-1",
            word: word,
            assignedMode: .multipleChoice,
            options: options,
            correctOptionIndex: 0,
            eliminatedOptionId: options[1].id,
            clozeStages: stageSet,
            hintBadgeText: "h... • noun"
        )
        #expect(item == identicalItem)
    }

    @Test("ReflexDrillSessionPlan aggregates plan items and exposes convenience properties")
    func testDrillSessionPlan() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = [
            ReflexBlitzOption(text: "habit", isCorrect: true),
            ReflexBlitzOption(text: "focus", isCorrect: false)
        ]
        let initial = ClozeSentenceParts(prefix: "She has a ", slot: "[ _________ ]", suffix: " of reading.")
        let stageSet = ReflexClozeStageSet(
            initialParts: initial,
            lengthMaskedParts: initial,
            patternRevealedParts: initial,
            maskedWordString: "h _ _ _ t",
            strategy: .shortWordPrefix
        )
        let item1 = ReflexDrillPlanItem(
            id: "plan-1",
            word: word,
            assignedMode: .typing,
            options: options,
            correctOptionIndex: 0,
            eliminatedOptionId: nil,
            clozeStages: stageSet,
            hintBadgeText: "h... • noun"
        )

        let sessionPlan = ReflexDrillSessionPlan(
            mode: .typing,
            items: [item1]
        )

        #expect(sessionPlan.mode == .typing)
        #expect(sessionPlan.count == 1)
        #expect(!sessionPlan.isEmpty)
        #expect(sessionPlan.items.first?.id == "plan-1")

        let emptyPlan = ReflexDrillSessionPlan(
            mode: .speaking,
            items: []
        )
        #expect(emptyPlan.isEmpty)
        #expect(emptyPlan.count == 0)
    }
}
