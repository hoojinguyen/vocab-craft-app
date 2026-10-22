import CraftUIKit
import SwiftUI

@MainActor
public struct ShadowingEchoView: View {
    @Environment(\.craftTheme) private var theme
    @Bindable public var viewModel: ShadowingStudioViewModel

    public init(viewModel: ShadowingStudioViewModel) {
        self.viewModel = viewModel
    }

    private var speechState: CraftSpeechState {
        switch viewModel.playbackPhase {
        case .idle, .playingNative, .readyToRecord:
            return .idle
        case let .listening(levels):
            return .listening(audioLevels: levels)
        case .evaluating:
            return .processing
        case let .evaluated(score):
            return .evaluated(overallScore: score)
        }
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: theme.spacing.md) {
                progressHeader

                playerContainer

                playbackControlsBar

                CraftVoiceMatchCard(
                    originText: viewModel.currentSentence.textEn,
                    actualText: viewModel.currentEvaluation?.spokenText,
                    explicitTokens: viewModel.currentEvaluationTokens,
                    subtitle: viewModel.currentSentence.textVi,
                    speechState: speechState,
                    customInstruction: String(localized: "app.shadowing.round3.title"),
                    onTapMic: {
                        viewModel.toggleRecording()
                    },
                    onReset: {
                        viewModel.startCurrentSentence()
                    }
                )

                if !viewModel.currentSentence.keyWords.isEmpty {
                    keyWordsBar
                }

                if case .evaluated = viewModel.playbackPhase {
                    comparisonActionBar
                }

                nextSentenceOrFinishButton
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.bottom, theme.spacing.xl)
        }
        .onAppear {
            viewModel.startCurrentSentence()
        }
        .popover(item: $viewModel.selectedKeyWordForPopover) { keyWord in
            ShadowingKeyWordPopoverView(
                keyWord: keyWord,
                isBookmarked: viewModel.bookmarkedWordIds.contains(keyWord.lemma),
                onToggleBookmark: {
                    viewModel.toggleBookmark(for: keyWord)
                }
            )
            .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: theme.spacing.xs) {
            HStack {
                Text(LocalizedStringKey("app.shadowing.round3.title"))
                    .font(theme.typography.titleMedium)
                    .foregroundStyle(theme.colors.textPrimary)

                Spacer()

                Text(
                    String(
                        format: String(localized: "app.shadowing.progress_format"),
                        viewModel.currentSentenceIndex + 1,
                        viewModel.video.sentences.count
                    )
                )
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
            }

            CraftProgressBar(
                currentStep: viewModel.currentSentenceIndex + 1,
                totalSteps: max(viewModel.video.sentences.count, 1),
                height: 4
            )
        }
        .padding(.top, theme.spacing.xs)
    }

    // MARK: - Video Player Container

    private var playerContainer: some View {
        ZStack {
            CraftYouTubePlayerView(
                videoId: viewModel.video.youtubeVideoId,
                bridgeHolder: viewModel.bridgeHolder,
                onMessage: { message in
                    switch message {
                    case .segmentFinished:
                        viewModel.handleSegmentFinished()
                    case .error(let code):
                        viewModel.handlePlaybackError(code: code)
                    default:
                        break
                    }
                }
            )

            if let error = viewModel.playbackError {
                ShadowingPlaybackErrorOverlay(
                    message: error,
                    onRetry: {
                        viewModel.retryPlayback()
                    }
                )
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)
                .stroke(theme.colors.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - Playback Controls Bar

    private var playbackControlsBar: some View {
        HStack {
            HStack(spacing: theme.spacing.xs) {
                speedPill(0.85)
                speedPill(1.0)
            }

            Spacer()

            CraftButton(
                String(localized: "app.shadowing.action.retry"),
                iconName: "arrow.counterclockwise",
                variant: .ghost,
                size: .sm,
                action: {
                    viewModel.startCurrentSentence()
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

    // MARK: - Key Words Bar

    private var keyWordsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
                ForEach(viewModel.currentSentence.keyWords) { keyWord in
                    CraftPill(
                        keyWord.lemma,
                        iconName: viewModel.bookmarkedWordIds.contains(keyWord.lemma) ? "bookmark.fill" : "bookmark",
                        isSelected: viewModel.bookmarkedWordIds.contains(keyWord.lemma),
                        action: {
                            viewModel.selectedKeyWordForPopover = keyWord
                        }
                    )
                }
            }
            .padding(.vertical, theme.spacing.xxs)
        }
    }

    // MARK: - Comparison Action Bar

    private var comparisonActionBar: some View {
        HStack(spacing: theme.spacing.sm) {
            CraftButton(
                String(localized: "app.shadowing.action.hear_native"),
                iconName: "speaker.wave.2.fill",
                variant: .secondary,
                isFullWidth: true,
                action: {
                    viewModel.playNativeAudio()
                }
            )

            CraftButton(
                String(localized: "app.shadowing.action.hear_me"),
                iconName: "waveform.badge.mic",
                variant: .secondary,
                isFullWidth: true,
                action: {
                    viewModel.playUserAudio()
                }
            )
        }
    }

    // MARK: - Next / Finish Button

    @ViewBuilder
    private var nextSentenceOrFinishButton: some View {
        if !viewModel.isLastSentence {
            CraftButton(
                String(localized: "app.shadowing.action.next_sentence"),
                iconName: "arrow.right",
                variant: .primary,
                isFullWidth: true,
                action: {
                    viewModel.advanceToNextSentence()
                }
            )
            .padding(.top, theme.spacing.xs)
        } else {
            CraftButton(
                String(localized: "app.shadowing.round3.finish"),
                iconName: "checkmark.circle.fill",
                variant: .primary,
                isFullWidth: true,
                action: {
                    viewModel.advanceToNextRound()
                }
            )
            .padding(.top, theme.spacing.xs)
        }
    }
}
