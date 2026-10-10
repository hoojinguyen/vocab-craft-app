@testable import VocabCraftApp
import XCTest

final class VocabularyDataSourceProtocolTests: XCTestCase {
    func testDefaultLearningPathProtocolExtensions() async throws {
        let mock = MockVocabularyDataSource()
        let paths = try await mock.fetchLearningPaths()
        XCTAssertFalse(paths.isEmpty)
        XCTAssertEqual(paths.first?.code, "essential-english-mastery")

        let decks = try await mock.fetchTopicDecks(for: "essential-english-mastery")
        XCTAssertEqual(decks.count, mock.decks.count)
    }
}
