import CraftUIKit
import Foundation
import SwiftUI
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class ColorTokensTests: XCTestCase {
    func testVocabColorTokensInstantiation() {
        let tokens = VocabColorTokens()
        XCTAssertNotNil(tokens.canvasBackground)
        XCTAssertNotNil(tokens.surfaceCard)
        XCTAssertNotNil(tokens.brandPrimary)
        XCTAssertNotNil(tokens.brandSecondary)
        XCTAssertNotNil(tokens.accent)
        XCTAssertNotNil(tokens.textPrimary)
        XCTAssertNotNil(tokens.textSecondary)
        XCTAssertNotNil(tokens.textMuted)
        XCTAssertNotNil(tokens.textInverse)
        XCTAssertNotNil(tokens.borderDefault)
        XCTAssertNotNil(tokens.statusSuccess)
        XCTAssertNotNil(tokens.statusWarning)
        XCTAssertNotNil(tokens.statusDanger)
        XCTAssertNotNil(tokens.statusInfo)
    }

    func testVocabThemeInstantiation() {
        let theme = VocabTheme()
        XCTAssertNotNil(theme.colors)
        XCTAssertNotNil(theme.typography)
        XCTAssertNotNil(theme.spacing)
        XCTAssertNotNil(theme.radii)
        XCTAssertNotNil(theme.shadows)
        XCTAssertNotNil(theme.gradients)
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
