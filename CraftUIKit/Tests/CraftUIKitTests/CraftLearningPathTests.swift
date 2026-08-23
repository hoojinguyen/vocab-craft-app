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

    // MARK: - LessonNode VoiceOver and CraftLessonNode Tests

    func testLessonNodeVoiceOverLabelFormatting() {
        let completedNode = LessonNodeModel(id: "1", title: "Intro", iconName: "star", state: .completed)
        let activeNode = LessonNodeModel(id: "2", title: "Grammar", iconName: "book", state: .active, progress: 0.6)
        let lockedNode = LessonNodeModel(id: "3", title: "Verbs", iconName: "lock", state: .locked)

        XCTAssertEqual(completedNode.state, .completed)
        XCTAssertEqual(activeNode.progress, 0.6)
        XCTAssertEqual(lockedNode.state, .locked)
    }

    func testCraftLessonNodeVoiceOverAccessibilityDescriptions() {
        let completed = LessonNodeModel(id: "1", title: "Intro", iconName: "star", state: .completed)
        let completedNode = CraftLessonNode(model: completed)
        XCTAssertEqual(completedNode.accessibilityLabelText, "Lesson: Intro, Completed")
        XCTAssertEqual(completedNode.accessibilityHintText, "Double tap to review")
        XCTAssertEqual(completedNode.accessibilityTraits, .isButton)

        let activeWithProgress = LessonNodeModel(id: "2", title: "Grammar", iconName: "book", state: .active, progress: 0.6)
        let activeNode = CraftLessonNode(model: activeWithProgress)
        XCTAssertEqual(activeNode.accessibilityLabelText, "Lesson: Grammar, Current lesson. 60% complete")
        XCTAssertEqual(activeNode.accessibilityHintText, "Double tap to continue")
        XCTAssertEqual(activeNode.accessibilityTraits, .isButton)

        let activeWithoutProgress = LessonNodeModel(id: "2b", title: "Grammar", iconName: "book", state: .active)
        let activeNode2 = CraftLessonNode(model: activeWithoutProgress)
        XCTAssertEqual(activeNode2.accessibilityLabelText, "Lesson: Grammar, Current lesson")
        XCTAssertEqual(activeNode2.accessibilityHintText, "Double tap to continue")

        let inProgress = LessonNodeModel(id: "3", title: "Phrases", iconName: "quote.bubble", state: .inProgress, progress: 0.45)
        let inProgressNode = CraftLessonNode(model: inProgress)
        XCTAssertEqual(inProgressNode.accessibilityLabelText, "Lesson: Phrases, In progress. 45% complete")
        XCTAssertEqual(inProgressNode.accessibilityHintText, "Double tap to continue")
        XCTAssertEqual(inProgressNode.accessibilityTraits, .isButton)

        let inProgressNoVal = LessonNodeModel(id: "3b", title: "Phrases", iconName: "quote.bubble", state: .inProgress)
        let inProgressNode2 = CraftLessonNode(model: inProgressNoVal)
        XCTAssertEqual(inProgressNode2.accessibilityLabelText, "Lesson: Phrases, In progress")
        XCTAssertEqual(inProgressNode2.accessibilityHintText, "Double tap to continue")

        let upcoming = LessonNodeModel(id: "4", title: "Vocabulary", iconName: "character.book.closed", state: .upcoming)
        let upcomingNode = CraftLessonNode(model: upcoming)
        XCTAssertEqual(upcomingNode.accessibilityLabelText, "Lesson: Vocabulary, Upcoming lesson")
        XCTAssertEqual(upcomingNode.accessibilityHintText, "Double tap to start")
        XCTAssertEqual(upcomingNode.accessibilityTraits, .isButton)

        let locked = LessonNodeModel(id: "5", title: "Verbs", iconName: "lock", state: .locked)
        let lockedNode = CraftLessonNode(model: locked)
        XCTAssertEqual(lockedNode.accessibilityLabelText, "Lesson: Verbs, Locked")
        XCTAssertEqual(lockedNode.accessibilityHintText, "Complete previous lessons to unlock")
        XCTAssertEqual(lockedNode.accessibilityTraits, .notEnabled)

        let bonus = LessonNodeModel(id: "6", title: "Mastery Challenge", iconName: "crown.fill", state: .bonus)
        let bonusNode = CraftLessonNode(model: bonus)
        XCTAssertEqual(bonusNode.accessibilityLabelText, "Bonus Lesson: Mastery Challenge")
        XCTAssertEqual(bonusNode.accessibilityHintText, "Double tap to start")
        XCTAssertEqual(bonusNode.accessibilityTraits, .isButton)
    }

    func testCraftLessonNodeEquatability() {
        let model1 = LessonNodeModel(id: "1", title: "Intro", iconName: "star", state: .completed)
        let model2 = LessonNodeModel(id: "1", title: "Intro", iconName: "star", state: .completed)
        let model3 = LessonNodeModel(id: "2", title: "Grammar", iconName: "book", state: .active)

        let node1 = CraftLessonNode(model: model1, onTap: { print("1") })
        let node2 = CraftLessonNode(model: model2, onTap: { print("2") })
        let node3 = CraftLessonNode(model: model3)

        XCTAssertEqual(node1, node2)
        XCTAssertNotEqual(node1, node3)
    }

    func testCraftLessonNodeInstantiationAllStates() {
        for state in LessonNodeState.allCases {
            let model = LessonNodeModel(
                id: "node_\(state.rawValue)",
                title: "Test \(state.rawValue)",
                iconName: "circle.fill",
                state: state,
                progress: 0.5,
                badgeCount: 3,
                badgeText: "NEW"
            )
            let nodeWithTap = CraftLessonNode(model: model) { }
            let nodeWithoutTap = CraftLessonNode(model: model)

            XCTAssertNotNil(nodeWithTap)
            XCTAssertNotNil(nodeWithoutTap)
            XCTAssertEqual(nodeWithTap.model.id, "node_\(state.rawValue)")
            XCTAssertEqual(nodeWithTap.model.state, state)
        }
    }

    // MARK: - Row Splitting Algorithm Tests

    func testRowPatternSplitting() {
        let nodes = (0..<7).map { LessonNodeModel(id: "node_\($0)", title: "Lesson \($0)", iconName: "star", state: .upcoming) }

        let standardRows = RowPattern.standard.split(nodes: nodes)
        XCTAssertEqual(standardRows.count, 5) // [1], [2], [1], [2], [1]
        XCTAssertEqual(standardRows[0].arrangement, .single)
        XCTAssertEqual(standardRows[0].nodes.count, 1)
        XCTAssertEqual(standardRows[1].arrangement, .pair)
        XCTAssertEqual(standardRows[1].nodes.count, 2)
        XCTAssertEqual(standardRows[2].arrangement, .single)
        XCTAssertEqual(standardRows[2].nodes.count, 1)
        XCTAssertEqual(standardRows[3].arrangement, .pair)
        XCTAssertEqual(standardRows[3].nodes.count, 2)
        XCTAssertEqual(standardRows[4].arrangement, .single)
        XCTAssertEqual(standardRows[4].nodes.count, 1)

        let waveRows = RowPattern.wave.split(nodes: (0..<9).map { LessonNodeModel(id: "w_\($0)", title: "\($0)", iconName: "star", state: .upcoming) })
        // [1], [2], [3], [2], [1]
        XCTAssertEqual(waveRows.map(\.nodes.count), [1, 2, 3, 2, 1])
        XCTAssertEqual(waveRows[0].arrangement, .single)
        XCTAssertEqual(waveRows[1].arrangement, .pair)
        XCTAssertEqual(waveRows[2].arrangement, .triple)
        XCTAssertEqual(waveRows[3].arrangement, .pair)
        XCTAssertEqual(waveRows[4].arrangement, .single)
    }

    func testRowPatternSplittingEdgeCases() {
        // Empty nodes
        let emptyRows = RowPattern.standard.split(nodes: [])
        XCTAssertTrue(emptyRows.isEmpty)

        // Custom pattern
        let customNodes = (0..<6).map { LessonNodeModel(id: "c_\($0)", title: "C\($0)", iconName: "star", state: .upcoming) }
        let customRows = RowPattern.custom([3, 1, 2]).split(nodes: customNodes)
        XCTAssertEqual(customRows.count, 3)
        XCTAssertEqual(customRows[0].nodes.count, 3)
        XCTAssertEqual(customRows[0].arrangement, .triple)
        XCTAssertEqual(customRows[1].nodes.count, 1)
        XCTAssertEqual(customRows[1].arrangement, .single)
        XCTAssertEqual(customRows[2].nodes.count, 2)
        XCTAssertEqual(customRows[2].arrangement, .pair)

        // Custom pattern with invalid/empty counts defaults gracefully
        let fallbackRows = RowPattern.custom([]).split(nodes: customNodes)
        XCTAssertEqual(fallbackRows.count, 6)
        XCTAssertEqual(fallbackRows.map(\.nodes.count), [1, 1, 1, 1, 1, 1])

        // Partial row at the end adjusts arrangement to actual node count
        let partialNodes = (0..<4).map { LessonNodeModel(id: "p_\($0)", title: "P\($0)", iconName: "star", state: .upcoming) }
        // Wave pattern wants [1, 2, 3] -> 1st row has 1 (.single), 2nd row has 2 (.pair), 3rd row has 1 remaining (.single instead of .triple)
        let partialWave = RowPattern.wave.split(nodes: partialNodes)
        XCTAssertEqual(partialWave.count, 3)
        XCTAssertEqual(partialWave[0].nodes.count, 1)
        XCTAssertEqual(partialWave[0].arrangement, .single)
        XCTAssertEqual(partialWave[1].nodes.count, 2)
        XCTAssertEqual(partialWave[1].arrangement, .pair)
        XCTAssertEqual(partialWave[2].nodes.count, 1)
        XCTAssertEqual(partialWave[2].arrangement, .single)
    }

    // MARK: - CraftLessonRow View Tests

    func testCraftLessonRowInstantiationAndEquatability() {
        let nodeA = LessonNodeModel(id: "a", title: "A", iconName: "star", state: .completed)
        let nodeB = LessonNodeModel(id: "b", title: "B", iconName: "book", state: .active)
        let nodeC = LessonNodeModel(id: "c", title: "C", iconName: "lock", state: .locked)

        let row1 = CraftLessonRow(nodes: [nodeA], arrangement: .single)
        let row2 = CraftLessonRow(nodes: [nodeA], arrangement: .single)
        let row3 = CraftLessonRow(nodes: [nodeA, nodeB], arrangement: .pair)
        let row4 = CraftLessonRow(nodes: [nodeA, nodeB, nodeC], arrangement: .triple)

        XCTAssertEqual(row1, row2)
        XCTAssertNotEqual(row1, row3)
        XCTAssertNotEqual(row3, row4)

        XCTAssertEqual(row1.nodes.count, 1)
        XCTAssertEqual(row1.arrangement, .single)
        XCTAssertEqual(row3.nodes.count, 2)
        XCTAssertEqual(row3.arrangement, .pair)
        XCTAssertEqual(row4.nodes.count, 3)
        XCTAssertEqual(row4.arrangement, .triple)
    }

    func testCraftLessonRowTapCallback() {
        var tappedNode: LessonNodeModel?
        let node = LessonNodeModel(id: "tap_1", title: "Tap Test", iconName: "star", state: .active)
        let row = CraftLessonRow(nodes: [node], arrangement: .single) { selected in
            tappedNode = selected
        }
        XCTAssertNotNil(row)
        row.onNodeTap?(node)
        XCTAssertEqual(tappedNode?.id, "tap_1")
    }

    // MARK: - NodeAnchorPreferenceKey Tests

    func testNodeAnchorPreferenceKeyDefaultValueAndReduce() {
        XCTAssertTrue(NodeAnchorPreferenceKey.defaultValue.isEmpty)

        var current: NodeAnchorPreferenceKey.Value = [:]
        // Test reduce with mock logic if Anchor cannot be instantiated directly without GeometryReader
        NodeAnchorPreferenceKey.reduce(value: &current, nextValue: { [:] })
        XCTAssertTrue(current.isEmpty)
    }

    // MARK: - CraftLessonSectionView Tests

    func testSectionViewInstantiation() {
        let nodes = [
            LessonNodeModel(id: "s1_n1", title: "Start", iconName: "play.fill", state: .completed),
            LessonNodeModel(id: "s1_n2", title: "Practice", iconName: "pencil", state: .active),
            LessonNodeModel(id: "s1_n3", title: "Review", iconName: "checkmark", state: .upcoming)
        ]
        let section = LessonSection(
            id: "sec_test",
            title: "Basics",
            subtitle: "Getting Started with Greetings",
            level: "A1",
            progress: "2/3",
            nodes: nodes,
            connectorStyle: .dashed
        )
        let sectionView = CraftLessonSectionView(section: section, rowPattern: .standard)
        XCTAssertNotNil(sectionView)
        XCTAssertEqual(sectionView.section.id, "sec_test")
        XCTAssertEqual(sectionView.section.title, "Basics")
        XCTAssertEqual(sectionView.section.subtitle, "Getting Started with Greetings")
        XCTAssertEqual(sectionView.section.level, "A1")
        XCTAssertEqual(sectionView.section.progress, "2/3")
        XCTAssertEqual(sectionView.rowPattern, .standard)
    }

    func testSectionViewWithCustomPatternAndTapHandler() {
        var tappedNode: LessonNodeModel?
        let nodes = [
            LessonNodeModel(id: "n1", title: "Node 1", iconName: "star", state: .completed),
            LessonNodeModel(id: "n2", title: "Node 2", iconName: "star", state: .active),
            LessonNodeModel(id: "n3", title: "Node 3", iconName: "star", state: .locked),
            LessonNodeModel(id: "n4", title: "Node 4", iconName: "star", state: .bonus)
        ]
        let section = LessonSection(id: "sec_wave", title: "Wave Unit", nodes: nodes, connectorStyle: .solid)
        let sectionView = CraftLessonSectionView(
            section: section,
            rowPattern: .wave
        ) { node in
            tappedNode = node
        }

        XCTAssertNotNil(sectionView)
        XCTAssertEqual(sectionView.section.nodes.count, 4)
        XCTAssertEqual(sectionView.section.connectorStyle, .solid)
        XCTAssertEqual(sectionView.rowPattern, .wave)

        sectionView.onNodeTap?(nodes[1])
        XCTAssertEqual(tappedNode?.id, "n2")
    }

    func testSectionViewMinimalHeader() {
        let section = LessonSection(id: "sec_minimal", title: "Minimal Unit", nodes: [])
        let sectionView = CraftLessonSectionView(section: section)

        XCTAssertNotNil(sectionView)
        XCTAssertEqual(sectionView.section.title, "Minimal Unit")
        XCTAssertNil(sectionView.section.level)
        XCTAssertNil(sectionView.section.subtitle)
        XCTAssertNil(sectionView.section.progress)
        XCTAssertTrue(sectionView.section.nodes.isEmpty)
        XCTAssertEqual(sectionView.rowPattern, .standard)
    }

    func testSectionViewSingleNode() {
        let single = LessonNodeModel(id: "single_1", title: "Only Node", iconName: "star", state: .active)
        let section = LessonSection(id: "sec_single", title: "Single Node Section", nodes: [single])
        let sectionView = CraftLessonSectionView(section: section, rowPattern: .standard)

        XCTAssertNotNil(sectionView)
        XCTAssertEqual(sectionView.section.nodes.count, 1)
    }

    func testSectionViewWithDifferentConnectorStyles() {
        let nodes = [
            LessonNodeModel(id: "c1", title: "Node 1", iconName: "star", state: .completed),
            LessonNodeModel(id: "c2", title: "Node 2", iconName: "pencil", state: .upcoming)
        ]

        let dashedSection = LessonSection(id: "s_dash", title: "Dashed", nodes: nodes, connectorStyle: .dashed)
        let solidSection = LessonSection(id: "s_solid", title: "Solid", nodes: nodes, connectorStyle: .solid)
        let gradientSection = LessonSection(id: "s_grad", title: "Gradient", nodes: nodes, connectorStyle: .gradient(from: .blue, to: .green))
        let animatedSection = LessonSection(id: "s_anim", title: "Animated", nodes: nodes, connectorStyle: .animated)

        XCTAssertEqual(CraftLessonSectionView(section: dashedSection).section.connectorStyle, .dashed)
        XCTAssertEqual(CraftLessonSectionView(section: solidSection).section.connectorStyle, .solid)
        XCTAssertEqual(CraftLessonSectionView(section: gradientSection).section.connectorStyle, .gradient(from: .blue, to: .green))
        XCTAssertEqual(CraftLessonSectionView(section: animatedSection).section.connectorStyle, .animated)
    }

    func testSectionViewHeaderVariants() {
        let sectionWithLevel = LessonSection(id: "s_lvl", title: "Title", level: "B1", nodes: [])
        let viewWithLevel = CraftLessonSectionView(section: sectionWithLevel)
        XCTAssertEqual(viewWithLevel.section.level, "B1")

        let sectionWithProgress = LessonSection(id: "s_prog", title: "Title", progress: "4/10", nodes: [])
        let viewWithProgress = CraftLessonSectionView(section: sectionWithProgress)
        XCTAssertEqual(viewWithProgress.section.progress, "4/10")

        let sectionWithSubtitle = LessonSection(id: "s_sub", title: "Title", subtitle: "Sub text", nodes: [])
        let viewWithSubtitle = CraftLessonSectionView(section: sectionWithSubtitle)
        XCTAssertEqual(viewWithSubtitle.section.subtitle, "Sub text")
    }
}




