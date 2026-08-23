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
}
