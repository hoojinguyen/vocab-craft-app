@testable import CraftUIKit
import SwiftUI
import XCTest

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

    // MARK: - Task 5: Surface Styles & Comprehensive Unit Tests

    func testAllSurfaceStylesForFeedbackSheet() {
        for style in CraftSurfaceStyle.allCases {
            // Explicit surface style initializer
            let sheet = CraftFeedbackSheet(
                status: .success,
                title: "Style \(style.rawValue)",
                message: "Testing surface style rendering",
                actionTitle: "CONTINUE",
                surfaceStyle: style,
                onContinue: {}
            )
            XCTAssertEqual(sheet.surfaceStyle, style)
            XCTAssertNotNil(sheet.body)

            // Sheet with extra content and explicit style
            let sheetWithExtra = CraftFeedbackSheet(
                status: .warning,
                title: "Warning \(style.rawValue)",
                surfaceStyle: style,
                onContinue: {}
            ) {
                Text("Auxiliary hint for \(style.rawValue)")
            }
            XCTAssertEqual(sheetWithExtra.surfaceStyle, style)
            XCTAssertNotNil(sheetWithExtra.body)

            // Modifier presentation with explicit style
            let isPresented = Binding.constant(true)
            let hostView = Text("Host")
                .craftFeedbackSheet(
                    isPresented: isPresented,
                    status: .info,
                    title: "Info \(style.rawValue)",
                    surfaceStyle: style,
                    onContinue: {}
                )
            XCTAssertNotNil(hostView)
        }

        // Test environment fallback when surfaceStyle is nil
        let sheetWithoutExplicitStyle = CraftFeedbackSheet(
            status: .success,
            onContinue: {}
        )
        XCTAssertNil(sheetWithoutExplicitStyle.surfaceStyle)
        XCTAssertNotNil(sheetWithoutExplicitStyle.body)

        // Test inside custom surface style environment wrapper
        let inheritedGlassView = CraftFeedbackSheet(
            status: .success,
            onContinue: {}
        )
        .craftSurfaceStyle(.glass)
        .craftTheme(CraftDefaultTheme())
        XCTAssertNotNil(inheritedGlassView)

        let inheritedElevatedView = CraftFeedbackSheet(
            status: .error,
            onContinue: {}
        )
        .craftSurfaceStyle(.elevated)
        .craftTheme(CraftDefaultTheme())
        XCTAssertNotNil(inheritedElevatedView)

        let inheritedTactileView = CraftFeedbackSheet(
            status: .warning,
            onContinue: {}
        )
        .craftSurfaceStyle(.tactile3D)
        .craftTheme(CraftDefaultTheme())
        XCTAssertNotNil(inheritedTactileView)
    }

    func testCraftFeedbackSheetAccessibilityDescription() {
        let sheetWithoutMessage = CraftFeedbackSheet(
            status: .success,
            title: "Nice work!",
            actionTitle: "CONTINUE",
            onContinue: {}
        )
        XCTAssertEqual(sheetWithoutMessage.accessibilityDescription, "Nice work!. Action: CONTINUE")

        let sheetWithMessage = CraftFeedbackSheet(
            status: .error,
            title: "Incorrect",
            message: "Correct: Apple",
            actionTitle: "NEXT QUESTION",
            onContinue: {}
        )
        XCTAssertEqual(sheetWithMessage.accessibilityDescription, "Incorrect, Correct: Apple. Action: NEXT QUESTION")
    }
}

// MARK: - Accessibility & Extended Tests

extension FeedbackComponentTests {
    func testFeedbackSheetAccessibilityTree() {
        // 1. Verify localized status titles in English & Vietnamese
        XCTAssertEqual(CraftLocalized.string("craft.feedback.success_title", language: "en"), "Nice work!")
        XCTAssertEqual(CraftLocalized.string("craft.feedback.success_title", language: "vi"), "Chính xác!")

        XCTAssertEqual(CraftLocalized.string("craft.feedback.error_title", language: "en"), "Incorrect")
        XCTAssertEqual(CraftLocalized.string("craft.feedback.error_title", language: "vi"), "Chưa chính xác")

        XCTAssertEqual(CraftLocalized.string("craft.feedback.warning_title", language: "en"), "Almost!")
        XCTAssertEqual(CraftLocalized.string("craft.feedback.warning_title", language: "vi"), "Gần đúng!")

        XCTAssertEqual(CraftLocalized.string("craft.feedback.info_title", language: "en"), "Explanation")
        XCTAssertEqual(CraftLocalized.string("craft.feedback.info_title", language: "vi"), "Giải thích")

        XCTAssertEqual(CraftLocalized.string("craft.feedback.continue_action", language: "en"), "Continue")
        XCTAssertEqual(CraftLocalized.string("craft.feedback.continue_action", language: "vi"), "Tiếp tục")

        // 2. Verify resolved accessibility properties across all statuses
        for status in CraftFeedbackStatus.allCases {
            let defaultSheet = CraftFeedbackSheet(status: status, onContinue: {})
            XCTAssertFalse(defaultSheet.resolvedTitle.isEmpty)
            XCTAssertEqual(defaultSheet.resolvedActionTitle, "Continue")
            XCTAssertFalse(status.iconName.isEmpty)
            XCTAssertNotNil(defaultSheet.body)
        }

        // 3. Verify custom sheet with secondary action and message accessibility structure
        var secondaryInvoked = false
        var continueInvoked = false
        let detailedSheet = CraftFeedbackSheet(
            status: .error,
            title: "Custom Error Title",
            message: "Correct answer: Phenomenon",
            actionTitle: "NEXT QUESTION",
            secondaryActionTitle: "View Explanation",
            onSecondaryAction: { secondaryInvoked = true },
            onContinue: { continueInvoked = true }
        ) {
            Text("Extra Grammar Tip")
        }

        XCTAssertEqual(detailedSheet.resolvedTitle, "Custom Error Title")
        XCTAssertEqual(detailedSheet.message, "Correct answer: Phenomenon")
        XCTAssertEqual(detailedSheet.resolvedActionTitle, "NEXT QUESTION")
        XCTAssertEqual(detailedSheet.secondaryActionTitle, "View Explanation")
        XCTAssertNotNil(detailedSheet.body)

        detailedSheet.onSecondaryAction?()
        XCTAssertTrue(secondaryInvoked)
        detailedSheet.onContinue()
        XCTAssertTrue(continueInvoked)

        // 4. Verify accessibility in Light and Dark mode environments
        let lightSheet = CraftFeedbackSheet(status: .success, onContinue: {})
            .environment(\.colorScheme, .light)
        XCTAssertNotNil(lightSheet)

        let darkSheet = CraftFeedbackSheet(status: .error, onContinue: {})
            .environment(\.colorScheme, .dark)
        XCTAssertNotNil(darkSheet)

        // 5. Verify presentation modifier across different status types
        for status in CraftFeedbackStatus.allCases {
            let presentedModifierView = Text("Host")
                .craftFeedbackSheet(
                    isPresented: .constant(true),
                    status: status,
                    onContinue: {}
                )
            XCTAssertNotNil(presentedModifierView)
        }
    }

    func testFeedbackSheetAllStatusColors() {
        let theme = CraftDefaultTheme()

        // 1. Verify default semantic status colors exist and match expected palette
        XCTAssertNotNil(theme.colors.statusSuccess)
        XCTAssertNotNil(theme.colors.statusDanger)
        XCTAssertNotNil(theme.colors.statusWarning)
        XCTAssertNotNil(theme.colors.statusInfo)

        // 2. Verify sheet body evaluates cleanly for all 4 statuses with default theme
        for status in CraftFeedbackStatus.allCases {
            let sheet = CraftFeedbackSheet(
                status: status,
                title: "Testing \(status.rawValue)",
                message: "Status message for \(status.rawValue)",
                onContinue: {}
            )
            XCTAssertNotNil(sheet.body)
        }

        // 3. Test custom theme with customized semantic status color palette
        struct CustomStatusColors: CraftColorTokens {
            var canvasBackground: Color = .black
            var surfaceCard: Color = Color(hex: 0x1E1E24)
            var surfaceElevated: Color = Color(hex: 0x2A2A32)
            var surfaceSubtle: Color = Color(hex: 0x16161A)
            var brandPrimary: Color = .purple
            var brandSecondary: Color = .pink
            var accent: Color = .yellow
            var textPrimary: Color = .white
            var textSecondary: Color = .gray
            var textMuted: Color = .gray
            var textInverse: Color = .black
            var borderDefault: Color = .gray
            var borderFocus: Color = .purple
            var hairline: Color = .gray
            var statusSuccess: Color = Color(hex: 0x22C55E)
            var statusWarning: Color = Color(hex: 0xEAB308)
            var statusDanger: Color = Color(hex: 0xF43F5E)
            var statusInfo: Color = Color(hex: 0x06B6D4)
        }

        struct CustomTheme: CraftTheme {
            var colors: CraftColorTokens = CustomStatusColors()
            var typography: CraftTypographyTokens = CraftDefaultTypographyTokens()
            var spacing: CraftSpacingTokens = CraftDefaultSpacingTokens()
            var radii: CraftRadiusTokens = CraftDefaultRadiusTokens()
            var shadows: CraftShadowTokens = CraftDefaultShadowTokens()
            var gradients: CraftGradientTokens = CraftDefaultGradientTokens()
            var animations: CraftAnimationTokens = CraftDefaultAnimationTokens()
            var opacities: CraftOpacityTokens = CraftDefaultOpacityTokens()
            var depths: CraftDepthTokens = CraftDefaultDepthTokens()
        }

        let customTheme = CustomTheme()
        XCTAssertEqual(customTheme.colors.statusSuccess, Color(hex: 0x22C55E))
        XCTAssertEqual(customTheme.colors.statusWarning, Color(hex: 0xEAB308))
        XCTAssertEqual(customTheme.colors.statusDanger, Color(hex: 0xF43F5E))
        XCTAssertEqual(customTheme.colors.statusInfo, Color(hex: 0x06B6D4))

        for status in CraftFeedbackStatus.allCases {
            let customThemedSheet = CraftFeedbackSheet(
                status: status,
                title: "Custom Themed \(status.rawValue)",
                onContinue: {}
            )
            .craftTheme(customTheme)

            XCTAssertNotNil(customThemedSheet)
        }

        // 4. Verify dynamic light/dark mode color resolution
        let dynamicSuccess = Color.craftDynamic(light: Color(hex: 0x10B981), dark: Color(hex: 0x059669))
        let dynamicDanger = Color.craftDynamic(light: Color(hex: 0xEF4444), dark: Color(hex: 0xDC2626))
        let dynamicWarning = Color.craftDynamic(light: Color(hex: 0xF59E0B), dark: Color(hex: 0xD97706))
        let dynamicInfo = Color.craftDynamic(light: Color(hex: 0x0284C7), dark: Color(hex: 0x0369A1))

        XCTAssertNotNil(dynamicSuccess)
        XCTAssertNotNil(dynamicDanger)
        XCTAssertNotNil(dynamicWarning)
        XCTAssertNotNil(dynamicInfo)

        for status in CraftFeedbackStatus.allCases {
            let darkSheet = CraftFeedbackSheet(status: status, onContinue: {})
                .environment(\.colorScheme, .dark)
                .craftTheme(CraftDefaultTheme())
            XCTAssertNotNil(darkSheet)

            let lightSheet = CraftFeedbackSheet(status: status, onContinue: {})
                .environment(\.colorScheme, .light)
                .craftTheme(CraftDefaultTheme())
            XCTAssertNotNil(lightSheet)
        }
    }

    func testStyleDirectArgumentAndHintCard() {
        for style in CraftSurfaceStyle.allCases {
            let sheet = CraftFeedbackSheet(
                status: .success,
                title: "Direct Style Test",
                message: "Testing style: \(style.rawValue)",
                secondaryActionTitle: "Explain",
                style: style,
                onSecondaryAction: {},
                onContinue: {}
            ) {
                CraftFeedbackHintCard("Helpful hint with accessible contrast")
            }

            XCTAssertEqual(sheet.style, style)
            XCTAssertEqual(sheet.surfaceStyle, style)
            XCTAssertEqual(sheet.resolvedSurfaceStyle, style)
            XCTAssertNotNil(sheet.body)
        }

        let hintCard = CraftFeedbackHintCard("Custom Hint", icon: "sparkles", tint: .green)
        XCTAssertEqual(hintCard.text, "Custom Hint")
        XCTAssertEqual(hintCard.icon, "sparkles")
        XCTAssertEqual(hintCard.tint, .green)
        XCTAssertNotNil(hintCard.body)
    }

    // MARK: - Edge-to-Edge Docking, Streak, and Custom Titles Tests

    func testCraftFeedbackSheetWithStreakDisplay() {
        let sheet = CraftFeedbackSheet(
            status: .success,
            title: "Chính xác!",
            streakCount: 5,
            onContinue: {}
        )
        XCTAssertEqual(sheet.streakCount, 5)
        XCTAssertEqual(sheet.resolvedTitle, "Chính xác!")
        XCTAssertNotNil(sheet.body)

        // Sheet with nil streak
        let sheetNoStreak = CraftFeedbackSheet(
            status: .error,
            title: "✕ Chưa chính xác",
            onContinue: {}
        )
        XCTAssertNil(sheetNoStreak.streakCount)
        XCTAssertEqual(sheetNoStreak.resolvedTitle, "✕ Chưa chính xác")
        XCTAssertNotNil(sheetNoStreak.body)
    }

    func testCraftFeedbackSheetEdgeToEdgeAndCustomActionTitles() {
        let timeoutSheet = CraftFeedbackSheet(
            status: .warning,
            title: "⏰ Hết giờ!",
            actionTitle: "Đã hiểu",
            onContinue: {}
        )
        XCTAssertEqual(timeoutSheet.resolvedTitle, "⏰ Hết giờ!")
        XCTAssertEqual(timeoutSheet.resolvedActionTitle, "Đã hiểu")
        XCTAssertNotNil(timeoutSheet.body)

        let correctSheet = CraftFeedbackSheet(
            status: .success,
            title: "✓ Chính xác!",
            actionTitle: "Tiếp tục",
            streakCount: 12,
            onContinue: {}
        )
        XCTAssertEqual(correctSheet.resolvedTitle, "✓ Chính xác!")
        XCTAssertEqual(correctSheet.resolvedActionTitle, "Tiếp tục")
        XCTAssertEqual(correctSheet.streakCount, 12)
        XCTAssertNotNil(correctSheet.body)
    }

    func testCraftFeedbackSheetModifierWithStreak() {
        let isPresented = Binding.constant(true)
        var continued = false
        let modifier = CraftFeedbackSheetModifier(
            isPresented: isPresented,
            status: .success,
            title: "✓ Chính xác!",
            actionTitle: "Tiếp tục",
            streakCount: 7,
            onContinue: { continued = true }
        )
        XCTAssertEqual(modifier.status, .success)
        XCTAssertEqual(modifier.title, "✓ Chính xác!")
        XCTAssertEqual(modifier.actionTitle, "Tiếp tục")
        XCTAssertEqual(modifier.streakCount, 7)
        modifier.onContinue()
        XCTAssertTrue(continued)

        let modifiedView = Text("Question Content").craftFeedbackSheet(
            isPresented: isPresented,
            status: .success,
            title: "✓ Chính xác!",
            actionTitle: "Tiếp tục",
            streakCount: 7,
            onContinue: {}
        )
        XCTAssertNotNil(modifiedView)

        let modifiedViewWithExtra = Text("Question Content").craftFeedbackSheet(
            isPresented: isPresented,
            status: .error,
            title: "✕ Chưa chính xác",
            actionTitle: "Tiếp tục",
            streakCount: 0,
            onContinue: {}
        ) {
            Text("Extra info")
        }
        XCTAssertNotNil(modifiedViewWithExtra)
    }
}
