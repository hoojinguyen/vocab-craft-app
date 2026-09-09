import CraftUIKit
import SwiftUI

/// Compact, Apple ID-style profile card row displaying user avatar, name, CEFR level badge,
/// and chevron drill-down trigger in an elegant horizontal layout.
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
        CraftCard(style: .outlined, padding: 0) {
            Button(action: {
                onTapAction?()
            }) {
                HStack(spacing: theme.spacing.md) {
                    // Avatar Squircle / Circle with Gradient Aura
                    ZStack {
                        Circle()
                            .fill(theme.gradients.brandHero)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                            )
                            .craftShadow(theme.shadows.sm)

                        Text(userName.prefix(1))
                            .font(theme.typography.titleLarge)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.colors.textInverse)
                    }
                    .accessibilityHidden(true)

                    // User Name & Subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        CraftText(
                            userName,
                            style: .headline,
                            color: theme.colors.textPrimary
                        )
                        .fontWeight(.bold)

                        CraftText(
                            AppStrings.Settings.profileTagline,
                            style: .caption,
                            color: theme.colors.textSecondary
                        )
                        .lineLimit(1)
                    }

                    Spacer(minLength: theme.spacing.xs)

                    // Level Badge & Chevron
                    CraftBadge(
                        userLevel,
                        symbol: .star,
                        variant: .subtle,
                        tone: .primary,
                        size: .sm
                    )

                    CraftIcon("chevron.right", size: .sm, color: theme.colors.textMuted)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.craftPress(scale: 0.98))
            .accessibilityHint(AppStrings.Settings.profileActionViewText)
        }
    }
}

#if canImport(PreviewsMacros)
#Preview("HeroProfileCard") {
    HeroProfileCard()
        .padding()
}
#endif
