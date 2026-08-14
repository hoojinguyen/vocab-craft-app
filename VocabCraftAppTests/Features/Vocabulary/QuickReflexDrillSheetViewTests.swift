import SwiftUI
@testable import VocabCraftApp
import XCTest

final class QuickReflexDrillSheetViewTests: XCTestCase {
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
    }
}
