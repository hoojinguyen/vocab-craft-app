import CraftUIKit
import SwiftUI

/// Mode item presentation model for the Reflex Blitz Mode Selection Bento cards.
public struct ReflexBlitzModeItem: Identifiable, Equatable {
    public let mode: ReflexBlitzMode
    public let titleKey: LocalizedStringKey
    public let subtitleKey: LocalizedStringKey
    public let title: String
    public let subtitle: String
    public let badgeText: String
    public let iconName: String
    public let accentColor: Color

    public var id: String { mode.rawValue }

    public init(
        mode: ReflexBlitzMode,
        titleKey: LocalizedStringKey,
        subtitleKey: LocalizedStringKey,
        title: String,
        subtitle: String,
        badgeText: String,
        iconName: String,
        accentColor: Color
    ) {
        self.mode = mode
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.iconName = iconName
        self.accentColor = accentColor
    }

    public init(
        mode: ReflexBlitzMode,
        title: String,
        subtitle: String,
        badgeText: String,
        iconName: String,
        accentColor: Color
    ) {
        self.mode = mode
        self.titleKey = LocalizedStringKey(title)
        self.subtitleKey = LocalizedStringKey(subtitle)
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.iconName = iconName
        self.accentColor = accentColor
    }
}

/// Bento-style Mode Selection View allowing the user to select one of 4 Reflex Blitz drill modalities:
/// Speaking (Luyện nói), Typing (Gõ từ), Multiple Choice (Trắc nghiệm), and Listening (Phản xạ nghe).
/// Includes a 3-card Quick Stats Dashboard and 100% CraftUIKit tokens.
public struct ReflexBlitzModeSelectionView: View {
    @Environment(\.craftTheme) private var theme

    public let weeklyPracticedCount: Int
    public let weakWordsCount: Int
    public let averageSpeedSeconds: Double
    public let onSelectMode: (ReflexBlitzMode) -> Void
    public var onSelectConfig: ((ReflexBlitzDeepLinkConfig) -> Void)?
    public let onDismiss: () -> Void

    @State private var selectedModeTrigger: ReflexBlitzMode?

    public init(
        weeklyPracticedCount: Int = 0,
        weakWordsCount: Int = 0,
        averageSpeedSeconds: Double = 0.0,
        onSelectMode: @escaping (ReflexBlitzMode) -> Void,
        onSelectConfig: ((ReflexBlitzDeepLinkConfig) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.weeklyPracticedCount = weeklyPracticedCount
        self.weakWordsCount = weakWordsCount
        self.averageSpeedSeconds = averageSpeedSeconds
        self.onSelectMode = onSelectMode
        self.onSelectConfig = onSelectConfig
        self.onDismiss = onDismiss
    }

    public static func modeItem(for mode: ReflexBlitzMode) -> ReflexBlitzModeItem {
        switch mode {
        case .speaking:
            return ReflexBlitzModeItem(
                mode: .speaking,
                titleKey: AppStrings.ReflexBlitz.speakingTitle,
                subtitleKey: AppStrings.ReflexBlitz.speakingSubtitle,
                title: AppStrings.ReflexBlitz.speakingTitleText,
                subtitle: AppStrings.ReflexBlitz.speakingSubtitleText,
                badgeText: "6.0s",
                iconName: "waveform.and.mic",
                accentColor: Color(hex: 0xE06D3B)
            )
        case .typing:
            return ReflexBlitzModeItem(
                mode: .typing,
                titleKey: AppStrings.ReflexBlitz.typingTitle,
                subtitleKey: AppStrings.ReflexBlitz.typingSubtitle,
                title: AppStrings.ReflexBlitz.typingTitleText,
                subtitle: AppStrings.ReflexBlitz.typingSubtitleText,
                badgeText: "7.5s",
                iconName: "keyboard",
                accentColor: Color(hex: 0x8B5CF6)
            )
        case .multipleChoice:
            return ReflexBlitzModeItem(
                mode: .multipleChoice,
                titleKey: AppStrings.ReflexBlitz.mcTitle,
                subtitleKey: AppStrings.ReflexBlitz.mcSubtitle,
                title: AppStrings.ReflexBlitz.mcTitleText,
                subtitle: AppStrings.ReflexBlitz.mcSubtitleText,
                badgeText: "4.5s",
                iconName: "square.grid.2x2.fill",
                accentColor: Color(hex: 0x10B981)
            )
        case .listening:
            return ReflexBlitzModeItem(
                mode: .listening,
                titleKey: AppStrings.ReflexBlitz.listeningTitle,
                subtitleKey: AppStrings.ReflexBlitz.listeningSubtitle,
                title: AppStrings.ReflexBlitz.listeningTitleText,
                subtitle: AppStrings.ReflexBlitz.listeningSubtitleText,
                badgeText: "5.5s",
                iconName: "headphones",
                accentColor: Color(hex: 0x0284C7)
            )
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Dismiss Bar
                topDismissBar

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header Title & Subtitle Section
                        headerSection

                        // Quick Stats Dashboard
                        quickStatsDashboard

                        // 4 Bento Cards Grid
                        modeGrid

                        // Bottom Scaffolding Hint
                        footerHintSection
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedModeTrigger)
    }

    // MARK: - View Components

    private var topDismissBar: some View {
        HStack {
            CraftIconButton(
                iconName: "xmark",
                size: .md,
                shape: .circle,
                variant: .subtle,
                accessibilityLabelKey: AppStrings.Common.close,
                action: onDismiss
            )
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            CraftBadge(
                AppStrings.ReflexBlitz.hubBadge,
                iconName: "bolt.fill",
                variant: .subtle,
                tone: .primary,
                size: .md,
                shape: .capsule
            )

            CraftText(
                AppStrings.ReflexBlitz.hubTitle,
                style: .displaySerif,
                color: theme.colors.textPrimary,
                textAlignment: .center
            )

            CraftText(
                AppStrings.ReflexBlitz.hubSubtitle,
                style: .bodyMedium,
                color: theme.colors.textSecondary,
                textAlignment: .center
            )
        }
        .padding(.top, 4)
        .padding(.horizontal, 16)
    }

    private var quickStatsDashboard: some View {
        HStack(spacing: 10) {
            // 1. Weekly Practiced Words
            CraftCard(
                style: .outlined,
                cornerRadius: theme.radii.lg,
                padding: theme.spacing.sm
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        CraftIcon("flame.fill", size: .sm, color: theme.colors.brandPrimary)
                        CraftText(
                            verbatim: "\(weeklyPracticedCount)",
                            style: .metricRounded,
                            color: theme.colors.textPrimary
                        )
                    }
                    CraftText(
                        AppStrings.ReflexBlitz.weeklyWords(weeklyPracticedCount),
                        style: .caption,
                        color: theme.colors.textMuted,
                        lineLimit: 1
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 2. Weak Words
            CraftCard(
                style: .outlined,
                cornerRadius: theme.radii.lg,
                padding: theme.spacing.sm
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        CraftIcon("exclamationmark.triangle.fill", size: .sm, color: theme.colors.statusWarning)
                        CraftText(
                            verbatim: "\(weakWordsCount)",
                            style: .metricRounded,
                            color: theme.colors.textPrimary
                        )
                    }
                    CraftText(
                        AppStrings.ReflexBlitz.weakWords(weakWordsCount),
                        style: .caption,
                        color: theme.colors.textMuted,
                        lineLimit: 1
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 3. Avg Speed
            CraftCard(
                style: .outlined,
                cornerRadius: theme.radii.lg,
                padding: theme.spacing.sm
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        CraftIcon("bolt.fill", size: .sm, color: theme.colors.accent)
                        CraftText(
                            verbatim: String(format: "%.1fs", averageSpeedSeconds),
                            style: .metricRounded,
                            color: theme.colors.textPrimary
                        )
                    }
                    CraftText(
                        AppStrings.ReflexBlitz.avgSpeedLabel,
                        style: .caption,
                        color: theme.colors.textMuted,
                        lineLimit: 1
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
    }

    private var modeGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(ReflexBlitzMode.allCases) { mode in
                modeCard(for: Self.modeItem(for: mode))
            }
        }
        .padding(.horizontal, 18)
    }

    @ViewBuilder
    private func modeCard(for item: ReflexBlitzModeItem) -> some View {
        CraftActionCard(
            title: item.titleKey,
            subtitle: item.subtitleKey,
            iconName: item.iconName,
            badgeText: item.badgeText,
            badgeIcon: "stopwatch.fill",
            accentColor: item.accentColor,
            style: .tactile3D,
            showChevron: true
        ) {
            selectedModeTrigger = item.mode
            onSelectMode(item.mode)
        }
    }

    private var footerHintSection: some View {
        HStack(spacing: 8) {
            CraftIcon("sparkles", size: .sm, color: theme.colors.brandPrimary)
            CraftText(
                AppStrings.ReflexBlitz.hubFooterHint,
                style: .caption,
                color: theme.colors.textMuted,
                textAlignment: .center
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}
