import XCTest
import SwiftUI
@testable import CraftUIKit

final class CatalogViewTests: XCTestCase {
    func testCatalogThemeTypeEnumCases() {
        XCTAssertEqual(CatalogThemeType.allCases.count, 2)
        XCTAssertEqual(CatalogThemeType.defaultSlate.rawValue, "Default Slate")
        XCTAssertEqual(CatalogThemeType.emeraldTeal.rawValue, "Emerald Teal")
        
        let slateTheme = CatalogThemeType.defaultSlate.theme
        XCTAssertNotNil(slateTheme)
        
        let emeraldTheme = CatalogThemeType.emeraldTeal.theme
        XCTAssertNotNil(emeraldTheme)
        XCTAssertEqual(emeraldTheme.colors.brandPrimary, Color(hex: 0x10B981))
    }

    func testCatalogColorSchemeEnumCases() {
        XCTAssertEqual(CatalogColorScheme.allCases.count, 3)
        XCTAssertNil(CatalogColorScheme.system.colorScheme)
        XCTAssertEqual(CatalogColorScheme.light.colorScheme, .light)
        XCTAssertEqual(CatalogColorScheme.dark.colorScheme, .dark)
    }

    func testEmeraldThemeTokens() {
        let theme = CraftEmeraldTheme()
        XCTAssertEqual(theme.colors.brandPrimary, Color(hex: 0x10B981))
        XCTAssertEqual(theme.colors.brandSecondary, Color(hex: 0x14B8A6))
        XCTAssertEqual(theme.spacing.base, 16)
        XCTAssertEqual(theme.radii.md, 12)
    }

    func testCraftCatalogViewInstantiation() {
        let view = CraftCatalogView()
        XCTAssertNotNil(view.body)
    }
}
