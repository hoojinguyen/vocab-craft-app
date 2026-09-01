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
        summary.ratingTier.localizedTitle
    }

    private var starCount: Int {
        summary.ratingTier.starCount
    }

    private var headerIconName: String {
        summary.ratingTier.iconName
    }

    private var headerAccentColor: Color {
        switch summary.ratingTier {
        case .master:
            return theme.colors.brandPrimary
        case .swift:
            return theme.colors.brandSecondary
        case .steady:
            return theme.colors.accent
        }
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                summaryContent
                    .padding(.bottom, summary.weakWordAttempts.isEmpty ? 140 : 200)
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
                perfectScoreView
            }
        }
        .padding(.top, theme.spacing.base)
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftCard(
                style: .tactile3D,
                cornerRadius: theme.radii.xl,
                padding: theme.spacing.base,
                customTint: headerAccentColor,
                customBorderColor: headerAccentColor.opacity(0.3),
                customBottomColor: headerAccentColor.opacity(0.7)
            ) {
                Image(systemName: headerIconName)
                    .font(theme.typography.displayLarge)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
            }
            .frame(width: 80, height: 80)
            .accessibilityHidden(true)

            VStack(spacing: theme.spacing.xs) {
                Text(cleanRatingTitle)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(theme.colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                ratingStarsView
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
                    .font(theme.typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(index <= starCount ? theme.colors.accent : theme.colors.textMuted.opacity(0.35))
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Bento Metrics Grid
    private var bentoMetricsGrid: some View {
        HStack(spacing: theme.spacing.sm) {
            bentoCard(
                iconName: "speedometer",
                tint: theme.colors.brandPrimary,
                value: formattedAvgTime,
                title: String(localized: "app.reflex.summary.avg_speed"),
                accessibilityLabel: String(localized: "app.reflex.summary.a11y_avg_speed \(formattedAvgTime)")
            )

            bentoCard(
                iconName: "target",
                tint: theme.colors.statusSuccess,
                value: "\(summary.correctWords)/\(summary.totalWords)",
                title: String(localized: "app.reflex.summary.accuracy"),
                accessibilityLabel: String(localized: "app.reflex.summary.a11y_accuracy \(summary.correctWords) \(summary.totalWords)")
            )

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
        CraftCard(style: .tactile3D, padding: theme.spacing.md) {
            VStack(spacing: theme.spacing.xs) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: iconName)
                        .font(theme.typography.bodyLarge)
                        .fontWeight(.semibold)
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
                    .font(theme.typography.headline)
                    .accessibilityHidden(true)

                Text(AppStrings.ReflexBlitz.weakWordsHeader)
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

    // MARK: - Active Recall Vocabulary Row
    private func weakWordRow(for weak: ReflexBlitzAttempt) -> some View {
        CraftCard(
            style: .tactile3D,
            padding: theme.spacing.base,
            customBorderColor: theme.colors.statusDanger.opacity(0.4),
            customBottomColor: theme.colors.statusDanger.opacity(0.8)
        ) {
            HStack(alignment: .center, spacing: theme.spacing.sm) {
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
                                weak.cleanPos,
                                variant: .subtle,
                                tone: .neutral,
                                size: .sm
                            )
                        }

                        CraftBadge(
                            weak.cleanLevel.uppercased(),
                            variant: .subtle,
                            tone: .primary,
                            size: .sm
                        )
                    }
                }

                Spacer(minLength: theme.spacing.xs)

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
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(weak.lemma), \(weak.cleanPos)")
    }

    // MARK: - Perfect Score State
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

    // MARK: - Sticky Bottom Action Dock
    public var bottomActionDock: some View {
        VStack(spacing: theme.spacing.md) {
            if !summary.weakWordAttempts.isEmpty {
                CraftButton(
                    AppStrings.ReflexBlitz.redrillWeak,
                    variant: .tactile,
                    size: .lg,
                    isFullWidth: true,
                    customTint: theme.colors.brandPrimary,
                    action: onReDrillWeak
                )

                CraftButton(
                    AppStrings.ReflexBlitz.finishSaveText,
                    variant: .secondary,
                    size: .lg,
                    isFullWidth: true,
                    action: onFinish
                )
            } else {
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
        .padding(.top, theme.spacing.md)
        .padding(.bottom, theme.spacing.lg)
        .background(
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [theme.colors.canvasBackground.opacity(0), theme.colors.canvasBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)

                theme.colors.canvasBackground
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }
}
