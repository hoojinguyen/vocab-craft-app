import CraftUIKit
import SwiftUI

/// Main container view for the Mixed Reflex Drill session.
/// Seamlessly manages 4 randomized multi-sensory interactive modes:
/// 1. Multiple Choice (.multipleChoice - 4.5s)
/// 2. Speaking (.speaking - 6.0s) with continuous speech recognition & waveform
/// 3. Typing (.typing - 7.5s) with auto-focused TextField
/// 4. Listening (.listening - 5.5s) with automatic TTS audio stimulus
///
/// Fully incorporates the Loop-Back mechanism: any failed or timed-out word
/// is immediately requeued at the end of the session with a fresh alternative mode.
public struct MixedReflexDrillView: View {
    @Environment(\.craftTheme) var theme
    @Bindable public var viewModel: MixedReflexDrillViewModel
    public var speechEngine: (any ReflexSpeechEngineProtocol)?
    public let onFinish: () -> Void
    public let startWithCountdown: Bool

    @State var isCountingDown: Bool
    @State var timerTask: Task<Void, Never>?
    @State var speechStartTask: Task<Void, Never>?
    @State var fractionRemaining: Double = 1.0
    @State var cardPhase: ReflexCardPhase = .activeCountdown
    @State var typingText: String = ""
    @State var liveTranscript: String = ""
    @State var currentOptions: [ReflexBlitzOption] = []
    @State private var showExitAlert: Bool = false
    @State var currentTimerStage: ReflexBlitzTimerStage = .steady
    @State var hintStage: Int = 0

    public var isTimerPaused: Bool {
        get { viewModel.isTimerPaused }
        nonmutating set { viewModel.isTimerPaused = newValue }
    }

    public var pausedElapsedMs: Int {
        get { viewModel.pausedElapsedMs }
        nonmutating set { viewModel.pausedElapsedMs = newValue }
    }

    public var wordStartTime: Date? {
        get { viewModel.wordStartTime }
        nonmutating set { viewModel.wordStartTime = newValue }
    }

    public var elapsedTimeMs: Int {
        get {
            if isTimerPaused {
                return pausedElapsedMs
            }
            if let wordStartTime {
                return max(0, Int(Date().timeIntervalSince(wordStartTime) * 1000))
            }
            return viewModel.elapsedTimeMs
        }
        nonmutating set { viewModel.elapsedTimeMs = newValue }
    }

    public var speechState: CraftSpeechState {
        get { viewModel.speechState }
        nonmutating set { viewModel.speechState = newValue }
    }

    public var isPermissionDenied: Bool {
        get { viewModel.isPermissionDenied }
        nonmutating set { viewModel.isPermissionDenied = newValue }
    }

    public var showPermissionAlert: Bool {
        get { viewModel.showPermissionAlert }
        nonmutating set { viewModel.showPermissionAlert = newValue }
    }

    public var permissionNotice: ReflexPermissionNotice? {
        get { viewModel.permissionNotice }
        nonmutating set { viewModel.permissionNotice = newValue }
    }

    public init(
        viewModel: MixedReflexDrillViewModel,
        speechEngine: (any ReflexSpeechEngineProtocol)? = nil,
        startWithCountdown: Bool = true,
        onFinish: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.speechEngine = speechEngine ?? viewModel.speechEngine ?? ResilientReflexSpeechEngine()
        self.startWithCountdown = startWithCountdown
        self.onFinish = onFinish
        self._isCountingDown = State(initialValue: startWithCountdown)
    }

    public var isReviewed: Bool {
        if case .reviewed = cardPhase { return true }
        return false
    }

    public var reviewedResult: ReflexCardResult? {
        if case .reviewed(let result) = cardPhase { return result }
        return nil
    }

    public var isResultCorrect: Bool {
        reviewedResult?.isCorrect ?? false
    }

    public var isResultTimeout: Bool {
        reviewedResult?.isTimeout ?? false
    }

    public var timerStage: ReflexBlitzTimerStage {
        get { currentTimerStage }
        nonmutating set { currentTimerStage = newValue }
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            if viewModel.isCompleted, let summary = viewModel.sessionSummary {
                MixedReflexSummaryView(
                    summary: summary,
                    onSpeakWord: { lemma in
                        viewModel.playAudio(for: lemma)
                    },
                    onReDrillWeak: {
                        viewModel.reDrillWeakWords()
                        isCountingDown = true
                        let contextualPhrases = viewModel.queue.map(\.word.lemma)
                        speechEngine?.startSession(contextualPhrases: contextualPhrases, lazy: true)
                    },
                    onFinish: onFinish
                )
                .transition(.opacity)
            } else if isCountingDown, let currentItem = viewModel.currentItem {
                ReflexCountdownOverlayView(
                    count: 3,
                    title: AppStrings.Practice.mixedDrillTitleText,
                    subtitle: AppStrings.Practice.mixedDrillSubtitleText,
                    iconName: "bolt.fill",
                    tintColor: theme.colors.brandPrimary,
                    onFinish: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isCountingDown = false
                            startDrillItem(currentItem)
                        }
                    }
                )
                .transition(.opacity)
            } else if let currentItem = viewModel.currentItem {
                drillingSessionContent(currentItem: currentItem)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            setupSpeechEngineCallbacks()
            let contextualPhrases = viewModel.queue.map(\.word.lemma)
            speechEngine?.startSession(contextualPhrases: contextualPhrases, lazy: true)
            if !isCountingDown, let current = viewModel.currentItem {
                startDrillItem(current)
            }
        }
        .onDisappear {
            stopDrillSession()
        }
        .alert(
            AppStrings.ReflexBlitz.exitDialogTitleText,
            isPresented: $showExitAlert
        ) {
            Button(AppStrings.ReflexBlitz.exitDialogConfirmText, role: .destructive) {
                stopDrillSession()
                onFinish()
            }
            Button(AppStrings.ReflexBlitz.exitDialogCancelText, role: .cancel) {
                resumeDrillSession()
            }
        } message: {
            Text(AppStrings.ReflexBlitz.exitDialogMessageText)
        }
        .interactiveDismissDisabled(true)
        .alert(
            permissionNotice?.title ?? AppStrings.Lesson.permissionTitleText,
            isPresented: $viewModel.showPermissionAlert,
            presenting: permissionNotice
        ) { notice in
            Button(notice.settingsActionTitle) {
                openSettings()
                dismissPermissionAlert()
            }
            Button(notice.dismissActionTitle, role: .cancel) {
                dismissPermissionAlert()
            }
        } message: { notice in
            Text(notice.message)
        }
        .onChange(of: viewModel.showPermissionAlert) { wasPresented, isPresented in
            if wasPresented && !isPresented && permissionNotice != nil {
                dismissPermissionAlert()
            }
        }
    }

    // MARK: - Drilling Session Main Content
    @ViewBuilder
    private func drillingSessionContent(currentItem: MixedReflexDrillItem) -> some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: theme.spacing.sm) {
                ReflexHeaderBarView(
                    currentIndex: viewModel.currentIndex,
                    totalCount: viewModel.queue.count,
                    comboStreak: viewModel.comboStreak,
                    fractionRemaining: fractionRemaining,
                    timerStage: timerStage,
                    attempts: viewModel.attempts,
                    wordStartTime: wordStartTime,
                    timeLimitSeconds: currentItem.assignedMode.timeLimitSeconds,
                    isTimerActive: cardPhase == .activeCountdown && !isTimerPaused,
                    showSkipInHeader: false,
                    onClose: {
                        pauseDrillSession()
                        showExitAlert = true
                    },
                    onSkip: {
                        handleTimeout()
                    }
                )
                .padding(.top, theme.spacing.sm)

                challengeCard(for: currentItem)
                    .id("\(viewModel.currentIndex)-\(currentItem.id)")
                    .transition(.opacity)

                Spacer(minLength: theme.spacing.xs)

                // Skip Button for Typing
                if cardPhase == .activeCountdown && currentItem.assignedMode == .typing {
                    CraftButton(
                        AppStrings.ReflexBlitz.skip,
                        iconName: "forward.fill",
                        variant: .outline,
                        size: .md,
                        isFullWidth: true,
                        style: .outlined,
                        action: {
                            handleTimeout()
                        }
                    )
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.lg)
                    .transition(.opacity)
                }
            }

            // Floating Bottom Feedback Sheet Overlay
            if case .reviewed(let result) = cardPhase {
                CraftFeedbackSheet(
                    status: result.isCorrect ? .success : (result.isTimeout ? .warning : .error),
                    title: result.isCorrect ? AppStrings.ReflexBlitz.correctTitleText : (result.isTimeout ? AppStrings.ReflexBlitz.timeoutTitleText : AppStrings.ReflexBlitz.incorrectTitleText),
                    actionTitle: AppStrings.ReflexBlitz.continueCTAText,
                    streakCount: nil,
                    style: .tactile3D,
                    onContinue: {
                        advanceToNextItem()
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
    }
}
