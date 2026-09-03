@testable import CraftUIKit
import SwiftUI
import Testing

@Suite("CraftMilestonePill Tests")
struct CraftMilestonePillTests {
    @Test("Verify pill initialization and accessibility text")
    func testPillProperties() {
        let pill = CraftMilestonePill(sectionId: "sec-1", title: "Present Simple for Personal Facts")
        #expect(pill.sectionId == "sec-1")
        #expect(pill.title == "Present Simple for Personal Facts")
        #expect(pill.coordinateSpaceName == "CraftFluidJourneySpace")
        #expect(pill.coordinateSpaceName == CraftMilestonePill.coordinateSpaceName)
    }

    @Test("Verify custom coordinate space configuration")
    func testCustomCoordinateSpace() {
        let pill = CraftMilestonePill(
            sectionId: "sec-custom",
            title: "Unit Boundary",
            coordinateSpaceName: "CustomCoordinateSpace"
        )
        #expect(pill.sectionId == "sec-custom")
        #expect(pill.title == "Unit Boundary")
        #expect(pill.coordinateSpaceName == "CustomCoordinateSpace")
    }

    @Test("Verify accessibility traits and label")
    func testPillAccessibility() {
        let title = "Past Continuous Mastery"
        let pill = CraftMilestonePill(sectionId: "sec-2", title: title)
        #expect(pill.accessibilityLabelText == title)
        #expect(pill.accessibilityTraits == .isHeader)
    }

    @Test("Verify equatable conformance")
    func testPillEquatable() {
        let pill1 = CraftMilestonePill(sectionId: "sec-1", title: "Title 1")
        let pill2 = CraftMilestonePill(sectionId: "sec-1", title: "Title 1")
        let pill3 = CraftMilestonePill(sectionId: "sec-2", title: "Title 1")
        let pill4 = CraftMilestonePill(sectionId: "sec-1", title: "Title 2")

        #expect(pill1 == pill2)
        #expect(pill1 != pill3)
        #expect(pill1 != pill4)
    }

    @Test("Verify coordinate space constant")
    func testCoordinateSpaceConstant() {
        #expect(CraftMilestonePill.coordinateSpaceName == "CraftFluidJourneySpace")
        #expect(CraftMilestonePill.defaultCoordinateSpaceName == "CraftFluidJourneySpace")
    }
}
