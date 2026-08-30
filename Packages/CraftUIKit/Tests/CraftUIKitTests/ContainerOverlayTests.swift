#if canImport(XCTest)
import XCTest
#endif
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

    func testCardGlassStyle() {
        let card = CraftCard(style: .glass, isPressable: false) {
            Text("Frosted Glass Content")
        }
        XCTAssertEqual(card.style, .glass)
        XCTAssertEqual(card.style.surfaceStyle, .glass)
        XCTAssertNotNil(card.body)
    }

    func testCardSurfaceStyleMapping() {
        XCTAssertEqual(CraftCardStyle.flat.surfaceStyle, .flat)
        XCTAssertEqual(CraftCardStyle.elevated.surfaceStyle, .elevated)
        XCTAssertEqual(CraftCardStyle.outlined.surfaceStyle, .outlined)
        XCTAssertEqual(CraftCardStyle.tactile3D.surfaceStyle, .tactile3D)
        XCTAssertEqual(CraftCardStyle.glass.surfaceStyle, .glass)
        XCTAssertNil(CraftCardStyle.gradient.surfaceStyle)

        XCTAssertEqual(CraftCardStyle(surfaceStyle: .flat), .flat)
        XCTAssertEqual(CraftCardStyle(surfaceStyle: .elevated), .elevated)
        XCTAssertEqual(CraftCardStyle(surfaceStyle: .outlined), .outlined)
        XCTAssertEqual(CraftCardStyle(surfaceStyle: .tactile3D), .tactile3D)
        XCTAssertEqual(CraftCardStyle(surfaceStyle: .glass), .glass)
    }

    func testCardSurfaceStyleConvenienceInit() {
        let card = CraftCard(surfaceStyle: .glass, isPressable: true) {
            Text("Surface Style Card")
        }
        XCTAssertEqual(card.style, .glass)
        XCTAssertTrue(card.isPressable)
        XCTAssertNotNil(card.body)
    }

    func testCardCustomSolidTint() {
        let card = CraftCard(style: .glass, customTint: .purple) {
            Text("Tinted Glass")
        }
        XCTAssertEqual(card.style, .glass)
        XCTAssertEqual(card.customTint, .purple)
        XCTAssertNotNil(card.body)
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

    func testCardCustomGradient() {
        let gradient = LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let card = CraftCard(
            style: .gradient,
            customGradient: gradient
        ) {
            Text("Gradient Card")
        }
        XCTAssertEqual(card.style, .gradient)
        XCTAssertNotNil(card.customGradient)
        XCTAssertNotNil(card.body)
    }

    func testCardTactile3DStyle() {
        var tapped = false
        let card = CraftCard(style: .tactile3D, isPressable: true, action: {
            tapped = true
        }) {
            Text("Tactile 3D Card")
        }
        XCTAssertEqual(card.style, .tactile3D)
        XCTAssertTrue(card.isPressable)
        XCTAssertNotNil(card.body)
        card.action?()
        XCTAssertTrue(tapped)
    }

    func testCardTactile3DNonPressable() {
        let card = CraftCard(style: .tactile3D, isPressable: false) {
            Text("Non-pressable Tactile 3D")
        }
        XCTAssertEqual(card.style, .tactile3D)
        XCTAssertFalse(card.isPressable)
        XCTAssertNotNil(card.body)
    }

    func testTactileCardButtonStyle() {
        let buttonStyle = CraftTactileCardButtonStyle(depth: 4, radius: 16, bottomColor: .gray)
        XCTAssertEqual(buttonStyle.depth, 4)
        XCTAssertEqual(buttonStyle.radius, 16)
        let button = Button("Tactile Button") {}
            .buttonStyle(buttonStyle)
        XCTAssertNotNil(button)
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
        XCTAssertEqual(ringNormal.accessibilityLabel, "Progress")
        XCTAssertNotNil(ringNormal.body)
    }

    func testProgressRingCustomAccessibilityLabel() {
        let ring = CraftProgressRing(
            progress: 0.5,
            accessibilityLabel: "Daily Mastery Target"
        ) {
            Text("50%")
        }
        XCTAssertEqual(ring.accessibilityLabel, "Daily Mastery Target")
        XCTAssertNotNil(ring.body)
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

    func testListRowLocalization() {
        var actionTriggered = false
        let row = CraftListRow(
            title: LocalizedStringKey("row_title_key"),
            subtitle: LocalizedStringKey("row_subtitle_key"),
            iconName: "book.fill",
            showChevron: true,
            action: { actionTriggered = true }
        ) {
            Text("Active")
        }
        XCTAssertEqual(row.title, "")
        XCTAssertNil(row.subtitle)
        XCTAssertEqual(row.iconName, "book.fill")
        XCTAssertTrue(row.showChevron)
        XCTAssertNotNil(row.body)

        row.action?()
        XCTAssertTrue(actionTriggered)
    }

    // MARK: - CraftEmptyState Tests

    func testEmptyStateWithCraftSymbol() {
        var buttonTapped = false
        let emptyState = CraftEmptyState(
            symbol: .study,
            title: "No Study Cards",
            message: "Create your first vocabulary card to start reviewing.",
            buttonTitle: "Add Word",
            buttonSymbol: .add,
            buttonAction: { buttonTapped = true }
        )

        XCTAssertEqual(emptyState.title, "No Study Cards")
        XCTAssertEqual(emptyState.message, "Create your first vocabulary card to start reviewing.")
        XCTAssertEqual(emptyState.iconName, "character.book.closed")
        XCTAssertEqual(emptyState.buttonTitle, "Add Word")
        XCTAssertEqual(emptyState.buttonIcon, "plus")
        XCTAssertNotNil(emptyState.body)

        emptyState.buttonAction?()
        XCTAssertTrue(buttonTapped)
    }

    func testDefaultEmptyStateIllustrationWithSymbol() {
        let illustration = CraftDefaultEmptyStateIllustration(symbol: .bookmark)
        XCTAssertEqual(illustration.iconName, "bookmark")
        XCTAssertNotNil(illustration.body)
    }

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

    func testDefaultEmptyStateIllustrationView() {
        let illustration = CraftDefaultEmptyStateIllustration(iconName: "star.fill")
        XCTAssertEqual(illustration.iconName, "star.fill")
        XCTAssertNotNil(illustration.body)
    }

    func testEmptyStateLocalization() {
        var buttonTapped = false
        let emptyState = CraftEmptyState(
            iconName: "tray.fill",
            title: LocalizedStringKey("empty_title_key"),
            message: LocalizedStringKey("empty_message_key"),
            buttonTitle: LocalizedStringKey("empty_action_key"),
            buttonIcon: "plus",
            buttonAction: { buttonTapped = true }
        )

        XCTAssertEqual(emptyState.title, "")
        XCTAssertNil(emptyState.message)
        XCTAssertEqual(emptyState.iconName, "tray.fill")
        XCTAssertNil(emptyState.buttonTitle)
        XCTAssertEqual(emptyState.buttonIcon, "plus")
        XCTAssertNotNil(emptyState.body)

        emptyState.buttonAction?()
        XCTAssertTrue(buttonTapped)
    }

    // MARK: - CraftShimmerModifier Tests

    func testShimmerModifier() {
        let shimmeringView = Text("Loading Skeleton")
            .craftShimmer(isActive: true, duration: 2.0, bounce: true)
        XCTAssertNotNil(shimmeringView)

        let inactiveView = Text("Static Skeleton")
            .craftShimmer(isActive: false)
        XCTAssertNotNil(inactiveView)
    }

    // MARK: - CraftToast Tests

    func testToastDataInit() {
        let toast = CraftToastData(
            title: "Saved",
            message: "Word added to favorites",
            iconName: "heart.fill",
            style: .success,
            surfaceStyle: .glass,
            duration: 4.0
        )
        XCTAssertEqual(toast.title, "Saved")
        XCTAssertEqual(toast.message, "Word added to favorites")
        XCTAssertEqual(toast.iconName, "heart.fill")
        XCTAssertEqual(toast.style, .success)
        XCTAssertEqual(toast.surfaceStyle, .glass)
        XCTAssertEqual(toast.duration, 4.0)
    }

    func testToastStyles() {
        for style in CraftToastStyle.allCases {
            let toastView = CraftToast(
                message: "Test message",
                title: "Alert",
                style: style,
                surfaceStyle: .elevated
            )
            XCTAssertEqual(toastView.style, style)
            XCTAssertEqual(toastView.title, "Alert")
            XCTAssertEqual(toastView.message, "Test message")
            XCTAssertEqual(toastView.surfaceStyle, .elevated)
            XCTAssertNotNil(toastView.body)
        }
    }

    func testToastGlassSurfaceStyle() {
        let toast = CraftToast(
            message: "Glass toast notification",
            title: "Glass Title",
            style: .info,
            surfaceStyle: .glass
        )
        XCTAssertEqual(toast.surfaceStyle, .glass)
        XCTAssertNotNil(toast.body)
    }

    func testToastLocalizedStringKeyInit() {
        let toast = CraftToast(
            messageKey: LocalizedStringKey("toast_msg_key"),
            titleKey: LocalizedStringKey("toast_title_key"),
            style: .warning,
            surfaceStyle: .glass
        )
        XCTAssertEqual(toast.style, .warning)
        XCTAssertEqual(toast.surfaceStyle, .glass)
        XCTAssertNotNil(toast.body)
    }

    func testToastViewModifier() {
        var isPresented = true
        let view = Text("Host View")
            .craftToast(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                message: "Quick notification",
                style: .info,
                surfaceStyle: .glass,
                position: .top
            )
        XCTAssertNotNil(view)
    }

    func testToastItemBinding() {
        var toastData: CraftToastData? = CraftToastData(message: "Item toast", surfaceStyle: .glass)
        let view = Text("Host View")
            .craftToast(item: Binding(get: { toastData }, set: { toastData = $0 }))
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
            title: "Options",
            style: .glass
        ) {
            Text("Sheet Content")
        }
        XCTAssertEqual(sheet.title, "Options")
        XCTAssertEqual(sheet.style, .glass)
        XCTAssertNotNil(sheet.body)

        let hostView = Text("Host View")
            .craftBottomSheet(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                style: .glass
            ) {
                Text("Content inside modifier")
            }
        XCTAssertNotNil(hostView)
    }

    func testBottomSheetLocalizedStringKeyInit() {
        var isPresented = true
        let sheet = CraftBottomSheet(
            isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
            titleKey: LocalizedStringKey("sheet_title_key"),
            style: .elevated
        ) {
            Text("Localized Sheet Content")
        }
        XCTAssertNil(sheet.title)
        XCTAssertEqual(sheet.style, .elevated)
        XCTAssertNotNil(sheet.body)

        let hostView = Text("Host View")
            .craftBottomSheet(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                titleKey: LocalizedStringKey("sheet_title_key"),
                style: .glass
            ) {
                Text("Sheet inside modifier")
            }
        XCTAssertNotNil(hostView)
    }

    func testBottomSheetSurfaceStyles() {
        var isPresented = true
        let styles: [CraftSurfaceStyle] = [.elevated, .glass, .outlined, .flat]
        for style in styles {
            let sheet = CraftBottomSheet(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                title: "Style \(style.rawValue)",
                style: style
            ) {
                Text("Content")
            }
            XCTAssertEqual(sheet.style, style)
            XCTAssertNotNil(sheet.body)
        }
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
            cancelAction: { cancelled = true },
            style: .glass
        )

        XCTAssertEqual(dialog.title, "Delete Deck?")
        XCTAssertEqual(dialog.message, "This action cannot be undone.")
        XCTAssertEqual(dialog.iconName, "trash.fill")
        XCTAssertEqual(dialog.primaryButtonTitle, "Delete")
        XCTAssertEqual(dialog.primaryButtonVariant, .danger)
        XCTAssertEqual(dialog.cancelButtonTitle, "Cancel")
        XCTAssertEqual(dialog.style, .glass)
        XCTAssertNotNil(dialog.body)

        dialog.primaryAction()
        XCTAssertTrue(confirmed)

        dialog.cancelAction?()
        XCTAssertTrue(cancelled)
    }

    func testDialogDefaultLocalizedButtons() {
        let dialog = CraftDialog(
            title: "Default Actions",
            primaryAction: {}
        )
        XCTAssertEqual(dialog.primaryButtonTitle, CraftLocalized.string("craft.common.action.confirm"))
        XCTAssertEqual(dialog.cancelButtonTitle, CraftLocalized.string("craft.common.action.cancel"))
        XCTAssertEqual(dialog.style, .elevated)
        XCTAssertNotNil(dialog.body)
    }

    func testDialogLocalizedStringKeyInit() {
        var confirmed = false
        var cancelled = false

        let dialog = CraftDialog(
            titleKey: LocalizedStringKey("dialog_title_key"),
            messageKey: LocalizedStringKey("dialog_msg_key"),
            iconName: "info.circle",
            primaryButtonTitleKey: LocalizedStringKey("dialog_confirm_key"),
            primaryAction: { confirmed = true },
            cancelButtonTitleKey: LocalizedStringKey("dialog_cancel_key"),
            cancelAction: { cancelled = true },
            style: .glass
        )
        XCTAssertEqual(dialog.title, "")
        XCTAssertNil(dialog.message)
        XCTAssertEqual(dialog.style, .glass)
        XCTAssertNotNil(dialog.body)

        dialog.primaryAction()
        XCTAssertTrue(confirmed)

        dialog.cancelAction?()
        XCTAssertTrue(cancelled)
    }

    func testDialogSurfaceStyles() {
        for style in CraftSurfaceStyle.allCases {
            let dialog = CraftDialog(
                title: "Style \(style.rawValue)",
                primaryAction: {},
                style: style
            )
            XCTAssertEqual(dialog.style, style)
            XCTAssertNotNil(dialog.body)
        }
    }

    func testDialogBackdropOptions() {
        XCTAssertEqual(CraftDialogBackdrop.allCases.count, 2)
        XCTAssertTrue(CraftDialogBackdrop.allCases.contains(.dimmed))
        XCTAssertTrue(CraftDialogBackdrop.allCases.contains(.material))
    }

    func testDialogModifierWithBackdropAndStyle() {
        var isPresented = true
        let view = Text("Host View")
            .craftDialog(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                title: "Confirm Action",
                message: "Are you sure?",
                primaryButtonTitle: "Yes",
                primaryAction: { },
                style: .glass,
                backdrop: .material
            )
        XCTAssertNotNil(view)
    }

    func testDialogModifierWithLocalizedKeys() {
        var isPresented = true
        let view = Text("Host View")
            .craftDialog(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                titleKey: LocalizedStringKey("dialog_title"),
                messageKey: LocalizedStringKey("dialog_msg"),
                primaryButtonTitleKey: LocalizedStringKey("dialog_confirm"),
                primaryAction: { },
                cancelButtonTitleKey: LocalizedStringKey("dialog_cancel"),
                cancelAction: { },
                style: .glass,
                backdrop: .material
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

    func testDialogButtonLayoutEnumCases() {
        XCTAssertEqual(CraftDialogButtonLayout.allCases.count, 3)
        XCTAssertTrue(CraftDialogButtonLayout.allCases.contains(.automatic))
        XCTAssertTrue(CraftDialogButtonLayout.allCases.contains(.horizontal))
        XCTAssertTrue(CraftDialogButtonLayout.allCases.contains(.vertical))
    }

    func testDialogModifierSmartBackdropTapCallback() {
        var isPresented = true
        let modifier = CraftDialogModifier(
            isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
            backdrop: .dimmed,
            dismissOnBackdropTap: true,
            onBackdropDismiss: {}
        ) {
            Text("Dialog Body")
        }

        XCTAssertTrue(modifier.dismissOnBackdropTap)
        XCTAssertNotNil(modifier.onBackdropDismiss)
        modifier.onBackdropDismiss?()
        XCTAssertTrue(cancelled)
    }

    func testDialogButtonLayoutAndCustomIconColor() {
        let dialog = CraftDialog(
            title: "Test Layout",
            message: "Message",
            iconName: "bell.fill",
            iconColor: .orange,
            primaryButtonTitle: "Confirm",
            primaryButtonVariant: .primary,
            primaryAction: {},
            cancelButtonTitle: "Cancel",
            cancelButtonVariant: .outline,
            cancelAction: {},
            style: .elevated,
            buttonLayout: .horizontal
        )

        XCTAssertEqual(dialog.buttonLayout, .horizontal)
        XCTAssertEqual(dialog.iconColor, .orange)
        XCTAssertEqual(dialog.iconName, "bell.fill")
        XCTAssertEqual(dialog.cancelButtonVariant, .outline)
        XCTAssertNotNil(dialog.body)
    }

    func testDialogVerticalButtonLayout() {
        let dialog = CraftDialog(
            title: "Vertical Layout",
            primaryAction: {},
            buttonLayout: .vertical
        )

        XCTAssertEqual(dialog.buttonLayout, .vertical)
        XCTAssertNil(dialog.cancelButtonVariant)
        XCTAssertNotNil(dialog.body)
    }

    func testDialogCustomCancelButtonVariant() {
        let dialog = CraftDialog(
            title: "Custom Cancel",
            primaryAction: {},
            cancelButtonVariant: .danger
        )

        XCTAssertEqual(dialog.cancelButtonVariant, .danger)
        XCTAssertNotNil(dialog.body)
    }

    func testDialogLocalizedStringKeyWithNewProperties() {
        let dialog = CraftDialog(
            titleKey: LocalizedStringKey("dialog_title"),
            messageKey: LocalizedStringKey("dialog_msg"),
            iconName: "trash.fill",
            iconColor: .red,
            primaryButtonTitleKey: LocalizedStringKey("dialog_confirm"),
            primaryButtonVariant: .danger,
            primaryAction: {},
            cancelButtonTitleKey: LocalizedStringKey("dialog_cancel"),
            cancelButtonVariant: .ghost,
            cancelAction: {},
            style: .glass,
            buttonLayout: .vertical
        )

        XCTAssertEqual(dialog.buttonLayout, .vertical)
        XCTAssertEqual(dialog.iconColor, .red)
        XCTAssertEqual(dialog.cancelButtonVariant, .ghost)
        XCTAssertNotNil(dialog.body)
    }

    func testDialogCustomContentWithNewProperties() {
        let dialog = CraftDialog(
            title: "Custom Content",
            iconColor: .blue,
            primaryAction: {},
            cancelButtonVariant: .secondary,
            buttonLayout: .automatic
        ) {
            Text("Extra details")
        }

        XCTAssertEqual(dialog.buttonLayout, .automatic)
        XCTAssertEqual(dialog.iconColor, .blue)
        XCTAssertEqual(dialog.cancelButtonVariant, .secondary)
        XCTAssertNotNil(dialog.body)
    }

    // MARK: - View.craftDialog Extension Tests

    func testViewCraftDialogStringExtensionWithNewParameters() {
        var isPresented = true
        var cancelled = false
        let view = Text("Host View")
            .craftDialog(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                title: "Warning",
                message: "Delete this permanently?",
                iconName: "trash.fill",
                iconColor: .red,
                primaryButtonTitle: "Delete",
                primaryButtonVariant: .danger,
                primaryAction: {},
                cancelButtonTitle: "Cancel",
                cancelButtonVariant: .ghost,
                cancelAction: { cancelled = true },
                style: .elevated,
                buttonLayout: .vertical,
                backdrop: .material,
                dismissOnBackdropTap: false
            )
        XCTAssertNotNil(view)
        XCTAssertFalse(cancelled)
    }

    func testViewCraftDialogLocalizedExtensionWithNewParameters() {
        var isPresented = true
        var cancelled = false
        let view = Text("Host View")
            .craftDialog(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                titleKey: LocalizedStringKey("dialog_title"),
                messageKey: LocalizedStringKey("dialog_msg"),
                iconName: "bell.fill",
                iconColor: .orange,
                primaryButtonTitleKey: LocalizedStringKey("dialog_confirm"),
                primaryButtonVariant: .primary,
                primaryAction: {},
                cancelButtonTitleKey: LocalizedStringKey("dialog_cancel"),
                cancelButtonVariant: .outline,
                cancelAction: { cancelled = true },
                style: .glass,
                buttonLayout: .horizontal,
                backdrop: .dimmed,
                dismissOnBackdropTap: true
            )
        XCTAssertNotNil(view)
        XCTAssertFalse(cancelled)
    }

    func testViewCraftDialogCustomContentExtensionWithNewParameters() {
        var isPresented = true
        var backdropDismissed = false
        let view = Text("Host View")
            .craftDialog(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                backdrop: .material,
                dismissOnBackdropTap: true,
                onBackdropDismiss: { backdropDismissed = true }
            ) {
                Text("Custom Modal Dialog")
            }
        XCTAssertNotNil(view)
        XCTAssertFalse(backdropDismissed)
    }

    // MARK: - Overlay Hierarchy & Isolation Tests

    func testOverlayDoesNotCorruptHostHierarchy() {
        var isToastPresented = true
        let toastView = Text("Host Screen")
            .craftToast(
                isPresented: Binding(get: { isToastPresented }, set: { isToastPresented = $0 }),
                message: "Notification",
                position: .top
            )
        XCTAssertNotNil(toastView)

        var isSheetPresented = true
        let sheetView = Text("Host Screen")
            .craftBottomSheet(
                isPresented: Binding(get: { isSheetPresented }, set: { isSheetPresented = $0 }),
                title: "Bottom Sheet"
            ) {
                Text("Sheet Body")
            }
        XCTAssertNotNil(sheetView)

        var isDialogPresented = true
        let dialogView = Text("Host Screen")
            .craftDialog(
                isPresented: Binding(get: { isDialogPresented }, set: { isDialogPresented = $0 }),
                title: "Alert Dialog",
                primaryAction: {}
            )
        XCTAssertNotNil(dialogView)

        // Test modifiers with isPresented = true and false
        for presented in [true, false] {
            var state = presented
            let toastMod = CraftToastModifier(
                isPresented: Binding(get: { state }, set: { state = $0 }),
                data: CraftToastData(message: "Toast isolation test"),
                position: .bottom
            )
            let toastModifiedView = Text("Host").modifier(toastMod)
            XCTAssertNotNil(toastModifiedView)

            let sheetMod = CraftBottomSheetModifier(
                isPresented: Binding(get: { state }, set: { state = $0 }),
                title: "Sheet Title",
                detents: [.medium, .large],
                style: .glass,
                onDismiss: nil
            ) {
                Text("Sheet Content")
            }
            let sheetModifiedView = Text("Host").modifier(sheetMod)
            XCTAssertNotNil(sheetModifiedView)

            let dialogMod = CraftDialogModifier(
                isPresented: Binding(get: { state }, set: { state = $0 }),
                backdrop: .material,
                dismissOnBackdropTap: true,
                onBackdropDismiss: nil
            ) {
                Text("Dialog Content")
            }
            let dialogModifiedView = Text("Host").modifier(dialogMod)
            XCTAssertNotNil(dialogModifiedView)
        }
    }
}
