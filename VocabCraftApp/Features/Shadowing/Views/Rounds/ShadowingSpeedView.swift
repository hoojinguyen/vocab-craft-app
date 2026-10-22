import CraftUIKit
import SwiftUI

@MainActor
public struct ShadowingSpeedView: View {
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

                teleprompterSection

                quickControlBar

                CraftButton(
                    String(localized: "app.shadowing.round2.advance_to_round3"),
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
            viewModel.startRound2Playback()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .center) {
                Text(LocalizedStringKey("app.shadowing.round2.title"))
                    .font(theme.typography.titleLarge)
                    .foregroundStyle(theme.colors.textPrimary)

                Spacer()

                if viewModel.isHeadphonesConnected {
                    CraftBadge(
                        String(localized: "app.shadowing.round2.headphone_connected"),
                        iconName: "headphones",
                        variant: .solid,
                        tone: .success,
                        size: .sm
                    )
                } else {
                    CraftBadge(
                        String(localized: "app.shadowing.round2.headphone_advisory"),
                        iconName: "headphones",
                        variant: .subtle,
                        tone: .warning,
                        size: .sm
                    )
                }
            }

            if viewModel.round2AudioURL != nil {
                HStack(spacing: theme.spacing.xxs) {
                    Image(systemName: "mic.fill")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.successGreen)

                    Text(LocalizedStringKey("app.shadowing.round2.listening_hint"))
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.successGreen)
                }
            }
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

    // MARK: - Teleprompter

    private var teleprompterSection: some View {
        CraftShadowingTeleprompterView(
            currentSentence: viewModel.currentSentence,
            nextSentence: viewModel.nextSentence,
            currentTime: viewModel.currentVideoTime,
            playbackSpeed: viewModel.playbackSpeed
        )
    }

    // MARK: - Quick Control Bar

    private var quickControlBar: some View {
        HStack {
            HStack(spacing: theme.spacing.xs) {
                speedPill(0.85)
                speedPill(1.0)
            }

            Spacer()

            CraftButton(
                String(localized: "app.shadowing.round2.rewind_5s"),
                iconName: "gobackward.5",
                variant: .ghost,
                size: .sm,
                action: {
                    viewModel.rewind5Seconds()
                }
            )

            CraftIconButton(
                iconName: viewModel.isPlaying ? "pause.fill" : "play.fill",
                size: .md,
                variant: .subtle,
                accessibilityLabelKey: viewModel.isPlaying ? "app.shadowing.round2.pause" : "app.shadowing.round2.resume",
                action: {
                    viewModel.togglePlayPause()
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
