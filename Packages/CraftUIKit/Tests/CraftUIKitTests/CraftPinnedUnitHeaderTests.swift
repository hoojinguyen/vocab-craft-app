@testable import CraftUIKit
import SwiftUI
import Testing

@Suite("CraftPinnedUnitHeader Tests")
struct CraftPinnedUnitHeaderTests {
    @Test("Verify header data binding")
    func testHeaderBinding() {
        let section = LessonSection(
            id: "sec-1",
            title: "Everyday Conversations",
            subtitle: "Habits & Moods",
            level: "A2",
            nodes: []
        )
        let header = CraftPinnedUnitHeader(section: section, onTap: {})
        #expect(header.section.id == "sec-1")
        #expect(header.section.title == "Everyday Conversations")
        #expect(header.section.level == "A2")
        #expect(header.section.subtitle == "Habits & Moods")
    }

    @Test("Verify header tap invokes onTap callback")
    func testHeaderOnTapCallback() {
        var tapped = false
        let section = LessonSection(id: "sec-1", title: "Unit 1", nodes: [])
        let header = CraftPinnedUnitHeader(section: section, onTap: {
            tapped = true
        })
        header.onTap?()
        #expect(tapped == true)
        #expect(header.onHeaderTap != nil)
    }

    @Test("Verify header tap invokes onHeaderTap callback")
    func testHeaderOnHeaderTapCallback() {
        var tapped = false
        let section = LessonSection(id: "sec-1", title: "Unit 1", nodes: [])
        let header = CraftPinnedUnitHeader(section: section, onHeaderTap: {
            tapped = true
        })
        header.onHeaderTap?()
        #expect(tapped == true)
    }

    @Test("Verify custom corner radius and tap callback")
    func testCustomCornerRadiusWithTap() {
        var tapped = false
        let section = LessonSection(id: "sec-1", title: "Unit 1", nodes: [])
        let header = CraftPinnedUnitHeader(section: section, cornerRadius: 24, onTap: {
            tapped = true
        })
        header.onTap?()
        #expect(tapped == true)
        #expect(header.cornerRadius == 24)
    }

    @Test("Verify header accessibility properties")
    func testHeaderAccessibility() {
        let section = LessonSection(
            id: "sec-1",
            title: "Everyday Conversations",
            subtitle: "Habits & Moods",
            level: "A2",
            nodes: []
        )
        let header = CraftPinnedUnitHeader(section: section, onTap: {})
        #expect(header.accessibilityLabelText == "A2, Everyday Conversations, Habits & Moods")
        #expect(header.accessibilityTraits == .isButton)
        #expect(!header.accessibilityHintText.isEmpty)
    }

    @Test("Verify header accessibility label when level or subtitle is nil")
    func testHeaderAccessibilityWithoutLevelOrSubtitle() {
        let sectionWithoutLevelOrSubtitle = LessonSection(id: "sec-2", title: "Grammar Basics", nodes: [])
        let header = CraftPinnedUnitHeader(section: sectionWithoutLevelOrSubtitle)
        #expect(header.accessibilityLabelText == "Grammar Basics")
        #expect(header.accessibilityTraits == .isButton)
    }

    @Test("Verify header equatable semantics")
    func testHeaderEquatable() {
        let section1 = LessonSection(id: "sec-1", title: "Unit 1", level: "A1", nodes: [])
        let section2 = LessonSection(id: "sec-1", title: "Unit 1", level: "A1", nodes: [])
        let section3 = LessonSection(id: "sec-2", title: "Unit 2", level: "A2", nodes: [])

        let header1 = CraftPinnedUnitHeader(section: section1, onTap: {})
        let header2 = CraftPinnedUnitHeader(section: section2, onTap: {})
        let header3 = CraftPinnedUnitHeader(section: section3, onTap: {})

        #expect(header1 == header2)
        #expect(header1 != header3)
    }

    @Test("Verify corner radius configuration")
    func testCornerRadiusConfiguration() {
        let section = LessonSection(id: "sec-1", title: "Unit 1", nodes: [])
        let defaultHeader = CraftPinnedUnitHeader(section: section)
        #expect(defaultHeader.cornerRadius == nil)
        #expect(CraftPinnedUnitHeader.defaultCornerRadius == 20)

        let customHeader = CraftPinnedUnitHeader(section: section, cornerRadius: 16)
        #expect(customHeader.cornerRadius == 16)
    }

    @Test("Verify pinned unit header supports tactile3D surface style")
    func testPinnedUnitHeaderSupportsTactile3D() {
        let section = LessonSection(id: "sec-1", title: "Unit 1", nodes: [])
        let header = CraftPinnedUnitHeader(section: section, surfaceStyle: .tactile3D)
        #expect(header.effectiveSurfaceStyle == .tactile3D)
        #expect(header.surfaceStyle == .tactile3D)
    }

    @Test("Verify pinned unit header default surface style resolution")
    func testPinnedUnitHeaderDefaultSurfaceStyle() {
        let section = LessonSection(id: "sec-1", title: "Unit 1", nodes: [])
        let header = CraftPinnedUnitHeader(section: section)
        #expect(header.surfaceStyle == nil)
        #expect(header.effectiveSurfaceStyle == .elevated)
    }

    @Test("Verify pinned unit header equatable with surface style")
    func testPinnedUnitHeaderSurfaceStyleEquatable() {
        let section = LessonSection(id: "sec-1", title: "Unit 1", nodes: [])
        let header1 = CraftPinnedUnitHeader(section: section, surfaceStyle: .tactile3D)
        let header2 = CraftPinnedUnitHeader(section: section, surfaceStyle: .tactile3D)
        let header3 = CraftPinnedUnitHeader(section: section, surfaceStyle: .glass)
        let headerDefault = CraftPinnedUnitHeader(section: section)

        #expect(header1 == header2)
        #expect(header1 != header3)
        #expect(headerDefault != header1)
    }
}
