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
}
