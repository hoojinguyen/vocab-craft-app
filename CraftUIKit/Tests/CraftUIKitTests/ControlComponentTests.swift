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

    func testNativeButtonStyles() {
        let view = VStack {
            Button("Primary") {}.buttonStyle(.craftPrimary())
            Button("Secondary") {}.buttonStyle(.craftSecondary())
            Button("Outline") {}.buttonStyle(.craftOutline())
            Button("Ghost") {}.buttonStyle(.craftGhost())
            Button("Danger") {}.buttonStyle(.craftDanger())
        }
        XCTAssertNotNil(view)
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

    // MARK: - CraftSearchBar Tests

    func testSearchBarInit() {
        var query = "swift"
        let searchBar = CraftSearchBar(
            text: Binding(get: { query }, set: { query = $0 }),
            placeholder: "Search vocabulary..."
        )

        XCTAssertEqual(searchBar.text.wrappedValue, "swift")
        XCTAssertEqual(searchBar.placeholder, "Search vocabulary...")
        XCTAssertNotNil(searchBar.body)
    }

    func testSearchBarDefaults() {
        var query = ""
        let searchBar = CraftSearchBar(text: Binding(get: { query }, set: { query = $0 }))
        XCTAssertEqual(searchBar.placeholder, "Search...")
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
}
