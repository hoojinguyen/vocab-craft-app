import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class VocabularyModelsTests: XCTestCase {
    func testVaultWordItemInitialization() {
        let item = VaultWordItem(
            id: 101,
            lemma: "Ephemeral",
            pos: "adj.",
            phonetic: "/ɪˈfem.ər.əl/",
            definitionVi: "Phù du, chóng phai",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Sự nổi tiếng của cô ấy tỏ ra rất ngắn ngủi.",
            cefrLevel: "B2",
            isMastered: true,
            isBookmarked: false,
            correctStreak: 4
        )
        XCTAssertEqual(item.id, 101)
        XCTAssertEqual(item.lemma, "Ephemeral")
        XCTAssertEqual(item.pos, "adj.")
        XCTAssertEqual(item.cefrLevel, "B2")
        XCTAssertEqual(item.correctStreak, 4)
        XCTAssertTrue(item.isMastered)
        XCTAssertFalse(item.isBookmarked)
        XCTAssertEqual(item.ipa, "/ɪˈfem.ər.əl/")
    }
}
