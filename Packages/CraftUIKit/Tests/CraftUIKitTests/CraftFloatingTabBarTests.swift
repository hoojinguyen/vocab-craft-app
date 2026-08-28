@testable import CraftUIKit
import SwiftUI
import XCTest

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
