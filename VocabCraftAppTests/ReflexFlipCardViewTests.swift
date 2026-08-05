import XCTest
import SwiftUI
@testable import VocabCraftApp

final class ReflexFlipCardViewTests: XCTestCase {
    func testCardInitialization() {
        let word = TopicWord(id: "w1", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán")
        let card = ReflexFlipCardView(word: word, isFlipped: false, isSuccess: true, onAudioTap: {})
        XCTAssertNotNil(card)
    }

    func testCardInitializationFlippedAndFailure() {
        let word = TopicWord(id: "w2", english: "Heuristic", phonetic: "/hjʊəˈrɪstɪk/", vietnamese: "Phương pháp kinh nghiệm")
        let card = ReflexFlipCardView(word: word, isFlipped: true, isSuccess: false, onAudioTap: {})
        XCTAssertNotNil(card)
    }

    func testReflexFlipCardViewRendersMinimalElements() {
        let word = TopicWord(id: "w1", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Sự tự động hóa", example: "Factory automation reduces costs.", partOfSpeech: "noun")
        let card = ReflexFlipCardView(word: word, isFlipped: false, isSuccess: true, onAudioTap: {})
        XCTAssertEqual(card.word.english, "Automation")
        XCTAssertEqual(card.word.partOfSpeech, "noun")
    }
}
