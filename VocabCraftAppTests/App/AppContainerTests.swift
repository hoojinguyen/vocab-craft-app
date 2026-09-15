import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("AppContainer Tests")
struct AppContainerTests {
    @Test @MainActor
    func appContainerProvidesBundledVocabularyDataSourceByDefault() {
        let container = AppContainer()
        #expect(container.vocabularyDataSource is BundledVocabularyDataSource)
    }

    @Test @MainActor
    func appContainerWiresVocabularyRepositoryWithBundledDataSource() async throws {
        let container = AppContainer()
        #expect(container.vocabularyRepository is VocabularyRepositoryImpl)

        let words = try await container.vocabularyRepository.fetchWordRecords(limit: 5)
        #expect(!words.isEmpty)
        #expect(words.count == 5)

        let defaultWords = try await container.vocabularyRepository.fetchWordRecords()
        #expect(!defaultWords.isEmpty)

        let firstWord = try #require(words.first)
        let fetchedWord = try await container.vocabularyRepository.fetchWord(id: firstWord.id)
        #expect(fetchedWord?.id == firstWord.id)
        #expect(fetchedWord?.lemma == firstWord.lemma)

        let searchResults = try await container.vocabularyRepository.searchWords(query: firstWord.lemma)
        #expect(!searchResults.isEmpty)
        #expect(searchResults.contains(where: { $0.id == firstWord.id }))

        let suggested = try await container.vocabularyRepository.fetchSuggestedWords(limit: 3)
        #expect(!suggested.isEmpty)
        #expect(suggested.count <= 3)

        let defaultSuggested = try await container.vocabularyRepository.fetchSuggestedWords()
        #expect(!defaultSuggested.isEmpty)
    }

    @Test @MainActor
    func appContainerAllowsCustomDataSourceInjection() async throws {
        let customSource = BundledVocabularyDataSource()
        let container = AppContainer(vocabularyDataSource: customSource)
        #expect((container.vocabularyDataSource as AnyObject) === (customSource as AnyObject))
    }

    @Test @MainActor
    func appContainerMockModeUsesMockVocabularyRepository() {
        let container = AppContainer.mock
        #expect(container.vocabularyRepository is MockVocabularyRepository)
    }

    #if canImport(SwiftDataMacros) || canImport(SwiftData)
    @Test @MainActor
    func appBootstrapperIntegratesWithBundledDataSource() {
        let bootstrapper = AppBootstrapper(inMemoryOnly: true)
        bootstrapper.bootstrap()
        #expect(bootstrapper.state == .ready)
        #expect(bootstrapper.appContainer?.vocabularyDataSource is BundledVocabularyDataSource)
        #expect(bootstrapper.appContainer?.vocabularyRepository is VocabularyRepositoryImpl)
    }
    #endif
}
#endif
