import SwiftUI

// MARK: - Dialog Backdrop

/// Backdrop appearance styles for modal dialog overlays.
public enum CraftDialogBackdrop: Sendable, CaseIterable {
    /// Standard semi-transparent dimmed overlay.
    case dimmed
    /// Frosted ultra-thin material blur backdrop with subtle dimming.
    case material
}

// MARK: - Dialog Button Layout

/// Layout arrangement options for dialog action buttons.
public enum CraftDialogButtonLayout: Sendable, CaseIterable {
    /// Automatically selects horizontal or vertical layout based on available space and labels.
    case automatic
    /// Forces side-by-side horizontal button layout.
    case horizontal
    /// Forces stacked vertical button layout.
    case vertical
}

// MARK: - CraftDialog Component

/// A standardized modal dialog for confirmations, alerts, and critical user decisions,
/// supporting theme-driven surfaces (.elevated, .outlined, .glass), localization, and custom backdrops.
public struct CraftDialog<CustomContent: View>: View {
    @Environment(\.craftTheme) private var theme
    @State private var hasAppeared: Bool = false

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let messageKey: LocalizedStringKey?
    private let rawMessage: String?
    private let primaryButtonTitleKey: LocalizedStringKey?
    private let rawPrimaryButtonTitle: String?
    private let cancelButtonTitleKey: LocalizedStringKey?
    private let rawCancelButtonTitle: String?

    public var title: String { rawTitle ?? "" }
    public var message: String? { rawMessage }
    public var primaryButtonTitle: String { rawPrimaryButtonTitle ?? CraftLocalized.string("craft.common.action.confirm") }
    public var cancelButtonTitle: String? { rawCancelButtonTitle }

    public let iconName: String?
    public let iconColor: Color?
    public let primaryButtonVariant: CraftButtonVariant
    public let primaryAction: () -> Void
    public let cancelButtonVariant: CraftButtonVariant?
    public let cancelAction: (() -> Void)?
    public let style: CraftSurfaceStyle
    public let buttonLayout: CraftDialogButtonLayout
    public let customContent: CustomContent

    private var hasCancelButton: Bool {
        cancelButtonTitleKey != nil || rawCancelButtonTitle != nil
    }

    // MARK: - String Initializer

    public init(
        title: String,
        message: String? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        primaryButtonTitle: String = CraftLocalized.string("craft.common.action.confirm"),
        primaryButtonVariant: CraftButtonVariant = .primary,
        primaryAction: @escaping () -> Void,
        cancelButtonTitle: String? = CraftLocalized.string("craft.common.action.cancel"),
        cancelButtonVariant: CraftButtonVariant? = nil,
        cancelAction: (() -> Void)? = nil,
        style: CraftSurfaceStyle = .elevated,
        buttonLayout: CraftDialogButtonLayout = .automatic,
        @ViewBuilder customContent: () -> CustomContent
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.messageKey = nil
        self.rawMessage = message
        self.iconName = iconName
        self.iconColor = iconColor
        self.primaryButtonTitleKey = nil
        self.rawPrimaryButtonTitle = primaryButtonTitle
        self.primaryButtonVariant = primaryButtonVariant
        self.primaryAction = primaryAction
        self.cancelButtonTitleKey = nil
        self.rawCancelButtonTitle = cancelButtonTitle
        self.cancelButtonVariant = cancelButtonVariant
        self.cancelAction = cancelAction
        self.style = style
        self.buttonLayout = buttonLayout
        self.customContent = customContent()
    }

    // MARK: - LocalizedStringKey Initializer

    public init(
        titleKey: LocalizedStringKey,
        messageKey: LocalizedStringKey? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        primaryButtonTitleKey: LocalizedStringKey? = nil,
        primaryButtonVariant: CraftButtonVariant = .primary,
        primaryAction: @escaping () -> Void,
        cancelButtonTitleKey: LocalizedStringKey? = nil,
        cancelButtonVariant: CraftButtonVariant? = nil,
        cancelAction: (() -> Void)? = nil,
        style: CraftSurfaceStyle = .elevated,
        buttonLayout: CraftDialogButtonLayout = .automatic,
        @ViewBuilder customContent: () -> CustomContent
    ) {
        self.titleKey = titleKey
        self.rawTitle = nil
        self.messageKey = messageKey
        self.rawMessage = nil
        self.iconName = iconName
        self.iconColor = iconColor
        self.primaryButtonTitleKey = primaryButtonTitleKey
        self.rawPrimaryButtonTitle = nil
        self.primaryButtonVariant = primaryButtonVariant
        self.primaryAction = primaryAction
        self.cancelButtonTitleKey = cancelButtonTitleKey
        self.rawCancelButtonTitle = nil
        self.cancelButtonVariant = cancelButtonVariant
        self.cancelAction = cancelAction
        self.style = style
        self.buttonLayout = buttonLayout
        self.customContent = customContent()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radii.xl)

        VStack(spacing: theme.spacing.lg) {
            // Icon Badge
            if let iconName {
                let badgeColor = iconColor ?? (primaryButtonVariant == .danger ? theme.colors.statusDanger : theme.colors.brandPrimary)

                ZStack {
                    Circle()
                        .fill(badgeColor.opacity(0.12))
                        .frame(width: 56, height: 56)

                    CraftIcon(iconName, size: .lg, color: badgeColor)
                        .symbolEffect(.bounce.byLayer, value: hasAppeared)
                }
            }

            // Title and Message
            VStack(spacing: theme.spacing.xs) {
                if let titleKey {
                    Text(titleKey)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                } else if let rawTitle {
                    Text(rawTitle)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                }

                if let messageKey {
                    CraftText(
                        messageKey,
                        style: .bodyMedium,
                        color: theme.colors.textSecondary,
                        textAlignment: .center
                    )
                } else if let rawMessage, !rawMessage.isEmpty {
                    CraftText(
                        rawMessage,
                        style: .bodyMedium,
                        color: theme.colors.textSecondary,
                        textAlignment: .center
                    )
                }
            }

            // Custom Content Slot
            customContent

            // Action Buttons
            dialogActions
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: 340)
        .background(dialogBackground(shape: shape))
        .clipShape(shape)
        .overlay(dialogBorder(shape: shape))
        .modifier(DialogShadowModifier(style: style, theme: theme))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .sensoryFeedback(.warning, trigger: hasAppeared) { _, _ in
            primaryButtonVariant == .danger
        }
        .onAppear {
            hasAppeared = true
        }
        .padding(.horizontal, theme.spacing.lg)
    }

    @ViewBuilder
    private var primaryButtonView: some View {
        if let primaryButtonTitleKey {
            CraftButton(
                primaryButtonTitleKey,
                variant: primaryButtonVariant,
                size: .md,
                action: primaryAction
            )
            .frame(maxWidth: .infinity)
        } else {
            CraftButton(
                primaryButtonTitle,
                variant: primaryButtonVariant,
                size: .md,
                action: primaryAction
            )
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func cancelButtonView(variant: CraftButtonVariant) -> some View {
        if let cancelButtonTitleKey {
            CraftButton(
                cancelButtonTitleKey,
                variant: variant,
                size: .md,
                action: {
                    cancelAction?()
                }
            )
            .frame(maxWidth: .infinity)
        } else if let cancelButtonTitle {
            CraftButton(
                cancelButtonTitle,
                variant: variant,
                size: .md,
                action: {
                    cancelAction?()
                }
            )
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var horizontalActions: some View {
        if hasCancelButton {
            HStack(spacing: theme.spacing.sm) {
                cancelButtonView(variant: cancelButtonVariant ?? .outline)
                primaryButtonView
            }
            .frame(maxWidth: .infinity)
        } else {
            primaryButtonView
        }
    }

    @ViewBuilder
    private var verticalActions: some View {
        VStack(spacing: theme.spacing.sm) {
            primaryButtonView
            if hasCancelButton {
                cancelButtonView(variant: cancelButtonVariant ?? .ghost)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var dialogActions: some View {
        switch buttonLayout {
        case .automatic:
            if hasCancelButton {
                ViewThatFits(in: .horizontal) {
                    horizontalActions
                    verticalActions
                }
            } else {
                primaryButtonView
            }
        case .horizontal:
            horizontalActions
        case .vertical:
            verticalActions
        }
    }

    @ViewBuilder
    private func dialogBackground(shape: RoundedRectangle) -> some View {
        switch style {
        case .glass:
            ZStack {
                shape.fill(.ultraThinMaterial)
                shape.fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
            }
        case .outlined, .elevated, .tactile3D:
            shape.fill(theme.colors.surfaceCard)
        case .flat:
            shape.fill(theme.colors.surfaceSubtle)
        }
    }

    @ViewBuilder
    private func dialogBorder(shape: RoundedRectangle) -> some View {
        switch style {
        case .glass:
            ZStack {
                shape.strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                shape.strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
            }
        case .outlined:
            shape.strokeBorder(theme.colors.borderDefault, lineWidth: 1)
        case .elevated:
            shape.strokeBorder(
                LinearGradient(
                    stops: [
                        .init(color: .craftDynamic(light: Color.white.opacity(0.8), dark: Color.white.opacity(0.18)), location: 0.0),
                        .init(color: theme.colors.borderDefault.opacity(0.4), location: 0.5),
                        .init(color: theme.colors.hairline, location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        case .flat, .tactile3D:
            EmptyView()
        }
    }
}

private struct DialogShadowModifier: ViewModifier {
    let style: CraftSurfaceStyle
    let theme: CraftTheme

    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            content.craftShadow(theme.shadows.xl)
        case .glass:
            content.craftShadow(theme.shadows.lg)
        case .flat, .outlined, .tactile3D:
            content
        }
    }
}

// MARK: - Convenience Inits

public extension CraftDialog where CustomContent == EmptyView {
    init(
        title: String,
        message: String? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        primaryButtonTitle: String = CraftLocalized.string("craft.common.action.confirm"),
        primaryButtonVariant: CraftButtonVariant = .primary,
        primaryAction: @escaping () -> Void,
        cancelButtonTitle: String? = CraftLocalized.string("craft.common.action.cancel"),
        cancelButtonVariant: CraftButtonVariant? = nil,
        cancelAction: (() -> Void)? = nil,
        style: CraftSurfaceStyle = .elevated,
        buttonLayout: CraftDialogButtonLayout = .automatic
    ) {
        self.init(
            title: title,
            message: message,
            iconName: iconName,
            iconColor: iconColor,
            primaryButtonTitle: primaryButtonTitle,
            primaryButtonVariant: primaryButtonVariant,
            primaryAction: primaryAction,
            cancelButtonTitle: cancelButtonTitle,
            cancelButtonVariant: cancelButtonVariant,
            cancelAction: cancelAction,
            style: style,
            buttonLayout: buttonLayout
        ) {
            EmptyView()
        }
    }

    init(
        titleKey: LocalizedStringKey,
        messageKey: LocalizedStringKey? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        primaryButtonTitleKey: LocalizedStringKey? = nil,
        primaryButtonVariant: CraftButtonVariant = .primary,
        primaryAction: @escaping () -> Void,
        cancelButtonTitleKey: LocalizedStringKey? = nil,
        cancelButtonVariant: CraftButtonVariant? = nil,
        cancelAction: (() -> Void)? = nil,
        style: CraftSurfaceStyle = .elevated,
        buttonLayout: CraftDialogButtonLayout = .automatic
    ) {
        self.init(
            titleKey: titleKey,
            messageKey: messageKey,
            iconName: iconName,
            iconColor: iconColor,
            primaryButtonTitleKey: primaryButtonTitleKey,
            primaryButtonVariant: primaryButtonVariant,
            primaryAction: primaryAction,
            cancelButtonTitleKey: cancelButtonTitleKey,
            cancelButtonVariant: cancelButtonVariant,
            cancelAction: cancelAction,
            style: style,
            buttonLayout: buttonLayout
        ) {
            EmptyView()
        }
    }
}

// MARK: - Dialog View Modifier

public struct CraftDialogModifier<DialogBody: View>: ViewModifier {
    @Environment(\.craftTheme) private var theme
    @Binding public var isPresented: Bool
    public let backdrop: CraftDialogBackdrop
    public let dismissOnBackdropTap: Bool
    public let onBackdropDismiss: (() -> Void)?
    public let dialogContent: DialogBody

    public init(
        isPresented: Binding<Bool>,
        backdrop: CraftDialogBackdrop = .dimmed,
        dismissOnBackdropTap: Bool = true,
        onBackdropDismiss: (() -> Void)? = nil,
        @ViewBuilder dialogContent: () -> DialogBody
    ) {
        self._isPresented = isPresented
        self.backdrop = backdrop
        self.dismissOnBackdropTap = dismissOnBackdropTap
        self.onBackdropDismiss = onBackdropDismiss
        self.dialogContent = dialogContent()
    }

    public func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                // Backdrop
                Group {
                    switch backdrop {
                    case .dimmed:
                        Color.black.opacity(0.4)
                    case .material:
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(Color.black.opacity(0.25))
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    guard dismissOnBackdropTap else { return }
                    onBackdropDismiss?()
                    withAnimation(theme.animations.springSmooth) {
                        isPresented = false
                    }
                }
                .zIndex(999)

                // Dialog Content
                dialogContent
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .zIndex(1000)
            }
        }
    }
}

// MARK: - View Extensions

public extension View {
    /// Presents a standardized confirmation/alert modal dialog over this view.
    func craftDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        primaryButtonTitle: String = CraftLocalized.string("craft.common.action.confirm"),
        primaryButtonVariant: CraftButtonVariant = .primary,
        primaryAction: @escaping () -> Void,
        cancelButtonTitle: String? = CraftLocalized.string("craft.common.action.cancel"),
        cancelButtonVariant: CraftButtonVariant? = nil,
        cancelAction: (() -> Void)? = nil,
        style: CraftSurfaceStyle = .elevated,
        buttonLayout: CraftDialogButtonLayout = .automatic,
        backdrop: CraftDialogBackdrop = .dimmed,
        dismissOnBackdropTap: Bool? = nil
    ) -> some View {
        let resolvedDismissOnBackdropTap = dismissOnBackdropTap ?? (primaryButtonVariant != .danger)
        return modifier(
            CraftDialogModifier(
                isPresented: isPresented,
                backdrop: backdrop,
                dismissOnBackdropTap: resolvedDismissOnBackdropTap,
                onBackdropDismiss: cancelAction
            ) {
                CraftDialog(
                    title: title,
                    message: message,
                    iconName: iconName,
                    iconColor: iconColor,
                    primaryButtonTitle: primaryButtonTitle,
                    primaryButtonVariant: primaryButtonVariant,
                    primaryAction: {
                        primaryAction()
                        withAnimation {
                            isPresented.wrappedValue = false
                        }
                    },
                    cancelButtonTitle: cancelButtonTitle,
                    cancelButtonVariant: cancelButtonVariant,
                    cancelAction: cancelButtonTitle != nil ? {
                        cancelAction?()
                        withAnimation {
                            isPresented.wrappedValue = false
                        }
                    } : nil,
                    style: style,
                    buttonLayout: buttonLayout
                )
            }
        )
    }

    /// Presents a standardized localized confirmation/alert modal dialog over this view.
    func craftDialog(
        isPresented: Binding<Bool>,
        titleKey: LocalizedStringKey,
        messageKey: LocalizedStringKey? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        primaryButtonTitleKey: LocalizedStringKey? = nil,
        primaryButtonVariant: CraftButtonVariant = .primary,
        primaryAction: @escaping () -> Void,
        cancelButtonTitleKey: LocalizedStringKey? = nil,
        cancelButtonVariant: CraftButtonVariant? = nil,
        cancelAction: (() -> Void)? = nil,
        style: CraftSurfaceStyle = .elevated,
        buttonLayout: CraftDialogButtonLayout = .automatic,
        backdrop: CraftDialogBackdrop = .dimmed,
        dismissOnBackdropTap: Bool? = nil
    ) -> some View {
        let resolvedDismissOnBackdropTap = dismissOnBackdropTap ?? (primaryButtonVariant != .danger)
        return modifier(
            CraftDialogModifier(
                isPresented: isPresented,
                backdrop: backdrop,
                dismissOnBackdropTap: resolvedDismissOnBackdropTap,
                onBackdropDismiss: cancelAction
            ) {
                CraftDialog(
                    titleKey: titleKey,
                    messageKey: messageKey,
                    iconName: iconName,
                    iconColor: iconColor,
                    primaryButtonTitleKey: primaryButtonTitleKey,
                    primaryButtonVariant: primaryButtonVariant,
                    primaryAction: {
                        primaryAction()
                        withAnimation {
                            isPresented.wrappedValue = false
                        }
                    },
                    cancelButtonTitleKey: cancelButtonTitleKey,
                    cancelButtonVariant: cancelButtonVariant,
                    cancelAction: cancelButtonTitleKey != nil ? {
                        cancelAction?()
                        withAnimation {
                            isPresented.wrappedValue = false
                        }
                    } : nil,
                    style: style,
                    buttonLayout: buttonLayout
                )
            }
        )
    }

    /// Presents a custom modal dialog container over this view.
    func craftDialog<CustomContent: View>(
        isPresented: Binding<Bool>,
        backdrop: CraftDialogBackdrop = .dimmed,
        dismissOnBackdropTap: Bool = true,
        onBackdropDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> CustomContent
    ) -> some View {
        modifier(
            CraftDialogModifier(
                isPresented: isPresented,
                backdrop: backdrop,
                dismissOnBackdropTap: dismissOnBackdropTap,
                onBackdropDismiss: onBackdropDismiss,
                dialogContent: content
            )
        )
    }
}

#if canImport(PreviewsMacros)
#Preview("CraftDialog") {
    @Previewable @State var showConfirmation = false
    @Previewable @State var showDanger = false
    @Previewable @State var showInfo = false
    @Previewable @State var showGlass = false

    VStack(spacing: 16) {
        CraftButton("Standard Confirmation", variant: .primary, size: .md) {
            showConfirmation = true
        }
        CraftButton("Destructive (.danger)", variant: .danger, size: .md) {
            showDanger = true
        }
        CraftButton("Informational (Single Action)", variant: .outline, size: .md) {
            showInfo = true
        }
        CraftButton("Liquid Glass Dialog", variant: .secondary, size: .md, style: .glass) {
            showGlass = true
        }
    }
    .padding(24)
    .craftDialog(
        isPresented: $showConfirmation,
        title: "Save Vocabulary Set",
        message: "Are you sure you want to save changes to 'Advanced GRE Words'?",
        iconName: "checkmark.circle.fill",
        primaryButtonTitle: "Save Set",
        primaryButtonVariant: .primary,
        primaryAction: {},
        cancelButtonTitle: "Cancel",
        buttonLayout: .automatic
    )
    .craftDialog(
        isPresented: $showDanger,
        title: "Delete Study Deck?",
        message: "This operation is irreversible. All 140 cards and review progress will be permanently deleted.",
        iconName: "trash.fill",
        iconColor: .red,
        primaryButtonTitle: "Delete Forever",
        primaryButtonVariant: .danger,
        primaryAction: {},
        cancelButtonTitle: "Keep Deck",
        buttonLayout: .vertical,
        dismissOnBackdropTap: false
    )
    .craftDialog(
        isPresented: $showInfo,
        title: "Streak Milestone Reached!",
        message: "You've maintained your vocabulary study streak for 14 consecutive days.",
        iconName: "flame.fill",
        iconColor: .orange,
        primaryButtonTitle: "Continue",
        primaryButtonVariant: .primary,
        primaryAction: {},
        cancelButtonTitle: nil,
        buttonLayout: .automatic
    )
    .craftDialog(
        isPresented: $showGlass,
        title: "Liquid Glass Dialog",
        message: "Translucent backdrop with specular reflections and frosted glass surface.",
        iconName: "sparkles",
        iconColor: .cyan,
        primaryButtonTitle: "Explore Glass",
        primaryButtonVariant: .primary,
        primaryAction: {},
        cancelButtonTitle: "Dismiss",
        cancelButtonVariant: .ghost,
        style: .glass,
        buttonLayout: .automatic,
        backdrop: .material
    )
}
#endif
