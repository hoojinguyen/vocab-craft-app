import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("Domain Entities Clean Architecture Tests")
struct DomainEntitiesTests {
    @Test("TopicDeck is pure domain entity with hex color")
    func testTopicDeckPureDomain() {
        let deck = TopicDeck(
            id: "ielts_tech",
            title: "Technology",
            wordCount: 20,
            completionPercentage: 0.5,
            badgeColorHex: "#3B82F6",
            iconName: "desktopcomputer"
        )
        #expect(deck.id == "ielts_tech")
        #expect(deck.badgeColorHex == "#3B82F6")
    }

    @Test("ReflexDrillItem domain entity initialization")
    func testReflexDrillItem() {
        let item = ReflexDrillItem(
            id: 101,
            drillType: "speed",
            promptText: "Thói quen",
            correctAnswer: "habit",
            distractors: ["hobby", "habitat"],
            targetTimeMs: 2500,
            sentenceTextEn: "It is a good habit."
        )
        #expect(item.id == "101")
        #expect(item.correctAnswer == "habit")
    }
}
#endif
