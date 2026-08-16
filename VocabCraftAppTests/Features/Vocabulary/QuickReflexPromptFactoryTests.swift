import XCTest
@testable import VocabCraftApp

final class QuickReflexPromptFactoryTests: XCTestCase {
    func testMakePromptsUsesDefinitionAndRetrieveHints() {
        let word = makeWord(
            lemma: "resilience",
            pos: "noun",
            definition: "Khả năng phục hồi",
            exampleSentenceVi: "Sự kiên cường giúp cô ấy vượt qua khó khăn."
        )

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(prompts.retrieve.phase, .retrieve)
        XCTAssertEqual(prompts.retrieve.promptText, "Khả năng phục hồi")
        XCTAssertEqual(prompts.retrieve.targetExpression, "resilience")
        XCTAssertEqual(prompts.retrieve.hints, ["noun", "r"])
    }

    func testMakePromptsUsesVietnameseExampleAndLemmaUseHint() {
        let word = makeWord(
            lemma: "resilience",
            pos: "noun",
            definition: "Khả năng phục hồi",
            exampleSentenceVi: "Sự kiên cường giúp cô ấy vượt qua khó khăn."
        )

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(prompts.use.phase, .useInSentence)
        XCTAssertEqual(prompts.use.promptText, "Sự kiên cường giúp cô ấy vượt qua khó khăn.")
        XCTAssertEqual(prompts.use.targetExpression, "resilience")
        XCTAssertTrue(prompts.use.hints.isEmpty)
    }

    func testMakePromptsAddsAPartOfSpeechSentenceFrameForUseStage() {
        let noun = makeWord(lemma: "resilience", pos: "noun", definition: "Khả năng phục hồi", exampleSentenceVi: "")
        let verb = makeWord(lemma: "adapt", pos: "verb", definition: "Thích nghi", exampleSentenceVi: "")

        let nounFrame = QuickReflexPromptFactory().makePrompts(for: noun).use.sentenceFrame
        let verbFrame = QuickReflexPromptFactory().makePrompts(for: verb).use.sentenceFrame

        XCTAssertNotNil(nounFrame)
        XCTAssertNotNil(verbFrame)
        XCTAssertNotEqual(nounFrame, verbFrame)
    }

    func testMakePromptsFallsBackWhenVietnameseExampleIsEmpty() {
        let word = makeWord(lemma: "break the ice", pos: "phrase", definition: "Bắt chuyện", exampleSentenceVi: "")

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(prompts.use.promptText, AppStrings.Reflex.quickUsePrompt("break the ice"))
    }

    private func makeWord(
        lemma: String,
        pos: String,
        definition: String,
        exampleSentenceVi: String
    ) -> WordItem {
        WordItem(
            id: 1,
            lemma: lemma,
            phonetic: "",
            pos: pos,
            definition: definition,
            exampleSentenceEn: "",
            exampleSentenceVi: exampleSentenceVi,
            cefrLevel: "B1",
            masteryLevel: 0
        )
    }
}
