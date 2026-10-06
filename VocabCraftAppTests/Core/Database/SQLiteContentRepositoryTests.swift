@testable import VocabCraftApp
import XCTest

final class SQLiteContentRepositoryTests: XCTestCase {
    func testInitializationThrowsOnMissingFile() {
        let missingURL = FileManager.default.temporaryDirectory.appendingPathComponent("missing.sqlite")
        XCTAssertThrowsError(try SQLiteContentRepository(url: missingURL))
    }
}
