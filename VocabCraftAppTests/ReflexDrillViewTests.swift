import SwiftUI
@testable import VocabCraftApp
import XCTest

@MainActor
final class ReflexDrillViewTests: XCTestCase {
    func testReflexDrillViewInitializationWithoutEngine() {
        let vm = ReflexDrillViewModel(
            fetchVocabularyUseCase: MockFetchVocabularyUseCase(),
            evaluateSRSUseCase: MockEvaluateSRSUseCase(),
            ttsService: MockTextToSpeechService(),
            sttService: MockSpeechRecognitionService(),
            cefrLevel: "B1"
        )
        let view = ReflexDrillView(viewModel: vm)
        XCTAssertNotNil(view)
    }

    func testReflexDrillViewInitializationWithCEFRLevel() {
        let vm = ReflexDrillViewModel(
            fetchVocabularyUseCase: MockFetchVocabularyUseCase(),
            evaluateSRSUseCase: MockEvaluateSRSUseCase(),
            ttsService: MockTextToSpeechService(),
            sttService: MockSpeechRecognitionService(),
            cefrLevel: "C1"
        )
        let view = ReflexDrillView(viewModel: vm)
        XCTAssertNotNil(view)
    }

    func testSRSSparkleEffectViewInstantiation() {
        var isEmitting = true
        let binding = Binding(get: { isEmitting }, set: { isEmitting = $0 })
        let view = SRSSparkleEffectView(isEmitting: binding)
        XCTAssertNotNil(view)
    }
}
