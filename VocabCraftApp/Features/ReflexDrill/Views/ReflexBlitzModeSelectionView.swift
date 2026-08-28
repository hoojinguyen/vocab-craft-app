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

    public static func modeItem(
        for mode: ReflexBlitzMode,
        colors: CraftColorTokens = CraftDefaultColorTokens()
    ) -> ReflexBlitzModeItem {
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
                accentColor: colors.brandPrimary
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
                accentColor: colors.streakLegendary
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
                accentColor: colors.statusSuccess
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
                accentColor: colors.statusInfo
            )
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: theme.spacing.md),
            GridItem(.flexible(), spacing: theme.spacing.md)
        ]
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Dismiss Bar
                topDismissBar

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: theme.spacing.lg) {
                        // Header Title & Subtitle Section
                        headerSection

                        // 4 Bento Cards Grid (Primary Core Action)
                        modeGrid

                        // Quick Stats Dashboard (Secondary support information)
                        quickStatsDashboard

                        // Bottom Scaffolding Hint
                        footerHintSection
                    }
                    .padding(.bottom, theme.spacing.xl)
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
                size: .sm,
                shape: .circle,
                variant: .subtle,
                style: nil,
                customTint: theme.colors.textSecondary,
                accessibilityLabelKey: AppStrings.Common.close,
                action: onDismiss
            )
            Spacer()
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.top, theme.spacing.base)
    }

    private var headerSection: some View {
        VStack(spacing: theme.spacing.sm) {
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
        .padding(.top, theme.spacing.xs)
        .padding(.horizontal, theme.spacing.base)
    }

    private var modeGrid: some View {
        LazyVGrid(columns: columns, spacing: theme.spacing.md) {
            ForEach(ReflexBlitzMode.allCases) { mode in
                modeCard(for: Self.modeItem(for: mode, colors: theme.colors))
            }
        }
        .padding(.horizontal, theme.spacing.base)
    }

    @ViewBuilder
    private func modeCard(for item: ReflexBlitzModeItem) -> some View {
        CraftActionCard(
            title: item.titleKey,
            subtitle: item.subtitleKey,
            iconName: item.iconName,
            badgeText: item.badgeText,
            badgeIcon: nil,
            accentColor: item.accentColor,
            style: .tactile3D,
            showChevron: false
        ) {
            selectedModeTrigger = item.mode
            onSelectMode(item.mode)
        }
    }

    private var quickStatsDashboard: some View {
        HStack(spacing: theme.spacing.sm) {
            CraftBadge(
                AppStrings.ReflexBlitz.weeklyWords(weeklyPracticedCount),
                variant: .subtle,
                tone: .neutral,
                size: .sm,
                shape: .capsule
            )

            CraftBadge(
                AppStrings.ReflexBlitz.weakWords(weakWordsCount),
                variant: .subtle,
                tone: weakWordsCount > 0 ? .warning : .neutral,
                size: .sm,
                shape: .capsule
            )

            CraftBadge(
                String(format: "%.1fs %@", averageSpeedSeconds, AppStrings.ReflexBlitz.avgSpeedLabelText),
                variant: .subtle,
                tone: .primary,
                size: .sm,
                shape: .capsule
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, theme.spacing.base)
    }

    private var footerHintSection: some View {
        CraftText(
            AppStrings.ReflexBlitz.hubFooterHint,
            style: .caption,
            color: theme.colors.textMuted,
            textAlignment: .center
        )
        .padding(.horizontal, theme.spacing.lg)
        .padding(.top, theme.spacing.sm)
    }
}
