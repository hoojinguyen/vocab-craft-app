import CraftUIKit
import SwiftUI

/// Discovery card view introducing a new vocabulary word during a lesson's micro-cycle.
public struct LessonDiscoveryCardView: View {
    public let word: TopicWordDTO?
    public let sense: SenseDetail?
    public let indexInCycle: Int
    public let totalInCycle: Int
    public let onContinue: () -> Void
    public let onPlayAudio: () -> Void

    @Environment(\.craftTheme) private var theme

    private var lemma: String {
        sense?.headword ?? word?.lemma ?? ""
    }

    private var phonetic: String {
        sense?.ipa ?? word?.phonetic ?? ""
    }

    private var pos: String {
        sense?.partOfSpeech.rawValue ?? word?.pos ?? ""
    }

    private var cefrLevel: String {
        sense?.cefrLevel.rawValue ?? word?.cefrLevel ?? ""
    }

    private var definitionVi: String {
        sense?.definitionVI ?? word?.definitionVi ?? ""
    }

    private var exampleEn: String {
        sense?.examples.first?.textEN ?? word?.exampleEn ?? ""
    }

    private var exampleVi: String {
        sense?.examples.first?.textVI ?? word?.exampleVi ?? ""
    }

    private var stepIdentifier: String {
        sense?.id.rawValue.uuidString.lowercased() ?? "\(word?.id ?? 0)"
    }

    public init(
        word: TopicWordDTO,
        indexInCycle: Int,
        totalInCycle: Int,
        onContinue: @escaping () -> Void,
        onPlayAudio: @escaping () -> Void
    ) {
        self.word = word
        self.sense = nil
        self.indexInCycle = indexInCycle
        self.totalInCycle = totalInCycle
        self.onContinue = onContinue
        self.onPlayAudio = onPlayAudio
    }

    public init(
        sense: SenseDetail,
        indexInCycle: Int,
        totalInCycle: Int,
        onContinue: @escaping () -> Void,
        onPlayAudio: @escaping () -> Void
    ) {
        self.word = nil
        self.sense = sense
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
                                        lemma,
                                        style: .titleLargeSerif,
                                        color: theme.colors.textPrimary
                                    )

                                    if !phonetic.isEmpty {
                                        CraftText(
                                            phonetic,
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

                                if !pos.isEmpty {
                                    CraftBadge(
                                        pos,
                                        variant: .subtle,
                                        tone: .neutral,
                                        size: .sm,
                                        shape: .capsule
                                    )
                                }

                                if !cefrLevel.isEmpty {
                                    CraftBadge(
                                        cefrLevel,
                                        variant: .subtle,
                                        tone: .warning,
                                        size: .sm,
                                        shape: .capsule
                                    )
                                }
                            }

                            CraftDivider()

                            CraftText(
                                definitionVi,
                                style: .titleMedium,
                                color: theme.colors.textPrimary
                            )

                            if !exampleEn.isEmpty {
                                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                    Text(exampleEn)
                                        .font(theme.typography.bodySerif)
                                        .foregroundStyle(theme.colors.textPrimary)

                                    if !exampleVi.isEmpty {
                                        CraftText(
                                            exampleVi,
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
        .task(id: stepIdentifier) {
            // Give spring transition 300ms to complete smoothly before starting TTS
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            onPlayAudio()
        }
    }
}
