@testable import CraftUIKit
import SwiftUI
#if canImport(XCTest)
import XCTest
#endif

final class CraftFloatingTabBarTests: XCTestCase {
    func testSelectionAnimationRespectsReduceMotion() {
        let animations = CraftDefaultAnimationTokens()

        XCTAssertNotNil(
            CraftTabBarAnimationPolicy.selectionAnimation(
                reduceMotion: false,
                animations: animations
            )
        )
        XCTAssertNil(
            CraftTabBarAnimationPolicy.selectionAnimation(
                reduceMotion: true,
                animations: animations
            )
        )
    }

    func testScrollPresentationReducerCompactsAfterDeliberateDownwardTravel() {
        var reducer = CraftTabBarScrollPresentationReducer()

        XCTAssertNil(reducer.receive(contentOffset: 0, threshold: 24))
        XCTAssertNil(reducer.receive(contentOffset: 12, threshold: 24))
        XCTAssertEqual(reducer.receive(contentOffset: 24, threshold: 24), .compact)
        XCTAssertEqual(reducer.presentation, .compact)
    }

    func testScrollPresentationReducerExpandsAfterDeliberateUpwardTravel() {
        var reducer = CraftTabBarScrollPresentationReducer(presentation: .compact)

        XCTAssertNil(reducer.receive(contentOffset: 96, threshold: 24))
        XCTAssertNil(reducer.receive(contentOffset: 84, threshold: 24))
        XCTAssertEqual(reducer.receive(contentOffset: 72, threshold: 24), .expanded)
        XCTAssertEqual(reducer.presentation, .expanded)
    }

    func testScrollPresentationReducerIgnoresTopBounceAndNonFiniteOffsets() {
        var reducer = CraftTabBarScrollPresentationReducer()

        XCTAssertNil(reducer.receive(contentOffset: 0, threshold: 24))
        XCTAssertNil(reducer.receive(contentOffset: -32, threshold: 24))
        XCTAssertNil(reducer.receive(contentOffset: .infinity, threshold: 24))
        XCTAssertEqual(reducer.presentation, .expanded)
    }

    func testPresentationAnimationRespectsReduceMotion() {
        let animations = CraftDefaultAnimationTokens()

        XCTAssertNotNil(
            CraftTabBarAnimationPolicy.presentationAnimation(
                reduceMotion: false,
                animations: animations
            )
        )
        XCTAssertNil(
            CraftTabBarAnimationPolicy.presentationAnimation(
                reduceMotion: true,
                animations: animations
            )
        )
    }
}
