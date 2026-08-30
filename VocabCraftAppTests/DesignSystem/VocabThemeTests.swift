import Foundation
import CraftUIKit
import SwiftUI
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class VocabThemeTests: XCTestCase {
    func testVocabColorTokensInitialization() {
        let tokens = VocabColorTokens()
        XCTAssertNotNil(tokens.canvasBackground)
        XCTAssertNotNil(tokens.surfaceCard)
        XCTAssertNotNil(tokens.surfaceElevated)
        XCTAssertNotNil(tokens.surfaceSubtle)
        XCTAssertNotNil(tokens.brandPrimary)
        XCTAssertNotNil(tokens.brandSecondary)
        XCTAssertNotNil(tokens.accent)
        XCTAssertNotNil(tokens.textPrimary)
        XCTAssertNotNil(tokens.textSecondary)
        XCTAssertNotNil(tokens.textMuted)
        XCTAssertNotNil(tokens.textInverse)
        XCTAssertNotNil(tokens.borderDefault)
        XCTAssertNotNil(tokens.borderFocus)
        XCTAssertNotNil(tokens.hairline)
        XCTAssertNotNil(tokens.statusSuccess)
        XCTAssertNotNil(tokens.statusWarning)
        XCTAssertNotNil(tokens.statusDanger)
        XCTAssertNotNil(tokens.statusInfo)
    }

    func testVocabGradientTokensInitialization() {
        let gradients = VocabGradientTokens()
        XCTAssertNotNil(gradients.brandHero)
        XCTAssertNotNil(gradients.surfaceGlass)
        XCTAssertNotNil(gradients.accentShine)
        XCTAssertNotNil(gradients.fadeBottom)
    }

    func testVocabThemeAggregatesAllTokens() {
        let theme = VocabTheme()
        XCTAssertNotNil(theme.colors)
        XCTAssertNotNil(theme.typography)
        XCTAssertNotNil(theme.spacing)
        XCTAssertNotNil(theme.radii)
        XCTAssertNotNil(theme.shadows)
        XCTAssertNotNil(theme.gradients)
        XCTAssertNotNil(theme.animations)
        XCTAssertNotNil(theme.depths)
    }

    func testVocabThemeCustomInitialization() {
        let customColors = VocabColorTokens(accent: .red)
        let theme = VocabTheme(colors: customColors)
        XCTAssertNotNil(theme.colors.accent)
    }

    func testCraftThemeViewModifierWithVocabTheme() {
        let view = Text("Hello").craftTheme(VocabTheme())
        XCTAssertNotNil(view)
    }
}
