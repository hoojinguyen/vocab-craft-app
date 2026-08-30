import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class VocabularyDomainEntitiesTests: XCTestCase {
    func test_subTopicStage_stateTransitions() {
        let stage = SubTopicStage(
            id: "stage_daily_1",
            deckId: "deck_daily",
            title: "Chặng 1: Thói quen",
            iconName: "heart",
            sortOrder: 1,
            state: .active,
            words: []
        )
        XCTAssertEqual(stage.state, .active)
        XCTAssertEqual(stage.id, "stage_daily_1")
        XCTAssertEqual(stage.deckId, "deck_daily")
        XCTAssertEqual(stage.title, "Chặng 1: Thói quen")
        XCTAssertEqual(stage.iconName, "heart")
        XCTAssertEqual(stage.sortOrder, 1)
        XCTAssertTrue(stage.words.isEmpty)
    }

    func test_personalWord_needsReviewComputedProperly() {
        let word = PersonalWord(
            id: 1,
            lemma: "Resilience",
            phonetic: "/rɪˈzɪl.jəns/",
            pos: "noun",
            cefrLevel: "B2",
            definitionVi: "Khả năng phục hồi",
            definitionEn: "Capacity to recover",
            exampleEn: "Her resilience helped her.",
            exampleVi: "Sự kiên cường giúp cô ấy.",
            masteryLevel: 2,
            isBookmarked: true,
            needsReview: true,
            mistakeCount: 1,
            sourceDeckTitle: "Giao Tiếp Hằng Ngày",
            sourceStageTitle: "Chặng 1: Thói quen"
        )
        XCTAssertEqual(word.id, 1)
        XCTAssertEqual(word.lemma, "Resilience")
        XCTAssertEqual(word.phonetic, "/rɪˈzɪl.jəns/")
        XCTAssertEqual(word.pos, "noun")
        XCTAssertEqual(word.cefrLevel, "B2")
        XCTAssertEqual(word.definitionVi, "Khả năng phục hồi")
        XCTAssertEqual(word.definitionEn, "Capacity to recover")
        XCTAssertEqual(word.exampleEn, "Her resilience helped her.")
        XCTAssertEqual(word.exampleVi, "Sự kiên cường giúp cô ấy.")
        XCTAssertEqual(word.masteryLevel, 2)
        XCTAssertTrue(word.isBookmarked)
        XCTAssertTrue(word.needsReview)
        XCTAssertEqual(word.mistakeCount, 1)
        XCTAssertEqual(word.sourceDeckTitle, "Giao Tiếp Hằng Ngày")
        XCTAssertEqual(word.sourceStageTitle, "Chặng 1: Thói quen")
    }

    func test_stageChallenge_entities() {
        let question = WordChallengeQuestion(
            id: "q1",
            wordId: 1,
            prompt: "Khả năng phục hồi",
            hintPhonetic: "/rɪˈzɪl.jəns/",
            correctAnswer: "Resilience",
            options: ["Resilience", "Overwhelmed", "Gratitude", "Empathy"],
            exampleSentence: "Her ___ helped her overcome difficulties."
        )
        XCTAssertEqual(question.id, "q1")
        XCTAssertEqual(question.wordId, 1)
        XCTAssertEqual(question.prompt, "Khả năng phục hồi")
        XCTAssertEqual(question.hintPhonetic, "/rɪˈzɪl.jəns/")
        XCTAssertEqual(question.correctAnswer, "Resilience")
        XCTAssertEqual(question.options, ["Resilience", "Overwhelmed", "Gratitude", "Empathy"])
        XCTAssertEqual(question.exampleSentence, "Her ___ helped her overcome difficulties.")

        let result = WordChallengeResult(wordId: 1, isCorrect: true, timeTakenMs: 1500)
        XCTAssertEqual(result.wordId, 1)
        XCTAssertTrue(result.isCorrect)
        XCTAssertEqual(result.timeTakenMs, 1500)

        let summary = StageCompletionSummary(
            stageId: "stage_daily_1",
            totalQuestions: 7,
            correctCount: 6,
            xpEarned: 60,
            weakWordIds: [2]
        )
        XCTAssertEqual(summary.stageId, "stage_daily_1")
        XCTAssertEqual(summary.totalQuestions, 7)
        XCTAssertEqual(summary.correctCount, 6)
        XCTAssertEqual(summary.xpEarned, 60)
        XCTAssertEqual(summary.weakWordIds, [2])
    }
}
