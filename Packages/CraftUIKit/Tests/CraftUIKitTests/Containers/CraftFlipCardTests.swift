import CraftUIKit
import SwiftUI
import XCTest

final class CraftFlipCardTests: XCTestCase {
    @MainActor
    func testCraftFlipCardInstantiationWithTactile3DStyle() {
        var isFlipped = false
        let binding = Binding<Bool>(get: { isFlipped }, set: { isFlipped = $0 })
        let card = CraftFlipCard(
            isFlipped: binding,
            style: .tactile3D,
            cornerRadius: 20,
            padding: 16
        ) {
            Text("Front Content")
        } back: {
            Text("Back Content")
        }

        XCTAssertNotNil(card)
        XCTAssertEqual(card.style, .tactile3D)
        XCTAssertEqual(card.cornerRadius, 20)
        XCTAssertEqual(card.padding, 16)
        XCTAssertNotNil(card.body)
    }

    @MainActor
    func testCraftFlipCardWithHighlightShadowColor() {
        let binding = Binding<Bool>.constant(true)
        let card = CraftFlipCard(
            isFlipped: binding,
            style: .tactile3D,
            highlightShadowColor: Color.green.opacity(0.3)
        ) {
            Text("Front")
        } back: {
            Text("Back")
        }

        XCTAssertNotNil(card)
        XCTAssertEqual(card.highlightShadowColor, Color.green.opacity(0.3))
        XCTAssertNotNil(card.body)
    }

    @MainActor
    func testCraftFlipCardAcrossAllSurfaceStyles() {
        for style in CraftCardStyle.allCases {
            let card = CraftFlipCard(
                isFlipped: .constant(false),
                style: style
            ) {
                Text("Front \(style.rawValue)")
            } back: {
                Text("Back \(style.rawValue)")
            }
            XCTAssertNotNil(card.body)
        }
    }
}
