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

    func testAppThemeManagerPresetSwitching() {
        let manager = AppThemeManager.shared
        manager.setPreset(.editorial)
        XCTAssertEqual(manager.currentPreset, .editorial)
        XCTAssertNotNil(manager.currentPreset.theme)

        manager.setPreset(.neoArcade)
        XCTAssertEqual(manager.currentPreset, .neoArcade)
        XCTAssertNotNil(manager.currentPreset.theme)

        manager.setPreset(.nordicZen)
        XCTAssertEqual(manager.currentPreset, .nordicZen)
        XCTAssertNotNil(manager.currentPreset.theme)

        manager.setPreset(.classic)
        XCTAssertEqual(manager.currentPreset, .classic)
        XCTAssertNotNil(manager.currentPreset.theme)
    }

    func testAppThemeManagerColorSchemeSwitching() {
        let manager = AppThemeManager.shared
        manager.setColorScheme(.dark)
        XCTAssertEqual(manager.preferredColorScheme, .dark)

        manager.setColorScheme(.light)
        XCTAssertEqual(manager.preferredColorScheme, .light)

        manager.setColorScheme(nil)
        XCTAssertNil(manager.preferredColorScheme)
    }
}

