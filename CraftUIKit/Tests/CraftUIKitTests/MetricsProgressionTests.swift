import XCTest
import SwiftUI
@testable import CraftUIKit

final class MetricsProgressionTests: XCTestCase {

    // MARK: - CraftSegmentItem Tests

    func testSegmentItemProperties() {
        let item1 = CraftSegmentItem(id: "item-1", label: "Mastered", value: 45, color: .green)
        XCTAssertEqual(item1.id, "item-1")
        XCTAssertEqual(item1.label, "Mastered")
        XCTAssertEqual(item1.value, 45)
        XCTAssertEqual(item1.color, .green)

        let itemAutoId = CraftSegmentItem(label: "Learning", value: 30, color: .blue)
        XCTAssertFalse(itemAutoId.id.isEmpty)
        XCTAssertEqual(itemAutoId.label, "Learning")
        XCTAssertEqual(itemAutoId.value, 30)
    }

    func testSegmentItemEquality() {
        let itemA = CraftSegmentItem(id: "same", label: "A", value: 10, color: .red)
        let itemB = CraftSegmentItem(id: "same", label: "A", value: 10, color: .red)
        let itemC = CraftSegmentItem(id: "diff", label: "B", value: 20, color: .blue)

        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
        XCTAssertEqual(itemA.hashValue, itemB.hashValue)
    }

    func testSegmentItemLocalization() {
        let item = CraftSegmentItem(id: "loc-1", label: LocalizedStringKey("segment_key"), value: 50, color: .purple)
        XCTAssertEqual(item.id, "loc-1")
        XCTAssertEqual(item.label, "")
        XCTAssertNotNil(item.localizedLabel)
        XCTAssertEqual(item.value, 50)
        XCTAssertEqual(item.color, .purple)
    }

    // MARK: - CraftSegmentedBar Tests

    func testSegmentedBarTotalAndRatios() {
        let items = [
            CraftSegmentItem(id: "1", label: "A", value: 30, color: .red),
            CraftSegmentItem(id: "2", label: "B", value: 70, color: .blue)
        ]
        let bar = CraftSegmentedBar(items: items)
        XCTAssertEqual(bar.totalValue, 100)
        XCTAssertEqual(bar.ratio(for: items[0]), 0.3, accuracy: 0.0001)
        XCTAssertEqual(bar.ratio(for: items[1]), 0.7, accuracy: 0.0001)
        XCTAssertEqual(bar.percentage(for: items[0]), 30, accuracy: 0.0001)
        XCTAssertEqual(bar.percentage(for: items[1]), 70, accuracy: 0.0001)
    }

    func testSegmentedBarZeroAndEmptyItems() {
        let emptyBar = CraftSegmentedBar(items: [])
        XCTAssertEqual(emptyBar.totalValue, 0)
        let dummyItem = CraftSegmentItem(id: "dummy", label: "D", value: 10, color: .red)
        XCTAssertEqual(emptyBar.ratio(for: dummyItem), 0)
        XCTAssertEqual(emptyBar.percentage(for: dummyItem), 0)

        let zeroItems = [
            CraftSegmentItem(id: "1", label: "Zero1", value: 0, color: .red),
            CraftSegmentItem(id: "2", label: "Zero2", value: 0, color: .blue)
        ]
        let zeroBar = CraftSegmentedBar(items: zeroItems)
        XCTAssertEqual(zeroBar.totalValue, 0)
        XCTAssertEqual(zeroBar.ratio(for: zeroItems[0]), 0)
        XCTAssertEqual(zeroBar.percentage(for: zeroItems[0]), 0)
    }

    func testSegmentedBarNegativeValuesClamping() {
        let items = [
            CraftSegmentItem(id: "1", label: "Negative", value: -20, color: .red),
            CraftSegmentItem(id: "2", label: "Positive", value: 50, color: .blue)
        ]
        let bar = CraftSegmentedBar(items: items)
        XCTAssertEqual(bar.totalValue, 50)
        XCTAssertEqual(bar.ratio(for: items[0]), 0)
        XCTAssertEqual(bar.ratio(for: items[1]), 1.0, accuracy: 0.0001)
    }

    func testSegmentedBarCustomOptionsAndBody() {
        let items = [
            CraftSegmentItem(id: "1", label: "A", value: 25, color: .orange),
            CraftSegmentItem(id: "2", label: "B", value: 75, color: .purple)
        ]
        let bar = CraftSegmentedBar(
            items: items,
            height: 14,
            cornerRadius: 7,
            showLegend: true,
            showPercentages: false,
            animated: false
        )
        XCTAssertEqual(bar.items, items)
        XCTAssertEqual(bar.height, 14)
        XCTAssertEqual(bar.cornerRadius, 7)
        XCTAssertTrue(bar.showLegend)
        XCTAssertFalse(bar.showPercentages)
        XCTAssertFalse(bar.animated)
        XCTAssertNotNil(bar.body)
    }

    func testSegmentedBarWithLocalizedItems() {
        let items = [
            CraftSegmentItem(label: LocalizedStringKey("known"), value: 60, color: .green),
            CraftSegmentItem(label: LocalizedStringKey("learning"), value: 40, color: .yellow)
        ]
        let bar = CraftSegmentedBar(items: items)
        XCTAssertEqual(bar.totalValue, 100)
        XCTAssertNotNil(bar.body)
    }

    // MARK: - CraftStepState Tests

    func testStepStateCases() {
        let allStates: [CraftStepState] = [.completed, .active, .locked, .upcoming]
        XCTAssertEqual(CraftStepState.allCases, allStates)
    }

    // MARK: - CraftStepNode Tests

    func testStepNodeStates() {
        let completed = CraftStepNode(title: "Stage 1", state: .completed, stepNumber: 1)
        XCTAssertEqual(completed.state, .completed)
        XCTAssertEqual(completed.stepNumber, 1)
        XCTAssertFalse(completed.isLast)
        XCTAssertNil(completed.subtitle)
        XCTAssertNil(completed.onTap)
        XCTAssertNotNil(completed.body)
    }

    func testStepNodeFullConfiguration() {
        var tapped = false
        let activeNode = CraftStepNode(
            title: "Advanced Grammar",
            subtitle: "12 lessons remaining",
            state: .active,
            stepNumber: 3,
            isLast: false,
            onTap: { tapped = true }
        )

        XCTAssertEqual(activeNode.title, "Advanced Grammar")
        XCTAssertEqual(activeNode.subtitle, "12 lessons remaining")
        XCTAssertEqual(activeNode.state, .active)
        XCTAssertEqual(activeNode.stepNumber, 3)
        XCTAssertFalse(activeNode.isLast)
        XCTAssertNotNil(activeNode.onTap)
        XCTAssertNotNil(activeNode.body)

        activeNode.onTap?()
        XCTAssertTrue(tapped)
    }

    func testStepNodeLockedAndUpcomingStates() {
        let lockedNode = CraftStepNode(
            title: "Expert Vocabulary",
            subtitle: "Unlocks at Level 10",
            state: .locked,
            stepNumber: 4,
            isLast: false
        )
        XCTAssertEqual(lockedNode.state, .locked)
        XCTAssertNotNil(lockedNode.body)

        let upcomingNode = CraftStepNode(
            title: "Final Review",
            state: .upcoming,
            stepNumber: 5,
            isLast: true
        )
        XCTAssertEqual(upcomingNode.state, .upcoming)
        XCTAssertTrue(upcomingNode.isLast)
        XCTAssertNotNil(upcomingNode.body)
    }

    func testStepNodeLocalization() {
        var tapped = false
        let node = CraftStepNode(
            title: LocalizedStringKey("step_title_key"),
            subtitle: LocalizedStringKey("step_subtitle_key"),
            state: .active,
            stepNumber: 2,
            isLast: false,
            onTap: { tapped = true }
        )
        XCTAssertEqual(node.title, "")
        XCTAssertNil(node.subtitle)
        XCTAssertEqual(node.state, .active)
        XCTAssertEqual(node.stepNumber, 2)
        XCTAssertNotNil(node.body)

        node.onTap?()
        XCTAssertTrue(tapped)
    }
}

