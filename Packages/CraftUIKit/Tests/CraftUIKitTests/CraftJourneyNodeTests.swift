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

        #expect(CraftJourneyNode.diameter(for: activeNode.state) == 72)
        #expect(CraftJourneyNode.diameter(for: inProgressNode.state) == 72)
        #expect(CraftJourneyNode.diameter(for: completedNode.state) == 72)
        #expect(CraftJourneyNode.diameter(for: lockedNode.state) == 72)
        #expect(CraftJourneyNode.diameter(for: upcomingNode.state) == 72)
        #expect(CraftJourneyNode.diameter(for: bonusNode.state) == 72)
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
}
