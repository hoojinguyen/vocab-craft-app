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
}
