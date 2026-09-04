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
        #expect(pill.coordinateSpaceName == "CraftFluidJourneyScrollCoordinateSpace")
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
        #expect(CraftMilestonePill.coordinateSpaceName == "CraftFluidJourneyScrollCoordinateSpace")
        #expect(CraftMilestonePill.defaultCoordinateSpaceName == "CraftFluidJourneyScrollCoordinateSpace")
    }

    @Test("Verify surface style property and equatable with surface style")
    func testPillSurfaceStyleEquatable() {
        let pillDefault = CraftMilestonePill(sectionId: "sec-1", title: "Title 1")
        let pillGlass = CraftMilestonePill(sectionId: "sec-1", title: "Title 1", surfaceStyle: .glass)
        let pillElevated = CraftMilestonePill(sectionId: "sec-1", title: "Title 1", surfaceStyle: .elevated)

        #expect(pillDefault.surfaceStyle == nil)
        #expect(pillGlass.surfaceStyle == .glass)
        #expect(pillElevated.surfaceStyle == .elevated)

        #expect(pillDefault != pillGlass)
        #expect(pillGlass != pillElevated)

        let pillGlass2 = CraftMilestonePill(sectionId: "sec-1", title: "Title 1", surfaceStyle: .glass)
        #expect(pillGlass == pillGlass2)
    }

    @Test("Verify milestone pill supports tactile3D surface style")
    func testMilestonePillSupportsTactile3D() {
        let pill = CraftMilestonePill(sectionId: "s1", title: "Topic", surfaceStyle: .tactile3D)
        #expect(pill.effectiveSurfaceStyle == .tactile3D)
        #expect(pill.surfaceStyle == .tactile3D)
    }
}
