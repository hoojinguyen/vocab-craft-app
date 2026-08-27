import XCTest
import SwiftUI
@testable import CraftUIKit

final class ControlComponentTests: XCTestCase {

    // MARK: - CraftButton Tests

    func testButtonVariantsAndSizes() {
        let button = CraftButton("Submit", variant: .primary, size: .lg, isLoading: false) {}
        XCTAssertEqual(button.title, "Submit")
        XCTAssertEqual(button.variant, .primary)
        XCTAssertEqual(button.size, .lg)
        XCTAssertEqual(button.size.height, 54)
    }

    func testButtonSizeHeights() {
        XCTAssertEqual(CraftButtonSize.sm.height, 32)
        XCTAssertEqual(CraftButtonSize.md.height, 44)
        XCTAssertEqual(CraftButtonSize.lg.height, 54)
    }

    func testButtonAllVariants() {
        for variant in CraftButtonVariant.allCases {
            for size in CraftButtonSize.allCases {
                let btn = CraftButton("Test", iconName: "arrow.right", variant: variant, size: size, isLoading: false) {}
                XCTAssertEqual(btn.variant, variant)
                XCTAssertEqual(btn.size, size)
                XCTAssertEqual(btn.iconName, "arrow.right")
                XCTAssertNotNil(btn.body)
            }
        }
    }

    func testButtonLoadingState() {
        let loadingBtn = CraftButton("Saving", variant: .primary, size: .md, isLoading: true) {}
        XCTAssertTrue(loadingBtn.isLoading)
        XCTAssertNotNil(loadingBtn.body)
    }

    func testButtonActionExecution() {
        var actionFired = false
        let button = CraftButton("Tap Me") {
            actionFired = true
        }
        button.action()
        XCTAssertTrue(actionFired)
    }

    func testButtonSquashAndStretchMotion() {
        let button = CraftButton("Animate Me") {}
        XCTAssertNotNil(button.body)
    }

    func testButtonLocalizationAndVerbatim() {
        let localizedButton = CraftButton(LocalizedStringKey("start_quiz"), variant: .primary) {}
        XCTAssertNil(localizedButton.title)
        XCTAssertEqual(localizedButton.variant, .primary)
        XCTAssertNotNil(localizedButton.body)

        let verbatimButton = CraftButton(verbatim: "Custom Action", variant: .outline, size: .sm) {}
        XCTAssertEqual(verbatimButton.title, "Custom Action")
        XCTAssertEqual(verbatimButton.variant, .outline)
        XCTAssertEqual(verbatimButton.size, .sm)
        XCTAssertNotNil(verbatimButton.body)
    }

    func testButtonIconPositions() {
        let leadingIconBtn = CraftButton("Next", iconName: "arrow.forward", iconPosition: .leading) {}
        XCTAssertEqual(leadingIconBtn.iconPosition, .leading)
        XCTAssertEqual(leadingIconBtn.iconName, "arrow.forward")
        XCTAssertNotNil(leadingIconBtn.body)

        let trailingIconBtn = CraftButton("Next", iconName: "arrow.right", iconPosition: .trailing) {}
        XCTAssertEqual(trailingIconBtn.iconPosition, .trailing)
        XCTAssertEqual(trailingIconBtn.iconName, "arrow.right")
        XCTAssertNotNil(trailingIconBtn.body)
    }

    func testButtonTactileVariant() {
        let button = CraftButton("PRACTICE", variant: .tactile, size: .lg, isUppercase: true, tracking: 1.2, isFullWidth: true) {}
        XCTAssertEqual(button.variant, .tactile)
        XCTAssertEqual(button.size, .lg)
        XCTAssertTrue(button.isUppercase)
        XCTAssertEqual(button.tracking, 1.2)
        XCTAssertTrue(button.isFullWidth)
        XCTAssertNotNil(button.body)
    }

    func testButtonTactileAllSizes() {
        for size in CraftButtonSize.allCases {
            let button = CraftButton("TACTILE", variant: .tactile, size: size) {}
            XCTAssertEqual(button.variant, .tactile)
            XCTAssertEqual(button.size, size)
            XCTAssertNotNil(button.body)
        }
    }

    func testButtonTactileNativeStyle() {
        let view = Button("Practice") {}.buttonStyle(.craftTactile())
        XCTAssertNotNil(view)

        let smView = Button("Small Tactile") {}.buttonStyle(.craftTactile(size: .sm))
        XCTAssertNotNil(smView)

        let lgLoadingView = Button("Large Tactile Loading") {}.buttonStyle(.craftTactile(size: .lg, isLoading: true))
        XCTAssertNotNil(lgLoadingView)
    }

    func testNativeButtonStyles() {
        let view = VStack {
            Button("Primary") {}.buttonStyle(.craftPrimary())
            Button("Secondary") {}.buttonStyle(.craftSecondary())
            Button("Outline") {}.buttonStyle(.craftOutline())
            Button("Ghost") {}.buttonStyle(.craftGhost())
            Button("Danger") {}.buttonStyle(.craftDanger())
            Button("Tactile") {}.buttonStyle(.craftTactile())
        }
        XCTAssertNotNil(view)
    }

    // MARK: - CraftInteractiveButtonStyle Tests

    func testInteractiveButtonStyleInstantiation() {
        let defaultStyle = CraftInteractiveButtonStyle()
        XCTAssertEqual(defaultStyle.scale, 0.97)
        XCTAssertEqual(defaultStyle.opacity, 1.0)

        let customStyle = CraftInteractiveButtonStyle(scale: 0.92, opacity: 0.85)
        XCTAssertEqual(customStyle.scale, 0.92)
        XCTAssertEqual(customStyle.opacity, 0.85)
    }

    func testInteractiveButtonStyleConvenience() {
        let defaultStyle: CraftInteractiveButtonStyle = .craftPress()
        XCTAssertEqual(defaultStyle.scale, 0.97)
        XCTAssertEqual(defaultStyle.opacity, 1.0)

        let customStyle: CraftInteractiveButtonStyle = .craftPress(scale: 0.94, opacity: 0.8)
        XCTAssertEqual(customStyle.scale, 0.94)
        XCTAssertEqual(customStyle.opacity, 0.8)
    }

    func testInteractiveButtonStyleApplication() {
        let button = Button("Interactive Button") {}
            .buttonStyle(.craftPress())
        XCTAssertNotNil(button)

        let customButton = Button("Interactive Button Custom") {}
            .buttonStyle(.craftPress(scale: 0.92, opacity: 0.85))
        XCTAssertNotNil(customButton)
    }

    func testCraftPressEffectViewModifier() {
        let view = Text("Press Me")
            .craftPressEffect()
        XCTAssertNotNil(view)

        let customView = Text("Press Me Custom")
            .craftPressEffect(scale: 0.93, opacity: 0.9, hapticFeedback: false)
        XCTAssertNotNil(customView)

        let explicitModifier = Text("Press Modifier")
            .modifier(CraftPressEffectModifier(scale: 0.95, opacity: 0.8, hapticFeedback: true))
        XCTAssertNotNil(explicitModifier)
    }

    // MARK: - CraftTextField Tests

    func testTextFieldInitAndProperties() {
        var text = "Hello"
        let textField = CraftTextField(
            placeholder: "Enter name",
            text: Binding(get: { text }, set: { text = $0 }),
            label: "Name",
            helperText: "Your full name",
            errorMessage: nil,
            leadingIcon: "person.fill",
            isSecure: false
        )

        XCTAssertEqual(textField.placeholder, "Enter name")
        XCTAssertEqual(textField.text.wrappedValue, "Hello")
        XCTAssertEqual(textField.label, "Name")
        XCTAssertEqual(textField.helperText, "Your full name")
        XCTAssertNil(textField.errorMessage)
        XCTAssertEqual(textField.leadingIcon, "person.fill")
        XCTAssertFalse(textField.isSecure)
        XCTAssertFalse(textField.hasError)
        XCTAssertNotNil(textField.body)
    }

    func testTextFieldErrorState() {
        var text = ""
        let errorField = CraftTextField(
            placeholder: "Email",
            text: Binding(get: { text }, set: { text = $0 }),
            errorMessage: "Invalid email address"
        )
        XCTAssertEqual(errorField.errorMessage, "Invalid email address")
        XCTAssertTrue(errorField.hasError)
        XCTAssertNotNil(errorField.body)
    }

    func testTextFieldLocalization() {
        var text = "Localized Value"
        let localizedField = CraftTextField(
            LocalizedStringKey("placeholder_key"),
            text: Binding(get: { text }, set: { text = $0 }),
            label: LocalizedStringKey("label_key"),
            helperText: LocalizedStringKey("helper_key"),
            errorMessage: LocalizedStringKey("error_key"),
            leadingIcon: "envelope.fill",
            isSecure: true
        )
        XCTAssertTrue(localizedField.hasError)
        XCTAssertTrue(localizedField.isSecure)
        XCTAssertEqual(localizedField.leadingIcon, "envelope.fill")
        XCTAssertNotNil(localizedField.body)
    }

    // MARK: - CraftSearchBar Tests

    func testSearchBarInit() {
        var query = "swift"
        let searchBar = CraftSearchBar(
            text: Binding(get: { query }, set: { query = $0 }),
            placeholder: "Search vocabulary..."
        )

        XCTAssertEqual(searchBar.text.wrappedValue, "swift")
        XCTAssertEqual(searchBar.placeholder, "Search vocabulary...")
        XCTAssertEqual(searchBar.style, .standard)
        XCTAssertEqual(searchBar.shape, .capsule)
        XCTAssertNil(searchBar.trailingIcon)
        XCTAssertNotNil(searchBar.body)
    }

    func testSearchBarRecessedStyleAndShape() {
        var query = "vocab"
        let searchBar = CraftSearchBar(
            text: Binding(get: { query }, set: { query = $0 }),
            placeholder: "Search words",
            style: .recessed,
            shape: .roundedRectangle(radius: 14),
            trailingIcon: "slider.horizontal.3",
            trailingAction: {}
        )
        XCTAssertEqual(searchBar.style, .recessed)
        XCTAssertEqual(searchBar.shape, .roundedRectangle(radius: 14))
        XCTAssertEqual(searchBar.trailingIcon, "slider.horizontal.3")
        XCTAssertNotNil(searchBar.body)
    }

    func testSearchBarDefaults() {
        var query = ""
        let searchBar = CraftSearchBar(text: Binding(get: { query }, set: { query = $0 }))
        XCTAssertEqual(searchBar.placeholder, "Search...")
        XCTAssertNotNil(searchBar.body)
    }

    func testSearchBarLocalization() {
        var query = ""
        let searchBar = CraftSearchBar(
            text: Binding(get: { query }, set: { query = $0 }),
            placeholder: LocalizedStringKey("search_placeholder")
        )
        XCTAssertNotNil(searchBar.body)
    }

    func testSearchBarFullSpectrumStyles() {
        XCTAssertEqual(CraftSearchBarStyle.allCases.count, 7)
        XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.standard))
        XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.flat))
        XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.elevated))
        XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.outlined))
        XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.recessed))
        XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.tactile3D))
        XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.glass))

        for style in CraftSearchBarStyle.allCases {
            var query = "test"
            let searchBar = CraftSearchBar(
                text: Binding(get: { query }, set: { query = $0 }),
                placeholder: "Search in \(style.rawValue)...",
                style: style,
                customTint: .teal
            )
            XCTAssertEqual(searchBar.style, style)
            XCTAssertEqual(searchBar.customTint, .teal)
            XCTAssertNotNil(searchBar.body)
        }
    }

    func testSearchBarSizesAndLoadingState() {
        XCTAssertEqual(CraftSearchBarSize.allCases.count, 3)
        XCTAssertEqual(CraftSearchBarSize.sm.height, 36)
        XCTAssertEqual(CraftSearchBarSize.md.height, 44)
        XCTAssertEqual(CraftSearchBarSize.lg.height, 52)

        for size in CraftSearchBarSize.allCases {
            var query = "size test"
            let searchBar = CraftSearchBar(
                text: Binding(get: { query }, set: { query = $0 }),
                size: size,
                isLoading: true
            )
            XCTAssertEqual(searchBar.size, size)
            XCTAssertTrue(searchBar.isLoading)
            XCTAssertNotNil(searchBar.body)
        }
    }


    // MARK: - CraftToggle Tests

    func testToggleInitAndProperties() {
        var isOn = true
        let toggle = CraftToggle(
            isOn: Binding(get: { isOn }, set: { isOn = $0 }),
            title: "Dark Mode",
            subtitle: "Use dark appearance",
            iconName: "moon.fill"
        )

        XCTAssertTrue(toggle.isOn.wrappedValue)
        XCTAssertEqual(toggle.title, "Dark Mode")
        XCTAssertEqual(toggle.subtitle, "Use dark appearance")
        XCTAssertEqual(toggle.iconName, "moon.fill")
        XCTAssertNotNil(toggle.body)
    }

    func testToggleStyleApplication() {
        var isOn = false
        let view = Toggle("Sound Effects", isOn: Binding(get: { isOn }, set: { isOn = $0 }))
            .toggleStyle(.craft)
        XCTAssertNotNil(view)
    }

    func testToggleLocalization() {
        var isOn = true
        let toggle = CraftToggle(
            isOn: Binding(get: { isOn }, set: { isOn = $0 }),
            title: LocalizedStringKey("toggle_title"),
            subtitle: LocalizedStringKey("toggle_subtitle"),
            iconName: "bell.fill"
        )
        XCTAssertTrue(toggle.isOn.wrappedValue)
        XCTAssertNil(toggle.title)
        XCTAssertNil(toggle.subtitle)
        XCTAssertEqual(toggle.iconName, "bell.fill")
        XCTAssertNotNil(toggle.body)
    }

    // MARK: - CraftStepper Tests

    func testStepperBounds() {
        var value = 10
        let stepper = CraftStepper(
            value: Binding(get: { value }, set: { value = $0 }),
            range: 5...50,
            step: 5,
            unit: "words",
            label: "Target Count"
        )

        XCTAssertEqual(stepper.value.wrappedValue, 10)
        XCTAssertEqual(stepper.range, 5...50)
        XCTAssertEqual(stepper.step, 5)
        XCTAssertEqual(stepper.unit, "words")
        XCTAssertEqual(stepper.label, "Target Count")
        XCTAssertNotNil(stepper.body)
    }

    func testStepperIncrementAndDecrement() {
        var value = 10
        let binding = Binding(get: { value }, set: { value = $0 })
        let stepper = CraftStepper(value: binding, range: 0...20, step: 5)

        stepper.increment()
        XCTAssertEqual(value, 15)

        stepper.increment()
        XCTAssertEqual(value, 20)

        // Cannot increment past upper bound
        stepper.increment()
        XCTAssertEqual(value, 20)

        stepper.decrement()
        XCTAssertEqual(value, 15)

        stepper.decrement()
        stepper.decrement()
        stepper.decrement()
        // Cannot decrement below lower bound
        XCTAssertEqual(value, 0)
    }

    func testStepperLocalization() {
        var value = 5
        let stepper = CraftStepper(
            value: Binding(get: { value }, set: { value = $0 }),
            range: 1...10,
            step: 1,
            unit: LocalizedStringKey("stepper_unit"),
            label: LocalizedStringKey("stepper_label")
        )
        XCTAssertNil(stepper.unit)
        XCTAssertNil(stepper.label)
        XCTAssertEqual(stepper.value.wrappedValue, 5)
        XCTAssertNotNil(stepper.body)
    }

    // MARK: - CraftPill / CraftFilterChip Tests

    func testPillInitAndProperties() {
        var isSelected = true
        var tapCount = 0
        let pill = CraftPill(
            "Beginner",
            iconName: "bookmark",
            count: 42,
            isSelected: isSelected
        ) {
            tapCount += 1
            isSelected.toggle()
        }

        XCTAssertEqual(pill.title, "Beginner")
        XCTAssertEqual(pill.iconName, "bookmark")
        XCTAssertEqual(pill.count, 42)
        XCTAssertTrue(pill.isSelected)
        XCTAssertNotNil(pill.body)

        pill.action()
        XCTAssertEqual(tapCount, 1)
        XCTAssertFalse(isSelected)
    }

    func testFilterChipTypeAlias() {
        let chip = CraftFilterChip("Grammar", isSelected: false) {}
        XCTAssertEqual(chip.title, "Grammar")
        XCTAssertFalse(chip.isSelected)
        XCTAssertNotNil(chip.body)
    }

    func testPillLocalization() {
        var tapped = false
        let pill = CraftPill(
            LocalizedStringKey("pill_title"),
            iconName: "star",
            count: 10,
            isSelected: true
        ) {
            tapped = true
        }
        XCTAssertNil(pill.title)
        XCTAssertEqual(pill.iconName, "star")
        XCTAssertEqual(pill.count, 10)
        XCTAssertTrue(pill.isSelected)
        XCTAssertNotNil(pill.body)
        pill.action()
        XCTAssertTrue(tapped)
    }

    // MARK: - Upgraded Controls Surface Styles & Zero Hardcoding Tests

    func testButtonSurfaceStylesAndCustomGradients() {
        let gradient = LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let glassButton = CraftButton(
            "Glass Button",
            variant: .primary,
            style: .glass,
            customTint: .blue,
            customGradient: gradient
        ) {}

        XCTAssertEqual(glassButton.style, .glass)
        XCTAssertEqual(glassButton.customTint, .blue)
        XCTAssertNotNil(glassButton.customGradient)
        XCTAssertNotNil(glassButton.body)

        // Test all 5 surface styles rendering on CraftButton
        for surfaceStyle in CraftSurfaceStyle.allCases {
            let btn = CraftButton(
                "Style \(surfaceStyle.rawValue)",
                style: surfaceStyle,
                customTint: .teal
            ) {}
            XCTAssertEqual(btn.style, surfaceStyle)
            XCTAssertNotNil(btn.body)
        }

        // Test native button styles with style and gradient
        let nativeGlass = Button("Native Glass") {}.buttonStyle(.craftGlass(customTint: .pink, customGradient: gradient))
        XCTAssertNotNil(nativeGlass)

        let nativePrimaryStyled = Button("Native Styled") {}.buttonStyle(.craftPrimary(style: .elevated, customTint: .indigo))
        XCTAssertNotNil(nativePrimaryStyled)
    }

    func testButtonLoadingAccessibility() {
        let loadingBtn = CraftButton("Submit", isLoading: true) {}
        XCTAssertTrue(loadingBtn.isLoading)
        XCTAssertNotNil(loadingBtn.body)

        let localizedLoadingBtn = CraftButton(LocalizedStringKey("submit_key"), isLoading: true) {}
        XCTAssertTrue(localizedLoadingBtn.isLoading)
        XCTAssertNotNil(localizedLoadingBtn.body)

        let loadingString = CraftLocalized.string("craft.button.loading_a11y")
        XCTAssertEqual(loadingString, "Loading")
        let viLoadingString = CraftLocalized.string("craft.button.loading_a11y", language: "vi")
        XCTAssertEqual(viLoadingString, "Đang tải")
    }

    func testChoiceCardAllFiveSurfaceStyles() {
        for style in CraftSurfaceStyle.allCases {
            for state in CraftChoiceState.allCases {
                let card = CraftChoiceCard(
                    prefix: "A",
                    title: "Choice in \(style.rawValue)",
                    subtitle: "Subtitle for \(state.rawValue)",
                    state: state,
                    style: style
                ) {}
                XCTAssertEqual(card.style, style)
                XCTAssertEqual(card.state, state)
                XCTAssertNotNil(card.body)
            }
        }
    }

    func testChoiceCardAllPrefixStyles() {
        let styles: [CraftChoicePrefixStyle] = [.circle, .roundedSquare, .minimal, .none]
        XCTAssertEqual(CraftChoicePrefixStyle.allCases.count, 4)

        for prefixStyle in styles {
            let card = CraftChoiceCard(
                prefix: "1",
                prefixStyle: prefixStyle,
                title: "Title \(prefixStyle.rawValue)",
                subtitle: "Subtitle \(prefixStyle.rawValue)",
                state: .idle,
                style: .tactile3D
            ) {}

            XCTAssertEqual(card.prefix, "1")
            XCTAssertEqual(card.prefixStyle, prefixStyle)
            XCTAssertEqual(card.title, "Title \(prefixStyle.rawValue)")
            XCTAssertEqual(card.subtitle, "Subtitle \(prefixStyle.rawValue)")
            XCTAssertEqual(card.state, .idle)
            XCTAssertEqual(card.style, .tactile3D)
            XCTAssertNotNil(card.body)

            // Also test with LocalizedStringKey
            let localizedCard = CraftChoiceCard(
                prefix: LocalizedStringKey("prefix_\(prefixStyle.rawValue)"),
                prefixStyle: prefixStyle,
                title: LocalizedStringKey("title_\(prefixStyle.rawValue)"),
                subtitle: LocalizedStringKey("subtitle_\(prefixStyle.rawValue)"),
                state: .selected,
                style: .glass
            ) {}

            XCTAssertEqual(localizedCard.prefixStyle, prefixStyle)
            XCTAssertNil(localizedCard.prefix)
            XCTAssertNil(localizedCard.title)
            XCTAssertNil(localizedCard.subtitle)
            XCTAssertEqual(localizedCard.state, .selected)
            XCTAssertEqual(localizedCard.style, .glass)
            XCTAssertNotNil(localizedCard.body)
        }
    }

    func testChoiceCardDefaultPrefixStyleIsCircle() {
        // Test default with title only
        let defaultCard = CraftChoiceCard(title: "Default Option") {}
        XCTAssertEqual(defaultCard.prefixStyle, .circle)
        XCTAssertEqual(defaultCard.prefix, "A")
        XCTAssertEqual(defaultCard.title, "Default Option")
        XCTAssertNil(defaultCard.subtitle)
        XCTAssertEqual(defaultCard.state, .idle)
        XCTAssertEqual(defaultCard.style, .tactile3D)

        // Test default with custom prefix, title, subtitle, state, style omitting prefixStyle
        let explicitCard = CraftChoiceCard(
            prefix: "B",
            title: "Option B",
            subtitle: "Secondary info",
            state: .selected,
            style: .outlined
        ) {}
        XCTAssertEqual(explicitCard.prefixStyle, .circle)
        XCTAssertEqual(explicitCard.prefix, "B")
        XCTAssertEqual(explicitCard.title, "Option B")
        XCTAssertEqual(explicitCard.subtitle, "Secondary info")
        XCTAssertEqual(explicitCard.state, .selected)
        XCTAssertEqual(explicitCard.style, .outlined)

        // Test localized initializer omitting prefixStyle
        let localizedDefaultCard = CraftChoiceCard(
            title: LocalizedStringKey("choice.title")
        ) {}
        XCTAssertEqual(localizedDefaultCard.prefixStyle, .circle)
        XCTAssertNil(localizedDefaultCard.prefix)
        XCTAssertEqual(localizedDefaultCard.state, .idle)

        let localizedExplicitCard = CraftChoiceCard(
            prefix: LocalizedStringKey("choice.prefix"),
            title: LocalizedStringKey("choice.title"),
            subtitle: LocalizedStringKey("choice.subtitle"),
            state: .correct,
            style: .elevated
        ) {}
        XCTAssertEqual(localizedExplicitCard.prefixStyle, .circle)
        XCTAssertEqual(localizedExplicitCard.state, .correct)
        XCTAssertEqual(localizedExplicitCard.style, .elevated)
    }

    func testChoiceCardAccessibilityValues() {
        // Verify accessibility localized string lookup for all states
        XCTAssertEqual(CraftLocalized.string("craft.choice.selected_a11y"), "Selected")
        XCTAssertEqual(CraftLocalized.string("craft.choice.correct_a11y"), "Correct Answer")
        XCTAssertEqual(CraftLocalized.string("craft.choice.wrong_a11y"), "Incorrect Answer")
        XCTAssertEqual(CraftLocalized.string("craft.choice.disabled_a11y"), "Disabled")

        // Vietnamese accessibility translations
        XCTAssertEqual(CraftLocalized.string("craft.choice.selected_a11y", language: "vi"), "Đã chọn")
        XCTAssertEqual(CraftLocalized.string("craft.choice.correct_a11y", language: "vi"), "Đáp án đúng")
        XCTAssertEqual(CraftLocalized.string("craft.choice.wrong_a11y", language: "vi"), "Đáp án chưa đúng")
        XCTAssertEqual(CraftLocalized.string("craft.choice.disabled_a11y", language: "vi"), "Vô hiệu hóa")

        // Verify card body instantiates without errors for all states and prefix styles
        for prefixStyle in CraftChoicePrefixStyle.allCases {
            for state in CraftChoiceState.allCases {
                let card = CraftChoiceCard(
                    prefix: "A",
                    prefixStyle: prefixStyle,
                    title: "Accessibility Test \(state.rawValue)",
                    subtitle: "Subtitle \(state.rawValue)",
                    state: state
                ) {}
                XCTAssertEqual(card.state, state)
                XCTAssertEqual(card.prefixStyle, prefixStyle)
                XCTAssertNotNil(card.body)
            }
        }
    }

    func testChoiceCardZeroHardcodingAndLocalization() {
        let selectedA11y = CraftLocalized.string("craft.choice.selected_a11y")
        XCTAssertEqual(selectedA11y, "Selected")

        let correctA11y = CraftLocalized.string("craft.choice.correct_a11y")
        XCTAssertEqual(correctA11y, "Correct Answer")

        let wrongA11y = CraftLocalized.string("craft.choice.wrong_a11y")
        XCTAssertEqual(wrongA11y, "Incorrect Answer")

        let disabledA11y = CraftLocalized.string("craft.choice.disabled_a11y")
        XCTAssertEqual(disabledA11y, "Disabled")

        // Test Vietnamese localization
        XCTAssertEqual(CraftLocalized.string("craft.choice.selected_a11y", language: "vi"), "Đã chọn")
        XCTAssertEqual(CraftLocalized.string("craft.choice.correct_a11y", language: "vi"), "Đáp án đúng")
        XCTAssertEqual(CraftLocalized.string("craft.choice.wrong_a11y", language: "vi"), "Đáp án chưa đúng")
        XCTAssertEqual(CraftLocalized.string("craft.choice.disabled_a11y", language: "vi"), "Vô hiệu hóa")
    }

    func testChoiceCardHasSubtitleAlignment() {
        let cardWithoutSubtitle = CraftChoiceCard(title: "Single Line Option") {}
        XCTAssertFalse(cardWithoutSubtitle.hasSubtitle)

        let cardWithEmptySubtitle = CraftChoiceCard(title: "Option", subtitle: "   ") {}
        XCTAssertFalse(cardWithEmptySubtitle.hasSubtitle)

        let cardWithSubtitle = CraftChoiceCard(title: "Option", subtitle: "Detailed explanation") {}
        XCTAssertTrue(cardWithSubtitle.hasSubtitle)

        let localizedCardWithoutSubtitle = CraftChoiceCard(title: LocalizedStringKey("option.title")) {}
        XCTAssertFalse(localizedCardWithoutSubtitle.hasSubtitle)

        let localizedCardWithSubtitle = CraftChoiceCard(title: LocalizedStringKey("option.title"), subtitle: LocalizedStringKey("option.subtitle")) {}
        XCTAssertTrue(localizedCardWithSubtitle.hasSubtitle)
    }

    func testChoiceCardCustomStatusIndicatorsAndVisibility() {
        // Test indicator visibility toggles
        let cardWithIndicator = CraftChoiceCard(title: "Option", state: .correct, showsStatusIndicator: true) {}
        XCTAssertTrue(cardWithIndicator.showsStatusIndicator)
        XCTAssertNil(cardWithIndicator.correctIconName)
        XCTAssertNil(cardWithIndicator.wrongIconName)
        XCTAssertNotNil(cardWithIndicator.body)

        let cardWithoutIndicator = CraftChoiceCard(title: "Option", state: .correct, showsStatusIndicator: false) {}
        XCTAssertFalse(cardWithoutIndicator.showsStatusIndicator)
        XCTAssertNotNil(cardWithoutIndicator.body)

        // Test custom SF Symbol icon strings
        let cardCustomSF = CraftChoiceCard(
            title: "Option",
            state: .correct,
            showsStatusIndicator: true,
            correctIconName: "checkmark.seal.fill",
            wrongIconName: "xmark.octagon.fill"
        ) {}
        XCTAssertEqual(cardCustomSF.correctIconName, "checkmark.seal.fill")
        XCTAssertEqual(cardCustomSF.wrongIconName, "xmark.octagon.fill")
        XCTAssertNotNil(cardCustomSF.body)

        // Test custom CraftSymbol initializers
        let cardCustomSymbol = CraftChoiceCard(
            title: "Option",
            state: .wrong,
            showsStatusIndicator: true,
            correctSymbol: .trophy,
            wrongSymbol: .lightbulb
        ) {}
        XCTAssertEqual(cardCustomSymbol.correctIconName, CraftSymbol.trophy.rawValue)
        XCTAssertEqual(cardCustomSymbol.wrongIconName, CraftSymbol.lightbulb.rawValue)
        XCTAssertNotNil(cardCustomSymbol.body)
    }

    func testTextFieldStylesEnumAndRendering() {
        XCTAssertEqual(CraftTextFieldStyle.allCases.count, 4)
        XCTAssertTrue(CraftTextFieldStyle.allCases.contains(.standard))
        XCTAssertTrue(CraftTextFieldStyle.allCases.contains(.recessed))
        XCTAssertTrue(CraftTextFieldStyle.allCases.contains(.underlined))
        XCTAssertTrue(CraftTextFieldStyle.allCases.contains(.glass))

        for style in CraftTextFieldStyle.allCases {
            var text = "Test Input"
            let field = CraftTextField(
                placeholder: "Placeholder",
                text: Binding(get: { text }, set: { text = $0 }),
                label: "Label",
                helperText: "Helper",
                errorMessage: nil,
                leadingIcon: "magnifyingglass",
                isSecure: false,
                style: style
            )
            XCTAssertEqual(field.style, style)
            XCTAssertNotNil(field.body)

            let secureField = CraftTextField(
                placeholder: "Secure",
                text: Binding(get: { text }, set: { text = $0 }),
                isSecure: true,
                style: style
            )
            XCTAssertEqual(secureField.style, style)
            XCTAssertNotNil(secureField.body)

            let errorField = CraftTextField(
                placeholder: "Error",
                text: Binding(get: { text }, set: { text = $0 }),
                errorMessage: "Invalid",
                style: style
            )
            XCTAssertEqual(errorField.style, style)
            XCTAssertNotNil(errorField.body)
        }
    }

    func testTextFieldLocalizedConstructorsWithStyle() {
        var text = ""
        let localizedField = CraftTextField(
            LocalizedStringKey("search_key"),
            text: Binding(get: { text }, set: { text = $0 }),
            label: LocalizedStringKey("label_key"),
            style: .glass
        )
        XCTAssertEqual(localizedField.style, .glass)
        XCTAssertNotNil(localizedField.body)
    }

    func testToggleCustomTintsAndSurfaceStyles() {
        var isOn = true
        let toggle = CraftToggle(
            isOn: Binding(get: { isOn }, set: { isOn = $0 }),
            title: "Custom Tint Toggle",
            subtitle: "Subtitle",
            iconName: "flame",
            activeTint: .orange,
            inactiveTint: .gray,
            style: .glass
        )
        XCTAssertEqual(toggle.activeTint, .orange)
        XCTAssertEqual(toggle.inactiveTint, .gray)
        XCTAssertEqual(toggle.style, .glass)
        XCTAssertNotNil(toggle.body)

        // Test standalone switch with custom tints
        let craftSwitch = CraftSwitch(
            isOn: Binding(get: { isOn }, set: { isOn = $0 }),
            activeTint: .purple,
            inactiveTint: .blue,
            style: .glass
        )
        XCTAssertEqual(craftSwitch.activeTint, .purple)
        XCTAssertEqual(craftSwitch.inactiveTint, .blue)
        XCTAssertEqual(craftSwitch.style, .glass)
        XCTAssertNotNil(craftSwitch.body)

        // Test ToggleStyle convenience functions
        let customStyleView = Toggle("Label", isOn: Binding(get: { isOn }, set: { isOn = $0 }))
            .toggleStyle(.craft(activeTint: .pink, inactiveTint: .yellow, style: .glass))
        XCTAssertNotNil(customStyleView)

        let switchStyleView = Toggle("Switch", isOn: Binding(get: { isOn }, set: { isOn = $0 }))
            .toggleStyle(.craftSwitch(activeTint: .green, inactiveTint: .gray, style: .glass))
        XCTAssertNotNil(switchStyleView)
    }

    func testSearchBarGlassStyleAndLocalization() {
        XCTAssertEqual(CraftSearchBarStyle.allCases.count, 7)
        XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.standard))
        XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.recessed))
        XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.glass))

        var query = "iOS"
        let glassSearchBar = CraftSearchBar(
            text: Binding(get: { query }, set: { query = $0 }),
            placeholder: "Search glass...",
            style: .glass,
            shape: .capsule,
            onCancel: {}
        )
        XCTAssertEqual(glassSearchBar.style, .glass)
        XCTAssertNotNil(glassSearchBar.body)

        let roundedGlassSearchBar = CraftSearchBar(
            text: Binding(get: { query }, set: { query = $0 }),
            placeholder: "Search rounded...",
            style: .glass,
            shape: .roundedRectangle(radius: 16),
            onCancel: {}
        )
        XCTAssertEqual(roundedGlassSearchBar.style, .glass)
        XCTAssertNotNil(roundedGlassSearchBar.body)

        // Verify localized cancel & clear
        XCTAssertEqual(CraftLocalized.string("craft.common.action.cancel"), "Cancel")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.cancel", language: "vi"), "Hủy")
        XCTAssertEqual(CraftLocalized.string("craft.search.clear_a11y"), "Clear search")
        XCTAssertEqual(CraftLocalized.string("craft.search.clear_a11y", language: "vi"), "Xóa tìm kiếm")
        XCTAssertEqual(CraftLocalized.string("craft.search.placeholder"), "Search...")
        XCTAssertEqual(CraftLocalized.string("craft.search.placeholder", language: "vi"), "Tìm kiếm...")
        XCTAssertEqual(CraftLocalized.string("craft.search.trailing_action_a11y"), "Trailing action")
        XCTAssertEqual(CraftLocalized.string("craft.search.trailing_action_a11y", language: "vi"), "Tác vụ mở rộng")
    }

    func testPillSurfaceStylesAndCustomTint() {
        for style in CraftSurfaceStyle.allCases {
            var selected = false
            let pill = CraftPill(
                "Style \(style.rawValue)",
                iconName: "tag",
                count: 5,
                isSelected: selected,
                style: style,
                customTint: .indigo
            ) {
                selected.toggle()
            }
            XCTAssertEqual(pill.style, style)
            XCTAssertEqual(pill.customTint, .indigo)
            XCTAssertEqual(pill.resolvedStyle, style)
            XCTAssertNotNil(pill.body)

            // Test selected state
            let selectedPill = CraftPill(
                "Selected \(style.rawValue)",
                isSelected: true,
                style: style,
                customTint: .cyan
            ) {}
            XCTAssertTrue(selectedPill.isSelected)
            XCTAssertEqual(selectedPill.style, style)
            XCTAssertEqual(selectedPill.customTint, .cyan)
            XCTAssertNotNil(selectedPill.body)
        }
    }

    func testStepperSurfaceStylesAndLocalization() {
        for style in CraftSurfaceStyle.allCases {
            var val = 5
            let stepper = CraftStepper(
                value: Binding(get: { val }, set: { val = $0 }),
                range: 0...20,
                step: 1,
                unit: "pts",
                label: "Score",
                style: style
            )
            XCTAssertEqual(stepper.style, style)
            XCTAssertEqual(stepper.resolvedStyle, style)
            XCTAssertNotNil(stepper.body)
        }

        // Verify localized increase & decrease & default label strings
        XCTAssertEqual(CraftLocalized.string("craft.stepper.increase_a11y"), "Increase")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.increase_a11y", language: "vi"), "Tăng")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.decrease_a11y"), "Decrease")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.decrease_a11y", language: "vi"), "Giảm")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.default_label"), "Stepper")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.default_label", language: "vi"), "Bộ đếm")
    }

    func testTextFieldAccessibilityLocalization() {
        XCTAssertEqual(CraftLocalized.string("craft.textfield.show_password_a11y"), "Show password")
        XCTAssertEqual(CraftLocalized.string("craft.textfield.show_password_a11y", language: "vi"), "Hiện mật khẩu")
        XCTAssertEqual(CraftLocalized.string("craft.textfield.hide_password_a11y"), "Hide password")
        XCTAssertEqual(CraftLocalized.string("craft.textfield.hide_password_a11y", language: "vi"), "Ẩn mật khẩu")
    }

    func testToggleAccessibilityLocalization() {
        XCTAssertEqual(CraftLocalized.string("craft.common.state.on"), "On")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.on", language: "vi"), "Bật")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.off"), "Off")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.off", language: "vi"), "Tắt")
    }

    // MARK: - CraftSegmentedControl Tests

    func testCraftSegmentedControlOptionsAndStyles() {
        var selected = "tab1"
        var selectedCallback: String?
        let options = [
            CraftSegmentOption("tab1", title: "Tab 1", count: 5, symbol: CraftSymbol.study),
            CraftSegmentOption("tab2", title: "Tab 2", count: 10),
            CraftSegmentOption("tab3", title: "Tab 3")
        ]

        let control = CraftSegmentedControl(
            selection: Binding(get: { selected }, set: { selected = $0 }),
            options: options,
            style: .glass,
            onSelect: { selectedCallback = $0 }
        )

        XCTAssertEqual(control.options.count, 3)
        XCTAssertEqual(control.options[0].id, "tab1")
        XCTAssertEqual(control.options[0].count, 5)
        XCTAssertEqual(control.options[0].symbol, CraftSymbol.study)
        XCTAssertEqual(control.style, CraftSurfaceStyle.glass)
        XCTAssertNotNil(control.body)

        control.onSelect?("tab2")
        XCTAssertEqual(selectedCallback, "tab2")
    }

    // MARK: - CraftSpeakerButton Tests

    func testCraftSpeakerButtonInitAndProperties() {
        var played = false
        let btn = CraftSpeakerButton(
            variant: .subtle,
            size: .md,
            isPlaying: false,
            action: { played = true }
        )
        XCTAssertEqual(btn.variant, .subtle)
        XCTAssertEqual(btn.size, .md)
        XCTAssertFalse(btn.isPlaying)
        XCTAssertNil(btn.label)
        XCTAssertNotNil(btn.body)

        btn.action()
        XCTAssertTrue(played)
    }

    func testCraftSpeakerButtonPillMode() {
        let btn = CraftSpeakerButton(
            variant: .subtle,
            size: .md,
            isPlaying: true,
            label: LocalizedStringKey("craft.audio.pronounce"),
            action: {}
        )
        XCTAssertTrue(btn.isPlaying)
        XCTAssertNotNil(btn.label)
        XCTAssertNotNil(btn.body)
    }

    func testCraftSpeakerButtonAllVariantsAndSizes() {
        for variant in CraftSpeakerButtonVariant.allCases {
            for size in CraftIconSize.allCases {
                let btn = CraftSpeakerButton(
                    variant: variant,
                    size: size,
                    isPlaying: true,
                    customTint: .purple,
                    action: {}
                )
                XCTAssertEqual(btn.variant, variant)
                XCTAssertEqual(btn.size, size)
                XCTAssertTrue(btn.isPlaying)
                XCTAssertEqual(btn.customTint, .purple)
                XCTAssertNotNil(btn.body)
            }
        }
    }
}
