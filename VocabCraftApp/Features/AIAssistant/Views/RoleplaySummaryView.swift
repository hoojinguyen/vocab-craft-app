import CraftUIKit
import SwiftUI

public struct RoleplaySummaryView: View {
    public let summary: RoleplaySessionSummary
    public let onStartReflex: (() -> Void)?
    public let onSaveToVault: ((SentenceRefinementPair) -> Void)?
    public let onRemoveFromVault: ((SentenceRefinementPair) -> Void)?
    public let onDismiss: () -> Void

    @Environment(\.craftTheme) private var theme
    @Environment(\.appRouter) private var appRouter
    @State private var confettiTrigger: Bool
    @State private var savedRefinementIds: Set<UUID> = []

    public var masteredWords: [String] {
        summary.targetWordsMastered
    }

    public var unmasteredWords: [String] {
        let masteredSet = Set(summary.targetWordsMastered)
        return summary.targetWordsAttempted.filter { !masteredSet.contains($0) }
    }

    public init(
        summary: RoleplaySessionSummary,
        onStartReflex: (() -> Void)? = nil,
        onSaveToVault: ((SentenceRefinementPair) -> Void)? = nil,
        onRemoveFromVault: ((SentenceRefinementPair) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.summary = summary
        self.onStartReflex = onStartReflex
        self.onSaveToVault = onSaveToVault
        self.onRemoveFromVault = onRemoveFromVault
        self.onDismiss = onDismiss
        let ratio = summary.targetWordsAttempted.isEmpty ? 1.0 : Double(summary.targetWordsMastered.count) / Double(summary.targetWordsAttempted.count)
        self._confettiTrigger = State(initialValue: ratio >= 0.8)
    }

    public init(
        summary: RoleplaySessionSummary,
        onDismiss: @escaping () -> Void
    ) {
        self.init(
            summary: summary,
            onStartReflex: nil,
            onSaveToVault: nil,
            onRemoveFromVault: nil,
            onDismiss: onDismiss
        )
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: theme.spacing.lg) {
                    companionPraiseHeader

                    scoreCard

                    targetWordsBreakdownCard

                    takeawaysSection

                    actionButtonsSection
                }
                .frame(maxWidth: .infinity)
            }
        }
        .craftConfetti(isTriggered: $confettiTrigger, particleCount: 36)
    }

    // MARK: - Subviews

    private var companionPraiseHeader: some View {
        VStack(spacing: theme.spacing.sm) {
            ZStack {
                Circle()
                    .fill(theme.colors.accent.opacity(0.12))
                    .frame(width: theme.spacing.xxl, height: theme.spacing.xxl)

                Circle()
                    .stroke(theme.colors.accent.opacity(0.35), lineWidth: theme.depths.depthSm)
                    .frame(width: theme.spacing.xxl, height: theme.spacing.xxl)

                CraftIcon(.sparkles, size: .lg, color: theme.colors.accent)
            }
            .padding(.top, theme.spacing.xl)

            Text(AppStrings.AIAssistant.summaryCongratulations)
                .font(theme.typography.titleLarge)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    private var scoreCard: some View {
        CraftCard(style: .outlined, cornerRadius: theme.radii.xl, padding: theme.spacing.lg) {
            VStack(spacing: theme.spacing.md) {
                HStack {
                    Text(AppStrings.AIAssistant.summaryFluencyScore)
                        .font(theme.typography.bodyLarge)
                        .foregroundStyle(theme.colors.textSecondary)
                    Spacer()
                    Text("\(summary.fluencyScore)%")
                        .font(theme.typography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.statusSuccess)
                }

                CraftDivider()

                HStack {
                    Text(AppStrings.AIAssistant.summaryMasteredWords)
                        .font(theme.typography.bodyLarge)
                        .foregroundStyle(theme.colors.textSecondary)
                    Spacer()
                    Text("\(summary.targetWordsMastered.count) / \(summary.targetWordsAttempted.count)")
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.brandPrimary)
                }
            }
        }
        .padding(.horizontal, theme.spacing.base)
    }

    @ViewBuilder
    private var targetWordsBreakdownCard: some View {
        if !masteredWords.isEmpty || !unmasteredWords.isEmpty {
            CraftCard(style: .outlined, cornerRadius: theme.radii.xl, padding: theme.spacing.md) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    if !masteredWords.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            CraftBadge(
                                AppStrings.AIAssistant.summaryMasteredWords,
                                symbol: .checkmarkCircle,
                                variant: .subtle,
                                tone: .success
                            )

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: theme.spacing.xs) {
                                    ForEach(masteredWords, id: \.self) { word in
                                        CraftBadge(
                                            verbatim: word,
                                            symbol: .checkmarkCircle,
                                            variant: .subtle,
                                            tone: .success,
                                            size: .sm
                                        )
                                    }
                                }
                            }
                        }
                    }

                    if !masteredWords.isEmpty && !unmasteredWords.isEmpty {
                        CraftDivider()
                    }

                    if !unmasteredWords.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            CraftBadge(
                                AppStrings.AIAssistant.summaryUnmasteredWords,
                                symbol: .exclamationmarkTriangle,
                                variant: .subtle,
                                tone: .warning
                            )

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: theme.spacing.xs) {
                                    ForEach(unmasteredWords, id: \.self) { word in
                                        CraftBadge(
                                            verbatim: word,
                                            symbol: .exclamationmarkTriangle,
                                            variant: .subtle,
                                            tone: .warning,
                                            size: .sm
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, theme.spacing.base)
        }
    }

    @ViewBuilder
    private var takeawaysSection: some View {
        if !summary.refinements.isEmpty {
            CraftCard(style: .outlined, cornerRadius: theme.radii.xl, padding: theme.spacing.md) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text(AppStrings.AIAssistant.summaryTakeawaysTitle)
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.textPrimary)

                    ForEach(summary.refinements) { refinement in
                        let isSaved = savedRefinementIds.contains(refinement.id)
                        HStack(alignment: .center, spacing: theme.spacing.sm) {
                            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                                Text(refinement.originalUserSentence)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textMuted)
                                Text(refinement.refinedNativeSentence)
                                    .font(theme.typography.bodyMedium)
                                    .foregroundStyle(theme.colors.brandPrimary)
                            }

                            Spacer(minLength: theme.spacing.xs)

                            CraftIconButton(
                                symbol: isSaved ? .bookmarkFill : .bookmark,
                                size: .sm,
                                variant: isSaved ? .filled : .subtle,
                                isSelected: isSaved,
                                accessibilityLabelKey: AppStrings.AIAssistant.summarySaveToVault
                            ) {
                                if isSaved {
                                    savedRefinementIds.remove(refinement.id)
                                    onRemoveFromVault?(refinement)
                                } else {
                                    savedRefinementIds.insert(refinement.id)
                                    onSaveToVault?(refinement)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, theme.spacing.base)
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftButton(
                AppStrings.AIAssistant.summaryActionReflex,
                variant: .primary,
                size: .lg,
                isFullWidth: true
            ) {
                if let onStartReflex {
                    onStartReflex()
                } else {
                    onDismiss()
                    appRouter.navigateToReflex()
                }
            }

            CraftButton(
                AppStrings.Common.done,
                variant: .secondary,
                size: .md,
                isFullWidth: true
            ) {
                onDismiss()
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.top, theme.spacing.sm)
        .padding(.bottom, theme.spacing.xl)
    }
}
