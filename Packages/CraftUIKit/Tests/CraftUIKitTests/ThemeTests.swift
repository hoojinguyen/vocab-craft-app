import XCTest
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
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
        XCTAssertNotNil(colors.brandPrimary)
        XCTAssertNotNil(colors.brandSecondary)
        XCTAssertNotNil(colors.accent)

        let gradients = CraftDefaultGradientTokens()
        XCTAssertNotNil(gradients.brandHero)
        XCTAssertNotNil(gradients.surfaceGlass)
    }

    func testAllNineThemePresetsHaveFullDynamicTokens() {
        for preset in CraftThemePreset.allCases {
            let theme = preset.theme
            let colors = theme.colors

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
            XCTAssertNotNil(colors.streakStarter)
            XCTAssertNotNil(colors.streakBlaze)
            XCTAssertNotNil(colors.streakLegendary)
            XCTAssertNotNil(colors.streakFreeze)
            XCTAssertNotNil(colors.streakPending)
            XCTAssertNotNil(colors.streakGlow)
            XCTAssertNotNil(colors.pathCompleted)
            XCTAssertNotNil(colors.pathActive)
            XCTAssertNotNil(colors.pathUpcoming)
            XCTAssertNotNil(colors.pathLocked)
            XCTAssertNotNil(colors.pathHaloGlow)
        }
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

    func testCraftAppearanceModeMapping() {
        XCTAssertNil(CraftAppearanceMode.system.colorScheme)
        XCTAssertEqual(CraftAppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(CraftAppearanceMode.dark.colorScheme, .dark)
    }

    func testCraftThemeManagerAppearanceModePersistence() {
        let manager = CraftThemeManager()
        manager.setAppearanceMode(.dark)
        XCTAssertEqual(manager.appearanceMode, .dark)
        XCTAssertEqual(manager.preferredColorScheme, .dark)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "app_appearance_mode"), "dark")

        manager.setAppearanceMode(.light)
        XCTAssertEqual(manager.appearanceMode, .light)
        XCTAssertEqual(manager.preferredColorScheme, .light)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "app_appearance_mode"), "light")

        manager.setAppearanceMode(.system)
        XCTAssertEqual(manager.appearanceMode, .system)
        XCTAssertNil(manager.preferredColorScheme)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "app_appearance_mode"), "system")
    }

    func testDynamicColorResolutionWithTraits() {
        let colors = CraftDefaultColorTokens()

        #if os(iOS)
        let lightTrait = UITraitCollection(userInterfaceStyle: .light)
        let darkTrait = UITraitCollection(userInterfaceStyle: .dark)

        // Canvas Background
        let canvasUI = UIColor(colors.canvasBackground)
        let lightCanvas = canvasUI.resolvedColor(with: lightTrait)
        let darkCanvas = canvasUI.resolvedColor(with: darkTrait)
        XCTAssertNotEqual(lightCanvas, darkCanvas, "Canvas background must adapt between light and dark modes")

        // Surface Card
        let surfaceUI = UIColor(colors.surfaceCard)
        let lightSurface = surfaceUI.resolvedColor(with: lightTrait)
        let darkSurface = surfaceUI.resolvedColor(with: darkTrait)
        XCTAssertNotEqual(lightSurface, darkSurface, "Surface card must adapt between light and dark modes")

        // Text Primary
        let textUI = UIColor(colors.textPrimary)
        let lightText = textUI.resolvedColor(with: lightTrait)
        let darkText = textUI.resolvedColor(with: darkTrait)
        XCTAssertNotEqual(lightText, darkText, "Text primary must adapt between light and dark modes")

        // Brand Primary
        let brandUI = UIColor(colors.brandPrimary)
        let lightBrand = brandUI.resolvedColor(with: lightTrait)
        let darkBrand = brandUI.resolvedColor(with: darkTrait)
        XCTAssertNotEqual(lightBrand, darkBrand, "Brand primary must adapt between light and dark modes")

        // Border Focus
        let borderFocusUI = UIColor(colors.borderFocus)
        let lightBorderFocus = borderFocusUI.resolvedColor(with: lightTrait)
        let darkBorderFocus = borderFocusUI.resolvedColor(with: darkTrait)
        XCTAssertNotEqual(lightBorderFocus, darkBorderFocus, "Border focus must adapt between light and dark modes")

        // Status Colors
        let successUI = UIColor(colors.statusSuccess)
        let warningUI = UIColor(colors.statusWarning)
        let dangerUI = UIColor(colors.statusDanger)
        let infoUI = UIColor(colors.statusInfo)
        XCTAssertNotEqual(successUI.resolvedColor(with: lightTrait), successUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(warningUI.resolvedColor(with: lightTrait), warningUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(dangerUI.resolvedColor(with: lightTrait), dangerUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(infoUI.resolvedColor(with: lightTrait), infoUI.resolvedColor(with: darkTrait))

        // Streak Colors
        let streakStarterUI = UIColor(colors.streakStarter)
        let streakBlazeUI = UIColor(colors.streakBlaze)
        let streakLegendaryUI = UIColor(colors.streakLegendary)
        let streakFreezeUI = UIColor(colors.streakFreeze)
        let streakPendingUI = UIColor(colors.streakPending)
        let streakGlowUI = UIColor(colors.streakGlow)
        XCTAssertNotEqual(streakStarterUI.resolvedColor(with: lightTrait), streakStarterUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(streakBlazeUI.resolvedColor(with: lightTrait), streakBlazeUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(streakLegendaryUI.resolvedColor(with: lightTrait), streakLegendaryUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(streakFreezeUI.resolvedColor(with: lightTrait), streakFreezeUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(streakPendingUI.resolvedColor(with: lightTrait), streakPendingUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(streakGlowUI.resolvedColor(with: lightTrait), streakGlowUI.resolvedColor(with: darkTrait))

        // Learning Path Colors
        let pathCompletedUI = UIColor(colors.pathCompleted)
        let pathActiveUI = UIColor(colors.pathActive)
        let pathUpcomingUI = UIColor(colors.pathUpcoming)
        let pathLockedUI = UIColor(colors.pathLocked)
        let pathHaloGlowUI = UIColor(colors.pathHaloGlow)
        XCTAssertNotEqual(pathCompletedUI.resolvedColor(with: lightTrait), pathCompletedUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(pathActiveUI.resolvedColor(with: lightTrait), pathActiveUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(pathUpcomingUI.resolvedColor(with: lightTrait), pathUpcomingUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(pathLockedUI.resolvedColor(with: lightTrait), pathLockedUI.resolvedColor(with: darkTrait))
        XCTAssertNotEqual(pathHaloGlowUI.resolvedColor(with: lightTrait), pathHaloGlowUI.resolvedColor(with: darkTrait))

        #elseif os(macOS)
        guard let lightApp = NSAppearance(named: .aqua),
              let darkApp = NSAppearance(named: .darkAqua) else {
            XCTFail("Could not load NSAppearance")
            return
        }

        func resolveMacColor(_ color: Color) -> (light: NSColor, dark: NSColor) {
            let nsColor = NSColor(color)
            var light = nsColor
            var dark = nsColor
            lightApp.performAsCurrentDrawingAppearance {
                light = nsColor.usingColorSpace(.sRGB) ?? nsColor
            }
            darkApp.performAsCurrentDrawingAppearance {
                dark = nsColor.usingColorSpace(.sRGB) ?? nsColor
            }
            return (light, dark)
        }

        let (lightCanvas, darkCanvas) = resolveMacColor(colors.canvasBackground)
        XCTAssertNotEqual(lightCanvas, darkCanvas)

        let (lightSurface, darkSurface) = resolveMacColor(colors.surfaceCard)
        XCTAssertNotEqual(lightSurface, darkSurface)

        let (lightText, darkText) = resolveMacColor(colors.textPrimary)
        XCTAssertNotEqual(lightText, darkText)

        let (lightBrand, darkBrand) = resolveMacColor(colors.brandPrimary)
        XCTAssertNotEqual(lightBrand, darkBrand)

        let (lightBorderFocus, darkBorderFocus) = resolveMacColor(colors.borderFocus)
        XCTAssertNotEqual(lightBorderFocus, darkBorderFocus)

        let (lightSuccess, darkSuccess) = resolveMacColor(colors.statusSuccess)
        let (lightWarning, darkWarning) = resolveMacColor(colors.statusWarning)
        let (lightDanger, darkDanger) = resolveMacColor(colors.statusDanger)
        let (lightInfo, darkInfo) = resolveMacColor(colors.statusInfo)
        XCTAssertNotEqual(lightSuccess, darkSuccess)
        XCTAssertNotEqual(lightWarning, darkWarning)
        XCTAssertNotEqual(lightDanger, darkDanger)
        XCTAssertNotEqual(lightInfo, darkInfo)

        let (lightStreakStarter, darkStreakStarter) = resolveMacColor(colors.streakStarter)
        let (lightStreakBlaze, darkStreakBlaze) = resolveMacColor(colors.streakBlaze)
        let (lightStreakLegendary, darkStreakLegendary) = resolveMacColor(colors.streakLegendary)
        let (lightStreakFreeze, darkStreakFreeze) = resolveMacColor(colors.streakFreeze)
        let (lightStreakPending, darkStreakPending) = resolveMacColor(colors.streakPending)
        let (lightStreakGlow, darkStreakGlow) = resolveMacColor(colors.streakGlow)
        XCTAssertNotEqual(lightStreakStarter, darkStreakStarter)
        XCTAssertNotEqual(lightStreakBlaze, darkStreakBlaze)
        XCTAssertNotEqual(lightStreakLegendary, darkStreakLegendary)
        XCTAssertNotEqual(lightStreakFreeze, darkStreakFreeze)
        XCTAssertNotEqual(lightStreakPending, darkStreakPending)
        XCTAssertNotEqual(lightStreakGlow, darkStreakGlow)

        let (lightPathCompleted, darkPathCompleted) = resolveMacColor(colors.pathCompleted)
        let (lightPathActive, darkPathActive) = resolveMacColor(colors.pathActive)
        let (lightPathUpcoming, darkPathUpcoming) = resolveMacColor(colors.pathUpcoming)
        let (lightPathLocked, darkPathLocked) = resolveMacColor(colors.pathLocked)
        let (lightPathHaloGlow, darkPathHaloGlow) = resolveMacColor(colors.pathHaloGlow)
        XCTAssertNotEqual(lightPathCompleted, darkPathCompleted)
        XCTAssertNotEqual(lightPathActive, darkPathActive)
        XCTAssertNotEqual(lightPathUpcoming, darkPathUpcoming)
        XCTAssertNotEqual(lightPathLocked, darkPathLocked)
        XCTAssertNotEqual(lightPathHaloGlow, darkPathHaloGlow)
        #endif
    }

    func testAllPresetsDynamicResolutionWithTraits() {
        for preset in CraftThemePreset.allCases {
            let colors = preset.theme.colors

            #if os(iOS)
            let lightTrait = UITraitCollection(userInterfaceStyle: .light)
            let darkTrait = UITraitCollection(userInterfaceStyle: .dark)

            let canvasUI = UIColor(colors.canvasBackground)
            XCTAssertNotEqual(
                canvasUI.resolvedColor(with: lightTrait),
                canvasUI.resolvedColor(with: darkTrait),
                "Preset \(preset) canvasBackground must adapt"
            )

            let surfaceUI = UIColor(colors.surfaceCard)
            XCTAssertNotEqual(
                surfaceUI.resolvedColor(with: lightTrait),
                surfaceUI.resolvedColor(with: darkTrait),
                "Preset \(preset) surfaceCard must adapt"
            )

            let textUI = UIColor(colors.textPrimary)
            XCTAssertNotEqual(
                textUI.resolvedColor(with: lightTrait),
                textUI.resolvedColor(with: darkTrait),
                "Preset \(preset) textPrimary must adapt"
            )

            let brandUI = UIColor(colors.brandPrimary)
            XCTAssertNotEqual(
                brandUI.resolvedColor(with: lightTrait),
                brandUI.resolvedColor(with: darkTrait),
                "Preset \(preset) brandPrimary must adapt"
            )

            let successUI = UIColor(colors.statusSuccess)
            XCTAssertNotEqual(
                successUI.resolvedColor(with: lightTrait),
                successUI.resolvedColor(with: darkTrait),
                "Preset \(preset) statusSuccess must adapt"
            )

            let borderFocusUI = UIColor(colors.borderFocus)
            XCTAssertNotEqual(
                borderFocusUI.resolvedColor(with: lightTrait),
                borderFocusUI.resolvedColor(with: darkTrait),
                "Preset \(preset) borderFocus must adapt"
            )
            #elseif os(macOS)
            guard let lightApp = NSAppearance(named: .aqua),
                  let darkApp = NSAppearance(named: .darkAqua) else { continue }

            func resolve(_ color: Color) -> (NSColor, NSColor) {
                let ns = NSColor(color)
                var l = ns, d = ns
                lightApp.performAsCurrentDrawingAppearance { l = ns.usingColorSpace(.sRGB) ?? ns }
                darkApp.performAsCurrentDrawingAppearance { d = ns.usingColorSpace(.sRGB) ?? ns }
                return (l, d)
            }

            let (lc, dc) = resolve(colors.canvasBackground)
            XCTAssertNotEqual(lc, dc, "Preset \(preset) canvasBackground must adapt")

            let (ls, ds) = resolve(colors.surfaceCard)
            XCTAssertNotEqual(ls, ds, "Preset \(preset) surfaceCard must adapt")

            let (lt, dt) = resolve(colors.textPrimary)
            XCTAssertNotEqual(lt, dt, "Preset \(preset) textPrimary must adapt")

            let (lb, db) = resolve(colors.brandPrimary)
            XCTAssertNotEqual(lb, db, "Preset \(preset) brandPrimary must adapt")

            let (lsucc, dsucc) = resolve(colors.statusSuccess)
            XCTAssertNotEqual(lsucc, dsucc, "Preset \(preset) statusSuccess must adapt")

            let (lbf, dbf) = resolve(colors.borderFocus)
            XCTAssertNotEqual(lbf, dbf, "Preset \(preset) borderFocus must adapt")
            #endif
        }
    }
}


