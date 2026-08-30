import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class TopicDecksViewModelTests: XCTestCase {
    func test_loadDecks_populatesCuratedDecks() async {
        let container = AppContainer.mock
        let sut = container.makeTopicDecksViewModel()

        XCTAssertTrue(sut.decks.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)

        await sut.loadDecks()

        XCTAssertEqual(sut.decks.count, 4)
        XCTAssertEqual(sut.decks.map(\.id), ["deck_daily", "deck_business", "deck_tech", "deck_academic"])
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_loadDecks_withFailingUseCase_setsErrorMessage() async {
        struct FailingUseCase: FetchTopicDecksUseCaseProtocol {
            func execute() async throws -> [TopicDeck] {
                throw NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch topic decks"])
            }
        }

        let sut = TopicDecksViewModel(fetchTopicDecksUseCase: FailingUseCase())
        await sut.loadDecks()

        XCTAssertTrue(sut.decks.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Failed to fetch topic decks")
    }
}
