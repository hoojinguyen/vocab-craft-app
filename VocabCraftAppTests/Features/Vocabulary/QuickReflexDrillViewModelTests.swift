@testable import VocabCraftApp
import XCTest

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
        let steps = viewModel.state.steps
        XCTAssertEqual(steps.count, 3)
        XCTAssertEqual(steps[0].type, .fastMeaning)
        XCTAssertEqual(steps[1].type, .fillInBlank)
        XCTAssertEqual(steps[2].type, .pronunciation)
        XCTAssertTrue(steps[0].options.contains("Phù du, chóng phai"))
    }

    @MainActor
    func testTapToTalkRecordingAndEvaluation() {
        let mockSTT = MockSpeechRecognitionService()
        let viewModel = QuickReflexDrillViewModel(targetWord: targetWord, allWords: samplePool, sttService: mockSTT)
        viewModel.state.currentStepIndex = 2 // Step 3: Pronunciation

        // Tap 1: Start listening
        viewModel.handleMicTap()
        XCTAssertTrue(viewModel.isListening)

        // Simulated speech stream
        mockSTT.simulateResult("Her fame proved to be ephemeral.")

        if !viewModel.state.isStepEvaluated {
            viewModel.handleMicTap()
        }
        XCTAssertFalse(viewModel.isListening)
        XCTAssertTrue(viewModel.state.isStepEvaluated)
        XCTAssertTrue(viewModel.state.isStepCorrect)
    }

    @MainActor
    func testOptionSubmissionAndNextStep() {
        let viewModel = QuickReflexDrillViewModel(targetWord: targetWord, allWords: samplePool)
        viewModel.state.currentStepIndex = 0 // Step 1: Fast Meaning Options

        viewModel.submitAnswer("Phù du, chóng phai")
        XCTAssertTrue(viewModel.state.isStepEvaluated)
        XCTAssertTrue(viewModel.state.isStepCorrect)
        XCTAssertEqual(viewModel.state.selectedOption, "Phù du, chóng phai")

        viewModel.nextStep()
        XCTAssertEqual(viewModel.state.currentStepIndex, 1)
        XCTAssertFalse(viewModel.state.isStepEvaluated)
    }
}
