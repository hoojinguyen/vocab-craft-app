import XCTest
import SwiftUI
@testable import VocabCraftApp

final class ColorTokensTests: XCTestCase {
    func testColorTokensExist() {
        XCTAssertNotNil(Color.vocabCanvas)
        XCTAssertNotNil(Color.vocabSurfaceSoft)
        XCTAssertNotNil(Color.vocabHeroTeal)
        XCTAssertNotNil(Color.vocabMint)
        XCTAssertNotNil(Color.vocabPeach)
        XCTAssertNotNil(Color.vocabLavender)
        XCTAssertNotNil(Color.vocabCoral)
        XCTAssertNotNil(Color.vocabInk)
    }

    func testColorHexInitializer() {
        let redColor = Color(hex: "#FF0000")
        XCTAssertNotNil(redColor)

        let greenWithoutHash = Color(hex: "00FF00")
        XCTAssertNotNil(greenWithoutHash)
    }
}
