import XCTest
@testable import VocabCraftApp

final class CollocationExtractorTests: XCTestCase {
    func testExtractUsesExplicitCollocationWhenAvailable() {
        let word = WordItem(
            id: 1,
            lemma: "Ephemeral",
            phonetic: "/ɪˈfem.ər.əl/",
            pos: "adj.",
            definition: "Phù du",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Danh tiếng ngắn ngủi",
            cefrLevel: "B2",
            masteryLevel: 3,
            collocationEn: "ephemeral fame"
        )
        let collocation = CollocationExtractor.extract(for: word)
        XCTAssertEqual(collocation, "ephemeral fame")
    }

    func testExtractFromExampleSentenceWhenExplicitCollocationMissing() {
        let word = WordItem(
            id: 2,
            lemma: "Resilience",
            phonetic: "/rɪˈzɪl.jəns/",
            pos: "n.",
            definition: "Kiên cường",
            exampleSentenceEn: "Courage and resilience are essential for victory.",
            exampleSentenceVi: "Kiên cường",
            cefrLevel: "C1",
            masteryLevel: 4
        )
        let collocation = CollocationExtractor.extract(for: word)
        XCTAssertFalse(collocation.isEmpty)
        XCTAssertTrue(collocation.lowercased().contains("resilience"))
    }

    func testExtractFallbackByPartOfSpeech() {
        let word = WordItem(
            id: 3,
            lemma: "innovate",
            phonetic: "/ˈɪn.ə.veɪt/",
            pos: "v.",
            definition: "Đổi mới",
            exampleSentenceEn: "",
            exampleSentenceVi: "",
            cefrLevel: "B2",
            masteryLevel: 1
        )
        let collocation = CollocationExtractor.extract(for: word)
        XCTAssertEqual(collocation, "to innovate actively")
    }

    func testExtractFallbackForNoun() {
        let word = WordItem(
            id: 4,
            lemma: "decision",
            phonetic: "",
            pos: "noun",
            definition: "Quyết định",
            exampleSentenceEn: "",
            exampleSentenceVi: "",
            cefrLevel: "B1",
            masteryLevel: 1
        )
        let collocation = CollocationExtractor.extract(for: word)
        XCTAssertEqual(collocation, "great decision")
    }

    func testExtractFallbackForAdjective() {
        let word = WordItem(
            id: 5,
            lemma: "challenging",
            phonetic: "",
            pos: "adjective",
            definition: "Thách thức",
            exampleSentenceEn: "",
            exampleSentenceVi: "",
            cefrLevel: "B2",
            masteryLevel: 1
        )
        let collocation = CollocationExtractor.extract(for: word)
        XCTAssertEqual(collocation, "challenging situation")
    }

    func testExtractFallbackForOtherPartOfSpeech() {
        let word = WordItem(
            id: 6,
            lemma: "smoothly",
            phonetic: "",
            pos: "adverb",
            definition: "Mượt mà",
            exampleSentenceEn: "",
            exampleSentenceVi: "",
            cefrLevel: "B2",
            masteryLevel: 1
        )
        let collocation = CollocationExtractor.extract(for: word)
        XCTAssertEqual(collocation, "smoothly in practice")
    }
}
