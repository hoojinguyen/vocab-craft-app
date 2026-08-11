import XCTest
@testable import VocabCraftApp

final class QuickReflexDrillViewModelTests: XCTestCase {
    var targetWord: WordItem!
    var samplePool: [WordItem]!

    override func setUp() {
        super.setUp()
        targetWord = WordItem(
            id: 1,
            lemma: "Ephemeral",
            phonetic: "/'fem.ər.əl/",
            pos: "adj.",
            definition: "Phù du, chóng phai",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Sự nổi tiếng của cô ấy chỉ kéo dài ngắn ngủi.",
            cefrLevel: "B2",
            masteryLevel: 2
        )
        samplePool = [
            targetWord,
            WordItem(id: 2, lemma: "Resilience", phonetic: "/rɪ'zɪl.jəns/", pos: "n.", definition: "Khả năng phục hồi", exampleSentenceEn: "Test", exampleSentenceVi: "Test", cefrLevel: "C1", masteryLevel: 5),
            WordItem(id: 3, lemma: "Meticulous", phonetic: "/mə'tɪk.jə.ləs/", pos: "adj.", definition: "Tỉ mỉ, cẩn thận", exampleSentenceEn: "Test", exampleSentenceVi: "Test", cefrLevel: "B2", masteryLevel: 1),
            WordItem(id: 4, lemma: "Pragmatic", phonetic: "/præɡ'mæt.ɪk/", pos: "adj.", definition: "Thực tế", exampleSentenceEn: "Test", exampleSentenceVi: "Test", cefrLevel: "C1", masteryLevel: 3)
        ]
    }

    @MainActor
    func testStepGeneration() {
        let viewModel = QuickReflexDrillViewModel(targetWord: targetWord, allWords: samplePool)
        let steps = viewModel.steps
        XCTAssertEqual(steps.count, 3)
        XCTAssertEqual(steps[0].type, .pronunciation)
        XCTAssertEqual(steps[1].type, .fastMeaning)
        XCTAssertEqual(steps[2].type, .fillInBlank)
        XCTAssertTrue(steps[1].options.contains("Phù du, chóng phai"))
    }

    @MainActor
    func testAnswerValidationAndAdvancement() {
        let viewModel = QuickReflexDrillViewModel(targetWord: targetWord, allWords: samplePool)
        
        // Step 1 correct
        viewModel.submitAnswer("Her fame proved to be ephemeral.")
        XCTAssertEqual(viewModel.currentStepIndex, 1)

        // Step 2 correct option
        viewModel.submitAnswer("Phù du, chóng phai")
        XCTAssertEqual(viewModel.currentStepIndex, 2)

        // Step 3 correct lemma
        viewModel.submitAnswer("Ephemeral")
        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertTrue(viewModel.isCorrect)
    }
}
