import CraftUIKit
import SwiftUI

/// Main container screen for interactive Lesson Learning sessions on the Learning Path.
public struct LessonLearningView: View {
    @State private var viewModel: LessonLearningViewModel
    @State private var showExitAlert: Bool = false
    public let onDismiss: () -> Void
    public let onFinished: (LessonSummaryModel) -> Void

    @Environment(\.craftTheme) private var theme

    public init(
        viewModel: LessonLearningViewModel,
        onDismiss: @escaping () -> Void,
        onFinished: @escaping (LessonSummaryModel) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack(spacing: theme.spacing.md) {
                    Button {
                        CraftHaptics.shared.light()
                        showExitAlert = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(theme.colors.textMuted)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppStrings.Common.close)

                    CraftProgressBar(
                        progress: viewModel.progress,
                        height: 8,
                        tintColor: theme.colors.brandPrimary,
                        trackColor: theme.colors.surfaceElevated
                    )

                    Spacer(minLength: 44)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.xs)

                // Main Step Content
                if let step = viewModel.currentStep {
                    Group {
                        switch step {
                        case .discovery(let word, let idx, let total):
                            LessonDiscoveryCardView(
                                word: word,
                                indexInCycle: idx,
                                totalInCycle: total,
                                onContinue: {
                                    viewModel.advanceStep()
                                },
                                onPlayAudio: {
                                    viewModel.playAudio(for: word.lemma)
                                }
                            )
                        case .exercise(let item):
                            LessonExerciseContainerView(
                                item: item,
                                viewModel: viewModel
                            )
                        case .summary(let summary):
                            LessonSummaryView(
                                summary: summary,
                                onFinish: {
                                    onFinished(summary)
                                },
                                onReplayAudio: { word in
                                    viewModel.playAudio(for: word.lemma)
                                }
                            )
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                }
            }
        }
        .animation(.smooth(duration: 0.28), value: viewModel.currentStepIndex)
        .alert(
            AppStrings.Lesson.exitAlertTitleText,
            isPresented: $showExitAlert
        ) {
            Button(AppStrings.Lesson.exitAlertConfirmText, role: .destructive) {
                onDismiss()
            }
            Button(AppStrings.Lesson.exitAlertCancelText, role: .cancel) {}
        } message: {
            Text(AppStrings.Lesson.exitAlertMessageText)
        }
    }
}
