import CraftUIKit
import SwiftUI

@MainActor
public struct ShadowingImmersionView: View {
    @Environment(\.craftTheme) private var theme
    public let viewModel: ShadowingStudioViewModel

    public init(viewModel: ShadowingStudioViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: theme.spacing.lg) {
                headerSection

                playerContainer

                subtitleCard

                controlsBar

                CraftButton(
                    String(localized: "app.shadowing.round1.skip_to_round2"),
                    iconName: "arrow.right",
                    variant: .primary,
                    isFullWidth: true,
                    action: {
                        viewModel.advanceToNextRound()
                    }
                )
                .padding(.top, theme.spacing.sm)
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.bottom, theme.spacing.xl)
        }
        .onAppear {
            viewModel.startRound1Playback()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(LocalizedStringKey("app.shadowing.round1.title"))
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.textPrimary)

            Text(LocalizedStringKey("app.shadowing.round1.instruction"))
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.xs)
    }

    // MARK: - Video Player Container

    private var playerContainer: some View {
        CraftYouTubePlayerView(
            videoId: viewModel.video.youtubeVideoId,
            bridgeHolder: viewModel.bridgeHolder,
            onMessage: { message in
                switch message {
                case .timeUpdate(let currentTime):
                    viewModel.handleTimeUpdate(seconds: currentTime)
                case .segmentFinished:
                    viewModel.advanceToNextRound()
                default:
                    break
                }
            }
        )
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)
                .stroke(theme.colors.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - Subtitle Card

    private var subtitleCard: some View {
        CraftCard(style: .elevated) {
            VStack(spacing: theme.spacing.xs) {
                Text(viewModel.currentSentence.textEn)
                    .font(theme.typography.titleMedium)
                    .foregroundStyle(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                if !viewModel.currentSentence.textVi.isEmpty {
                    Text(viewModel.currentSentence.textVi)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, theme.spacing.xs)
        }
    }

    // MARK: - Quick Controls Bar

    private var controlsBar: some View {
        HStack {
            HStack(spacing: theme.spacing.xs) {
                speedPill(0.85)
                speedPill(1.0)
            }

            Spacer()

            CraftIconButton(
                iconName: viewModel.isPlaying ? "pause.fill" : "play.fill",
                size: .md,
                variant: .subtle,
                accessibilityLabelKey: viewModel.isPlaying ? "app.shadowing.round2.pause" : "app.shadowing.round2.resume",
                action: {
                    viewModel.togglePlayPause()
                }
            )

            CraftIconButton(
                iconName: "arrow.counterclockwise",
                size: .md,
                variant: .ghost,
                accessibilityLabelKey: "app.shadowing.action.retry",
                action: {
                    viewModel.bridgeHolder.seekTo(seconds: 0)
                    viewModel.bridgeHolder.playVideo()
                    viewModel.isPlaying = true
                }
            )
        }
    }

    private func speedPill(_ speed: Float) -> some View {
        CraftPill(
            String(format: "%.2gx", speed),
            isSelected: viewModel.playbackSpeed == speed,
            action: { viewModel.setPlaybackSpeed(speed) }
        )
        .accessibilityLabel(String(format: String(localized: "app.shadowing.speed"), String(format: "%.2gx", speed)))
    }
}
