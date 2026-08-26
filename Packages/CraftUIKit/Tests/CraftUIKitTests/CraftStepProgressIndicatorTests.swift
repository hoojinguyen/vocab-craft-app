import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftStepProgressIndicatorTests: XCTestCase {
    func testStepStatusInitialization() {
        let statuses: [CraftStepStatus] = [
            .completed(isCorrect: true),
            .completed(isCorrect: false),
            .active,
            .unreached,
            .custom(.blue)
        ]
        XCTAssertEqual(statuses.count, 5)
        XCTAssertEqual(CraftStepStatus.completed(isCorrect: true), CraftStepStatus.completed(isCorrect: true))
        XCTAssertNotEqual(CraftStepStatus.completed(isCorrect: true), CraftStepStatus.completed(isCorrect: false))
        XCTAssertNotEqual(CraftStepStatus.active, CraftStepStatus.unreached)
        XCTAssertEqual(CraftStepStatus.custom(.blue), CraftStepStatus.custom(.blue))
    }

    func testIndicatorWithTotalSteps() {
        let indicator = CraftStepProgressIndicator(totalSteps: 10, currentStep: 2)
        XCTAssertEqual(indicator.totalSteps, 10)
        XCTAssertEqual(indicator.currentStep, 2)
        XCTAssertEqual(indicator.steps.count, 10)
        XCTAssertEqual(indicator.steps[0], .completed(isCorrect: true))
        XCTAssertEqual(indicator.steps[1], .completed(isCorrect: true))
        XCTAssertEqual(indicator.steps[2], .active)
        XCTAssertEqual(indicator.steps[3], .unreached)
        XCTAssertEqual(indicator.steps[9], .unreached)
        XCTAssertEqual(indicator.displayStep, 3)
    }

    func testIndicatorBoundsHandling() {
        let indicatorZero = CraftStepProgressIndicator(totalSteps: 0, currentStep: -1)
        XCTAssertEqual(indicatorZero.totalSteps, 0)
        XCTAssertEqual(indicatorZero.displayStep, 0)
        XCTAssertTrue(indicatorZero.steps.isEmpty)

        let indicatorNegative = CraftStepProgressIndicator(totalSteps: -5, currentStep: 0)
        XCTAssertEqual(indicatorNegative.totalSteps, 0)
        XCTAssertEqual(indicatorNegative.displayStep, 0)

        let indicatorNegCur = CraftStepProgressIndicator(totalSteps: 5, currentStep: -2)
        XCTAssertEqual(indicatorNegCur.totalSteps, 5)
        XCTAssertEqual(indicatorNegCur.displayStep, 1)
        XCTAssertTrue(indicatorNegCur.steps.allSatisfy { $0 == .unreached })

        let indicatorOverflow = CraftStepProgressIndicator(totalSteps: 5, currentStep: 10)
        XCTAssertEqual(indicatorOverflow.totalSteps, 5)
        XCTAssertEqual(indicatorOverflow.displayStep, 5)
        XCTAssertTrue(indicatorOverflow.steps.allSatisfy { $0 == .completed(isCorrect: true) })
    }

    func testIndicatorWithCustomSteps() {
        let customSteps: [CraftStepStatus] = [
            .completed(isCorrect: true),
            .completed(isCorrect: false),
            .active,
            .unreached
        ]
        let indicator = CraftStepProgressIndicator(
            steps: customSteps,
            currentStep: 2,
            height: 6,
            spacing: 8,
            showCounter: true,
            counterStyle: .phrase
        )
        XCTAssertEqual(indicator.totalSteps, 4)
        XCTAssertEqual(indicator.steps, customSteps)
        XCTAssertEqual(indicator.height, 6)
        XCTAssertEqual(indicator.spacing, 8)
        XCTAssertTrue(indicator.showCounter)
        XCTAssertEqual(indicator.counterStyle, .phrase)
        XCTAssertEqual(indicator.displayStep, 3)
    }

    func testCounterStyles() {
        XCTAssertEqual(CraftStepCounterStyle.ratio, CraftStepCounterStyle.ratio)
        XCTAssertEqual(CraftStepCounterStyle.phrase, CraftStepCounterStyle.phrase)
        XCTAssertEqual(CraftStepCounterStyle.hidden, CraftStepCounterStyle.hidden)
        XCTAssertNotEqual(CraftStepCounterStyle.ratio, CraftStepCounterStyle.phrase)
        XCTAssertNotEqual(CraftStepCounterStyle.phrase, CraftStepCounterStyle.hidden)
    }

    func testColorMapping() {
        let indicator = CraftStepProgressIndicator(totalSteps: 5, currentStep: 2)
        XCTAssertEqual(indicator.color(for: .custom(.blue)), Color.blue)
    }

    func testVoiceOverAccessibilityValues() {
        let enValue = CraftLocalized.format("craft.step_progress.a11y_value_format", 3, 10)
        XCTAssertEqual(enValue, "Step 3 of 10")

        let viValue = CraftLocalized.format("craft.step_progress.a11y_value_format", language: "vi", 3, 10)
        XCTAssertEqual(viValue, "Bước 3 trên 10")
    }
}
