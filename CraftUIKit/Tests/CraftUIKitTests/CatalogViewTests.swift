import XCTest
import SwiftUI
@testable import CraftUIKit

final class CatalogViewTests: XCTestCase {
    func testCatalogThemeTypeEnumCases() {
        XCTAssertEqual(CatalogThemeType.allCases.count, 2)
        XCTAssertEqual(CatalogThemeType.defaultSlate.rawValue, "Default Slate")
        XCTAssertEqual(CatalogThemeType.emeraldTeal.rawValue, "Emerald Teal")
        XCTAssertEqual(CatalogThemeType.defaultSlate.id, "Default Slate")
        XCTAssertEqual(CatalogThemeType.emeraldTeal.id, "Emerald Teal")

        let slateTheme = CatalogThemeType.defaultSlate.theme
        XCTAssertNotNil(slateTheme)

        let emeraldTheme = CatalogThemeType.emeraldTeal.theme
        XCTAssertNotNil(emeraldTheme)
        XCTAssertEqual(emeraldTheme.colors.brandPrimary, Color(hex: 0x10B981))
    }

    func testCatalogColorSchemeEnumCases() {
        XCTAssertEqual(CatalogColorScheme.allCases.count, 3)
        XCTAssertEqual(CatalogColorScheme.system.id, "System")
        XCTAssertEqual(CatalogColorScheme.light.id, "Light")
        XCTAssertEqual(CatalogColorScheme.dark.id, "Dark")

        XCTAssertNil(CatalogColorScheme.system.colorScheme)
        XCTAssertEqual(CatalogColorScheme.light.colorScheme, .light)
        XCTAssertEqual(CatalogColorScheme.dark.colorScheme, .dark)
    }

    func testCatalogTabItemConformances() {
        XCTAssertEqual(CatalogTabItem.allCases.count, 4)
        XCTAssertEqual(CatalogTabItem.home.id, "Home")
        XCTAssertEqual(CatalogTabItem.home.title, "Home")
        XCTAssertEqual(CatalogTabItem.home.symbol, "house")

        XCTAssertEqual(CatalogTabItem.study.id, "Study")
        XCTAssertEqual(CatalogTabItem.study.title, "Study")
        XCTAssertEqual(CatalogTabItem.study.symbol, "character.book.closed")

        XCTAssertEqual(CatalogTabItem.practice.id, "Practice")
        XCTAssertEqual(CatalogTabItem.practice.title, "Practice")
        XCTAssertEqual(CatalogTabItem.practice.symbol, "bolt.fill")

        XCTAssertEqual(CatalogTabItem.profile.id, "Profile")
        XCTAssertEqual(CatalogTabItem.profile.title, "Profile")
        XCTAssertEqual(CatalogTabItem.profile.symbol, "person.crop.circle")
    }

    func testCatalogEmptyStatePresetProperties() {
        XCTAssertEqual(CatalogEmptyStatePreset.allCases.count, 3)
        XCTAssertEqual(CatalogEmptyStatePreset.study.id, "Study Cards")
        XCTAssertEqual(CatalogEmptyStatePreset.study.symbol, .study)
        XCTAssertEqual(CatalogEmptyStatePreset.study.title, "No Study Cards")
        XCTAssertEqual(CatalogEmptyStatePreset.study.buttonTitle, "Add Word")
        XCTAssertEqual(CatalogEmptyStatePreset.study.buttonSymbol, .add)

        XCTAssertEqual(CatalogEmptyStatePreset.search.symbol, .search)
        XCTAssertEqual(CatalogEmptyStatePreset.search.title, "No Results Found")
        XCTAssertEqual(CatalogEmptyStatePreset.search.buttonSymbol, .clear)

        XCTAssertEqual(CatalogEmptyStatePreset.bookmark.symbol, .bookmark)
        XCTAssertEqual(CatalogEmptyStatePreset.bookmark.title, "No Bookmarks Saved")
        XCTAssertEqual(CatalogEmptyStatePreset.bookmark.buttonSymbol, .list)
    }

    func testCatalogStreakTierPresetProperties() {
        XCTAssertEqual(CatalogStreakTierPreset.allCases.count, 3)

        let starter = CatalogStreakTierPreset.starter
        XCTAssertEqual(starter.id, "Starter (3d)")
        XCTAssertEqual(starter.days, 3)
        XCTAssertEqual(starter.tier, .starter)
        XCTAssertEqual(starter.bestStreak, 7)
        XCTAssertEqual(starter.nextMilestone, 7)

        let blaze = CatalogStreakTierPreset.blaze
        XCTAssertEqual(blaze.id, "Blaze (14d)")
        XCTAssertEqual(blaze.days, 14)
        XCTAssertEqual(blaze.tier, .blaze)
        XCTAssertEqual(blaze.bestStreak, 30)
        XCTAssertEqual(blaze.nextMilestone, 21)

        let legendary = CatalogStreakTierPreset.legendary
        XCTAssertEqual(legendary.id, "Legendary (45d)")
        XCTAssertEqual(legendary.days, 45)
        XCTAssertEqual(legendary.tier, .legendary)
        XCTAssertEqual(legendary.bestStreak, 60)
        XCTAssertEqual(legendary.nextMilestone, 50)
    }

    func testEmeraldThemeTokens() {
        let theme = CraftEmeraldTheme()
        XCTAssertEqual(theme.colors.brandPrimary, Color(hex: 0x10B981))
        XCTAssertEqual(theme.colors.brandSecondary, Color(hex: 0x14B8A6))
        XCTAssertEqual(theme.colors.accent, Color(hex: 0xF59E0B))
        XCTAssertEqual(theme.colors.statusSuccess, Color(hex: 0x10B981))
        XCTAssertEqual(theme.colors.statusWarning, Color(hex: 0xF59E0B))
        XCTAssertEqual(theme.colors.statusDanger, Color(hex: 0xEF4444))
        XCTAssertEqual(theme.colors.statusInfo, Color(hex: 0x06B6D4))

        XCTAssertEqual(theme.spacing.base, 16)
        XCTAssertEqual(theme.radii.md, 12)
        XCTAssertNotNil(theme.gradients.brandHero)
        XCTAssertNotNil(theme.shadows.md)
        XCTAssertNotNil(theme.animations.springSmooth)
    }

    func testCraftCatalogViewInstantiation() {
        let view = CraftCatalogView()
        XCTAssertNotNil(view.body)
    }

    func testCraftCatalogViewThemesAndColorSchemesRendering() {
        for themeType in CatalogThemeType.allCases {
            let themedView = CraftCatalogView()
                .craftTheme(themeType.theme)
            XCTAssertNotNil(themedView)
        }

        for scheme in [ColorScheme.light, ColorScheme.dark] {
            let schemeView = CraftCatalogView()
                .preferredColorScheme(scheme)
            XCTAssertNotNil(schemeView)
        }
    }

    func testPressEffectModifierAndButtonStyle() {
        let style = CraftInteractiveButtonStyle(scale: 0.95, opacity: 0.9)
        XCTAssertEqual(style.scale, 0.95)
        XCTAssertEqual(style.opacity, 0.9)

        let mod = CraftPressEffectModifier(scale: 0.96, opacity: 0.85, hapticFeedback: true)
        XCTAssertEqual(mod.scale, 0.96)
        XCTAssertEqual(mod.opacity, 0.85)
        XCTAssertTrue(mod.hapticFeedback)

        let button = Button("Test") {}
            .buttonStyle(.craftPress(scale: 0.95, opacity: 0.9))
        XCTAssertNotNil(button)

        let modifiedView = Text("Interactive")
            .craftPressEffect(scale: 0.96)
        XCTAssertNotNil(modifiedView)
    }

    func testShimmerModifierConfiguration() {
        let mod = CraftShimmerModifier(isActive: true, duration: 1.2, bounce: true)
        XCTAssertTrue(mod.isActive)
        XCTAssertEqual(mod.duration, 1.2)
        XCTAssertTrue(mod.bounce)

        let activeShimmer = Text("Skeleton")
            .craftShimmer(isActive: true, duration: 1.2, bounce: true)
        XCTAssertNotNil(activeShimmer)

        let inactiveShimmer = Text("Loaded Content")
            .craftShimmer(isActive: false)
        XCTAssertNotNil(inactiveShimmer)
    }

    func testTypographyModifierAllStyles() {
        for style in CraftTypographyStyle.allCases {
            let mod = CraftTypographyModifier(style)
            XCTAssertEqual(mod.style, style)

            let view = Text("Sample Text")
                .craftTypography(style)
            XCTAssertNotNil(view)
        }
    }

    func testCatalogRowPatternPresets() {
        XCTAssertEqual(CatalogRowPatternPreset.allCases.count, 4)
        XCTAssertEqual(CatalogRowPatternPreset.standard.id, "Standard (1-2-1)")
        XCTAssertEqual(CatalogRowPatternPreset.wave.id, "Wave (1-2-3-2-1)")
        XCTAssertEqual(CatalogRowPatternPreset.linear.id, "Linear (1-1-1)")
        XCTAssertEqual(CatalogRowPatternPreset.pairs.id, "Pairs (2-2)")

        XCTAssertEqual(CatalogRowPatternPreset.standard.pattern, .standard)
        XCTAssertEqual(CatalogRowPatternPreset.wave.pattern, .wave)
        XCTAssertEqual(CatalogRowPatternPreset.linear.pattern, .custom([1]))
        XCTAssertEqual(CatalogRowPatternPreset.pairs.pattern, .custom([2]))
    }

    func testCatalogWindingPresets() {
        XCTAssertEqual(CatalogWindingPreset.allCases.count, 3)
        XCTAssertEqual(CatalogWindingPreset.standard.id, "Standard")
        XCTAssertEqual(CatalogWindingPreset.gentle.id, "Gentle")
        XCTAssertEqual(CatalogWindingPreset.linear.id, "Linear")

        XCTAssertEqual(CatalogWindingPreset.standard.winding, .standard)
        XCTAssertEqual(CatalogWindingPreset.gentle.winding, .gentle)
        XCTAssertEqual(CatalogWindingPreset.linear.winding, .linear)
    }

    func testCatalogLearningPathMockData() {
        let sections = CatalogLearningPathMockData.defaultSections
        XCTAssertEqual(sections.count, 2)

        let section1 = sections[0]
        XCTAssertEqual(section1.id, "sec_1")
        XCTAssertEqual(section1.title, "Unit 1: Khởi đầu (Foundations)")
        XCTAssertEqual(section1.nodes.count, 6)
        XCTAssertEqual(section1.nodes[0].state, .completed)
        XCTAssertEqual(section1.nodes[0].stars, 3)
        XCTAssertEqual(section1.nodes[2].state, .active)
        XCTAssertEqual(section1.nodes[2].progress, 0.6)
        XCTAssertEqual(section1.nodes[4].kind, .checkpoint)
        XCTAssertEqual(section1.nodes[4].badgeText, "HOT")
        XCTAssertEqual(section1.nodes[5].kind, .treasureChest)
        XCTAssertEqual(section1.nodes[5].xpReward, 100)

        let section2 = sections[1]
        XCTAssertEqual(section2.id, "sec_2")
        XCTAssertEqual(section2.title, "Unit 2: Giao tiếp Hàng ngày (Daily Conversations)")
        XCTAssertEqual(section2.nodes.count, 4)
        XCTAssertEqual(section2.nodes[0].state, .locked)
        XCTAssertEqual(section2.nodes[3].kind, .treasureChest)
    }

    func testEmeraldThemeDepthsAndTokens() {
        let theme = CraftEmeraldTheme()
        XCTAssertEqual(theme.depths.depthSm, 2)
        XCTAssertEqual(theme.depths.depthMd, 4)
        XCTAssertEqual(theme.depths.depthLg, 6)
        XCTAssertNotNil(theme.depths.topHighlight)
        XCTAssertNotNil(theme.gradients.surfaceGlass)
        XCTAssertNotNil(theme.gradients.accentShine)
        XCTAssertNotNil(theme.gradients.fadeBottom)
    }
}
