import SwiftUI

// MARK: - Default Empty State Illustration

/// A standard circular badge illustration for default empty state views.
public struct CraftDefaultEmptyStateIllustration: View {
    @Environment(\.craftTheme) private var theme
    public let iconName: String

    public init(iconName: String = "sparkles") {
        self.iconName = iconName
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(theme.colors.surfaceSubtle)
                .frame(width: 72, height: 72)

            CraftIcon(iconName, size: .xl, color: theme.colors.brandPrimary)
        }
    }
}

// MARK: - CraftEmptyState Component

/// A standardized empty state placeholder view displaying an illustration or icon,
/// header title, descriptive message, and an optional call-to-action button.
public struct CraftEmptyState<Illustration: View>: View {
    @Environment(\.craftTheme) private var theme

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let messageKey: LocalizedStringKey?
    private let rawMessage: String?
    private let buttonTitleKey: LocalizedStringKey?
    private let rawButtonTitle: String?

    public var title: String { rawTitle ?? "" }
    public var message: String? { rawMessage }
    public var buttonTitle: String? { rawButtonTitle }
    public let iconName: String?
    public let buttonIcon: String?
    public let buttonAction: (() -> Void)?
    public let illustration: Illustration

    // MARK: - Generic Initializers (String)

    public init(
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.messageKey = nil
        self.rawMessage = message
        self.iconName = nil
        self.buttonTitleKey = nil
        self.rawButtonTitle = buttonTitle
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
        self.titleKey = nil
        self.rawTitle = title
        self.messageKey = nil
        self.rawMessage = message
        self.iconName = iconName
        self.buttonTitleKey = nil
        self.rawButtonTitle = buttonTitle
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = illustration()
    }

    // MARK: - Generic Initializers (LocalizedStringKey)

    public init(
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttonTitle: LocalizedStringKey? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.titleKey = title
        self.rawTitle = nil
        self.messageKey = message
        self.rawMessage = nil
        self.iconName = nil
        self.buttonTitleKey = buttonTitle
        self.rawButtonTitle = nil
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = illustration()
    }

    public init(
        iconName: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttonTitle: LocalizedStringKey? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.titleKey = title
        self.rawTitle = nil
        self.messageKey = message
        self.rawMessage = nil
        self.iconName = iconName
        self.buttonTitleKey = buttonTitle
        self.rawButtonTitle = nil
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = illustration()
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Illustration or Icon
            illustration

            // Text copy
            VStack(spacing: theme.spacing.xs) {
                if let titleKey {
                    CraftText(
                        titleKey,
                        style: .titleMedium,
                        color: theme.colors.textPrimary,
                        textAlignment: .center
                    )
                } else if let rawTitle {
                    CraftText(
                        rawTitle,
                        style: .titleMedium,
                        color: theme.colors.textPrimary,
                        textAlignment: .center
                    )
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
            .padding(.horizontal, theme.spacing.lg)

            // Primary Action Button
            if let buttonAction {
                if let buttonTitleKey {
                    CraftButton(
                        buttonTitleKey,
                        iconName: buttonIcon,
                        variant: .primary,
                        size: .md,
                        action: buttonAction
                    )
                    .padding(.top, theme.spacing.xs)
                } else if let rawButtonTitle {
                    CraftButton(
                        rawButtonTitle,
                        iconName: buttonIcon,
                        variant: .primary,
                        size: .md,
                        action: buttonAction
                    )
                    .padding(.top, theme.spacing.xs)
                }
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: 500)
    }
}

// MARK: - Convenience Inits with Concrete Default Illustration

public extension CraftEmptyState where Illustration == CraftDefaultEmptyStateIllustration {
    init(
        iconName: String = "sparkles",
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.messageKey = nil
        self.rawMessage = message
        self.iconName = iconName
        self.buttonTitleKey = nil
        self.rawButtonTitle = buttonTitle
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = CraftDefaultEmptyStateIllustration(iconName: iconName)
    }

    init(
        iconName: String = "sparkles",
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttonTitle: LocalizedStringKey? = nil,
        buttonIcon: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.titleKey = title
        self.rawTitle = nil
        self.messageKey = message
        self.rawMessage = nil
        self.iconName = iconName
        self.buttonTitleKey = buttonTitle
        self.rawButtonTitle = nil
        self.buttonIcon = buttonIcon
        self.buttonAction = buttonAction
        self.illustration = CraftDefaultEmptyStateIllustration(iconName: iconName)
    }
}


