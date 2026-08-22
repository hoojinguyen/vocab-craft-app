import XCTest
import SwiftUI
@testable import CraftUIKit

final class ContainerOverlayTests: XCTestCase {

    // MARK: - CraftCard Tests

    func testCardStylesAndProperties() {
        let card = CraftCard(style: .elevated, isPressable: true) {
            Text("Card Content")
        }
        XCTAssertEqual(card.style, .elevated)
        XCTAssertTrue(card.isPressable)
        XCTAssertNotNil(card.body)
    }

    func testCardAllStyles() {
        for style in CraftCardStyle.allCases {
            let card = CraftCard(style: style, isPressable: false) {
                Text("Style: \(style.rawValue)")
            }
            XCTAssertEqual(card.style, style)
            XCTAssertFalse(card.isPressable)
            XCTAssertNotNil(card.body)
        }
    }

    func testCardPressableAction() {
        var tapped = false
        let card = CraftCard(style: .flat, isPressable: true, action: {
            tapped = true
        }) {
            Text("Interactive")
        }
        XCTAssertTrue(card.isPressable)
        card.action?()
        XCTAssertTrue(tapped)
        XCTAssertNotNil(card.body)
    }

    func testCardCustomPaddingAndCornerRadius() {
        let card = CraftCard(
            style: .outlined,
            cornerRadius: 20,
            padding: 24
        ) {
            Text("Custom")
        }
        XCTAssertEqual(card.cornerRadius, 20)
        XCTAssertEqual(card.padding, 24)
        XCTAssertNotNil(card.body)
    }

    // MARK: - CraftProgressBar Tests

    func testProgressBarClamping() {
        let barOver = CraftProgressBar(progress: 1.5)
        XCTAssertEqual(barOver.clampedProgress, 1.0)

        let barUnder = CraftProgressBar(progress: -0.2)
        XCTAssertEqual(barUnder.clampedProgress, 0.0)

        let barNormal = CraftProgressBar(progress: 0.65)
        XCTAssertEqual(barNormal.clampedProgress, 0.65, accuracy: 0.001)
        XCTAssertNotNil(barNormal.body)
    }

    func testProgressBarSteppedInit() {
        let steppedBar = CraftProgressBar(currentStep: 3, totalSteps: 5)
        XCTAssertEqual(steppedBar.progress, 0.6, accuracy: 0.001)
        XCTAssertEqual(steppedBar.clampedProgress, 0.6, accuracy: 0.001)
        XCTAssertEqual(steppedBar.currentStep, 3)
        XCTAssertEqual(steppedBar.totalSteps, 5)
        XCTAssertNotNil(steppedBar.body)
    }

    func testProgressBarCustomStyling() {
        let bar = CraftProgressBar(
            progress: 0.5,
            height: 12,
            tintColor: .blue,
            trackColor: .gray,
            cornerRadius: 6
        )
        XCTAssertEqual(bar.height, 12)
        XCTAssertEqual(bar.tintColor, .blue)
        XCTAssertEqual(bar.trackColor, .gray)
        XCTAssertEqual(bar.cornerRadius, 6)
        XCTAssertNotNil(bar.body)
    }

    // MARK: - CraftProgressRing Tests

    func testProgressRingClamping() {
        let ringOver = CraftProgressRing(progress: 1.2)
        XCTAssertEqual(ringOver.clampedProgress, 1.0)

        let ringUnder = CraftProgressRing(progress: -0.5)
        XCTAssertEqual(ringUnder.clampedProgress, 0.0)

        let ringNormal = CraftProgressRing(progress: 0.75, lineWidth: 10, size: 100)
        XCTAssertEqual(ringNormal.clampedProgress, 0.75, accuracy: 0.001)
        XCTAssertEqual(ringNormal.lineWidth, 10)
        XCTAssertEqual(ringNormal.size, 100)
        XCTAssertNotNil(ringNormal.body)
    }

    func testProgressRingCustomCenterContent() {
        let ring = CraftProgressRing(progress: 0.8) {
            Text("80%")
        }
        XCTAssertEqual(ring.clampedProgress, 0.8, accuracy: 0.001)
        XCTAssertNotNil(ring.body)
    }

    // MARK: - CraftListRow Tests

    func testListRowProperties() {
        var actionTriggered = false
        let row = CraftListRow(
            title: "Daily Goal",
            subtitle: "20 words per day",
            iconName: "target",
            iconColor: .white,
            iconBackgroundColor: .blue,
            showChevron: true,
            action: { actionTriggered = true }
        ) {
            Text("Active")
        }

        XCTAssertEqual(row.title, "Daily Goal")
        XCTAssertEqual(row.subtitle, "20 words per day")
        XCTAssertEqual(row.iconName, "target")
        XCTAssertEqual(row.iconColor, .white)
        XCTAssertEqual(row.iconBackgroundColor, .blue)
        XCTAssertTrue(row.showChevron)
        XCTAssertNotNil(row.body)

        row.action?()
        XCTAssertTrue(actionTriggered)
    }

    func testListRowDefaultTrailingChevron() {
        let row = CraftListRow(
            title: "Account Settings",
            subtitle: "Manage profile",
            iconName: "gear",
            showChevron: true
        )
        XCTAssertEqual(row.title, "Account Settings")
        XCTAssertTrue(row.showChevron)
        XCTAssertNotNil(row.body)
    }

    // MARK: - CraftEmptyState Tests

    func testEmptyStateWithIconAndButton() {
        var buttonTapped = false
        let emptyState = CraftEmptyState(
            iconName: "tray",
            title: "No Saved Words",
            message: "Start exploring and save words to practice later.",
            buttonTitle: "Explore Now",
            buttonIcon: "sparkles",
            buttonAction: { buttonTapped = true }
        )

        XCTAssertEqual(emptyState.title, "No Saved Words")
        XCTAssertEqual(emptyState.message, "Start exploring and save words to practice later.")
        XCTAssertEqual(emptyState.iconName, "tray")
        XCTAssertEqual(emptyState.buttonTitle, "Explore Now")
        XCTAssertEqual(emptyState.buttonIcon, "sparkles")
        XCTAssertNotNil(emptyState.body)

        emptyState.buttonAction?()
        XCTAssertTrue(buttonTapped)
    }

    func testEmptyStateCustomIllustration() {
        let emptyState = CraftEmptyState(
            title: "No Results",
            message: "Try searching something else."
        ) {
            Image(systemName: "magnifyingglass")
        }
        XCTAssertEqual(emptyState.title, "No Results")
        XCTAssertEqual(emptyState.message, "Try searching something else.")
        XCTAssertNotNil(emptyState.body)
    }

    // MARK: - CraftToast Tests

    func testToastDataInit() {
        let toast = CraftToastData(
            title: "Saved",
            message: "Word added to favorites",
            iconName: "heart.fill",
            style: .success,
            duration: 4.0
        )
        XCTAssertEqual(toast.title, "Saved")
        XCTAssertEqual(toast.message, "Word added to favorites")
        XCTAssertEqual(toast.iconName, "heart.fill")
        XCTAssertEqual(toast.style, .success)
        XCTAssertEqual(toast.duration, 4.0)
    }

    func testToastStyles() {
        for style in CraftToastStyle.allCases {
            let toastView = CraftToast(
                message: "Test message",
                title: "Alert",
                style: style
            )
            XCTAssertEqual(toastView.style, style)
            XCTAssertEqual(toastView.title, "Alert")
            XCTAssertEqual(toastView.message, "Test message")
            XCTAssertNotNil(toastView.body)
        }
    }

    func testToastViewModifier() {
        var isPresented = true
        let view = Text("Host View")
            .craftToast(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                message: "Quick notification",
                style: .info,
                position: .top
            )
        XCTAssertNotNil(view)
    }

    // MARK: - CraftBottomSheet Tests

    func testBottomSheetDetents() {
        let mediumDetent = CraftSheetDetent.medium
        let largeDetent = CraftSheetDetent.large
        let customFraction = CraftSheetDetent.fraction(0.35)
        let customHeight = CraftSheetDetent.height(280)

        XCTAssertEqual(mediumDetent, .medium)
        XCTAssertEqual(largeDetent, .large)
        XCTAssertEqual(customFraction, .fraction(0.35))
        XCTAssertEqual(customHeight, .height(280))
    }

    func testBottomSheetViewAndModifier() {
        var isPresented = true
        let sheet = CraftBottomSheet(
            isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
            title: "Options"
        ) {
            Text("Sheet Content")
        }
        XCTAssertEqual(sheet.title, "Options")
        XCTAssertNotNil(sheet.body)

        let hostView = Text("Host View")
            .craftBottomSheet(isPresented: Binding(get: { isPresented }, set: { isPresented = $0 })) {
                Text("Content inside modifier")
            }
        XCTAssertNotNil(hostView)
    }

    // MARK: - CraftDialog Tests

    func testDialogInitAndActions() {
        var confirmed = false
        var cancelled = false

        let dialog = CraftDialog(
            title: "Delete Deck?",
            message: "This action cannot be undone.",
            iconName: "trash.fill",
            primaryButtonTitle: "Delete",
            primaryButtonVariant: .danger,
            primaryAction: { confirmed = true },
            cancelButtonTitle: "Cancel",
            cancelAction: { cancelled = true }
        )

        XCTAssertEqual(dialog.title, "Delete Deck?")
        XCTAssertEqual(dialog.message, "This action cannot be undone.")
        XCTAssertEqual(dialog.iconName, "trash.fill")
        XCTAssertEqual(dialog.primaryButtonTitle, "Delete")
        XCTAssertEqual(dialog.primaryButtonVariant, .danger)
        XCTAssertEqual(dialog.cancelButtonTitle, "Cancel")
        XCTAssertNotNil(dialog.body)

        dialog.primaryAction()
        XCTAssertTrue(confirmed)

        dialog.cancelAction?()
        XCTAssertTrue(cancelled)
    }

    func testDialogModifier() {
        var isPresented = true
        let view = Text("Host View")
            .craftDialog(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                title: "Confirm Action",
                message: "Are you sure?",
                primaryButtonTitle: "Yes",
                primaryAction: { }
            )
        XCTAssertNotNil(view)
    }

    func testDialogWithoutCancelButton() {
        let dialog = CraftDialog(
            title: "Information",
            message: "Operation completed successfully.",
            primaryButtonTitle: "OK",
            primaryAction: { },
            cancelButtonTitle: nil
        )
        XCTAssertNil(dialog.cancelButtonTitle)
        XCTAssertNil(dialog.cancelAction)
        XCTAssertNotNil(dialog.body)
    }

    func testToastItemBinding() {
        var toastData: CraftToastData? = CraftToastData(message: "Item toast")
        let view = Text("Host View")
            .craftToast(item: Binding(get: { toastData }, set: { toastData = $0 }))
        XCTAssertNotNil(view)
    }
}
