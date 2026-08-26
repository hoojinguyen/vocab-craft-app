import SwiftUI

// MARK: - Default Empty State Illustration

/// A refined 3-tier layered squircle badge illustration with subtle depth for empty state views.
public struct CraftDefaultEmptyStateIllustration: View {
    @Environment(\.craftTheme) private var theme
    public let iconName: String
    public let symbol: CraftSymbol?

    public init(symbol: CraftSymbol = .study) {
        self.symbol = symbol
        self.iconName = symbol.rawValue
    }

    public init(iconName: String = "character.book.closed") {
        self.symbol = CraftSymbol(rawValue: iconName)
        self.iconName = iconName
    }

    public var body: some View {
        ZStack {
            // Layer 1: Outer soft squircle container
            RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                .fill(theme.colors.surfaceSubtle)
                .frame(width: 88, height: 88)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                        .strokeBorder(theme.colors.borderDefault.opacity(0.6), lineWidth: 1)
                )

            // Layer 2: Inner accent pill badge
            RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)
                .fill(theme.colors.brandPrimary.opacity(0.12))
                .frame(width: 56, height: 56)

            // Layer 3: Hierarchical focal icon
            CraftIcon(
                iconName,
                size: .lg,
                color: theme.colors.brandPrimary,
                renderingMode: .hierarchical,
                weight: .bold
            )
        }
        .craftShadow(theme.shadows.sm)
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
        symbol: CraftSymbol = .study,
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        buttonSymbol: CraftSymbol? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.init(
            iconName: symbol.rawValue,
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            buttonIcon: buttonSymbol?.rawValue,
            buttonAction: buttonAction
        )
    }

    init(
        iconName: String = "character.book.closed",
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
        symbol: CraftSymbol = .study,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttonTitle: LocalizedStringKey? = nil,
        buttonSymbol: CraftSymbol? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.init(
            iconName: symbol.rawValue,
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            buttonIcon: buttonSymbol?.rawValue,
            buttonAction: buttonAction
        )
    }

    init(
        iconName: String = "character.book.closed",
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

#Preview("CraftEmptyState") {
    ScrollView {
        VStack(spacing: 48) {
            CraftEmptyState(
                iconName: "star.fill",
                title: "No Favorites",
                message: "You haven't favorited anything yet.",
                buttonTitle: "Explore",
                buttonAction: {}
            )
            
            CraftEmptyState(
                iconName: "folder",
                title: "Empty Folder"
            )
        }
        .padding()
    }
}
