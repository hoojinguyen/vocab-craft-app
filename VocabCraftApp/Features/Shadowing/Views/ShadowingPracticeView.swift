import CraftUIKit
import SwiftUI

public struct ShadowingPracticeView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ShadowingPracticeViewModel

    public init(viewModel: ShadowingPracticeViewModel) {
        self._viewModel = State(initialValue: viewModel)
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
        VStack(spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.spacing.md) {
                    playerContainer

                    playbackControlsBar

                    CraftVoiceMatchCard(
                        originText: viewModel.currentSentence.textEn,
                        actualText: viewModel.currentEvaluation?.spokenText,
                        subtitle: viewModel.currentSentence.textVi,
                        speechState: speechState,
                        customInstruction: String(localized: "app.shadowing.title"),
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
                }
                .padding(.horizontal, theme.spacing.md)
                .padding(.bottom, theme.spacing.xl)
            }
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
        .onAppear {
            viewModel.startCurrentSentence()
        }
        .onDisappear {
            viewModel.cleanup()
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

    private var headerBar: some View {
        VStack(spacing: theme.spacing.xs) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel(String(localized: "common.close", defaultValue: "Close", bundle: .module))

                Spacer()

                Text(viewModel.video.title)
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(
                    String(
                        format: String(localized: "app.shadowing.progress_format"),
                        viewModel.currentSentenceIndex + 1,
                        viewModel.video.sentences.count
                    )
                )
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.top, theme.spacing.xs)

            CraftProgressBar(
                currentStep: viewModel.currentSentenceIndex + 1,
                totalSteps: max(viewModel.video.sentences.count, 1),
                height: 4
            )
            .padding(.horizontal, theme.spacing.md)
        }
    }

    private var playerContainer: some View {
        CraftYouTubePlayerView(
            videoId: viewModel.video.youtubeVideoId,
            bridgeHolder: viewModel.bridgeHolder,
            onMessage: { message in
                if case .segmentFinished = message {
                    viewModel.handleSegmentFinished()
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

    private var playbackControlsBar: some View {
        HStack {
            HStack(spacing: theme.spacing.xs) {
                speedPill(0.8)
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
            String(format: "%.1fx", speed),
            isSelected: viewModel.playbackSpeed == speed,
            action: { viewModel.setSpeed(speed) }
        )
    }

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

    private var comparisonActionBar: some View {
        VStack(spacing: theme.spacing.sm) {
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
            } else {
                CraftButton(
                    String(localized: "app.shadowing.celebration.title"),
                    iconName: "checkmark.circle.fill",
                    variant: .primary,
                    isFullWidth: true,
                    action: {
                        dismiss()
                    }
                )
            }
        }
    }
}

#if canImport(PreviewsMacros)
#Preview("ShadowingPracticeView") {
    let video = ShadowingVideo(
        id: "preview_vid",
        youtubeVideoId: "dQw4w9WgXcQ",
        title: "Ordering Coffee in London",
        topic: .dailyLife,
        level: "B1",
        durationSeconds: 15.0,
        sentences: [
            ShadowingSentence(
                id: "s1",
                orderIndex: 0,
                startTime: 0.0,
                endTime: 3.5,
                textEn: "Could I have an oat flat white, please?",
                textVi: "Cho tôi một ly flat white sữa yến mạch được không?",
                keyWords: [
                    ShadowingKeyWord(
                        lemma: "flat white",
                        phonetic: "/ˌflæt ˈwaɪt/",
                        definitionVi: "Cà phê sữa kiểu Úc"
                    )
                ]
            )
        ]
    )
    ShadowingPracticeView(viewModel: ShadowingPracticeViewModel(video: video))
}
#endif
