import SwiftUI
@testable import VocabCraftApp
import XCTest

final class ColorTokensTests: XCTestCase {
    func testSemanticColorTokensExistAndInstantiate() {
        XCTAssertNotNil(Color.vocabCanvas)
        XCTAssertNotNil(Color.vocabSurfaceCard)
        XCTAssertNotNil(Color.vocabHeroTeal)
        XCTAssertNotNil(Color.vocabInk)
        XCTAssertNotNil(Color.vocabMuted)
        XCTAssertNotNil(Color.vocabHairline)
        XCTAssertNotNil(Color.vocabCoral)
        XCTAssertNotNil(Color.vocabMint)
        XCTAssertNotNil(Color.vocabPeach)
        XCTAssertNotNil(Color.vocabLavender)
    }

    func testColorHexInitializer() {
        let redColor = Color(hex: "#FF0000")
        XCTAssertNotNil(redColor)

        let greenWithoutHash = Color(hex: "00FF00")
        XCTAssertNotNil(greenWithoutHash)
    }

    func testSRSSparkleEffectViewLifecycle() {
        let binding = Binding.constant(true)
        let view = SRSSparkleEffectView(isEmitting: binding)
        XCTAssertNotNil(view.body)
    }
}
