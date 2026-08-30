import CraftUIKit
import Foundation
import SpeechKit
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("SpeechKitAdapterTests")
struct SpeechKitAdapterTests {
    @Test("Exact match status maps to CraftSpeechStatus.matched")
    func testExactMatchMapping() {
        let token = WordTokenResult(
            targetWord: "hello",
            spokenWord: "hello",
            status: .exactMatch,
            confidence: 0.95
        )
        let craftToken = token.asCraftSpeechWordToken

        #expect(craftToken.targetWord == "hello")
        #expect(craftToken.spokenWord == "hello")
        #expect(craftToken.status == .matched)
        #expect(craftToken.confidence == 0.95)
    }

    @Test("Fuzzy match status maps to CraftSpeechStatus.fuzzy")
    func testFuzzyMatchMapping() {
        let token = WordTokenResult(
            targetWord: "world",
            spokenWord: "word",
            status: .fuzzyMatch,
            confidence: 0.65
        )
        let craftToken = token.asCraftSpeechWordToken

        #expect(craftToken.targetWord == "world")
        #expect(craftToken.spokenWord == "word")
        #expect(craftToken.status == .fuzzy)
    }

    @Test("Missing status maps to CraftSpeechStatus.mismatched")
    func testMissingMapping() {
        let token = WordTokenResult(
            targetWord: "swift",
            spokenWord: nil,
            status: .missing,
            confidence: nil
        )
        let craftToken = token.asCraftSpeechWordToken

        #expect(craftToken.targetWord == "swift")
        #expect(craftToken.spokenWord == nil)
        #expect(craftToken.status == .mismatched)
        #expect(craftToken.confidence == nil)
    }
}
#endif
