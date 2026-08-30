import CraftUIKit
import SwiftUI

/// Elevated hero profile header card displaying user avatar, CEFR level badge,
/// perks summary, and profile action trigger in an elegant centered layout.
public struct HeroProfileCard: View {
    @Environment(\.craftTheme) private var theme
    public let userName: String
    public let userLevel: String
    public let onTapAction: (() -> Void)?

    public init(
        userName: String = "Hooji N.",
        userLevel: String = "B2 Intermediate",
        onTapAction: (() -> Void)? = nil
    ) {
        self.userName = userName
        self.userLevel = userLevel
        self.onTapAction = onTapAction
    }

    public var body: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .center, spacing: theme.spacing.md) {
                // Centered Avatar with glowing aura ring
                ZStack {
                    Circle()
                        .fill(theme.gradients.brandHero)
                        .frame(width: 68, height: 68)
                        .overlay(
                            Circle()
                                .strokeBorder(theme.colors.borderDefault, lineWidth: 2)
                        )
                        .craftShadow(theme.shadows.md)

                    Text(userName.prefix(1))
                        .font(theme.typography.displayLarge)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.textInverse)
                }
                .padding(.top, theme.spacing.xs)

                // User Name & Level Badge
                VStack(spacing: theme.spacing.xs) {
                    CraftText(
                        userName,
                        style: .titleLarge,
                        color: theme.colors.textPrimary
                    )
                    .fontWeight(.bold)

                    CraftBadge(
                        userLevel,
                        symbol: .star,
                        variant: .subtle,
                        tone: .primary,
                        size: .md
                    )
                }

                // Subtitle / Tagline
                CraftText(
                    AppStrings.Settings.profileTagline,
                    style: .caption,
                    color: theme.colors.textSecondary
                )
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, theme.spacing.sm)

                // Action Button
                CraftButton(
                    AppStrings.Settings.profileActionView,
                    variant: .secondary,
                    size: .md,
                    action: {
                        onTapAction?()
                    }
                )
                .frame(maxWidth: .infinity)
                .padding(.top, theme.spacing.xs / 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.xs)
        }
    }
}

#if canImport(PreviewsMacros)
#Preview("HeroProfileCard") {
    HeroProfileCard()
        .padding()
}
#endif
