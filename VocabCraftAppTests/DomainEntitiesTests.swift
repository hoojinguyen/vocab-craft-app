import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("Domain Entities Clean Architecture Tests")
struct DomainEntitiesTests {
    @Test("MixedReflexDrillItem domain entity initialization")
    func testMixedReflexDrillItem() {
        let word = VaultWordItem(
            id: 101,
            lemma: "habit",
            pos: "n.",
            phonetic: "/ˈhæb.ɪt/",
            definitionVi: "Thói quen",
            exampleSentenceEn: "It is a good habit.",
            exampleSentenceVi: "Đó là một thói quen tốt."
        )
        let item = MixedReflexDrillItem(
            word: word,
            assignedMode: .multipleChoice
        )
        #expect(item.lemma == "habit")
        #expect(item.assignedMode == .multipleChoice)
        #expect(item.definitionVi == "Thói quen")
    }
}
#endif
