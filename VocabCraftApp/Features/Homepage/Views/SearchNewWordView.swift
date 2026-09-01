import CraftUIKit
import SwiftUI

/// Dedicated Search New Word view serving as the entry point for looking up new vocabulary.
public struct SearchNewWordView: View {
    @Environment(\.craftTheme) private var theme
    @State private var searchText = ""

    private let recentSearches = ["resilient", "ubiquitous", "ephemeral", "pragmatic", "meticulous"]

    private struct SuggestedTopic: Identifiable {
        let id = UUID()
        let titleKey: LocalizedStringKey
        let iconName: String
        let color: (CraftColorTokens) -> Color
    }

    private var suggestedTopics: [SuggestedTopic] {
        [
            SuggestedTopic(titleKey: AppStrings.Search.topicIelts, iconName: "sparkles", color: { $0.accent }),
            SuggestedTopic(titleKey: AppStrings.Search.topicBusiness, iconName: "briefcase.fill", color: { $0.statusInfo }),
            SuggestedTopic(titleKey: AppStrings.Search.topicAcademic, iconName: "book.closed.fill", color: { $0.statusDanger }),
            SuggestedTopic(titleKey: AppStrings.Search.topicDaily, iconName: "bubble.left.and.bubble.right.fill", color: { $0.statusSuccess })
        ]
    }

    public init() {}

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: theme.spacing.lg) {
                    // Header Title
                    headerSection

                    // Search Bar
                    CraftSearchBar(
                        text: $searchText,
                        placeholder: AppStrings.Homepage.searchPlaceholder,
                        size: .lg,
                        style: .outlined,
                        shape: .roundedRectangle(radius: theme.radii.lg)
                    )
                    .padding(.horizontal, theme.spacing.base)

                    // Future Feature Roadmap Banner
                    roadmapBanner

                    // Recent Searches
                    recentSearchesSection

                    // Suggested Topics Grid
                    suggestedTopicsSection

                    Spacer(minLength: 100)
                }
                .padding(.top, theme.spacing.xs)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                HStack(spacing: theme.spacing.xs) {
                    Text(AppStrings.Search.title)
                        .font(theme.typography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.textPrimary)

                    CraftIcon(.search, size: .lg, color: theme.colors.brandPrimary)
                }

                Text(AppStrings.Homepage.searchPlaceholder)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.top, theme.spacing.xs)
    }

    private var roadmapBanner: some View {
        CraftCard(
            style: .outlined,
            cornerRadius: theme.radii.xl,
            padding: theme.spacing.base,
            customGradient: LinearGradient(
                colors: [theme.colors.accent.opacity(0.08), theme.colors.surfaceCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    CraftBadge(
                        AppStrings.Search.upcomingFeatureBadge,
                        symbol: .sparkles,
                        variant: .subtle,
                        tone: .primary,
                        size: .sm,
                        customTint: theme.colors.accent
                    )
                    Spacer()
                }

                Text(AppStrings.Search.smartLookupTitle)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(AppStrings.Search.smartLookupDescription)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, theme.spacing.base)
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(AppStrings.Search.recentSearchesTitle)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)
                .padding(.horizontal, theme.spacing.base)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(recentSearches, id: \.self) { word in
                        CraftPill(
                            word,
                            iconName: "clock.arrow.circlepath",
                            isSelected: searchText == word,
                            style: .flat
                        ) {
                            searchText = word
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.base)
            }
        }
    }

    private var suggestedTopicsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(AppStrings.Search.suggestedTopicsTitle)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)
                .padding(.horizontal, theme.spacing.base)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: theme.spacing.sm),
                    GridItem(.flexible(), spacing: theme.spacing.sm)
                ],
                spacing: theme.spacing.sm
            ) {
                ForEach(suggestedTopics) { topic in
                    let color = topic.color(theme.colors)
                    CraftCard(
                        style: .outlined,
                        isPressable: true,
                        cornerRadius: theme.radii.lg,
                        padding: theme.spacing.sm,
                        action: {
                            // Action when topic is pressed
                        }
                    ) {
                        HStack(spacing: theme.spacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: theme.radii.sm)
                                    .fill(color.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                CraftIcon(
                                    topic.iconName,
                                    size: .md,
                                    color: color
                                )
                            }

                            Text(topic.titleKey)
                                .font(theme.typography.label)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.textPrimary)
                                .lineLimit(1)

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            .padding(.horizontal, theme.spacing.base)
        }
    }
}
