import CraftUIKit
import SwiftUI

public struct ShadowingHubView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.locale) private var locale

    @State private var viewModel: ShadowingHubViewModel
    public let onSelectVideo: (ShadowingVideo) -> Void

    public init(
        viewModel: ShadowingHubViewModel,
        onSelectVideo: @escaping (ShadowingVideo) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onSelectVideo = onSelectVideo
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: theme.spacing.lg) {
                    headerSection

                    if let challengeVideo = viewModel.dailyChallengeVideo {
                        DailyChallengeHeroCard(
                            video: challengeVideo,
                            onStart: { onSelectVideo(challengeVideo) }
                        )
                        .padding(.horizontal, theme.spacing.md)
                    }

                    LevelFilterChipsView(
                        selectedLevel: viewModel.selectedLevelFilter,
                        onSelectLevel: { level in
                            viewModel.selectLevelFilter(level)
                        }
                    )

                    if viewModel.isLoading && viewModel.topics.isEmpty {
                        loadingPlaceholder
                    } else {
                        topicSections
                    }
                }
                .padding(.bottom, theme.spacing.xl)
            }
            .refreshable {
                await viewModel.loadCatalog()
            }
        }
        .task {
            await viewModel.loadCatalog()
        }
        .onAppear {
            Task {
                await viewModel.loadCatalog()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(LocalizedStringKey("app.shadowing.hub.title"))
                    .font(theme.typography.displayLarge)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(LocalizedStringKey("app.shadowing.hub.subtitle"))
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer()

            CraftStreakBadge(
                count: viewModel.streakDays,
                size: .md
            )
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.top, theme.spacing.sm)
    }

    // MARK: - Topic Sections

    private var topicSections: some View {
        VStack(spacing: theme.spacing.lg) {
            ForEach(viewModel.topics) { topic in
                let videos = viewModel.videosByTopic[topic] ?? []
                if !videos.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack {
                            Text(topicTitle(for: topic))
                                .font(theme.typography.titleMedium)
                                .foregroundStyle(theme.colors.textPrimary)

                            Spacer()

                            Text(
                                String(
                                    format: String(localized: "app.shadowing.hub.see_all", bundle: .main),
                                    videos.count
                                )
                            )
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                        }
                        .padding(.horizontal, theme.spacing.md)

                        VStack(spacing: theme.spacing.md) {
                            ForEach(videos) { video in
                                ShadowingVideoCardView(
                                    video: video,
                                    progress: viewModel.progressMap[video.id],
                                    onSelect: { onSelectVideo(video) }
                                )
                            }
                        }
                        .padding(.horizontal, theme.spacing.md)
                    }
                }
            }
        }
    }

    // MARK: - Loading Placeholder

    private var loadingPlaceholder: some View {
        VStack(spacing: theme.spacing.md) {
            CraftSpinner(size: .lg, color: theme.colors.brandPrimary)
                .frame(maxWidth: .infinity, minHeight: 120)
        }
    }

    // MARK: - Helpers

    private func topicTitle(for topic: ShadowingTopicItem) -> String {
        if locale.identifier.starts(with: "vi") {
            return topic.titleVi
        } else {
            return topic.titleEn
        }
    }
}
