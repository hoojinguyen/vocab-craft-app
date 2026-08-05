import XCTest
import SwiftUI
@testable import VocabCraftApp

final class VocabularyViewsTests: XCTestCase {
    func testVocabularySummaryCardInstantiation() {
        let view = VocabularySummaryCard(
            totalWords: 1420,
            srsRetentionPercentage: 0.85,
            dueCount: 24
        )
        XCTAssertNotNil(view.body)
        XCTAssertEqual(view.totalWords, 1420)
        XCTAssertEqual(view.srsRetentionPercentage, 0.85)
        XCTAssertEqual(view.dueCount, 24)
    }

    func testWordAccordionCardExpandedState() {
        let item = WordItem.mockData[0]
        let card = WordAccordionCard(
            item: item,
            isExpanded: true,
            onTap: {},
            onAudioTap: {},
            onDrillTap: {}
        )
        XCTAssertNotNil(card.body)
        XCTAssertTrue(card.isExpanded)
    }

    func testWordAccordionCardCollapsedState() {
        let item = WordItem.mockData[0]
        let card = WordAccordionCard(
            item: item,
            isExpanded: false,
            onTap: {},
            onAudioTap: {},
            onDrillTap: {}
        )
        XCTAssertNotNil(card.body)
        XCTAssertFalse(card.isExpanded)
    }

    func testWordAccordionCardCallbacks() {
        var tapped = false
        var audioTapped = false
        var drillTapped = false

        let card = WordAccordionCard(
            item: WordItem.mockData[0],
            isExpanded: true,
            onTap: { tapped = true },
            onAudioTap: { audioTapped = true },
            onDrillTap: { drillTapped = true }
        )
        card.onTap()
        card.onAudioTap()
        card.onDrillTap()

        XCTAssertTrue(tapped)
        XCTAssertTrue(audioTapped)
        XCTAssertTrue(drillTapped)
    }

    func testTopicDecksGridViewInstantiation() {
        let view = TopicDecksGridView(onDeckSelected: { _ in })
        XCTAssertNotNil(view.body)
    }
}

