import CraftUIKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SpeakingPrepareView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.appRouter) private var appRouter
    let blueprint: SpeakingBlueprint
    let viewModel: SpeakingHubViewModel
    let onStart: (SpeakingSessionPlan) -> Void

    @State private var level: SpeakingLevel = .a2
    @State private var includeWords = false
    @State private var targetWords: [SpeakingTargetWord] = []
    @State private var issues: [SpeakingPrecheck.Issue] = []
    @State private var isPreparing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    levelSection
                    vocabularySection
                    goalSection
                    precheckSection
                    CraftButton(AppStrings.Speaking.prepareStart, isLoading: isPreparing, isFullWidth: true) {
                        Task { await start() }
                    }
                    .disabled(isPreparing || !issues.isEmpty)
                }
                .padding(theme.spacing.base)
            }
            .background(theme.colors.canvasBackground)
            .navigationTitle(LocalizedStringKey(blueprint.titleKey))
            .task {
                issues = await viewModel.runPrecheck()
                await refreshWords()
            }
            .onChange(of: includeWords) { _, _ in Task { await refreshWords() } }
        }
    }

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            CraftText(AppStrings.Speaking.prepareLevel, style: .headline)
            CraftSegmentedControl(
                selection: $level,
                options: [
                    CraftSegmentOption(.a2, title: "A2"),
                    CraftSegmentOption(.b1, title: "B1")
                ],
                style: .outlined
            )
        }
    }

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            CraftToggle(isOn: $includeWords, title: AppStrings.Speaking.prepareVocabToggle)
            if includeWords {
                CraftText(AppStrings.Speaking.prepareWords, style: .headline)
                if !targetWords.isEmpty {
                    CraftSpeechWordFlowLayout(spacing: theme.spacing.xs, lineSpacing: theme.spacing.xs, alignment: .leading) {
                        ForEach(targetWords, id: \.wordId) { word in
                            CraftPill(word.lemma, isSelected: true) {}
                        }
                    }
                }
            }
        }
    }

    private var goalSection: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                CraftText(AppStrings.Speaking.prepareGoal, style: .headline)
                CraftText(LocalizedStringKey(blueprint.briefKey), style: .bodyMedium, color: theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var precheckSection: some View {
        ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
            CraftCard {
                CraftListRow(
                    title: issueTitle(for: issue),
                    iconName: "exclamationmark.triangle",
                    showChevron: issue != .offline,
                    action: { handle(issue) }
                ) {
                    if issue != .offline {
                        CraftButton(AppStrings.Speaking.errorOpenSettings, size: .sm) { handle(issue) }
                    }
                }
            }
        }
        if issues.contains(.offline) {
            CraftButton(AppStrings.Speaking.errorTryAgain, variant: .secondary) {
                Task { issues = await viewModel.runPrecheck() }
            }
        }
    }

    private func issueTitle(for issue: SpeakingPrecheck.Issue) -> LocalizedStringKey {
        switch issue {
        case .missingKey: AppStrings.Speaking.prepareCheckKey
        case .microphoneDenied: AppStrings.Speaking.prepareCheckMic
        case .offline: AppStrings.Speaking.prepareCheckNetwork
        }
    }

    private func handle(_ issue: SpeakingPrecheck.Issue) {
        switch issue {
        case .missingKey:
            appRouter.selectTab(.settings)
        case .microphoneDenied:
            #if canImport(UIKit)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            #endif
        case .offline:
            Task { issues = await viewModel.runPrecheck() }
        }
    }

    private func refreshWords() async {
        guard includeWords else {
            targetWords = []
            return
        }
        guard let plan = await viewModel.makePlan(blueprintId: blueprint.id, level: level, includeWords: true) else {
            targetWords = []
            return
        }
        targetWords = plan.targetWords
    }

    private func start() async {
        isPreparing = true
        defer { isPreparing = false }
        issues = await viewModel.runPrecheck()
        guard issues.isEmpty,
              let plan = await viewModel.makePlan(blueprintId: blueprint.id, level: level, includeWords: includeWords)
        else { return }
        onStart(plan)
    }
}
