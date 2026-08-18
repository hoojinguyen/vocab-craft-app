import SwiftUI

/// Main container view for the Spoken Reflex Blitz drill experience.
/// Manages phase transitions (countdown, drilling, timeout revealing, summary),
/// audio speech recognition status visualizer, progressive scaffolding, and typing fallback.
public struct ReflexBlitzView: View {
    public var viewModel: ReflexBlitzViewModel
    @State private var typingInput: String = ""
    public var onDismiss: () -> Void

    public init(viewModel: ReflexBlitzViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            if viewModel.phase == .summary, let summary = viewModel.sessionSummary {
                ReflexBlitzSummaryView(
                    summary: summary,
                    onReDrillWeak: {
                        viewModel.reDrillWeakWords()
                    },
                    onFinish: onDismiss
                )
            } else {
                VStack(spacing: 20) {
                    // Header Bar
                    ReflexBlitzHeaderView(
                        currentIndex: viewModel.currentWordIndex,
                        totalCount: viewModel.words.count,
                        comboStreak: viewModel.comboStreak,
                        onClose: {
                            viewModel.cancelSession()
                            onDismiss()
                        },
                        onSkip: {
                            viewModel.handleTimeout()
                        }
                    )
                    .padding(.top, 12)

                    Spacer(minLength: 12)

                    // Challenge Card with Integrated Voice / Fallback Dock & Perimeter Timer
                    if let word = viewModel.currentWord {
                        ReflexBlitzCardView(
                            word: word,
                            fractionRemaining: viewModel.fractionRemaining,
                            timerStage: viewModel.timerStage,
                            showHint: viewModel.showHint,
                            isCorrect: viewModel.currentAttemptIsCorrect,
                            isTimeout: viewModel.phase == .timeoutRevealing,
                            liveTranscript: viewModel.liveTranscript,
                            elapsedTimeMs: viewModel.elapsedTimeMs,
                            isKeyboardFallbackActive: viewModel.isKeyboardFallbackActive,
                            keyboardInputText: $typingInput,
                            onSubmitKeyboard: {
                                submitKeyboard()
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }

                    Spacer(minLength: 12)

                    // Mode Switcher Control
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.toggleKeyboardFallback()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isKeyboardFallbackActive ? "mic.fill" : "keyboard")
                                .font(.caption)
                            Text(viewModel.isKeyboardFallbackActive ? "Chuyển sang chế độ nói" : "Hoặc gõ phím")
                                .font(.caption.bold())
                        }
                        .foregroundColor(viewModel.isKeyboardFallbackActive ? .vocabHeroAccent : .vocabMuted)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            viewModel.isKeyboardFallbackActive
                                ? Color.vocabHeroAccent.opacity(0.1)
                                : Color.vocabMuted.opacity(0.08)
                        )
                        .clipShape(Capsule())
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(BentoCardButtonStyle())
                    .accessibilityLabel(viewModel.isKeyboardFallbackActive ? "Chuyển về chế độ micro" : "Chuyển sang gõ phím thay thế")
                    .padding(.bottom, 24)
                }

                if viewModel.phase == .countdown {
                    ReflexCountdownOverlayView(count: viewModel.countdownCount)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            if viewModel.phase == .countdown {
                viewModel.startCountdown()
            }
        }
        .onDisappear {
            viewModel.cancelSession()
        }
        .sensoryFeedback(.success, trigger: viewModel.currentAttemptIsCorrect) { _, isCorrect in isCorrect }
        .sensoryFeedback(.impact(weight: .heavy), trigger: viewModel.phase) { _, newPhase in newPhase == .timeoutRevealing }
    }

    private func submitKeyboard() {
        let text = typingInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.submitKeyboardInput(text)
        typingInput = ""
    }
}
