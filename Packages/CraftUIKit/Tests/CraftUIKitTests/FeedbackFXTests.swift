#if canImport(XCTest)
import XCTest
#endif
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

    func testSparkleDurationConstant() {
        XCTAssertEqual(CraftSparkleView.animationDuration, 1.0)
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

    func testSparkleDismissImmediately() {
        var isTriggered = true
        let binding = Binding(get: { isTriggered }, set: { isTriggered = $0 })
        let view = CraftSparkleView(isTriggered: binding, style: .sparkles)
        XCTAssertTrue(isTriggered)

        view.dismissImmediately()
        XCTAssertFalse(isTriggered, "dismissImmediately must reset isTriggered binding to false")
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

    // MARK: - Feedback Localization Tests

    func testWaveformLocalization() {
        XCTAssertEqual(CraftLocalized.string("craft.waveform.recording_active_a11y", language: "en"), "Audio waveform recording active")
        XCTAssertEqual(CraftLocalized.string("craft.waveform.recording_active_a11y", language: "vi"), "Đang thu âm sóng âm thanh")

        XCTAssertEqual(CraftLocalized.string("craft.waveform.visualizer_a11y", language: "en"), "Audio waveform visualizer")
        XCTAssertEqual(CraftLocalized.string("craft.waveform.visualizer_a11y", language: "vi"), "Trình hiển thị sóng âm")

        XCTAssertEqual(CraftLocalized.format("craft.waveform.audio_level_format", language: "en", 75), "75 percent average audio level")
        XCTAssertEqual(CraftLocalized.format("craft.waveform.audio_level_format", language: "vi", 75), "Mức âm thanh trung bình 75 phần trăm")
    }

    func testCountdownLocalization() {
        XCTAssertEqual(CraftLocalized.string("craft.countdown.go_text", language: "en"), "GO!")
        XCTAssertEqual(CraftLocalized.string("craft.countdown.go_text", language: "vi"), "BẮT ĐẦU!")

        XCTAssertEqual(CraftLocalized.format("craft.countdown.label_format", language: "en", 3), "Countdown 3")
        XCTAssertEqual(CraftLocalized.format("craft.countdown.label_format", language: "vi", 3), "Đếm ngược 3")
    }

    func testSparkleLocalization() {
        XCTAssertEqual(CraftLocalized.string("craft.sparkle.sparkle_label", language: "en"), "Sparkle!")
        XCTAssertEqual(CraftLocalized.string("craft.sparkle.sparkle_label", language: "vi"), "Lấp lánh!")

        XCTAssertEqual(CraftLocalized.string("craft.sparkle.celebration_label", language: "en"), "Celebration!")
        XCTAssertEqual(CraftLocalized.string("craft.sparkle.celebration_label", language: "vi"), "Chúc mừng!")
    }

    func testStreakCelebrationLocalization() {
        XCTAssertEqual(CraftLocalized.string("craft.common.unit.days_single", language: "en"), "days")
        XCTAssertEqual(CraftLocalized.string("craft.common.unit.days_single", language: "vi"), "ngày")

        XCTAssertEqual(CraftLocalized.string("craft.streak.celebration_title", language: "en"), "Streak Extended!")
        XCTAssertEqual(CraftLocalized.string("craft.streak.celebration_title", language: "vi"), "Chuỗi ngày rực lửa!")

        XCTAssertEqual(CraftLocalized.string("craft.streak.continue_action", language: "en"), "Continue Learning")
        XCTAssertEqual(CraftLocalized.string("craft.streak.continue_action", language: "vi"), "Tiếp tục học")

        XCTAssertEqual(CraftLocalized.string("craft.streak.celebration_hint", language: "en"), "Double tap to dismiss and continue learning.")
        XCTAssertEqual(CraftLocalized.string("craft.streak.celebration_hint", language: "vi"), "Chạm hai lần để đóng màn hình và tiếp tục học.")

        XCTAssertEqual(CraftLocalized.format("craft.streak.milestone_title_format", language: "en", 14), "14-Day Milestone!")
        XCTAssertEqual(CraftLocalized.format("craft.streak.milestone_title_format", language: "vi", 14), "Cột mốc 14 ngày!")
    }

    // MARK: - CraftSymbolEffects Tests

    func testSymbolBounceModifier() {
        let view = Image(systemName: "star.fill").craftSymbolBounce(value: 5)
        XCTAssertNotNil(view)
    }

    func testSymbolPulseModifier() {
        let activeView = Image(systemName: "mic.fill").craftSymbolPulse(isActive: true)
        let inactiveView = Image(systemName: "mic.fill").craftSymbolPulse(isActive: false)
        let defaultView = Image(systemName: "mic.fill").craftSymbolPulse()
        XCTAssertNotNil(activeView)
        XCTAssertNotNil(inactiveView)
        XCTAssertNotNil(defaultView)
    }

    func testSymbolVariableColorModifier() {
        let activeView = Image(systemName: "speaker.wave.3.fill").craftSymbolVariableColor(isActive: true)
        let inactiveView = Image(systemName: "speaker.wave.3.fill").craftSymbolVariableColor(isActive: false)
        let defaultView = Image(systemName: "speaker.wave.3.fill").craftSymbolVariableColor()
        XCTAssertNotNil(activeView)
        XCTAssertNotNil(inactiveView)
        XCTAssertNotNil(defaultView)
    }

    func testSymbolReplaceModifier() {
        let view = Image(systemName: "checkmark").craftSymbolReplace()
        XCTAssertNotNil(view)
    }

    // MARK: - CraftPathUnlockSurge Tests

    func testPathSurgeShapeProgressAndAnimatableData() {
        var shape = CraftPathSurgeShape(
            from: CGPoint(x: 10, y: 10),
            to: CGPoint(x: 100, y: 100),
            progress: 0.5,
            trailLength: 0.2
        )
        XCTAssertEqual(shape.progress, 0.5)
        XCTAssertEqual(shape.trailLength, 0.2)
        XCTAssertEqual(shape.animatableData, 0.5)

        shape.animatableData = 0.8
        XCTAssertEqual(shape.progress, 0.8)

        let pathAtZero = CraftPathSurgeShape(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 100),
            progress: 0.0
        ).path(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertTrue(pathAtZero.isEmpty)

        let pathAtFull = CraftPathSurgeShape(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 100),
            progress: 1.0,
            trailLength: 0.3
        ).path(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertFalse(pathAtFull.isEmpty)
    }

    func testPathUnlockSurgeViewInitWithEndpoints() {
        var completed = false
        let surge = CraftPathUnlockSurgeView(
            from: CGPoint(x: 20, y: 30),
            to: CGPoint(x: 120, y: 180),
            isTriggered: true,
            color: .yellow,
            glowColor: .white,
            lineWidth: 5.0,
            sparkSize: 14.0,
            duration: 0.65,
            onComplete: { completed = true }
        )
        XCTAssertEqual(surge.from, CGPoint(x: 20, y: 30))
        XCTAssertEqual(surge.to, CGPoint(x: 120, y: 180))
        XCTAssertEqual(surge.isTriggered, true)
        XCTAssertEqual(surge.color, .yellow)
        XCTAssertEqual(surge.glowColor, .white)
        XCTAssertEqual(surge.lineWidth, 5.0)
        XCTAssertEqual(surge.sparkSize, 14.0)
        XCTAssertEqual(surge.duration, 0.65)
        surge.onComplete?()
        XCTAssertTrue(completed)
        XCTAssertNotNil(surge.body)
    }

    func testPathUnlockSurgeViewInitWithSnakeSegment() {
        let segment = SnakePathSegmentGeometry(
            from: CGPoint(x: 50, y: 50),
            to: CGPoint(x: 250, y: 150),
            type: .rightHairpin,
            turnRadius: 24,
            turnX: 300
        )
        let surge = CraftPathUnlockSurgeView(
            segment: segment,
            isTriggered: true,
            lineWidth: 4.0
        )
        XCTAssertEqual(surge.from, CGPoint(x: 50, y: 50))
        XCTAssertEqual(surge.to, CGPoint(x: 250, y: 150))
        XCTAssertNotNil(surge.segment)
        XCTAssertEqual(surge.lineWidth, 4.0)
        XCTAssertNotNil(surge.body)
    }

    func testPathUnlockSurgeViewInitWithPath() {
        var testPath = Path()
        testPath.move(to: CGPoint(x: 0, y: 0))
        testPath.addLine(to: CGPoint(x: 50, y: 50))

        let surge = CraftPathUnlockSurgeView(
            path: testPath,
            progress: 0.75,
            color: .blue
        )
        XCTAssertEqual(surge.explicitProgress, 0.75)
        XCTAssertEqual(surge.color, .blue)
        XCTAssertNotNil(surge.body)
    }

    func testPathUnlockSurgeViewModifiers() {
        var isTriggered = true
        let binding = Binding(get: { isTriggered }, set: { isTriggered = $0 })
        let modifiedWithPoints = Text("Learning Path").craftPathUnlockSurge(
            isTriggered: binding,
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 200),
            color: .orange,
            onComplete: {}
        )
        XCTAssertNotNil(modifiedWithPoints)

        let segment = SnakePathSegmentGeometry(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 100),
            type: .horizontal,
            turnRadius: 10,
            turnX: 0
        )
        let modifiedWithSegment = Text("Learning Path").craftPathUnlockSurge(
            isTriggered: binding,
            segment: segment,
            color: .green
        )
        XCTAssertNotNil(modifiedWithSegment)
    }

    func testCraftPathUnlockSurgeTypeAlias() {
        let view: CraftPathUnlockSurge = CraftPathUnlockSurge(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 50, y: 50)
        )
        XCTAssertNotNil(view.body)
    }
}
