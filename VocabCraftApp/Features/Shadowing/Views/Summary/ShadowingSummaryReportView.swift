import CraftUIKit
import SwiftUI

@MainActor
public struct ShadowingSummaryReportView: View {
    @Environment(\.craftTheme) private var theme
    public let viewModel: ShadowingStudioViewModel
    public let onFinish: () -> Void

    public init(
        viewModel: ShadowingStudioViewModel,
        onFinish: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onFinish = onFinish
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: theme.spacing.xl) {
                celebrationHeader

                metricsCard

                if viewModel.round2AudioURL != nil {
                    round2AudioSection
                }

                if !viewModel.bookmarkedWordIds.isEmpty {
                    savedWordsSection
                }

                actionButtonsSection
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.top, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xxl)
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: theme.spacing.md) {
            ZStack {
                Circle()
                    .fill(theme.colors.brandPrimary.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "trophy.fill")
                    .font(theme.typography.displayLarge)
                    .foregroundStyle(theme.colors.accent)
            }

            VStack(spacing: theme.spacing.xxs) {
                Text(LocalizedStringKey("app.shadowing.summary.title"))
                    .font(theme.typography.displayLarge)
                    .foregroundStyle(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(viewModel.video.title)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Metrics Card

    private var metricsCard: some View {
        CraftCard(style: .elevated) {
            VStack(spacing: theme.spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        Text(
                            String(
                                format: String(localized: "app.shadowing.summary.score_format"),
                                Int(viewModel.averageMasteryScore.rounded())
                            )
                        )
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)

                        Text(
                            String(
                                format: String(localized: "app.shadowing.progress_format"),
                                viewModel.video.sentences.count,
                                viewModel.video.sentences.count
                            )
                        )
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                    }

                    Spacer()

                    CraftBadge(
                        "\(Int(viewModel.averageMasteryScore.rounded()))%",
                        symbol: .star,
                        variant: .solid,
                        tone: viewModel.averageMasteryScore >= 70 ? .success : .warning,
                        size: .md
                    )
                }

                CraftProgressBar(
                    currentStep: Int(viewModel.averageMasteryScore.rounded()),
                    totalSteps: 100,
                    height: 8
                )
            }
            .padding(.vertical, theme.spacing.xs)
        }
    }

    // MARK: - Round 2 Audio Section

    private var round2AudioSection: some View {
        CraftCard(style: .outlined) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "waveform")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.brandPrimary)

                    Text(LocalizedStringKey("app.shadowing.summary.round2_audio"))
                        .font(theme.typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.brandPrimary)

                    Spacer()
                }

                CraftButton(
                    String(localized: "app.shadowing.summary.round2_audio"),
                    iconName: "play.circle.fill",
                    variant: .secondary,
                    isFullWidth: true,
                    action: {
                        viewModel.playRound2Audio()
                    }
                )
            }
            .padding(.vertical, theme.spacing.xxs)
        }
    }

    // MARK: - Saved Words Section

    private var savedWordsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(
                String(
                    format: String(localized: "app.shadowing.summary.saved_words"),
                    viewModel.bookmarkedWordIds.count
                )
            )
            .font(theme.typography.headline)
            .foregroundStyle(theme.colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(Array(viewModel.bookmarkedWordIds.sorted()), id: \.self) { word in
                        CraftPill(
                            word,
                            iconName: "bookmark.fill",
                            isSelected: true,
                            action: {}
                        )
                    }
                }
                .padding(.vertical, theme.spacing.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftButton(
                String(localized: "app.shadowing.summary.finish"),
                iconName: "checkmark",
                variant: .primary,
                isFullWidth: true,
                action: {
                    Task {
                        try? await viewModel.finishSession()
                        onFinish()
                    }
                }
            )

            CraftButton(
                String(localized: "app.shadowing.summary.retry_weak"),
                iconName: "arrow.counterclockwise",
                variant: .secondary,
                isFullWidth: true,
                action: {
                    viewModel.retryWeakSentences()
                }
            )
        }
        .padding(.top, theme.spacing.xs)
    }
}
