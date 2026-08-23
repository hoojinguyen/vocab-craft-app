import XCTest
import SwiftUI
@testable import CraftUIKit

final class TokenTests: XCTestCase {
    func testStreakColorAndGradientTokens() {
        let theme = CraftDefaultTheme()
        XCTAssertNotNil(theme.colors.streakFreeze)
        XCTAssertNotNil(theme.colors.streakPending)
        XCTAssertNotNil(theme.colors.streakGlow)
        XCTAssertNotNil(theme.gradients.streakStarter)
        XCTAssertNotNil(theme.gradients.streakBlaze)
        XCTAssertNotNil(theme.gradients.streakLegendary)
    }

    func testDefaultStreakColorValues() {
        let colors = CraftDefaultColorTokens()
        XCTAssertEqual(colors.streakFreeze, Color(hex: 0x38BDF8))
        XCTAssertEqual(colors.streakPending, Color(hex: 0x94A3B8))
        XCTAssertEqual(colors.streakGlow, Color(hex: 0xF59E0B).opacity(0.35))
    }

    func testDefaultStreakGradientTokens() {
        let gradients = CraftDefaultGradientTokens()
        XCTAssertNotNil(gradients.streakStarter)
        XCTAssertNotNil(gradients.streakBlaze)
        XCTAssertNotNil(gradients.streakLegendary)
    }
}
