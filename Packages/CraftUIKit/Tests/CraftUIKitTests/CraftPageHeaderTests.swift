#if canImport(XCTest)
import XCTest
#endif
import SwiftUI
@testable import CraftUIKit

final class CraftPageHeaderTests: XCTestCase {
    func testCraftHeaderAlignmentEnum() {
        XCTAssertEqual(CraftHeaderAlignment.leading, .leading)
        XCTAssertEqual(CraftHeaderAlignment.center, .center)
        XCTAssertNotEqual(CraftHeaderAlignment.leading, .center)
    }

    func testCraftPageHeaderLeadingInitialization() {
        let header = CraftPageHeader(
            "Test Title",
            subtitle: "Test Subtitle",
            alignment: .leading,
            enableScrollFade: true,
            leading: { Text("Back") },
            trailing: { Text("Action") }
        )
        XCTAssertEqual(header.title, "Test Title")
        XCTAssertEqual(header.subtitle, "Test Subtitle")
        XCTAssertEqual(header.alignment, .leading)
        XCTAssertTrue(header.enableScrollFade)
        XCTAssertNotNil(header.body)
    }

    func testCraftPageHeaderCenterInitializationWithDefaults() {
        let header = CraftPageHeader(
            "Center Title",
            alignment: .center
        )
        XCTAssertEqual(header.title, "Center Title")
        XCTAssertNil(header.subtitle)
        XCTAssertEqual(header.alignment, .center)
        XCTAssertTrue(header.enableScrollFade)
        XCTAssertNotNil(header.body)
    }

    func testCraftPageHeaderStringInitializers() {
        let header = CraftPageHeader(
            verbatim: "Verbatim Title",
            subtitleVerbatim: "Verbatim Subtitle",
            alignment: .leading
        )
        XCTAssertEqual(header.alignment, .leading)
        XCTAssertNotNil(header.body)
    }

    func testCraftPageHeaderDisabledScrollFade() {
        let header = CraftPageHeader(
            "No Fade Title",
            enableScrollFade: false
        )
        XCTAssertEqual(header.title, "No Fade Title")
        XCTAssertFalse(header.enableScrollFade)
        XCTAssertNotNil(header.body)
    }

    func testCraftPageHeaderWithOnlyLeadingSlot() {
        let header = CraftPageHeader(
            "Only Leading",
            alignment: .leading,
            leading: {
                Text("Back")
            }
        )
        XCTAssertEqual(header.title, "Only Leading")
        XCTAssertEqual(header.alignment, .leading)
        XCTAssertNotNil(header.body)
    }

    func testCraftPageHeaderWithOnlyTrailingSlot() {
        let header = CraftPageHeader(
            "Only Trailing",
            alignment: .center,
            trailing: {
                Text("Search")
            }
        )
        XCTAssertEqual(header.title, "Only Trailing")
        XCTAssertEqual(header.alignment, .center)
        XCTAssertNotNil(header.body)
    }
}
