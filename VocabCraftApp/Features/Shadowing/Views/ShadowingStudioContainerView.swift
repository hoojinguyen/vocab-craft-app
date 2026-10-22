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
        HStack(spacing: theme.spacing.xs) {
            ForEach(ShadowingRoundStage.allCases) { stage in
                CraftPill(
                    stageTitle(for: stage),
                    isSelected: viewModel.activeRound == stage,
                    action: {
                        viewModel.selectRound(stage)
                    }
                )
            }
        }
    }

    private func stageTitle(for stage: ShadowingRoundStage) -> String {
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
