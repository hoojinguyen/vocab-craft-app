@testable import CraftUIKit
import SwiftUI
import XCTest

final class CraftLessonDetailSheetTests: XCTestCase {
    // MARK: - Active Node Tests

    func testActiveNodeProperties() {
        let node = LessonNodeModel(
            id: "act_node",
            title: "Daily Greetings",
            subtitle: "10 words • 3 min",
            iconName: "hand.wave.fill",
            state: .active,
            kind: .standard,
            progress: 0.4,
            xpReward: 30,
            estimatedMinutes: 3
        )

        let sheet = CraftLessonDetailSheet(node: node)

        XCTAssertEqual(sheet.ctaTitle, "START LESSON")
        XCTAssertEqual(sheet.ctaVariant, .primary)
        XCTAssertFalse(sheet.isCtaDisabled)
        XCTAssertEqual(sheet.formattedXPReward, "+30 XP")
        XCTAssertEqual(sheet.formattedDuration, "3 min")
        XCTAssertEqual(sheet.formattedVocabularyCount, "10 words • 3 min")
        XCTAssertEqual(sheet.statusBadgeTitle, "Active")
        XCTAssertEqual(sheet.statusBadgeTone, .primary)
    }

    // MARK: - Locked Node Tests

    func testLockedNodeProperties() {
        let node = LessonNodeModel(
            id: "lock_node",
            title: "Advanced Grammar",
            iconName: "lock.fill",
            state: .locked,
            kind: .standard,
            xpReward: 50,
            estimatedMinutes: 8
        )

        let sheet = CraftLessonDetailSheet(node: node)

        XCTAssertEqual(sheet.ctaTitle, "LESSON LOCKED")
        XCTAssertEqual(sheet.ctaVariant, .secondary)
        XCTAssertTrue(sheet.isCtaDisabled)
        XCTAssertEqual(sheet.formattedXPReward, "+50 XP")
        XCTAssertEqual(sheet.formattedDuration, "8 min")
        XCTAssertEqual(sheet.statusBadgeTitle, "Locked")
        XCTAssertEqual(sheet.statusBadgeTone, .neutral)
    }

    // MARK: - Progression States CTA Tests

    func testInProgressNodeCTAWithAndWithoutProgress() {
        let progressNode = LessonNodeModel(
            id: "prog_node",
            title: "Common Verbs",
            state: .inProgress,
            progress: 0.65
        )
        let progressSheet = CraftLessonDetailSheet(node: progressNode)
        XCTAssertEqual(progressSheet.ctaTitle, "CONTINUE (65%)")
        XCTAssertEqual(progressSheet.ctaVariant, .primary)
        XCTAssertFalse(progressSheet.isCtaDisabled)
        XCTAssertEqual(progressSheet.statusBadgeTone, .primary)

        let nilProgressNode = LessonNodeModel(
            id: "nil_prog_node",
            title: "Common Verbs",
            state: .inProgress,
            progress: nil
        )
        let nilProgressSheet = CraftLessonDetailSheet(node: nilProgressNode)
        XCTAssertEqual(nilProgressSheet.ctaTitle, "CONTINUE (0%)")
        XCTAssertEqual(nilProgressSheet.ctaVariant, .primary)
        XCTAssertFalse(nilProgressSheet.isCtaDisabled)
    }

    func testCompletedNodeCTAAndStars() {
        let node = LessonNodeModel(
            id: "comp_node",
            title: "Basic Alphabet",
            state: .completed,
            xpReward: 25,
            stars: 3
        )
        let sheet = CraftLessonDetailSheet(node: node)

        XCTAssertEqual(sheet.ctaTitle, "REVIEW (+25 XP)")
        XCTAssertEqual(sheet.ctaVariant, .secondary)
        XCTAssertFalse(sheet.isCtaDisabled)
        XCTAssertEqual(sheet.statusBadgeTitle, "Completed")
        XCTAssertEqual(sheet.statusBadgeTone, .success)
        XCTAssertEqual(sheet.node.stars, 3)
    }

    func testBonusNodeCTA() {
        let node = LessonNodeModel(
            id: "bon_node",
            title: "Boss Exam",
            state: .bonus,
            kind: .checkpoint,
            xpReward: 100
        )
        let sheet = CraftLessonDetailSheet(node: node)

        XCTAssertEqual(sheet.ctaTitle, "CONQUER CHALLENGE")
        XCTAssertEqual(sheet.ctaVariant, .primary)
        XCTAssertFalse(sheet.isCtaDisabled)
        XCTAssertEqual(sheet.statusBadgeTitle, "Bonus")
        XCTAssertEqual(sheet.statusBadgeTone, .warning)
    }

    func testUpcomingNodeCTA() {
        let node = LessonNodeModel(
            id: "up_node",
            title: "Food & Drinks",
            state: .upcoming
        )
        let sheet = CraftLessonDetailSheet(node: node)

        XCTAssertEqual(sheet.ctaTitle, "START LESSON")
        XCTAssertEqual(sheet.ctaVariant, .primary)
        XCTAssertFalse(sheet.isCtaDisabled)
        XCTAssertEqual(sheet.statusBadgeTitle, "Upcoming")
        XCTAssertEqual(sheet.statusBadgeTone, .neutral)
    }

    // MARK: - Metric Fallback Tests

    func testMetricDefaultsAndFallbacks() {
        let defaultNode = LessonNodeModel(
            id: "def_node",
            title: "Minimal Node",
            state: .active
        )
        let sheet = CraftLessonDetailSheet(node: defaultNode)

        XCTAssertEqual(sheet.formattedXPReward, "+20 XP")
        XCTAssertEqual(sheet.formattedDuration, "5 min")
        XCTAssertEqual(sheet.formattedVocabularyCount, "15 new words")
    }

    // MARK: - Callback Tests

    func testActionCallbacks() {
        var startCalledWith: LessonNodeModel?
        var dismissCalled = false

        let node = LessonNodeModel(
            id: "cb_node",
            title: "Callback Node",
            state: .active
        )

        let sheet = CraftLessonDetailSheet(
            node: node,
            onStart: { started in startCalledWith = started },
            onDismiss: { dismissCalled = true }
        )

        sheet.onStart?(node)
        XCTAssertEqual(startCalledWith?.id, "cb_node")

        sheet.onDismiss?()
        XCTAssertTrue(dismissCalled)
    }

    // MARK: - Kinds & Body Rendering Tests

    func testKindVariantsBodyRendering() {
        let checkpointNode = LessonNodeModel(
            id: "cp_node",
            title: "Checkpoint Unit 1",
            iconName: "crown.fill",
            state: .active,
            kind: .checkpoint
        )
        let cpSheet = CraftLessonDetailSheet(node: checkpointNode)
        XCTAssertNotNil(cpSheet.body)

        let treasureNode = LessonNodeModel(
            id: "tc_node",
            title: "Treasure Chest",
            iconName: "gift.fill",
            state: .completed,
            kind: .treasureChest,
            stars: 3
        )
        let tcSheet = CraftLessonDetailSheet(node: treasureNode)
        XCTAssertNotNil(tcSheet.body)
    }

    func testBodyRenderingForAllStates() {
        for state in LessonNodeState.allCases {
            let node = LessonNodeModel(
                id: "render_\(state.rawValue)",
                title: "Render Test \(state.rawValue)",
                subtitle: "Subtitle for \(state.rawValue)",
                iconName: "star.fill",
                state: state,
                progress: 0.5,
                xpReward: 40,
                estimatedMinutes: 6,
                stars: state == .completed ? 3 : nil,
                objectives: ["Objective 1", "Objective 2"]
            )
            let sheet = CraftLessonDetailSheet(node: node)
            XCTAssertNotNil(sheet.body)
        }
    }
}
