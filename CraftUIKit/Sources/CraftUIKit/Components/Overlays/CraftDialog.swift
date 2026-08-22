import SwiftUI

// MARK: - CraftDialog Component

/// A standardized modal dialog for confirmations, alerts, and critical user decisions.
public struct CraftDialog<CustomContent: View>: View {
    @Environment(\.craftTheme) private var theme

    public let title: String
    public let message: String?
    public let iconName: String?
    public let primaryButtonTitle: String
    public let primaryButtonVariant: CraftButtonVariant
    public let primaryAction: () -> Void
    public let cancelButtonTitle: String?
    public let cancelAction: (() -> Void)?
    public let customContent: CustomContent

    public init(
        title: String,
        message: String? = nil,
        iconName: String? = nil,
        primaryButtonTitle: String = "Confirm",
        primaryButtonVariant: CraftButtonVariant = .primary,
        primaryAction: @escaping () -> Void,
        cancelButtonTitle: String? = "Cancel",
        cancelAction: (() -> Void)? = nil,
        @ViewBuilder customContent: () -> CustomContent
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.primaryButtonTitle = primaryButtonTitle
        self.primaryButtonVariant = primaryButtonVariant
        self.primaryAction = primaryAction
        self.cancelButtonTitle = cancelButtonTitle
        self.cancelAction = cancelAction
        self.customContent = customContent()
    }

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Icon Badge
            if let iconName {
                let badgeColor = primaryButtonVariant == .danger ? theme.colors.statusDanger : theme.colors.brandPrimary

                ZStack {
                    Circle()
                        .fill(badgeColor.opacity(0.12))
                        .frame(width: 56, height: 56)

                    CraftIcon(iconName, size: .lg, color: badgeColor)
                }
            }

            // Title and Message
            VStack(spacing: theme.spacing.xs) {
                CraftText(
                    title,
                    style: .headline,
                    color: theme.colors.textPrimary,
                    textAlignment: .center
                )

                if let message, !message.isEmpty {
                    CraftText(
                        message,
                        style: .bodyMedium,
                        color: theme.colors.textSecondary,
                        textAlignment: .center
                    )
                }
            }

            // Custom Content Slot
            customContent

            // Action Buttons
            VStack(spacing: theme.spacing.sm) {
                CraftButton(
                    primaryButtonTitle,
                    variant: primaryButtonVariant,
                    size: .md,
                    action: primaryAction
                )
                .frame(maxWidth: .infinity)

                if let cancelButtonTitle {
                    CraftButton(
                        cancelButtonTitle,
                        variant: .ghost,
                        size: .md,
                        action: {
                            cancelAction?()
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: 340)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl)
                .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
        )
        .craftShadow(theme.shadows.xl)
        .padding(.horizontal, theme.spacing.lg)
    }
}

// MARK: - Convenience Inits

public extension CraftDialog where CustomContent == EmptyView {
    init(
        title: String,
        message: String? = nil,
        iconName: String? = nil,
        primaryButtonTitle: String = "Confirm",
        primaryButtonVariant: CraftButtonVariant = .primary,
        primaryAction: @escaping () -> Void,
        cancelButtonTitle: String? = "Cancel",
        cancelAction: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            message: message,
            iconName: iconName,
            primaryButtonTitle: primaryButtonTitle,
            primaryButtonVariant: primaryButtonVariant,
            primaryAction: primaryAction,
            cancelButtonTitle: cancelButtonTitle,
            cancelAction: cancelAction
        ) {
            EmptyView()
        }
    }
}

// MARK: - Dialog View Modifier

public struct CraftDialogModifier<DialogBody: View>: ViewModifier {
    @Environment(\.craftTheme) private var theme
    @Binding public var isPresented: Bool
    public let dialogContent: DialogBody

    public init(
        isPresented: Binding<Bool>,
        @ViewBuilder dialogContent: () -> DialogBody
    ) {
        self._isPresented = isPresented
        self.dialogContent = dialogContent()
    }

    public func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                // Dimmed Backdrop
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(theme.animations.springSmooth) {
                            isPresented = false
                        }
                    }
                    .zIndex(999)

                // Dialog Content
                dialogContent
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(1000)
            }
        }
        .animation(theme.animations.springSmooth, value: isPresented)
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
        primaryButtonTitle: String = "Confirm",
        primaryButtonVariant: CraftButtonVariant = .primary,
        primaryAction: @escaping () -> Void,
        cancelButtonTitle: String? = "Cancel",
        cancelAction: (() -> Void)? = nil
    ) -> some View {
        modifier(
            CraftDialogModifier(isPresented: isPresented) {
                CraftDialog(
                    title: title,
                    message: message,
                    iconName: iconName,
                    primaryButtonTitle: primaryButtonTitle,
                    primaryButtonVariant: primaryButtonVariant,
                    primaryAction: {
                        primaryAction()
                        withAnimation {
                            isPresented.wrappedValue = false
                        }
                    },
                    cancelButtonTitle: cancelButtonTitle,
                    cancelAction: cancelButtonTitle != nil ? {
                        cancelAction?()
                        withAnimation {
                            isPresented.wrappedValue = false
                        }
                    } : nil
                )
            }
        )
    }

    /// Presents a custom modal dialog container over this view.
    func craftDialog<CustomContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> CustomContent
    ) -> some View {
        modifier(CraftDialogModifier(isPresented: isPresented, dialogContent: content))
    }
}
