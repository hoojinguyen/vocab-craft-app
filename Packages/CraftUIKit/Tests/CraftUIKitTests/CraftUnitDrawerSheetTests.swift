@testable import CraftUIKit
import SwiftUI
import Testing

@Suite("CraftUnitDrawerSheet Tests")
struct CraftUnitDrawerSheetTests {
    @Test("Verify drawer initialization")
    func testDrawerInit() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", level: "A2", nodes: [
                LessonNodeModel(id: "node-1", title: "Lesson 1", state: .completed),
                LessonNodeModel(id: "node-2", title: "Lesson 2", state: .active)
            ])
        ]
        let sheet = CraftUnitDrawerSheet(
            sections: sections,
            deckTitle: "Everyday English",
            deckSubtitle: "A2 Level",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        #expect(sheet.sections.count == 1)
        #expect(sheet.activeSectionId == "sec-1")
        #expect(sheet.deckTitle == "Everyday English")
        #expect(sheet.deckSubtitle == "A2 Level")
    }

    @Test("Verify convenience initializer without onAdjustPlan")
    func testConvenienceInit() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", nodes: [])
        ]
        let sheet = CraftUnitDrawerSheet(
            sections: sections,
            deckTitle: "Deck Title",
            deckSubtitle: "Deck Subtitle",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        #expect(sheet.onAdjustPlan == nil)
        #expect(sheet.sections.count == 1)
        #expect(sheet.deckTitle == "Deck Title")
    }

    @Test("Verify initial expansion defaults to activeSectionId")
    func testInitialExpansion() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", nodes: []),
            LessonSection(id: "sec-2", title: "Unit 2", nodes: [])
        ]
        let sheet = CraftUnitDrawerSheet(
            sections: sections,
            deckTitle: "Deck Title",
            deckSubtitle: "Subtitle",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        #expect(sheet.isSectionExpanded("sec-1") == true)
        #expect(sheet.isSectionExpanded("sec-2") == false)
    }

    @Test("Verify toggle section expansion and collapse via binding")
    func testToggleSectionExpansion() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", nodes: []),
            LessonSection(id: "sec-2", title: "Unit 2", nodes: [])
        ]
        var expanded: Set<String> = ["sec-1"]
        let binding = Binding(
            get: { expanded },
            set: { expanded = $0 }
        )

        let sheet = CraftUnitDrawerSheet(
            sections: sections,
            deckTitle: "Deck Title",
            deckSubtitle: "Subtitle",
            activeSectionId: "sec-1",
            expandedSectionIds: binding,
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        #expect(sheet.isSectionExpanded("sec-1") == true)
        #expect(sheet.isSectionExpanded("sec-2") == false)

        // Expand sec-2
        sheet.toggleSection("sec-2")
        #expect(sheet.isSectionExpanded("sec-2") == true)

        // Collapse sec-1
        sheet.toggleSection("sec-1")
        #expect(sheet.isSectionExpanded("sec-1") == false)
    }

    @Test("Verify select lesson callback execution")
    func testSelectLessonCallback() {
        var selectedSectionId: String?
        var selectedNodeId: String?
        var dismissed = false

        let sheet = CraftUnitDrawerSheet(
            sections: [],
            deckTitle: "Deck",
            deckSubtitle: "Sub",
            activeSectionId: "sec-1",
            onSelectLesson: { secId, nodeId in
                selectedSectionId = secId
                selectedNodeId = nodeId
            },
            onDismiss: {
                dismissed = true
            }
        )

        sheet.selectLesson(sectionId: "sec-1", nodeId: "node-42")
        #expect(selectedSectionId == "sec-1")
        #expect(selectedNodeId == "node-42")
        #expect(dismissed == true)
    }

    @Test("Verify adjust plan callback execution")
    func testAdjustPlanCallback() {
        var adjustCalled = false
        let sheet = CraftUnitDrawerSheet(
            sections: [],
            deckTitle: "Deck",
            deckSubtitle: "Sub",
            activeSectionId: "sec-1",
            onAdjustPlan: {
                adjustCalled = true
            },
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )

        sheet.onAdjustPlan?()
        #expect(adjustCalled == true)
    }

    @Test("Verify dismiss callback execution")
    func testDismissCallback() {
        var dismissed = false
        let sheet = CraftUnitDrawerSheet(
            sections: [],
            deckTitle: "Deck",
            deckSubtitle: "Sub",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {
                dismissed = true
            }
        )

        sheet.onDismiss()
        #expect(dismissed == true)
    }

    @Test("Verify equatable semantics")
    func testDrawerEquatable() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", nodes: [])
        ]
        let sheet1 = CraftUnitDrawerSheet(
            sections: sections,
            deckTitle: "Everyday English",
            deckSubtitle: "A2 Level",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        let sheet2 = CraftUnitDrawerSheet(
            sections: sections,
            deckTitle: "Everyday English",
            deckSubtitle: "A2 Level",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        let sheet3 = CraftUnitDrawerSheet(
            sections: sections,
            deckTitle: "Business English",
            deckSubtitle: "B1 Level",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )

        #expect(sheet1 == sheet2)
        #expect(sheet1 != sheet3)
    }

    @Test("Verify active section synchronization")
    func testActiveSectionSynchronization() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", nodes: []),
            LessonSection(id: "sec-2", title: "Unit 2", nodes: [])
        ]
        var expanded: Set<String> = []
        let binding = Binding(
            get: { expanded },
            set: { expanded = $0 }
        )
        let sheet = CraftUnitDrawerSheet(
            sections: sections,
            deckTitle: "Deck Title",
            deckSubtitle: "Subtitle",
            activeSectionId: "sec-2",
            expandedSectionIds: binding,
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        #expect(sheet.isSectionExpanded("sec-2") == false)
        sheet.synchronizeActiveSection()
        #expect(sheet.isSectionExpanded("sec-2") == true)
    }

    @Test("Verify section meta subtitle merges level and summary")
    func testSectionMetaSubtitle() {
        let sheet = CraftUnitDrawerSheet(
            sections: [],
            deckTitle: "Deck",
            deckSubtitle: "Sub",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        let full = LessonSection(
            id: "sec-1",
            title: "Giao Tiếp Hằng Ngày",
            subtitle: "3 lessons • 13 words",
            level: "A2 - B1",
            nodes: []
        )
        #expect(sheet.sectionMetaSubtitle(for: full) == "A2 - B1 • 3 lessons • 13 words")

        let noLevel = LessonSection(id: "sec-2", title: "Unit 2", subtitle: "3 lessons", nodes: [])
        #expect(sheet.sectionMetaSubtitle(for: noLevel) == "3 lessons")

        let bare = LessonSection(id: "sec-3", title: "Unit 3", nodes: [])
        #expect(sheet.sectionMetaSubtitle(for: bare) == nil)
    }

    @Test("Verify section completion requires all nodes completed")
    func testSectionCompletion() {
        let sheet = CraftUnitDrawerSheet(
            sections: [],
            deckTitle: "Deck",
            deckSubtitle: "Sub",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        let done = LessonSection(id: "sec-1", title: "Unit 1", nodes: [
            LessonNodeModel(id: "n-1", title: "L1", state: .completed),
            LessonNodeModel(id: "n-2", title: "L2", state: .completed)
        ])
        #expect(sheet.isSectionCompleted(done) == true)

        let partial = LessonSection(id: "sec-2", title: "Unit 2", nodes: [
            LessonNodeModel(id: "n-3", title: "L3", state: .completed),
            LessonNodeModel(id: "n-4", title: "L4", state: .active)
        ])
        #expect(sheet.isSectionCompleted(partial) == false)

        let empty = LessonSection(id: "sec-3", title: "Unit 3", nodes: [])
        #expect(sheet.isSectionCompleted(empty) == false)
    }

    @Test("Verify lesson status text reuses localized journey keys")
    func testLessonStatusText() {
        let sheet = CraftUnitDrawerSheet(
            sections: [],
            deckTitle: "Deck",
            deckSubtitle: "Sub",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        #expect(
            sheet.lessonStatusText(for: LessonNodeModel(id: "n-1", title: "L1", state: .completed))
                == CraftLocalized.string("craft.fluid_journey.completed_status")
        )
        #expect(
            sheet.lessonStatusText(for: LessonNodeModel(id: "n-2", title: "L2", state: .active))
                == CraftLocalized.string("craft.fluid_journey.current_status")
        )
        #expect(
            sheet.lessonStatusText(for: LessonNodeModel(id: "n-3", title: "L3", state: .inProgress))
                == CraftLocalized.string("craft.fluid_journey.current_status")
        )
        #expect(sheet.lessonStatusText(for: LessonNodeModel(id: "n-4", title: "L4", state: .upcoming)) == nil)
        #expect(sheet.lessonStatusText(for: LessonNodeModel(id: "n-5", title: "L5", state: .locked)) == nil)
        #expect(sheet.lessonStatusText(for: LessonNodeModel(id: "n-6", title: "L6", state: .bonus)) == nil)
    }
}
