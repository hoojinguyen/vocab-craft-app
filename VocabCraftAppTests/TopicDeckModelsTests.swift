import XCTest
@testable import VocabCraftApp

final class TopicDeckModelsTests: XCTestCase {
    func testSubTopicNodeInitialization() {
        let word = TopicWord(
            id: "w1",
            english: "Algorithm",
            phonetic: "/ˈæl.ɡə.rɪ.ðəm/",
            vietnamese: "Thuật toán",
            isMastered: true,
            isSavedToPersonalVault: true
        )
        let node = SubTopicNode(
            id: "node-1",
            title: "Công nghệ & AI",
            iconName: "cpu",
            totalWords: 25,
            learnedWords: 12,
            state: .active,
            words: [word]
        )
        XCTAssertEqual(node.state, .active)
        XCTAssertEqual(node.words.count, 1)
        XCTAssertEqual(node.words.first?.english, "Algorithm")
    }
}
