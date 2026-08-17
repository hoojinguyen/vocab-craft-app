import SwiftUI

/// Main container view for the Spoken Reflex Blitz drill experience.
/// Manages phase transitions (countdown, drilling, timeout revealing, summary),
/// audio speech recognition status visualizer, progressive scaffolding, and typing fallback.
public struct ReflexBlitzView: View {
    @State private var viewModel: ReflexBlitzViewModel
    @State private var typingInput: String = ""
    public var onDismiss: () -> Void

    public init(viewModel: ReflexBlitzViewModel, onDismiss: @escaping () -> Void) {
        self._viewModel = State(initialValue: viewModel)
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

                    // Challenge Card
                    if let word = viewModel.currentWord {
                        ReflexBlitzCardView(
                            word: word,
                            showHint: viewModel.showHint,
                            isCorrect: viewModel.currentAttemptIsCorrect,
                            isTimeout: viewModel.phase == .timeoutRevealing
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }

                    Spacer(minLength: 12)

                    // Input & Speech Visualizer Hub
                    VStack(spacing: 14) {
                        if viewModel.isKeyboardFallbackActive {
                            // Keyboard Fallback Input Mode
                            HStack(spacing: 10) {
                                TextField("Nhập từ tiếng Anh...", text: $typingInput)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.vocabSurfaceCard)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.vocabHairline, lineWidth: 1.5)
                                    )
                                    .autocorrectionDisabled()
                                    #if os(iOS)
                                    .textInputAutocapitalization(.never)
                                    #endif
                                    .onSubmit {
                                        submitKeyboard()
                                    }
                                    .accessibilityLabel("Ô nhập từ tiếng Anh thay thế giọng nói")

                                Button(action: submitKeyboard) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(typingInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .vocabMuted.opacity(0.4) : .vocabHeroAccent)
                                }
                                .disabled(typingInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .frame(minWidth: 44, minHeight: 44)
                                .accessibilityLabel("Gửi câu trả lời đã gõ")
                            }
                            .padding(.horizontal)

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.toggleKeyboardFallback()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "mic.fill")
                                        .font(.caption)
                                    Text("Chuyển sang chế độ nói")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(.vocabHeroAccent)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(Color.vocabHeroAccent.opacity(0.1))
                                .clipShape(Capsule())
                                .frame(minHeight: 44)
                            }
                            .buttonStyle(BentoCardButtonStyle())
                            .accessibilityLabel("Chuyển về chế độ micro")

                        } else {
                            // Voice Continuous Listening Visualizer
                            VStack(spacing: 8) {
                                HStack(spacing: 5) {
                                    ForEach(0..<7) { index in
                                        Capsule()
                                            .fill(viewModel.currentAttemptIsCorrect ? Color.vocabMint : Color.vocabHeroAccent)
                                            .frame(
                                                width: 4,
                                                height: CGFloat(10 + ((index * 7 + (viewModel.elapsedTimeMs / 100)) % 22))
                                            )
                                            .animation(.easeInOut(duration: 0.15), value: viewModel.elapsedTimeMs)
                                    }
                                }
                                .frame(height: 36)
                                .accessibilityHidden(true)

                                if !viewModel.liveTranscript.isEmpty {
                                    Text(viewModel.liveTranscript)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.vocabInk)
                                        .lineLimit(1)
                                        .transition(.opacity)
                                } else {
                                    Text("Nói từ tiếng Anh vào micro...")
                                        .font(.caption)
                                        .foregroundColor(.vocabMuted)
                                }

                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.toggleKeyboardFallback()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "keyboard")
                                            .font(.caption2)
                                        Text("Hoặc gõ phím")
                                            .font(.caption2.bold())
                                    }
                                    .foregroundColor(.vocabMuted)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(Color.vocabMuted.opacity(0.08))
                                    .clipShape(Capsule())
                                    .frame(minHeight: 44)
                                }
                                .buttonStyle(BentoCardButtonStyle())
                                .accessibilityLabel("Chuyển sang gõ phím thay thế")
                            }
                            .padding(.bottom, 24)
                        }
                    }
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
