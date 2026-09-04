import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class AppContainerVocabularyTests: XCTestCase {
    @MainActor
    func test_appContainer_instantiatesVocabularyViewModelsWithCleanDependencies() {
        let container = AppContainer.mock
        let personalVM = container.makePersonalVaultViewModel()
        XCTAssertNotNil(personalVM)

        let homeVM = container.makeHomepageViewModel()
        XCTAssertNotNil(homeVM)
    }

    @MainActor
    func test_appContainer_instantiatesSmartReviewViewModel() {
        let container = AppContainer.mock
        let weakWord = PersonalWord(
            id: 1,
            lemma: "Resilience",
            phonetic: "/rɪˈzɪl.jəns/",
            pos: "noun",
            cefrLevel: "B2",
            definitionVi: "Sự kiên cường",
            definitionEn: "Capacity to recover",
            exampleEn: "Her resilience helped her.",
            exampleVi: "Sự kiên cường giúp cô ấy.",
            needsReview: true
        )
        let smartReviewVM = container.makeSmartReviewViewModel(weakWords: [weakWord])
        XCTAssertNotNil(smartReviewVM)
        XCTAssertEqual(smartReviewVM.weakWords.count, 1)
    }

    @MainActor
    func test_appContainer_useSampleDataToggle_configuresSampleDataSource() {
        let containerWithSample = AppContainer(useSampleData: true)
        XCTAssertNotNil(containerWithSample.fetchPersonalVaultUseCase)
        XCTAssertNotNil(containerWithSample.reviewWeakWordsUseCase)
        XCTAssertNotNil(containerWithSample.stageProgressRepository)
    }

    @MainActor
    func test_appContainer_instantiatesMixedReflexDrillDependencies() {
        let container = AppContainer.mock
        let queueUseCase = container.makeGenerateMixedReflexQueueUseCase()
        XCTAssertNotNil(queueUseCase)

        let recordAttemptUseCase = container.makeRecordMixedDrillAttemptUseCase()
        XCTAssertNotNil(recordAttemptUseCase)

        let sampleWords = [
            VaultWordItem(id: 1, lemma: "resilience", pos: "n.", definitionVi: "Sự kiên cường"),
            VaultWordItem(id: 2, lemma: "habit", pos: "n.", definitionVi: "Thói quen")
        ]
        let drillVM = container.makeMixedReflexDrillViewModel(selectedWords: sampleWords)
        XCTAssertNotNil(drillVM)
        XCTAssertEqual(drillVM.queue.count, 2)
        XCTAssertFalse(drillVM.isCompleted)
    }

    @MainActor
    func test_appContainer_instantiatesLearningPathUseCases() {
        let container = AppContainer.mock
        XCTAssertNotNil(container.fetchLearningPathUseCase)
        XCTAssertNotNil(container.completeLessonUseCase)
        XCTAssertNotNil(container.makeFetchLearningPathUseCase())
        XCTAssertNotNil(container.makeCompleteLessonUseCase())
    }
}

#if canImport(Testing)
import Testing

@Suite("AppContainer Audio Dependency Tests")
struct AppContainerAudioDependencyTests {
    @Test @MainActor func appContainerSharesCoordinatorBetweenTTSAndCreatedSpeechEngines() {
        let container = AppContainer.mock
        let coordinator = container.audioSessionCoordinator

        let tts = container.ttsService as? TextToSpeechService
        #expect(tts != nil)
        #expect((tts?.audioSessionCoordinator as AnyObject?) === (coordinator as AnyObject))

        let engine = container.makeReflexSpeechEngine() as? ResilientReflexSpeechEngine
        #expect(engine != nil)
        #expect((engine?.audioSessionCoordinator as AnyObject?) === (coordinator as AnyObject))
    }
}
#endif
