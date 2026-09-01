import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("Domain Entities Clean Architecture Tests")
struct DomainEntitiesTests {
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
