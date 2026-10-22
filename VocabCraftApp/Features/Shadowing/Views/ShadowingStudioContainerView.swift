import CraftUIKit
import SwiftUI

@MainActor
public struct ShadowingStudioContainerView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ShadowingStudioViewModel

    public init(viewModel: ShadowingStudioViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            topNavigationBar

            stageContentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
        .onAppear {
            viewModel.startActiveRound()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Top Navigation & Stage Pills

    private var topNavigationBar: some View {
        VStack(spacing: theme.spacing.xs) {
            HStack {
                Button(action: {
                    viewModel.cleanup()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(String(localized: "common.close"))

                Spacer()

                stagePillsBar

                Spacer()

                // Balancing frame for symmetry
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.top, theme.spacing.xxs)

            Divider()
                .overlay(theme.colors.hairline)
        }
    }

    private var stagePillsBar: some View {
        HStack(spacing: theme.spacing.sm) {
            ForEach(ShadowingRoundStage.allCases) { stage in
                StageStepButton(
                    symbol: stageSymbol(for: stage),
                    isSelected: viewModel.activeRound == stage,
                    accessibilityLabel: fullStageTitle(for: stage),
                    theme: theme,
                    action: {
                        viewModel.selectRound(stage)
                    }
                )
            }
        }
    }

    private func stageSymbol(for stage: ShadowingRoundStage) -> String {
        switch stage {
        case .round1Immersion:
            return "1"
        case .round2SpeedShadowing:
            return "2"
        case .round3EchoDrill:
            return "3"
        case .summaryReport:
            return "★"
        }
    }

    private func fullStageTitle(for stage: ShadowingRoundStage) -> String {
        switch stage {
        case .round1Immersion:
            return String(localized: "app.shadowing.stage.round1")
        case .round2SpeedShadowing:
            return String(localized: "app.shadowing.stage.round2")
        case .round3EchoDrill:
            return String(localized: "app.shadowing.stage.round3")
        case .summaryReport:
            return String(localized: "app.shadowing.stage.summary")
        }
    }
    // MARK: - Stage Content View

    @ViewBuilder
    private var stageContentView: some View {
        switch viewModel.activeRound {
        case .round1Immersion:
            ShadowingImmersionView(viewModel: viewModel)
        case .round2SpeedShadowing:
            ShadowingSpeedView(viewModel: viewModel)
        case .round3EchoDrill:
            ShadowingEchoView(viewModel: viewModel)
        case .summaryReport:
            ShadowingSummaryReportView(
                viewModel: viewModel,
                onFinish: {
                    dismiss()
                }
            )
        }
    }
}

private struct StageStepButton: View {
    let symbol: String
    let isSelected: Bool
    let accessibilityLabel: String
    let theme: CraftTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? theme.colors.brandPrimary : theme.colors.surfaceSubtle)

                Circle()
                    .stroke(isSelected ? theme.colors.brandPrimary : theme.colors.borderDefault, lineWidth: 1)

                Text(symbol)
                    .font(theme.typography.label)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? theme.colors.textInverse : theme.colors.textSecondary)
            }
            .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
