import XCTest
@testable import VocabCraftApp

@MainActor
final class TopicRoadmapViewModelTests: XCTestCase {
    func test_loadRoadmap_populatesStagesAndSetsActiveStage() async {
        let container = AppContainer.mock
        let sut = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        
        XCTAssertTrue(sut.stages.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        
        await sut.loadRoadmap()
        
        XCTAssertFalse(sut.stages.isEmpty)
        XCTAssertEqual(sut.stages.count, 2)
        XCTAssertEqual(sut.stages.first?.state, .active)
        XCTAssertEqual(sut.stages.last?.state, .locked)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_activeStage_returnsFirstActiveStage() async {
        let container = AppContainer.mock
        let sut = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        
        XCTAssertNil(sut.activeStage)
        
        await sut.loadRoadmap()
        
        XCTAssertNotNil(sut.activeStage)
        XCTAssertEqual(sut.activeStage?.id, "stage_daily_1")
        XCTAssertEqual(sut.activeStage?.state, .active)
    }

    func test_progressMetrics_calculatesCorrectValues() async {
        let container = AppContainer.mock
        let sut = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        await sut.loadRoadmap()
        
        XCTAssertEqual(sut.totalStagesCount, 2)
        XCTAssertEqual(sut.completedStagesCount, 0)
        XCTAssertEqual(sut.progressPercentage, 0.0)
        XCTAssertEqual(sut.totalWordsCount, 13) // 7 in stage 1 + 6 in stage 2
    }

    func test_stageSelection_setsSelectedStage() async {
        let container = AppContainer.mock
        let sut = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        await sut.loadRoadmap()
        
        guard let firstStage = sut.stages.first else {
            XCTFail("Expected non-empty stages")
            return
        }
        
        XCTAssertNil(sut.selectedStage)
        sut.selectStage(firstStage)
        XCTAssertEqual(sut.selectedStage?.id, firstStage.id)
    }

    func test_loadRoadmap_withFailingUseCase_setsErrorMessage() async {
        struct FailingUseCase: FetchDeckRoadmapUseCaseProtocol {
            func execute(deckId: String) async throws -> [SubTopicStage] {
                throw NSError(domain: "test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Failed to load roadmap"])
            }
        }
        
        let sut = TopicRoadmapViewModel(deckId: "deck_unknown", fetchDeckRoadmapUseCase: FailingUseCase())
        await sut.loadRoadmap()
        
        XCTAssertTrue(sut.stages.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Failed to load roadmap")
    }
}
