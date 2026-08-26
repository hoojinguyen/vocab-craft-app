import XCTest
import SwiftUI
@testable import CraftUIKit

final class CatalogViewTests: XCTestCase {
    // MARK: - Theme & Options Enums

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

    func testCatalogLanguageEnumCases() {
        XCTAssertEqual(CatalogLanguage.allCases.count, 2)
        XCTAssertEqual(CatalogLanguage.english.id, "English")
        XCTAssertEqual(CatalogLanguage.vietnamese.id, "Tiếng Việt")
        XCTAssertEqual(CatalogLanguage.english.code, "en")
        XCTAssertEqual(CatalogLanguage.vietnamese.code, "vi")
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
        XCTAssertEqual(CatalogTabItem.practice.badgeCount, 3)

        XCTAssertEqual(CatalogTabItem.profile.id, "Profile")
        XCTAssertEqual(CatalogTabItem.profile.title, "Profile")
        XCTAssertEqual(CatalogTabItem.profile.symbol, "person.crop.circle")
        XCTAssertNil(CatalogTabItem.profile.badgeCount)
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

    // MARK: - Themes & Surface Styles Rendering

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
        XCTAssertEqual(theme.depths.depthSm, 2)
        XCTAssertEqual(theme.depths.depthMd, 4)
        XCTAssertEqual(theme.depths.depthLg, 6)
        XCTAssertNotNil(theme.depths.topHighlight)
        XCTAssertNotNil(theme.glass.borderGradient)
        XCTAssertEqual(theme.glass.tintOpacity, 0.15)
    }

    func testCraftCatalogViewInstantiation() {
        let view = CraftCatalogView()
        XCTAssertNotNil(view.body)
    }

    func testCraftCatalogViewThemesSurfaceStylesAndLanguages() {
        for themeType in CatalogThemeType.allCases {
            let themedView = CraftCatalogView()
                .craftTheme(themeType.theme)
            XCTAssertNotNil(themedView)
        }

        for style in CraftSurfaceStyle.allCases {
            let surfaceView = CraftCatalogView()
                .craftSurfaceStyle(style)
            XCTAssertNotNil(surfaceView)
        }

        for lang in CatalogLanguage.allCases {
            let localizedView = CraftCatalogView()
                .environment(\.locale, Locale(identifier: lang.code))
            XCTAssertNotNil(localizedView)
        }

        for scheme in [ColorScheme.light, ColorScheme.dark] {
            let schemeView = CraftCatalogView()
                .preferredColorScheme(scheme)
            XCTAssertNotNil(schemeView)
        }
    }

    // MARK: - Showcase Component Verification

    func testAtomsShowcaseComponents() {
        let theme = CraftDefaultTheme()

        // 1. CraftText Markdown, tracking, lineSpacing
        let markdown = try? AttributedString(markdown: "Rich **Markdown** with `code`")
        if let markdown {
            let textView = CraftText(markdown, style: .bodyMedium, tracking: 2.0, lineSpacing: 8)
            XCTAssertNotNil(textView)
            XCTAssertEqual(textView.tracking, 2.0)
            XCTAssertEqual(textView.lineSpacing, 8)
        }

        // 2. CraftBadge 5 surface styles
        for style in CraftSurfaceStyle.allCases {
            let badge = CraftBadge("Badge", symbol: .sparkles, style: style)
            XCTAssertNotNil(badge)
            XCTAssertEqual(badge.style, style)
        }

        // 3. CraftIconButton 5 surface styles & 44pt min target
        for style in CraftSurfaceStyle.allCases {
            let button = CraftIconButton(symbol: .favoriteFill, style: style, accessibilityLabel: "Fav") {}
            XCTAssertNotNil(button)
            XCTAssertEqual(button.style, style)
            XCTAssertEqual(button.minTouchTarget, 44)
        }

        // 4. CraftDivider styles
        let solidDivider = CraftDivider(style: .solid)
        let dashedDivider = CraftDivider(style: .dashed(dash: 6, gap: 4))
        let gradientDivider = CraftDivider(style: .gradient(theme.gradients.brandHero))
        XCTAssertEqual(solidDivider.style, .solid)
        XCTAssertEqual(dashedDivider.style, .dashed(dash: 6, gap: 4))
        XCTAssertEqual(gradientDivider.style, .gradient(theme.gradients.brandHero))

        // 5. CraftSpinner scales
        for size in CraftIconSize.allCases {
            let spinner = CraftSpinner(size: size, color: theme.colors.brandPrimary)
            XCTAssertEqual(spinner.size, size)
            XCTAssertEqual(spinner.color, theme.colors.brandPrimary)
        }
    }

    func testControlsShowcaseComponents() {
        let theme = CraftDefaultTheme()

        // 1. CraftButton 5 surface styles & loading state
        for style in CraftSurfaceStyle.allCases {
            let button = CraftButton("Button", style: style, customGradient: theme.gradients.brandHero) {}
            XCTAssertNotNil(button)
            XCTAssertEqual(button.style, style)
        }
        let loadingButton = CraftButton("Loading", isLoading: true) {}
        XCTAssertTrue(loadingButton.isLoading)

        // 2. CraftChoiceCard 5 surface styles & states & prefix styles
        for style in CraftSurfaceStyle.allCases {
            for state in CraftChoiceState.allCases {
                for prefixStyle in CraftChoicePrefixStyle.allCases {
                    let card = CraftChoiceCard(prefix: "A", prefixStyle: prefixStyle, title: "Option", state: state, style: style) {}
                    XCTAssertNotNil(card)
                    XCTAssertEqual(card.state, state)
                    XCTAssertEqual(card.style, style)
                    XCTAssertEqual(card.prefixStyle, prefixStyle)
                }
            }
        }

        // 3. CraftTextField styles
        for style in CraftTextFieldStyle.allCases {
            var text = "Hello"
            let binding = Binding(get: { text }, set: { text = $0 })
            let tf = CraftTextField(placeholder: "Placeholder", text: binding, style: style)
            XCTAssertNotNil(tf)
            XCTAssertEqual(tf.style, style)
        }

        // 4. CraftSearchBar styles
        for style in CraftSearchBarStyle.allCases {
            var search = ""
            let binding = Binding(get: { search }, set: { search = $0 })
            let sb = CraftSearchBar(text: binding, style: style)
            XCTAssertNotNil(sb)
            XCTAssertEqual(sb.style, style)
        }

        // 5. CraftPill 5 surface styles
        for style in CraftSurfaceStyle.allCases {
            let pill = CraftPill("Filter", count: 5, isSelected: true, style: style) {}
            XCTAssertNotNil(pill)
            XCTAssertEqual(pill.style, style)
            XCTAssertTrue(pill.isSelected)
        }
    }

    func testContainersAndOverlaysShowcaseComponents() {
        let theme = CraftDefaultTheme()

        // 1. CraftCard 5 surface styles
        for style in CraftSurfaceStyle.allCases {
            let card = CraftCard(surfaceStyle: style) {
                Text("Card Content")
            }
            XCTAssertNotNil(card)
            XCTAssertEqual(card.style.surfaceStyle, style)
        }

        // 2. CraftFlipCard
        var isFlipped = false
        let flipBinding = Binding(get: { isFlipped }, set: { isFlipped = $0 })
        let flipCard = CraftFlipCard(isFlipped: flipBinding, axis: .horizontal) {
            Text("Front")
        } back: {
            Text("Back")
        }
        XCTAssertNotNil(flipCard)

        // 3. CraftListRow
        let listRow = CraftListRow(title: "Mastered Words", subtitle: "142 items", iconName: "checkmark.seal.fill")
        XCTAssertNotNil(listRow)

        // 4. CraftProgressBar & Ring & SegmentedBar
        let bar = CraftProgressBar(progress: 0.75, height: 10)
        XCTAssertEqual(bar.progress, 0.75)
        XCTAssertEqual(bar.height, 10)

        let ring = CraftProgressRing(progress: 0.85, lineWidth: 8, size: 70)
        XCTAssertEqual(ring.progress, 0.85)

        let segBar = CraftSegmentedBar(
            items: [CraftSegmentItem(id: "1", label: "A", value: 60, color: theme.colors.brandPrimary)],
            height: 12
        )
        XCTAssertNotNil(segBar)

        // 5. CraftDialog & CraftToast styles
        for style in CraftToastStyle.allCases {
            let toast = CraftToast(message: "Toast msg", style: style, surfaceStyle: .glass)
            XCTAssertNotNil(toast)
            XCTAssertEqual(toast.style, style)
            XCTAssertEqual(toast.surfaceStyle, .glass)
        }
    }

    func testUniversalJourneyPathComponents() {
        // 1. CraftPathNode 5 shapes x 5 surface styles x 6 states
        for shape in CraftNodeShape.allCases {
            for surfaceStyle in CraftSurfaceStyle.allCases {
                for state in CraftNodeState.allCases {
                    let model = CraftPathNodeModel(
                        id: "test_node",
                        title: "Node Title",
                        state: state,
                        shape: shape,
                        surfaceStyle: surfaceStyle
                    )
                    let node = CraftPathNode(model: model, calloutText: "START")
                    XCTAssertNotNil(node)
                    XCTAssertEqual(node.model.shape, shape)
                    XCTAssertEqual(node.model.surfaceStyle, surfaceStyle)
                    XCTAssertEqual(node.model.state, state)
                }
            }
        }

        // 2. CraftJourneySectionView
        let section = CraftJourneySection(
            id: "sec_test",
            title: "Section 1",
            nodes: [
                CraftPathNodeModel(id: "n1", title: "Node 1", state: .completed, stars: 3),
                CraftPathNodeModel(id: "n2", title: "Node 2", state: .active)
            ]
        )
        let sectionView = CraftJourneySectionView(section: section)
        XCTAssertNotNil(sectionView)
    }

    func testUniversalActivityAndStreakTrackerComponents() {
        let trackerData = CraftActivityTrackerData(
            currentValue: 14,
            bestRecord: 30,
            tier: .blaze,
            shieldTokens: 2,
            maxShieldTokens: 3,
            nextMilestone: 21,
            isCompletedToday: true,
            cycleDays: [
                CraftActivityDay(id: "1", weekdaySymbol: "T2", status: .completed),
                CraftActivityDay(id: "2", weekdaySymbol: "T3", status: .completed, isToday: true)
            ]
        )

        let trackerCard = CraftActivityTrackerCard(data: trackerData, cardStyle: .tactile3D)
        XCTAssertNotNil(trackerCard)
        XCTAssertEqual(trackerCard.data.currentValue, 14)
        XCTAssertEqual(trackerCard.data.tier, .blaze)
        XCTAssertEqual(trackerCard.cardStyle, .tactile3D)

        let celebrationSheet = CraftCelebrationSheet(
            currentValue: 14,
            previousValue: 13,
            cycleDays: trackerData.cycleDays,
            onContinue: {}
        )
        XCTAssertNotNil(celebrationSheet)
        XCTAssertEqual(celebrationSheet.currentValue, 14)
        XCTAssertEqual(celebrationSheet.previousValue, 13)
        XCTAssertEqual(celebrationSheet.tier, .blaze)
        XCTAssertTrue(celebrationSheet.isMilestone)
    }
}
