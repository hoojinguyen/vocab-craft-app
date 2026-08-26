import XCTest
import SwiftUI
@testable import CraftUIKit

final class InteractiveCardTests: XCTestCase {

    // MARK: - CraftChoiceState Tests

    func testChoiceStateEnumCases() {
        let allStates = CraftChoiceState.allCases
        XCTAssertEqual(allStates.count, 5)
        XCTAssertTrue(allStates.contains(.idle))
        XCTAssertTrue(allStates.contains(.selected))
        XCTAssertTrue(allStates.contains(.correct))
        XCTAssertTrue(allStates.contains(.wrong))
        XCTAssertTrue(allStates.contains(.disabled))
    }

    func testChoiceStateEquatableAndHashable() {
        XCTAssertEqual(CraftChoiceState.idle, CraftChoiceState.idle)
        XCTAssertNotEqual(CraftChoiceState.idle, CraftChoiceState.selected)
        let stateSet: Set<CraftChoiceState> = [.idle, .selected, .correct, .wrong, .disabled]
        XCTAssertEqual(stateSet.count, 5)
    }

    // MARK: - CraftChoicePrefixStyle Tests

    func testChoicePrefixStyleEnumCasesAndProtocols() {
        let allStyles = CraftChoicePrefixStyle.allCases
        XCTAssertEqual(allStyles.count, 4)
        XCTAssertTrue(allStyles.contains(.circle))
        XCTAssertTrue(allStyles.contains(.roundedSquare))
        XCTAssertTrue(allStyles.contains(.minimal))
        XCTAssertTrue(allStyles.contains(.none))

        XCTAssertEqual(CraftChoicePrefixStyle.circle.rawValue, "circle")
        XCTAssertEqual(CraftChoicePrefixStyle.roundedSquare.rawValue, "roundedSquare")
        XCTAssertEqual(CraftChoicePrefixStyle.minimal.rawValue, "minimal")
        XCTAssertEqual(CraftChoicePrefixStyle.none.rawValue, "none")

        // Equatable and Hashable conformance
        XCTAssertEqual(CraftChoicePrefixStyle.circle, CraftChoicePrefixStyle.circle)
        XCTAssertNotEqual(CraftChoicePrefixStyle.circle, CraftChoicePrefixStyle.minimal)
        let styleSet: Set<CraftChoicePrefixStyle> = [.circle, .roundedSquare, .minimal, .none]
        XCTAssertEqual(styleSet.count, 4)
    }

    // MARK: - CraftChoiceCard Tests

    func testChoiceCardInitializersAndStates() {
        var tapped = false
        let card = CraftChoiceCard(prefix: "A", title: "Option 1", state: .correct) {
            tapped = true
        }
        XCTAssertEqual(card.prefix, "A")
        XCTAssertEqual(card.title, "Option 1")
        XCTAssertNil(card.subtitle)
        XCTAssertEqual(card.state, .correct)
        card.action()
        XCTAssertTrue(tapped)
    }

    func testChoiceCardDefaultInitializer() {
        var tapped = false
        let card = CraftChoiceCard(title: "Default Choice") {
            tapped = true
        }
        XCTAssertEqual(card.prefix, "A")
        XCTAssertEqual(card.title, "Default Choice")
        XCTAssertNil(card.subtitle)
        XCTAssertEqual(card.state, .idle)
        card.action()
        XCTAssertTrue(tapped)
    }

    func testChoiceCardWithSubtitleAndPrefix() {
        let card = CraftChoiceCard(
            prefix: "B",
            title: "Option B",
            subtitle: "Secondary explanation text",
            state: .selected
        ) {}

        XCTAssertEqual(card.prefix, "B")
        XCTAssertEqual(card.title, "Option B")
        XCTAssertEqual(card.subtitle, "Secondary explanation text")
        XCTAssertEqual(card.state, .selected)
        XCTAssertNotNil(card.body)
    }

    func testChoiceCardMultiCharacterPrefixAndLongText() {
        let card = CraftChoiceCard(
            prefix: "10.",
            title: "Very long vocabulary term spanning across multiple lines of text",
            subtitle: "Comprehensive explanation detailing linguistic etymology and connotations",
            state: .selected
        ) {}

        XCTAssertEqual(card.prefix, "10.")
        XCTAssertEqual(card.title, "Very long vocabulary term spanning across multiple lines of text")
        XCTAssertEqual(card.subtitle, "Comprehensive explanation detailing linguistic etymology and connotations")
        XCTAssertNotNil(card.body)
    }

    func testChoiceCardLocalizedLongPrefix() {
        let card = CraftChoiceCard(
            prefix: LocalizedStringKey("choice.prefix.long"),
            title: LocalizedStringKey("choice.title.long"),
            subtitle: LocalizedStringKey("choice.subtitle.long"),
            state: .idle
        ) {}

        XCTAssertNotNil(card.body)
    }

    func testChoiceCardNilPrefix() {
        let card = CraftChoiceCard(
            prefix: nil,
            title: "No prefix choice",
            state: .idle
        ) {}

        XCTAssertNil(card.prefix)
        XCTAssertEqual(card.title, "No prefix choice")
        XCTAssertNotNil(card.body)
    }

    func testChoiceCardDisabledState() {
        let card = CraftChoiceCard(
            prefix: "D",
            title: "Disabled Choice",
            state: .disabled
        ) {}

        XCTAssertEqual(card.state, .disabled)
        XCTAssertNotNil(card.body)
    }

    func testChoiceCardAllStatesBodyRendering() {
        for state in CraftChoiceState.allCases {
            let card = CraftChoiceCard(
                prefix: "C",
                title: "State \(state.rawValue)",
                subtitle: "Subtitle for \(state.rawValue)",
                state: state
            ) {}
            XCTAssertEqual(card.state, state)
            XCTAssertNotNil(card.body)
        }
    }

    func testChoiceCardLocalization() {
        var tapped = false
        let card = CraftChoiceCard(
            prefix: LocalizedStringKey("prefix_key"),
            title: LocalizedStringKey("title_key"),
            subtitle: LocalizedStringKey("subtitle_key"),
            state: .selected
        ) {
            tapped = true
        }
        XCTAssertNil(card.prefix)
        XCTAssertNil(card.title)
        XCTAssertNil(card.subtitle)
        XCTAssertEqual(card.state, .selected)
        XCTAssertNotNil(card.body)
        card.action()
        XCTAssertTrue(tapped)
    }

    func testChoiceCardStateIndicators() {
        var tapped = false
        let correctCard = CraftChoiceCard(
            prefix: "A",
            title: "Selected Option",
            state: .correct
        ) {
            tapped = true
        }
        XCTAssertEqual(correctCard.prefix, "A")
        XCTAssertEqual(correctCard.title, "Selected Option")
        XCTAssertEqual(correctCard.state, .correct)
        XCTAssertNotNil(correctCard.body)
        correctCard.action()
        XCTAssertTrue(tapped)

        let wrongCard = CraftChoiceCard(
            prefix: "B",
            title: "Wrong Option",
            state: .wrong
        ) {}
        XCTAssertEqual(wrongCard.state, .wrong)
        XCTAssertNotNil(wrongCard.body)
    }

    func testChoiceCardAllStatesWithTheme() {
        let theme = CraftDefaultTheme()
        for state in CraftChoiceState.allCases {
            let card = CraftChoiceCard(
                prefix: "A",
                title: "Card in \(state.rawValue)",
                subtitle: "Subtitle for \(state.rawValue)",
                state: state
            ) {}
            XCTAssertNotNil(card.body)
            let view = card.craftTheme(theme)
            XCTAssertNotNil(view)
        }
    }

    func testChoiceCardAccessibilityAndHierarchicalIndicators() {
        let idleCard = CraftChoiceCard(prefix: "A", title: "Option", state: .idle) {}
        let selectedCard = CraftChoiceCard(prefix: "B", title: "Option", state: .selected) {}
        let correctCard = CraftChoiceCard(prefix: "C", title: "Option", state: .correct) {}
        let wrongCard = CraftChoiceCard(prefix: "D", title: "Option", state: .wrong) {}

        XCTAssertEqual(idleCard.state, .idle)
        XCTAssertEqual(selectedCard.state, .selected)
        XCTAssertEqual(correctCard.state, .correct)
        XCTAssertEqual(wrongCard.state, .wrong)

        XCTAssertNotNil(idleCard.body)
        XCTAssertNotNil(selectedCard.body)
        XCTAssertNotNil(correctCard.body)
        XCTAssertNotNil(wrongCard.body)
    }

    func testChoiceCardGlassStyleAcrossStates() {
        for state in CraftChoiceState.allCases {
            let card = CraftChoiceCard(
                prefix: "G",
                title: "Glass Card \(state.rawValue)",
                subtitle: "Liquid glass material option",
                state: state,
                style: .glass
            ) {}
            XCTAssertEqual(card.style, .glass)
            XCTAssertNotNil(card.body)
        }
    }

    func testChoiceCardShakeEffectGeometry() {
        let effect = ChoiceShakeEffect(shakes: 1.0, amount: 8, shakesPerUnit: 3)
        let transform = effect.effectValue(size: CGSize(width: 200, height: 50))
        XCTAssertNotNil(transform)
    }

    func testChoiceCardEnvironmentSurfaceStyleInheritance() {
        let defaultCard = CraftChoiceCard(title: "Default Card") {}
        XCTAssertEqual(defaultCard.style, .tactile3D)
        XCTAssertEqual(defaultCard.resolvedStyle, .tactile3D)

        let explicitGlass = CraftChoiceCard(title: "Glass", style: .glass) {}
        XCTAssertEqual(explicitGlass.style, .glass)

        let explicitFlat = CraftChoiceCard(title: "Flat", style: .flat) {}
        XCTAssertEqual(explicitFlat.style, .flat)

        let explicitElevated = CraftChoiceCard(title: "Elevated", style: .elevated) {}
        XCTAssertEqual(explicitElevated.style, .elevated)

        let explicitOutlined = CraftChoiceCard(title: "Outlined", style: .outlined) {}
        XCTAssertEqual(explicitOutlined.style, .outlined)
    }

    func testChoiceCardButtonStyleConfiguration() {
        for style in CraftSurfaceStyle.allCases {
            for state in CraftChoiceState.allCases {
                let buttonStyle = CraftChoiceCardButtonStyle(state: state, style: style, depth: 4)
                XCTAssertEqual(buttonStyle.state, state)
                XCTAssertEqual(buttonStyle.style, style)
                XCTAssertEqual(buttonStyle.depth, 4)
            }
        }
    }

    func testChoiceCardDefaultParametersContract() {
        var tapped = false
        let card = CraftChoiceCard(title: "Contract Test") {
            tapped = true
        }
        XCTAssertEqual(card.prefix, "A")
        XCTAssertEqual(card.prefixStyle, .circle)
        XCTAssertEqual(card.title, "Contract Test")
        XCTAssertNil(card.subtitle)
        XCTAssertEqual(card.state, .idle)
        XCTAssertEqual(card.style, .tactile3D)
        XCTAssertEqual(card.resolvedStyle, .tactile3D)
        card.action()
        XCTAssertTrue(tapped)
        XCTAssertNotNil(card.body)
    }

    func testChoiceCardPrefixStylesAndCustomization() {
        for prefixStyle in CraftChoicePrefixStyle.allCases {
            let card = CraftChoiceCard(
                prefix: "P",
                prefixStyle: prefixStyle,
                title: "Custom Card \(prefixStyle.rawValue)",
                subtitle: "Custom Subtitle",
                state: .selected,
                style: .glass
            ) {}

            XCTAssertEqual(card.prefix, "P")
            XCTAssertEqual(card.prefixStyle, prefixStyle)
            XCTAssertEqual(card.title, "Custom Card \(prefixStyle.rawValue)")
            XCTAssertEqual(card.subtitle, "Custom Subtitle")
            XCTAssertEqual(card.state, .selected)
            XCTAssertEqual(card.style, .glass)
            XCTAssertNotNil(card.body)
        }
    }

    func testChoiceCardNonePrefixStyleBehavior() {
        // With nil prefix
        let nilPrefixCard = CraftChoiceCard(
            prefix: nil,
            prefixStyle: .none,
            title: "No Prefix Style with Nil",
            subtitle: "Sub"
        ) {}
        XCTAssertNil(nilPrefixCard.prefix)
        XCTAssertEqual(nilPrefixCard.prefixStyle, .none)
        XCTAssertNotNil(nilPrefixCard.body)

        // With explicit non-nil prefix (prefixStyle .none hides the badge)
        let withPrefixCard = CraftChoiceCard(
            prefix: "Z",
            prefixStyle: .none,
            title: "No Prefix Style with Prefix Value",
            subtitle: "Sub"
        ) {}
        XCTAssertEqual(withPrefixCard.prefix, "Z")
        XCTAssertEqual(withPrefixCard.prefixStyle, .none)
        XCTAssertNotNil(withPrefixCard.body)
    }

    func testChoiceCardLocalizedPrefixStyles() {
        for prefixStyle in CraftChoicePrefixStyle.allCases {
            let localizedCard = CraftChoiceCard(
                prefix: LocalizedStringKey("key.prefix"),
                prefixStyle: prefixStyle,
                title: LocalizedStringKey("key.title"),
                subtitle: LocalizedStringKey("key.subtitle"),
                state: .correct,
                style: .elevated
            ) {}
            XCTAssertEqual(localizedCard.prefixStyle, prefixStyle)
            XCTAssertNil(localizedCard.prefix)
            XCTAssertNil(localizedCard.title)
            XCTAssertNil(localizedCard.subtitle)
            XCTAssertEqual(localizedCard.state, .correct)
            XCTAssertEqual(localizedCard.style, .elevated)
            XCTAssertNotNil(localizedCard.body)
        }
    }

    func testChoiceCardAllPrefixStylesWithAllStatesAndSurfaceStyles() {
        for prefixStyle in CraftChoicePrefixStyle.allCases {
            for surfaceStyle in CraftSurfaceStyle.allCases {
                for state in CraftChoiceState.allCases {
                    let card = CraftChoiceCard(
                        prefix: "X",
                        prefixStyle: prefixStyle,
                        title: "Prefix \(prefixStyle.rawValue) in \(surfaceStyle.rawValue)",
                        subtitle: "State \(state.rawValue)",
                        state: state,
                        style: surfaceStyle
                    ) {}
                    XCTAssertEqual(card.prefix, "X")
                    XCTAssertEqual(card.prefixStyle, prefixStyle)
                    XCTAssertEqual(card.state, state)
                    XCTAssertEqual(card.style, surfaceStyle)
                    XCTAssertNotNil(card.body)
                }
            }
        }
    }

    // MARK: - CraftFlipCard Tests

    func testFlipCardBinding() {
        var flipped = false
        let binding = Binding(get: { flipped }, set: { flipped = $0 })
        let flipCard = CraftFlipCard(isFlipped: binding) {
            Text("Front")
        } back: {
            Text("Back")
        }

        XCTAssertFalse(flipCard.isFlipped)
        XCTAssertEqual(flipCard.axis, .horizontal)
        XCTAssertNotNil(flipCard.body)

        // Toggle state
        flipped = true
        XCTAssertTrue(flipCard.isFlipped)
    }

    func testFlipCardVerticalAxis() {
        var flipped = true
        let binding = Binding(get: { flipped }, set: { flipped = $0 })
        let flipCard = CraftFlipCard(isFlipped: binding, axis: .vertical) {
            Text("Front Side")
        } back: {
            Text("Back Side")
        }

        XCTAssertTrue(flipCard.isFlipped)
        XCTAssertEqual(flipCard.axis, .vertical)
        XCTAssertNotNil(flipCard.body)
    }

    func testFlipCardCustomContentRendering() {
        var flipped = false
        let binding = Binding(get: { flipped }, set: { flipped = $0 })
        let flipCard = CraftFlipCard(isFlipped: binding) {
            VStack {
                Text("Question")
                Image(systemName: "questionmark")
            }
        } back: {
            VStack {
                Text("Answer")
                Image(systemName: "checkmark")
            }
        }

        XCTAssertNotNil(flipCard.front)
        XCTAssertNotNil(flipCard.back)
        XCTAssertNotNil(flipCard.body)
    }

    func testFlipCardSpecularGlareAndEdgeThickness() {
        var flipped = false
        let binding = Binding(get: { flipped }, set: { flipped = $0 })
        let flipCard = CraftFlipCard(
            isFlipped: binding,
            axis: .horizontal,
            edgeThickness: 3,
            showSpecularGlare: true,
            cornerRadius: 20
        ) {
            Text("Front Card")
        } back: {
            Text("Back Card")
        }

        XCTAssertEqual(flipCard.edgeThickness, 3)
        XCTAssertTrue(flipCard.showSpecularGlare)
        XCTAssertEqual(flipCard.cornerRadius, 20)
        XCTAssertEqual(flipCard.axis, .horizontal)
        XCTAssertNotNil(flipCard.body)
    }

    func testSpecularGlareModifierAnimatableData() {
        var modifier = CraftSpecularGlareModifier(progress: 0.25, axis: .horizontal, cornerRadius: 16, isEnabled: true)
        XCTAssertEqual(modifier.animatableData, 0.25, accuracy: 0.001)

        modifier.animatableData = 0.75
        XCTAssertEqual(modifier.animatableData, 0.75, accuracy: 0.001)

        let modifiedView = Text("Glossy Card").modifier(modifier)
        XCTAssertNotNil(modifiedView)
    }

    func testSpecularGlareModifierAdaptation() {
        var glareDark = CraftSpecularGlareModifier(progress: 0.5, axis: .horizontal, cornerRadius: 16, isEnabled: true, colorScheme: .dark)
        XCTAssertEqual(glareDark.progress, 0.5)
        XCTAssertEqual(glareDark.colorScheme, .dark)

        glareDark.animatableData = 0.75
        XCTAssertEqual(glareDark.progress, 0.75)

        let glareLight = CraftSpecularGlareModifier(progress: 0.5, axis: .vertical, cornerRadius: 12, isEnabled: true, colorScheme: .light)
        XCTAssertEqual(glareLight.colorScheme, .light)
        XCTAssertEqual(glareLight.axis, .vertical)
    }

    func testFlipCardVerticalAxisWithSpecularDisabled() {
        var flipped = true
        let binding = Binding(get: { flipped }, set: { flipped = $0 })
        let flipCard = CraftFlipCard(
            isFlipped: binding,
            axis: .vertical,
            edgeThickness: 0,
            showSpecularGlare: false
        ) {
            Text("No Glare Front")
        } back: {
            Text("No Glare Back")
        }

        XCTAssertEqual(flipCard.edgeThickness, 0)
        XCTAssertFalse(flipCard.showSpecularGlare)
        XCTAssertEqual(flipCard.axis, .vertical)
        XCTAssertNotNil(flipCard.body)
    }

    func testFlipCardPerspectiveAndCustomAnimation() {
        var flipped = false
        let binding = Binding(get: { flipped }, set: { flipped = $0 })
        let flipCard = CraftFlipCard(
            isFlipped: binding,
            perspective: 0.75,
            animation: .spring(response: 0.4, dampingFraction: 0.8)
        ) {
            Text("Custom Front")
        } back: {
            Text("Custom Back")
        }

        XCTAssertEqual(flipCard.perspective, 0.75)
        XCTAssertNotNil(flipCard.animation)
        XCTAssertNotNil(flipCard.body)
    }

    func testFlipCardLocalizationKeys() {
        let flipToBackEn = CraftLocalized.string("craft.flipcard.flip_to_back_action")
        let flipToFrontEn = CraftLocalized.string("craft.flipcard.flip_to_front_action")
        let frontA11y = CraftLocalized.string("craft.flipcard.front_side_hint")
        let backA11y = CraftLocalized.string("craft.flipcard.back_side_hint")

        XCTAssertEqual(flipToBackEn, "Flip to back")
        XCTAssertEqual(flipToFrontEn, "Flip to front")
        XCTAssertEqual(frontA11y, "Front of card")
        XCTAssertEqual(backA11y, "Back of card")

        XCTAssertEqual(CraftLocalized.string("craft.flipcard.flip_to_back_action", language: "vi"), "Lật ra mặt sau")
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.flip_to_front_action", language: "vi"), "Lật ra mặt trước")
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.front_side_hint", language: "vi"), "Mặt trước của thẻ")
        XCTAssertEqual(CraftLocalized.string("craft.flipcard.back_side_hint", language: "vi"), "Mặt sau của thẻ")

        XCTAssertFalse(flipToBackEn.isEmpty)
        XCTAssertFalse(flipToFrontEn.isEmpty)
        XCTAssertFalse(frontA11y.isEmpty)
        XCTAssertFalse(backA11y.isEmpty)
    }

    func testFlipCardModernizedInitializersAndFeatures() {
        var flipped = false
        let binding = Binding(get: { flipped }, set: { flipped = $0 })
        let card = CraftFlipCard(
            isFlipped: binding,
            axis: .horizontal,
            edgeThickness: 3,
            showSpecularGlare: true,
            showsHighlightBorder: false,
            isTapToFlipEnabled: true,
            cornerRadius: 16,
            perspective: 0.45
        ) {
            Text("Front")
        } back: {
            Text("Back")
        }

        XCTAssertFalse(card.isFlipped)
        XCTAssertEqual(card.showsHighlightBorder, false)
        XCTAssertEqual(card.isTapToFlipEnabled, true)
        XCTAssertEqual(card.perspective, 0.45)
        XCTAssertNotNil(card.body)
    }

    // MARK: - Craft3DFlipModifier Tests

    func test3DFlipModifierCullingAndDegrees() {
        // Front side at resting state (t = 0.0)
        var frontModifier = Craft3DFlipModifier(progress: 0.0, side: .front, axis: .horizontal, perspective: 0.45, reduceMotion: false)
        XCTAssertTrue(frontModifier.isVisible)
        XCTAssertEqual(frontModifier.currentDegrees, 0.0, accuracy: 0.001)

        // Front side just before midpoint (t = 0.49)
        frontModifier.animatableData = 0.49
        XCTAssertTrue(frontModifier.isVisible)
        XCTAssertEqual(frontModifier.currentDegrees, 0.49 * 180.0, accuracy: 0.001)

        // Front side at/past midpoint (t = 0.50, t = 0.80) -> must be hidden
        frontModifier.animatableData = 0.50
        XCTAssertFalse(frontModifier.isVisible)
        frontModifier.animatableData = 0.80
        XCTAssertFalse(frontModifier.isVisible)

        // Back side at resting front state (t = 0.0) -> must be hidden
        var backModifier = Craft3DFlipModifier(progress: 0.0, side: .back, axis: .horizontal, perspective: 0.45, reduceMotion: false)
        XCTAssertFalse(backModifier.isVisible)

        // Back side at/past midpoint (t = 0.50, t = 1.0) -> must be visible
        backModifier.animatableData = 0.50
        XCTAssertTrue(backModifier.isVisible)
        XCTAssertEqual(backModifier.currentDegrees, (0.50 - 1.0) * 180.0, accuracy: 0.001)

        backModifier.animatableData = 1.0
        XCTAssertTrue(backModifier.isVisible)
        XCTAssertEqual(backModifier.currentDegrees, 0.0, accuracy: 0.001)

        // Reduce motion behavior
        let reduceMotionModifier = Craft3DFlipModifier(progress: 0.2, side: .front, axis: .horizontal, perspective: 0.45, reduceMotion: true)
        XCTAssertEqual(reduceMotionModifier.currentDegrees, 0.0)
    }
}

