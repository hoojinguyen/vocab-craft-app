import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("VocabularyFilterService Tests")
struct VocabularyFilterServiceTests {
    let service = VocabularyFilterService()

    let sampleWords: [WordItem] = [
        WordItem(id: 1, lemma: "apple", phonetic: "/ˈæp.əl/", pos: "noun", definition: "quả táo", exampleSentenceEn: "An apple a day", exampleSentenceVi: "", cefrLevel: "A1", masteryLevel: 5),
        WordItem(id: 2, lemma: "benevolent", phonetic: "/bəˈnev.əl.ənt/", pos: "adj", definition: "nhân từ", exampleSentenceEn: "A benevolent leader", exampleSentenceVi: "", cefrLevel: "C1", masteryLevel: 1),
        WordItem(id: 3, lemma: "resilient", phonetic: "/rɪˈzɪl.jənt/", pos: "adj", definition: "kiên cường", exampleSentenceEn: "Be resilient", exampleSentenceVi: "", cefrLevel: "B2", masteryLevel: 2),
        WordItem(id: 4, lemma: "cat", phonetic: "/kæt/", pos: "noun", definition: "con mèo", exampleSentenceEn: "A black cat", exampleSentenceVi: "", cefrLevel: "A2", masteryLevel: 4)
    ]

    @Test("Filters by search query matching lemma or definition")
    func testSearchQuery() {
        let filtered = service.filter(words: sampleWords, filter: .all, searchText: "apple")
        #expect(filtered.count == 1)
        #expect(filtered.first?.lemma == "apple")

        let filteredDef = service.filter(words: sampleWords, filter: .all, searchText: "nhân từ")
        #expect(filteredDef.count == 1)
        #expect(filteredDef.first?.lemma == "benevolent")
    }

    @Test("Filters by mastery level (needsReview vs mastered)")
    func testMasteryFilter() {
        let needsReview = service.filter(words: sampleWords, filter: .needsReview, searchText: "")
        #expect(needsReview.count == 2)
        #expect(needsReview.map(\.lemma).contains("benevolent"))
        #expect(needsReview.map(\.lemma).contains("resilient"))

        let mastered = service.filter(words: sampleWords, filter: .mastered, searchText: "")
        #expect(mastered.count == 2)
        #expect(mastered.map(\.lemma).contains("apple"))
        #expect(mastered.map(\.lemma).contains("cat"))
    }

    @Test("Filters by CEFR level groups")
    func testCEFRFilter() {
        let a1a2 = service.filter(words: sampleWords, filter: .a1a2, searchText: "")
        #expect(a1a2.count == 2)

        let b1b2 = service.filter(words: sampleWords, filter: .b1b2, searchText: "")
        #expect(b1b2.count == 1)
        #expect(b1b2.first?.lemma == "resilient")

        let c1c2 = service.filter(words: sampleWords, filter: .c1c2, searchText: "")
        #expect(c1c2.count == 1)
        #expect(c1c2.first?.lemma == "benevolent")
    }

    @Test("Calculates filter count correctly")
    func testFilterCount() {
        #expect(service.countMatches(in: sampleWords, for: .all) == 4)
        #expect(service.countMatches(in: sampleWords, for: .needsReview) == 2)
        #expect(service.countMatches(in: sampleWords, for: .mastered) == 2)
        #expect(service.countMatches(in: sampleWords, for: .a1a2) == 2)
        #expect(service.countMatches(in: sampleWords, for: .b1b2) == 1)
        #expect(service.countMatches(in: sampleWords, for: .c1c2) == 1)
    }

    @Test("Calculates all filter counts in a single pass")
    func testCountAllCategories() {
        let counts = service.countAllCategories(in: sampleWords)
        #expect(counts[.all] == 4)
        #expect(counts[.needsReview] == 2)
        #expect(counts[.mastered] == 2)
        #expect(counts[.a1a2] == 2)
        #expect(counts[.b1b2] == 1)
        #expect(counts[.c1c2] == 1)
    }
}
#endif
