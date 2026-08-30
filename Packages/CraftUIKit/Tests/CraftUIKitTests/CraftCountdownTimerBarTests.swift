#if canImport(XCTest)
import XCTest
#endif
import SwiftUI
@testable import CraftUIKit

final class CraftCountdownTimerBarTests: XCTestCase {

    // MARK: - Stage Derivation Tests

    func testStageDerivation() {
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.8), .steady)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.3), .warning)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.1), .urgent)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.0), .urgent)
    }

    func testStageDerivationBoundaries() {
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 1.5), .steady)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.41), .steady)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.40), .warning)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.25), .warning)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.15), .urgent)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.14), .urgent)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: -0.5), .urgent)
    }

    // MARK: - Color Config Tests

    func testColorConfigDefaults() {
        let config = CraftCountdownColorConfig()
        XCTAssertTrue(config.showGlow)
        XCTAssertNil(config.steady)
        XCTAssertNil(config.warning)
        XCTAssertNil(config.urgent)
        XCTAssertNil(config.trackColor)
        XCTAssertEqual(config.glowRadius, 6)
    }

    func testColorConfigCustomOverrides() {
        let config = CraftCountdownColorConfig(
            steady: .blue,
            warning: .yellow,
            urgent: .purple,
            trackColor: .gray,
            showGlow: false,
            glowRadius: 12
        )
        XCTAssertFalse(config.showGlow)
        XCTAssertEqual(config.steady, .blue)
        XCTAssertEqual(config.warning, .yellow)
        XCTAssertEqual(config.urgent, .purple)
        XCTAssertEqual(config.trackColor, .gray)
        XCTAssertEqual(config.glowRadius, 12)
    }

    // MARK: - Progress Clamping Tests

    func testProgressClamping() {
        let bar = CraftCountdownTimerBar(progress: 1.5)
        XCTAssertEqual(bar.clampedProgress, 1.0)

        let negativeBar = CraftCountdownTimerBar(progress: -0.2)
        XCTAssertEqual(negativeBar.clampedProgress, 0.0)

        let validBar = CraftCountdownTimerBar(progress: 0.65)
        XCTAssertEqual(validBar.clampedProgress, 0.65)
    }

    // MARK: - Time-Driven Mode Tests

    func testTimeDrivenInitialization() {
        let now = Date()
        let bar = CraftCountdownTimerBar(
            startDate: now,
            timeLimit: 30,
            isActive: true
        )
        XCTAssertNotNil(bar.startDate)
        XCTAssertEqual(bar.timeLimit, 30)
        XCTAssertTrue(bar.isActive)
        XCTAssertNil(bar.progress)
        XCTAssertEqual(bar.clampedProgress, 1.0, accuracy: 0.05)
    }

    func testTimeDrivenExpiredClamping() {
        let pastDate = Date().addingTimeInterval(-60)
        let bar = CraftCountdownTimerBar(
            startDate: pastDate,
            timeLimit: 30,
            isActive: true
        )
        XCTAssertEqual(bar.clampedProgress, 0.0)
    }

    // MARK: - Stage Override Tests

    func testExplicitStageOverride() {
        let bar = CraftCountdownTimerBar(progress: 0.9, stage: .urgent)
        XCTAssertEqual(bar.stage, .urgent)
    }

    // MARK: - Localization Tests

    func testCountdownLocalizationKeys() {
        let label = CraftLocalized.string("craft.countdown.time_remaining_label")
        XCTAssertFalse(label.isEmpty)
        XCTAssertNotEqual(label, "craft.countdown.time_remaining_label")

        let labelEn = CraftLocalized.string("craft.countdown.time_remaining_label", language: "en")
        let labelVi = CraftLocalized.string("craft.countdown.time_remaining_label", language: "vi")
        XCTAssertEqual(labelEn, "Time remaining")
        XCTAssertEqual(labelVi, "Thời gian còn lại")
    }

    // MARK: - View Body Rendering Test

    func testViewBodyRendersWithoutCrash() {
        let fractionBar = CraftCountdownTimerBar(progress: 0.5)
        XCTAssertNotNil(fractionBar.body)

        let timeBar = CraftCountdownTimerBar(timeLimit: 10)
        XCTAssertNotNil(timeBar.body)
    }
}
