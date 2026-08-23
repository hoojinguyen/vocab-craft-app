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

    // MARK: - LessonNodeKind Tests

    func testLessonNodeKindCasesAndRawValues() {
        XCTAssertEqual(LessonNodeKind.allCases.count, 3)
        XCTAssertEqual(LessonNodeKind.allCases, [
            .standard,
            .checkpoint,
            .treasureChest
        ])
        XCTAssertEqual(LessonNodeKind.standard.rawValue, "standard")
        XCTAssertEqual(LessonNodeKind.checkpoint.rawValue, "checkpoint")
        XCTAssertEqual(LessonNodeKind.treasureChest.rawValue, "treasureChest")
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

    func testLessonNodeModelEnhancedFieldsAndDefaults() {
        let defaultNode = LessonNodeModel(
            id: "default_node",
            title: "Greetings"
        )

        XCTAssertEqual(defaultNode.id, "default_node")
        XCTAssertEqual(defaultNode.title, "Greetings")
        XCTAssertNil(defaultNode.subtitle)
        XCTAssertEqual(defaultNode.iconName, "book.fill")
        XCTAssertEqual(defaultNode.state, .upcoming)
        XCTAssertEqual(defaultNode.kind, .standard)
        XCTAssertNil(defaultNode.progress)
        XCTAssertNil(defaultNode.xpReward)
        XCTAssertNil(defaultNode.estimatedMinutes)
        XCTAssertNil(defaultNode.stars)
        XCTAssertNil(defaultNode.badgeCount)
        XCTAssertNil(defaultNode.badgeText)

        let fullNode = LessonNodeModel(
            id: "full_node",
            title: "Boss Challenge",
            subtitle: "15 từ mới • 4 phút",
            iconName: "crown.fill",
            state: .active,
            kind: .checkpoint,
            progress: 0.75,
            xpReward: 50,
            estimatedMinutes: 4,
            stars: 3,
            badgeCount: 1,
            badgeText: "HOT"
        )

        XCTAssertEqual(fullNode.subtitle, "15 từ mới • 4 phút")
        XCTAssertEqual(fullNode.kind, .checkpoint)
        XCTAssertEqual(fullNode.xpReward, 50)
        XCTAssertEqual(fullNode.estimatedMinutes, 4)
        XCTAssertEqual(fullNode.stars, 3)

        let treasureNode = LessonNodeModel(
            id: "chest_node",
            title: "Milestone Chest",
            iconName: "gift.fill",
            state: .completed,
            kind: .treasureChest,
            xpReward: 100
        )
        XCTAssertEqual(treasureNode.kind, .treasureChest)
        XCTAssertEqual(treasureNode.xpReward, 100)

        // Equatable and Hashable with new fields
        let fullNodeCopy = LessonNodeModel(
            id: "full_node",
            title: "Boss Challenge",
            subtitle: "15 từ mới • 4 phút",
            iconName: "crown.fill",
            state: .active,
            kind: .checkpoint,
            progress: 0.75,
            xpReward: 50,
            estimatedMinutes: 4,
            stars: 3,
            badgeCount: 1,
            badgeText: "HOT"
        )
        XCTAssertEqual(fullNode, fullNodeCopy)

        let set: Set<LessonNodeModel> = [defaultNode, fullNode, treasureNode, fullNodeCopy]
        XCTAssertEqual(set.count, 3)
    }

    // MARK: - SerpentineWinding Tests

    func testSerpentineWindingOffsetRatios() {
        let standard = SerpentineWinding.standard
        let expectedStandard: [CGFloat] = [0.0, -0.40, -0.55, -0.25, 0.0, 0.25, 0.55, 0.40]
        for (i, expected) in expectedStandard.enumerated() {
            XCTAssertEqual(standard.offsetRatio(for: i), expected, accuracy: 0.001)
        }
        // Test wrap-around
        XCTAssertEqual(standard.offsetRatio(for: 8), 0.0, accuracy: 0.001)
        XCTAssertEqual(standard.offsetRatio(for: 9), -0.40, accuracy: 0.001)
        XCTAssertEqual(standard.offsetRatio(for: 15), 0.40, accuracy: 0.001)
        // Test negative index safety
        XCTAssertEqual(standard.offsetRatio(for: -1), 0.0, accuracy: 0.001)

        let gentle = SerpentineWinding.gentle
        let expectedGentle: [CGFloat] = [0.0, -0.25, -0.35, -0.15, 0.0, 0.15, 0.35, 0.25]
        for (i, expected) in expectedGentle.enumerated() {
            XCTAssertEqual(gentle.offsetRatio(for: i), expected, accuracy: 0.001)
        }
        XCTAssertEqual(gentle.offsetRatio(for: 8), 0.0, accuracy: 0.001)

        let linear = SerpentineWinding.linear
        XCTAssertEqual(linear.offsetRatio(for: 0), 0.0, accuracy: 0.001)
        XCTAssertEqual(linear.offsetRatio(for: 5), 0.0, accuracy: 0.001)

        let custom = SerpentineWinding.custom([0.1, -0.2, 0.3])
        XCTAssertEqual(custom.offsetRatio(for: 0), 0.1, accuracy: 0.001)
        XCTAssertEqual(custom.offsetRatio(for: 1), -0.2, accuracy: 0.001)
        XCTAssertEqual(custom.offsetRatio(for: 2), 0.3, accuracy: 0.001)
        XCTAssertEqual(custom.offsetRatio(for: 3), 0.1, accuracy: 0.001)

        let emptyCustom = SerpentineWinding.custom([])
        XCTAssertEqual(emptyCustom.offsetRatio(for: 0), 0.0, accuracy: 0.001)
        XCTAssertEqual(emptyCustom.offsetRatio(for: 4), 0.0, accuracy: 0.001)
    }

    func testSerpentineWindingEquatability() {
        XCTAssertEqual(SerpentineWinding.standard, .standard)
        XCTAssertEqual(SerpentineWinding.gentle, .gentle)
        XCTAssertEqual(SerpentineWinding.linear, .linear)
        XCTAssertEqual(SerpentineWinding.custom([0.5, -0.5]), .custom([0.5, -0.5]))
        XCTAssertNotEqual(SerpentineWinding.standard, .gentle)
        XCTAssertNotEqual(SerpentineWinding.custom([0.5]), .custom([0.6]))
    }

    // MARK: - SmartConnectorStyle Tests

    func testSmartConnectorStyleCasesAndRawValues() {
        XCTAssertEqual(SmartConnectorStyle.allCases.count, 4)
        XCTAssertEqual(SmartConnectorStyle.allCases, [.solid, .breathing, .dashed, .muted])
        XCTAssertEqual(SmartConnectorStyle.solid.rawValue, "solid")
        XCTAssertEqual(SmartConnectorStyle.breathing.rawValue, "breathing")
        XCTAssertEqual(SmartConnectorStyle.dashed.rawValue, "dashed")
        XCTAssertEqual(SmartConnectorStyle.muted.rawValue, "muted")
    }

    func testSmartConnectorStyleInference() {
        // Solid: completed -> completed
        XCTAssertEqual(SmartConnectorStyle.infer(from: .completed, to: .completed), .solid)

        // Breathing: completed -> active, completed -> inProgress
        XCTAssertEqual(SmartConnectorStyle.infer(from: .completed, to: .active), .breathing)
        XCTAssertEqual(SmartConnectorStyle.infer(from: .completed, to: .inProgress), .breathing)

        // Dashed: active -> upcoming, active -> bonus, inProgress -> upcoming, inProgress -> bonus
        XCTAssertEqual(SmartConnectorStyle.infer(from: .active, to: .upcoming), .dashed)
        XCTAssertEqual(SmartConnectorStyle.infer(from: .active, to: .bonus), .dashed)
        XCTAssertEqual(SmartConnectorStyle.infer(from: .inProgress, to: .upcoming), .dashed)
        XCTAssertEqual(SmartConnectorStyle.infer(from: .inProgress, to: .bonus), .dashed)

        // Muted / Fallback: all other combinations
        XCTAssertEqual(SmartConnectorStyle.infer(from: .upcoming, to: .upcoming), .muted)
        XCTAssertEqual(SmartConnectorStyle.infer(from: .upcoming, to: .locked), .muted)
        XCTAssertEqual(SmartConnectorStyle.infer(from: .locked, to: .locked), .muted)
        XCTAssertEqual(SmartConnectorStyle.infer(from: .completed, to: .locked), .muted)
        XCTAssertEqual(SmartConnectorStyle.infer(from: .active, to: .locked), .muted)
        XCTAssertEqual(SmartConnectorStyle.infer(from: .bonus, to: .locked), .muted)
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
            progressText: "1/10",
            progressValue: 0.1,
            bannerIcon: "flag.fill",
            nodes: [node],
            winding: .gentle,
            connectorStyle: .solid
        )

        XCTAssertEqual(section.id, "sec_1")
        XCTAssertEqual(section.title, "Unit 1: Foundations")
        XCTAssertEqual(section.subtitle, "Getting Started")
        XCTAssertEqual(section.level, "BEGINNER")
        XCTAssertEqual(section.progressText, "1/10")
        XCTAssertEqual(section.progress, "1/10")
        XCTAssertEqual(section.progressValue, 0.1)
        XCTAssertEqual(section.bannerIcon, "flag.fill")
        XCTAssertEqual(section.nodes.count, 1)
        XCTAssertEqual(section.nodes.first, node)
        XCTAssertEqual(section.winding, .gentle)
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
        XCTAssertNil(section.progressText)
        XCTAssertNil(section.progress)
        XCTAssertNil(section.progressValue)
        XCTAssertNil(section.bannerIcon)
        XCTAssertEqual(section.nodes, [])
        XCTAssertEqual(section.winding, .standard)
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

    // MARK: - CraftLearningPath Container Tests

    func testLearningPathInstantiationAndEmptySection() {
        let emptySection = LessonSection(id: "empty", title: "Empty", nodes: [])
        let emptyPath = CraftLearningPath(section: emptySection)
        XCTAssertNotNil(emptyPath)
        XCTAssertEqual(emptyPath.sections.count, 1)
        XCTAssertTrue(emptyPath.sections[0].nodes.isEmpty)

        let multiSectionPath = CraftLearningPath(sections: [emptySection, emptySection])
        XCTAssertEqual(multiSectionPath.sections.count, 2)
    }

    func testLearningPathInitializersAndDefaultParameters() {
        let node = LessonNodeModel(id: "n1", title: "Node 1", iconName: "star", state: .active)
        let section = LessonSection(id: "s1", title: "Section 1", nodes: [node])

        // Single section init defaults
        let singlePath = CraftLearningPath(section: section)
        XCTAssertEqual(singlePath.sections.count, 1)
        XCTAssertEqual(singlePath.sections.first?.id, "s1")
        XCTAssertEqual(singlePath.rowPattern, .standard)
        XCTAssertTrue(singlePath.scrollToActive)
        XCTAssertTrue(singlePath.showCelebration)
        XCTAssertNil(singlePath.onNodeTap)

        // Multi-section custom init
        var tapCount = 0
        let multiPath = CraftLearningPath(
            sections: [section],
            rowPattern: .wave,
            onNodeTap: { _ in tapCount += 1 },
            scrollToActive: false,
            showCelebration: false
        )
        XCTAssertEqual(multiPath.sections.count, 1)
        XCTAssertEqual(multiPath.rowPattern, .wave)
        XCTAssertFalse(multiPath.scrollToActive)
        XCTAssertFalse(multiPath.showCelebration)
        XCTAssertNotNil(multiPath.onNodeTap)

        multiPath.onNodeTap?(node)
        XCTAssertEqual(tapCount, 1)
    }

    func testLearningPathActiveNodeResolution() {
        let completed = LessonNodeModel(id: "c1", title: "C1", iconName: "star", state: .completed)
        let active = LessonNodeModel(id: "a1", title: "A1", iconName: "book", state: .active)
        let upcoming = LessonNodeModel(id: "u1", title: "U1", iconName: "lock", state: .upcoming)

        let section1 = LessonSection(id: "s1", title: "S1", nodes: [completed])
        let section2 = LessonSection(id: "s2", title: "S2", nodes: [active, upcoming])

        let path = CraftLearningPath(sections: [section1, section2])
        XCTAssertEqual(path.activeNodeID, "a1")

        let noActivePath = CraftLearningPath(sections: [section1])
        XCTAssertNil(noActivePath.activeNodeID)

        let emptyPath = CraftLearningPath(sections: [])
        XCTAssertNil(emptyPath.activeNodeID)
    }

    func testLearningPathEmptyStateCondition() {
        let emptyPath1 = CraftLearningPath(sections: [])
        XCTAssertTrue(emptyPath1.isEmpty)

        let emptySection = LessonSection(id: "s_empty", title: "Empty", nodes: [])
        let emptyPath2 = CraftLearningPath(sections: [emptySection, emptySection])
        XCTAssertTrue(emptyPath2.isEmpty)

        let populatedNode = LessonNodeModel(id: "p1", title: "P1", iconName: "star", state: .upcoming)
        let populatedSection = LessonSection(id: "s_pop", title: "Pop", nodes: [populatedNode])
        let populatedPath = CraftLearningPath(sections: [emptySection, populatedSection])
        XCTAssertFalse(populatedPath.isEmpty)
    }

    func testLearningPathMultiSectionHierarchy() {
        let sec1Nodes = [
            LessonNodeModel(id: "s1_n1", title: "S1 N1", iconName: "star", state: .completed),
            LessonNodeModel(id: "s1_n2", title: "S1 N2", iconName: "star", state: .completed)
        ]
        let sec2Nodes = [
            LessonNodeModel(id: "s2_n1", title: "S2 N1", iconName: "book", state: .active),
            LessonNodeModel(id: "s2_n2", title: "S2 N2", iconName: "lock", state: .locked)
        ]

        let section1 = LessonSection(id: "sec_1", title: "Unit 1", nodes: sec1Nodes, connectorStyle: .solid)
        let section2 = LessonSection(id: "sec_2", title: "Unit 2", nodes: sec2Nodes, connectorStyle: .dashed)

        let path = CraftLearningPath(sections: [section1, section2], rowPattern: .custom([2]))
        XCTAssertEqual(path.sections.count, 2)
        XCTAssertEqual(path.sections[0].nodes.count, 2)
        XCTAssertEqual(path.sections[1].nodes.count, 2)
        XCTAssertEqual(path.rowPattern, .custom([2]))
        XCTAssertEqual(path.activeNodeID, "s2_n1")
    }

    // MARK: - Full Integration Suite Tests

    func testFullLearningPathSuite() {
        let mockNodes = [
            LessonNodeModel(id: "n1", title: "Alphabet", iconName: "textformat", state: .completed),
            LessonNodeModel(id: "n2", title: "Phonics", iconName: "waveform", state: .completed),
            LessonNodeModel(id: "n3", title: "Common Nouns", iconName: "sparkles", state: .active, progress: 0.75, badgeCount: 1),
            LessonNodeModel(id: "n4", title: "Verbs", iconName: "figure.run", state: .upcoming),
            LessonNodeModel(id: "n5", title: "Challenge", iconName: "crown.fill", state: .bonus),
            LessonNodeModel(id: "n6", title: "Adjectives", iconName: "paintpalette.fill", state: .locked)
        ]
        let section1 = LessonSection(id: "sec_1", title: "Unit 1: Fundamentals", level: "BEGINNER", progress: "2/6", nodes: mockNodes)
        let section2 = LessonSection(id: "sec_2", title: "Unit 2: Conversation", level: "INTERMEDIATE", progress: "0/6", nodes: mockNodes.map {
            LessonNodeModel(id: "sec2_\($0.id)", title: $0.title, iconName: $0.iconName, state: .locked)
        })

        var tappedNode: LessonNodeModel?
        let learningPath = CraftLearningPath(
            sections: [section1, section2],
            rowPattern: .standard,
            onNodeTap: { node in
                tappedNode = node
            },
            scrollToActive: true,
            showCelebration: true
        )

        XCTAssertEqual(learningPath.sections.count, 2)
        XCTAssertEqual(learningPath.sections[0].id, "sec_1")
        XCTAssertEqual(learningPath.sections[0].title, "Unit 1: Fundamentals")
        XCTAssertEqual(learningPath.sections[0].level, "BEGINNER")
        XCTAssertEqual(learningPath.sections[0].progress, "2/6")
        XCTAssertEqual(learningPath.sections[0].nodes.count, 6)

        XCTAssertEqual(learningPath.sections[1].id, "sec_2")
        XCTAssertEqual(learningPath.sections[1].title, "Unit 2: Conversation")
        XCTAssertEqual(learningPath.sections[1].level, "INTERMEDIATE")
        XCTAssertEqual(learningPath.sections[1].progress, "0/6")
        XCTAssertEqual(learningPath.sections[1].nodes.count, 6)

        XCTAssertEqual(learningPath.rowPattern, .standard)
        XCTAssertEqual(learningPath.activeNodeID, "n3")
        XCTAssertTrue(learningPath.scrollToActive)
        XCTAssertTrue(learningPath.showCelebration)
        XCTAssertFalse(learningPath.isEmpty)

        // Tap simulation
        learningPath.onNodeTap?(mockNodes[2])
        XCTAssertEqual(tappedNode?.id, "n3")
        XCTAssertEqual(tappedNode?.progress, 0.75)
        XCTAssertEqual(tappedNode?.badgeCount, 1)
    }

    func testFullLearningPathWavePatternSuite() {
        let nodes = (1...6).map {
            LessonNodeModel(id: "node_\($0)", title: "Lesson \($0)", iconName: "star.fill", state: $0 == 1 ? .completed : ($0 == 2 ? .active : .locked))
        }
        let section = LessonSection(id: "sec_wave_suite", title: "Wave Pattern Section", subtitle: "Dynamic Layout", level: "A2", progress: "1/6", nodes: nodes, connectorStyle: .gradient(from: .blue, to: .purple))

        let path = CraftLearningPath(
            section: section,
            rowPattern: .wave,
            scrollToActive: false,
            showCelebration: false
        )

        XCTAssertEqual(path.sections.count, 1)
        XCTAssertEqual(path.rowPattern, .wave)
        XCTAssertEqual(path.activeNodeID, "node_2")
        XCTAssertFalse(path.scrollToActive)
        XCTAssertFalse(path.showCelebration)
        XCTAssertEqual(path.sections[0].connectorStyle, .gradient(from: .blue, to: .purple))
    }

    func testActiveToBonusConnectorSection() {
        let activeNode = LessonNodeModel(id: "n_act", title: "Active Lesson", iconName: "flame.fill", state: .active)
        let bonusNode = LessonNodeModel(id: "n_bon", title: "Bonus Challenge", iconName: "crown.fill", state: .bonus)
        let section = LessonSection(id: "sec_act_bonus", title: "Bonus Section", nodes: [activeNode, bonusNode])

        let sectionView = CraftLessonSectionView(section: section)
        XCTAssertNotNil(sectionView)
        XCTAssertEqual(sectionView.section.nodes.count, 2)
        XCTAssertEqual(sectionView.section.nodes[0].state, .active)
        XCTAssertEqual(sectionView.section.nodes[1].state, .bonus)
    }

    func testSendableCallbacks() {
        let sendableTap: @Sendable () -> Void = {}
        let node = LessonNodeModel(id: "sendable_node", title: "Node", iconName: "star", state: .active)
        let lessonNode = CraftLessonNode(model: node, onTap: sendableTap)
        XCTAssertNotNil(lessonNode)

        let sendableNodeTap: @Sendable (LessonNodeModel) -> Void = { _ in }
        let row = CraftLessonRow(nodes: [node], arrangement: .single, onNodeTap: sendableNodeTap)
        XCTAssertNotNil(row)

        let section = LessonSection(id: "sec_sendable", title: "Section", nodes: [node])
        let sectionView = CraftLessonSectionView(section: section, onNodeTap: sendableNodeTap)
        XCTAssertNotNil(sectionView)

        let path = CraftLearningPath(section: section, onNodeTap: sendableNodeTap)
        XCTAssertNotNil(path)
    }
}
