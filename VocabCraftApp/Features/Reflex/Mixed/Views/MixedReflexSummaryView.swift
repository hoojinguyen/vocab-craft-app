import CraftUIKit
import SwiftUI

/// Summary view for Mixed Reflex Drill sessions.
/// Displays session rating, Bento metrics (Speed, Accuracy, Max Combo),
/// list of practiced words with mastery badges, and actions to retry or finish.
public struct MixedReflexSummaryView: View {
    @Environment(\.craftTheme) private var theme

    public let summary: ReflexBlitzSessionSummary
    public let practicedWords: [VaultWordItem]
    public let onSpeakWord: ((String) -> Void)?
    public let onRetry: () -> Void
    public let onDone: () -> Void

    public init(
        summary: ReflexBlitzSessionSummary,
        practicedWords: [VaultWordItem] = [],
        onSpeakWord: ((String) -> Void)? = nil,
        onRetry: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        self.summary = summary
        self.practicedWords = practicedWords
        self.onSpeakWord = onSpeakWord
        self.onRetry = onRetry
        self.onDone = onDone
    }

    private var formattedAvgTime: String {
        String(format: "%.1fs", Double(summary.averageResponseTimeMs) / 1000.0)
    }

    private var cleanRatingTitle: String {
        summary.ratingTier.localizedTitle
    }

    private var headerIconName: String {
        summary.ratingTier.iconName
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: theme.spacing.lg) {
                    headerSection
                    metricsBentoGrid
                    practicedWordsSection
                }
                .padding(.bottom, 110)
            }

            stickyBottomActionDock
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: headerIconName)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(theme.colors.brandPrimary)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 68, height: 68)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(theme.colors.brandPrimary.opacity(0.35), lineWidth: 1.5)
                )
                .craftShadow(theme.shadows.sm)
                .accessibilityHidden(true)

            VStack(spacing: theme.spacing.xs) {
                Text(cleanRatingTitle)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundColor(theme.colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(AppStrings.ReflexBlitz.summaryTitle)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, theme.spacing.base)
        .padding(.horizontal, theme.spacing.base)
    }

    // MARK: - Metrics Bento Grid
    private var metricsBentoGrid: some View {
        HStack(spacing: theme.spacing.sm) {
            metricCard(
                icon: "speedometer",
                color: theme.colors.brandPrimary,
                value: formattedAvgTime,
                title: AppStrings.ReflexBlitz.summaryAvgSpeedText,
                accessibilityLabel: String(format: "%@: %@", AppStrings.ReflexBlitz.summaryAvgSpeedText, formattedAvgTime)
            )

            metricCard(
                icon: "target",
                color: theme.colors.statusSuccess,
                value: "\(summary.correctWords)/\(summary.totalWords)",
                title: AppStrings.ReflexBlitz.summaryAccuracyText,
                accessibilityLabel: String(format: "%@: %lld/%lld", AppStrings.ReflexBlitz.summaryAccuracyText, summary.correctWords, summary.totalWords)
            )

            metricCard(
                icon: "flame.fill",
                color: theme.colors.brandSecondary,
                value: "x\(summary.maxComboStreak)",
                title: AppStrings.ReflexBlitz.summaryMaxComboText,
                accessibilityLabel: String(format: "%@: %lld", AppStrings.ReflexBlitz.summaryMaxComboText, summary.maxComboStreak)
            )
        }
        .padding(.horizontal, theme.spacing.base)
    }

    private func metricCard(
        icon: String,
        color: Color,
        value: String,
        title: String,
        accessibilityLabel: String
    ) -> some View {
        CraftCard(style: .outlined, padding: theme.spacing.md) {
            VStack(spacing: theme.spacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(color)
                }
                .accessibilityHidden(true)

                Text(value)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Practiced Words Section
    private var practicedWordsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "character.book.closed.fill")
                    .font(.subheadline.bold())
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(theme.colors.brandPrimary)

                Text(String(localized: "app.reflex.summary.practiced_words_count \(summary.attempts.count)"))
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding(.horizontal, theme.spacing.base)
            .accessibilityAddTraits(.isHeader)

            LazyVStack(spacing: theme.spacing.sm) {
                ForEach(summary.attempts) { attempt in
                    wordAttemptRow(attempt)
                }
            }
            .padding(.horizontal, theme.spacing.base)
        }
    }

    private func wordAttemptRow(_ attempt: ReflexBlitzAttempt) -> some View {
        let isMastered = isWordMastered(attempt: attempt)
        let timeFormatted = String(format: "%.1fs", Double(attempt.responseTimeMs) / 1000.0)

        return CraftCard(style: .outlined, padding: theme.spacing.base) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                wordAttemptHeader(attempt: attempt, isMasteredWord: isMastered)
                wordAttemptMeta(attempt: attempt)
                wordAttemptFooter(attempt: attempt, timeFormatted: timeFormatted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(attempt.lemma), \(attempt.definitionVi), \(timeFormatted)")
    }

    private func wordAttemptHeader(attempt: ReflexBlitzAttempt, isMasteredWord: Bool) -> some View {
        HStack(alignment: .center) {
            Text(attempt.lemma)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundColor(theme.colors.textPrimary)

            if let onSpeak = onSpeakWord {
                CraftSpeakerButton(
                    variant: .subtle,
                    size: .sm,
                    customTint: theme.colors.brandPrimary
                ) {
                    onSpeak(attempt.lemma)
                }
                .accessibilityLabel(String(localized: "app.reflex.summary.a11y_speak_word \(attempt.lemma)"))
            }

            Spacer()

            wordAttemptStatusBadge(attempt: attempt, isMasteredWord: isMasteredWord)
        }
    }

    @ViewBuilder
    private func wordAttemptStatusBadge(attempt: ReflexBlitzAttempt, isMasteredWord: Bool) -> some View {
        if isMasteredWord {
            CraftBadge(
                String(localized: "app.reflex.summary.mastered"),
                iconName: "checkmark.seal.fill",
                variant: .subtle,
                tone: .success,
                size: .sm,
                shape: .capsule
            )
        } else if attempt.isCorrect {
            CraftBadge(
                String(localized: "app.reflex.summary.correct"),
                iconName: "checkmark",
                variant: .subtle,
                tone: .primary,
                size: .sm,
                shape: .capsule
            )
        } else {
            CraftBadge(
                String(localized: "app.reflex.summary.retried"),
                iconName: "arrow.triangle.2.circlepath",
                variant: .subtle,
                tone: .warning,
                size: .sm,
                shape: .capsule
            )
        }
    }

    @ViewBuilder
    private func wordAttemptMeta(attempt: ReflexBlitzAttempt) -> some View {
        let metaParts = [attempt.pos, attempt.ipa].filter { !$0.isEmpty }
        if !metaParts.isEmpty {
            Text(metaParts.joined(separator: " • "))
                .font(theme.typography.phonetic)
                .foregroundColor(theme.colors.textMuted)
        }
    }

    private func wordAttemptFooter(attempt: ReflexBlitzAttempt, timeFormatted: String) -> some View {
        HStack(alignment: .center, spacing: theme.spacing.xs) {
            if !attempt.definitionVi.isEmpty {
                Text(attempt.definitionVi)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            CraftBadge(
                timeFormatted,
                iconName: "stopwatch.fill",
                variant: .subtle,
                tone: attempt.isCorrect ? .primary : .danger,
                size: .sm,
                shape: .capsule
            )
        }
    }

    private func isWordMastered(attempt: ReflexBlitzAttempt) -> Bool {
        if let matchingWord = practicedWords.first(where: { $0.id == attempt.wordId || $0.lemma.lowercased() == attempt.lemma.lowercased() }) {
            return matchingWord.isMastered
        }
        return false
    }

    // MARK: - Sticky Bottom Action Dock
    private var stickyBottomActionDock: some View {
        VStack(spacing: theme.spacing.xs) {
            CraftButton(
                String(localized: "app.reflex.summary.retry_drill"),
                iconName: "arrow.triangle.2.circlepath",
                variant: .ghost,
                size: .lg,
                isFullWidth: true,
                action: onRetry
            )

            CraftButton(
                AppStrings.ReflexBlitz.finishSave,
                iconName: "checkmark",
                variant: .primary,
                size: .lg,
                isFullWidth: true,
                action: onDone
            )
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.top, theme.spacing.sm)
        .padding(.bottom, theme.spacing.md)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .craftShadow(theme.shadows.sm)
        )
    }
}
