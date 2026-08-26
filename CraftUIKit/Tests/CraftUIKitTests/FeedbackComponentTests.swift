import XCTest
import SwiftUI
@testable import CraftUIKit

final class FeedbackComponentTests: XCTestCase {
    func testCraftFeedbackStatusProperties() {
        XCTAssertEqual(CraftFeedbackStatus.success.iconName, "checkmark.circle.fill")
        XCTAssertEqual(CraftFeedbackStatus.error.iconName, "xmark.circle.fill")
        XCTAssertEqual(CraftFeedbackStatus.warning.iconName, "exclamationmark.circle.fill")
        XCTAssertEqual(CraftFeedbackStatus.info.iconName, "info.circle.fill")

        XCTAssertEqual(CraftFeedbackStatus.allCases.count, 4)
    }

    func testCraftFeedbackSheetInitialization() {
        var continueTriggered = false
        let sheet = CraftFeedbackSheet(
            status: .success,
            title: "Nice work!",
            message: "You got it right!",
            actionTitle: "CONTINUE",
            onContinue: {
                continueTriggered = true
            }
        )

        XCTAssertEqual(sheet.status, .success)
        XCTAssertEqual(sheet.title, "Nice work!")
        XCTAssertEqual(sheet.message, "You got it right!")
        XCTAssertEqual(sheet.actionTitle, "CONTINUE")
        XCTAssertNil(sheet.surfaceStyle)

        sheet.onContinue()
        XCTAssertTrue(continueTriggered)
        XCTAssertNotNil(sheet.body)
    }

    func testCraftFeedbackSheetWithExtraContent() {
        var secondaryTriggered = false
        let sheet = CraftFeedbackSheet(
            status: .error,
            title: "Incorrect",
            message: "Correct: Apple",
            secondaryActionTitle: "Explain",
            onSecondaryAction: {
                secondaryTriggered = true
            },
            onContinue: {}
        ) {
            Text("Extra Hint")
        }

        XCTAssertEqual(sheet.status, .error)
        XCTAssertEqual(sheet.secondaryActionTitle, "Explain")
        sheet.onSecondaryAction?()
        XCTAssertTrue(secondaryTriggered)
        XCTAssertNotNil(sheet.extraContent)
        XCTAssertNotNil(sheet.body)
    }

    func testCraftFeedbackSheetAllStatusesAndSurfaceStyles() {
        for status in CraftFeedbackStatus.allCases {
            for surfaceStyle in CraftSurfaceStyle.allCases {
                let sheet = CraftFeedbackSheet(
                    status: status,
                    surfaceStyle: surfaceStyle,
                    onContinue: {}
                )
                XCTAssertEqual(sheet.status, status)
                XCTAssertEqual(sheet.surfaceStyle, surfaceStyle)
                XCTAssertNotNil(sheet.body)
            }
        }
    }

    func testCraftFeedbackSheetResolvedTitlesAndDefaults() {
        let successSheet = CraftFeedbackSheet(status: .success, onContinue: {})
        XCTAssertEqual(successSheet.resolvedTitle, CraftLocalized.string("craft.feedback.success_title"))
        XCTAssertEqual(successSheet.resolvedActionTitle, CraftLocalized.string("craft.feedback.continue_action"))

        let errorSheet = CraftFeedbackSheet(status: .error, onContinue: {})
        XCTAssertEqual(errorSheet.resolvedTitle, CraftLocalized.string("craft.feedback.error_title"))

        let warningSheet = CraftFeedbackSheet(status: .warning, onContinue: {})
        XCTAssertEqual(warningSheet.resolvedTitle, CraftLocalized.string("craft.feedback.warning_title"))

        let infoSheet = CraftFeedbackSheet(status: .info, onContinue: {})
        XCTAssertEqual(infoSheet.resolvedTitle, CraftLocalized.string("craft.feedback.info_title"))

        let explicitSheet = CraftFeedbackSheet(
            status: .success,
            title: "Custom Title",
            actionTitle: "Custom Action",
            onContinue: {}
        )
        XCTAssertEqual(explicitSheet.resolvedTitle, "Custom Title")
        XCTAssertEqual(explicitSheet.resolvedActionTitle, "Custom Action")
    }

    func testCraftFeedbackSheetModifier() {
        let dummyView = Text("Question Content")
            .craftFeedbackSheet(
                isPresented: .constant(true),
                status: .success,
                title: "Nice work!",
                onContinue: {}
            )
        XCTAssertNotNil(dummyView)
    }

    func testCraftFeedbackSheetModifierWithExtraContent() {
        var continued = false
        var explained = false
        let isPresentedBinding = Binding.constant(true)
        let modifier = CraftFeedbackSheetModifier(
            isPresented: isPresentedBinding,
            status: .error,
            title: "Incorrect",
            message: "Correct: Apple",
            actionTitle: "CONTINUE",
            secondaryActionTitle: "Explain",
            surfaceStyle: .glass,
            onSecondaryAction: { explained = true },
            onContinue: { continued = true },
            extraContent: { Text("Explanation text") }
        )
        XCTAssertEqual(modifier.status, .error)
        XCTAssertEqual(modifier.title, "Incorrect")
        XCTAssertEqual(modifier.message, "Correct: Apple")
        XCTAssertEqual(modifier.actionTitle, "CONTINUE")
        XCTAssertEqual(modifier.secondaryActionTitle, "Explain")
        XCTAssertEqual(modifier.surfaceStyle, .glass)
        modifier.onContinue()
        XCTAssertTrue(continued)
        modifier.onSecondaryAction?()
        XCTAssertTrue(explained)
        XCTAssertNotNil(modifier.extraContent)

        let viewWithExtra = Text("Question")
            .craftFeedbackSheet(
                isPresented: isPresentedBinding,
                status: .error,
                title: "Incorrect",
                message: "Correct: Apple",
                actionTitle: "CONTINUE",
                secondaryActionTitle: "Explain",
                surfaceStyle: .glass,
                onSecondaryAction: { explained = true },
                onContinue: { continued = true }
            ) {
                Text("Explanation text")
            }
        XCTAssertNotNil(viewWithExtra)
    }
}
