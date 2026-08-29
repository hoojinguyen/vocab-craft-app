import Foundation
import Testing
@testable import VocabCraftApp

@Suite("ReflexDrillable Protocol Tests")
struct ReflexDrillableTests {
    struct MockDrillItem: ReflexDrillable {
        let id: String
        let lemma: String
        let pos: String
        let ipa: String
        let definitionVi: String
        let exampleSentenceEn: String
        let exampleSentenceVi: String
        let clozeSentenceEn: String
        let cefrLevel: String
        let audioResourceUrl: String?
    }

    @Test("Verifies cleanPos, cleanLevel, and cleanInitialLetterHint extensions")
    func testDrillableExtensions() {
        let item = MockDrillItem(
            id: "1",
            lemma: "habit",
            pos: "n.",
            ipa: "/ˈhæb.ɪt/",
            definitionVi: "Thói quen",
            exampleSentenceEn: "Reading books is a habit.",
            exampleSentenceVi: "Đọc sách là một thói quen.",
            clozeSentenceEn: "Reading books is a [ _________ ].",
            cefrLevel: "B1",
            audioResourceUrl: nil
        )

        #expect(item.cleanPos == "noun")
        #expect(item.cleanLevel == "B1")
        #expect(item.cleanInitialLetterHint == "h... • noun")
    }

    @Test("Verifies cleanPos mapping for various parts of speech")
    func testCleanPosVariants() {
        func makeItem(pos: String, lemma: String = "test") -> MockDrillItem {
            MockDrillItem(
                id: "1",
                lemma: lemma,
                pos: pos,
                ipa: "",
                definitionVi: "",
                exampleSentenceEn: "",
                exampleSentenceVi: "",
                clozeSentenceEn: "",
                cefrLevel: "",
                audioResourceUrl: nil
            )
        }

        #expect(makeItem(pos: "v.").cleanPos == "verb")
        #expect(makeItem(pos: "verb").cleanPos == "verb")
        #expect(makeItem(pos: "n.").cleanPos == "noun")
        #expect(makeItem(pos: "noun").cleanPos == "noun")
        #expect(makeItem(pos: "adj.").cleanPos == "adj")
        #expect(makeItem(pos: "adjective").cleanPos == "adj")
        #expect(makeItem(pos: "adv.").cleanPos == "adv")
        #expect(makeItem(pos: "adverb").cleanPos == "adv")
        #expect(makeItem(pos: "prep.").cleanPos == "prep")
        #expect(makeItem(pos: "preposition").cleanPos == "prep")
        #expect(makeItem(pos: "conj.").cleanPos == "conj")
        #expect(makeItem(pos: "conjunction").cleanPos == "conj")
        #expect(makeItem(pos: "pron.").cleanPos == "pron")
        #expect(makeItem(pos: "pronoun").cleanPos == "pron")
        #expect(makeItem(pos: "phrase").cleanPos == "phrase")
        #expect(makeItem(pos: "").cleanPos == "word")
    }

    @Test("Verifies cleanLevel fallback to B2 when empty")
    func testCleanLevelFallback() {
        let emptyLevelItem = MockDrillItem(
            id: "1",
            lemma: "focus",
            pos: "v.",
            ipa: "",
            definitionVi: "",
            exampleSentenceEn: "",
            exampleSentenceVi: "",
            clozeSentenceEn: "",
            cefrLevel: "",
            audioResourceUrl: nil
        )
        #expect(emptyLevelItem.cleanLevel == "B2")

        let specifiedLevelItem = MockDrillItem(
            id: "2",
            lemma: "resilience",
            pos: "n.",
            ipa: "",
            definitionVi: "",
            exampleSentenceEn: "",
            exampleSentenceVi: "",
            clozeSentenceEn: "",
            cefrLevel: "C1",
            audioResourceUrl: nil
        )
        #expect(specifiedLevelItem.cleanLevel == "C1")
    }

    @Test("Verifies VaultWordItem conformance to ReflexDrillable")
    func testVaultWordItemConformance() {
        let vaultWord = VaultWordItem(
            id: 101,
            lemma: "resilience",
            pos: "n.",
            phonetic: "/rɪˈzɪl.jəns/",
            definitionVi: "Khả năng phục hồi",
            exampleSentenceEn: "Her resilience inspired everyone.",
            exampleSentenceVi: "Sự kiên cường của cô ấy truyền cảm hứng.",
            cefrLevel: "B2"
        )

        let drillable: any ReflexDrillable = vaultWord
        #expect(drillable.lemma == "resilience")
        #expect(drillable.cleanPos == "noun")
        #expect(drillable.ipa == "/rɪˈzɪl.jəns/")
        #expect(drillable.definitionVi == "Khả năng phục hồi")
        #expect(drillable.exampleSentenceEn == "Her resilience inspired everyone.")
        #expect(drillable.exampleSentenceVi == "Sự kiên cường của cô ấy truyền cảm hứng.")
        #expect(drillable.clozeSentenceEn == "Her resilience inspired everyone.")
        #expect(drillable.cleanLevel == "B2")
        #expect(drillable.cleanInitialLetterHint == "r... • noun")
        #expect(drillable.audioResourceUrl == nil)
    }

    @Test("Verifies MixedReflexDrillItem conformance to ReflexDrillable")
    func testMixedReflexDrillItemConformance() {
        let vaultWord = VaultWordItem(
            id: 202,
            lemma: "adapt",
            pos: "v.",
            phonetic: "/əˈdæpt/",
            definitionVi: "Thích nghi",
            exampleSentenceEn: "You need to adapt to changes.",
            exampleSentenceVi: "Bạn cần thích nghi với thay đổi.",
            cefrLevel: "B1"
        )
        let mixedItem = MixedReflexDrillItem(
            word: vaultWord,
            assignedMode: .speaking
        )

        let drillable: any ReflexDrillable = mixedItem
        #expect(drillable.lemma == "adapt")
        #expect(drillable.cleanPos == "verb")
        #expect(drillable.ipa == "/əˈdæpt/")
        #expect(drillable.definitionVi == "Thích nghi")
        #expect(drillable.cleanLevel == "B1")
        #expect(drillable.cleanInitialLetterHint == "a... • verb")
    }
}
