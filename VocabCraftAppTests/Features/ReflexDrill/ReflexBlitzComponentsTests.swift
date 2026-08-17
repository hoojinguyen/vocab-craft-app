import SwiftUI
import XCTest
@testable import VocabCraftApp

final class ReflexBlitzComponentsTests: XCTestCase {
    @MainActor
    func testHeaderViewInstantiation() {
        var didClose = false
        var didSkip = false

        let header = ReflexBlitzHeaderView(
            currentIndex: 2,
            totalCount: 8,
            comboStreak: 3,
            onClose: { didClose = true },
            onSkip: { didSkip = true }
        )
        XCTAssertNotNil(header)
        XCTAssertEqual(header.currentIndex, 2)
        XCTAssertEqual(header.totalCount, 8)
        XCTAssertEqual(header.comboStreak, 3)

        header.onClose()
        header.onSkip()
        XCTAssertTrue(didClose)
        XCTAssertTrue(didSkip)
    }

    @MainActor
    func testHeaderViewBodyRendersAcrossComboThresholds() {
        let noComboHeader = ReflexBlitzHeaderView(
            currentIndex: 0,
            totalCount: 5,
            comboStreak: 1,
            onClose: {},
            onSkip: {}
        )
        XCTAssertNotNil(noComboHeader.body)

        let comboHeader = ReflexBlitzHeaderView(
            currentIndex: 4,
            totalCount: 5,
            comboStreak: 4,
            onClose: {},
            onSkip: {}
        )
        XCTAssertNotNil(comboHeader.body)
    }

    @MainActor
    func testCountdownOverlayInstantiationAndBody() {
        let overlayCountdown = ReflexCountdownOverlayView(count: 3)
        XCTAssertNotNil(overlayCountdown)
        XCTAssertEqual(overlayCountdown.count, 3)
        XCTAssertNotNil(overlayCountdown.body)

        let overlayGo = ReflexCountdownOverlayView(count: 0)
        XCTAssertNotNil(overlayGo)
        XCTAssertEqual(overlayGo.count, 0)
        XCTAssertNotNil(overlayGo.body)
    }

    @MainActor
    func testCardViewInstantiationAndStates() {
        let word = ReflexBlitzWordItem(
            id: 1,
            lemma: "ephemeral",
            pos: "adj.",
            definitionVi: "Phù du, chóng tàn",
            exampleSentenceEn: "Her fame is ephemeral in nature.",
            exampleSentenceVi: "Danh tiếng của cô ấy phù du."
        )

        // Default state
        let defaultCard = ReflexBlitzCardView(
            word: word,
            showHint: false,
            isCorrect: false,
            isTimeout: false
        )
        XCTAssertNotNil(defaultCard)
        XCTAssertEqual(defaultCard.word.id, 1)
        XCTAssertFalse(defaultCard.showHint)
        XCTAssertFalse(defaultCard.isCorrect)
        XCTAssertFalse(defaultCard.isTimeout)
        XCTAssertNotNil(defaultCard.body)

        // Hint visible state
        let hintedCard = ReflexBlitzCardView(
            word: word,
            showHint: true,
            isCorrect: false,
            isTimeout: false
        )
        XCTAssertNotNil(hintedCard)
        XCTAssertTrue(hintedCard.showHint)
        XCTAssertNotNil(hintedCard.body)

        // Correct match state
        let correctCard = ReflexBlitzCardView(
            word: word,
            showHint: false,
            isCorrect: true,
            isTimeout: false
        )
        XCTAssertNotNil(correctCard)
        XCTAssertTrue(correctCard.isCorrect)
        XCTAssertNotNil(correctCard.body)

        // Timeout state
        let timeoutCard = ReflexBlitzCardView(
            word: word,
            showHint: false,
            isCorrect: false,
            isTimeout: true
        )
        XCTAssertNotNil(timeoutCard)
        XCTAssertTrue(timeoutCard.isTimeout)
        XCTAssertNotNil(timeoutCard.body)
    }
}
