import XCTest
import SwiftUI
@testable import VocabCraftApp

final class BentoCardsTests: XCTestCase {
    func testSRSMemoryHeroCardInitialization() {
        let hero = SRSMemoryHeroCard(totalWords: 1420, retentionPercentage: 0.85)
        XCTAssertNotNil(hero)
        XCTAssertEqual(hero.totalWords, 1420)
        XCTAssertEqual(hero.retentionPercentage, 0.85, accuracy: 0.001)
    }

    func testSRSMemoryHeroCardInstantiation() {
        let heroCard = SRSMemoryHeroCard(totalWords: 1420, retentionPercentage: 0.85)
        XCTAssertNotNil(heroCard.body)
        XCTAssertEqual(heroCard.totalWords, 1420)
        XCTAssertEqual(heroCard.retentionPercentage, 0.85)
    }

    func testActionCardsGridInitializationAndCallbacks() {
        var reflexCalled = false
        var queueCalled = false

        let grid = ActionCardsGrid(
            dueCardsCount: 24,
            onReflexTap: { reflexCalled = true },
            onQueueTap: { queueCalled = true }
        )

        XCTAssertNotNil(grid)
        XCTAssertEqual(grid.dueCardsCount, 24)

        grid.onReflexTap()
        XCTAssertTrue(reflexCalled)

        grid.onQueueTap()
        XCTAssertTrue(queueCalled)
    }

    func testCEFRDistributionCardInitialization() {
        var detailTapped = false

        let cefrCard = CEFRDistributionCard(
            a1a2Count: 450,
            b1b2Count: 620,
            c1c2Count: 350,
            onDetailTap: { detailTapped = true }
        )

        XCTAssertNotNil(cefrCard)
        XCTAssertEqual(cefrCard.a1a2Count, 450)
        XCTAssertEqual(cefrCard.b1b2Count, 620)
        XCTAssertEqual(cefrCard.c1c2Count, 350)

        cefrCard.onDetailTap?()
        XCTAssertTrue(detailTapped)
    }
}
