import XCTest
import SwiftUI
@testable import CraftUIKit

final class FeedbackFXTests: XCTestCase {

    // MARK: - CraftWaveformView Tests

    func testWaveformClampingAndCount() {
        let view = CraftWaveformView(audioLevels: [-0.5, 0.5, 1.5], barCount: 16)
        XCTAssertEqual(view.barCount, 16)
        XCTAssertEqual(view.normalizedLevels.count, 16)
        XCTAssertEqual(view.normalizedLevels[0], 0.0)
        XCTAssertEqual(view.normalizedLevels[1], 0.5)
        XCTAssertEqual(view.normalizedLevels[2], 1.0)
        for i in 3..<16 {
            XCTAssertEqual(view.normalizedLevels[i], 0.0)
        }
    }

    func testWaveformDefaultProperties() {
        let view = CraftWaveformView()
        XCTAssertEqual(view.barCount, 16)
        XCTAssertEqual(view.spacing, 4)
        XCTAssertEqual(view.minHeight, 4)
        XCTAssertEqual(view.maxHeight, 40)
        XCTAssertEqual(view.barWidth, 4)
        XCTAssertFalse(view.isRecording)
        XCTAssertNil(view.activeColor)
        XCTAssertNil(view.inactiveColor)
        XCTAssertEqual(view.normalizedLevels.count, 16)
        XCTAssertNotNil(view.body)
    }

    func testWaveformTruncationAndCustomProperties() {
        let levels: [CGFloat] = Array(repeating: 0.8, count: 25)
        let view = CraftWaveformView(
            audioLevels: levels,
            barCount: 10,
            spacing: 5,
            minHeight: 6,
            maxHeight: 60,
            barWidth: 4,
            isRecording: true,
            activeColor: .red,
            inactiveColor: .gray
        )

        XCTAssertEqual(view.barCount, 10)
        XCTAssertEqual(view.normalizedLevels.count, 10)
        XCTAssertEqual(view.normalizedLevels.first, 0.8)
        XCTAssertEqual(view.spacing, 5)
        XCTAssertEqual(view.minHeight, 6)
        XCTAssertEqual(view.maxHeight, 60)
        XCTAssertEqual(view.barWidth, 4)
        XCTAssertTrue(view.isRecording)
        XCTAssertEqual(view.activeColor, .red)
        XCTAssertEqual(view.inactiveColor, .gray)
        XCTAssertNotNil(view.body)
    }

    func testWaveformHeightCalculation() {
        let view = CraftWaveformView(
            audioLevels: [0.0, 0.5, 1.0],
            barCount: 3,
            minHeight: 10,
            maxHeight: 50
        )
        XCTAssertEqual(view.barHeight(for: 0.0), 10)
        XCTAssertEqual(view.barHeight(for: 0.5), 30)
        XCTAssertEqual(view.barHeight(for: 1.0), 50)
    }

    // MARK: - CraftSparkleView & Modifiers Tests

    func testSparkleStyles() {
        XCTAssertEqual(CraftSparkleStyle.allCases.count, 2)
        XCTAssertTrue(CraftSparkleStyle.allCases.contains(.sparkles))
        XCTAssertTrue(CraftSparkleStyle.allCases.contains(.confetti))
    }

    func testSparkleViewInit() {
        var isTriggered = true
        let binding = Binding(get: { isTriggered }, set: { isTriggered = $0 })
        let view = CraftSparkleView(
            isTriggered: binding,
            style: .sparkles,
            particleCount: 24
        )

        XCTAssertTrue(view.isTriggered)
        XCTAssertEqual(view.style, .sparkles)
        XCTAssertEqual(view.particleCount, 24)
        XCTAssertNotNil(view.body)
    }

    func testConfettiViewInit() {
        var isTriggered = true
        let binding = Binding(get: { isTriggered }, set: { isTriggered = $0 })
        let view = CraftSparkleView(
            isTriggered: binding,
            style: .confetti,
            particleCount: 45
        )

        XCTAssertTrue(view.isTriggered)
        XCTAssertEqual(view.style, .confetti)
        XCTAssertEqual(view.particleCount, 45)
        XCTAssertNotNil(view.body)
    }

    func testSparkleAndConfettiViewModifiers() {
        var triggered = true
        let binding = Binding(get: { triggered }, set: { triggered = $0 })

        let sparkleModified = Text("Test").craftSparkle(isTriggered: binding, particleCount: 20)
        XCTAssertNotNil(sparkleModified)

        let confettiModified = Text("Test").craftConfetti(isTriggered: binding, particleCount: 30)
        XCTAssertNotNil(confettiModified)
    }

    // MARK: - CraftCountdownOverlay Tests

    func testCountdownInit() {
        var finished = false
        let countdown = CraftCountdownOverlay(startNumber: 3) {
            finished = true
        }
        XCTAssertEqual(countdown.startNumber, 3)
        XCTAssertEqual(countdown.goText, "GO!")
        XCTAssertNil(countdown.title)
        countdown.onFinish()
        XCTAssertTrue(finished)
        XCTAssertNotNil(countdown.body)
    }

    func testCountdownCustomConfiguration() {
        var finished = false
        let countdown = CraftCountdownOverlay(
            startNumber: 5,
            title: "Speed Challenge",
            goText: "START!",
            onFinish: { finished = true }
        )
        XCTAssertEqual(countdown.startNumber, 5)
        XCTAssertEqual(countdown.title, "Speed Challenge")
        XCTAssertEqual(countdown.goText, "START!")
        countdown.onFinish()
        XCTAssertTrue(finished)
        XCTAssertNotNil(countdown.body)
    }

    func testCountdownViewModifier() {
        var isPresented = true
        let binding = Binding(get: { isPresented }, set: { isPresented = $0 })
        var finished = false

        let modified = Text("Game Screen").craftCountdown(
            isPresented: binding,
            startNumber: 3,
            title: "Ready?",
            onFinish: { finished = true }
        )
        XCTAssertNotNil(modified)
        XCTAssertFalse(finished)
    }
}
