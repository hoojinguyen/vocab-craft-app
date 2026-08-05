import XCTest
import SwiftUI
@testable import VocabCraftApp

@MainActor
final class ReflexDrillViewTests: XCTestCase {
    func testReflexDrillViewInitializationWithoutEngine() {
        let view = ReflexDrillView(datasetEngine: nil, cefrLevel: "B1")
        XCTAssertNotNil(view)
    }

    func testReflexDrillViewInitializationWithCEFRLevel() {
        let view = ReflexDrillView(datasetEngine: nil, cefrLevel: "C1")
        XCTAssertNotNil(view)
    }

    func testSRSSparkleEffectViewInstantiation() {
        var isEmitting = true
        let binding = Binding(get: { isEmitting }, set: { isEmitting = $0 })
        let view = SRSSparkleEffectView(isEmitting: binding)
        XCTAssertNotNil(view)
    }
}
