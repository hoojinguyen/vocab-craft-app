import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class VocabularyDomainEntitiesTests: XCTestCase {
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
}
