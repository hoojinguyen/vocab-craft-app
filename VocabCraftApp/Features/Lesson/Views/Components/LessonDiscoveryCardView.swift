import CraftUIKit
import SwiftUI

/// Discovery card view introducing a new vocabulary word during a lesson's micro-cycle.
public struct LessonDiscoveryCardView: View {
    public let word: TopicWordDTO
    public let indexInCycle: Int
    public let totalInCycle: Int
    public let onContinue: () -> Void
    public let onPlayAudio: () -> Void

    @Environment(\.craftTheme) private var theme

    public init(
        word: TopicWordDTO,
        indexInCycle: Int,
        totalInCycle: Int,
        onContinue: @escaping () -> Void,
        onPlayAudio: @escaping () -> Void
    ) {
        self.word = word
        self.indexInCycle = indexInCycle
        self.totalInCycle = totalInCycle
        self.onContinue = onContinue
        self.onPlayAudio = onPlayAudio
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    Spacer(minLength: theme.spacing.xs)

                    CraftCard(style: .tactile3D) {
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                    CraftText(
                                        word.lemma,
                                        style: .titleLargeSerif,
                                        color: theme.colors.textPrimary
                                    )

                                    if !word.phonetic.isEmpty {
                                        CraftText(
                                            word.phonetic,
                                            style: .caption,
                                            color: theme.colors.textMuted
                                        )
                                    }
                                }

                                Spacer()

                                CraftSpeakerButton(
                                    variant: .subtle,
                                    size: .md,
                                    isPlaying: false,
                                    label: nil,
                                    action: onPlayAudio
                                )
                            }

                            HStack(spacing: theme.spacing.xs) {
                                if totalInCycle > 0 {
                                    CraftBadge(
                                        "\(indexInCycle)/\(totalInCycle)",
                                        variant: .subtle,
                                        tone: .neutral,
                                        size: .sm,
                                        shape: .capsule
                                    )
                                }

                                if !word.pos.isEmpty {
                                    CraftBadge(
                                        word.pos,
                                        variant: .subtle,
                                        tone: .neutral,
                                        size: .sm,
                                        shape: .capsule
                                    )
                                }

                                if !word.cefrLevel.isEmpty {
                                    CraftBadge(
                                        word.cefrLevel,
                                        variant: .subtle,
                                        tone: .warning,
                                        size: .sm,
                                        shape: .capsule
                                    )
                                }
                            }

                            CraftDivider()

                            CraftText(
                                word.definitionVi,
                                style: .titleMedium,
                                color: theme.colors.textPrimary
                            )

                            if !word.exampleEn.isEmpty {
                                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                    Text(word.exampleEn)
                                        .font(theme.typography.bodySerif)
                                        .foregroundStyle(theme.colors.textPrimary)

                                    if !word.exampleVi.isEmpty {
                                        CraftText(
                                            word.exampleVi,
                                            style: .caption,
                                            color: theme.colors.textMuted
                                        )
                                    }
                                }
                                .padding(theme.spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(theme.colors.surfaceSubtle)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                            }
                        }
                        .padding(.vertical, theme.spacing.xs)
                    }
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.vertical, theme.spacing.md)
                }
            }

            CraftButton(
                AppStrings.Lesson.continueAction,
                variant: .tactile,
                size: .lg,
                isFullWidth: true,
                style: .tactile3D
            ) {
                CraftHaptics.shared.medium()
                onContinue()
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.base)
        }
        .task(id: word.id) {
            onPlayAudio()
        }
    }
}
