#if canImport(XCTest)
import XCTest
#endif
import SwiftUI
@testable import CraftUIKit

final class SurfaceStyleTests: XCTestCase {

    // MARK: - Enum & Conformance Tests

    func testCraftSurfaceStyleEnumCases() {
        let expectedCases: [CraftSurfaceStyle] = [.flat, .elevated, .outlined, .tactile3D, .glass]
        XCTAssertEqual(CraftSurfaceStyle.allCases, expectedCases)
        XCTAssertEqual(CraftSurfaceStyle.allCases.count, 5)

        XCTAssertEqual(CraftSurfaceStyle.flat.rawValue, "flat")
        XCTAssertEqual(CraftSurfaceStyle.elevated.rawValue, "elevated")
        XCTAssertEqual(CraftSurfaceStyle.outlined.rawValue, "outlined")
        XCTAssertEqual(CraftSurfaceStyle.tactile3D.rawValue, "tactile3D")
        XCTAssertEqual(CraftSurfaceStyle.glass.rawValue, "glass")
    }

    func testCraftSurfaceStyleSendable() {
        let style: CraftSurfaceStyle = .glass
        Task {
            let taskStyle = style
            XCTAssertEqual(taskStyle, .glass)
        }
    }

    // MARK: - Glass Token Tests

    func testDefaultGlassTokens() {
        let glass = CraftDefaultGlassTokens()
        XCTAssertEqual(glass.tintOpacity, 0.15)
        XCTAssertNotNil(glass.borderGradient)
    }

    func testCustomGlassTokensInit() {
        let customGradient = LinearGradient(
            colors: [.red, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let customGlass = CraftDefaultGlassTokens(tintOpacity: 0.25, borderGradient: customGradient)
        XCTAssertEqual(customGlass.tintOpacity, 0.25)
        XCTAssertNotNil(customGlass.borderGradient)
    }

    func testGlassTokensProtocolExtensionDefaults() {
        struct MinimalGlassTokens: CraftGlassTokens {}
        let minimal = MinimalGlassTokens()
        XCTAssertEqual(minimal.tintOpacity, 0.15)
        XCTAssertNotNil(minimal.borderGradient)
    }

    // MARK: - Theme Integration Tests

    func testThemeGlassIntegration() {
        let theme = CraftDefaultTheme()
        XCTAssertEqual(theme.glass.tintOpacity, 0.15)
        XCTAssertNotNil(theme.glass.borderGradient)
    }

    func testThemeProtocolDefaultGlassImplementation() {
        struct CustomThemeWithoutGlass: CraftTheme {
            var colors: CraftColorTokens = CraftDefaultColorTokens()
            var typography: CraftTypographyTokens = CraftDefaultTypographyTokens()
            var spacing: CraftSpacingTokens = CraftDefaultSpacingTokens()
            var radii: CraftRadiusTokens = CraftDefaultRadiusTokens()
            var shadows: CraftShadowTokens = CraftDefaultShadowTokens()
            var gradients: CraftGradientTokens = CraftDefaultGradientTokens()
            var animations: CraftAnimationTokens = CraftDefaultAnimationTokens()
            var opacities: CraftOpacityTokens = CraftDefaultOpacityTokens()
        }

        let customTheme = CustomThemeWithoutGlass()
        XCTAssertEqual(customTheme.glass.tintOpacity, 0.15)
        XCTAssertNotNil(customTheme.glass.borderGradient)
    }

    func testCustomThemeWithCustomGlassTokens() {
        struct CustomGlass: CraftGlassTokens {
            var tintOpacity: Double = 0.40
            var borderGradient: LinearGradient = LinearGradient(
                colors: [.green, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        let customTheme = CraftDefaultTheme(glass: CustomGlass())
        XCTAssertEqual(customTheme.glass.tintOpacity, 0.40)
    }

    // MARK: - Environment Tests

    func testEnvironmentDefaultValue() {
        XCTAssertEqual(CraftSurfaceStyleKey.defaultValue, .flat)

        var values = EnvironmentValues()
        XCTAssertEqual(values.craftSurfaceStyle, .flat)

        values.craftSurfaceStyle = .glass
        XCTAssertEqual(values.craftSurfaceStyle, .glass)

        values.craftSurfaceStyle = .tactile3D
        XCTAssertEqual(values.craftSurfaceStyle, .tactile3D)
    }

    func testViewCraftSurfaceStyleModifier() {
        let view = Text("Test Surface")
            .craftSurfaceStyle(.elevated)
        XCTAssertNotNil(view)

        let glassView = Text("Glass")
            .craftSurfaceStyle(.glass)
        XCTAssertNotNil(glassView)
    }

    // MARK: - CraftSurfaceModifier Rendering Tests

    func testModifierResolvedStyleExplicit() {
        let modifier = CraftSurfaceModifier(
            style: .glass,
            shape: RoundedRectangle(cornerRadius: 12)
        )
        XCTAssertEqual(modifier.resolvedStyle, .glass)
        XCTAssertEqual(modifier.style, .glass)
    }

    func testModifierResolvedStyleFallbackToEnvironment() {
        let modifier = CraftSurfaceModifier(
            style: nil,
            shape: Capsule()
        )
        // With default environment, resolvedStyle is .flat
        XCTAssertEqual(modifier.resolvedStyle, .flat)
        XCTAssertNil(modifier.style)
    }

    func testCraftSurfaceAllStylesBodyRendering() {
        for style in CraftSurfaceStyle.allCases {
            let view = Text("Surface \(style.rawValue)")
                .craftSurface(style: style, shape: RoundedRectangle(cornerRadius: 16))
            XCTAssertNotNil(view)
        }
    }

    func testCraftSurfaceTactile3DDepressionAndCustomDepth() {
        let unpressed = Text("Tactile Unpressed")
            .craftSurface(
                style: .tactile3D,
                shape: RoundedRectangle(cornerRadius: 12),
                isPressed: false,
                depth: 6
            )
        XCTAssertNotNil(unpressed)

        let pressed = Text("Tactile Pressed")
            .craftSurface(
                style: .tactile3D,
                shape: RoundedRectangle(cornerRadius: 12),
                isPressed: true,
                depth: 8
            )
        XCTAssertNotNil(pressed)
    }

    func testCraftSurfaceCustomTintAndGradient() {
        let tinted = Text("Custom Tint")
            .craftSurface(
                style: .glass,
                shape: Capsule(),
                customTint: .blue
            )
        XCTAssertNotNil(tinted)

        let customGrad = LinearGradient(
            colors: [.purple, .orange],
            startPoint: .leading,
            endPoint: .trailing
        )
        let gradientSurface = Text("Gradient")
            .craftSurface(
                style: .elevated,
                shape: RoundedRectangle(cornerRadius: 8),
                customGradient: customGrad
            )
        XCTAssertNotNil(gradientSurface)
    }

    func testCraftSurfaceWithDifferentShapes() {
        let rect = Text("Rectangle")
            .craftSurface(style: .outlined, shape: Rectangle())
        XCTAssertNotNil(rect)

        let circle = Text("Circle")
            .craftSurface(style: .elevated, shape: Circle())
        XCTAssertNotNil(circle)

        let capsule = Text("Capsule")
            .craftSurface(style: .glass, shape: Capsule())
        XCTAssertNotNil(capsule)
    }

    func testEnvironmentInheritanceInViewHierarchy() {
        struct InheritedSurfaceView: View {
            @Environment(\.craftSurfaceStyle) var envStyle

            var body: some View {
                VStack {
                    Text("Inherits \(envStyle.rawValue)")
                        .craftSurface(shape: RoundedRectangle(cornerRadius: 12))
                    Text("Overrides to flat")
                        .craftSurface(style: .flat, shape: RoundedRectangle(cornerRadius: 12))
                }
            }
        }

        let container = InheritedSurfaceView()
            .craftSurfaceStyle(.glass)
            .craftTheme(CraftDefaultTheme())

        XCTAssertNotNil(container)
    }
}
