import CraftUIKit
import SwiftUI

/// Elevated hero profile header card displaying user avatar, membership tier, CEFR level badge,
/// perks summary, and profile action trigger using CraftUIKit design tokens.
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
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                // Top Header Row
                HStack(spacing: theme.spacing.md) {
                    // Avatar with glowing aura
                    ZStack {
                        Circle()
                            .fill(theme.gradients.brandHero)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.colors.borderDefault, lineWidth: 2)
                            )
                            .craftShadow(theme.shadows.md)

                        Text(userName.prefix(1))
                            .font(theme.typography.titleLarge)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.colors.textInverse)
                    }

                    VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
                        HStack(spacing: theme.spacing.xs) {
                            CraftText(userName, style: .headline, color: theme.colors.textPrimary)
                            CraftBadge(
                                AppStrings.Settings.membershipActive,
                                symbol: .sparkles,
                                variant: .subtle,
                                tone: .success,
                                size: .sm
                            )
                        }

                        CraftBadge(
                            userLevel,
                            symbol: .star,
                            variant: .subtle,
                            tone: .primary,
                            size: .sm
                        )
                    }

                    Spacer()
                }

                // Perks Tagline
                CraftText(
                    AppStrings.Settings.profilePerks,
                    style: .caption,
                    color: theme.colors.textSecondary
                )
                .fixedSize(horizontal: false, vertical: true)

                // Action Button
                CraftButton(
                    AppStrings.Settings.profileActionView,
                    variant: .secondary,
                    size: .md,
                    action: {
                        onTapAction?()
                    }
                )
            }
        }
    }
}

#Preview("HeroProfileCard") {
    HeroProfileCard()
        .padding()
}
