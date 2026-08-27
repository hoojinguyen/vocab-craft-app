import XCTest
import SwiftUI
@testable import CraftUIKit

final class ThemeTests: XCTestCase {
    func testDefaultThemeTokens() {
        let theme = CraftDefaultTheme()
        XCTAssertEqual(theme.spacing.base, 16)
        XCTAssertEqual(theme.radii.md, 12)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.colors.canvasBackground)
        XCTAssertEqual(theme.depths.depthSm, 2)
        XCTAssertEqual(theme.depths.depthMd, 4)
        XCTAssertEqual(theme.depths.depthLg, 6)
        XCTAssertNotNil(theme.depths.topHighlight)
    }

    func testCraftDefaultPaletteAntiSlopValues() {
        let colors = CraftDefaultColorTokens()
        XCTAssertEqual(colors.brandPrimary, Color(hex: 0xE06D3B))
        XCTAssertEqual(colors.brandSecondary, Color(hex: 0xD97706))
        XCTAssertEqual(colors.accent, Color(hex: 0xF59E0B))

        let gradients = CraftDefaultGradientTokens()
        XCTAssertNotNil(gradients.brandHero)
        XCTAssertNotNil(gradients.surfaceGlass)
    }

    func testCustomThemeOverrides() {
        struct CustomColors: CraftColorTokens {
            var canvasBackground: Color = .black
            var surfaceCard: Color = .gray
            var surfaceElevated: Color = .gray
            var surfaceSubtle: Color = .gray
            var brandPrimary: Color = .purple
            var brandSecondary: Color = .pink
            var accent: Color = .yellow
            var textPrimary: Color = .white
            var textSecondary: Color = .gray
            var textMuted: Color = .gray
            var textInverse: Color = .black
            var borderDefault: Color = .gray
            var borderFocus: Color = .purple
            var hairline: Color = .gray
            var statusSuccess: Color = .green
            var statusWarning: Color = .orange
            var statusDanger: Color = .red
            var statusInfo: Color = .blue
        }

        struct CustomTheme: CraftTheme {
            var colors: CraftColorTokens = CustomColors()
            var typography: CraftTypographyTokens = CraftDefaultTypographyTokens()
            var spacing: CraftSpacingTokens = CraftDefaultSpacingTokens()
            var radii: CraftRadiusTokens = CraftDefaultRadiusTokens()
            var shadows: CraftShadowTokens = CraftDefaultShadowTokens()
            var gradients: CraftGradientTokens = CraftDefaultGradientTokens()
            var animations: CraftAnimationTokens = CraftDefaultAnimationTokens()
            var opacities: CraftOpacityTokens = CraftDefaultOpacityTokens()
            var depths: CraftDepthTokens = CraftDefaultDepthTokens()
        }

        let customTheme = CustomTheme()
        XCTAssertEqual(customTheme.colors.brandPrimary, Color.purple)
        XCTAssertEqual(customTheme.colors.canvasBackground, Color.black)
        XCTAssertEqual(customTheme.depths.depthSm, 2)
    }

    func testDefaultColorTokensCompleteness() {
        let colors = CraftDefaultColorTokens()
        XCTAssertNotNil(colors.canvasBackground)
        XCTAssertNotNil(colors.surfaceCard)
        XCTAssertNotNil(colors.surfaceElevated)
        XCTAssertNotNil(colors.surfaceSubtle)
        XCTAssertNotNil(colors.brandPrimary)
        XCTAssertNotNil(colors.brandSecondary)
        XCTAssertNotNil(colors.accent)
        XCTAssertNotNil(colors.textPrimary)
        XCTAssertNotNil(colors.textSecondary)
        XCTAssertNotNil(colors.textMuted)
        XCTAssertNotNil(colors.textInverse)
        XCTAssertNotNil(colors.borderDefault)
        XCTAssertNotNil(colors.borderFocus)
        XCTAssertNotNil(colors.hairline)
        XCTAssertNotNil(colors.statusSuccess)
        XCTAssertNotNil(colors.statusWarning)
        XCTAssertNotNil(colors.statusDanger)
        XCTAssertNotNil(colors.statusInfo)
    }

    func testTypographyTokens() {
        let typography = CraftDefaultTypographyTokens()
        XCTAssertNotNil(typography.displayLarge)
        XCTAssertNotNil(typography.displayHero)
        XCTAssertNotNil(typography.displaySerif)
        XCTAssertNotNil(typography.titleLarge)
        XCTAssertNotNil(typography.titleMedium)
        XCTAssertNotNil(typography.headline)
        XCTAssertNotNil(typography.bodyLarge)
        XCTAssertNotNil(typography.bodyMedium)
        XCTAssertNotNil(typography.bodySerif)
        XCTAssertNotNil(typography.phonetic)
        XCTAssertNotNil(typography.metricRounded)
        XCTAssertNotNil(typography.label)
        XCTAssertNotNil(typography.caption)

        for style in CraftTypographyStyle.allCases {
            XCTAssertNotNil(typography.font(for: style))
        }
    }

    func testDynamicTypographyScaleTokens() {
        let typography = CraftDefaultTypographyTokens()
        _ = typography.displayLarge
        _ = typography.displayHero
        _ = typography.displaySerif
        _ = typography.titleLarge
        _ = typography.titleMedium
        _ = typography.headline
        _ = typography.bodyLarge
        _ = typography.bodyMedium
        _ = typography.bodySerif
        _ = typography.phonetic
        _ = typography.metricRounded
        _ = typography.label
        _ = typography.caption
        XCTAssertNotNil(typography.font(for: .displayLarge))
        XCTAssertNotNil(typography.font(for: .displayHero))
        XCTAssertNotNil(typography.font(for: .displaySerif))
        XCTAssertNotNil(typography.font(for: .titleLarge))
        XCTAssertNotNil(typography.font(for: .titleMedium))
        XCTAssertNotNil(typography.font(for: .headline))
        XCTAssertNotNil(typography.font(for: .bodyLarge))
        XCTAssertNotNil(typography.font(for: .bodyMedium))
        XCTAssertNotNil(typography.font(for: .bodySerif))
        XCTAssertNotNil(typography.font(for: .phonetic))
        XCTAssertNotNil(typography.font(for: .metricRounded))
        XCTAssertNotNil(typography.font(for: .label))
        XCTAssertNotNil(typography.font(for: .caption))
    }

    func testSpacingScaleTokens() {
        let spacing = CraftDefaultSpacingTokens()
        XCTAssertEqual(spacing.xs, 4)
        XCTAssertEqual(spacing.sm, 8)
        XCTAssertEqual(spacing.md, 12)
        XCTAssertEqual(spacing.base, 16)
        XCTAssertEqual(spacing.lg, 24)
        XCTAssertEqual(spacing.xl, 32)
        XCTAssertEqual(spacing.xxl, 48)
    }

    func testRadiusScaleTokens() {
        let radii = CraftDefaultRadiusTokens()
        XCTAssertEqual(radii.xs, 4)
        XCTAssertEqual(radii.sm, 8)
        XCTAssertEqual(radii.md, 12)
        XCTAssertEqual(radii.lg, 16)
        XCTAssertEqual(radii.xl, 24)
        XCTAssertEqual(radii.full, 9999)
    }

    func testShadowTokens() {
        let shadows = CraftDefaultShadowTokens()
        XCTAssertEqual(shadows.sm.radius, 4)
        XCTAssertEqual(shadows.md.radius, 8)
        XCTAssertEqual(shadows.lg.radius, 16)
        XCTAssertEqual(shadows.xl.radius, 24)

        let customShadow = CraftShadow(color: .red, radius: 10, x: 2, y: 4)
        XCTAssertEqual(customShadow.radius, 10)
        XCTAssertEqual(customShadow.x, 2)
        XCTAssertEqual(customShadow.y, 4)
    }

    func testGradientTokens() {
        let gradients = CraftDefaultGradientTokens()
        XCTAssertNotNil(gradients.brandHero)
        XCTAssertNotNil(gradients.surfaceGlass)
        XCTAssertNotNil(gradients.accentShine)
        XCTAssertNotNil(gradients.fadeBottom)
    }

    func testAnimationTokens() {
        let animations = CraftDefaultAnimationTokens()
        XCTAssertNotNil(animations.springSnappy)
        XCTAssertNotNil(animations.springSmooth)
        XCTAssertNotNil(animations.springBouncy)
    }

    func testEnvironmentInjection() {
        struct TestHostView: View {
            @Environment(\.craftTheme) var theme

            var body: some View {
                Text("Test")
                    .foregroundColor(theme.colors.brandPrimary)
                    .craftShadow(theme.shadows.md)
            }
        }

        let defaultHost = TestHostView()
        XCTAssertNotNil(defaultHost.body)

        let modifiedView = TestHostView().craftTheme(CraftDefaultTheme())
        XCTAssertNotNil(modifiedView)
    }

    func testThemePresetEnumCoverageAndInstantiation() {
        for preset in CraftThemePreset.allCases {
            let theme = preset.theme
            XCTAssertNotNil(theme.colors.canvasBackground)
            XCTAssertNotNil(theme.colors.brandPrimary)
            XCTAssertNotNil(theme.colors.surfaceCard)
            XCTAssertNotNil(theme.typography.titleLarge)
            XCTAssertNotNil(theme.gradients.brandHero)
            XCTAssertNotNil(theme.depths.depthSm)
            XCTAssertNotNil(theme.glass.tintOpacity)
            XCTAssertFalse(preset.displayName.isEmpty)
            XCTAssertFalse(preset.subtitle.isEmpty)
        }
    }

    func testEditorialThemeTokens() {
        let theme = CraftEditorialTheme()
        XCTAssertNotNil(theme.colors.canvasBackground)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.colors.accent)
        XCTAssertNotNil(theme.typography.displaySerif)
        XCTAssertNotNil(theme.gradients.brandHero)
        XCTAssertEqual(theme.spacing.base, 16)
        XCTAssertEqual(theme.radii.md, 12)
    }

    func testNeoArcadeThemeTokens() {
        let theme = CraftNeoArcadeTheme()
        XCTAssertNotNil(theme.colors.canvasBackground)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.colors.accent)
        XCTAssertNotNil(theme.typography.displayLarge)
        XCTAssertNotNil(theme.animations.springBouncy)
        XCTAssertNotNil(theme.gradients.streakLegendary)
    }

    func testNordicZenThemeTokens() {
        let theme = CraftNordicZenTheme()
        XCTAssertNotNil(theme.colors.canvasBackground)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.colors.accent)
        XCTAssertNotNil(theme.typography.headline)
        XCTAssertNotNil(theme.gradients.brandHero)
        XCTAssertNotNil(theme.depths.topHighlight)
    }

    func testKyotoMatchaThemeTokens() {
        let theme = CraftKyotoMatchaTheme()
        XCTAssertNotNil(theme.colors.canvasBackground)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.colors.accent)
        XCTAssertNotNil(theme.typography.displaySerif)
        XCTAssertNotNil(theme.gradients.brandHero)
    }

    func testAIAcousticThemeTokens() {
        let theme = CraftAIAcousticTheme()
        XCTAssertNotNil(theme.colors.canvasBackground)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.colors.accent)
        XCTAssertNotNil(theme.typography.phonetic)
        XCTAssertNotNil(theme.gradients.brandHero)
    }

    func testOxfordHeritageThemeTokens() {
        let theme = CraftOxfordHeritageTheme()
        XCTAssertNotNil(theme.colors.canvasBackground)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.colors.accent)
        XCTAssertNotNil(theme.typography.displaySerif)
        XCTAssertNotNil(theme.gradients.streakLegendary)
    }

    func testSolarMomentumThemeTokens() {
        let theme = CraftSolarMomentumTheme()
        XCTAssertNotNil(theme.colors.canvasBackground)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.colors.accent)
        XCTAssertNotNil(theme.typography.metricRounded)
        XCTAssertNotNil(theme.gradients.brandHero)
    }

    func testTactileClayThemeTokens() {
        let theme = CraftTactileClayTheme()
        XCTAssertNotNil(theme.colors.canvasBackground)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.colors.accent)
        XCTAssertNotNil(theme.typography.headline)
        XCTAssertNotNil(theme.gradients.brandHero)
    }
}


