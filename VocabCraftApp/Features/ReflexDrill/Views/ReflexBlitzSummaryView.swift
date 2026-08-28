import CraftUIKit
import SwiftUI

public struct ReflexBlitzSummaryView: View {
    @Environment(\.craftTheme) private var theme

    public let summary: ReflexBlitzSessionSummary
    public let onSpeakWord: ((String) -> Void)?
    public let onReDrillWeak: () -> Void
    public let onFinish: () -> Void

    @State private var isSparkleTriggered: Bool = true

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

    private var formattedAvgTime: String {
        String(format: "%.1fs", Double(summary.averageResponseTimeMs) / 1000.0)
    }

    private var cleanRatingTitle: String {
        summary.speedRating
            .replacingOccurrences(of: "⚡️ ", with: "")
            .replacingOccurrences(of: "🔥 ", with: "")
            .replacingOccurrences(of: "🌱 ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
    }

    public var summaryContent: some View {
        VStack(spacing: theme.spacing.lg) {
            headerView
            bentoMetricsGrid

            if !summary.weakWordAttempts.isEmpty {
                weakWordsSection
            } else {
                perfectScoreCard
            }
        }
        .padding(.top, theme.spacing.base)
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: theme.spacing.md) {
            // Icon with decorative background ring
            ZStack {
                Circle()
                    .fill(headerAccentColor.opacity(0.12))
                    .frame(width: 68, height: 68)
                Circle()
                    .strokeBorder(headerAccentColor.opacity(0.24), lineWidth: 1.5)
                    .frame(width: 68, height: 68)

                Image(systemName: headerIconName)
                    .font(.system(size: 32, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(headerAccentColor)
            }
            .craftShadow(theme.shadows.sm)
            .accessibilityHidden(true)

            // Rating title & subtitle
            VStack(spacing: theme.spacing.xs) {
                Text(cleanRatingTitle)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(theme.colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                ratingStarsView

                Text(String(localized: "app.reflex.summary.title"))
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textMuted)
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "app.reflex.summary.a11y_header_format \(cleanRatingTitle)"))
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

    // MARK: - Bento Metrics Grid
    private var bentoMetricsGrid: some View {
        HStack(spacing: theme.spacing.sm) {
            // Metric 1: Avg Speed
            bentoCard(
                iconName: "speedometer",
                tint: theme.colors.brandPrimary,
                value: formattedAvgTime,
                title: String(localized: "app.reflex.summary.avg_speed"),
                accessibilityLabel: String(localized: "app.reflex.summary.a11y_avg_speed \(formattedAvgTime)")
            )

            // Metric 2: Accuracy
            bentoCard(
                iconName: "target",
                tint: theme.colors.statusSuccess,
                value: "\(summary.correctWords)/\(summary.totalWords)",
                title: String(localized: "app.reflex.summary.accuracy"),
                accessibilityLabel: String(localized: "app.reflex.summary.a11y_accuracy \(summary.correctWords) \(summary.totalWords)")
            )

            // Metric 3: Max Combo
            bentoCard(
                iconName: "flame.fill",
                tint: theme.colors.brandSecondary,
                value: "x\(summary.maxComboStreak)",
                title: String(localized: "app.reflex.summary.max_combo"),
                accessibilityLabel: String(localized: "app.reflex.summary.a11y_max_combo \(summary.maxComboStreak)")
            )
        }
        .padding(.horizontal, theme.spacing.base)
    }

    private func bentoCard(
        iconName: String,
        tint: Color,
        value: String,
        title: String,
        accessibilityLabel: String
    ) -> some View {
        CraftCard(style: .outlined, padding: theme.spacing.md) {
            VStack(spacing: theme.spacing.xs) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(tint)
                }
                .accessibilityHidden(true)

                Text(value)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
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

    // MARK: - Weak Words Section
    private var weakWordsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "exclamationmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(theme.colors.statusDanger)
                    .font(.headline)
                    .accessibilityHidden(true)

                Text(String(localized: "app.reflex.summary.weak_words_header \(summary.weakWordAttempts.count)"))
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(theme.colors.textPrimary)
            }
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

    // MARK: - 3-Tier Vocabulary Row
    private func weakWordRow(for weak: ReflexBlitzAttempt) -> some View {
        let timeLabel = weak.responseTimeMs >= 6000 ? String(localized: "app.reflex.summary.timeout_label") : String(format: "%.1fs", Double(weak.responseTimeMs) / 1000.0)
        let meta = [weak.pos, weak.ipa].filter { !$0.isEmpty }.joined(separator: " • ")

        return CraftCard(style: .outlined, padding: theme.spacing.base) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                // Tier 1: Lemma text on the left, Audio Speaker button on the right
                HStack(alignment: .center) {
                    Text(weak.lemma)
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundStyle(theme.colors.textPrimary)

                    Spacer()

                    if let onSpeak = onSpeakWord {
                        CraftSpeakerButton(
                            variant: .subtle,
                            size: .sm,
                            customTint: theme.colors.brandPrimary
                        ) {
                            onSpeak(weak.lemma)
                        }
                        .accessibilityLabel(String(localized: "app.reflex.summary.a11y_speak_word \(weak.lemma)"))
                    }
                }

                // Tier 2: Part of Speech & IPA phonetics metadata
                if !meta.isEmpty {
                    Text(meta)
                        .font(theme.typography.phonetic)
                        .foregroundStyle(theme.colors.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                // Tier 3: Vietnamese definition on the left, response time badge on the right
                HStack(alignment: .center, spacing: theme.spacing.xs) {
                    if !weak.definitionVi.isEmpty {
                        Text(weak.definitionVi)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    CraftBadge(
                        timeLabel,
                        iconName: "stopwatch.fill",
                        variant: .subtle,
                        tone: .danger,
                        size: .sm
                    )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "app.reflex.summary.a11y_weak_word \(weak.lemma) \(timeLabel)"))
    }

    // MARK: - Perfect Score State
    private var perfectScoreCard: some View {
        CraftCard(style: .elevated, customTint: theme.colors.surfaceCard) {
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: "medal.fill")
                    .font(.system(size: 44, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(theme.colors.accent)
                    .accessibilityHidden(true)

                Text(String(localized: "app.reflex.summary.perfect_title"))
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(String(localized: "app.reflex.summary.perfect_desc"))
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .padding(.horizontal, theme.spacing.sm)
        }
        .padding(.horizontal, theme.spacing.base)
        .craftSparkle(isTriggered: $isSparkleTriggered, particleCount: 25)
    }

    // MARK: - Sticky Bottom Action Dock
    private var bottomActionDock: some View {
        VStack(spacing: theme.spacing.xs) {
            if !summary.weakWordAttempts.isEmpty {
                // Primary Action: Re-drill weak words
                CraftButton(
                    String(localized: "app.reflex.summary.redrill_weak \(summary.weakWordAttempts.count)"),
                    iconName: "arrow.triangle.2.circlepath",
                    variant: .primary,
                    size: .lg,
                    isFullWidth: true,
                    customTint: theme.colors.statusDanger,
                    action: onReDrillWeak
                )

                // Secondary Action: Finish & Save
                CraftButton(
                    String(localized: "app.reflex.summary.finish_save"),
                    variant: .ghost,
                    size: .md,
                    isFullWidth: true,
                    action: onFinish
                )
            } else {
                // Primary Action: Finish & Save
                CraftButton(
                    String(localized: "app.reflex.summary.finish_save"),
                    iconName: "checkmark",
                    variant: .primary,
                    size: .lg,
                    isFullWidth: true,
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
