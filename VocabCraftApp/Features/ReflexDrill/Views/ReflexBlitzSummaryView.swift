import CraftUIKit
import SwiftUI

public struct ReflexBlitzSummaryView: View {
    @Environment(\.craftTheme) private var theme

    public let summary: ReflexBlitzSessionSummary
    public let onSpeakWord: ((String) -> Void)?
    public let onReDrillWeak: () -> Void
    public let onFinish: () -> Void

    @State private var isCelebrationTriggered: Bool = false

    public init(
        summary: ReflexBlitzSessionSummary,
        onSpeakWord: ((String) -> Void)? = nil,
        onReDrillWeak: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.summary = summary
        self.onSpeakWord = onSpeakWord
        self.onReDrillWeak = onReDrillWeak
        self.onFinish = onFinish
    }

    private var isMasterLevel: Bool {
        summary.speedRating.contains("Master") || (starCount == 3 && summary.weakWordAttempts.isEmpty)
    }

    private var formattedAvgTime: String {
        String(format: "%.1fs", Double(summary.averageResponseTimeMs) / 1000.0)
    }

    private var localizedRatingTitle: String {
        AppStrings.ReflexBlitz.localizedRatingTitle(for: summary.speedRating)
    }

    private var starCount: Int {
        if summary.speedRating.contains("Master") {
            return 3
        } else if summary.speedRating.contains("Swift") {
            return 2
        } else {
            return 1
        }
    }

    private var headerIconName: String {
        if summary.speedRating.contains("Master") {
            return "bolt.shield.fill"
        } else if summary.speedRating.contains("Swift") {
            return "flame.fill"
        } else {
            return "sparkles"
        }
    }

    private var headerAccentColor: Color {
        if summary.speedRating.contains("Master") {
            return theme.colors.brandPrimary
        } else if summary.speedRating.contains("Swift") {
            return theme.colors.brandSecondary
        } else {
            return theme.colors.statusSuccess
        }
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                summaryContent
                    .padding(.bottom, summary.weakWordAttempts.isEmpty ? 110 : 160)
            }

            bottomActionDock
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
        .craftConfetti(isTriggered: $isCelebrationTriggered, particleCount: 40)
        .task {
            if isMasterLevel {
                try? await Task.sleep(for: .milliseconds(150))
                isCelebrationTriggered = true
            }
        }
        .sensoryFeedback(.success, trigger: isCelebrationTriggered) { _, isTriggered in isTriggered }
    }

    public var summaryContent: some View {
        VStack(spacing: theme.spacing.lg) {
            headerView
            bentoMetricsGrid

            if !summary.weakWordAttempts.isEmpty {
                weakWordsSection
            } else {
                perfectScoreView
            }
        }
        .padding(.top, theme.spacing.base)
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: theme.spacing.md) {
            // Hero badge tactile 3D squircle container
            ZStack {
                Image(systemName: headerIconName)
                    .font(.system(size: 30, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(headerAccentColor)
            }
            .frame(width: 64, height: 64)
            .craftSurface(
                style: .tactile3D,
                shape: RoundedRectangle(cornerRadius: theme.radii.lg),
                customTint: headerAccentColor.opacity(0.12)
            )
            .accessibilityHidden(true)

            // Rating title & stars (no redundant announcement subtitle)
            VStack(spacing: theme.spacing.xs) {
                Text(localizedRatingTitle)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                ratingStarsView
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "app.reflex.summary.a11y_header_format", bundle: .module), localizedRatingTitle))
    }

    // MARK: - Rating Stars
    private var ratingStarsView: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(1...3, id: \.self) { index in
                Image(systemName: index <= starCount ? "star.fill" : "star")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(index <= starCount ? theme.colors.accent : theme.colors.textMuted.opacity(0.35))
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Bento Metrics Grid (Typography-First, Tactile 3D)
    private var bentoMetricsGrid: some View {
        HStack(spacing: theme.spacing.sm) {
            // Metric 1: Avg Speed
            bentoCard(
                value: formattedAvgTime,
                title: AppStrings.ReflexBlitz.summaryAvgSpeedText,
                accessibilityLabel: String(format: String(localized: "app.reflex.summary.a11y_avg_speed", bundle: .module), formattedAvgTime)
            )

            // Metric 2: Accuracy
            bentoCard(
                value: "\(summary.correctWords)/\(summary.totalWords)",
                title: AppStrings.ReflexBlitz.summaryAccuracyText,
                accessibilityLabel: String(format: String(localized: "app.reflex.summary.a11y_accuracy", bundle: .module), summary.correctWords, summary.totalWords)
            )

            // Metric 3: Max Combo
            bentoCard(
                value: "x\(summary.maxComboStreak)",
                title: AppStrings.ReflexBlitz.summaryMaxComboText,
                accessibilityLabel: String(format: String(localized: "app.reflex.summary.a11y_max_combo", bundle: .module), summary.maxComboStreak)
            )
        }
        .padding(.horizontal, theme.spacing.base)
    }

    private func bentoCard(
        value: String,
        title: String,
        accessibilityLabel: String
    ) -> some View {
        CraftCard(style: .tactile3D, padding: theme.spacing.md) {
            VStack(spacing: theme.spacing.xs) {
                Text(value)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Weak Words Section (Active Recall, Tactile 3D with Subtle Red Danger Rim)
    private var weakWordsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(AppStrings.ReflexBlitz.weakWordsHeader)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)
                .padding(.horizontal, theme.spacing.base)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: theme.spacing.sm) {
                ForEach(summary.weakWordAttempts) { weak in
                    weakWordRow(for: weak)
                }
            }
            .padding(.horizontal, theme.spacing.base)
        }
    }

    // MARK: - Vocabulary Row (Active Recall - No definition, Subtle Red Danger 3D Rim)
    private func weakWordRow(for weak: ReflexBlitzAttempt) -> some View {
        CraftCard(
            style: .tactile3D,
            padding: theme.spacing.md,
            customBorderColor: theme.colors.statusDanger.opacity(0.4),
            customBottomColor: theme.colors.statusDanger.opacity(0.8)
        ) {
            HStack(alignment: .center, spacing: theme.spacing.md) {
                // Word Details (Lemma, IPA, POS, CEFR) - Active Recall, no definition
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(weak.lemma)
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if !weak.ipa.isEmpty {
                        Text(weak.ipa)
                            .font(theme.typography.phonetic)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: theme.spacing.xs) {
                        if !weak.pos.isEmpty {
                            CraftBadge(
                                verbatim: weak.cleanPos,
                                variant: .subtle,
                                tone: .neutral,
                                size: .sm
                            )
                        }

                        CraftBadge(
                            verbatim: weak.cleanLevel.uppercased(),
                            variant: .subtle,
                            tone: .primary,
                            size: .sm
                        )
                    }
                }

                Spacer(minLength: theme.spacing.xs)

                // Speaker audio button on trailing edge
                if let onSpeak = onSpeakWord {
                    CraftSpeakerButton(
                        variant: .subtle,
                        size: .sm,
                        customTint: theme.colors.brandPrimary
                    ) {
                        onSpeak(weak.lemma)
                    }
                    .accessibilityLabel(String(format: String(localized: "app.reflex.summary.a11y_speak_word", bundle: .module), weak.lemma))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "app.reflex.summary.a11y_weak_word", bundle: .module), weak.lemma, weak.cleanPos))
    }

    // MARK: - Perfect Score State (Clean, Unboxed, Airy)
    private var perfectScoreView: some View {
        VStack(spacing: theme.spacing.xs) {
            Text(AppStrings.ReflexBlitz.perfectDesc)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.xl)
                .padding(.vertical, theme.spacing.base)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sticky Bottom Action Dock (Icon-free, Concise Text)
    private var bottomActionDock: some View {
        VStack(spacing: theme.spacing.xs) {
            if !summary.weakWordAttempts.isEmpty {
                // Primary Action: Re-drill weak words (Brand Primary tactile button, no icon)
                CraftButton(
                    AppStrings.ReflexBlitz.redrillWeak,
                    variant: .tactile,
                    size: .lg,
                    isFullWidth: true,
                    customTint: theme.colors.brandPrimary,
                    action: onReDrillWeak
                )

                // Secondary Action: Done (no icon)
                CraftButton(
                    AppStrings.ReflexBlitz.finishSaveText,
                    variant: .secondary,
                    size: .md,
                    isFullWidth: true,
                    action: onFinish
                )
            } else {
                // Primary Action: Done (Brand Primary tactile button, no icon)
                CraftButton(
                    AppStrings.ReflexBlitz.finishSaveText,
                    variant: .tactile,
                    size: .lg,
                    isFullWidth: true,
                    customTint: theme.colors.brandPrimary,
                    action: onFinish
                )
            }
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
