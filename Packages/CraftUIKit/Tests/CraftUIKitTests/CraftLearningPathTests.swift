#if canImport(XCTest)
import XCTest
#endif
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
        XCTAssertNil(defaultNode.objectives)
        XCTAssertNil(defaultNode.objectiveKeys)

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
            badgeText: "HOT",
            objectives: ["Master 15 advanced words", "Pass timed test"],
            objectiveKeys: ["craft.objectives.master15", "craft.objectives.timed_test"]
        )

        XCTAssertEqual(fullNode.subtitle, "15 từ mới • 4 phút")
        XCTAssertEqual(fullNode.kind, .checkpoint)
        XCTAssertEqual(fullNode.xpReward, 50)
        XCTAssertEqual(fullNode.estimatedMinutes, 4)
        XCTAssertEqual(fullNode.stars, 3)
        XCTAssertEqual(fullNode.objectives, ["Master 15 advanced words", "Pass timed test"])
        XCTAssertEqual(fullNode.objectiveKeys, ["craft.objectives.master15", "craft.objectives.timed_test"])

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
            badgeText: "HOT",
            objectives: ["Master 15 advanced words", "Pass timed test"],
            objectiveKeys: ["craft.objectives.master15", "craft.objectives.timed_test"]
        )
        XCTAssertEqual(fullNode, fullNodeCopy)

        let differentObjectivesNode = LessonNodeModel(
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
            badgeText: "HOT",
            objectives: ["Different objective"],
            objectiveKeys: ["craft.objectives.different"]
        )
        XCTAssertNotEqual(fullNode, differentObjectivesNode)

        let set: Set<LessonNodeModel> = [defaultNode, fullNode, treasureNode, fullNodeCopy, differentObjectivesNode]
        XCTAssertEqual(set.count, 4)
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

    func testBobbingAnimationPhaseAndToken() {
        XCTAssertEqual(BobbingPhase.allCases, [.high, .low])
        XCTAssertEqual(BobbingPhase.allCases.count, 2)
        XCTAssertEqual(BobbingPhase.high.rawValue, "high")
        XCTAssertEqual(BobbingPhase.low.rawValue, "low")

        let bobbing = Animation.craftBobbing
        XCTAssertNotNil(bobbing)
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

    // MARK: - CraftSmartConnector Tests

    func testCraftSmartConnectorInstantiationForAllStyles() {
        let from = CGPoint(x: 100, y: 150)
        let to = CGPoint(x: 200, y: 350)

        for style in SmartConnectorStyle.allCases {
            let connector = CraftSmartConnector(from: from, to: to, style: style)
            XCTAssertNotNil(connector)
            XCTAssertEqual(connector.from, from)
            XCTAssertEqual(connector.to, to)
            XCTAssertEqual(connector.style, style)
            XCTAssertNil(connector.customColor)

            let customConnector = CraftSmartConnector(from: from, to: to, style: style, customColor: .purple)
            XCTAssertNotNil(customConnector)
            XCTAssertEqual(customConnector.customColor, .purple)
        }
    }

    func testCraftSmartConnectorEquatability() {
        let from1 = CGPoint(x: 50, y: 50)
        let to1 = CGPoint(x: 150, y: 200)
        let from2 = CGPoint(x: 60, y: 60)

        let conn1 = CraftSmartConnector(from: from1, to: to1, style: .solid)
        let conn2 = CraftSmartConnector(from: from1, to: to1, style: .solid)
        let conn3 = CraftSmartConnector(from: from1, to: to1, style: .breathing)
        let conn4 = CraftSmartConnector(from: from2, to: to1, style: .solid)
        let conn5 = CraftSmartConnector(from: from1, to: to1, style: .solid, customColor: .red)
        let conn6 = CraftSmartConnector(from: from1, to: to1, style: .solid, customColor: .red)

        XCTAssertEqual(conn1, conn2)
        XCTAssertNotEqual(conn1, conn3)
        XCTAssertNotEqual(conn1, conn4)
        XCTAssertNotEqual(conn1, conn5)
        XCTAssertEqual(conn5, conn6)
    }

    func testCraftNodeConnectorBezierCurveContinuityAndBoundingBox() {
        // Offset S-curve left to right
        let connectorLR = CraftNodeConnector(
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 300, y: 500)
        )
        let pathLR = connectorLR.path(in: CGRect(x: 0, y: 0, width: 400, height: 600))
        XCTAssertFalse(pathLR.isEmpty)
        XCTAssertEqual(pathLR.boundingRect.minX, 100, accuracy: 1.0)
        XCTAssertEqual(pathLR.boundingRect.maxX, 300, accuracy: 1.0)
        XCTAssertEqual(pathLR.boundingRect.minY, 100, accuracy: 1.0)
        XCTAssertEqual(pathLR.boundingRect.maxY, 500, accuracy: 1.0)

        // Offset S-curve right to left
        let connectorRL = CraftNodeConnector(
            from: CGPoint(x: 300, y: 100),
            to: CGPoint(x: 100, y: 500)
        )
        let pathRL = connectorRL.path(in: CGRect(x: 0, y: 0, width: 400, height: 600))
        XCTAssertFalse(pathRL.isEmpty)
        XCTAssertEqual(pathRL.boundingRect.minX, 100, accuracy: 1.0)
        XCTAssertEqual(pathRL.boundingRect.maxX, 300, accuracy: 1.0)
        XCTAssertEqual(pathRL.boundingRect.minY, 100, accuracy: 1.0)
        XCTAssertEqual(pathRL.boundingRect.maxY, 500, accuracy: 1.0)
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

    func testCraftLessonNodeDimensionsForAllStatesAndKinds() {
        let completed = CraftLessonNode(model: LessonNodeModel(id: "1", title: "1", state: .completed))
        let active = CraftLessonNode(model: LessonNodeModel(id: "2", title: "2", state: .active))
        let inProgress = CraftLessonNode(model: LessonNodeModel(id: "3", title: "3", state: .inProgress))
        let upcoming = CraftLessonNode(model: LessonNodeModel(id: "4", title: "4", state: .upcoming))
        let locked = CraftLessonNode(model: LessonNodeModel(id: "5", title: "5", state: .locked))
        let bonus = CraftLessonNode(model: LessonNodeModel(id: "6", title: "6", state: .bonus))

        XCTAssertEqual(completed.nodeDiameter, 52)
        XCTAssertEqual(active.nodeDiameter, 64)
        XCTAssertEqual(inProgress.nodeDiameter, 56)
        XCTAssertEqual(upcoming.nodeDiameter, 48)
        XCTAssertEqual(locked.nodeDiameter, 48)
        XCTAssertEqual(bonus.nodeDiameter, 56)

        XCTAssertEqual(completed.iconSize, 20)
        XCTAssertEqual(active.iconSize, 26)
        XCTAssertEqual(inProgress.iconSize, 22)
        XCTAssertEqual(upcoming.iconSize, 18)
        XCTAssertEqual(locked.iconSize, 18)
        XCTAssertEqual(bonus.iconSize, 22)

        // Kind variants
        let checkpoint = CraftLessonNode(model: LessonNodeModel(id: "cp", title: "Checkpoint", state: .active, kind: .checkpoint))
        let treasure = CraftLessonNode(model: LessonNodeModel(id: "tc", title: "Treasure", state: .completed, kind: .treasureChest))
        XCTAssertEqual(checkpoint.model.kind, .checkpoint)
        XCTAssertEqual(treasure.model.kind, .treasureChest)
    }

    func testCraftLessonNodeVoiceOverDescriptionsWithXPReward() {
        let activeWithXP = LessonNodeModel(
            id: "act_xp",
            title: "Daily Greetings",
            state: .active,
            progress: 0.65,
            xpReward: 25
        )
        let activeNode = CraftLessonNode(model: activeWithXP)
        XCTAssertEqual(activeNode.accessibilityLabelText, "Lesson: Daily Greetings, Current lesson. 65% complete. Reward: 25 XP")
        XCTAssertEqual(activeNode.accessibilityHintText, "Double tap to continue")

        let completedWithXP = LessonNodeModel(
            id: "comp_xp",
            title: "Basics",
            state: .completed,
            xpReward: 10
        )
        let compNode = CraftLessonNode(model: completedWithXP)
        XCTAssertEqual(compNode.accessibilityLabelText, "Lesson: Basics, Completed. Reward: 10 XP")

        let lockedWithXP = LessonNodeModel(
            id: "lock_xp",
            title: "Verbs",
            state: .locked,
            xpReward: 20
        )
        let lockedNode = CraftLessonNode(model: lockedWithXP)
        XCTAssertEqual(lockedNode.accessibilityLabelText, "Lesson: Verbs, Locked. Reward: 20 XP")

        let bonusWithXP = LessonNodeModel(
            id: "bonus_xp",
            title: "Mastery Challenge",
            state: .bonus,
            xpReward: 50
        )
        let bonusNode = CraftLessonNode(model: bonusWithXP)
        XCTAssertEqual(bonusNode.accessibilityLabelText, "Bonus Lesson: Mastery Challenge. Reward: 50 XP")
    }

    func testActiveCalloutBubbleInstantiationAndVariants() {
        let defaultBubble = ActiveCalloutBubble()
        XCTAssertEqual(defaultBubble.text, "CONTINUE")

        let customBubble = ActiveCalloutBubble("START")
        XCTAssertEqual(customBubble.text, "START")

        let paramBubble = ActiveCalloutBubble(text: "START NOW")
        XCTAssertEqual(paramBubble.text, "START NOW")

        let nodeWithCallout = CraftLessonNode(
            model: LessonNodeModel(id: "c1", title: "Node", state: .active),
            calloutText: "START"
        )
        XCTAssertEqual(nodeWithCallout.calloutText, "START")
    }

    func testTactileShapesAndButtonStyle() {
        let hexagon = HexagonShape()
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let hexPath = hexagon.path(in: rect)
        XCTAssertFalse(hexPath.isEmpty)

        let insetHex = hexagon.inset(by: 2)
        let insetHexPath = insetHex.path(in: rect)
        XCTAssertFalse(insetHexPath.isEmpty)

        let diamond = DiamondShape()
        let diamondPath = diamond.path(in: rect)
        XCTAssertFalse(diamondPath.isEmpty)

        let insetDiamond = diamond.inset(by: 2)
        let insetDiamondPath = insetDiamond.path(in: rect)
        XCTAssertFalse(insetDiamondPath.isEmpty)

        let caret = CaretDownShape()
        let caretPath = caret.path(in: CGRect(x: 0, y: 0, width: 10, height: 6))
        XCTAssertFalse(caretPath.isEmpty)

        let buttonStyle = TactileNodeButtonStyle(isLocked: false, depth: 4)
        XCTAssertFalse(buttonStyle.isLocked)
        XCTAssertEqual(buttonStyle.depth, 4)
    }

    func testCraftLessonNodeMetadataFormatting() {
        let nodeWithSubtitle = CraftLessonNode(
            model: LessonNodeModel(id: "m1", title: "Test", subtitle: "10 words • 2 min", xpReward: 50)
        )
        XCTAssertEqual(nodeWithSubtitle.metadataText, "10 words • 2 min")

        let nodeWithXPOnly = CraftLessonNode(
            model: LessonNodeModel(id: "m2", title: "Test", xpReward: 30)
        )
        XCTAssertEqual(nodeWithXPOnly.metadataText, "+30 XP")

        let nodeWithNeither = CraftLessonNode(
            model: LessonNodeModel(id: "m3", title: "Test")
        )
        XCTAssertNil(nodeWithNeither.metadataText)
    }

    func testTactileNodeButtonStyleLocked() {
        let lockedStyle = TactileNodeButtonStyle(isLocked: true, depth: 4)
        XCTAssertTrue(lockedStyle.isLocked)
        XCTAssertEqual(lockedStyle.depth, 4)
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

    // MARK: - Snake Row Layout and Node Slot Tests

    func testNodeSlotCasesRawValuesAndXRatios() {
        XCTAssertEqual(NodeSlot.allCases.count, 3)
        XCTAssertTrue(NodeSlot.allCases.contains(.center))
        XCTAssertTrue(NodeSlot.allCases.contains(.left))
        XCTAssertTrue(NodeSlot.allCases.contains(.right))

        XCTAssertEqual(NodeSlot.left.rawValue, "left")
        XCTAssertEqual(NodeSlot.center.rawValue, "center")
        XCTAssertEqual(NodeSlot.right.rawValue, "right")

        XCTAssertEqual(NodeSlot.left.xRatio, 0.26, accuracy: 0.001)
        XCTAssertEqual(NodeSlot.center.xRatio, 0.50, accuracy: 0.001)
        XCTAssertEqual(NodeSlot.right.xRatio, 0.74, accuracy: 0.001)

        XCTAssertEqual(NodeSlot.left, NodeSlot.left)
        XCTAssertNotEqual(NodeSlot.left, NodeSlot.right)
        XCTAssertNotEqual(NodeSlot.center, NodeSlot.left)

        let set: Set<NodeSlot> = [.left, .center, .right, .left]
        XCTAssertEqual(set.count, 3)
    }

    func testPositionedLessonNodePropertiesAndEquatability() {
        let node1 = LessonNodeModel(id: "n1", title: "Lesson 1", state: .completed)
        let node2 = LessonNodeModel(id: "n2", title: "Lesson 2", state: .active)

        let pNode1 = PositionedLessonNode(node: node1, slot: .center, traversalIndex: 0)
        let pNode1Duplicate = PositionedLessonNode(node: node1, slot: .center, traversalIndex: 0)
        let pNode2 = PositionedLessonNode(node: node2, slot: .left, traversalIndex: 1)

        XCTAssertEqual(pNode1.id, "n1")
        XCTAssertEqual(pNode1.node, node1)
        XCTAssertEqual(pNode1.slot, .center)
        XCTAssertEqual(pNode1.traversalIndex, 0)

        XCTAssertEqual(pNode1, pNode1Duplicate)
        XCTAssertNotEqual(pNode1, pNode2)
    }

    func testSnakeRowLayoutPropertiesAndEquatability() {
        let pNode1 = PositionedLessonNode(
            node: LessonNodeModel(id: "n1", title: "L1"),
            slot: .center,
            traversalIndex: 0
        )
        let pNode2 = PositionedLessonNode(
            node: LessonNodeModel(id: "n2", title: "L2"),
            slot: .left,
            traversalIndex: 1
        )

        let layout1 = SnakeRowLayout(id: "row_0", rowIndex: 0, nodes: [pNode1])
        let layout1Copy = SnakeRowLayout(id: "row_0", rowIndex: 0, nodes: [pNode1])
        let layout2 = SnakeRowLayout(id: "row_1", rowIndex: 1, nodes: [pNode2])

        XCTAssertEqual(layout1.id, "row_0")
        XCTAssertEqual(layout1.rowIndex, 0)
        XCTAssertEqual(layout1.nodes.count, 1)
        XCTAssertEqual(layout1.nodes.first, pNode1)

        XCTAssertEqual(layout1, layout1Copy)
        XCTAssertNotEqual(layout1, layout2)
    }

    func testSnakeRowLayoutStandardPattern() {
        let nodes = (0..<6).map {
            LessonNodeModel(id: "node_\($0)", title: "Lesson \($0)")
        }
        let rows = RowPattern.standard.layoutRows(nodes: nodes)

        // Row 0 (Count 1): Center
        XCTAssertEqual(rows.count, 4)
        XCTAssertEqual(rows[0].id, "row_0")
        XCTAssertEqual(rows[0].rowIndex, 0)
        XCTAssertEqual(rows[0].nodes.count, 1)
        XCTAssertEqual(rows[0].nodes[0].slot, .center)
        XCTAssertEqual(rows[0].nodes[0].traversalIndex, 0)
        XCTAssertEqual(rows[0].nodes[0].node.id, "node_0")

        // Row 1 (Count 2): Right then Left (traversal: Right first (1), then Left (2))
        XCTAssertEqual(rows[1].id, "row_1")
        XCTAssertEqual(rows[1].rowIndex, 1)
        XCTAssertEqual(rows[1].nodes.count, 2)
        XCTAssertEqual(rows[1].nodes[0].slot, .left)
        XCTAssertEqual(rows[1].nodes[1].slot, .right)
        XCTAssertEqual(rows[1].nodes[1].traversalIndex, 1) // First visited in row 1
        XCTAssertEqual(rows[1].nodes[1].node.id, "node_1")
        XCTAssertEqual(rows[1].nodes[0].traversalIndex, 2) // Second visited in row 1
        XCTAssertEqual(rows[1].nodes[0].node.id, "node_2")

        // Row 2 (Count 1): Center
        XCTAssertEqual(rows[2].id, "row_2")
        XCTAssertEqual(rows[2].rowIndex, 2)
        XCTAssertEqual(rows[2].nodes.count, 1)
        XCTAssertEqual(rows[2].nodes[0].slot, .center)
        XCTAssertEqual(rows[2].nodes[0].traversalIndex, 3)
        XCTAssertEqual(rows[2].nodes[0].node.id, "node_3")

        // Row 3 (Count 2): Right then Left (traversal: Right first (4), then Left (5))
        XCTAssertEqual(rows[3].id, "row_3")
        XCTAssertEqual(rows[3].rowIndex, 3)
        XCTAssertEqual(rows[3].nodes.count, 2)
        XCTAssertEqual(rows[3].nodes[0].slot, .left)
        XCTAssertEqual(rows[3].nodes[1].slot, .right)
        XCTAssertEqual(rows[3].nodes[1].traversalIndex, 4)
        XCTAssertEqual(rows[3].nodes[1].node.id, "node_4")
        XCTAssertEqual(rows[3].nodes[0].traversalIndex, 5)
        XCTAssertEqual(rows[3].nodes[0].node.id, "node_5")
    }

    func testSnakeRowLayoutSingleNodeAndEmpty() {
        let emptyRows = RowPattern.standard.layoutRows(nodes: [])
        XCTAssertTrue(emptyRows.isEmpty)

        let singleNode = [LessonNodeModel(id: "n0", title: "Intro")]
        let singleRows = RowPattern.standard.layoutRows(nodes: singleNode)
        XCTAssertEqual(singleRows.count, 1)
        XCTAssertEqual(singleRows[0].id, "row_0")
        XCTAssertEqual(singleRows[0].rowIndex, 0)
        XCTAssertEqual(singleRows[0].nodes.count, 1)
        XCTAssertEqual(singleRows[0].nodes[0].slot, .center)
        XCTAssertEqual(singleRows[0].nodes[0].traversalIndex, 0)
        XCTAssertEqual(singleRows[0].nodes[0].node.id, "n0")
    }

    func testSnakeRowLayoutWavePattern() {
        let nodes = (0..<8).map {
            LessonNodeModel(id: "wave_\($0)", title: "Wave \($0)")
        }
        let rows = RowPattern.wave.layoutRows(nodes: nodes)

        // Wave is [1, 2, 3, 2] -> sum = 8 nodes -> exactly 4 rows
        XCTAssertEqual(rows.count, 4)

        // Row 0: 1 node @ center (traversal index 0)
        XCTAssertEqual(rows[0].nodes.count, 1)
        XCTAssertEqual(rows[0].nodes[0].slot, .center)
        XCTAssertEqual(rows[0].nodes[0].traversalIndex, 0)

        // Row 1: 2 nodes @ left, right (traversal right=1, left=2)
        XCTAssertEqual(rows[1].nodes.count, 2)
        XCTAssertEqual(rows[1].nodes[0].slot, .left)
        XCTAssertEqual(rows[1].nodes[1].slot, .right)
        XCTAssertEqual(rows[1].nodes[1].traversalIndex, 1)
        XCTAssertEqual(rows[1].nodes[0].traversalIndex, 2)

        // Row 2: 3 nodes @ left, center, right (traversal left=3, center=4, right=5)
        XCTAssertEqual(rows[2].nodes.count, 3)
        XCTAssertEqual(rows[2].nodes[0].slot, .left)
        XCTAssertEqual(rows[2].nodes[1].slot, .center)
        XCTAssertEqual(rows[2].nodes[2].slot, .right)
        XCTAssertEqual(rows[2].nodes[0].traversalIndex, 3)
        XCTAssertEqual(rows[2].nodes[1].traversalIndex, 4)
        XCTAssertEqual(rows[2].nodes[2].traversalIndex, 5)

        // Row 3: 2 nodes @ left, right (traversal right=6, left=7)
        XCTAssertEqual(rows[3].nodes.count, 2)
        XCTAssertEqual(rows[3].nodes[0].slot, .left)
        XCTAssertEqual(rows[3].nodes[1].slot, .right)
        XCTAssertEqual(rows[3].nodes[1].traversalIndex, 6)
        XCTAssertEqual(rows[3].nodes[0].traversalIndex, 7)
    }

    func testSnakeRowLayoutCustomPatternAndEdgeCases() {
        let nodes = (0..<6).map {
            LessonNodeModel(id: "c_\($0)", title: "Custom \($0)")
        }

        // Custom [3, 1, 2]
        let customRows = RowPattern.custom([3, 1, 2]).layoutRows(nodes: nodes)
        XCTAssertEqual(customRows.count, 3)
        XCTAssertEqual(customRows[0].nodes.count, 3)
        XCTAssertEqual(customRows[0].nodes[0].slot, .left)
        XCTAssertEqual(customRows[0].nodes[1].slot, .center)
        XCTAssertEqual(customRows[0].nodes[2].slot, .right)

        XCTAssertEqual(customRows[1].nodes.count, 1)
        XCTAssertEqual(customRows[1].nodes[0].slot, .center)
        XCTAssertEqual(customRows[1].nodes[0].traversalIndex, 3)

        XCTAssertEqual(customRows[2].nodes.count, 2)
        XCTAssertEqual(customRows[2].nodes[0].slot, .left)
        XCTAssertEqual(customRows[2].nodes[1].slot, .right)
        XCTAssertEqual(customRows[2].nodes[1].traversalIndex, 4)
        XCTAssertEqual(customRows[2].nodes[0].traversalIndex, 5)

        // Custom empty defaults to 1 per row
        let fallbackRows = RowPattern.custom([]).layoutRows(nodes: nodes)
        XCTAssertEqual(fallbackRows.count, 6)
        for (i, row) in fallbackRows.enumerated() {
            XCTAssertEqual(row.nodes.count, 1)
            XCTAssertEqual(row.nodes[0].slot, .center)
            XCTAssertEqual(row.nodes[0].traversalIndex, i)
        }

        // Partial row at end
        let partialNodes = (0..<2).map {
            LessonNodeModel(id: "p_\($0)", title: "Partial \($0)")
        }
        // Standard pattern [1, 2]: row 0 takes 1 node, row 1 has 1 node left (instead of 2)
        let partialRows = RowPattern.standard.layoutRows(nodes: partialNodes)
        XCTAssertEqual(partialRows.count, 2)
        XCTAssertEqual(partialRows[0].nodes.count, 1)
        XCTAssertEqual(partialRows[0].nodes[0].slot, .center)
        XCTAssertEqual(partialRows[0].nodes[0].traversalIndex, 0)
        XCTAssertEqual(partialRows[1].nodes.count, 1)
        XCTAssertEqual(partialRows[1].nodes[0].slot, .center)
        XCTAssertEqual(partialRows[1].nodes[0].traversalIndex, 1)
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

    // MARK: - Task 4: Serpentine Row & Unit Portal Tests

    func testCraftLessonRowOffsetCalculation() {
        let node = LessonNodeModel(id: "n1", title: "Intro", state: .completed)
        let row = CraftLessonRow(node: node, offsetRatio: -0.4)
        XCTAssertEqual(row.node.id, "n1")
        XCTAssertEqual(row.offsetRatio, -0.4, accuracy: 0.01)
    }

    func testCraftLessonRowSerpentineInitializationAndEquatability() {
        let node1 = LessonNodeModel(id: "n1", title: "Greetings", state: .active)
        let node2 = LessonNodeModel(id: "n2", title: "Numbers", state: .upcoming)

        let row1 = CraftLessonRow(node: node1, offsetRatio: -0.55)
        let row2 = CraftLessonRow(node: node1, offsetRatio: -0.55)
        let row3 = CraftLessonRow(node: node1, offsetRatio: 0.25)
        let row4 = CraftLessonRow(node: node2, offsetRatio: -0.55)

        XCTAssertEqual(row1, row2)
        XCTAssertNotEqual(row1, row3)
        XCTAssertNotEqual(row1, row4)

        XCTAssertEqual(row1.node, node1)
        XCTAssertEqual(row1.offsetRatio, -0.55, accuracy: 0.001)

        // Single-node backward compatibility helper
        XCTAssertEqual(row1.nodes.count, 1)
        XCTAssertEqual(row1.nodes.first, node1)
    }

    func testCraftLessonRowTapCallbackWithSingleNode() {
        var tapped: LessonNodeModel?
        let node = LessonNodeModel(id: "tap_node", title: "Tap Me", state: .active)
        let row = CraftLessonRow(node: node, offsetRatio: 0.4) { selected in
            tapped = selected
        }
        XCTAssertNotNil(row)
        row.onNodeTap?(node)
        XCTAssertEqual(tapped?.id, "tap_node")
    }

    func testCraftLessonSectionViewUnitPortalHeaderCard() {
        let node1 = LessonNodeModel(id: "n1", title: "Basics", state: .completed)
        let node2 = LessonNodeModel(id: "n2", title: "Phrases", state: .active)

        let section = LessonSection(
            id: "sec_portal",
            title: "Unit 1: Essential Foundations",
            subtitle: "Master everyday vocabulary and phrases",
            level: "UNIT 1",
            progressText: "4/8 HOÀN THÀNH",
            progressValue: 0.5,
            bannerIcon: "sparkles",
            nodes: [node1, node2],
            winding: .standard
        )

        var tappedNode: LessonNodeModel?
        let sectionView = CraftLessonSectionView(section: section) { node in
            tappedNode = node
        }

        XCTAssertNotNil(sectionView)
        XCTAssertEqual(sectionView.section.id, "sec_portal")
        XCTAssertEqual(sectionView.section.title, "Unit 1: Essential Foundations")
        XCTAssertEqual(sectionView.section.subtitle, "Master everyday vocabulary and phrases")
        XCTAssertEqual(sectionView.section.level, "UNIT 1")
        XCTAssertEqual(sectionView.section.progressText, "4/8 HOÀN THÀNH")
        XCTAssertEqual(sectionView.section.progressValue, 0.5)
        XCTAssertEqual(sectionView.section.bannerIcon, "sparkles")
        XCTAssertEqual(sectionView.section.nodes.count, 2)
        XCTAssertEqual(sectionView.section.winding, .standard)

        sectionView.onNodeTap?(node2)
        XCTAssertEqual(tappedNode?.id, "n2")
    }

    func testCraftLessonSectionViewWindingOffsetsAndInferredConnectors() {
        let nodes = (0..<4).map {
            LessonNodeModel(
                id: "w_node_\($0)",
                title: "Lesson \($0)",
                state: $0 == 0 ? .completed : ($0 == 1 ? .active : .upcoming)
            )
        }
        let section = LessonSection(
            id: "sec_winding",
            title: "Serpentine Section",
            nodes: nodes,
            winding: .gentle
        )

        let sectionView = CraftLessonSectionView(section: section)
        XCTAssertNotNil(sectionView)
        XCTAssertEqual(sectionView.section.winding, .gentle)
        XCTAssertEqual(sectionView.section.winding.offsetRatio(for: 0), 0.0, accuracy: 0.001)
        XCTAssertEqual(sectionView.section.winding.offsetRatio(for: 1), -0.25, accuracy: 0.001)
        XCTAssertEqual(sectionView.section.winding.offsetRatio(for: 2), -0.35, accuracy: 0.001)
        XCTAssertEqual(sectionView.section.winding.offsetRatio(for: 3), -0.15, accuracy: 0.001)

        // Check inferred connector styles between consecutive pairs
        let style01 = SmartConnectorStyle.infer(from: nodes[0].state, to: nodes[1].state)
        XCTAssertEqual(style01, .breathing)

        let style12 = SmartConnectorStyle.infer(from: nodes[1].state, to: nodes[2].state)
        XCTAssertEqual(style12, .dashed)

        let style23 = SmartConnectorStyle.infer(from: nodes[2].state, to: nodes[3].state)
        XCTAssertEqual(style23, .muted)
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

    func testCraftLessonSectionHeaderView() {
        let fullSection = LessonSection(
            id: "s_header",
            title: "Unit 1: Basics",
            subtitle: "Intro phrases",
            level: "LEVEL 1",
            progressText: "3/5",
            progressValue: 0.6,
            bannerIcon: "sparkles",
            nodes: []
        )
        let headerView = CraftLessonSectionHeaderView(section: fullSection)
        XCTAssertNotNil(headerView.body)
        XCTAssertEqual(headerView.section.id, "s_header")
        XCTAssertTrue(headerView.hasHeaderContent)

        let minimalSection = LessonSection(id: "s_min", title: "Minimal", nodes: [])
        let minHeaderView = CraftLessonSectionHeaderView(section: minimalSection)
        XCTAssertTrue(minHeaderView.hasHeaderContent)

        let emptySection = LessonSection(id: "s_empty", title: "", nodes: [])
        let emptyHeaderView = CraftLessonSectionHeaderView(section: emptySection)
        XCTAssertFalse(emptyHeaderView.hasHeaderContent)
    }

    func testCraftLessonSectionBodyView() {
        var tappedNode: LessonNodeModel?
        let nodes = [
            LessonNodeModel(id: "bn1", title: "Body Node 1", state: .completed),
            LessonNodeModel(id: "bn2", title: "Body Node 2", state: .active)
        ]
        let section = LessonSection(id: "s_body", title: "Body Unit", nodes: nodes, rowPattern: .standard)

        let bodyView = CraftLessonSectionBodyView(section: section) { node in
            tappedNode = node
        }
        XCTAssertNotNil(bodyView.body)
        XCTAssertEqual(bodyView.section.id, "s_body")
        XCTAssertEqual(bodyView.rowPattern, .standard)

        bodyView.onNodeTap?(nodes[0])
        XCTAssertEqual(tappedNode?.id, "bn1")

        let waveBodyView = CraftLessonSectionBodyView(section: section, rowPattern: .wave)
        XCTAssertEqual(waveBodyView.rowPattern, .wave)
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
        XCTAssertFalse(singlePath.pinSectionHeaders)
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

    func testCraftLearningPathPinSectionHeaders() {
        let node = LessonNodeModel(id: "pn1", title: "Path Node", state: .active)
        let section = LessonSection(id: "ps1", title: "Path Section", nodes: [node])

        // Single section init defaults pinSectionHeaders to false
        let singlePathDefault = CraftLearningPath(section: section)
        XCTAssertFalse(singlePathDefault.pinSectionHeaders)
        XCTAssertNotNil(singlePathDefault.body)

        // Single section explicit pinSectionHeaders: false
        let singlePathNoPin = CraftLearningPath(section: section, pinSectionHeaders: false)
        XCTAssertFalse(singlePathNoPin.pinSectionHeaders)
        XCTAssertNotNil(singlePathNoPin.body)

        // Single section explicit pinSectionHeaders: true
        let singlePathWithPin = CraftLearningPath(section: section, pinSectionHeaders: true)
        XCTAssertTrue(singlePathWithPin.pinSectionHeaders)
        XCTAssertNotNil(singlePathWithPin.body)

        // Multi section init defaults pinSectionHeaders to false
        let multiPathDefault = CraftLearningPath(sections: [section])
        XCTAssertFalse(multiPathDefault.pinSectionHeaders)
        XCTAssertNotNil(multiPathDefault.body)

        // Multi section explicit pinSectionHeaders: false
        let multiPathNoPin = CraftLearningPath(sections: [section], pinSectionHeaders: false)
        XCTAssertFalse(multiPathNoPin.pinSectionHeaders)
        XCTAssertNotNil(multiPathNoPin.body)

        // Multi section explicit pinSectionHeaders: true
        let multiPathWithPin = CraftLearningPath(sections: [section], pinSectionHeaders: true)
        XCTAssertTrue(multiPathWithPin.pinSectionHeaders)
        XCTAssertNotNil(multiPathWithPin.body)

        // Single section with rowPattern init defaults pinSectionHeaders to false
        let customRowSingleDefault = CraftLearningPath(section: section, rowPattern: .wave)
        XCTAssertFalse(customRowSingleDefault.pinSectionHeaders)
        let customRowSingleNoPin = CraftLearningPath(section: section, rowPattern: .wave, pinSectionHeaders: false)
        XCTAssertFalse(customRowSingleNoPin.pinSectionHeaders)

        // Multi section with rowPattern init defaults pinSectionHeaders to false
        let customRowMultiDefault = CraftLearningPath(sections: [section], rowPattern: .wave)
        XCTAssertFalse(customRowMultiDefault.pinSectionHeaders)
        let customRowMultiNoPin = CraftLearningPath(sections: [section], rowPattern: .wave, pinSectionHeaders: false)
        XCTAssertFalse(customRowMultiNoPin.pinSectionHeaders)
    }

    func testCraftLearningPathDefaultPinSectionHeadersIsFalse() {
        let section = LessonSection(
            id: "unit_pin_default",
            title: "Default Pin Unit",
            nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
        )
        let path = CraftLearningPath(sections: [section])
        XCTAssertFalse(path.pinSectionHeaders)

        let singlePath = CraftLearningPath(section: section)
        XCTAssertFalse(singlePath.pinSectionHeaders)
    }

    func testCraftLearningPathStickyHUDTapGestureAccessibility() {
        let section = LessonSection(
            id: "unit_tap_hud",
            title: "Tap HUD Unit",
            level: "LEVEL 2",
            progressText: "2/4",
            progressValue: 0.5,
            nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
        )
        let path = CraftLearningPath(sections: [section])
        XCTAssertNotNil(path.body)
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

    // MARK: - Task 5: CraftLessonDetailSheet Tests

    func testLessonDetailSheetInstantiation() {
        let node = LessonNodeModel(
            id: "sheet_node_1",
            title: "Daily Food & Drinks",
            subtitle: "15 từ mới • 4 phút",
            iconName: "cup.and.saucer.fill",
            state: .active,
            kind: .standard,
            progress: 0.5,
            xpReward: 25,
            estimatedMinutes: 4
        )

        var startedNode: LessonNodeModel?
        var didDismiss = false

        let sheet = CraftLessonDetailSheet(
            node: node,
            onStart: { started in startedNode = started },
            onDismiss: { didDismiss = true }
        )

        XCTAssertNotNil(sheet)
        XCTAssertEqual(sheet.node.id, "sheet_node_1")
        XCTAssertEqual(sheet.node.title, "Daily Food & Drinks")

        sheet.onStart?(node)
        XCTAssertEqual(startedNode?.id, "sheet_node_1")

        sheet.onDismiss?()
        XCTAssertTrue(didDismiss)
    }

    func testLessonDetailSheetCTAResolutionAllStates() {
        // 1. Active State
        let activeNode = LessonNodeModel(id: "act", title: "Active Lesson", state: .active)
        let activeSheet = CraftLessonDetailSheet(node: activeNode)
        XCTAssertEqual(activeSheet.ctaTitle, "START LESSON")
        XCTAssertEqual(activeSheet.ctaVariant, .primary)
        XCTAssertFalse(activeSheet.isCtaDisabled)

        // 2. Upcoming State
        let upcomingNode = LessonNodeModel(id: "up", title: "Upcoming Lesson", state: .upcoming)
        let upcomingSheet = CraftLessonDetailSheet(node: upcomingNode)
        XCTAssertEqual(upcomingSheet.ctaTitle, "START LESSON")
        XCTAssertEqual(upcomingSheet.ctaVariant, .primary)
        XCTAssertFalse(upcomingSheet.isCtaDisabled)

        // 3. InProgress State (with progress)
        let inProgressNode = LessonNodeModel(id: "prog", title: "In Progress Lesson", state: .inProgress, progress: 0.65)
        let inProgressSheet = CraftLessonDetailSheet(node: inProgressNode)
        XCTAssertEqual(inProgressSheet.ctaTitle, "CONTINUE (65%)")
        XCTAssertEqual(inProgressSheet.ctaVariant, .primary)
        XCTAssertFalse(inProgressSheet.isCtaDisabled)

        // 3b. InProgress State (nil progress)
        let inProgressNilNode = LessonNodeModel(id: "prog_nil", title: "In Progress Nil", state: .inProgress)
        let inProgressNilSheet = CraftLessonDetailSheet(node: inProgressNilNode)
        XCTAssertEqual(inProgressNilSheet.ctaTitle, "CONTINUE (0%)")
        XCTAssertEqual(inProgressNilSheet.ctaVariant, .primary)
        XCTAssertFalse(inProgressNilSheet.isCtaDisabled)

        // 4. Completed State
        let completedNode = LessonNodeModel(id: "comp", title: "Completed Lesson", state: .completed)
        let completedSheet = CraftLessonDetailSheet(node: completedNode)
        XCTAssertEqual(completedSheet.ctaTitle, "REVIEW (+20 XP)")
        XCTAssertEqual(completedSheet.ctaVariant, .secondary)
        XCTAssertFalse(completedSheet.isCtaDisabled)

        // 5. Bonus State
        let bonusNode = LessonNodeModel(id: "bon", title: "Bonus Challenge", state: .bonus)
        let bonusSheet = CraftLessonDetailSheet(node: bonusNode)
        XCTAssertEqual(bonusSheet.ctaTitle, "CONQUER CHALLENGE")
        XCTAssertEqual(bonusSheet.ctaVariant, .primary)
        XCTAssertFalse(bonusSheet.isCtaDisabled)

        // 6. Locked State
        let lockedNode = LessonNodeModel(id: "lock", title: "Locked Lesson", state: .locked)
        let lockedSheet = CraftLessonDetailSheet(node: lockedNode)
        XCTAssertEqual(lockedSheet.ctaTitle, "LESSON LOCKED")
        XCTAssertEqual(lockedSheet.ctaVariant, .secondary)
        XCTAssertTrue(lockedSheet.isCtaDisabled)
    }

    func testLessonDetailSheetMetricsFormatting() {
        // Custom values
        let nodeWithValues = LessonNodeModel(
            id: "m1",
            title: "Travel Vocabulary",
            subtitle: "20 từ vựng du lịch",
            state: .active,
            xpReward: 35,
            estimatedMinutes: 8
        )
        let sheetWithValues = CraftLessonDetailSheet(node: nodeWithValues)
        XCTAssertEqual(sheetWithValues.formattedXPReward, "+35 XP")
        XCTAssertEqual(sheetWithValues.formattedDuration, "8 min")
        XCTAssertEqual(sheetWithValues.formattedVocabularyCount, "20 từ vựng du lịch")
        XCTAssertEqual(sheetWithValues.statusBadgeTitle, "Active")
        XCTAssertEqual(sheetWithValues.statusBadgeTone, .primary)

        // Default fallbacks
        let defaultNode = LessonNodeModel(id: "m2", title: "Default Lesson", state: .completed)
        let defaultSheet = CraftLessonDetailSheet(node: defaultNode)
        XCTAssertEqual(defaultSheet.formattedXPReward, "+20 XP")
        XCTAssertEqual(defaultSheet.formattedDuration, "5 min")
        XCTAssertEqual(defaultSheet.formattedVocabularyCount, "15 new words")
        XCTAssertEqual(defaultSheet.statusBadgeTitle, "Completed")
        XCTAssertEqual(defaultSheet.statusBadgeTone, .success)

        // Status badge tones for other states
        let lockedSheet = CraftLessonDetailSheet(node: LessonNodeModel(id: "l", title: "L", state: .locked))
        XCTAssertEqual(lockedSheet.statusBadgeTone, .neutral)

        let upcomingSheet = CraftLessonDetailSheet(node: LessonNodeModel(id: "u", title: "U", state: .upcoming))
        XCTAssertEqual(upcomingSheet.statusBadgeTone, .neutral)

        let bonusSheet = CraftLessonDetailSheet(node: LessonNodeModel(id: "b", title: "B", state: .bonus))
        XCTAssertEqual(bonusSheet.statusBadgeTone, .warning)

        let inProgressSheet = CraftLessonDetailSheet(node: LessonNodeModel(id: "p", title: "P", state: .inProgress))
        XCTAssertEqual(inProgressSheet.statusBadgeTone, .primary)
    }

    func testLessonDetailSheetCheckpointAndTreasureChestNodes() {
        let cpNode = LessonNodeModel(
            id: "cp_sheet",
            title: "Checkpoint Battle",
            iconName: "crown.fill",
            state: .active,
            kind: .checkpoint,
            xpReward: 100,
            estimatedMinutes: 10
        )
        let cpSheet = CraftLessonDetailSheet(node: cpNode)
        XCTAssertEqual(cpSheet.node.kind, .checkpoint)
        XCTAssertEqual(cpSheet.formattedXPReward, "+100 XP")
        XCTAssertEqual(cpSheet.formattedDuration, "10 min")

        let tcNode = LessonNodeModel(
            id: "tc_sheet",
            title: "Treasure Island",
            iconName: "gift.fill",
            state: .bonus,
            kind: .treasureChest,
            xpReward: 150
        )
        let tcSheet = CraftLessonDetailSheet(node: tcNode)
        XCTAssertEqual(tcSheet.node.kind, .treasureChest)
        XCTAssertEqual(tcSheet.formattedXPReward, "+150 XP")
    }

    func testLessonDetailSheetBodyRenderingForAllStates() {
        for state in LessonNodeState.allCases {
            let node = LessonNodeModel(
                id: "body_test_\(state.rawValue)",
                title: "Body Test \(state.rawValue)",
                subtitle: "Subtitle for \(state.rawValue)",
                iconName: "book.fill",
                state: state,
                progress: 0.5,
                xpReward: 30,
                estimatedMinutes: 5
            )
            let sheet = CraftLessonDetailSheet(
                node: node,
                onStart: { _ in },
                onDismiss: { }
            )
            XCTAssertNotNil(sheet.body)
        }
    }

    func testLessonDetailSheetBodyWithKindsAndSubtitles() {
        let checkpointNode = LessonNodeModel(
            id: "cp_body",
            title: "Checkpoint Boss",
            iconName: "",
            state: .active,
            kind: .checkpoint
        )
        let cpSheet = CraftLessonDetailSheet(node: checkpointNode)
        XCTAssertNotNil(cpSheet.body)

        let treasureChestNode = LessonNodeModel(
            id: "tc_body",
            title: "Treasure Chest",
            iconName: "",
            state: .bonus,
            kind: .treasureChest
        )
        let tcSheet = CraftLessonDetailSheet(node: treasureChestNode)
        XCTAssertNotNil(tcSheet.body)

        let emptySubtitleNode = LessonNodeModel(
            id: "empty_sub",
            title: "Empty Subtitle",
            subtitle: nil,
            state: .upcoming
        )
        let emptySubSheet = CraftLessonDetailSheet(node: emptySubtitleNode)
        XCTAssertNotNil(emptySubSheet.body)
    }

    @MainActor
    func testLessonDetailSheetActionCallbacksExecution() {
        final class CallbackBox: @unchecked Sendable {
            var startInvokedWith: LessonNodeModel?
            var dismissInvoked = false
        }
        let box = CallbackBox()

        let node = LessonNodeModel(
            id: "callback_node",
            title: "Callback Test",
            state: .active
        )

        let sendableStart: @Sendable (LessonNodeModel) -> Void = { n in
            box.startInvokedWith = n
        }
        let sendableDismiss: @Sendable () -> Void = {
            box.dismissInvoked = true
        }

        let sheet = CraftLessonDetailSheet(
            node: node,
            onStart: sendableStart,
            onDismiss: sendableDismiss
        )

        sheet.onStart?(node)
        XCTAssertEqual(box.startInvokedWith?.id, "callback_node")

        sheet.onDismiss?()
        XCTAssertTrue(box.dismissInvoked)
    }

    func testDetailSheetAccessibilityProperties() {
        let node = LessonNodeModel(
            id: "node_detail_a11y",
            title: "Advanced Phrasal Verbs",
            subtitle: "12 words • 3 min",
            iconName: "flame.fill",
            state: .active,
            xpReward: 35,
            estimatedMinutes: 3
        )
        let sheet = CraftLessonDetailSheet(node: node, onStart: { _ in }, onDismiss: { })
        XCTAssertEqual(sheet.node.id, "node_detail_a11y")
        XCTAssertEqual(sheet.formattedXPReward, "+35 XP")
        XCTAssertEqual(sheet.formattedDuration, "3 min")
        XCTAssertEqual(sheet.accessibilityXPLabel, "Reward: 35 XP")
        XCTAssertEqual(sheet.accessibilityDurationLabel, "Duration: 3 min")
        XCTAssertEqual(sheet.accessibilityVocabularyLabel, "12 words • 3 min")
    }

    func testDetailSheetAccessibilityFallbacks() {
        let defaultNode = LessonNodeModel(
            id: "node_default_a11y",
            title: "Basic Greetings"
        )
        let sheet = CraftLessonDetailSheet(node: defaultNode)
        XCTAssertEqual(sheet.formattedXPReward, "+20 XP")
        XCTAssertEqual(sheet.formattedDuration, "5 min")
        XCTAssertEqual(sheet.accessibilityXPLabel, "Reward: 20 XP")
        XCTAssertEqual(sheet.accessibilityDurationLabel, "Duration: 5 min")
        XCTAssertEqual(sheet.accessibilityVocabularyLabel, "15 new words")
    }

    @MainActor
    func testDetailSheetBodyContainsAccessibilityModifiers() {
        let node = LessonNodeModel(
            id: "node_body_a11y",
            title: "Idioms Masterclass",
            subtitle: "10 idioms • 5 min",
            state: .active,
            xpReward: 40,
            estimatedMinutes: 5
        )
        var dismissed = false
        let sheet = CraftLessonDetailSheet(
            node: node,
            onStart: { _ in },
            onDismiss: { dismissed = true }
        )
        XCTAssertNotNil(sheet.body)
        sheet.onDismiss?()
        XCTAssertTrue(dismissed)
    }

    // MARK: - Task 6: Root Container Integration, Sheet Wiring & Auto-Scroll Tests

    func testLearningPathInitializationWithWindingAndSheetProperties() {
        let node = LessonNodeModel(
            id: "n1",
            title: "Basics",
            subtitle: "10 words • 3 min",
            iconName: "book.fill",
            state: .active,
            kind: .standard,
            progress: 0.4,
            xpReward: 25,
            estimatedMinutes: 3,
            stars: 2
        )
        let section = LessonSection(
            id: "sec_1",
            title: "Unit 1: Essentials",
            nodes: [node],
            winding: .gentle
        )

        var startedNode: LessonNodeModel?
        var tappedNode: LessonNodeModel?

        let path = CraftLearningPath(
            sections: [section],
            winding: .gentle,
            onNodeTap: { tapped in tappedNode = tapped },
            onStartLesson: { started in startedNode = started },
            showDetailModal: true,
            scrollToActive: true,
            showCelebration: true
        )

        XCTAssertEqual(path.sections.count, 1)
        XCTAssertEqual(path.sections.first?.id, "sec_1")
        XCTAssertEqual(path.winding, .gentle)
        XCTAssertEqual(path.rowPattern, .standard)
        XCTAssertTrue(path.showDetailModal)
        XCTAssertTrue(path.scrollToActive)
        XCTAssertTrue(path.showCelebration)
        XCTAssertNotNil(path.onNodeTap)
        XCTAssertNotNil(path.onStartLesson)

        path.onNodeTap?(node)
        XCTAssertEqual(tappedNode?.id, "n1")

        path.onStartLesson?(node)
        XCTAssertEqual(startedNode?.id, "n1")
    }

    func testLearningPathSingleSectionInitWithWindingAndDefaults() {
        let node = LessonNodeModel(id: "n_single", title: "Single Node", state: .upcoming)
        let section = LessonSection(id: "sec_single", title: "Single Section", nodes: [node])

        let path = CraftLearningPath(
            section: section,
            winding: .linear,
            showDetailModal: false
        )

        XCTAssertEqual(path.sections.count, 1)
        XCTAssertEqual(path.winding, .linear)
        XCTAssertFalse(path.showDetailModal)
        XCTAssertTrue(path.scrollToActive)
        XCTAssertTrue(path.showCelebration)
        XCTAssertNil(path.onNodeTap)
        XCTAssertNil(path.onStartLesson)
    }

    func testLearningPathActiveNodeResolutionWithEnhancedSections() {
        let completedNode = LessonNodeModel(
            id: "u1_n1",
            title: "Intro",
            state: .completed,
            kind: .standard,
            xpReward: 20
        )
        let checkpointNode = LessonNodeModel(
            id: "u1_cp",
            title: "Checkpoint Boss",
            state: .completed,
            kind: .checkpoint,
            xpReward: 80
        )
        let activeNode = LessonNodeModel(
            id: "u2_n1",
            title: "Greetings",
            subtitle: "15 words • 5 min",
            state: .active,
            kind: .standard,
            progress: 0.6,
            xpReward: 30,
            estimatedMinutes: 5
        )
        let treasureNode = LessonNodeModel(
            id: "u2_chest",
            title: "Milestone Chest",
            state: .bonus,
            kind: .treasureChest,
            xpReward: 100
        )

        let section1 = LessonSection(
            id: "sec_1",
            title: "Unit 1: Foundations",
            nodes: [completedNode, checkpointNode],
            winding: .standard
        )
        let section2 = LessonSection(
            id: "sec_2",
            title: "Unit 2: Daily Dialogues",
            nodes: [activeNode, treasureNode],
            winding: .gentle
        )

        let path = CraftLearningPath(sections: [section1, section2], winding: .gentle)
        XCTAssertEqual(path.activeNodeID, "u2_n1")
        XCTAssertFalse(path.isEmpty)
    }

    func testLearningPathBackwardCompatibleRowPatternInitializers() {
        let node = LessonNodeModel(id: "n_compat", title: "Compat", state: .active)
        let section = LessonSection(id: "sec_compat", title: "Compat Section", nodes: [node])

        var tapped: LessonNodeModel?
        var started: LessonNodeModel?

        // Multi-section rowPattern init
        let multiPath = CraftLearningPath(
            sections: [section],
            rowPattern: .wave,
            onNodeTap: { tapped = $0 },
            onStartLesson: { started = $0 },
            showDetailModal: true,
            scrollToActive: false,
            showCelebration: false
        )
        XCTAssertEqual(multiPath.rowPattern, .wave)
        XCTAssertEqual(multiPath.winding, .standard)
        XCTAssertFalse(multiPath.scrollToActive)
        XCTAssertFalse(multiPath.showCelebration)
        XCTAssertTrue(multiPath.showDetailModal)

        multiPath.onNodeTap?(node)
        XCTAssertEqual(tapped?.id, "n_compat")

        multiPath.onStartLesson?(node)
        XCTAssertEqual(started?.id, "n_compat")

        // Single section rowPattern init
        let singlePath = CraftLearningPath(
            section: section,
            rowPattern: .custom([2, 1]),
            showDetailModal: false
        )
        XCTAssertEqual(singlePath.sections.count, 1)
        XCTAssertEqual(singlePath.rowPattern, .custom([2, 1]))
        XCTAssertFalse(singlePath.showDetailModal)
    }

    func testLearningPathBodyRenderingAndEmptyState() {
        // Populated path body
        let node = LessonNodeModel(
            id: "pop_node",
            title: "Food & Drinks",
            subtitle: "10 words",
            state: .active,
            kind: .checkpoint,
            xpReward: 50
        )
        let section = LessonSection(
            id: "pop_sec",
            title: "Unit 3: Gastronomy",
            level: "B1",
            progressText: "2/5",
            nodes: [node],
            winding: .standard
        )
        let populatedPath = CraftLearningPath(
            section: section,
            winding: .standard,
            onNodeTap: { _ in },
            onStartLesson: { _ in },
            showDetailModal: true,
            scrollToActive: true,
            showCelebration: true
        )
        XCTAssertNotNil(populatedPath.body)

        // Empty path body
        let emptyPath = CraftLearningPath(sections: [])
        XCTAssertTrue(emptyPath.isEmpty)
        XCTAssertNotNil(emptyPath.body)
    }

    // MARK: - Catalog Winding and Showcase Tests

    func testCatalogWindingPresetCasesAndProperties() {
        XCTAssertEqual(CatalogWindingPreset.allCases.count, 3)
        XCTAssertEqual(CatalogWindingPreset.allCases, [.standard, .gentle, .linear])
        XCTAssertEqual(CatalogWindingPreset.standard.rawValue, "Standard")
        XCTAssertEqual(CatalogWindingPreset.gentle.rawValue, "Gentle")
        XCTAssertEqual(CatalogWindingPreset.linear.rawValue, "Linear")
        XCTAssertEqual(CatalogWindingPreset.standard.winding, .standard)
        XCTAssertEqual(CatalogWindingPreset.gentle.winding, .gentle)
        XCTAssertEqual(CatalogWindingPreset.linear.winding, .linear)
    }

    func testCatalogLearningPathMockDataVietnameseCurriculum() {
        let sections = CatalogLearningPathMockData.defaultSections
        XCTAssertEqual(sections.count, 2)

        // Section 1
        let sec1 = sections[0]
        XCTAssertEqual(sec1.id, "sec_1")
        XCTAssertEqual(sec1.title, "Unit 1: Khởi đầu (Foundations)")
        XCTAssertEqual(sec1.level, "BEGINNER • LEVEL 1")
        XCTAssertEqual(sec1.bannerIcon, "sparkles")
        XCTAssertEqual(sec1.progressValue, 0.5)
        XCTAssertEqual(sec1.nodes.count, 6)

        // Section 1 Nodes
        let s1n1 = sec1.nodes[0]
        XCTAssertEqual(s1n1.id, "u1_n1")
        XCTAssertEqual(s1n1.title, "Chào hỏi & Làm quen")
        XCTAssertEqual(s1n1.iconName, "hand.wave.fill")
        XCTAssertEqual(s1n1.state, .completed)
        XCTAssertEqual(s1n1.kind, .standard)
        XCTAssertEqual(s1n1.subtitle, "10 từ mới • 3m")
        XCTAssertEqual(s1n1.xpReward, 15)
        XCTAssertEqual(s1n1.stars, 3)

        let s1n2 = sec1.nodes[1]
        XCTAssertEqual(s1n2.id, "u1_n2")
        XCTAssertEqual(s1n2.title, "Bảng chữ cái & Phát âm")
        XCTAssertEqual(s1n2.iconName, "textformat")
        XCTAssertEqual(s1n2.state, .completed)
        XCTAssertEqual(s1n2.kind, .standard)
        XCTAssertEqual(s1n2.subtitle, "12 ký tự • 4m")
        XCTAssertEqual(s1n2.xpReward, 20)
        XCTAssertEqual(s1n2.stars, 3)

        let s1n3 = sec1.nodes[2]
        XCTAssertEqual(s1n3.id, "u1_n3")
        XCTAssertEqual(s1n3.title, "Số đếm & Thời gian")
        XCTAssertEqual(s1n3.iconName, "number")
        XCTAssertEqual(s1n3.state, .active)
        XCTAssertEqual(s1n3.kind, .standard)
        XCTAssertEqual(s1n3.progress, 0.6)
        XCTAssertEqual(s1n3.subtitle, "15 từ vựng • 5m")
        XCTAssertEqual(s1n3.xpReward, 25)
        XCTAssertEqual(s1n3.badgeCount, 2)

        let s1n4 = sec1.nodes[3]
        XCTAssertEqual(s1n4.id, "u1_n4")
        XCTAssertEqual(s1n4.title, "Từ vựng Đồ ăn & Đồ uống")
        XCTAssertEqual(s1n4.iconName, "fork.knife")
        XCTAssertEqual(s1n4.state, .upcoming)
        XCTAssertEqual(s1n4.kind, .standard)
        XCTAssertEqual(s1n4.subtitle, "18 từ vựng • 5m")
        XCTAssertEqual(s1n4.xpReward, 25)

        let s1n5 = sec1.nodes[4]
        XCTAssertEqual(s1n5.id, "u1_n5")
        XCTAssertEqual(s1n5.title, "Thử thách Ngữ pháp Checkpoint")
        XCTAssertEqual(s1n5.iconName, "crown.fill")
        XCTAssertEqual(s1n5.state, .bonus)
        XCTAssertEqual(s1n5.kind, .checkpoint)
        XCTAssertEqual(s1n5.subtitle, "Bài kiểm tra nhanh")
        XCTAssertEqual(s1n5.xpReward, 50)
        XCTAssertEqual(s1n5.badgeText, "HOT")

        let s1n6 = sec1.nodes[5]
        XCTAssertEqual(s1n6.id, "u1_n6")
        XCTAssertEqual(s1n6.title, "Rương Báu Hoàn Thành Chặng 1")
        XCTAssertEqual(s1n6.iconName, "gift.fill")
        XCTAssertEqual(s1n6.state, .bonus)
        XCTAssertEqual(s1n6.kind, .treasureChest)
        XCTAssertEqual(s1n6.subtitle, "Mở khóa phần thưởng")
        XCTAssertEqual(s1n6.xpReward, 100)

        // Section 2
        let sec2 = sections[1]
        XCTAssertEqual(sec2.id, "sec_2")
        XCTAssertEqual(sec2.title, "Unit 2: Giao tiếp Hàng ngày (Daily Conversations)")
        XCTAssertEqual(sec2.level, "INTERMEDIATE • LEVEL 2")
        XCTAssertEqual(sec2.bannerIcon, "bubble.left.and.bubble.right.fill")
        XCTAssertEqual(sec2.progressValue, 0.0)
        XCTAssertEqual(sec2.nodes.count, 4)

        // Section 2 Nodes
        let s2n1 = sec2.nodes[0]
        XCTAssertEqual(s2n1.id, "u2_n1")
        XCTAssertEqual(s2n1.title, "Hỏi đường & Di chuyển")
        XCTAssertEqual(s2n1.iconName, "map.fill")
        XCTAssertEqual(s2n1.state, .locked)
        XCTAssertEqual(s2n1.kind, .standard)
        XCTAssertEqual(s2n1.subtitle, "15 từ mới • 5m")
        XCTAssertEqual(s2n1.xpReward, 30)

        let s2n2 = sec2.nodes[1]
        XCTAssertEqual(s2n2.id, "u2_n2")
        XCTAssertEqual(s2n2.title, "Mua sắm & Giá cả")
        XCTAssertEqual(s2n2.iconName, "cart.fill")
        XCTAssertEqual(s2n2.state, .locked)
        XCTAssertEqual(s2n2.kind, .standard)
        XCTAssertEqual(s2n2.subtitle, "20 từ mới • 6m")
        XCTAssertEqual(s2n2.xpReward, 30)

        let s2n3 = sec2.nodes[2]
        XCTAssertEqual(s2n3.id, "u2_n3")
        XCTAssertEqual(s2n3.title, "Khách sạn & Du lịch")
        XCTAssertEqual(s2n3.iconName, "bed.double.fill")
        XCTAssertEqual(s2n3.state, .locked)
        XCTAssertEqual(s2n3.kind, .standard)
        XCTAssertEqual(s2n3.subtitle, "18 từ mới • 5m")
        XCTAssertEqual(s2n3.xpReward, 35)

        let s2n4 = sec2.nodes[3]
        XCTAssertEqual(s2n4.id, "u2_n4")
        XCTAssertEqual(s2n4.title, "Rương Báu Hoàn Thành Chặng 2")
        XCTAssertEqual(s2n4.iconName, "gift.fill")
        XCTAssertEqual(s2n4.state, .bonus)
        XCTAssertEqual(s2n4.kind, .treasureChest)
        XCTAssertEqual(s2n4.subtitle, "Mở khóa phần thưởng")
        XCTAssertEqual(s2n4.xpReward, 150)
    }

    func testActiveNodeWithWarmRadiantHaloRendering() {
        let activeStandard = LessonNodeModel(
            id: "act_std",
            title: "Common Verbs",
            subtitle: "20 words • 5 min",
            iconName: "flame.fill",
            state: .active,
            kind: .standard,
            progress: 0.6,
            xpReward: 30,
            badgeCount: 2
        )
        let nodeView = CraftLessonNode(model: activeStandard, calloutText: "TIẾP TỤC")
        XCTAssertNotNil(nodeView.body)
        XCTAssertEqual(nodeView.calloutText, "TIẾP TỤC")
        XCTAssertEqual(nodeView.model.state, .active)

        let activeCheckpoint = LessonNodeModel(
            id: "act_cp",
            title: "Unit Exam",
            iconName: "crown.fill",
            state: .active,
            kind: .checkpoint,
            progress: 0.8,
            xpReward: 100
        )
        let checkpointNodeView = CraftLessonNode(model: activeCheckpoint)
        XCTAssertNotNil(checkpointNodeView.body)
    }

    func testBreathingConnectorViewWithGradient() {
        let from = CGPoint(x: 100, y: 150)
        let to = CGPoint(x: 180, y: 300)
        let breathing = BreathingConnectorView(from: from, to: to)
        XCTAssertNotNil(breathing.body)

        let customBreathing = BreathingConnectorView(from: from, to: to, color: .orange)
        XCTAssertNotNil(customBreathing.body)
    }

    func testCraftCatalogViewInstantiation() {
        let catalog = CraftCatalogView()
        XCTAssertNotNil(catalog.body)
    }

    // MARK: - Task 3: Hairpin Arcs Geometry & Snake Dotted Path Renderer Tests

    func testSnakePathSegmentTypeCases() {
        let horizontal = SnakePathSegmentType.horizontal
        let rightHairpin = SnakePathSegmentType.rightHairpin
        let leftHairpin = SnakePathSegmentType.leftHairpin

        XCTAssertEqual(horizontal.rawValue, "horizontal")
        XCTAssertEqual(rightHairpin.rawValue, "rightHairpin")
        XCTAssertEqual(leftHairpin.rawValue, "leftHairpin")
        XCTAssertEqual(horizontal, .horizontal)
        XCTAssertEqual(rightHairpin, .rightHairpin)
        XCTAssertEqual(leftHairpin, .leftHairpin)
        XCTAssertNotEqual(horizontal, rightHairpin)
        XCTAssertNotEqual(rightHairpin, leftHairpin)
    }

    func testSnakePathGeometrySegmentCalculations() {
        let p1 = CGPoint(x: 280, y: 100) // Right node
        let p2 = CGPoint(x: 100, y: 100) // Left node
        let horizontalSeg = SnakePathGeometry.createSegment(
            from: p1,
            to: p2,
            containerWidth: 380,
            turnRadius: 32,
            edgeInset: 28
        )
        XCTAssertEqual(horizontalSeg.type, .horizontal)
        XCTAssertEqual(horizontalSeg.from, p1)
        XCTAssertEqual(horizontalSeg.to, p2)
        XCTAssertEqual(horizontalSeg.turnRadius, 32)
        XCTAssertEqual(horizontalSeg.turnX, 280)

        // Near horizontal (dy < 15)
        let pNear1 = CGPoint(x: 100, y: 100)
        let pNear2 = CGPoint(x: 280, y: 110)
        let nearHorizontalSeg = SnakePathGeometry.createSegment(
            from: pNear1,
            to: pNear2,
            containerWidth: 380,
            turnRadius: 32,
            edgeInset: 28
        )
        XCTAssertEqual(nearHorizontalSeg.type, .horizontal)

        // Right hairpin: from Center to Right
        let pCenter = CGPoint(x: 190, y: 50)
        let pRight = CGPoint(x: 280, y: 150)
        let rightHairpinSeg = SnakePathGeometry.createSegment(
            from: pCenter,
            to: pRight,
            containerWidth: 380,
            turnRadius: 32,
            edgeInset: 28
        )
        XCTAssertEqual(rightHairpinSeg.type, .rightHairpin)
        XCTAssertEqual(rightHairpinSeg.turnX, 352) // 380 - 28

        // Left hairpin: from Left node down to Center
        let pLeft = CGPoint(x: 100, y: 50)
        let pCenterBelow = CGPoint(x: 190, y: 150)
        let leftHairpinFromLeft = SnakePathGeometry.createSegment(
            from: pLeft,
            to: pCenterBelow,
            containerWidth: 380,
            turnRadius: 32,
            edgeInset: 28
        )
        XCTAssertEqual(leftHairpinFromLeft.type, .leftHairpin)
        XCTAssertEqual(leftHairpinFromLeft.turnX, 28) // edgeInset

        // Left hairpin: from Center to Left (going down)
        let pLeftBelow = CGPoint(x: 100, y: 150)
        let pCenterToLeft = SnakePathGeometry.createSegment(
            from: pCenter,
            to: pLeftBelow,
            containerWidth: 380,
            turnRadius: 32,
            edgeInset: 28
        )
        XCTAssertEqual(pCenterToLeft.type, .leftHairpin)
        XCTAssertEqual(pCenterToLeft.turnX, 28)

        // Right hairpin: from Right node down to Center
        let pFromRight = CGPoint(x: 280, y: 100)
        let pToCenter = CGPoint(x: 190, y: 200)
        let rightHairpinFromRight = SnakePathGeometry.createSegment(
            from: pFromRight,
            to: pToCenter,
            containerWidth: 380,
            turnRadius: 32,
            edgeInset: 28
        )
        XCTAssertEqual(rightHairpinFromRight.type, .rightHairpin)
        XCTAssertEqual(rightHairpinFromRight.turnX, 352) // 380 - 28
    }

    func testSnakePathDrawingProducesNonEmptyPath() {
        let seg = SnakePathSegmentGeometry(
            from: CGPoint(x: 190, y: 50),
            to: CGPoint(x: 280, y: 150),
            type: .rightHairpin,
            turnRadius: 32,
            turnX: 352
        )
        let path = seg.buildPath()
        XCTAssertFalse(path.isEmpty)
        XCTAssertEqual(path.boundingRect.minX, 190, accuracy: 1.0)
        XCTAssertEqual(path.boundingRect.maxX, 352, accuracy: 1.0)
        XCTAssertEqual(path.boundingRect.minY, 50, accuracy: 1.0)
        XCTAssertEqual(path.boundingRect.maxY, 150, accuracy: 1.0)

        // Horizontal buildPath
        let hSeg = SnakePathSegmentGeometry(
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 280, y: 100),
            type: .horizontal,
            turnRadius: 32,
            turnX: 100
        )
        let hPath = hSeg.buildPath()
        XCTAssertFalse(hPath.isEmpty)
        XCTAssertEqual(hPath.boundingRect.minX, 100, accuracy: 1.0)
        XCTAssertEqual(hPath.boundingRect.maxX, 280, accuracy: 1.0)

        // Left Hairpin buildPath
        let lSeg = SnakePathSegmentGeometry(
            from: CGPoint(x: 280, y: 100),
            to: CGPoint(x: 190, y: 200),
            type: .leftHairpin,
            turnRadius: 32,
            turnX: 28
        )
        let lPath = lSeg.buildPath()
        XCTAssertFalse(lPath.isEmpty)
        XCTAssertEqual(lPath.boundingRect.minX, 28, accuracy: 1.0)
        XCTAssertEqual(lPath.boundingRect.maxX, 280, accuracy: 1.0)

        // Small turn radius clamped to min 4
        let smallRadiusSeg = SnakePathSegmentGeometry(
            from: CGPoint(x: 100, y: 50),
            to: CGPoint(x: 200, y: 150),
            type: .rightHairpin,
            turnRadius: 1.0,
            turnX: 250
        )
        let smallPath = smallRadiusSeg.buildPath()
        XCTAssertFalse(smallPath.isEmpty)
    }

    func testSnakePathSegmentGeometryEquatability() {
        let seg1 = SnakePathSegmentGeometry(
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 200, y: 200),
            type: .rightHairpin,
            turnRadius: 32,
            turnX: 300
        )
        let seg2 = SnakePathSegmentGeometry(
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 200, y: 200),
            type: .rightHairpin,
            turnRadius: 32,
            turnX: 300
        )
        let seg3 = SnakePathSegmentGeometry(
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 200, y: 200),
            type: .leftHairpin,
            turnRadius: 32,
            turnX: 28
        )

        XCTAssertEqual(seg1, seg2)
        XCTAssertNotEqual(seg1, seg3)
    }

    func testCraftSnakeDottedSegmentViewInstantiation() {
        let seg = SnakePathSegmentGeometry(
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 200, y: 200),
            type: .rightHairpin,
            turnRadius: 32,
            turnX: 300
        )

        let viewCompleted = CraftSnakeDottedSegmentView(
            segment: seg,
            fromState: .completed,
            toState: .completed
        )
        XCTAssertNotNil(viewCompleted.body)

        let viewActive = CraftSnakeDottedSegmentView(
            segment: seg,
            fromState: .completed,
            toState: .active
        )
        XCTAssertNotNil(viewActive.body)

        let viewUpcoming = CraftSnakeDottedSegmentView(
            segment: seg,
            fromState: .active,
            toState: .upcoming
        )
        XCTAssertNotNil(viewUpcoming.body)

        let viewLocked = CraftSnakeDottedSegmentView(
            segment: seg,
            fromState: .upcoming,
            toState: .locked
        )
        XCTAssertNotNil(viewLocked.body)

        let customView = CraftSnakeDottedSegmentView(
            segment: seg,
            fromState: .locked,
            toState: .locked,
            dotDiameter: 6.0,
            dotSpacing: 8.0,
            customColor: .purple
        )
        XCTAssertNotNil(customView.body)
        XCTAssertEqual(customView.dotDiameter, 6.0)
        XCTAssertEqual(customView.dotSpacing, 8.0)
        XCTAssertEqual(customView.customColor, .purple)
    }

    func testCraftSnakeConnectorLayerWithNodes() {
        let node1 = LessonNodeModel(id: "n1", title: "1", state: .completed)
        let node2 = LessonNodeModel(id: "n2", title: "2", state: .active)
        let node3 = LessonNodeModel(id: "n3", title: "3", state: .upcoming)

        let layer = GeometryReader { geo in
            CraftSnakeConnectorLayer(
                nodes: [node1, node2, node3],
                preferences: [:],
                geometry: geo,
                turnRadius: 32,
                edgeInset: 28,
                dotDiameter: 5,
                dotSpacing: 7
            )
        }
        XCTAssertNotNil(layer)

        let singleNodeLayer = GeometryReader { geo in
            CraftSnakeConnectorLayer(
                nodes: [node1],
                preferences: [:],
                geometry: geo
            )
        }
        XCTAssertNotNil(singleNodeLayer)
    }

    // MARK: - Task 4: CraftLessonRow Snake Grid & Node Aesthetics Tests

    func testCraftLessonRowSnakeRowLayoutSingleNode() {
        let node = LessonNodeModel(id: "snake_n1", title: "Center Lesson", iconName: "star.fill", state: .active)
        let pNode = PositionedLessonNode(node: node, slot: .center, traversalIndex: 0)
        let layout = SnakeRowLayout(id: "row_single", rowIndex: 0, nodes: [pNode])

        var tapped: LessonNodeModel?
        let row = CraftLessonRow(rowLayout: layout) { selected in
            tapped = selected
        }

        XCTAssertNotNil(row)
        XCTAssertEqual(row.rowLayout?.id, "row_single")
        XCTAssertEqual(row.nodes.count, 1)
        XCTAssertEqual(row.nodes.first?.id, "snake_n1")
        XCTAssertEqual(row.node.id, "snake_n1")
        XCTAssertEqual(row.arrangement, .single)
        XCTAssertNotNil(row.body)

        row.onNodeTap?(node)
        XCTAssertEqual(tapped?.id, "snake_n1")
    }

    func testCraftLessonRowSnakeRowLayoutPairNodes() {
        let nodeL = LessonNodeModel(id: "snake_left", title: "Left Lesson", state: .completed)
        let nodeR = LessonNodeModel(id: "snake_right", title: "Right Lesson", state: .upcoming)
        let pNodeL = PositionedLessonNode(node: nodeL, slot: .left, traversalIndex: 2)
        let pNodeR = PositionedLessonNode(node: nodeR, slot: .right, traversalIndex: 1)
        let layout = SnakeRowLayout(id: "row_pair", rowIndex: 1, nodes: [pNodeL, pNodeR])

        let row = CraftLessonRow(rowLayout: layout)

        XCTAssertNotNil(row)
        XCTAssertEqual(row.rowLayout?.id, "row_pair")
        XCTAssertEqual(row.nodes.count, 2)
        XCTAssertEqual(row.nodes[0].id, "snake_left")
        XCTAssertEqual(row.nodes[1].id, "snake_right")
        XCTAssertEqual(row.arrangement, .pair)
        XCTAssertNotNil(row.body)
    }

    func testCraftLessonRowSnakeRowLayoutTripleNodes() {
        let nodeL = LessonNodeModel(id: "trip_l", title: "Left", state: .completed)
        let nodeC = LessonNodeModel(id: "trip_c", title: "Center", state: .active)
        let nodeR = LessonNodeModel(id: "trip_r", title: "Right", state: .upcoming)
        let pNodeL = PositionedLessonNode(node: nodeL, slot: .left, traversalIndex: 3)
        let pNodeC = PositionedLessonNode(node: nodeC, slot: .center, traversalIndex: 4)
        let pNodeR = PositionedLessonNode(node: nodeR, slot: .right, traversalIndex: 5)
        let layout = SnakeRowLayout(id: "row_triple", rowIndex: 2, nodes: [pNodeL, pNodeC, pNodeR])

        let row = CraftLessonRow(rowLayout: layout)

        XCTAssertNotNil(row)
        XCTAssertEqual(row.rowLayout?.id, "row_triple")
        XCTAssertEqual(row.nodes.count, 3)
        XCTAssertEqual(row.arrangement, .triple)
        XCTAssertNotNil(row.body)
    }

    func testCraftLessonRowSnakeRowLayoutEquatability() {
        let node1 = LessonNodeModel(id: "eq_1", title: "Eq 1")
        let pNode1 = PositionedLessonNode(node: node1, slot: .center, traversalIndex: 0)
        let layout1 = SnakeRowLayout(id: "row_0", rowIndex: 0, nodes: [pNode1])
        let layout1Copy = SnakeRowLayout(id: "row_0", rowIndex: 0, nodes: [pNode1])

        let node2 = LessonNodeModel(id: "eq_2", title: "Eq 2")
        let pNode2 = PositionedLessonNode(node: node2, slot: .left, traversalIndex: 1)
        let layout2 = SnakeRowLayout(id: "row_1", rowIndex: 1, nodes: [pNode2])

        let row1 = CraftLessonRow(rowLayout: layout1)
        let row1Copy = CraftLessonRow(rowLayout: layout1Copy)
        let row2 = CraftLessonRow(rowLayout: layout2)
        let rowLegacy = CraftLessonRow(node: node1, offsetRatio: 0.0)

        XCTAssertEqual(row1, row1Copy)
        XCTAssertNotEqual(row1, row2)
        XCTAssertNotEqual(row1, rowLegacy)
    }

    func testCraftLessonNodeAestheticsAndLabelStack() {
        let fullNode = LessonNodeModel(
            id: "aesthetic_node",
            title: "Advanced Grammar",
            subtitle: "10 bài học • 3 phút",
            iconName: "crown.fill",
            state: .active,
            kind: .checkpoint,
            progress: 0.8,
            xpReward: 50,
            estimatedMinutes: 3,
            stars: 3,
            badgeCount: 2,
            badgeText: "HOT"
        )

        var didTap = false
        let nodeView = CraftLessonNode(
            model: fullNode,
            calloutText: "TIẾP TỤC",
            onTap: { didTap = true }
        )

        XCTAssertNotNil(nodeView)
        XCTAssertNotNil(nodeView.body)
        XCTAssertEqual(nodeView.model.id, "aesthetic_node")
        XCTAssertEqual(nodeView.calloutText, "TIẾP TỤC")
        XCTAssertEqual(nodeView.nodeDiameter, 64)
        XCTAssertEqual(nodeView.iconSize, 26)
        XCTAssertEqual(nodeView.metadataText, "10 bài học • 3 phút")
        XCTAssertEqual(nodeView.accessibilityTraits, .isButton)
        XCTAssertTrue(nodeView.accessibilityLabelText.contains("Advanced Grammar"))
        XCTAssertTrue(nodeView.accessibilityLabelText.contains("50 XP"))
        XCTAssertEqual(nodeView.accessibilityHintText, "Double tap to continue")

        nodeView.onTap?()
        XCTAssertTrue(didTap)
    }

    func testCraftLessonNodeAccessibilityTraitsAndLabelsAllStates() {
        let completed = CraftLessonNode(model: LessonNodeModel(id: "c", title: "Done", state: .completed, stars: 2))
        XCTAssertEqual(completed.accessibilityTraits, .isButton)
        XCTAssertEqual(completed.accessibilityHintText, "Double tap to review")
        XCTAssertTrue(completed.accessibilityLabelText.contains("Done, Completed"))

        let active = CraftLessonNode(model: LessonNodeModel(id: "a", title: "Current", state: .active, progress: 0.5))
        XCTAssertEqual(active.accessibilityTraits, .isButton)
        XCTAssertEqual(active.accessibilityHintText, "Double tap to continue")
        XCTAssertTrue(active.accessibilityLabelText.contains("Current lesson. 50% complete"))

        let locked = CraftLessonNode(model: LessonNodeModel(id: "l", title: "Locked", state: .locked))
        XCTAssertEqual(locked.accessibilityTraits, .notEnabled)
        XCTAssertEqual(locked.accessibilityHintText, "Complete previous lessons to unlock")
        XCTAssertTrue(locked.accessibilityLabelText.contains("Locked"))

        let bonus = CraftLessonNode(model: LessonNodeModel(id: "b", title: "Bonus", state: .bonus, xpReward: 100))
        XCTAssertEqual(bonus.accessibilityTraits, .isButton)
        XCTAssertEqual(bonus.accessibilityHintText, "Double tap to start")
        XCTAssertTrue(bonus.accessibilityLabelText.contains("Bonus Lesson: Bonus. Reward: 100 XP"))
    }

    func testCraftLessonNodeEmitsAnchorPreferenceOnTactileButtonAtom() {
        let node = LessonNodeModel(
            id: "node_anchor_test",
            title: "Long Title With Multiple Lines of Text",
            subtitle: "10 words • 5 min",
            iconName: "star.fill",
            state: .completed,
            stars: 3
        )
        let nodeView = CraftLessonNode(model: node)
        XCTAssertNotNil(nodeView.body)
        XCTAssertEqual(nodeView.model.id, "node_anchor_test")
    }

    // MARK: - Task 5: Full Snake Hybrid Engine Integration Tests

    func testLessonSectionWithRowPattern() {
        let node = LessonNodeModel(id: "n1", title: "Test", state: .completed)
        let defaultSection = LessonSection(id: "s_default", title: "Default", nodes: [node])
        XCTAssertEqual(defaultSection.rowPattern, .standard)

        let waveSection = LessonSection(
            id: "s_wave",
            title: "Wave Section",
            nodes: [node],
            rowPattern: .wave
        )
        XCTAssertEqual(waveSection.rowPattern, .wave)

        let customSection = LessonSection(
            id: "s_custom",
            title: "Custom Section",
            nodes: [node],
            rowPattern: .custom([2, 1])
        )
        XCTAssertEqual(customSection.rowPattern, .custom([2, 1]))
    }

    func testCraftLessonSectionViewSnakeHybridRowLayoutPartitioning() {
        let nodes = (1...6).map {
            LessonNodeModel(id: "node_\($0)", title: "Lesson \($0)", state: $0 <= 2 ? .completed : ($0 == 3 ? .active : .upcoming))
        }
        let section = LessonSection(
            id: "sec_snake",
            title: "Snake Unit",
            nodes: nodes,
            rowPattern: .standard
        )

        var tappedNode: LessonNodeModel?
        let sectionView = CraftLessonSectionView(section: section) { tapped in
            tappedNode = tapped
        }

        XCTAssertNotNil(sectionView)
        XCTAssertEqual(sectionView.section.id, "sec_snake")
        XCTAssertEqual(sectionView.rowPattern, .standard)

        // Partition with standard pattern [1, 2] -> 4 rows for 6 nodes
        let layouts = sectionView.rowPattern.layoutRows(nodes: section.nodes)
        XCTAssertEqual(layouts.count, 4)

        // Row 0: 1 node (center)
        XCTAssertEqual(layouts[0].nodes.count, 1)
        XCTAssertEqual(layouts[0].nodes[0].node.id, "node_1")
        XCTAssertEqual(layouts[0].nodes[0].slot, NodeSlot.center)
        XCTAssertEqual(layouts[0].nodes[0].traversalIndex, 0)

        // Row 1: 2 nodes (left, right)
        XCTAssertEqual(layouts[1].nodes.count, 2)
        XCTAssertEqual(layouts[1].nodes[0].node.id, "node_3")
        XCTAssertEqual(layouts[1].nodes[0].slot, NodeSlot.left)
        XCTAssertEqual(layouts[1].nodes[0].traversalIndex, 2)
        XCTAssertEqual(layouts[1].nodes[1].node.id, "node_2")
        XCTAssertEqual(layouts[1].nodes[1].slot, NodeSlot.right)
        XCTAssertEqual(layouts[1].nodes[1].traversalIndex, 1)

        // Row 2: 1 node (center)
        XCTAssertEqual(layouts[2].nodes.count, 1)
        XCTAssertEqual(layouts[2].nodes[0].node.id, "node_4")
        XCTAssertEqual(layouts[2].nodes[0].slot, NodeSlot.center)
        XCTAssertEqual(layouts[2].nodes[0].traversalIndex, 3)

        // Row 3: 2 nodes (left, right)
        XCTAssertEqual(layouts[3].nodes.count, 2)
        XCTAssertEqual(layouts[3].nodes[0].node.id, "node_6")
        XCTAssertEqual(layouts[3].nodes[0].slot, NodeSlot.left)
        XCTAssertEqual(layouts[3].nodes[0].traversalIndex, 5)
        XCTAssertEqual(layouts[3].nodes[1].node.id, "node_5")
        XCTAssertEqual(layouts[3].nodes[1].slot, NodeSlot.right)
        XCTAssertEqual(layouts[3].nodes[1].traversalIndex, 4)

        // Test tap handling
        sectionView.onNodeTap?(nodes[2])
        XCTAssertEqual(tappedNode?.id, "node_3")

        // View body rendering
        XCTAssertNotNil(sectionView.body)
    }

    func testCraftLessonSectionViewWaveRowLayoutPartitioning() {
        let nodes = (1...8).map {
            LessonNodeModel(id: "w_node_\($0)", title: "Wave \($0)", state: .upcoming)
        }
        let section = LessonSection(
            id: "sec_wave_snake",
            title: "Wave Snake Unit",
            nodes: nodes,
            rowPattern: .wave
        )

        let sectionView = CraftLessonSectionView(section: section, rowPattern: .wave)
        XCTAssertEqual(sectionView.rowPattern, RowPattern.wave)

        // Wave pattern [1, 2, 3, 2] -> 4 rows for 8 nodes
        let layouts = sectionView.rowPattern.layoutRows(nodes: section.nodes)
        XCTAssertEqual(layouts.count, 4)

        // Row 0: 1 node (center)
        XCTAssertEqual(layouts[0].nodes.count, 1)
        XCTAssertEqual(layouts[0].nodes[0].slot, NodeSlot.center)
        XCTAssertEqual(layouts[0].nodes[0].traversalIndex, 0)

        // Row 1: 2 nodes (left, right)
        XCTAssertEqual(layouts[1].nodes.count, 2)
        XCTAssertEqual(layouts[1].nodes[0].slot, NodeSlot.left)
        XCTAssertEqual(layouts[1].nodes[1].slot, NodeSlot.right)

        // Row 2: 3 nodes (left, center, right)
        XCTAssertEqual(layouts[2].nodes.count, 3)
        XCTAssertEqual(layouts[2].nodes[0].slot, NodeSlot.left)
        XCTAssertEqual(layouts[2].nodes[1].slot, NodeSlot.center)
        XCTAssertEqual(layouts[2].nodes[2].slot, NodeSlot.right)

        // Row 3: 2 nodes (left, right)
        XCTAssertEqual(layouts[3].nodes.count, 2)
        XCTAssertEqual(layouts[3].nodes[0].slot, NodeSlot.left)
        XCTAssertEqual(layouts[3].nodes[1].slot, NodeSlot.right)
    }

    func testCraftLearningPathSnakeHybridIntegrationMultiSection() {
        let sec1Nodes = [
            LessonNodeModel(id: "s1_n1", title: "S1 N1", state: .completed),
            LessonNodeModel(id: "s1_n2", title: "S1 N2", state: .completed),
            LessonNodeModel(id: "s1_n3", title: "S1 N3", state: .active, progress: 0.5)
        ]
        let sec2Nodes = [
            LessonNodeModel(id: "s2_n1", title: "S2 N1", state: .locked),
            LessonNodeModel(id: "s2_n2", title: "S2 N2", state: .locked),
            LessonNodeModel(id: "s2_n3", title: "S2 N3", state: .locked, kind: .treasureChest)
        ]

        let section1 = LessonSection(
            id: "sec_1",
            title: "Section 1",
            nodes: sec1Nodes,
            rowPattern: .standard
        )
        let section2 = LessonSection(
            id: "sec_2",
            title: "Section 2",
            nodes: sec2Nodes,
            rowPattern: .wave
        )

        var tapped: LessonNodeModel?
        var started: LessonNodeModel?
        let path = CraftLearningPath(
            sections: [section1, section2],
            onNodeTap: { tapped = $0 },
            onStartLesson: { started = $0 },
            showDetailModal: true,
            scrollToActive: true,
            showCelebration: true
        )

        XCTAssertFalse(path.isEmpty)
        XCTAssertEqual(path.sections.count, 2)
        XCTAssertEqual(path.activeNodeID, "s1_n3")
        XCTAssertTrue(path.scrollToActive)
        XCTAssertTrue(path.showCelebration)
        XCTAssertTrue(path.showDetailModal)

        path.onNodeTap?(sec1Nodes[2])
        XCTAssertEqual(tapped?.id, "s1_n3")

        path.onStartLesson?(sec1Nodes[2])
        XCTAssertEqual(started?.id, "s1_n3")

        XCTAssertNotNil(path.body)
    }

    func testCraftLearningPathActiveNodeResolutionAcrossSections() {
        let allCompletedSection = LessonSection(
            id: "s_done",
            title: "Done",
            nodes: [
                LessonNodeModel(id: "d1", title: "D1", state: .completed),
                LessonNodeModel(id: "d2", title: "D2", state: .completed)
            ]
        )
        let activeSection = LessonSection(
            id: "s_act",
            title: "Active",
            nodes: [
                LessonNodeModel(id: "a1", title: "A1", state: .active)
            ]
        )
        let lockedSection = LessonSection(
            id: "s_lock",
            title: "Locked",
            nodes: [
                LessonNodeModel(id: "l1", title: "L1", state: .locked)
            ]
        )

        let path1 = CraftLearningPath(sections: [allCompletedSection, activeSection, lockedSection])
        XCTAssertEqual(path1.activeNodeID, "a1")

        let path2 = CraftLearningPath(sections: [allCompletedSection, lockedSection])
        XCTAssertNil(path2.activeNodeID)

        let path3 = CraftLearningPath(sections: [])
        XCTAssertNil(path3.activeNodeID)
        XCTAssertTrue(path3.isEmpty)
    }

    func testCraftCatalogMockDataSnakeHybridIntegrity() {
        let sections = CatalogLearningPathMockData.defaultSections
        XCTAssertEqual(sections.count, 2)

        let sec1 = sections[0]
        XCTAssertEqual(sec1.id, "sec_1")
        XCTAssertEqual(sec1.nodes.count, 6)
        XCTAssertEqual(sec1.nodes.filter { $0.state == .completed }.count, 2)
        XCTAssertEqual(sec1.nodes.filter { $0.state == .active }.count, 1)
        XCTAssertEqual(sec1.nodes.filter { $0.state == .upcoming }.count, 1)
        XCTAssertEqual(sec1.nodes.filter { $0.state == .bonus }.count, 2)
        XCTAssertEqual(sec1.nodes.filter { $0.kind == .checkpoint }.count, 1)
        XCTAssertEqual(sec1.nodes.filter { $0.kind == .treasureChest }.count, 1)

        let sec2 = sections[1]
        XCTAssertEqual(sec2.id, "sec_2")
        XCTAssertEqual(sec2.nodes.count, 4)
        XCTAssertEqual(sec2.nodes.filter { $0.state == .locked }.count, 3)
        XCTAssertEqual(sec2.nodes.filter { $0.kind == .treasureChest }.count, 1)

        // Verify layout partitioning
        let sec1Layouts = sec1.rowPattern.layoutRows(nodes: sec1.nodes)
        XCTAssertEqual(sec1Layouts.count, 4) // [1], [2], [1], [2]
    }

    // MARK: - Task 3: 3D Tactile Lesson Nodes & Star Rating Tests

    func testCraftLessonNode3DPedestalAndStarRatingRendering() {
        // Test 1, 2, 3 stars on completed nodes
        for stars in 1...3 {
            let model = LessonNodeModel(
                id: "star_node_\(stars)",
                title: "Lesson \(stars)",
                subtitle: "\(stars) stars earned",
                state: .completed,
                stars: stars
            )
            let node = CraftLessonNode(model: model)
            XCTAssertNotNil(node.body)
            XCTAssertEqual(node.model.stars, stars)
            XCTAssertEqual(node.nodeDiameter, 52)
            XCTAssertEqual(node.accessibilityTraits, .isButton)
            XCTAssertEqual(node.accessibilityHintText, "Double tap to review")
        }

        // Test completed node with 0 / nil stars
        let noStarModel = LessonNodeModel(
            id: "no_star_node",
            title: "Lesson No Star",
            state: .completed,
            stars: nil
        )
        let noStarNode = CraftLessonNode(model: noStarModel)
        XCTAssertNil(noStarNode.model.stars)
        XCTAssertNotNil(noStarNode.body)
    }

    func testCraftLessonNodeStateTransitionsAndKindVariations() {
        let states: [LessonNodeState] = [.completed, .active, .inProgress, .upcoming, .locked, .bonus]
        let kinds: [LessonNodeKind] = [.standard, .checkpoint, .treasureChest]

        for kind in kinds {
            for state in states {
                let model = LessonNodeModel(
                    id: "node_\(kind.rawValue)_\(state.rawValue)",
                    title: "\(kind.rawValue) \(state.rawValue)",
                    state: state,
                    kind: kind,
                    progress: state == .inProgress || state == .active ? 0.42 : nil,
                    xpReward: 30
                )
                let node = CraftLessonNode(model: model)
                XCTAssertNotNil(node.body)
                XCTAssertEqual(node.model.kind, kind)
                XCTAssertEqual(node.model.state, state)
                XCTAssertFalse(node.accessibilityLabelText.isEmpty)

                if state == .locked {
                    XCTAssertEqual(node.accessibilityTraits, .notEnabled)
                    XCTAssertEqual(node.accessibilityHintText, "Complete previous lessons to unlock")
                } else {
                    XCTAssertEqual(node.accessibilityTraits, .isButton)
                }
            }
        }
    }


    // MARK: - Task 6: Generic Journey Path Primitives Tests

    func testCraftNodeStateAllCasesAndProperties() {
        XCTAssertEqual(CraftNodeState.allCases.count, 6)
        XCTAssertEqual(CraftNodeState.allCases, [.completed, .active, .inProgress, .upcoming, .locked, .bonus])
        XCTAssertEqual(CraftNodeState.completed.rawValue, "completed")
        XCTAssertEqual(CraftNodeState.active.rawValue, "active")
        XCTAssertEqual(CraftNodeState.inProgress.rawValue, "inProgress")
        XCTAssertEqual(CraftNodeState.upcoming.rawValue, "upcoming")
        XCTAssertEqual(CraftNodeState.locked.rawValue, "locked")
        XCTAssertEqual(CraftNodeState.bonus.rawValue, "bonus")
    }

    func testCraftNodeShapeAllCasesAndRawValues() {
        XCTAssertEqual(CraftNodeShape.allCases.count, 5)
        XCTAssertEqual(CraftNodeShape.allCases, [.circle, .hexagon, .diamond, .squircle, .star])
        XCTAssertEqual(CraftNodeShape.circle.rawValue, "circle")
        XCTAssertEqual(CraftNodeShape.hexagon.rawValue, "hexagon")
        XCTAssertEqual(CraftNodeShape.diamond.rawValue, "diamond")
        XCTAssertEqual(CraftNodeShape.squircle.rawValue, "squircle")
        XCTAssertEqual(CraftNodeShape.star.rawValue, "star")
    }

    func testCraftNodeIconInitAndStringLiteral() {
        let systemIcon: CraftNodeIcon = "star.fill"
        XCTAssertEqual(systemIcon.name, "star.fill")
        XCTAssertTrue(systemIcon.isSystem)

        let customAssetIcon = CraftNodeIcon.asset("custom_shield")
        XCTAssertEqual(customAssetIcon.name, "custom_shield")
        XCTAssertFalse(customAssetIcon.isSystem)

        let explicitSystemIcon = CraftNodeIcon.system("flame.fill")
        XCTAssertEqual(explicitSystemIcon.name, "flame.fill")
        XCTAssertTrue(explicitSystemIcon.isSystem)

        XCTAssertEqual(systemIcon, CraftNodeIcon(name: "star.fill", isSystem: true))
        XCTAssertNotEqual(systemIcon, customAssetIcon)
    }

    func testStarShapeAndSquircleShapePathGeneration() {
        let star = StarShape()
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let starPath = star.path(in: rect)
        XCTAssertFalse(starPath.isEmpty)

        let insetStar = star.inset(by: 4)
        let insetStarPath = insetStar.path(in: rect)
        XCTAssertFalse(insetStarPath.isEmpty)

        let squircle = SquircleShape(cornerRadius: 16)
        let squirclePath = squircle.path(in: rect)
        XCTAssertFalse(squirclePath.isEmpty)

        let insetSquircle = squircle.inset(by: 2)
        let insetSquirclePath = insetSquircle.path(in: rect)
        XCTAssertFalse(insetSquirclePath.isEmpty)
    }

    func testCraftPathNodeModelInitDefaultsAndPayload() {
        let defaultNode = CraftPathNodeModel(
            id: "path_node_1",
            title: "Journey Step 1"
        )
        XCTAssertEqual(defaultNode.id, "path_node_1")
        XCTAssertEqual(defaultNode.title, "Journey Step 1")
        XCTAssertNil(defaultNode.titleKey)
        XCTAssertNil(defaultNode.subtitle)
        XCTAssertNil(defaultNode.subtitleKey)
        XCTAssertEqual(defaultNode.state, .upcoming)
        XCTAssertEqual(defaultNode.shape, .circle)
        XCTAssertEqual(defaultNode.surfaceStyle, .tactile3D)
        XCTAssertEqual(defaultNode.icon.name, "book.fill")
        XCTAssertTrue(defaultNode.icon.isSystem)
        XCTAssertNil(defaultNode.progress)
        XCTAssertNil(defaultNode.badgeText)
        XCTAssertNil(defaultNode.badgeCount)
        XCTAssertNil(defaultNode.stars)
        XCTAssertNil(defaultNode.metricText)

        struct CustomQuestData: Sendable, Equatable, Hashable {
            let questType: String
            let rewardXP: Int
        }

        let customNode = CraftPathNodeModel(
            id: "quest_1",
            title: "Dragon Quest",
            titleKey: "quest.dragon.title",
            subtitle: "Defeat the guardian",
            subtitleKey: "quest.dragon.sub",
            state: .active,
            shape: .star,
            surfaceStyle: .glass,
            icon: .system("crown.fill"),
            progress: 0.5,
            badgeText: "EPIC",
            badgeCount: 1,
            stars: 3,
            metricText: "500 XP",
            customPayload: CustomQuestData(questType: "Boss", rewardXP: 500)
        )

        XCTAssertEqual(customNode.shape, .star)
        XCTAssertEqual(customNode.surfaceStyle, .glass)
        XCTAssertEqual(customNode.customPayload?.questType, "Boss")
        XCTAssertEqual(customNode.customPayload?.rewardXP, 500)
        XCTAssertEqual(customNode.metricText, "500 XP")
    }

    func testCraftPathNodeModelEquatableAndHashable() {
        let node1 = CraftPathNodeModel(
            id: "node_1",
            title: "Step 1",
            state: .active,
            shape: .hexagon,
            surfaceStyle: .elevated,
            icon: "star.fill"
        )
        let node2 = CraftPathNodeModel(
            id: "node_1",
            title: "Step 1",
            state: .active,
            shape: .hexagon,
            surfaceStyle: .elevated,
            icon: "star.fill"
        )
        let node3 = CraftPathNodeModel(
            id: "node_2",
            title: "Step 2",
            state: .locked,
            shape: .diamond,
            surfaceStyle: .flat,
            icon: "lock.fill"
        )

        XCTAssertEqual(node1, node2)
        XCTAssertNotEqual(node1, node3)

        let set: Set<CraftPathNodeModel<CraftEmptyPayload>> = [node1, node2, node3]
        XCTAssertEqual(set.count, 2)
    }

    func testCraftJourneySectionInitAndEquatable() {
        let node = CraftPathNodeModel(id: "n1", title: "Node 1", state: .completed)
        let section = CraftJourneySection(
            id: "journey_sec_1",
            title: "Chapter 1",
            subtitle: "The Beginning",
            levelText: "CH 1",
            progressText: "1/5",
            progressValue: 0.2,
            bannerIcon: "flag.fill",
            nodes: [node],
            winding: .gentle,
            connectorStyle: .solid,
            rowPattern: .standard
        )

        XCTAssertEqual(section.id, "journey_sec_1")
        XCTAssertEqual(section.title, "Chapter 1")
        XCTAssertEqual(section.subtitle, "The Beginning")
        XCTAssertEqual(section.levelText, "CH 1")
        XCTAssertEqual(section.progressText, "1/5")
        XCTAssertEqual(section.progressValue, 0.2)
        XCTAssertEqual(section.bannerIcon?.name, "flag.fill")
        XCTAssertEqual(section.nodes.count, 1)
        XCTAssertEqual(section.winding, .gentle)
        XCTAssertEqual(section.connectorStyle, .solid)
        XCTAssertEqual(section.rowPattern, .standard)
    }

    func testJourneyRowLayoutAndPositionedJourneyNode() {
        let node = CraftPathNodeModel(id: "p_1", title: "Positioned", state: .active)
        let pNode = PositionedJourneyNode(node: node, slot: .center, traversalIndex: 0)

        XCTAssertEqual(pNode.id, "p_1")
        XCTAssertEqual(pNode.slot, .center)
        XCTAssertEqual(pNode.traversalIndex, 0)
        XCTAssertEqual(pNode.node, node)

        let rowLayout = JourneyRowLayout(id: "j_row_0", rowIndex: 0, nodes: [pNode])
        XCTAssertEqual(rowLayout.id, "j_row_0")
        XCTAssertEqual(rowLayout.rowIndex, 0)
        XCTAssertEqual(rowLayout.nodes.count, 1)
        XCTAssertEqual(rowLayout.nodes.first, pNode)
    }

    func testRowPatternLayoutJourneyRows() {
        let nodes: [CraftPathNodeModel<CraftEmptyPayload>] = (0..<7).map {
            CraftPathNodeModel(id: "jn_\($0)", title: "Step \($0)", state: .upcoming)
        }

        let layouts = RowPattern.standard.layoutJourneyRows(nodes: nodes)
        XCTAssertEqual(layouts.count, 5) // [1], [2], [1], [2], [1]
        XCTAssertEqual(layouts[0].nodes.count, 1)
        XCTAssertEqual(layouts[0].nodes[0].slot, .center)
        XCTAssertEqual(layouts[1].nodes.count, 2)
        XCTAssertEqual(layouts[1].nodes[0].slot, .left)
        XCTAssertEqual(layouts[1].nodes[1].slot, .right)

        let waveLayouts = RowPattern.wave.layoutJourneyRows(nodes: (0..<6).map {
            CraftPathNodeModel(id: "wn_\($0)", title: "Wave \($0)")
        })
        XCTAssertEqual(waveLayouts.map { $0.nodes.count }, [1, 2, 3])
        XCTAssertEqual(waveLayouts[2].nodes.map(\.slot), [.left, .center, .right])
    }

    func testCraftPathNodeAllShapesAndSurfaceStylesRendering() {
        for shape in CraftNodeShape.allCases {
            for surface in CraftSurfaceStyle.allCases {
                for state in CraftNodeState.allCases {
                    let model = CraftPathNodeModel(
                        id: "test_\(shape.rawValue)_\(surface.rawValue)_\(state.rawValue)",
                        title: "Test Node",
                        subtitle: "Subtitle",
                        state: state,
                        shape: shape,
                        surfaceStyle: surface,
                        icon: "star.fill",
                        progress: state == .inProgress ? 0.5 : nil,
                        badgeText: "HOT",
                        badgeCount: 2,
                        stars: state == .completed ? 3 : nil,
                        metricText: "+50 XP"
                    )
                    let node = CraftPathNode(model: model) { _ in }
                    XCTAssertNotNil(node.body)
                    XCTAssertEqual(node.model.shape, shape)
                    XCTAssertEqual(node.model.surfaceStyle, surface)
                    XCTAssertEqual(node.model.state, state)
                }
            }
        }
    }

    func testCraftPathNodeAccessibilityAndDimensions() {
        let completed = CraftPathNode(model: CraftPathNodeModel(id: "c", title: "C", state: .completed))
        let active = CraftPathNode(model: CraftPathNodeModel(id: "a", title: "A", state: .active, progress: 0.7))
        let inProgress = CraftPathNode(model: CraftPathNodeModel(id: "p", title: "P", state: .inProgress, progress: 0.3))
        let upcoming = CraftPathNode(model: CraftPathNodeModel(id: "u", title: "U", state: .upcoming))
        let locked = CraftPathNode(model: CraftPathNodeModel(id: "l", title: "L", state: .locked))
        let bonus = CraftPathNode(model: CraftPathNodeModel(id: "b", title: "B", state: .bonus, metricText: "+100 XP"))

        XCTAssertEqual(completed.nodeDiameter, 52)
        XCTAssertEqual(active.nodeDiameter, 64)
        XCTAssertEqual(inProgress.nodeDiameter, 56)
        XCTAssertEqual(upcoming.nodeDiameter, 48)
        XCTAssertEqual(locked.nodeDiameter, 48)
        XCTAssertEqual(bonus.nodeDiameter, 56)

        XCTAssertTrue(completed.accessibilityTraits.contains(.isButton))
        XCTAssertFalse(locked.accessibilityTraits.contains(.isButton))
        XCTAssertEqual(completed.accessibilityHintText, "Double tap to review")
        XCTAssertEqual(active.accessibilityHintText, "Double tap to continue")
        XCTAssertEqual(locked.accessibilityHintText, "Complete previous lessons to unlock")

        XCTAssertTrue(active.accessibilityLabelText.contains("70% complete"))
        XCTAssertTrue(bonus.accessibilityLabelText.contains("+100 XP"))
    }

    func testCraftJourneySectionViewRendering() {
        let nodes = (0..<5).map {
            CraftPathNodeModel(id: "n_\($0)", title: "Step \($0)", state: $0 == 0 ? .completed : ($0 == 1 ? .active : .upcoming))
        }
        let section = CraftJourneySection(
            id: "j_sec_1",
            title: "Foundation Section",
            subtitle: "Complete all steps",
            levelText: "STAGE 1",
            progressText: "1/5",
            progressValue: 0.2,
            bannerIcon: "sparkles",
            nodes: nodes
        )

        var tappedNodeId: String?
        let sectionView = CraftJourneySectionView(section: section) { tapped in
            tappedNodeId = tapped.id
        }

        XCTAssertNotNil(sectionView.body)
        XCTAssertEqual(sectionView.section.id, "j_sec_1")
        XCTAssertEqual(sectionView.section.nodes.count, 5)
        XCTAssertNil(tappedNodeId)
    }

    func testLessonNodeModelAsPathNodeMapping() {
        let lesson = LessonNodeModel(
            id: "les_1",
            title: "Lesson Title",
            subtitle: "5 words • 2 min",
            iconName: "book.fill",
            state: .active,
            kind: .checkpoint,
            progress: 0.8,
            xpReward: 40,
            estimatedMinutes: 5,
            stars: 3,
            badgeCount: 2,
            badgeText: "HOT"
        )

        let pathNode = lesson.asPathNode
        XCTAssertEqual(pathNode.id, "les_1")
        XCTAssertEqual(pathNode.title, "Lesson Title")
        XCTAssertEqual(pathNode.subtitle, "5 words • 2 min")
        XCTAssertEqual(pathNode.state, .active)
        XCTAssertEqual(pathNode.shape, .hexagon)
        XCTAssertEqual(pathNode.surfaceStyle, .tactile3D)
        XCTAssertEqual(pathNode.icon.name, "book.fill")
        XCTAssertEqual(pathNode.progress, 0.8)
        XCTAssertEqual(pathNode.stars, 3)
        XCTAssertEqual(pathNode.badgeCount, 2)
        XCTAssertEqual(pathNode.badgeText, "HOT")
        XCTAssertEqual(pathNode.metricText, "Reward: 40 XP")
        XCTAssertEqual(pathNode.customPayload?.xpReward, 40)
        XCTAssertEqual(pathNode.customPayload?.estimatedMinutes, 5)
        XCTAssertEqual(pathNode.customPayload?.kind, .checkpoint)
    }

    func testLessonSectionAsJourneySectionMapping() {
        let lesson = LessonNodeModel(id: "l1", title: "L1", state: .completed)
        let section = LessonSection(
            id: "sec_map",
            title: "Unit Mapping",
            subtitle: "Test Subtitle",
            level: "LEVEL 3",
            progressText: "1/1",
            progressValue: 1.0,
            bannerIcon: "trophy.fill",
            nodes: [lesson]
        )

        let journeySection = section.asJourneySection
        XCTAssertEqual(journeySection.id, "sec_map")
        XCTAssertEqual(journeySection.title, "Unit Mapping")
        XCTAssertEqual(journeySection.subtitle, "Test Subtitle")
        XCTAssertEqual(journeySection.levelText, "LEVEL 3")
        XCTAssertEqual(journeySection.progressText, "1/1")
        XCTAssertEqual(journeySection.progressValue, 1.0)
        XCTAssertEqual(journeySection.bannerIcon?.name, "trophy.fill")
        XCTAssertEqual(journeySection.nodes.count, 1)
        XCTAssertEqual(journeySection.nodes[0].id, "l1")
    }

    // MARK: - Node Impression Telemetry Tests

    func testNodeImpressionInitializationAndThresholdDefaults() {
        let node = LessonNodeModel(id: "n_imp", title: "Impression Test")
        let expectation = XCTestExpectation(description: "Node impression triggered")

        let lessonNode = CraftLessonNode(
            model: node,
            onNodeImpression: { impressed in
                XCTAssertEqual(impressed.id, "n_imp")
                expectation.fulfill()
            },
            impressionThreshold: 0.1
        )
        XCTAssertEqual(lessonNode.impressionThreshold, 0.1)
        XCTAssertNotNil(lessonNode.onNodeImpression)

        // Test default threshold
        let defaultNode = CraftLessonNode(model: node)
        XCTAssertEqual(defaultNode.impressionThreshold, 0.5)
        XCTAssertNil(defaultNode.onNodeImpression)
    }

    func testCraftLessonRowImpressionForwarding() {
        let node = LessonNodeModel(id: "n_row_imp", title: "Row Impression")

        let row = CraftLessonRow(
            node: node,
            offsetRatio: 0.2,
            onNodeTap: nil,
            onNodeImpression: { _ in },
            impressionThreshold: 0.3
        )
        XCTAssertEqual(row.impressionThreshold, 0.3)
        XCTAssertNotNil(row.onNodeImpression)

        let defaultRow = CraftLessonRow(node: node)
        XCTAssertEqual(defaultRow.impressionThreshold, 0.5)
        XCTAssertNil(defaultRow.onNodeImpression)

        let snakeRow = CraftLessonRow(
            rowLayout: SnakeRowLayout(id: "row_1", rowIndex: 0, nodes: [PositionedLessonNode(node: node, slot: .center, traversalIndex: 0)]),
            onNodeTap: nil,
            onNodeImpression: { _ in },
            impressionThreshold: 0.25
        )
        XCTAssertEqual(snakeRow.impressionThreshold, 0.25)
        XCTAssertNotNil(snakeRow.onNodeImpression)

        let legacyRow = CraftLessonRow(
            nodes: [node],
            arrangement: .single,
            onNodeTap: nil,
            onNodeImpression: { _ in },
            impressionThreshold: 0.4
        )
        XCTAssertEqual(legacyRow.impressionThreshold, 0.4)
        XCTAssertNotNil(legacyRow.onNodeImpression)
    }

    func testCraftLessonSectionBodyAndSectionViewImpressionForwarding() {
        let node = LessonNodeModel(id: "n_sec_imp", title: "Sec Impression")
        let section = LessonSection(id: "sec_imp", title: "Section", nodes: [node])

        let bodyView = CraftLessonSectionBodyView(
            section: section,
            onNodeTap: nil,
            onNodeImpression: { _ in },
            impressionThreshold: 0.15
        )
        XCTAssertEqual(bodyView.impressionThreshold, 0.15)
        XCTAssertNotNil(bodyView.onNodeImpression)

        let defaultBodyView = CraftLessonSectionBodyView(section: section)
        XCTAssertEqual(defaultBodyView.impressionThreshold, 0.5)
        XCTAssertNil(defaultBodyView.onNodeImpression)

        let sectionView = CraftLessonSectionView(
            section: section,
            onNodeTap: nil,
            onNodeImpression: { _ in },
            impressionThreshold: 0.2
        )
        XCTAssertEqual(sectionView.impressionThreshold, 0.2)
        XCTAssertNotNil(sectionView.onNodeImpression)

        let defaultSectionView = CraftLessonSectionView(section: section)
        XCTAssertEqual(defaultSectionView.impressionThreshold, 0.5)
        XCTAssertNil(defaultSectionView.onNodeImpression)
    }

    func testCraftLearningPathImpressionInitializationAndDefaults() {
        let node = LessonNodeModel(id: "n_lp_imp", title: "LP Impression")
        let section = LessonSection(id: "sec_lp", title: "LP Section", nodes: [node])

        let path = CraftLearningPath(
            section: section,
            onNodeImpression: { _ in },
            nodeImpressionThreshold: 0.35
        )
        XCTAssertEqual(path.nodeImpressionThreshold, 0.35)
        XCTAssertNotNil(path.onNodeImpression)

        let defaultPath = CraftLearningPath(section: section)
        XCTAssertEqual(defaultPath.nodeImpressionThreshold, 0.5)
        XCTAssertNil(defaultPath.onNodeImpression)

        let multiSectionPath = CraftLearningPath(
            sections: [section],
            onNodeImpression: { _ in },
            nodeImpressionThreshold: 0.45
        )
        XCTAssertEqual(multiSectionPath.nodeImpressionThreshold, 0.45)
        XCTAssertNotNil(multiSectionPath.onNodeImpression)
    }

    // MARK: - Sticky HUD Builder Tests

    func testCraftLearningPathStickyHUDBuilderInitialization() {
        let section = LessonSection(
            id: "unit_hud",
            title: "Unit HUD",
            level: "LEVEL 1",
            progressText: "50%",
            progressValue: 0.5,
            nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
        )
        let path = CraftLearningPath(
            sections: [section],
            stickyHUD: { s in
                Text("Custom HUD: \(s.title)")
            }
        )
        XCTAssertNotNil(path.stickyHUDBuilder)
    }

    func testCraftLearningPathSingleSectionStickyHUDBuilderInitialization() {
        let section = LessonSection(
            id: "unit_single_hud",
            title: "Single Unit HUD",
            nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
        )
        let path = CraftLearningPath(
            section: section,
            stickyHUD: { s in
                Text("Single HUD: \(s.title)")
            }
        )
        XCTAssertNotNil(path.stickyHUDBuilder)
    }

    func testCraftLearningPathDefaultStickyHUDInitialization() {
        let section = LessonSection(
            id: "unit_default_hud",
            title: "Default Unit",
            nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
        )
        let path = CraftLearningPath(sections: [section])
        XCTAssertNil(path.stickyHUDBuilder)

        let singlePath = CraftLearningPath(section: section)
        XCTAssertNil(singlePath.stickyHUDBuilder)
    }

    func testCraftLessonSectionHeaderViewOnDockChangeCallback() {
        let section = LessonSection(
            id: "unit_dock",
            title: "Dock Unit",
            nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
        )
        var dockStatus: Bool?
        let headerView = CraftLessonSectionHeaderView(
            section: section,
            dockThreshold: 20,
            onDockChange: { isDocked in
                dockStatus = isDocked
            }
        )
        XCTAssertEqual(headerView.dockThreshold, 20)
        XCTAssertNotNil(headerView.onDockChange)
        headerView.onDockChange?(true)
        XCTAssertEqual(dockStatus, true)

        let defaultHeaderView = CraftLessonSectionHeaderView(section: section)
        XCTAssertEqual(defaultHeaderView.dockThreshold, 0)
        XCTAssertNil(defaultHeaderView.onDockChange)
        XCTAssertFalse(defaultHeaderView.isPinned)
    }

    func testCraftLessonSectionViewOnDockChangeForwarding() {
        let section = LessonSection(
            id: "unit_sec_dock",
            title: "Section Dock Unit",
            nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
        )
        let sectionView = CraftLessonSectionView(
            section: section,
            dockThreshold: 25,
            onDockChange: { _ in }
        )
        XCTAssertEqual(sectionView.dockThreshold, 25)
        XCTAssertNotNil(sectionView.onDockChange)

        let defaultSectionView = CraftLessonSectionView(section: section)
        XCTAssertEqual(defaultSectionView.dockThreshold, 0)
        XCTAssertNil(defaultSectionView.onDockChange)
    }

    func testCraftLessonSectionHeaderViewDockThresholdDefaultIsZero() {
        let section = LessonSection(
            id: "unit_dock_zero",
            title: "Dock Unit Zero",
            nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
        )
        let headerView = CraftLessonSectionHeaderView(section: section)
        XCTAssertEqual(headerView.dockThreshold, 0)
    }

    func testCraftLessonSectionViewDockThresholdDefaultIsZero() {
        let section = LessonSection(
            id: "unit_sec_zero",
            title: "Section Dock Zero",
            nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
        )
        let sectionView = CraftLessonSectionView(section: section)
        XCTAssertEqual(sectionView.dockThreshold, 0)
    }

    func testCraftLearningPathStickyHUDViewRendering() {
        let section = LessonSection(
            id: "unit_render_hud",
            title: "Render HUD Unit",
            level: "LEVEL 3",
            progressText: "4/5",
            progressValue: 0.8,
            bannerIcon: "star.fill",
            nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
        )
        let pathWithCustomHUD = CraftLearningPath(
            sections: [section],
            stickyHUD: { s in
                Text("Custom: \(s.title)")
            }
        )
        XCTAssertNotNil(pathWithCustomHUD.body)

        let pathWithDefaultHUD = CraftLearningPath(
            sections: [section]
        )
        XCTAssertNotNil(pathWithDefaultHUD.body)
    }

}



