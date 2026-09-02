import CraftUIKit
import SwiftUI

/// Summary view presented upon finishing all micro-cycles and exercises in a lesson.
public struct LessonSummaryView: View {
    public let summary: LessonSummaryModel
    public let onFinish: () -> Void
    public let onReplayAudio: (TopicWordDTO) -> Void

    @Environment(\.craftTheme) private var theme
    @State private var confettiTrigger: Bool = false

    public init(
        summary: LessonSummaryModel,
        onFinish: @escaping () -> Void,
        onReplayAudio: @escaping (TopicWordDTO) -> Void
    ) {
        self.summary = summary
        self.onFinish = onFinish
        self.onReplayAudio = onReplayAudio
    }

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            Spacer(minLength: theme.spacing.xs)

            // Star Rating Header
            VStack(spacing: theme.spacing.sm) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { idx in
                        Image(systemName: idx < summary.stars ? "star.fill" : "star")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(
                                idx < summary.stars
                                    ? theme.colors.accent
                                    : theme.colors.borderDefault
                            )
                    }
                }

                CraftText(
                    AppStrings.Lesson.summaryTitleText,
                    style: .titleLarge,
                    color: theme.colors.textPrimary
                )
            }

            // Metrics Row
            HStack(spacing: theme.spacing.md) {
                CraftCard(style: .subtle) {
                    VStack(spacing: 4) {
                        CraftText(
                            AppStrings.Lesson.xpEarnedFormat(summary.xpEarned),
                            style: .headline,
                            color: theme.colors.accent
                        )
                        CraftText(
                            "XP",
                            style: .caption,
                            color: theme.colors.textMuted
                        )
                    }
                    .frame(maxWidth: .infinity)
                }

                CraftCard(style: .subtle) {
                    VStack(spacing: 4) {
                        let pct = Int(summary.accuracyFraction * 100)
                        CraftText(
                            "\(pct)%",
                            style: .headline,
                            color: theme.colors.statusSuccess
                        )
                        CraftText(
                            AppStrings.Lesson.accuracyText,
                            style: .caption,
                            color: theme.colors.textMuted
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, theme.spacing.base)

            // Mastered Words List
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                CraftText(
                    AppStrings.Lesson.masteredWordsText,
                    style: .headline,
                    color: theme.colors.textPrimary
                )
                .padding(.horizontal, theme.spacing.base)

                ScrollView {
                    VStack(spacing: theme.spacing.xs) {
                        ForEach(summary.learnedWords, id: \.id) { word in
                            CraftListRow(
                                title: word.lemma,
                                subtitle: word.definitionVi,
                                leadingIcon: "character.book.closed.fill",
                                trailingAction: {
                                    onReplayAudio(word)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, theme.spacing.base)
                }
            }

            Spacer()

            CraftButton(
                AppStrings.Lesson.finishAction,
                variant: .primary,
                size: .lg,
                isFullWidth: true
            ) {
                CraftHaptics.shared.success()
                onFinish()
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.base)
        }
        .craftConfetti(isTriggered: $confettiTrigger, particleCount: 36)
        .onAppear {
            if summary.stars == 3 {
                confettiTrigger = true
            }
        }
    }
}
