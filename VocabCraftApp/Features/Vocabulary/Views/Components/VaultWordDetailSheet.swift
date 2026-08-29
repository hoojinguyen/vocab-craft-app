import CraftUIKit
import SwiftUI

/// Bottom sheet component displaying full vocabulary word metadata, bilingual definitions,
/// highlighted contextual examples, and SRS reflex progress.
public struct VaultWordDetailSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    public let word: VaultWordItem
    public let viewModel: PersonalVaultViewModel?
    public let isPlayingAudio: Bool?
    public let onPlayAudio: () -> Void
    public let onToggleBookmark: () -> Void

    @State private var isBookmarked: Bool

    public init(
        word: VaultWordItem,
        viewModel: PersonalVaultViewModel? = nil,
        isPlayingAudio: Bool? = nil,
        onPlayAudio: @escaping () -> Void,
        onToggleBookmark: @escaping () -> Void
    ) {
        self.word = word
        self.viewModel = viewModel
        self.isPlayingAudio = isPlayingAudio
        self.onPlayAudio = onPlayAudio
        self.onToggleBookmark = onToggleBookmark
        _isBookmarked = State(initialValue: word.isBookmarked)
    }

    public var effectiveIsPlayingAudio: Bool {
        if let explicit = isPlayingAudio {
            return explicit
        }
        return viewModel?.isSpeakingAudio ?? false
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                // Header: Lemma, Badges, Audio, Bookmark
                headerSection

                // Section 1: Definitions
                definitionsSection

                // Section 2: Examples
                if !word.exampleSentenceEn.isEmpty {
                    examplesSection
                }

                // Section 3: Reflex Progress
                progressSection
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
        .background(theme.colors.canvasBackground)
        .presentationDetents([.fraction(0.68), .large])
        .presentationDragIndicator(.visible)
        .onChange(of: word.isBookmarked) { _, newValue in
            isBookmarked = newValue
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(word.lemma)
                    .font(theme.typography.titleLarge)
                    .foregroundStyle(theme.colors.textPrimary)

                if !word.phonetic.isEmpty {
                    Text(word.phonetic)
                        .font(theme.typography.phonetic)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                HStack(spacing: theme.spacing.xs) {
                    if !word.pos.isEmpty {
                        CraftBadge(
                            verbatim: word.pos,
                            variant: .subtle,
                            tone: .neutral,
                            size: .md
                        )
                    }

                    if !word.cefrLevel.isEmpty {
                        CraftBadge(
                            verbatim: word.cefrLevel.uppercased(),
                            variant: .subtle,
                            tone: .primary,
                            size: .md
                        )
                    }
                }
            }

            Spacer()

            // Header Action Buttons: Speaker & Bookmark
            HStack(spacing: theme.spacing.sm) {
                CraftSpeakerButton(
                    variant: .subtle,
                    size: .md,
                    isPlaying: effectiveIsPlayingAudio
                ) {
                    onPlayAudio()
                }

                CraftIconButton(
                    symbol: isBookmarked ? .bookmarkFill : .bookmark,
                    size: .md,
                    shape: .circle,
                    variant: .subtle,
                    customTint: isBookmarked ? theme.colors.accent : theme.colors.textMuted,
                    isSelected: false,
                    accessibilityLabelKey: isBookmarked ? "homepage.saved" : "homepage.saveWord"
                ) {
                    isBookmarked.toggle()
                    onToggleBookmark()
                }
            }
        }
    }

    // MARK: - Definitions Section
    private var definitionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            CraftText(
                AppStrings.Vault.detailDefinitionsTitle,
                style: .headline,
                color: theme.colors.textPrimary
            )

            CraftCard(
                style: .flat,
                padding: theme.spacing.md
            ) {
                Text(word.definitionVi)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Examples Section
    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            CraftText(
                AppStrings.Vault.detailExamplesTitle,
                style: .headline,
                color: theme.colors.textPrimary
            )

            CraftCard(
                style: .flat,
                padding: theme.spacing.md
            ) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    highlightedExample(sentence: word.exampleSentenceEn, lemma: word.lemma)

                    if !word.exampleSentenceVi.isEmpty {
                        Text(word.exampleSentenceVi)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Reflex Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            CraftText(
                AppStrings.Vault.detailProgressTitle,
                style: .headline,
                color: theme.colors.textPrimary
            )

            CraftCard(
                style: .outlined,
                padding: theme.spacing.md
            ) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    // Streak count badge
                    HStack {
                        CraftBadge(
                            verbatim: AppStrings.Vault.detailStreakCount(word.correctStreak),
                            symbol: .streak,
                            variant: .subtle,
                            tone: word.correctStreak > 0 ? .warning : .neutral,
                            size: .md
                        )

                        Spacer()

                        if word.isMastered {
                            CraftBadge(
                                AppStrings.Vocabulary.masteredBadge,
                                symbol: .mastery,
                                variant: .solid,
                                tone: .success,
                                size: .md
                            )
                        }
                    }

                    // Practiced Modes
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText(
                            AppStrings.Vault.detailPracticedModes,
                            style: .label,
                            color: theme.colors.textSecondary
                        )

                        if word.practicedModes.isEmpty {
                            Text(verbatim: "-")
                                .font(theme.typography.bodyMedium)
                                .foregroundStyle(theme.colors.textMuted)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: theme.spacing.xs) {
                                    ForEach(Array(word.practicedModes), id: \.self) { mode in
                                        DynamicReflexModeBadge(mode: mode, isCompact: true)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func highlightedExample(sentence: String, lemma: String) -> some View {
        if let range = sentence.range(of: lemma, options: .caseInsensitive) {
            let prefix = String(sentence[..<range.lowerBound])
            let match = String(sentence[range])
            let suffix = String(sentence[range.upperBound...])

            (
                Text(prefix)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(theme.colors.textPrimary)
                +
                Text(match)
                    .font(theme.typography.bodyLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.brandPrimary)
                +
                Text(suffix)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(theme.colors.textPrimary)
            )
        } else {
            Text(sentence)
                .font(theme.typography.bodyLarge)
                .foregroundStyle(theme.colors.textPrimary)
        }
    }
}

#Preview("VaultWordDetailSheet") {
    VaultWordDetailSheet(
        word: VaultWordItem(
            id: 1,
            lemma: "resilience",
            pos: "noun",
            phonetic: "/rɪˈzɪl.jəns/",
            definitionVi: "Khả năng phục hồi, kiên cường",
            exampleSentenceEn: "Her resilience helped her overcome difficulties.",
            exampleSentenceVi: "Sự kiên cường giúp cô ấy vượt qua khó khăn.",
            cefrLevel: "B2",
            isMastered: false,
            isBookmarked: true,
            correctStreak: 2,
            practicedModes: [.speaking, .typing]
        ),
        onPlayAudio: {},
        onToggleBookmark: {}
    )
}
