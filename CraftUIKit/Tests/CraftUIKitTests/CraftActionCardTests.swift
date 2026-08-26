import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftActionCardTests: XCTestCase {

    // MARK: - Initializer Tests

    func testStringInitializer() {
        var tapped = false
        let card = CraftActionCard(
            title: "Luyện nói",
            subtitle: "Phản xạ phát âm & nhận diện giọng nói",
            iconName: "waveform.and.mic",
            badgeText: "6.0s",
            badgeIcon: "stopwatch.fill",
            accentColor: .orange,
            showChevron: true
        ) {
            tapped = true
        }

        XCTAssertEqual(card.title, "Luyện nói")
        XCTAssertEqual(card.subtitle, "Phản xạ phát âm & nhận diện giọng nói")
        XCTAssertEqual(card.iconName, "waveform.and.mic")
        XCTAssertEqual(card.badgeText, "6.0s")
        XCTAssertEqual(card.badgeIcon, "stopwatch.fill")
        XCTAssertEqual(card.showChevron, true)
        XCTAssertEqual(card.resolvedStyle, .outlined)
        XCTAssertNotNil(card.body)

        card.action()
        XCTAssertTrue(tapped)
    }

    func testCraftSymbolInitializer() {
        let card = CraftActionCard(
            title: "Streak",
            subtitle: "Maintain daily streak",
            symbol: .streak,
            badgeText: "HOT",
            style: .tactile3D
        ) {}

        XCTAssertEqual(card.title, "Streak")
        XCTAssertEqual(card.symbol, .streak)
        XCTAssertEqual(card.iconName, CraftSymbol.streak.rawValue)
        XCTAssertEqual(card.resolvedStyle, .tactile3D)
        XCTAssertNotNil(card.body)
    }

    func testLocalizedStringKeyInitializers() {
        var tapped = false
        let card = CraftActionCard(
            title: LocalizedStringKey("app.study.title"),
            subtitle: LocalizedStringKey("app.study.subtitle"),
            iconName: "book.fill",
            badgeText: "NEW",
            badgeIcon: "sparkles",
            accentColor: .blue,
            style: .elevated,
            showChevron: false,
            cornerRadius: 16
        ) {
            tapped = true
        }

        XCTAssertEqual(card.title, "")
        XCTAssertNil(card.subtitle)
        XCTAssertEqual(card.iconName, "book.fill")
        XCTAssertEqual(card.badgeText, "NEW")
        XCTAssertEqual(card.badgeIcon, "sparkles")
        XCTAssertFalse(card.showChevron)
        XCTAssertEqual(card.cornerRadius, 16)
        XCTAssertEqual(card.resolvedStyle, .elevated)
        XCTAssertNotNil(card.body)

        card.action()
        XCTAssertTrue(tapped)
    }

    func testLocalizedStringKeyWithSymbolInitializer() {
        let card = CraftActionCard(
            title: LocalizedStringKey("app.reflex.title"),
            subtitle: LocalizedStringKey("app.reflex.subtitle"),
            symbol: .practice,
            badgeKey: LocalizedStringKey("app.reflex.badge"),
            badgeIcon: "bolt.fill",
            accentColor: .purple,
            style: .glass,
            showChevron: true
        ) {}

        XCTAssertEqual(card.title, "")
        XCTAssertNil(card.subtitle)
        XCTAssertEqual(card.symbol, .practice)
        XCTAssertEqual(card.iconName, CraftSymbol.practice.rawValue)
        XCTAssertEqual(card.resolvedStyle, .glass)
        XCTAssertNotNil(card.body)
    }

    // MARK: - Surface Style Resolution Tests

    func testExplicitSurfaceStyleOverridesEnvironment() {
        let card = CraftActionCard(
            title: "Glass Card",
            style: .glass
        ) {}

        XCTAssertEqual(card.resolvedStyle, .glass)
    }

    func testAllSurfaceStylesRendering() {
        let styles: [CraftSurfaceStyle] = [.outlined, .tactile3D, .glass, .elevated, .flat]
        for surfaceStyle in styles {
            let card = CraftActionCard(
                title: "Card \(surfaceStyle.rawValue)",
                subtitle: "Testing style \(surfaceStyle.rawValue)",
                symbol: .starFill,
                badgeText: "STYLE",
                style: surfaceStyle
            ) {}

            XCTAssertEqual(card.resolvedStyle, surfaceStyle)
            XCTAssertNotNil(card.body)
        }
    }

    // MARK: - Options & Slots

    func testCardWithoutSubtitleAndWithoutBadge() {
        let card = CraftActionCard(
            title: "Minimal Card",
            iconName: "gearshape.fill",
            badgeText: nil,
            badgeIcon: nil,
            showChevron: false
        ) {}

        XCTAssertEqual(card.title, "Minimal Card")
        XCTAssertNil(card.subtitle)
        XCTAssertNil(card.badgeText)
        XCTAssertNil(card.badgeIcon)
        XCTAssertFalse(card.showChevron)
        XCTAssertNotNil(card.body)
    }

    func testCustomCornerRadiusAndAccent() {
        let customColor = Color.pink
        let card = CraftActionCard(
            title: "Custom Card",
            accentColor: customColor,
            cornerRadius: 28
        ) {}

        XCTAssertEqual(card.cornerRadius, 28)
        XCTAssertEqual(card.accentColor, customColor)
        XCTAssertNotNil(card.body)
    }

    // MARK: - Button Style Tests

    func testActionCardButtonStyleConfiguration() {
        let defaultButtonStyle = CraftActionCardButtonStyle()
        XCTAssertEqual(defaultButtonStyle.style, .outlined)
        XCTAssertEqual(defaultButtonStyle.depth, 4)
        XCTAssertEqual(defaultButtonStyle.cornerRadius, 22)
        XCTAssertNil(defaultButtonStyle.accentColor)

        let customButtonStyle = CraftActionCardButtonStyle(
            style: .tactile3D,
            depth: 6,
            cornerRadius: 18,
            accentColor: .green
        )
        XCTAssertEqual(customButtonStyle.style, .tactile3D)
        XCTAssertEqual(customButtonStyle.depth, 6)
        XCTAssertEqual(customButtonStyle.cornerRadius, 18)
        XCTAssertEqual(customButtonStyle.accentColor, .green)
    }

    // MARK: - Theming Environment

    func testThemedCardRendering() {
        let theme = CraftDefaultTheme()
        let card = CraftActionCard(
            title: "Themed Card",
            subtitle: "Supports full dark/light modes",
            symbol: .sparkles,
            badgeText: "HOT",
            style: .tactile3D
        ) {}

        let themedView = card.craftTheme(theme)
        XCTAssertNotNil(themedView)
    }
}
