import SwiftUI
@testable import VocabCraftApp
import XCTest

final class QuickReflexDrillSheetViewTests: XCTestCase {
    func testRetrievePhaseConfigurationHidesLemmaAndSupportsTypingFallback() {
        let configuration = QuickReflexDrillPhaseConfiguration(
            phase: .retrieve,
            inputMode: .typing
        )

        XCTAssertTrue(configuration.hidesLemma)
        XCTAssertTrue(configuration.showsTypingFallback)
        XCTAssertEqual(configuration.stageNumber, 1)
    }

    func testUsePhaseConfigurationShowsLemmaAndSupportsVoiceInput() {
        let configuration = QuickReflexDrillPhaseConfiguration(
            phase: .useInSentence,
            inputMode: .voice
        )

        XCTAssertFalse(configuration.hidesLemma)
        XCTAssertFalse(configuration.showsTypingFallback)
        XCTAssertEqual(configuration.stageNumber, 2)
    }

    func testTimeComparisonReportsSavingsAndSlowerDeltasForEachStage() {
        let comparison = QuickReflexTimeComparison(
            currentRetrieveTimeMs: 1_200,
            previousRetrieveTimeMs: 1_700,
            currentUseTimeMs: 2_800,
            previousUseTimeMs: 2_000
        )

        XCTAssertEqual(comparison.retrieveDelta, .saved(milliseconds: 500))
        XCTAssertEqual(comparison.useDelta, .slower(milliseconds: 800))
    }

    func testTimeDeltaStringsUseStaticLocalizedFormats() {
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
