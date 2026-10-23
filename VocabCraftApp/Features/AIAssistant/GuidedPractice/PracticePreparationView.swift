import CraftUIKit
import SwiftUI

/// Outcome of preflight capability evaluation prior to launching practice.
public enum PracticePreflightResult: Equatable, @unchecked Sendable {
    case ready
    case speechCaptureRequired(message: LocalizedStringKey)
    case llmUnavailable(message: LocalizedStringKey)
}

/// Mission briefing and preparation view guiding the learner through contextual framing,
/// role assignment, communication objectives, mode selection, and pre-lesson word review.
public struct PracticePreparationView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    public let mission: PracticeMission
    public let coordinator: PracticeSessionCoordinator?
    public let aiCapability: PracticeCapability
    public let speechCapability: PracticeCapability
    public let onStart: (PracticeMission, PracticeInputMode) -> Void
    public let onBack: () -> Void

    @State private var selectedMode: PracticeInputMode = .voice
    @State private var isReviewingWords = false
    @State private var isPrelessonExposureTracked = false
    @State private var showMicPermissionDialog = false
    @State private var showLLMUnavailableDialog = false

    /// Visible target vocabulary snapshots.
    /// Concealed by default to avoid biasing natural retrieval; revealed only when explicit review is initiated.
    public var shownTargetWords: [PracticeWordSnapshot] {
        isReviewingWords ? mission.wordSnapshots : []
    }

    private var template: PracticeTemplate? {
        PracticeTemplateCatalog.template(withId: mission.templateId)
    }

    public init(
        mission: PracticeMission,
        coordinator: PracticeSessionCoordinator? = nil,
        aiCapability: PracticeCapability = .standardCloud,
        speechCapability: PracticeCapability = .standardCloud,
        onStart: @escaping (PracticeMission, PracticeInputMode) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.mission = mission
        self.coordinator = coordinator
        self.aiCapability = aiCapability
        self.speechCapability = speechCapability
        self.onStart = onStart
        self.onBack = onBack
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                // MARK: - Navigation Bar
                navigationHeader

                // MARK: - Context & Scenario Brief
                scenarioBriefCard

                // MARK: - Mode Selection
                modeSelectionSection

                // MARK: - Pre-lesson Vocabulary Review Action
                reviewWordsActionSection

                // MARK: - Primary Launch Action
                launchActionSection
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.xl)
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
        .sheet(isPresented: $isReviewingWords) {
            prelessonWordReviewSheet
        }
        .craftDialog(
            isPresented: $showMicPermissionDialog,
            titleKey: AppStrings.GuidedPractice.modeVoiceTitle,
            messageKey: AppStrings.GuidedPractice.voicePermissionRequired,
            iconName: "mic.slash.fill",
            iconColor: theme.colors.warning,
            primaryButtonTitleKey: AppStrings.GuidedPractice.switchToText,
            primaryButtonVariant: .primary,
            primaryAction: {
                selectedMode = .typed
            },
            cancelButtonTitleKey: AppStrings.Common.cancel,
            cancelButtonVariant: .outline,
            cancelAction: {}
        )
        .craftDialog(
            isPresented: $showLLMUnavailableDialog,
            titleKey: AppStrings.GuidedPractice.errorTitle,
            messageKey: AppStrings.GuidedPractice.llmUnavailable,
            iconName: "exclamationmark.triangle.fill",
            iconColor: theme.colors.danger,
            primaryButtonTitleKey: AppStrings.Common.ok,
            primaryButtonVariant: .primary,
            primaryAction: {}
        )
    }

    // MARK: - Navigation Header

    private var navigationHeader: some View {
        HStack(spacing: theme.spacing.md) {
            CraftIconButton(
                iconName: "chevron.left",
                size: .md,
                variant: .ghost,
                accessibilityLabelKey: AppStrings.Common.back,
                action: onBack
            )

            CraftText(
                AppStrings.GuidedPractice.preparationTitle,
                style: .titleMedium,
                color: theme.colors.textPrimary
            )

            Spacer()
        }
        .padding(.top, theme.spacing.sm)
    }

    // MARK: - Scenario Brief Card

    private var scenarioBriefCard: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                // Scenario Title & Brief
                if let template {
                    CraftText(
                        LocalizedStringKey(template.titleKey),
                        style: .headline,
                        color: theme.colors.textPrimary
                    )

                    CraftText(
                        LocalizedStringKey(template.briefKey),
                        style: .bodyMedium,
                        color: theme.colors.textSecondary
                    )
                } else {
                    CraftText(
                        mission.templateId,
                        style: .headline,
                        color: theme.colors.textPrimary
                    )
                }

                Divider()
                    .background(theme.colors.borderDefault)

                // Roles
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    if let template, !template.roleKeys.isEmpty {
                        let learnerRole = Bundle.module.localizedString(
                            forKey: template.roleKeys[0],
                            value: template.roleKeys[0],
                            table: nil
                        )
                        CraftText(
                            AppStrings.GuidedPractice.preparationYourRole(learnerRole),
                            style: .caption,
                            color: theme.colors.textSecondary
                        )

                        if template.roleKeys.count > 1 {
                            let partnerRole = Bundle.module.localizedString(
                                forKey: template.roleKeys[1],
                                value: template.roleKeys[1],
                                table: nil
                            )
                            CraftText(
                                AppStrings.GuidedPractice.preparationPartnerRole(partnerRole),
                                style: .caption,
                                color: theme.colors.textSecondary
                            )
                        }
                    }
                }

                Divider()
                    .background(theme.colors.borderDefault)

                // Objectives
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText(
                        AppStrings.GuidedPractice.preparationObjectivesTitle,
                        style: .label,
                        color: theme.colors.brandPrimary
                    )

                    ForEach(mission.objectiveIds, id: \.self) { objectiveId in
                        HStack(alignment: .top, spacing: theme.spacing.xs) {
                            CraftIcon(
                                "checkmark.circle.fill",
                                size: .sm,
                                color: theme.colors.brandPrimary
                            )
                            .padding(.top, 2)

                            CraftText(
                                AppStrings.GuidedPractice.objectiveTitle(for: objectiveId),
                                style: .bodyMedium,
                                color: theme.colors.textPrimary
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mode Selection

    private var modeSelectionSection: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftChoiceCard(
                prefixStyle: .none,
                title: AppStrings.GuidedPractice.modeVoiceTitle,
                subtitle: AppStrings.GuidedPractice.modeVoiceDesc,
                state: selectedMode == .voice ? .selected : .idle,
                action: {
                    selectedMode = .voice
                }
            )

            CraftChoiceCard(
                prefixStyle: .none,
                title: AppStrings.GuidedPractice.modeTextTitle,
                subtitle: AppStrings.GuidedPractice.modeTextDesc,
                state: selectedMode == .typed ? .selected : .idle,
                action: {
                    selectedMode = .typed
                }
            )
        }
    }

    // MARK: - Word Review Action

    private var reviewWordsActionSection: some View {
        CraftButton(
            AppStrings.GuidedPractice.reviewWordsFirst,
            iconName: "book.fill",
            variant: .outline,
            size: .md,
            isFullWidth: true,
            action: {
                isReviewingWords = true
                Task {
                    await trackPrelessonReview()
                }
            }
        )
    }

    // MARK: - Launch Action

    private var launchActionSection: some View {
        CraftButton(
            AppStrings.GuidedPractice.startPractice,
            iconName: "play.fill",
            variant: .primary,
            size: .lg,
            isFullWidth: true,
            action: handleStart
        )
    }

    // MARK: - Word Review Sheet

    private var prelessonWordReviewSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.md) {
                    ForEach(mission.wordSnapshots, id: \.wordId) { word in
                        CraftCard(style: .outlined) {
                            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                CraftText(
                                    word.lemma,
                                    style: .headline,
                                    color: theme.colors.brandPrimary
                                )

                                CraftText(
                                    word.definitionVi,
                                    style: .bodyMedium,
                                    color: theme.colors.textPrimary
                                )

                                if !word.definitionEn.isEmpty {
                                    CraftText(
                                        word.definitionEn,
                                        style: .caption,
                                        color: theme.colors.textSecondary
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(theme.spacing.base)
            }
            .navigationTitle(AppStrings.GuidedPractice.reviewWordsSheetTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { isReviewingWords = false }) {
                        CraftText(
                            AppStrings.GuidedPractice.reviewWordsDone,
                            style: .label,
                            color: theme.colors.brandPrimary
                        )
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Preflight & Pre-lesson Tracking

    /// Evaluates preflight system capabilities before starting a practice session.
    nonisolated public static func preflight(
        mode: PracticeInputMode,
        aiCapability: PracticeCapability,
        speechCapability: PracticeCapability
    ) -> PracticePreflightResult {
        // Missing LLM generation capability rejects both voice and text with clear error.
        guard aiCapability.canGenerateDialogue else {
            return .llmUnavailable(message: AppStrings.GuidedPractice.llmUnavailable)
        }

        // Voice mode requires audio capture capability; does not block text mode.
        if mode == .voice && !speechCapability.canCaptureSpeech {
            return .speechCaptureRequired(message: AppStrings.GuidedPractice.voicePermissionRequired)
        }

        return .ready
    }

    private func handleStart() {
        let result = Self.preflight(
            mode: selectedMode,
            aiCapability: aiCapability,
            speechCapability: speechCapability
        )

        switch result {
        case .ready:
            onStart(mission, selectedMode)
        case .speechCaptureRequired:
            showMicPermissionDialog = true
        case .llmUnavailable:
            showLLMUnavailableDialog = true
        }
    }

    private func trackPrelessonReview() async {
        guard !isPrelessonExposureTracked, let coordinator else { return }
        let targetWordIds = Set(mission.targetWordIds)
        let content = mission.wordSnapshots.map(\.lemma).joined(separator: ", ")

        if let intent = await coordinator.preparePresentation(
            content: content,
            channel: .visual,
            origin: .prelessonReview,
            wordIds: targetWordIds,
            level: .lexical
        ) {
            await coordinator.confirmPresented(intentId: intent.id, at: Date())
            isPrelessonExposureTracked = true
        }
    }
}
