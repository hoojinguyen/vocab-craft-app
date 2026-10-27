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
        let isProductionSource = container.vocabularyDataSource is SQLiteContentRepository
            || container.vocabularyDataSource is BundledVocabularyDataSource
        #expect(isProductionSource)
    }

    @Test @MainActor
    func appContainerGetProductionDataSourceReturnsValidDataSource() {
        let dataSource = AppContainer.getProductionDataSource()
        let isProductionSource = dataSource is SQLiteContentRepository
            || dataSource is BundledVocabularyDataSource
        #expect(isProductionSource)
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
    func appContainerAllowsSQLiteContentRepositoryInjection() throws {
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID().uuidString).sqlite")
        FileManager.default.createFile(atPath: tempUrl.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: tempUrl) }

        let sqliteRepo = try SQLiteContentRepository(url: tempUrl)
        let container = AppContainer(vocabularyDataSource: sqliteRepo)
        #expect(container.vocabularyDataSource is SQLiteContentRepository)
    }

    @Test @MainActor
    func appContainerMockModeUsesMockVocabularyRepository() {
        let container = AppContainer.mock
        #expect(container.vocabularyRepository is MockVocabularyRepository)
    }

    @Test @MainActor
    func contentIsCopiedWhenInstalledCopyIsMissing() {
        #expect(AppContainer.shouldCopyBundledContent(
            destExists: false, bundleVersion: 10, destVersion: 0, savedVersion: 0,
            bundlePathCount: 4, destPathCount: 0
        ))
    }

    @Test @MainActor
    func contentIsCopiedWhenBundleVersionIsNewer() {
        #expect(AppContainer.shouldCopyBundledContent(
            destExists: true, bundleVersion: 11, destVersion: 10, savedVersion: 10,
            bundlePathCount: 4, destPathCount: 4
        ))
    }

    @Test @MainActor
    func contentIsCopiedWhenSavedVersionIsBehindTheBundle() {
        #expect(AppContainer.shouldCopyBundledContent(
            destExists: true, bundleVersion: 10, destVersion: 10, savedVersion: 8,
            bundlePathCount: 4, destPathCount: 4
        ))
    }

    @Test @MainActor
    func contentIsCopiedWhenInstalledCopyHasFewerPathsThanTheBundle() {
        #expect(AppContainer.shouldCopyBundledContent(
            destExists: true, bundleVersion: 10, destVersion: 10, savedVersion: 10,
            bundlePathCount: 4, destPathCount: 1
        ))
    }

    @Test @MainActor
    func contentIsNotRecopiedWhenBundleAndInstalledCopyMatch() {
        // A bundle that ships a single path must not be recopied on every launch.
        #expect(!AppContainer.shouldCopyBundledContent(
            destExists: true, bundleVersion: 10, destVersion: 10, savedVersion: 10,
            bundlePathCount: 1, destPathCount: 1
        ))
        #expect(!AppContainer.shouldCopyBundledContent(
            destExists: true, bundleVersion: 10, destVersion: 10, savedVersion: 10,
            bundlePathCount: 4, destPathCount: 4
        ))
    }

    @Test @MainActor
    func contentIsNotCopiedWhenInstalledCopyHasMorePathsThanTheBundle() {
        #expect(!AppContainer.shouldCopyBundledContent(
            destExists: true, bundleVersion: 10, destVersion: 10, savedVersion: 10,
            bundlePathCount: 1, destPathCount: 4
        ))
    }

    #if canImport(SwiftDataMacros) || canImport(SwiftData)
    @Test @MainActor
    func appBootstrapperIntegratesWithBundledDataSource() {
        let bootstrapper = AppBootstrapper(inMemoryOnly: true)
        bootstrapper.bootstrap()
        #expect(bootstrapper.state == .ready)
        let isProductionSource = bootstrapper.appContainer?.vocabularyDataSource is SQLiteContentRepository
            || bootstrapper.appContainer?.vocabularyDataSource is BundledVocabularyDataSource
        #expect(isProductionSource)
        #expect(bootstrapper.appContainer?.vocabularyRepository is VocabularyRepositoryImpl)
    }
    #endif
}
#endif
