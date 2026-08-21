import SwiftUI
@testable import VocabCraftApp
import XCTest

final class QuickReflexDrillSheetViewTests: XCTestCase {
    func testRecallWordPhaseConfigurationHidesLemmaAndSupportsTypingFallback() {
        let configuration = QuickReflexDrillPhaseConfiguration(
            phase: .recallWord,
            inputMode: .typing
        )

        XCTAssertTrue(configuration.hidesLemma)
        XCTAssertTrue(configuration.showsTypingFallback)
        XCTAssertEqual(configuration.stageNumber, 1)
    }

    func testRecallCollocationPhaseConfigurationShowsLemmaAndReportsStage2() {
        let configuration = QuickReflexDrillPhaseConfiguration(
            phase: .recallCollocation,
            inputMode: .voice
        )

        XCTAssertFalse(configuration.hidesLemma)
        XCTAssertFalse(configuration.showsTypingFallback)
        XCTAssertEqual(configuration.stageNumber, 2)
    }

    func testProduceSentenceAndShadowModelPhaseConfigurationReportsStage3() {
        let produceConfig = QuickReflexDrillPhaseConfiguration(
            phase: .produceSentence,
            inputMode: .voice
        )
        XCTAssertFalse(produceConfig.hidesLemma)
        XCTAssertEqual(produceConfig.stageNumber, 3)

        let shadowConfig = QuickReflexDrillPhaseConfiguration(
            phase: .shadowModel,
            inputMode: .voice
        )
        XCTAssertFalse(shadowConfig.hidesLemma)
        XCTAssertEqual(shadowConfig.stageNumber, 3)
    }

    func test3TierTimeComparisonReportsDeltasForEachStage() {
        let comparison = QuickReflexTimeComparison(
            currentRecallWordTimeMs: 1_200,
            previousRecallWordTimeMs: 1_700,
            currentCollocationTimeMs: 1_500,
            previousCollocationTimeMs: 1_500,
            currentProduceSentenceTimeMs: 2_800,
            previousProduceSentenceTimeMs: 2_000
        )

        XCTAssertEqual(comparison.recallWordDelta, .saved(milliseconds: 500))
        XCTAssertEqual(comparison.collocationDelta, .unchanged)
        XCTAssertEqual(comparison.produceSentenceDelta, .slower(milliseconds: 800))

        // Backward-compatibility properties
        XCTAssertEqual(comparison.retrieveDelta, .saved(milliseconds: 500))
        XCTAssertEqual(comparison.useDelta, .slower(milliseconds: 800))
    }

    func testLegacy2TierTimeComparisonInitializerCompatibility() {
        let comparison = QuickReflexTimeComparison(
            currentRetrieveTimeMs: 1_000,
            previousRetrieveTimeMs: 1_500,
            currentUseTimeMs: 2_500,
            previousUseTimeMs: 2_000
        )

        XCTAssertEqual(comparison.recallWordDelta, .saved(milliseconds: 500))
        XCTAssertEqual(comparison.collocationDelta, .unchanged)
        XCTAssertEqual(comparison.produceSentenceDelta, .slower(milliseconds: 500))
    }

    func testAppStringsReflex3TierLocalizationKeys() {
        let segment1 = AppStrings.Reflex.quickProgressSegment(1)
        XCTAssertFalse(segment1.isEmpty)
        XCTAssertTrue(segment1.contains("1") && segment1.contains("3"))

        let shadowScore = AppStrings.Reflex.quickShadowScoreLabel(88)
        XCTAssertFalse(shadowScore.isEmpty)
        XCTAssertTrue(shadowScore.contains("88%"))

        let saved = AppStrings.Reflex.quickTimeSaved("0.5s")
        let slower = AppStrings.Reflex.quickTimeSlower("0.8s")
        XCTAssertTrue(saved.contains("0.5s"))
        XCTAssertTrue(slower.contains("0.8s"))
        XCTAssertFalse(saved.contains("%@"))
        XCTAssertFalse(slower.contains("%@"))
    }

    @MainActor
    func testQuickReflexDrillSheetViewInitialization() {
        let word = WordItem(
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
        let view = QuickReflexDrillSheetView(
            targetWord: word,
            allWords: [word],
            onComplete: { _ in }
        )
        XCTAssertNotNil(view)

        let mockSpeechAssessment = MockSpeechAssessmentServiceForViewModel()
        let viewWithSpeechKit = QuickReflexDrillSheetView(
            targetWord: word,
            allWords: [word],
            speechAssessmentService: mockSpeechAssessment,
            onComplete: { _ in }
        )
        XCTAssertNotNil(viewWithSpeechKit)

        let viewWithAttemptRepository = QuickReflexDrillSheetView(
            targetWord: word,
            allWords: [word],
            attemptRepository: SheetAttemptRepository(),
            onComplete: { _ in }
        )
        XCTAssertNotNil(viewWithAttemptRepository)
    }
}

private final class SheetAttemptRepository: QuickReflexAttemptRepositoryProtocol {
    func save(_: QuickReflexAttempt) async throws {}

    func mostRecentSuccessfulAttempt(for _: Int64) async throws -> QuickReflexAttempt? {
        nil
    }
}
