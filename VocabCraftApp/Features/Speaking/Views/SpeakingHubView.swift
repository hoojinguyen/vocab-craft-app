import CraftUIKit
import SwiftUI

struct SpeakingHubView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.appRouter) private var appRouter
    @State private var viewModel: SpeakingHubViewModel
    @State private var selectedBlueprint: SpeakingBlueprint?
    @State private var pendingRoute: SpeakingRoute?
    @State private var callDependencies: SpeakingCallDependencies?

    let appContainer: AppContainer

    init(viewModel: SpeakingHubViewModel, appContainer: AppContainer) {
        _viewModel = State(initialValue: viewModel)
        self.appContainer = appContainer
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                header
                progressSection
                blueprintSection(title: AppStrings.Speaking.hubScenarios, blueprints: viewModel.scenarios)
                blueprintSection(title: AppStrings.Speaking.hubTopics, blueprints: viewModel.topics)
                phrasebookRow
                historySection
            }
            .padding(theme.spacing.base)
        }
        .background(theme.colors.canvasBackground)
        .task { await viewModel.load() }
        .sheet(item: $selectedBlueprint) { blueprint in
            SpeakingPrepareView(blueprint: blueprint, viewModel: viewModel) { plan in
                guard let dependencies = appContainer.makeSpeakingCallDependencies(plan: plan) else {
                    appRouter.selectTab(.settings)
                    selectedBlueprint = nil
                    return
                }
                callDependencies = dependencies
                pendingRoute = .call(plan)
                selectedBlueprint = nil
            }
        }
#if os(iOS)
        .fullScreenCover(item: $pendingRoute, onDismiss: { callDependencies = nil }) { route in
            switch route {
            case let .call(plan):
                if let callDependencies {
                    SpeakingCallView(plan: plan, dependencies: callDependencies) { sessionId in
                        pendingRoute = .result(sessionId)
                    }
                }
            case let .result(sessionId):
                SpeakingResultView(viewModel: appContainer.makeSpeakingResultViewModel(sessionId: sessionId))
            case .phrasebook:
                SpeakingPhrasebookView(repository: appContainer.speakingRepository, ttsService: appContainer.ttsService)
            case .prepare:
                EmptyView()
            }
        }
#else
        .sheet(item: $pendingRoute, onDismiss: { callDependencies = nil }) { route in
            switch route {
            case let .call(plan):
                if let callDependencies {
                    SpeakingCallView(plan: plan, dependencies: callDependencies) { sessionId in
                        pendingRoute = .result(sessionId)
                    }
                }
            case let .result(sessionId):
                SpeakingResultView(viewModel: appContainer.makeSpeakingResultViewModel(sessionId: sessionId))
            case .phrasebook:
                SpeakingPhrasebookView(repository: appContainer.speakingRepository, ttsService: appContainer.ttsService)
            case .prepare:
                EmptyView()
            }
        }
#endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            CraftText(AppStrings.Speaking.hubTitle, style: .titleLarge)
            CraftText(AppStrings.Speaking.hubSubtitle, style: .bodyMedium, color: theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var progressSection: some View {
        if let progress = viewModel.progress {
            CraftCard {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    CraftText(AppStrings.Speaking.hubProgress, style: .headline)
                    scoreRow(title: AppStrings.Speaking.resultFluency, score: progress.fluency)
                    scoreRow(title: AppStrings.Speaking.resultGrammar, score: progress.grammar)
                    scoreRow(title: AppStrings.Speaking.resultVocabulary, score: progress.vocabulary)
                    scoreRow(title: AppStrings.Speaking.resultPronunciation, score: progress.pronunciation)
                }
            }
        }
    }

    private func scoreRow(title: LocalizedStringKey, score: Double) -> some View {
        HStack(spacing: theme.spacing.md) {
            CraftText(title, style: .caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            CraftProgressBar(progress: score / 5)
                .frame(maxWidth: .infinity)
        }
    }

    private func blueprintSection(title: LocalizedStringKey, blueprints: [SpeakingBlueprint]) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            CraftText(title, style: .headline)
            ForEach(blueprints) { blueprint in
                CraftCard {
                    CraftListRow(
                        title: LocalizedStringKey(blueprint.titleKey),
                        subtitle: LocalizedStringKey(blueprint.briefKey),
                        showChevron: true,
                        action: { selectedBlueprint = blueprint }
                    )
                }
            }
        }
    }

    private var phrasebookRow: some View {
        CraftCard {
            CraftListRow(
                title: AppStrings.Speaking.hubPhrasebook,
                iconName: "book.closed",
                showChevron: true,
                action: { pendingRoute = .phrasebook }
            )
        }
    }

    @ViewBuilder
    private var historySection: some View {
        if !viewModel.history.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                CraftText(AppStrings.Speaking.hubHistory, style: .headline)
                ForEach(viewModel.history) { session in
                    CraftCard {
                        CraftListRow(
                            title: LocalizedStringKey(session.plan.blueprint.titleKey),
                        ) {
                            CraftBadge(statusTitle(for: session.status), size: .sm)
                        }
                    }
                }
            }
        } else {
            CraftText(AppStrings.Speaking.hubEmpty, style: .bodyMedium, color: theme.colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statusTitle(for status: SpeakingSessionStatus) -> LocalizedStringKey {
        switch status {
        case .pendingAnalysis: AppStrings.Speaking.resultAnalyzing
        case .analyzed: AppStrings.Speaking.resultScores
        case .analysisFailed: AppStrings.Speaking.resultFailed
        case .tooShort: AppStrings.Speaking.resultTooShort
        }
    }
}
