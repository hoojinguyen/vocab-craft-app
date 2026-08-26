@testable import VocabCraftApp
import XCTest

final class AppContainerVocabularyTests: XCTestCase {
    @MainActor
    func test_appContainer_instantiatesVocabularyViewModelsWithCleanDependencies() {
        let container = AppContainer.mock
        let personalVM = container.makePersonalVaultViewModel()
        XCTAssertNotNil(personalVM)

        let decksVM = container.makeTopicDecksViewModel()
        XCTAssertNotNil(decksVM)
    }

    @MainActor
    func test_appContainer_instantiatesTopicRoadmapViewModel() {
        let container = AppContainer.mock
        let roadmapVM = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        XCTAssertNotNil(roadmapVM)
        XCTAssertEqual(roadmapVM.deckId, "deck_daily")
    }

    @MainActor
    func test_appContainer_instantiatesStageChallengeViewModel() {
        let container = AppContainer.mock
        let stage = SubTopicStage(
            id: "stage_daily_1",
            deckId: "deck_daily",
            title: "Chặng 1",
            iconName: "heart",
            sortOrder: 1,
            state: .active,
            words: [
                TopicWord(
                    id: "1",
                    english: "Resilience",
                    phonetic: "/rɪˈzɪl.jəns/",
                    vietnamese: "Sự kiên cường",
                    example: "Her resilience helped her.",
                    partOfSpeech: "noun"
                )
            ]
        )
        let challengeVM = container.makeStageChallengeViewModel(stage: stage)
        XCTAssertNotNil(challengeVM)
        XCTAssertEqual(challengeVM.stage.id, "stage_daily_1")
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
        XCTAssertNotNil(containerWithSample.fetchTopicDecksUseCase)
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
