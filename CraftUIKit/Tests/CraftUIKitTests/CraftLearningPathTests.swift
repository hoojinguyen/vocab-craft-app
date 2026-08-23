import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftLearningPathTests: XCTestCase {
    // MARK: - LessonNodeState Tests

    func testLessonNodeStateCasesAndRawValues() {
        XCTAssertEqual(LessonNodeState.allCases.count, 6)
        XCTAssertEqual(LessonNodeState.allCases, [
            .completed,
            .active,
            .inProgress,
            .upcoming,
            .locked,
            .bonus
        ])
        XCTAssertEqual(LessonNodeState.completed.rawValue, "completed")
        XCTAssertEqual(LessonNodeState.active.rawValue, "active")
        XCTAssertEqual(LessonNodeState.inProgress.rawValue, "inProgress")
        XCTAssertEqual(LessonNodeState.upcoming.rawValue, "upcoming")
        XCTAssertEqual(LessonNodeState.locked.rawValue, "locked")
        XCTAssertEqual(LessonNodeState.bonus.rawValue, "bonus")
    }

    // MARK: - LessonNodeModel Tests

    func testModelInitializationAndEquatability() {
        let node1 = LessonNodeModel(
            id: "node_1",
            title: "Basics 1",
            iconName: "book.fill",
            state: .active,
            progress: 0.5,
            badgeCount: 2,
            badgeText: "NEW"
        )
        let node2 = LessonNodeModel(
            id: "node_1",
            title: "Basics 1",
            iconName: "book.fill",
            state: .active,
            progress: 0.5,
            badgeCount: 2,
            badgeText: "NEW"
        )
        let node3 = LessonNodeModel(
            id: "node_2",
            title: "Basics 2",
            iconName: "pencil",
            state: .locked
        )

        XCTAssertEqual(node1, node2)
        XCTAssertNotEqual(node1, node3)
        XCTAssertEqual(node1.id, "node_1")
        XCTAssertEqual(node1.title, "Basics 1")
        XCTAssertEqual(node1.iconName, "book.fill")
        XCTAssertEqual(node1.state, .active)
        XCTAssertEqual(node1.progress, 0.5)
        XCTAssertEqual(node1.badgeCount, 2)
        XCTAssertEqual(node1.badgeText, "NEW")

        // Defaults
        XCTAssertNil(node3.progress)
        XCTAssertNil(node3.badgeCount)
        XCTAssertNil(node3.badgeText)

        // Hashable
        let set: Set<LessonNodeModel> = [node1, node2, node3]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - ConnectorStyle Tests

    func testConnectorStyleEquatability() {
        let dashed = ConnectorStyle.dashed
        let solid = ConnectorStyle.solid
        let animated = ConnectorStyle.animated
        let gradient1 = ConnectorStyle.gradient(from: .blue, to: .purple)
        let gradient2 = ConnectorStyle.gradient(from: .blue, to: .purple)
        let gradient3 = ConnectorStyle.gradient(from: .red, to: .orange)

        XCTAssertEqual(dashed, .dashed)
        XCTAssertEqual(solid, .solid)
        XCTAssertEqual(animated, .animated)
        XCTAssertEqual(gradient1, gradient2)
        XCTAssertNotEqual(gradient1, gradient3)
        XCTAssertNotEqual(dashed, solid)
    }

    // MARK: - LessonSection Tests

    func testSectionModelCreation() {
        let node = LessonNodeModel(id: "n1", title: "Intro", iconName: "star.fill", state: .completed)
        let section = LessonSection(
            id: "sec_1",
            title: "Unit 1: Foundations",
            subtitle: "Getting Started",
            level: "BEGINNER",
            progress: "1/10",
            nodes: [node],
            connectorStyle: .solid
        )

        XCTAssertEqual(section.id, "sec_1")
        XCTAssertEqual(section.title, "Unit 1: Foundations")
        XCTAssertEqual(section.subtitle, "Getting Started")
        XCTAssertEqual(section.level, "BEGINNER")
        XCTAssertEqual(section.progress, "1/10")
        XCTAssertEqual(section.nodes.count, 1)
        XCTAssertEqual(section.nodes.first, node)
        XCTAssertEqual(section.connectorStyle, .solid)
    }

    func testSectionModelDefaultValues() {
        let section = LessonSection(
            id: "sec_default",
            title: "Unit Default",
            nodes: []
        )

        XCTAssertEqual(section.id, "sec_default")
        XCTAssertEqual(section.title, "Unit Default")
        XCTAssertNil(section.subtitle)
        XCTAssertNil(section.level)
        XCTAssertNil(section.progress)
        XCTAssertEqual(section.nodes, [])
        XCTAssertEqual(section.connectorStyle, .dashed)
    }

    // MARK: - RowPattern and Arrangement Tests

    func testRowPatternAndArrangementEquatability() {
        let pattern1: RowPattern = .standard
        let pattern2: RowPattern = .wave
        let pattern3: RowPattern = .custom([1, 3, 1])
        let pattern4: RowPattern = .custom([1, 3, 1])
        let pattern5: RowPattern = .custom([2, 2])

        XCTAssertEqual(pattern1, .standard)
        XCTAssertEqual(pattern2, .wave)
        XCTAssertEqual(pattern3, pattern4)
        XCTAssertNotEqual(pattern3, pattern5)
        XCTAssertNotEqual(pattern1, pattern2)

        let arr1: LessonRowArrangement = .single
        let arr2: LessonRowArrangement = .pair
        let arr3: LessonRowArrangement = .triple

        XCTAssertEqual(arr1, .single)
        XCTAssertEqual(arr2, .pair)
        XCTAssertEqual(arr3, .triple)
        XCTAssertNotEqual(arr1, arr2)
    }

    // MARK: - Connector and Animation Tests

    func testNodeConnectorPathGeneration() {
        let connector = CraftNodeConnector(
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 200, y: 300)
        )
        let path = connector.path(in: CGRect(x: 0, y: 0, width: 300, height: 400))
        XCTAssertFalse(path.isEmpty)
        XCTAssertEqual(path.boundingRect.minX, 100, accuracy: 1.0)
        XCTAssertEqual(path.boundingRect.maxX, 200, accuracy: 1.0)
        XCTAssertEqual(path.boundingRect.minY, 100, accuracy: 1.0)
        XCTAssertEqual(path.boundingRect.maxY, 300, accuracy: 1.0)
    }

    func testNodeConnectorStraightVerticalPath() {
        let connector = CraftNodeConnector(
            from: CGPoint(x: 150, y: 50),
            to: CGPoint(x: 150, y: 250)
        )
        let path = connector.path(in: CGRect(x: 0, y: 0, width: 300, height: 300))
        XCTAssertFalse(path.isEmpty)
        XCTAssertEqual(path.boundingRect.minX, 150, accuracy: 1.0)
        XCTAssertEqual(path.boundingRect.maxX, 150, accuracy: 1.0)
        XCTAssertEqual(path.boundingRect.minY, 50, accuracy: 1.0)
        XCTAssertEqual(path.boundingRect.maxY, 250, accuracy: 1.0)
    }

    func testAnimationPhases() {
        XCTAssertEqual(BreathingPhase.allCases, [.rest, .inhale])
        XCTAssertEqual(BreathingPhase.allCases.count, 2)

        XCTAssertEqual(GlowPhase.allCases, [.normal, .glowing])
        XCTAssertEqual(GlowPhase.allCases.count, 2)
    }

    func testConnectorViewsInstantiation() {
        let from = CGPoint(x: 50, y: 50)
        let to = CGPoint(x: 150, y: 200)

        let breathing = BreathingConnectorView(from: from, to: to)
        XCTAssertNotNil(breathing)

        let dashed = CraftStyledConnector(from: from, to: to, style: .dashed)
        XCTAssertNotNil(dashed)

        let solid = CraftStyledConnector(from: from, to: to, style: .solid)
        XCTAssertNotNil(solid)

        let gradient = CraftStyledConnector(from: from, to: to, style: .gradient(from: .blue, to: .purple))
        XCTAssertNotNil(gradient)

        let animated = CraftStyledConnector(from: from, to: to, style: .animated)
        XCTAssertNotNil(animated)

        let customColorBreathing = BreathingConnectorView(from: from, to: to, color: .orange)
        XCTAssertNotNil(customColorBreathing)

        let customColorStyled = CraftStyledConnector(from: from, to: to, style: .solid, color: .green)
        XCTAssertNotNil(customColorStyled)
    }

    func testNodeConnectorAnimatableData() {
        var connector = CraftNodeConnector(
            from: CGPoint(x: 10, y: 20),
            to: CGPoint(x: 30, y: 40)
        )
        let data = connector.animatableData
        XCTAssertEqual(data.first.first, 10)
        XCTAssertEqual(data.first.second, 20)
        XCTAssertEqual(data.second.first, 30)
        XCTAssertEqual(data.second.second, 40)

        connector.animatableData = AnimatablePair(
            CGPoint(x: 50, y: 60).animatableData,
            CGPoint(x: 70, y: 80).animatableData
        )
        XCTAssertEqual(connector.from, CGPoint(x: 50, y: 60))
        XCTAssertEqual(connector.to, CGPoint(x: 70, y: 80))
    }

    func testAnimationHelperTokens() {
        let breathing = Animation.craftBreathing
        let glow = Animation.craftGlow
        XCTAssertNotNil(breathing)
        XCTAssertNotNil(glow)
    }
}


