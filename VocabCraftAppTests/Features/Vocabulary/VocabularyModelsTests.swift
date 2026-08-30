import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class VocabularyModelsTests: XCTestCase {
    func testWordItemInitializationAndMockData() {
        let item = WordItem(
            id: 101,
            lemma: "Ephemeral",
            phonetic: "/ɪˈfem.ər.əl/",
            pos: "adj.",
            definition: "Phù du, chóng phai",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Sự nổi tiếng của cô ấy tỏ ra rất ngắn ngủi.",
            cefrLevel: "B2",
            masteryLevel: 4,
            nextReviewDate: Date()
        )
        XCTAssertEqual(item.id, 101)
        XCTAssertEqual(item.lemma, "Ephemeral")
        XCTAssertEqual(item.cefrLevel, "B2")
        XCTAssertEqual(item.masteryLevel, 4)
        XCTAssertFalse(WordItem.mockData.isEmpty)
    }
}
