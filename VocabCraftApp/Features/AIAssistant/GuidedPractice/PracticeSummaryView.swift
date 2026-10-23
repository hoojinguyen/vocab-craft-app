import CraftUIKit
import SwiftUI

/// Display representation of communicative objective results.
public enum PracticeObjectiveDisplayStatus: String, Sendable, Equatable {
    case achieved
    case notYet
    case notObserved

    public var tone: CraftBadgeTone {
        switch self {
        case .achieved: return .success
        case .notYet: return .warning
        case .notObserved: return .neutral
        }
    }

    public var titleKey: LocalizedStringKey {
        switch self {
        case .achieved: return AppStrings.GuidedPractice.statusAchieved
        case .notYet: return AppStrings.GuidedPractice.statusNotYet
        case .notObserved: return AppStrings.GuidedPractice.statusNotObserved
        }
    }
}

/// Retrospective summary screen presenting communicative evidence, objective outcomes,
/// and persistence status. Excludes legacy fluency scores and XP awards.
public struct PracticeSummaryView: View {
    @Environment(\.craftTheme) private var theme

    public let summary: PracticeSummary
    public let evidence: [WordUseEvidence]
    public let onContinue: () -> Void
    public let onDelete: (UUID) -> Void

    @State private var showDeleteConfirmation: Bool = false

    public init(
        summary: PracticeSummary,
        evidence: [WordUseEvidence] = [],
        onContinue: @escaping () -> Void,
        onDelete: @escaping (UUID) -> Void
    ) {
        self.summary = summary
        self.evidence = evidence
        self.onContinue = onContinue
        self.onDelete = onDelete
    }

    private var relevantEvidence: [WordUseEvidence] {
        if summary.evidenceIds.isEmpty {
            return evidence
        }
        return evidence.filter { summary.evidenceIds.contains($0.id) }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                // Header
                headerSection

                // Unsaved Warning Banner
                if !summary.persisted {
                    unsavedWarningBanner
                }

                // Objectives Section
                objectivesSection

                // Vocabulary Evidence Section
                evidenceSection

                // Actions
                actionsSection
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.vertical, theme.spacing.lg)
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
        .craftDialog(
            isPresented: $showDeleteConfirmation,
            titleKey: AppStrings.GuidedPractice.summaryDeleteConfirmTitle,
            messageKey: AppStrings.GuidedPractice.summaryDeleteConfirmMessage,
            iconName: "trash.fill",
            iconColor: theme.colors.danger,
            primaryButtonTitleKey: AppStrings.GuidedPractice.summaryDeleteConfirmAction,
            primaryButtonVariant: .danger,
            primaryAction: {
                onDelete(summary.sessionId)
            },
            cancelButtonTitleKey: AppStrings.Common.cancel,
            cancelButtonVariant: .outline,
            cancelAction: {}
        )
    }
}

// MARK: - Subviews

private extension PracticeSummaryView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.sm) {
                CraftText(
                    AppStrings.GuidedPractice.summaryTitle,
                    style: .titleLarge,
                    color: theme.colors.textPrimary
                )

                Spacer()

                if summary.status == .completed {
                    CraftBadge(
                        AppStrings.GuidedPractice.summaryStatusCompleted,
                        tone: .success,
                        size: .md
                    )
                } else {
                    CraftBadge(
                        AppStrings.GuidedPractice.summaryStatusPartial,
                        tone: .neutral,
                        size: .md
                    )
                }
            }

            CraftText(
                AppStrings.GuidedPractice.summarySubtitle,
                style: .bodyMedium,
                color: theme.colors.textSecondary
            )
        }
    }

    private var unsavedWarningBanner: some View {
        CraftCard(style: .outlined, customBorderColor: theme.colors.warning) {
            HStack(alignment: .top, spacing: theme.spacing.md) {
                CraftIcon(
                    "exclamationmark.triangle.fill",
                    size: .md,
                    color: theme.colors.warning
                )

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    CraftBadge(
                        AppStrings.GuidedPractice.summaryUnsavedBadge,
                        tone: .warning,
                        size: .sm
                    )

                    CraftText(
                        AppStrings.GuidedPractice.summaryUnsavedMessage,
                        style: .caption,
                        color: theme.colors.warning
                    )
                }

                Spacer()
            }
        }
    }

    private var objectivesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            CraftText(
                AppStrings.GuidedPractice.summaryObjectivesTitle,
                style: .headline,
                color: theme.colors.textPrimary
            )

            ForEach(summary.objectiveResults, id: \.objectiveId) { result in
                let displayStatus = Self.objectiveStatus(for: result, sessionStatus: summary.status)
                CraftCard(style: .elevated) {
                    HStack(spacing: theme.spacing.sm) {
                        CraftText(
                            AppStrings.GuidedPractice.objectiveTitle(for: result.objectiveId),
                            style: .bodyMedium,
                            color: theme.colors.textPrimary
                        )

                        Spacer()

                        CraftBadge(
                            displayStatus.titleKey,
                            tone: displayStatus.tone,
                            size: .md
                        )
                    }
                }
            }
        }
    }

    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            CraftText(
                AppStrings.GuidedPractice.summaryEvidenceTitle,
                style: .headline,
                color: theme.colors.textPrimary
            )

            if summary.perWordProgress.isEmpty && relevantEvidence.isEmpty {
                CraftCard(style: .flat) {
                    CraftText(
                        AppStrings.GuidedPractice.summaryEmptyEvidence,
                        style: .bodyMedium,
                        color: theme.colors.textSecondary
                    )
                }
            } else if !summary.perWordProgress.isEmpty {
                ForEach(summary.perWordProgress, id: \.self) { progress in
                    let matchingEvidence = relevantEvidence.filter { $0.wordId == progress.wordId }
                    CraftCard(style: .elevated) {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            HStack(spacing: theme.spacing.xs) {
                                CraftText(
                                    Self.wordTitle(for: progress.wordId),
                                    style: .headline,
                                    color: theme.colors.textPrimary
                                )

                                Spacer()

                                CraftBadge(
                                    Self.inputModeBadgeTitle(for: progress.inputMode),
                                    tone: .primary,
                                    size: .sm
                                )

                                CraftBadge(
                                    Self.stageTitle(for: progress.stage),
                                    tone: Self.stageTone(for: progress.stage),
                                    size: .sm
                                )
                            }

                            if !matchingEvidence.isEmpty {
                                ForEach(matchingEvidence, id: \.id) { item in
                                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                                        HStack(spacing: theme.spacing.xs) {
                                            CraftBadge(
                                                Self.supportBadgeTitle(primed: item.primed),
                                                tone: item.primed ? .warning : .success,
                                                size: .sm
                                            )

                                            CraftText(
                                                AppStrings.GuidedPractice.objectiveTitle(for: item.objectiveId),
                                                style: .caption,
                                                color: theme.colors.textSecondary
                                            )
                                        }

                                        if let quoted = Self.formattedQuotedSpan(for: item) {
                                            CraftText(
                                                verbatim: quoted,
                                                style: .bodyMedium,
                                                color: theme.colors.brandPrimary
                                            )
                                        }
                                    }
                                    .padding(.top, theme.spacing.xxs)
                                }
                            }
                        }
                    }
                }
            } else {
                ForEach(relevantEvidence, id: \.id) { item in
                    CraftCard(style: .elevated) {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            HStack(spacing: theme.spacing.xs) {
                                CraftText(
                                    Self.wordTitle(for: item.wordId),
                                    style: .headline,
                                    color: theme.colors.textPrimary
                                )

                                Spacer()

                                CraftBadge(
                                    Self.inputModeBadgeTitle(for: item.inputMode),
                                    tone: .primary,
                                    size: .sm
                                )

                                CraftBadge(
                                    Self.supportBadgeTitle(primed: item.primed),
                                    tone: item.primed ? .warning : .success,
                                    size: .sm
                                )
                            }

                            if let quoted = Self.formattedQuotedSpan(for: item) {
                                CraftText(
                                    verbatim: quoted,
                                    style: .bodyMedium,
                                    color: theme.colors.brandPrimary
                                )
                            }

                            CraftText(
                                AppStrings.GuidedPractice.objectiveTitle(for: item.objectiveId),
                                style: .caption,
                                color: theme.colors.textSecondary
                            )
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftButton(
                AppStrings.GuidedPractice.summaryContinue,
                variant: .primary,
                isFullWidth: true,
                action: onContinue
            )

            CraftButton(
                AppStrings.GuidedPractice.summaryDeleteSession,
                variant: .ghost,
                isFullWidth: true,
                action: {
                    showDeleteConfirmation = true
                }
            )
        }
        .padding(.top, theme.spacing.sm)
    }
}

// MARK: - Presentation Logic & Pure Transformation Helpers

public extension PracticeSummaryView {
    nonisolated static func objectiveStatus(
        for result: PracticeObjectiveResult,
        sessionStatus: PracticeSessionStatus
    ) -> PracticeObjectiveDisplayStatus {
        if sessionStatus == .partial && !result.opportunityObserved {
            return .notObserved
        }
        switch result.intentVerdict {
        case .achieved:
            return .achieved
        case .notYet, .uncertain:
            return .notYet
        }
    }

    nonisolated static func inputModeBadgeTitle(for mode: PracticeInputMode) -> LocalizedStringKey {
        switch mode {
        case .voice:
            return AppStrings.GuidedPractice.modeVoice
        case .typed:
            return AppStrings.GuidedPractice.modeTyped
        case .editedTranscript:
            return AppStrings.GuidedPractice.modeEdited
        }
    }

    nonisolated static func supportBadgeTitle(primed: Bool) -> LocalizedStringKey {
        primed ? AppStrings.GuidedPractice.supportPrimed : AppStrings.GuidedPractice.supportIndependent
    }

    nonisolated static func stageTitle(for stage: CommunicationStage) -> LocalizedStringKey {
        switch stage {
        case .noEvidence:
            return AppStrings.GuidedPractice.stageNoEvidence
        case .practicing:
            return AppStrings.GuidedPractice.stagePracticing
        case .independentFamiliar:
            return AppStrings.GuidedPractice.stageIndependentFamiliar
        case .transferred:
            return AppStrings.GuidedPractice.stageTransferred
        }
    }

    nonisolated static func stageTone(for stage: CommunicationStage) -> CraftBadgeTone {
        switch stage {
        case .noEvidence:
            return .neutral
        case .practicing:
            return .warning
        case .independentFamiliar, .transferred:
            return .success
        }
    }

    nonisolated static func formattedQuotedSpan(for evidence: WordUseEvidence) -> String? {
        guard let span = evidence.quotedSpan, !span.isEmpty else { return nil }
        return "\"\(span)\""
    }

    nonisolated static func wordTitle(for wordId: Int64) -> LocalizedStringKey {
        AppStrings.GuidedPractice.wordLabel(for: wordId)
    }
}
