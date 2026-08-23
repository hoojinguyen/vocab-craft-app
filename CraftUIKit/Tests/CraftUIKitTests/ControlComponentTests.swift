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
}
