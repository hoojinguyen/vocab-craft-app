#if canImport(XCTest)
import XCTest
#endif
import SwiftUI
@testable import CraftUIKit

final class TokenTests: XCTestCase {
    func testStreakColorAndGradientTokens() {
        let theme = CraftDefaultTheme()
        XCTAssertNotNil(theme.colors.streakStarter)
        XCTAssertNotNil(theme.colors.streakBlaze)
        XCTAssertNotNil(theme.colors.streakLegendary)
        XCTAssertNotNil(theme.colors.streakFreeze)
        XCTAssertNotNil(theme.colors.streakPending)
        XCTAssertNotNil(theme.colors.streakGlow)
        XCTAssertNotNil(theme.gradients.streakStarter)
        XCTAssertNotNil(theme.gradients.streakBlaze)
        XCTAssertNotNil(theme.gradients.streakLegendary)
    }

    func testDefaultStreakColorValues() {
        let colors = CraftDefaultColorTokens()
        XCTAssertNotNil(colors.streakStarter)
        XCTAssertNotNil(colors.streakBlaze)
        XCTAssertNotNil(colors.streakLegendary)
        XCTAssertNotNil(colors.streakFreeze)
        XCTAssertNotNil(colors.streakPending)
        XCTAssertNotNil(colors.streakGlow)
    }

    func testDefaultStreakGradientTokens() {
        let gradients = CraftDefaultGradientTokens()
        XCTAssertNotNil(gradients.streakStarter)
        XCTAssertNotNil(gradients.streakBlaze)
        XCTAssertNotNil(gradients.streakLegendary)
    }

    func testLearningPathColorTokens() {
        let colors = CraftDefaultColorTokens()
        XCTAssertNotNil(colors.pathCompleted)
        XCTAssertNotNil(colors.pathActive)
        XCTAssertNotNil(colors.pathUpcoming)
        XCTAssertNotNil(colors.pathLocked)
        XCTAssertNotNil(colors.pathHaloGlow)
    }

    func testLearningPathSpacingTokens() {
        let spacing = CraftDefaultSpacingTokens()
        XCTAssertEqual(spacing.pathDotDiameter, 5.5)
        XCTAssertEqual(spacing.pathDotSpacing, 6.0)
        XCTAssertEqual(spacing.pathTurnRadius, 32.0)
        XCTAssertEqual(spacing.pathEdgeInset, 16.0)
        XCTAssertEqual(spacing.pathRowSpacing, 44.0)
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
        XCTAssertEqual(customSpacing.pathDotDiameter, 5.5)
        XCTAssertEqual(customSpacing.pathDotSpacing, 6.0)
        XCTAssertEqual(customSpacing.pathTurnRadius, 32.0)
        XCTAssertEqual(customSpacing.pathEdgeInset, 16.0)
        XCTAssertEqual(customSpacing.pathRowSpacing, 44.0)
    }

    func testLearningPathTokensInTheme() {
        let theme = CraftDefaultTheme()
        XCTAssertNotNil(theme.colors.pathCompleted)
        XCTAssertNotNil(theme.colors.pathActive)
        XCTAssertNotNil(theme.colors.pathUpcoming)
        XCTAssertNotNil(theme.colors.pathLocked)
        XCTAssertNotNil(theme.colors.pathHaloGlow)
        XCTAssertEqual(theme.spacing.pathDotDiameter, 5.5)
        XCTAssertEqual(theme.spacing.pathDotSpacing, 6.0)
        XCTAssertEqual(theme.spacing.pathTurnRadius, 32.0)
        XCTAssertEqual(theme.spacing.pathEdgeInset, 16.0)
        XCTAssertEqual(theme.spacing.pathRowSpacing, 44.0)
    }

    func testDepthTokens() {
        let depths = CraftDefaultDepthTokens()
        XCTAssertEqual(depths.depthSm, 2)
        XCTAssertEqual(depths.depthMd, 4)
        XCTAssertEqual(depths.depthLg, 6)
        XCTAssertNotNil(depths.topHighlight)
    }

    func testCustomDepthTokens() {
        struct CustomDepths: CraftDepthTokens {
            var depthSm: CGFloat = 3
            var depthMd: CGFloat = 5
            var depthLg: CGFloat = 7
            var topHighlight: LinearGradient = LinearGradient(
                colors: [.white, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        let custom = CustomDepths()
        XCTAssertEqual(custom.depthSm, 3)
        XCTAssertEqual(custom.depthMd, 5)
        XCTAssertEqual(custom.depthLg, 7)
        XCTAssertNotNil(custom.topHighlight)
    }

    func testDepthTokensInTheme() {
        let theme = CraftDefaultTheme()
        XCTAssertEqual(theme.depths.depthSm, 2)
        XCTAssertEqual(theme.depths.depthMd, 4)
        XCTAssertEqual(theme.depths.depthLg, 6)
        XCTAssertNotNil(theme.depths.topHighlight)
    }

    func testExpandedAnimationTokens() {
        let tokens = CraftDefaultAnimationTokens()
        _ = tokens.springSnappy
        _ = tokens.springSmooth
        _ = tokens.springBouncy
        _ = tokens.springGentle
        _ = tokens.springInteractive
    }

    func testAnimationTokensProtocolExtensionDefaults() {
        struct MinimalAnimationTokens: CraftAnimationTokens {
            var springSnappy: Animation = .default
            var springSmooth: Animation = .default
            var springBouncy: Animation = .default
        }

        let tokens = MinimalAnimationTokens()
        _ = tokens.springSnappy
        _ = tokens.springSmooth
        _ = tokens.springBouncy
        _ = tokens.springGentle
        _ = tokens.springInteractive
    }

    func testCraftMotionGuardModifier() {
        let modifier = CraftMotionGuardModifier(animation: .default, value: 42)
        XCTAssertEqual(modifier.value, 42)
        XCTAssertEqual(modifier.animation, .default)

        let view = Text("Test").craftAnimation(.spring, value: 1)
        XCTAssertNotNil(view)
    }
}


