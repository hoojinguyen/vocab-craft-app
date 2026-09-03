import CraftUIKit
import SwiftUI

public struct OnboardingCoordinatorView: View {
    @State private var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    public init(viewModel: OnboardingViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Header
                HStack {
                    if viewModel.canGoBack {
                        CraftIconButton(
                            symbol: .chevronLeft,
                            size: .md,
                            accessibilityLabelKey: "common.back"
                        ) {
                            viewModel.previousStep()
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }

                    Spacer()

                    CraftStepProgressIndicator(
                        totalSteps: 4,
                        currentStep: viewModel.currentStep.rawValue,
                        counterStyle: .phrase
                    )

                    Spacer()

                    Button {
                        viewModel.skipOnboarding()
                    } label: {
                        Text("app.onboarding.common.skip")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary.opacity(viewModel.isSynthesizing ? 0.35 : 1.0))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSynthesizing)
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.sm)

                // Current Step Transition
                Group {
                    switch viewModel.currentStep {
                    case .goal:
                        OnboardingGoalStepView(viewModel: viewModel)
                    case .proficiency:
                        OnboardingProficiencyStepView(viewModel: viewModel)
                    case .habit:
                        OnboardingHabitStepView(viewModel: viewModel)
                    case .roadmapReveal:
                        OnboardingRoadmapRevealStepView(viewModel: viewModel)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(theme.animations.springSmooth, value: viewModel.currentStep)
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $viewModel.isPresentingMiniLesson) {
            OnboardingFirstLessonView(
                words: viewModel.roadmapResult?.starterWords ?? []
            ) {
                viewModel.completeOnboardingAndDismiss()
            }
        }
        #else
        .sheet(isPresented: $viewModel.isPresentingMiniLesson) {
            OnboardingFirstLessonView(
                words: viewModel.roadmapResult?.starterWords ?? []
            ) {
                viewModel.completeOnboardingAndDismiss()
            }
            .frame(minWidth: 500, minHeight: 600)
        }
        #endif
    }
}
