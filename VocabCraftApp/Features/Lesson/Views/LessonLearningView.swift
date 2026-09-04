import CraftUIKit
import SwiftUI

/// Main container screen for interactive Lesson Learning sessions on the Learning Path.
public struct LessonLearningView: View {
    @State private var viewModel: LessonLearningViewModel
    @State private var showExitAlert: Bool = false
    @State private var isCountingDown: Bool
    @State private var hasDismissed: Bool = false
    public let onDismiss: () -> Void
    public let onFinished: (LessonSummaryModel) -> Void
    public let startWithCountdown: Bool

    @Environment(\.craftTheme) private var theme

    public init(
        viewModel: LessonLearningViewModel,
        startWithCountdown: Bool = true,
        onDismiss: @escaping () -> Void,
        onFinished: @escaping (LessonSummaryModel) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.startWithCountdown = startWithCountdown
        let skipCountdown = ProcessInfo.processInfo.arguments.contains("-test-lesson-feedback-incorrect") || ProcessInfo.processInfo.arguments.contains("-test-lesson-feedback-correct")
        self._isCountingDown = State(initialValue: startWithCountdown && !skipCountdown)
        self.onDismiss = onDismiss
        self.onFinished = onFinished
    }

    private func dismissOnce() {
        guard !hasDismissed else { return }
        hasDismissed = true
        onDismiss()
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            if isCountingDown {
                ReflexCountdownOverlayView(
                    count: 3,
                    title: AppStrings.Lesson.discoveryTitleText,
                    subtitle: AppStrings.Lesson.countdownSubtitleText,
                    iconName: "book.pages.fill",
                    tintColor: theme.colors.brandPrimary,
                    onFinish: {
                        LessonPerformanceDiagnostics.event("LessonCountdownFinished")
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isCountingDown = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(200)
            } else {
                VStack(spacing: 0) {
                    // Top Navigation Bar (Hidden during summary)
                    if !viewModel.isSummaryStep {
                        HStack(spacing: theme.spacing.md) {
                            Button {
                                CraftHaptics.shared.light()
                                showExitAlert = true
                            } label: {
                                Image(systemName: "xmark")
                                    .font(theme.typography.bodyMedium.bold())
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
                    }

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
                                        viewModel.stopAudio()
                                        viewModel.advanceStep()
                                    },
                                    onPlayAudio: {
                                        viewModel.playAudio(for: word.lemma)
                                    }
                                )
                                .id("discovery-\(word.id)")

                            case .exercise(let item):
                                LessonExerciseContainerView(
                                    item: item,
                                    viewModel: viewModel
                                )
                                .id("exercise-\(item.id)")

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
                                .id("summary-\(summary.stageId)")
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                    }
                }

                // Floating Bottom Feedback Sheet Overlay
                if viewModel.isFeedbackPresented {
                    VStack(spacing: 0) {
                        Spacer()
                        CraftFeedbackSheet(
                            status: viewModel.lastAttemptCorrect ? .success : .error,
                            title: viewModel.lastAttemptCorrect ? AppStrings.ReflexBlitz.correctTitleText : AppStrings.ReflexBlitz.incorrectTitleText,
                            message: nil,
                            actionTitle: AppStrings.ReflexBlitz.continueCTAText,
                            streakCount: nil,
                            style: .tactile3D,
                            onContinue: {
                                viewModel.advanceStep()
                            }
                        )
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.currentStepIndex)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isCountingDown)
        .interactiveDismissDisabled(!viewModel.isSummaryStep)
        .onAppear {
            LessonPerformanceDiagnostics.event("LessonScreenAppeared", detail: "countdown=\(isCountingDown)")
            viewModel.startSpeechSession()
        }
        .onDisappear {
            LessonPerformanceDiagnostics.event("LessonScreenDisappeared")
            if !viewModel.isCompleted {
                dismissOnce()
            }
            viewModel.stopSpeechSession()
        }
        .alert(
            AppStrings.Lesson.exitAlertTitleText,
            isPresented: $showExitAlert
        ) {
            Button(AppStrings.Lesson.exitAlertConfirmText, role: .destructive) {
                dismissOnce()
            }
            Button(AppStrings.Lesson.exitAlertCancelText, role: .cancel) {}
        } message: {
            Text(AppStrings.Lesson.exitAlertMessageText)
        }
    }
}
