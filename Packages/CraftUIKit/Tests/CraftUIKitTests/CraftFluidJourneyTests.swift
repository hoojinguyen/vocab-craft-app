@testable import CraftUIKit
import SwiftUI
import Testing

@Suite("CraftFluidJourney Tests")
struct CraftFluidJourneyTests {
    @Test("Verify container initialization with sections")
    func testContainerInit() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", level: "A2", nodes: [
                LessonNodeModel(id: "n-1", title: "Node 1", state: .completed),
                LessonNodeModel(id: "n-2", title: "Node 2", state: .active)
            ])
        ]
        let journey = CraftFluidJourney(sections: sections)
        #expect(journey.sections.count == 1)
        #expect(journey.sections.first?.nodes.count == 2)
    }

    @Test("Verify single-section convenience initialization")
    func testSingleSectionInit() {
        let section = LessonSection(
            id: "sec-single",
            title: "Basics",
            level: "A1",
            nodes: [
                LessonNodeModel(id: "n-single", title: "Greeting", state: .upcoming)
            ]
        )
        let journey = CraftFluidJourney(section: section)
        #expect(journey.sections.count == 1)
        #expect(journey.sections.first?.id == "sec-single")
        #expect(journey.sections.first?.nodes.count == 1)
    }

    @Test("Verify default configuration properties")
    func testDefaultConfiguration() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", nodes: [])
        ]
        let journey = CraftFluidJourney(sections: sections)
        #expect(journey.deckTitle == nil)
        #expect(journey.deckSubtitle == nil)
        #expect(journey.showDetailModal == true)
        #expect(journey.scrollToActive == true)
        #expect(journey.externalScrollTrigger == 0)
        #expect(journey.onNodeTap == nil)
        #expect(journey.onStartLesson == nil)
        #expect(journey.onTabBarPresentationChange == nil)
        #expect(journey.onSelectLesson == nil)
        #expect(journey.onAdjustPlan == nil)

        let customTriggerJourney = CraftFluidJourney(sections: sections, externalScrollTrigger: 42)
        #expect(customTriggerJourney.externalScrollTrigger == 42)
    }

    @Test("Verify empty state detection")
    func testEmptyStateDetection() {
        let emptySectionsJourney = CraftFluidJourney(sections: [])
        #expect(emptySectionsJourney.isEmpty == true)

        let sectionsWithNoNodesJourney = CraftFluidJourney(sections: [
            LessonSection(id: "sec-1", title: "Unit 1", nodes: []),
            LessonSection(id: "sec-2", title: "Unit 2", nodes: [])
        ])
        #expect(sectionsWithNoNodesJourney.isEmpty == true)

        let populatedJourney = CraftFluidJourney(sections: [
            LessonSection(id: "sec-1", title: "Unit 1", nodes: [
                LessonNodeModel(id: "n-1", title: "Node 1", state: .active)
            ])
        ])
        #expect(populatedJourney.isEmpty == false)
    }

    @Test("Verify active node identifier resolution")
    func testActiveNodeIDResolution() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", nodes: [
                LessonNodeModel(id: "n-1", title: "Node 1", state: .completed),
                LessonNodeModel(id: "n-2", title: "Node 2", state: .completed)
            ]),
            LessonSection(id: "sec-2", title: "Unit 2", nodes: [
                LessonNodeModel(id: "n-3", title: "Node 3", state: .active),
                LessonNodeModel(id: "n-4", title: "Node 4", state: .upcoming)
            ])
        ]
        let journey = CraftFluidJourney(sections: sections)
        #expect(journey.activeNodeID == "n-3")

        let noActiveSections = [
            LessonSection(id: "sec-1", title: "Unit 1", nodes: [
                LessonNodeModel(id: "n-1", title: "Node 1", state: .completed)
            ])
        ]
        let noActiveJourney = CraftFluidJourney(sections: noActiveSections)
        #expect(noActiveJourney.activeNodeID == nil)
    }

    @Test("Verify active and default section resolution")
    func testActiveAndDefaultSectionResolution() {
        let sec1 = LessonSection(id: "sec-1", title: "Unit 1", nodes: [
            LessonNodeModel(id: "n-1", title: "Node 1", state: .completed)
        ])
        let sec2 = LessonSection(id: "sec-2", title: "Unit 2", nodes: [
            LessonNodeModel(id: "n-2", title: "Node 2", state: .active)
        ])
        let sec3 = LessonSection(id: "sec-3", title: "Unit 3", nodes: [
            LessonNodeModel(id: "n-3", title: "Node 3", state: .upcoming)
        ])

        let journey = CraftFluidJourney(sections: [sec1, sec2, sec3])
        #expect(journey.activeSection?.id == "sec-2")
        #expect(journey.defaultSection?.id == "sec-2")

        let allCompletedSections = [sec1, sec1]
        let completedJourney = CraftFluidJourney(sections: allCompletedSections)
        #expect(completedJourney.activeSection == nil)
        #expect(completedJourney.defaultSection?.id == "sec-1")
    }

    @Test("Verify scroll coordinate space constant")
    func testCoordinateSpaceConstant() {
        #expect(CraftFluidJourney.scrollCoordinateSpaceName == "CraftFluidJourneyScrollCoordinateSpace")
    }

    @Test("Verify milestone docking resolution logic")
    func testMilestoneDockingResolution() {
        let sec1 = LessonSection(id: "sec-1", title: "Unit 1", nodes: [
            LessonNodeModel(id: "n-1", title: "Node 1", state: .completed)
        ])
        let sec2 = LessonSection(id: "sec-2", title: "Unit 2", nodes: [
            LessonNodeModel(id: "n-2", title: "Node 2", state: .active)
        ])
        let sec3 = LessonSection(id: "sec-3", title: "Unit 3", nodes: [
            LessonNodeModel(id: "n-3", title: "Node 3", state: .upcoming)
        ])
        let journey = CraftFluidJourney(sections: [sec1, sec2, sec3])

        // 1. Initial / empty positions -> falls back to default section (sec-2 because it's active)
        let initialDock = journey.resolveDockedSection(from: [:], threshold: 140)
        #expect(initialDock?.id == "sec-2")

        // 2. User scrolled to top, sec-1 pill is near top (minY = 100 <= 140), sec-2 is below (minY = 600)
        let topPositions: [String: CGFloat] = [
            "sec-1": 100,
            "sec-2": 600,
            "sec-3": 1200
        ]
        let topDock = journey.resolveDockedSection(from: topPositions, threshold: 140)
        #expect(topDock?.id == "sec-1")

        // 3. User scrolled down, sec-1 is off-screen (minY = -400), sec-2 reached threshold (minY = 120)
        let scrolledPositions: [String: CGFloat] = [
            "sec-1": -400,
            "sec-2": 120,
            "sec-3": 700
        ]
        let scrolledDock = journey.resolveDockedSection(from: scrolledPositions, threshold: 140)
        #expect(scrolledDock?.id == "sec-2")

        // 4. User scrolled further, sec-2 is off-screen (minY = -200), sec-3 reached threshold (minY = 90)
        let deepPositions: [String: CGFloat] = [
            "sec-1": -1000,
            "sec-2": -200,
            "sec-3": 90
        ]
        let deepDock = journey.resolveDockedSection(from: deepPositions, threshold: 140)
        #expect(deepDock?.id == "sec-3")

        // 5. User scrolled back up, sec-3 moved down (minY = 300), sec-2 is now visible (minY = 80)
        let reversePositions: [String: CGFloat] = [
            "sec-1": -600,
            "sec-2": 80,
            "sec-3": 300
        ]
        let reverseDock = journey.resolveDockedSection(from: reversePositions, threshold: 140)
        #expect(reverseDock?.id == "sec-2")
    }

    @Test("Verify node global indexing and offset calculations")
    func testNodeOffsets() {
        let sec1 = LessonSection(id: "sec-1", title: "Unit 1", nodes: [
            LessonNodeModel(id: "n-0", title: "Node 0"),
            LessonNodeModel(id: "n-1", title: "Node 1"),
            LessonNodeModel(id: "n-2", title: "Node 2")
        ])
        let sec2 = LessonSection(id: "sec-2", title: "Unit 2", nodes: [
            LessonNodeModel(id: "n-3", title: "Node 3"),
            LessonNodeModel(id: "n-4", title: "Node 4")
        ])
        let journey = CraftFluidJourney(sections: [sec1, sec2])

        let lookup = journey.nodeIndexLookup
        #expect(lookup["n-0"] == 0)
        #expect(lookup["n-1"] == 1)
        #expect(lookup["n-2"] == 2)
        #expect(lookup["n-3"] == 3)
        #expect(lookup["n-4"] == 4)

        #expect(journey.offset(for: "n-0") == 0)
        #expect(journey.offset(for: "n-1") == -48)
        #expect(journey.offset(for: "n-2") == 0)
        #expect(journey.offset(for: "n-3") == 48)
        #expect(journey.offset(for: "n-4") == 0)
    }

    @Test("Verify fluid journey node offset sequence starts at center")
    func testFluidJourneyNodeOffsetSequenceStartsAtCenter() {
        #expect(FluidJourneyNodeOffset.offset(for: 0) == 0.0)
        #expect(FluidJourneyNodeOffset.offset(for: 1) == -48.0)
        #expect(FluidJourneyNodeOffset.offset(for: 2) == 0.0)
        #expect(FluidJourneyNodeOffset.offset(for: 3) == 48.0)
        #expect(FluidJourneyNodeOffset.offset(for: 4) == 0.0)
    }

    @Test("Verify callbacks execution")
    func testCallbacks() {
        var tappedNode: LessonNodeModel?
        var startedNode: LessonNodeModel?
        var tabPresentation: CraftTabBarPresentation?
        var selectedSectionNode: (String, String)?
        var adjustPlanTapped = false

        let node = LessonNodeModel(id: "test-node", title: "Test")
        let section = LessonSection(id: "test-sec", title: "Unit", nodes: [node])

        let journey = CraftFluidJourney(
            sections: [section],
            onNodeTap: { node in tappedNode = node },
            onStartLesson: { node in startedNode = node },
            onTabBarPresentationChange: { presentation in tabPresentation = presentation },
            onSelectLesson: { secId, nId in selectedSectionNode = (secId, nId) },
            onAdjustPlan: { adjustPlanTapped = true }
        )

        journey.onNodeTap?(node)
        #expect(tappedNode?.id == "test-node")

        journey.onStartLesson?(node)
        #expect(startedNode?.id == "test-node")

        journey.onTabBarPresentationChange?(.compact)
        #expect(tabPresentation == .compact)

        journey.onSelectLesson?("test-sec", "test-node")
        #expect(selectedSectionNode?.0 == "test-sec")
        #expect(selectedSectionNode?.1 == "test-node")

        journey.onAdjustPlan?()
        #expect(adjustPlanTapped == true)
    }

    // MARK: - CraftJourneyNode Refinement Tests

    @Test("Verify CraftJourneyNode uniform sizing across states")
    func testCraftJourneyNodeUniformSizingAcrossStates() {
        let completed = CraftJourneyNode.diameter(for: .completed)
        let active = CraftJourneyNode.diameter(for: .active)
        let inProgress = CraftJourneyNode.diameter(for: .inProgress)
        let locked = CraftJourneyNode.diameter(for: .locked)
        let upcoming = CraftJourneyNode.diameter(for: .upcoming)

        #expect(completed == 88, "Completed node must be 88pt")
        #expect(active == 88, "Active node base diameter must be 88pt, matching other nodes")
        #expect(inProgress == 88, "InProgress node must be 88pt")
        #expect(locked == 88, "Locked node must be 88pt")
        #expect(upcoming == 88, "Upcoming node must be 88pt")
    }

    @Test("Verify CraftJourneyNode preserves lesson icon when locked")
    func testCraftJourneyNodePreservesLessonIconWhenLocked() {
        let node = LessonNodeModel(
            id: "lesson_1",
            title: "Vocabulary Basics",
            iconName: "bubble.left.and.bubble.right.fill",
            state: .locked
        )
        let journeyNode = CraftJourneyNode(node: node)
        #expect(journeyNode.displayedIconName == "bubble.left.and.bubble.right.fill", "Locked node must preserve original lesson icon instead of lock.fill")
    }

    @Test("Verify CraftJourneyNode surface style resolution")
    func testCraftJourneyNodeSurfaceStyleResolution() {
        let node = LessonNodeModel(id: "n1", title: "Test", iconName: "book.fill", state: .active)
        let explicitNode = CraftJourneyNode(node: node, surfaceStyle: .glass)
        #expect(explicitNode.surfaceStyle == .glass)
    }

    // MARK: - Milestone Pill & Docking Hierarchy Tests

    @Test("CraftMilestonePill initialization and surface styles")
    func testMilestonePillInitializationAndProperties() {
        let pill = CraftMilestonePill(sectionId: "s1", title: "Present Simple for Personal Facts")
        #expect(pill.sectionId == "s1")
        #expect(pill.title == "Present Simple for Personal Facts")
        #expect(pill.accessibilityLabelText == "Present Simple for Personal Facts")
        #expect(pill.surfaceStyle == nil)

        let explicitGlassPill = CraftMilestonePill(sectionId: "s2", title: "Reading Bios", surfaceStyle: .glass)
        #expect(explicitGlassPill.surfaceStyle == .glass)
    }

    @Test("CraftFluidJourney resolves deck and subtopic correctly")
    func testFluidJourneyDockingResolvesDeckAndSubtopic() {
        let section1 = LessonSection(id: "s1", title: "Present Simple", subtitle: "Basics", level: "A2", nodes: [])
        let section2 = LessonSection(id: "s2", title: "Reading Bios", subtitle: "Intermediate", level: "A2", nodes: [])
        let journey = CraftFluidJourney(sections: [section1, section2], deckTitle: "Personal Details Vocabulary")

        #expect(journey.resolvedDeckTitle == "Personal Details Vocabulary")
    }

    @Test("CraftFluidJourney pinnedHeaderSection includes deck and subtopic context")
    func testFluidJourneyPinnedHeaderSectionContext() {
        let section1 = LessonSection(id: "s1", title: "Present Simple", subtitle: "Basics", level: "A2", nodes: [])
        let journeyWithDeck = CraftFluidJourney(sections: [section1], deckTitle: "Personal Details Vocabulary")
        let headerSec = journeyWithDeck.headerSection(for: section1)

        #expect(headerSec.id == "s1")
        #expect(headerSec.title == "Personal Details Vocabulary")
        #expect(headerSec.subtitle == "Present Simple")
        #expect(headerSec.level == "A2")

        let journeyWithoutDeck = CraftFluidJourney(sections: [section1])
        let unchangedHeaderSec = journeyWithoutDeck.headerSection(for: section1)
        #expect(unchangedHeaderSec.title == "Present Simple")
        #expect(unchangedHeaderSec.subtitle == "Basics")
    }

    @Test("CraftFluidJourney surfaceStyle property propagation")
    func testFluidJourneySurfaceStylePropagation() {
        let section1 = LessonSection(id: "s1", title: "Present Simple", level: "A2", nodes: [
            LessonNodeModel(id: "n1", title: "Lesson 1", state: .active)
        ])
        let defaultJourney = CraftFluidJourney(sections: [section1])
        #expect(defaultJourney.surfaceStyle == nil)

        let explicitJourney = CraftFluidJourney(sections: [section1], surfaceStyle: .glass)
        #expect(explicitJourney.surfaceStyle == .glass)
    }

    @Test("CraftFluidJourney milestoneTitle resolves section deck title directly")
    func testMilestoneTitleResolution() {
        let journey = CraftFluidJourney(sections: [])

        let sec1 = LessonSection(
            id: "s1",
            title: "Giao Tiếp Hằng Ngày",
            subtitle: "Thói quen & Cảm xúc",
            nodes: [LessonNodeModel(id: "n1", title: "Bài 1")]
        )
        #expect(journey.milestoneTitle(for: sec1) == "Giao Tiếp Hằng Ngày")

        let sec2 = LessonSection(
            id: "s2",
            title: "Công Sở & Kinh Doanh",
            subtitle: nil,
            nodes: [LessonNodeModel(id: "n2", title: "Bài 1")]
        )
        #expect(journey.milestoneTitle(for: sec2) == "Công Sở & Kinh Doanh")
    }

    // MARK: - Active Callout Bubble Tests

    @Test("Verify ActiveCalloutBubble attached above active node with clearance")
    func testActiveCalloutBubbleAttachedToActiveNode() {
        let activeNode = LessonNodeModel(id: "n-active", title: "Active Lesson", state: .active)
        let lockedNode = LessonNodeModel(id: "n-locked", title: "Locked Lesson", state: .locked)
        let completedNode = LessonNodeModel(id: "n-comp", title: "Completed Lesson", state: .completed)
        let upcomingNode = LessonNodeModel(id: "n-upcoming", title: "Upcoming Lesson", state: .upcoming)
        let inProgressNode = LessonNodeModel(id: "n-in-progress", title: "In Progress Lesson", state: .inProgress)
        let bonusNode = LessonNodeModel(id: "n-bonus", title: "Bonus Lesson", state: .bonus)

        let section = LessonSection(
            id: "sec-active-test",
            title: "Unit 1",
            nodes: [activeNode, lockedNode, completedNode, upcomingNode, inProgressNode, bonusNode]
        )
        let journey = CraftFluidJourney(sections: [section])

        // Only active node should display the callout bubble
        #expect(journey.shouldShowCallout(for: activeNode) == true)
        #expect(journey.shouldShowCallout(for: lockedNode) == false)
        #expect(journey.shouldShowCallout(for: completedNode) == false)
        #expect(journey.shouldShowCallout(for: upcomingNode) == false)
        #expect(journey.shouldShowCallout(for: inProgressNode) == false)
        #expect(journey.shouldShowCallout(for: bonusNode) == false)

        // Callout text must use the localized string "craft.fluid_journey.start_lesson"
        let expectedEnglish = CraftLocalized.string("craft.fluid_journey.start_lesson")
        #expect(expectedEnglish == "START LESSON")
        #expect(journey.calloutText(for: activeNode) == expectedEnglish)

        let expectedVietnamese = CraftLocalized.string("craft.fluid_journey.start_lesson", language: "vi")
        #expect(expectedVietnamese == "BẮT ĐẦU HỌC")

        // ActiveCalloutBubble initialization
        let bubble = ActiveCalloutBubble(text: journey.calloutText(for: activeNode))
        #expect(bubble.text == "START LESSON")
    }

    // MARK: - Safe Sequential Lesson Launch Transition Tests

    @Test("Verify safe lesson launch transition invokes start lesson callback cleanly")
    func testSafeSequentialLessonLaunchAfterSheetDismissal() {
        var startedNodeId: String?
        let testNode = LessonNodeModel(id: "node-safe-launch", title: "Target Lesson", state: .active)
        let section = LessonSection(id: "sec-safe", title: "Safe Unit", nodes: [testNode])

        let journey = CraftFluidJourney(
            sections: [section],
            onStartLesson: { node in
                startedNodeId = node.id
            },
            detailSheetBuilder: { node, onStart, _ in
                // Simulating tapping start inside detail sheet
                onStart(node)
                return AnyView(EmptyView())
            }
        )

        #expect(journey.sections.count == 1)
        #expect(journey.onStartLesson != nil)
        journey.onStartLesson?(testNode)
        #expect(startedNodeId == "node-safe-launch")
    }
}

