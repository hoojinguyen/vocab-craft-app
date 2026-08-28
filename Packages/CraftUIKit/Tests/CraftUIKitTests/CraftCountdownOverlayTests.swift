import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftCountdownOverlayTests: XCTestCase {

    // MARK: - Initializer & Defaults Tests

    func testCountdownInitDefaults() {
        var isFinished = false
        let overlay = CraftCountdownOverlay(
            startNumber: 3,
            title: "Speed Drill",
            onFinish: { isFinished = true }
        )

        XCTAssertEqual(overlay.startNumber, 3)
        XCTAssertEqual(overlay.title, "Speed Drill")
        XCTAssertNil(overlay.subtitle)
        XCTAssertNil(overlay.iconName)
        XCTAssertNil(overlay.tintColor)
        XCTAssertEqual(overlay.goText, "GO!")
        XCTAssertNotNil(overlay.body)

        overlay.onFinish()
        XCTAssertTrue(isFinished)
    }

    func testCountdownClampsStartNumber() {
        let zeroOverlay = CraftCountdownOverlay(startNumber: 0) {}
        XCTAssertEqual(zeroOverlay.startNumber, 1)

        let negativeOverlay = CraftCountdownOverlay(startNumber: -10) {}
        XCTAssertEqual(negativeOverlay.startNumber, 1)

        let positiveOverlay = CraftCountdownOverlay(startNumber: 5) {}
        XCTAssertEqual(positiveOverlay.startNumber, 5)
    }

    func testCountdownCustomConfiguration() {
        var isFinished = false
        let customTint = Color.orange

        let overlay = CraftCountdownOverlay(
            startNumber: 4,
            title: "Reflex Blitz",
            subtitle: "Translate rapidly within 3 seconds",
            iconName: "bolt.fill",
            tintColor: customTint,
            goText: "START!",
            onFinish: { isFinished = true }
        )

        XCTAssertEqual(overlay.startNumber, 4)
        XCTAssertEqual(overlay.title, "Reflex Blitz")
        XCTAssertEqual(overlay.subtitle, "Translate rapidly within 3 seconds")
        XCTAssertEqual(overlay.iconName, "bolt.fill")
        XCTAssertEqual(overlay.tintColor, customTint)
        XCTAssertEqual(overlay.goText, "START!")
        XCTAssertNotNil(overlay.body)

        overlay.onFinish()
        XCTAssertTrue(isFinished)
    }

    // MARK: - ViewModifier & Extension Tests

    func testCountdownViewModifier() {
        var isPresented = true
        let binding = Binding(get: { isPresented }, set: { isPresented = $0 })
        var isFinished = false

        let modified = Text("Study Session").craftCountdown(
            isPresented: binding,
            startNumber: 3,
            title: "Speed Round",
            subtitle: "Tap fast!",
            iconName: "timer",
            tintColor: .purple,
            goText: "READY!",
            onFinish: { isFinished = true }
        )

        XCTAssertNotNil(modified)
        XCTAssertFalse(isFinished)
    }
}
