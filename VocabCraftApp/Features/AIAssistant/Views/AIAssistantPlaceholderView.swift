import CraftUIKit
import SwiftUI

/// Dedicated AI Assistant placeholder view serving as the entry point for upcoming VocabCraft AI features.
public struct AIAssistantPlaceholderView: View {
    @Environment(\.craftTheme) private var theme

    public init() {}

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: theme.spacing.lg) {
                    // Page Header
                    CraftPageHeader(
                        AppStrings.AIAssistant.title,
                        alignment: .leading,
                        enableScrollFade: false
                    )

                    // Hero Banner Card
                    heroBannerCard

                    // Upcoming Features Section
                    upcomingFeaturesSection

                    Spacer(minLength: theme.spacing.xxl)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.xs)
            }
        }
    }

    // MARK: - Hero Banner Card

    private var heroBannerCard: some View {
        CraftCard(
            style: .outlined,
            cornerRadius: theme.radii.xl,
            padding: theme.spacing.lg,
            customGradient: LinearGradient(
                colors: [theme.colors.accent.opacity(0.12), theme.colors.surfaceCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ) {
            VStack(spacing: theme.spacing.md) {
                ZStack {
                    Circle()
                        .fill(theme.colors.accent.opacity(0.15))
                        .frame(width: 72, height: 72)

                    CraftIcon(
                        .sparkles,
                        size: .xl,
                        color: theme.colors.accent
                    )
                }
                .padding(.top, theme.spacing.xs)

                CraftBadge(
                    AppStrings.AIAssistant.badgeComingSoon,
                    symbol: .sparkles,
                    variant: .subtle,
                    tone: .primary,
                    size: .sm,
                    customTint: theme.colors.accent
                )

                Text(AppStrings.AIAssistant.heroTitle)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(AppStrings.AIAssistant.heroDescription)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Upcoming Features Section

    private var upcomingFeaturesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text(AppStrings.AIAssistant.upcomingFeaturesTitle)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)

            featureItemCard(
                icon: .practice,
                titleKey: AppStrings.AIAssistant.featureConversationTitle,
                descriptionKey: AppStrings.AIAssistant.featureConversationDescription,
                tintColor: theme.colors.brandPrimary
            )

            featureItemCard(
                icon: .study,
                titleKey: AppStrings.AIAssistant.featureContextTitle,
                descriptionKey: AppStrings.AIAssistant.featureContextDescription,
                tintColor: theme.colors.statusSuccess
            )

            featureItemCard(
                icon: .audio,
                titleKey: AppStrings.AIAssistant.featurePronunciationTitle,
                descriptionKey: AppStrings.AIAssistant.featurePronunciationDescription,
                tintColor: theme.colors.statusInfo
            )
        }
    }

    private func featureItemCard(
        icon: CraftSymbol,
        titleKey: LocalizedStringKey,
        descriptionKey: LocalizedStringKey,
        tintColor: Color
    ) -> some View {
        CraftCard(
            style: .outlined,
            cornerRadius: theme.radii.lg,
            padding: theme.spacing.md
        ) {
            HStack(alignment: .top, spacing: theme.spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: theme.radii.md)
                        .fill(tintColor.opacity(0.12))
                        .frame(width: 40, height: 40)

                    CraftIcon(
                        icon,
                        size: .md,
                        color: tintColor
                    )
                }

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(titleKey)
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.textPrimary)

                    Text(descriptionKey)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineSpacing(2)
                }

                Spacer(minLength: 0)
            }
        }
    }
}
