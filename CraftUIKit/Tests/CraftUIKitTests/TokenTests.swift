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

    func testLearningPathColorTokens() {
        let colors = CraftDefaultColorTokens()
        XCTAssertEqual(colors.pathCompleted, Color(hex: 0x10B981))
        XCTAssertEqual(colors.pathActive, Color(hex: 0xE06D3B))
        XCTAssertNotNil(colors.pathUpcoming)
        XCTAssertNotNil(colors.pathLocked)
        XCTAssertEqual(colors.pathHaloGlow, Color(hex: 0xE06D3B).opacity(0.20))
    }

    func testLearningPathSpacingTokens() {
        let spacing = CraftDefaultSpacingTokens()
        XCTAssertEqual(spacing.pathDotDiameter, 4.5)
        XCTAssertEqual(spacing.pathDotSpacing, 8.0)
        XCTAssertEqual(spacing.pathTurnRadius, 36.0)
        XCTAssertEqual(spacing.pathEdgeInset, 24.0)
        XCTAssertEqual(spacing.pathRowSpacing, 64.0)
    }

    func testLearningPathProtocolExtensionDefaults() {
        struct CustomColors: CraftColorTokens {
            var canvasBackground: Color = .clear
            var surfaceCard: Color = .clear
            var surfaceElevated: Color = .clear
            var surfaceSubtle: Color = .clear
            var brandPrimary: Color = Color(hex: 0x123456)
            var brandSecondary: Color = .clear
            var accent: Color = .clear
            var textPrimary: Color = .clear
            var textSecondary: Color = .clear
            var textMuted: Color = .clear
            var textInverse: Color = .clear
            var borderDefault: Color = .clear
            var borderFocus: Color = .clear
            var hairline: Color = .clear
            var statusSuccess: Color = Color(hex: 0x654321)
            var statusWarning: Color = .clear
            var statusDanger: Color = .clear
            var statusInfo: Color = .clear
        }

        struct CustomSpacing: CraftSpacingTokens {
            var xs: CGFloat = 4
            var sm: CGFloat = 8
            var md: CGFloat = 12
            var base: CGFloat = 16
            var lg: CGFloat = 24
            var xl: CGFloat = 32
            var xxl: CGFloat = 48
        }

        let customColors = CustomColors()
        XCTAssertEqual(customColors.pathCompleted, Color(hex: 0x654321))
        XCTAssertEqual(customColors.pathActive, Color(hex: 0x123456))
        XCTAssertNotNil(customColors.pathUpcoming)
        XCTAssertNotNil(customColors.pathLocked)
        XCTAssertEqual(customColors.pathHaloGlow, Color(hex: 0x123456).opacity(0.20))

        let customSpacing = CustomSpacing()
        XCTAssertEqual(customSpacing.pathDotDiameter, 4.5)
        XCTAssertEqual(customSpacing.pathDotSpacing, 8.0)
        XCTAssertEqual(customSpacing.pathTurnRadius, 36.0)
        XCTAssertEqual(customSpacing.pathEdgeInset, 24.0)
        XCTAssertEqual(customSpacing.pathRowSpacing, 64.0)
    }

    func testLearningPathTokensInTheme() {
        let theme = CraftDefaultTheme()
        XCTAssertNotNil(theme.colors.pathCompleted)
        XCTAssertNotNil(theme.colors.pathActive)
        XCTAssertNotNil(theme.colors.pathUpcoming)
        XCTAssertNotNil(theme.colors.pathLocked)
        XCTAssertNotNil(theme.colors.pathHaloGlow)
        XCTAssertEqual(theme.spacing.pathDotDiameter, 4.5)
        XCTAssertEqual(theme.spacing.pathDotSpacing, 8.0)
        XCTAssertEqual(theme.spacing.pathTurnRadius, 36.0)
        XCTAssertEqual(theme.spacing.pathEdgeInset, 24.0)
        XCTAssertEqual(theme.spacing.pathRowSpacing, 64.0)
    }
}

