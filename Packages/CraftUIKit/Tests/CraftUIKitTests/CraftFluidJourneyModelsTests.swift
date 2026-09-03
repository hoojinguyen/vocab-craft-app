@testable import CraftUIKit
import SwiftUI
import Testing

@Suite("CraftFluidJourneyModels Tests")
struct CraftFluidJourneyModelsTests {
    @Test("Test FluidJourneyMilestonePreferenceKey reduction")
    func testPreferenceKeyReduction() {
        var current: [String: CGFloat] = ["section1": 150.0]
        FluidJourneyMilestonePreferenceKey.reduce(value: &current) {
            ["section2": 320.0]
        }
        #expect(current["section1"] == 150.0)
        #expect(current["section2"] == 320.0)

        // Test overwrite reduction with latest value
        FluidJourneyMilestonePreferenceKey.reduce(value: &current) {
            ["section1": 175.0]
        }
        #expect(current["section1"] == 175.0)
        #expect(current["section2"] == 320.0)
    }

    @Test("Test FluidJourneyMilestonePreferenceKey default value")
    func testPreferenceKeyDefaultValue() {
        #expect(FluidJourneyMilestonePreferenceKey.defaultValue.isEmpty)
    }

    @Test("Test FluidJourneyNodeOffset sequence")
    func testNodeOffsetSequence() {
        #expect(FluidJourneyNodeOffset.offset(for: 0) == -45)
        #expect(FluidJourneyNodeOffset.offset(for: 1) == 0)
        #expect(FluidJourneyNodeOffset.offset(for: 2) == 45)
        #expect(FluidJourneyNodeOffset.offset(for: 3) == 0)
        #expect(FluidJourneyNodeOffset.offset(for: 4) == -45)
        #expect(FluidJourneyNodeOffset.offset(for: 5) == 0)
        #expect(FluidJourneyNodeOffset.offset(for: 6) == 45)
        #expect(FluidJourneyNodeOffset.offset(for: 7) == 0)

        // Negative index clamped to 0
        #expect(FluidJourneyNodeOffset.offset(for: -1) == -45)
        #expect(FluidJourneyNodeOffset.offset(for: -10) == -45)
    }

    @Test("Test FluidJourneySectionState enum and inference")
    func testSectionState() {
        #expect(FluidJourneySectionState.completed.rawValue == "completed")
        #expect(FluidJourneySectionState.current.rawValue == "current")
        #expect(FluidJourneySectionState.upcoming.rawValue == "upcoming")

        let completedSection = LessonSection(
            id: "s1",
            title: "Unit 1",
            nodes: [
                LessonNodeModel(id: "n1", title: "L1", state: .completed),
                LessonNodeModel(id: "n2", title: "L2", state: .completed)
            ]
        )
        #expect(FluidJourneySectionState.state(for: completedSection) == .completed)

        let activeSection = LessonSection(
            id: "s2",
            title: "Unit 2",
            nodes: [
                LessonNodeModel(id: "n3", title: "L3", state: .completed),
                LessonNodeModel(id: "n4", title: "L4", state: .active)
            ]
        )
        #expect(FluidJourneySectionState.state(for: activeSection) == .current)

        let inProgressSection = LessonSection(
            id: "s2b",
            title: "Unit 2B",
            nodes: [
                LessonNodeModel(id: "n3b", title: "L3b", state: .inProgress)
            ]
        )
        #expect(FluidJourneySectionState.state(for: inProgressSection) == .current)

        let upcomingSection = LessonSection(
            id: "s3",
            title: "Unit 3",
            nodes: [
                LessonNodeModel(id: "n5", title: "L5", state: .locked),
                LessonNodeModel(id: "n6", title: "L6", state: .upcoming)
            ]
        )
        #expect(FluidJourneySectionState.state(for: upcomingSection) == .upcoming)

        let emptySection = LessonSection(id: "s4", title: "Unit 4", nodes: [])
        #expect(FluidJourneySectionState.state(for: emptySection) == .upcoming)
    }
}
