import Foundation
import CraftUIKit
import SwiftUI
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

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
        for preset in CraftThemePreset.allCases {
            manager.setPreset(preset)
            XCTAssertEqual(manager.currentPreset, preset)
            XCTAssertNotNil(manager.currentPreset.theme)
            XCTAssertFalse(preset.displayName.isEmpty)
            XCTAssertFalse(preset.subtitle.isEmpty)
        }
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
