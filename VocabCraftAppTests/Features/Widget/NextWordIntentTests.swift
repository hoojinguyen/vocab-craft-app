import Foundation
import SwiftData
import Testing
@testable import VocabCraftApp
#if SWIFT_PACKAGE
@testable import VocabCraftWidgetExtension
#endif

@Suite("NextWordIntent Tests")
@MainActor
struct NextWordIntentTests {
    @Test("NextWordIntent rotates sequentially through words loaded from BundledVocabularyDataSource")
    func nextWordIntentRotatesSequentially() async throws {
        let container = try SharedAppGroupContainer.createContainer(inMemory: true)
        let context = container.mainContext

        let dataSource = BundledVocabularyDataSource()
        let catalogWords = try await dataSource.searchWords(query: "")
        #expect(!catalogWords.isEmpty)

        let intent = NextWordIntent()

        // 1. First execution creates initial state with first word in catalog
        try await intent.perform(in: context, dataSource: dataSource)
        var states = try context.fetch(FetchDescriptor<WidgetCurrentState>())
        #expect(states.count == 1)
        #expect(states[0].currentWordId == catalogWords[0].id)
        #expect(states[0].lemma == catalogWords[0].lemma)
        #expect(states[0].ipaUs == catalogWords[0].phonetic)
        #expect(states[0].definitionVi == catalogWords[0].definitionVi)
        #expect(states[0].exampleEn == catalogWords[0].exampleEn)

        // 2. Second execution advances to second word in catalog
        if catalogWords.count > 1 {
            try await intent.perform(in: context, dataSource: dataSource)
            states = try context.fetch(FetchDescriptor<WidgetCurrentState>())
            #expect(states.count == 1)
            #expect(states[0].currentWordId == catalogWords[1].id)
            #expect(states[0].lemma == catalogWords[1].lemma)
            #expect(states[0].ipaUs == catalogWords[1].phonetic)
        }
    }

    @Test("NextWordIntent wraps around when reaching end of words")
    func nextWordIntentWrapsAround() async throws {
        let container = try SharedAppGroupContainer.createContainer(inMemory: true)
        let context = container.mainContext

        let dataSource = BundledVocabularyDataSource()
        let catalogWords = try await dataSource.searchWords(query: "")
        #expect(!catalogWords.isEmpty)

        guard let lastWord = catalogWords.last else { return }

        // Seed state at the last word
        let lastState = WidgetCurrentState(
            currentWordId: lastWord.id,
            lemma: lastWord.lemma,
            ipaUs: lastWord.phonetic,
            definitionVi: lastWord.definitionVi,
            exampleEn: lastWord.exampleEn,
            lastUpdated: Date(timeIntervalSince1970: 500)
        )
        context.insert(lastState)
        try context.save()

        let intent = NextWordIntent()
        try await intent.perform(in: context, dataSource: dataSource)

        let states = try context.fetch(FetchDescriptor<WidgetCurrentState>())
        #expect(states.count == 1)
        #expect(states[0].currentWordId == catalogWords[0].id)
        #expect(states[0].lemma == catalogWords[0].lemma)
    }
}
