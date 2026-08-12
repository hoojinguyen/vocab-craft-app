import SwiftUI

// MARK: - Active Speech Visualizer View Component
public struct ReflexSpeechVisualizerView: View {
    public let isListening: Bool
    public let recognizedText: String

    @State private var barHeights: [CGFloat] = [12, 24, 18, 30, 16, 26, 14]

    public init(isListening: Bool, recognizedText: String) {
        self.isListening = isListening
        self.recognizedText = recognizedText
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header Label for Context & Affordance
            HStack {
                Label(
                    isListening ? AppStrings.Reflex.listening : AppStrings.Reflex.spokenAnswer,
                    systemImage: isListening ? "waveform" : "mic.fill"
                )
                .font(.caption2.bold().smallCaps())
                .foregroundColor(isListening ? .vocabCoral : .vocabMuted)

                Spacer()
            }

            // Equalizer Sound Bar Visualizer
            if isListening {
                HStack(spacing: 5) {
                    ForEach(0..<barHeights.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color.vocabCoral, Color.vocabPeach],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 4, height: barHeights[index])
                            .animation(.easeInOut(duration: 0.12), value: barHeights[index])
                    }
                }
                .frame(height: 32)
                .task(id: isListening) {
                    guard isListening else { return }
                    while !Task.isCancelled && isListening {
                        try? await Task.sleep(for: .milliseconds(120))
                        for i in 0..<barHeights.count {
                            barHeights[i] = CGFloat.random(in: 8...30)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Recognized Speech Text Display
            Text(displayText)
                .font(.system(size: 19, weight: recognizedText.isEmpty ? .medium : .semibold, design: .rounded))
                .foregroundColor(recognizedText.isEmpty ? .vocabMuted.opacity(0.6) : .vocabInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Color.vocabSurfaceCard

                if isListening {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.vocabCoral.opacity(0.6), Color.vocabPeach.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                }
            }
        )
        .cornerRadius(24)
        .shadow(
            color: isListening ? Color.vocabCoral.opacity(0.12) : Color.black.opacity(0.03),
            radius: isListening ? 12 : 6,
            x: 0,
            y: isListening ? 6 : 3
        )
        .padding(.horizontal, 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isListening)
    }

    private var displayText: String {
        if !recognizedText.isEmpty {
            return recognizedText
        }
        if isListening {
            return "Đang lắng nghe câu nói của bạn..."
        }
        return "Nhấn micro bên dưới và nói đáp án tiếng Anh..."
    }
}

// MARK: - Reflex Header Bar Component View
// MARK: - Reflex Header Bar Component View
public struct ReflexHeaderBarView: View {
    public let currentIndex: Int
    public let totalCount: Int
    public let cefrLevel: String
    public let isEvaluated: Bool
    public var onDismiss: (() -> Void)? = nil
    public let onSkip: () -> Void

    public init(
        currentIndex: Int,
        totalCount: Int,
        cefrLevel: String,
        isEvaluated: Bool,
        onDismiss: (() -> Void)? = nil,
        onSkip: @escaping () -> Void
    ) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.cefrLevel = cefrLevel
        self.isEvaluated = isEvaluated
        self.onDismiss = onDismiss
        self.onSkip = onSkip
    }

    public var body: some View {
        HStack(alignment: .center) {
            // Close Action
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.vocabInk)
                        .frame(width: 34, height: 34)
                        .background(Color.vocabMuted.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(BentoCardButtonStyle())
            }

            Spacer()

            // Center Title & Lesson Progress Badge
            HStack(spacing: 6) {
                Text("Reflex Drill (\(cefrLevel))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.vocabInk)

                Text("•")
                    .font(.caption)
                    .foregroundColor(.vocabMuted)

                Text("Bài \(currentIndex + 1)/\(max(1, totalCount))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.vocabHeroAccent.opacity(0.12))
                    .foregroundColor(.vocabHeroAccent)
                    .clipShape(Capsule())
            }

            Spacer()

            // Skip Action
            if !isEvaluated {
                Button(action: onSkip) {
                    HStack(spacing: 3) {
                        Text("Bỏ qua")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.vocabMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.vocabMuted.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(BentoCardButtonStyle())
            } else {
                Color.clear
                    .frame(width: 34, height: 34)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Prompt Hero Challenge Card Component View
public struct ReflexPromptHeroCardView: View {
    public let drill: ReflexDrillRecord
    public let isEvaluated: Bool
    public let isSpeaking: Bool
    @Binding public var showEnglishHint: Bool
    public let onSpeak: () -> Void

    public var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center) {
                Label("CÂU CẦN PHẢN XẠ NÓI", systemImage: "quote.bubble.fill")
                    .font(.caption2.bold().smallCaps())
                    .foregroundColor(.vocabHeroAccent)

                Spacer()

                // Target Speed Chip anchored in context
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                    Text("< 2.5s")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .monospacedDigit()
                }
                .foregroundColor(.vocabPeach)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.vocabPeach.opacity(0.14))
                .overlay(
                    Capsule()
                        .stroke(Color.vocabPeach.opacity(0.3), lineWidth: 1)
                )
                .clipShape(Capsule())
            }

            // Main Vietnamese Prompt
            Text(drill.promptText)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.vocabInk)
                .lineSpacing(4)
                .padding(.horizontal, 8)

            // English Hint / Reference Sentence
            if let sentence = drill.sentenceTextEn, !sentence.isEmpty {
                if showEnglishHint || isEvaluated {
                    Text("\"\(sentence)\"")
                        .font(.callout)
                        .italic()
                        .fontDesign(.serif)
                        .foregroundColor(.vocabMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showEnglishHint = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                            Text("Xem gợi ý đáp án")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.vocabPeach.opacity(0.14))
                        .foregroundColor(.vocabPeach)
                        .cornerRadius(14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(BentoCardButtonStyle())
                }
            }

            // Audio TTS Listen Button
            Button(action: onSpeak) {
                HStack(spacing: 8) {
                    Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.subheadline)
                        .symbolEffect(.bounce, value: isSpeaking)

                    Text(isSpeaking ? "Đang phát audio..." : "Nghe phát âm chuẩn")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.vocabHeroAccent.opacity(0.12))
                .foregroundColor(Color.vocabHeroAccent)
                .cornerRadius(20)
                .contentShape(Rectangle())
            }
            .buttonStyle(BentoCardButtonStyle())
            .frame(minHeight: 44)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Tactile Mic Control Hub Component View
public struct ReflexMicControlHubView: View {
    public let isListening: Bool
    public let onTapMic: () -> Void

    @State private var isMicPulsing = false

    public var body: some View {
        VStack(spacing: 12) {
            Button(action: onTapMic) {
                ZStack {
                    if isListening {
                        Circle()
                            .stroke(Color.vocabCoral.opacity(0.35), lineWidth: 4)
                            .frame(width: 108, height: 108)
                            .scaleEffect(isMicPulsing ? 1.2 : 1.0)
                            .opacity(isMicPulsing ? 0.2 : 0.8)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                    isMicPulsing = true
                                }
                            }
                            .onDisappear {
                                isMicPulsing = false
                            }
                    }

                    Circle()
                        .fill(
                            isListening
                            ? LinearGradient(colors: [Color.vocabCoral, Color.vocabCoral.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.vocabHeroAccent, Color.vocabHeroAccent.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 84, height: 84)
                        .shadow(
                            color: isListening ? Color.vocabCoral.opacity(0.4) : Color.vocabHeroAccent.opacity(0.35),
                            radius: 14,
                            x: 0,
                            y: 6
                        )

                    Image(systemName: isListening ? "waveform.and.mic" : "mic.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, value: isListening)
                }
                .frame(width: 112, height: 112)
                .contentShape(Circle())
            }
            .buttonStyle(BentoCardButtonStyle())
            .accessibilityLabel(isListening ? "Dừng ghi âm và chấm điểm" : "Bắt đầu nói đáp án tiếng Anh")

            Text(isListening ? "Chạm để hoàn thành bài nói" : "Chạm vào Micro để bắt đầu nói")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isListening ? .vocabCoral : .vocabMuted)
        }
        .padding(.vertical, 6)
        .sensoryFeedback(.impact(weight: .medium), trigger: isListening)
    }
}

// MARK: - Sticky Bottom Result Sheet Component View
public struct ReflexResultBottomDockView: View {
    public let state: ReflexDrillState
    public let onNext: () -> Void

    private var formattedTime: String {
        if state.elapsedTimeMs >= 1000 {
            let seconds = Double(state.elapsedTimeMs) / 1000.0
            return String(format: "%.1fs", seconds)
        } else {
            return "\(state.elapsedTimeMs)ms"
        }
    }

    private var conciseFeedbackText: String {
        if state.isCorrect {
            return "Phản xạ xuất sắc! Đáp án chuẩn xác."
        } else {
            return "Chưa trùng khớp — Hãy thử luyện tập lại."
        }
    }

    public var body: some View {
        let isSuccess = state.isCorrect
        let isSpeedTargetHit = state.elapsedTimeMs < 2500

        VStack(spacing: 12) {
            // Header Status & Speed Metric
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)

                    Text(isSuccess ? (isSpeedTargetHit ? "Phản xạ Tuyệt vời!" : "Chính xác!") : "Cần rèn luyện thêm")
                        .font(.headline.bold())
                        .foregroundColor(.vocabInk)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "stopwatch.fill")
                        .font(.caption2)
                    Text(formattedTime)
                        .font(.subheadline.bold())
                        .monospacedDigit()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSuccess ? Color.vocabMint.opacity(0.14) : Color.vocabInk.opacity(0.06))
                .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabInk)
                .cornerRadius(10)
            }
            .padding(.top, 4)

            // Concise Feedback Line (No redundant sentence echoing)
            Text(conciseFeedbackText)
                .font(.subheadline)
                .foregroundColor(.vocabMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            // SRS Progress & Schedule
            if let res = state.srsResult {
                Divider()
                    .background(Color.vocabHairline)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CẤP ĐỘ PHẢN XẠ (SRS)")
                            .font(.caption2.bold().smallCaps())
                            .foregroundColor(.vocabMuted)

                        if res.nextMastery > state.currentMastery {
                            HStack(spacing: 4) {
                                Text("Cấp \(state.currentMastery)")
                                    .font(.subheadline)
                                    .foregroundColor(.vocabMuted)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(.vocabHeroAccent)
                                Text("Cấp \(res.nextMastery)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.vocabHeroAccent)
                            }
                        } else {
                            Text("Cấp \(state.currentMastery)")
                                .font(.subheadline.bold())
                                .foregroundColor(.vocabInk)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("LỊCH ÔN TIẾP THEO")
                            .font(.caption2.bold().smallCaps())
                            .foregroundColor(.vocabMuted)

                        Text("\(res.intervalDays) ngày sau")
                            .font(.subheadline.bold())
                            .foregroundColor(.vocabInk)
                    }
                }
            }

            // Primary Action Button (Brand Emerald Mint Accent consistent across all screens)
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text("Bài tiếp theo")
                        .font(.headline.bold())
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.vocabHeroAccent, Color.vocabHeroAccent.opacity(0.88)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.vocabHeroAccent.opacity(0.25), radius: 8, x: 0, y: 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(BentoCardButtonStyle())
            .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Color.vocabSurfaceCard
                LinearGradient(
                    colors: [
                        isSuccess ? Color.vocabMint.opacity(0.08) : Color.vocabCoral.opacity(0.06),
                        Color.vocabSurfaceCard
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    isSuccess ? Color.vocabMint.opacity(0.35) : Color.vocabCoral.opacity(0.35),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .overlay(
            SRSSparkleEffectView(isEmitting: .constant(state.triggerSparkle))
        )
    }
}

// MARK: - Main Reflex Drill Screen View
public struct ReflexDrillView: View {
    @State private var viewModel: ReflexDrillViewModel
    @State private var showEnglishHint = false
    public var onDismiss: (() -> Void)? = nil

    @MainActor
    public init(viewModel: ReflexDrillViewModel, onDismiss: (() -> Void)? = nil) {
        self._viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header Bar
                        ReflexHeaderBarView(
                            currentIndex: viewModel.state.currentDrillIndex,
                            totalCount: viewModel.state.drillsList.count,
                            cefrLevel: viewModel.state.cefrLevel,
                            isEvaluated: viewModel.state.isEvaluated,
                            onDismiss: onDismiss,
                            onSkip: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    viewModel.nextDrill()
                                }
                            }
                        )

                        if let drill = viewModel.state.drill {
                            // Prompt Hero Challenge Card
                            ReflexPromptHeroCardView(
                                drill: drill,
                                isEvaluated: viewModel.state.isEvaluated,
                                isSpeaking: viewModel.isSpeaking,
                                showEnglishHint: $showEnglishHint,
                                onSpeak: { viewModel.speakCorrectAnswer() }
                            )

                            // Speech Visualizer & Live Text Display
                            ReflexSpeechVisualizerView(
                                isListening: viewModel.isListening,
                                recognizedText: viewModel.recognizedText
                            )

                            // Tactile Mic Control Hub (Hidden when evaluated to avoid occlusion behind bottom dock)
                            if !viewModel.state.isEvaluated {
                                ReflexMicControlHubView(
                                    isListening: viewModel.isListening,
                                    onTapMic: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            viewModel.handleMicTap()
                                        }
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        } else {
                            // Loading State
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(Color.vocabHeroAccent)
                                    .scaleEffect(1.2)
                                Text("Đang tải bài tập phản xạ nói...")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.vocabMuted)
                            }
                            .frame(maxWidth: .infinity, minHeight: 320)
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 20)
                }

                // Sticky Bottom Result Sheet (Docked cleanly below ScrollView)
                if viewModel.state.isEvaluated {
                    ReflexResultBottomDockView(
                        state: viewModel.state,
                        onNext: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                viewModel.nextDrill()
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            viewModel.loadDrills()
        }
        .onChange(of: viewModel.state.currentDrillIndex) { _, _ in
            showEnglishHint = false
        }
        .sensoryFeedback(viewModel.state.isCorrect ? .success : .error, trigger: viewModel.state.isEvaluated)
        .alert("Thông báo thu âm", isPresented: $viewModel.state.showErrorAlert) {
            Button("Đã hiểu", role: .cancel) { }
        } message: {
            Text(viewModel.state.errorMessage)
        }
    }
}
