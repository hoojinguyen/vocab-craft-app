import XCTest
import SwiftUI
@testable import VocabCraftApp

final class ReflexDrillViewTests: XCTestCase {
    func testReflexDrillViewInitializationWithoutEngine() {
        let view = ReflexDrillView(datasetEngine: nil, cefrLevel: "B1")
        XCTAssertNotNil(view)
    }

    func testReflexDrillViewInitializationWithCEFRLevel() {
        let view = ReflexDrillView(datasetEngine: nil, cefrLevel: "C1")
        XCTAssertNotNil(view)
    }
}
