import SwiftUI

// MARK: - CraftEmptyState Component

/// A standardized empty state placeholder view displaying an illustration or icon,
/// header title, descriptive message, and an optional call-to-action button.
public struct CraftEmptyState<Illustration: View>: View {
    @Environment(\.craftTheme) private var theme

    public let title: String
    public let message: String?
    public let iconName: String?
    public let buttonTitle: String?
    public let buttonIcon: String?
    public let buttonAction: (() -> Void)?
    public let illustration: Illustration

    public init(
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.title = title
        self.message = message
        self.iconName = nil
        self.buttonTitle = buttonTitle
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = illustration()
    }

    public init(
        iconName: String,
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.buttonTitle = buttonTitle
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = illustration()
    }

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Illustration or Icon
            illustration

            // Text copy
            VStack(spacing: theme.spacing.xs) {
                CraftText(
                    title,
                    style: .titleMedium,
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
            .padding(.horizontal, theme.spacing.lg)

            // Primary Action Button
            if let buttonTitle, let buttonAction {
                CraftButton(
                    buttonTitle,
                    iconName: buttonIcon,
                    variant: .primary,
                    size: .md,
                    action: buttonAction
                )
                .padding(.top, theme.spacing.xs)
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Convenience Inits

private struct DefaultEmptyStateIcon: View {
    @Environment(\.craftTheme) private var theme
    let iconName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.colors.surfaceSubtle)
                .frame(width: 72, height: 72)

            CraftIcon(iconName, size: .xl, color: theme.colors.brandPrimary)
        }
    }
}

public extension CraftEmptyState where Illustration == AnyView {
    init(
        iconName: String,
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.buttonTitle = buttonTitle
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = AnyView(DefaultEmptyStateIcon(iconName: iconName))
    }
}

