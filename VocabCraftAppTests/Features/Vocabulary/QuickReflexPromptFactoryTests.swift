import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class QuickReflexPromptFactoryTests: XCTestCase {
    func testMakePromptsUsesDefinitionAndRetrieveHintsWhenNoExample() {
        let word = makeWord(
            lemma: "resilience",
            pos: "noun",
            definition: "Khả năng phục hồi",
            exampleSentenceVi: "Sự kiên cường giúp cô ấy vượt qua khó khăn."
        )

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(prompts.recallWord.phase, .recallWord)
        XCTAssertEqual(prompts.recallWord.promptText, "Khả năng phục hồi")
        XCTAssertEqual(prompts.recallWord.targetExpression, "resilience")
        XCTAssertEqual(prompts.recallWord.hints, ["noun", "r"])
    }

    func testMakePromptsCreatesClozePromptWhenEnglishExampleAvailable() {
        let word = WordItem(
            id: 1,
            lemma: "ephemeral",
            phonetic: "",
            pos: "adj.",
            definition: "Phù du",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Danh tiếng ngắn ngủi.",
            cefrLevel: "B2",
            masteryLevel: 1
        )

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(prompts.recallWord.phase, .recallWord)
        XCTAssertEqual(prompts.recallWord.promptText, "Her fame proved to be [ ______ ].")
        XCTAssertEqual(prompts.recallWord.targetExpression, "ephemeral")
    }

    func testMakePromptsBuildsCollocationStageWithExplicitCollocation() {
        let word = WordItem(
            id: 1,
            lemma: "ephemeral",
            phonetic: "",
            pos: "adj.",
            definition: "Phù du",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Danh tiếng ngắn ngủi.",
            cefrLevel: "B2",
            masteryLevel: 1,
            collocationEn: "ephemeral fame",
            collocationVi: "danh tiếng phù du"
        )

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(prompts.recallCollocation.phase, .recallCollocation)
        XCTAssertEqual(prompts.recallCollocation.targetExpression, "ephemeral fame")
        XCTAssertEqual(prompts.recallCollocation.promptText, "danh tiếng phù du")
    }

    func testMakePromptsBuildsCollocationStageWithExtractedCollocationAndDefinitionFallback() {
        let word = WordItem(
            id: 2,
            lemma: "resilience",
            phonetic: "",
            pos: "noun",
            definition: "Khả năng phục hồi",
            exampleSentenceEn: "Courage and resilience are essential for victory.",
            exampleSentenceVi: "Kiên cường",
            cefrLevel: "C1",
            masteryLevel: 2
        )

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(prompts.recallCollocation.phase, .recallCollocation)
        XCTAssertFalse(prompts.recallCollocation.targetExpression.isEmpty)
        XCTAssertTrue(prompts.recallCollocation.targetExpression.contains("resilience"))
        XCTAssertEqual(prompts.recallCollocation.promptText, "Khả năng phục hồi")
    }

    func testMakePromptsBuildsProduceSentenceAndModelAudio() {
        let word = WordItem(
            id: 1,
            lemma: "resilience",
            phonetic: "",
            pos: "noun",
            definition: "Khả năng phục hồi",
            exampleSentenceEn: "Courage and resilience are essential for victory.",
            exampleSentenceVi: "Lòng dũng cảm và sự kiên cường là cần thiết để chiến thắng.",
            cefrLevel: "C1",
            masteryLevel: 2
        )

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(prompts.produceSentence.phase, .produceSentence)
        XCTAssertEqual(prompts.produceSentence.promptText, "Lòng dũng cảm và sự kiên cường là cần thiết để chiến thắng.")
        XCTAssertEqual(prompts.produceSentence.targetExpression, "resilience")
        XCTAssertEqual(prompts.produceSentence.modelAudioSentenceEn, "Courage and resilience are essential for victory.")
        XCTAssertEqual(prompts.modelSentenceEn, "Courage and resilience are essential for victory.")
    }

    func testMakePromptsUsesVietnameseExampleForProduceSentence() {
        let word = makeWord(
            lemma: "resilience",
            pos: "noun",
            definition: "Khả năng phục hồi",
            exampleSentenceVi: "Sự kiên cường giúp cô ấy vượt qua khó khăn."
        )

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(prompts.produceSentence.phase, .produceSentence)
        XCTAssertEqual(prompts.produceSentence.promptText, "Sự kiên cường giúp cô ấy vượt qua khó khăn.")
        XCTAssertEqual(prompts.produceSentence.targetExpression, "resilience")
        XCTAssertTrue(prompts.produceSentence.hints.isEmpty)
    }

    func testMakePromptsAddsAPartOfSpeechSentenceFrameForProduceStage() {
        let noun = makeWord(lemma: "resilience", pos: "noun", definition: "Khả năng phục hồi", exampleSentenceVi: "")
        let verb = makeWord(lemma: "adapt", pos: "verb", definition: "Thích nghi", exampleSentenceVi: "")
        let adverb = makeWord(lemma: "smoothly", pos: "adverb", definition: "Mượt mà", exampleSentenceVi: "")
        let adjective = makeWord(lemma: "sharp", pos: "adjective", definition: "Sắc bén", exampleSentenceVi: "")
        let idiom = makeWord(lemma: "break ice", pos: "idiom", definition: "Phá vỡ", exampleSentenceVi: "")

        let nounFrame = QuickReflexPromptFactory().makePrompts(for: noun).produceSentence.sentenceFrame
        let verbFrame = QuickReflexPromptFactory().makePrompts(for: verb).produceSentence.sentenceFrame
        let adverbFrame = QuickReflexPromptFactory().makePrompts(for: adverb).produceSentence.sentenceFrame
        let adjectiveFrame = QuickReflexPromptFactory().makePrompts(for: adjective).produceSentence.sentenceFrame
        let idiomFrame = QuickReflexPromptFactory().makePrompts(for: idiom).produceSentence.sentenceFrame

        XCTAssertNotNil(nounFrame)
        XCTAssertNotNil(verbFrame)
        XCTAssertNotNil(adverbFrame)
        XCTAssertNotNil(adjectiveFrame)
        XCTAssertNotNil(idiomFrame)
        XCTAssertNotEqual(nounFrame, verbFrame)
        XCTAssertNotEqual(verbFrame, adverbFrame)
    }

    func testMakePromptsFallsBackWhenVietnameseExampleIsEmpty() {
        let word = makeWord(lemma: "break the ice", pos: "phrase", definition: "Bắt chuyện", exampleSentenceVi: "")

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(prompts.produceSentence.promptText, AppStrings.Reflex.quickUsePrompt("break the ice"))
    }

    func testMakePromptsUsesEnglishExampleWhenVietnameseExampleIsMissing() {
        let word = WordItem(
            id: 1,
            lemma: "resilience",
            phonetic: "",
            pos: "noun",
            definition: "Khả năng phục hồi",
            exampleSentenceEn: "Her resilience helped her recover after the setback.",
            exampleSentenceVi: "",
            cefrLevel: "B1",
            masteryLevel: 0
        )

        let prompts = QuickReflexPromptFactory().makePrompts(for: word)

        XCTAssertEqual(
            prompts.produceSentence.promptText,
            AppStrings.Reflex.quickUsePromptFromExample(word.lemma, word.exampleSentenceEn)
        )
        XCTAssertNotEqual(prompts.produceSentence.promptText, AppStrings.Reflex.quickUsePrompt(word.lemma))
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
