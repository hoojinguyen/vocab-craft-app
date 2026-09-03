@testable import CraftUIKit
import SwiftUI
import Testing

@Suite("CraftJourneyNode Tests")
struct CraftJourneyNodeTests {
    @Test("Verify diameters across progression states")
    func testNodeDiameters() {
        let activeNode = LessonNodeModel(id: "1", title: "Active", state: .active)
        let inProgressNode = LessonNodeModel(id: "1b", title: "In Progress", state: .inProgress)
        let completedNode = LessonNodeModel(id: "2", title: "Completed", state: .completed)
        let lockedNode = LessonNodeModel(id: "3", title: "Locked", state: .locked)
        let upcomingNode = LessonNodeModel(id: "4", title: "Upcoming", state: .upcoming)
        let bonusNode = LessonNodeModel(id: "5", title: "Bonus", state: .bonus)

        #expect(CraftJourneyNode.diameter(for: activeNode.state) == 88)
        #expect(CraftJourneyNode.diameter(for: inProgressNode.state) == 88)
        #expect(CraftJourneyNode.diameter(for: completedNode.state) == 88)
        #expect(CraftJourneyNode.diameter(for: lockedNode.state) == 88)
        #expect(CraftJourneyNode.diameter(for: upcomingNode.state) == 88)
        #expect(CraftJourneyNode.diameter(for: bonusNode.state) == 88)
    }

    @Test("Verify CraftJourneyNode diameter is 88pt")
    func testCraftJourneyNodeDiameterIs88pt() {
        #expect(CraftJourneyNode.diameter(for: .active) == 88)
        #expect(CraftJourneyNode.diameter(for: .completed) == 88)
        #expect(CraftJourneyNode.diameter(for: .locked) == 88)
    }

    @Test("Verify CraftJourneyNode preserves semantic icon across states")
    func testCraftJourneyNodePreservesSemanticIconAcrossStates() {
        let node = LessonNodeModel(id: "n1", title: "Empathy", iconName: "heart", state: .completed)
        let view = CraftJourneyNode(node: node)
        #expect(view.displayedIconName == "heart")

        let lockedNode = LessonNodeModel(id: "n2", title: "Leadership", iconName: "star.fill", state: .locked)
        let lockedView = CraftJourneyNode(node: lockedNode)
        #expect(lockedView.displayedIconName == "star.fill")
    }

    @Test("Verify semantic icon size across states")
    func testCraftJourneyNodeIconSize() {
        let activeView = CraftJourneyNode(node: LessonNodeModel(id: "1", title: "Active", state: .active))
        let inProgressView = CraftJourneyNode(node: LessonNodeModel(id: "2", title: "In Progress", state: .inProgress))
        let completedView = CraftJourneyNode(node: LessonNodeModel(id: "3", title: "Completed", state: .completed))
        let lockedView = CraftJourneyNode(node: LessonNodeModel(id: "4", title: "Locked", state: .locked))

        #expect(activeView.iconSize == 34)
        #expect(inProgressView.iconSize == 34)
        #expect(completedView.iconSize == 32)
        #expect(lockedView.iconSize == 32)
    }

    @Test("Verify node view initialization and model properties")
    func testNodeInitialization() {
        let nodeModel = LessonNodeModel(id: "test-node", title: "Past Tense", state: .active)
        var tapCount = 0
        let journeyNode = CraftJourneyNode(node: nodeModel) {
            tapCount += 1
        }

        #expect(journeyNode.node.id == "test-node")
        #expect(journeyNode.node.state == .active)
        #expect(journeyNode.node.title == "Past Tense")

        journeyNode.onTap?()
        #expect(tapCount == 1)
    }

    @Test("Verify accessibility labels across states")
    func testAccessibilityLabels() {
        let completedNode = LessonNodeModel(id: "1", title: "Lesson 1", state: .completed)
        let activeNode = LessonNodeModel(id: "2", title: "Lesson 2", state: .active)
        let lockedNode = LessonNodeModel(id: "3", title: "Lesson 3", state: .locked)
        let upcomingNode = LessonNodeModel(id: "4", title: "Lesson 4", state: .upcoming)

        let completedView = CraftJourneyNode(node: completedNode)
        let activeView = CraftJourneyNode(node: activeNode)
        let lockedView = CraftJourneyNode(node: lockedNode)
        let upcomingView = CraftJourneyNode(node: upcomingNode)

        #expect(!completedView.accessibilityLabelText.isEmpty)
        #expect(!activeView.accessibilityLabelText.isEmpty)
        #expect(!lockedView.accessibilityLabelText.isEmpty)
        #expect(!upcomingView.accessibilityLabelText.isEmpty)

        #expect(completedView.accessibilityTraits == .isButton)
        #expect(activeView.accessibilityTraits == .isButton)
        #expect(lockedView.accessibilityTraits == [])
        #expect(upcomingView.accessibilityTraits == .isButton)
    }

    @Test("Verify resolvedIconName automatically prefers filled variants")
    func testResolvedIconNamePrefersFilledVariant() {
        let node = LessonNodeModel(id: "n-heart", title: "Heart Lesson", iconName: "heart", state: .active)
        let view = CraftJourneyNode(node: node)
        #expect(view.displayedIconName == "heart")
        #if canImport(UIKit) || canImport(AppKit)
        #expect(view.resolvedIconName == "heart.fill")
        #else
        #expect(view.resolvedIconName == "heart")
        #endif

        let filledNode = LessonNodeModel(id: "n-star", title: "Star Lesson", iconName: "star.fill", state: .completed)
        let filledView = CraftJourneyNode(node: filledNode)
        #expect(filledView.resolvedIconName == "star.fill")
    }
}
