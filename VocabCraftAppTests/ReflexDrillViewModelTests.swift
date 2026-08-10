import XCTest
@testable import VocabCraftApp

@MainActor
final class ReflexDrillViewModelTests: XCTestCase {
    func testReflexDrillViewModelInitializationAndSampleDrill() {
        let viewModel = ReflexDrillViewModel(cefrLevel: "B1")
        viewModel.setupSampleDrill()
        
        XCTAssertNotNil(viewModel.state.drill)
        XCTAssertEqual(viewModel.state.drill?.promptText, "Một chú chó đen nhảy qua rào")
    }

    func testEvaluateAnswerCorrectIncreasesMastery() {
        let viewModel = ReflexDrillViewModel(cefrLevel: "B1")
        viewModel.setupSampleDrill()
        viewModel.startDrillTimer()
        
        viewModel.evaluateAnswer("A black dog jumps over the fence")
        
        XCTAssertTrue(viewModel.state.isEvaluated)
        XCTAssertEqual(viewModel.state.currentMastery, 1)
        XCTAssertTrue(viewModel.state.triggerSparkle)
    }

    func testEvaluateAnswerIncorrectResetsMastery() {
        let viewModel = ReflexDrillViewModel(cefrLevel: "B1")
        viewModel.setupSampleDrill()
        viewModel.startDrillTimer()
        
        viewModel.evaluateAnswer("Wrong response")
        
        XCTAssertTrue(viewModel.state.isEvaluated)
        XCTAssertEqual(viewModel.state.currentMastery, 0)
        XCTAssertFalse(viewModel.state.triggerSparkle)
    }

    func testStartVoiceRecognitionDoesNotAutoEvaluateOnPartialResult() {
        let viewModel = ReflexDrillViewModel(cefrLevel: "B1")
        viewModel.setupSampleDrill()
        viewModel.startVoiceRecognition()
        
        // On simulator, startVoiceRecognition initiates simulationTask.
        // Immediately after start, before complete answer is simulated, it should not be evaluated.
        XCTAssertFalse(viewModel.state.isEvaluated)
    }
}
