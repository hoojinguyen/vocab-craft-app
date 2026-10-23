import CraftUIKit
import SwiftUI

/// Main entry point for the AI Guided Communication Practice experience.
///
/// Handles session continuation, mission recommendation display, pedagogical state empties,
/// and scenario browsing using CraftUIKit components and design tokens.
public struct PracticeHubView: View {
    @Environment(\.craftTheme) private var theme
    @Bindable public var viewModel: PracticeHubViewModel

    public let onStart: (PracticeMission, PracticeInputMode) -> Void
    public let onResume: (UUID) -> Void
    public let onOpenLesson: () -> Void

    @State private var preparingMission: PracticeMission?

    /// Visible target vocabulary snapshots in the hub.
    /// Strictly empty across all hub states to adhere to anti-priming constraints.
    public var shownTargetWords: [PracticeWordSnapshot] {
        viewModel.shownTargetWords
    }

    public init(
        viewModel: PracticeHubViewModel,
        onStart: @escaping (PracticeMission, PracticeInputMode) -> Void,
        onResume: @escaping (UUID) -> Void,
        onOpenLesson: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onStart = onStart
        self.onResume = onResume
        self.onOpenLesson = onOpenLesson
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                // MARK: - Header
                headerSection

                // MARK: - Content by State
                switch viewModel.state {
                case .loading:
                    loadingSection

                case .resumable(let sessionId):
                    resumableSection(sessionId: sessionId)

                case .recommended(let mission):
                    recommendedSection(mission: mission)

                case .needsVocabulary:
                    needsVocabularySection

                case .noCompatibleTemplate:
                    noCompatibleTemplateSection

                case .error:
                    errorSection
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.vertical, theme.spacing.base)
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
        .task {
            if viewModel.state == .loading {
                await viewModel.load()
            }
        }
        .sheet(item: $preparingMission) { mission in
            PracticePreparationView(
                mission: mission,
                onStart: { selectedMission, mode in
                    preparingMission = nil
                    onStart(selectedMission, mode)
                },
                onBack: {
                    preparingMission = nil
                }
            )
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            CraftText(
                AppStrings.GuidedPractice.hubTitle,
                style: .titleLarge,
                color: theme.colors.textPrimary
            )

            CraftText(
                AppStrings.GuidedPractice.hubSubtitle,
                style: .bodyMedium,
                color: theme.colors.textSecondary
            )
        }
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        HStack {
            Spacer()
            CraftSpinner(size: .lg)
                .padding(.vertical, theme.spacing.xxl)
            Spacer()
        }
    }

    // MARK: - Resumable Section

    private func resumableSection(sessionId: UUID) -> some View {
        CraftActionCard(
            title: AppStrings.GuidedPractice.hubResumeTitle,
            subtitle: AppStrings.GuidedPractice.hubResumeSubtitle,
            iconName: "arrow.clockwise.circle.fill",
            badgeKey: AppStrings.GuidedPractice.hubResumeBadge,
            badgeIcon: "play.circle.fill",
            action: {
                onResume(sessionId)
            }
        )
    }

    // MARK: - Recommended Section

    private func recommendedSection(mission: PracticeMission) -> some View {
        let template = PracticeTemplateCatalog.template(withId: mission.templateId)
        let titleKey: LocalizedStringKey = template.map { LocalizedStringKey($0.titleKey) } ?? LocalizedStringKey(mission.templateId)
        let subtitleKey: LocalizedStringKey? = template.map { LocalizedStringKey($0.briefKey) }

        return VStack(alignment: .leading, spacing: theme.spacing.lg) {
            // Primary Recommended Card
            CraftActionCard(
                title: titleKey,
                subtitle: subtitleKey,
                iconName: "sparkles",
                badgeKey: AppStrings.GuidedPractice.hubRecommendedBadge,
                badgeIcon: "star.fill",
                action: {
                    preparingMission = mission
                }
            )

            // Other Scenarios Catalog Section
            let otherTemplates = viewModel.templates.filter { $0.id != mission.templateId }
            if !otherTemplates.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    CraftText(
                        AppStrings.GuidedPractice.hubOtherScenarios,
                        style: .titleMedium,
                        color: theme.colors.textPrimary
                    )

                    VStack(spacing: theme.spacing.sm) {
                        ForEach(otherTemplates, id: \.id) { other in
                            CraftListRow(
                                title: LocalizedStringKey(other.titleKey),
                                subtitle: LocalizedStringKey(other.briefKey),
                                iconName: "bubble.left.and.bubble.right.fill",
                                showChevron: true,
                                action: {}
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Needs Vocabulary Section

    private var needsVocabularySection: some View {
        CraftEmptyState(
            iconName: "character.book.closed",
            title: AppStrings.GuidedPractice.emptyNeedsVocabTitle,
            message: AppStrings.GuidedPractice.emptyNeedsVocabDesc,
            buttonTitle: AppStrings.GuidedPractice.emptyNeedsVocabCTA,
            buttonAction: onOpenLesson
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xl)
    }

    // MARK: - No Compatible Template Section

    private var noCompatibleTemplateSection: some View {
        CraftEmptyState(
            iconName: "square.stack.3d.up.slash",
            title: AppStrings.GuidedPractice.emptyNoTemplateTitle,
            message: AppStrings.GuidedPractice.emptyNoTemplateDesc,
            buttonTitle: AppStrings.GuidedPractice.emptyNoTemplateCTA,
            buttonAction: onOpenLesson
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xl)
    }

    // MARK: - Error Section

    private var errorSection: some View {
        CraftEmptyState(
            iconName: "exclamationmark.triangle.fill",
            title: AppStrings.GuidedPractice.errorTitle,
            message: AppStrings.GuidedPractice.errorDesc,
            buttonTitle: AppStrings.GuidedPractice.errorRetry,
            buttonAction: {
                Task {
                    await viewModel.load()
                }
            }
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xl)
    }
}
