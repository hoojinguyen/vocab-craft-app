import SwiftUI

/// Active Speech Visualizer View for Reflex Drill.
/// Displays an animated equalizer / sound bars visualizer while listening to user speech,
/// along with real-time recognized text and dynamic state indicators.
public struct ReflexSpeechVisualizerView: View {
    public let isListening: Bool
    public let recognizedText: String

    @State private var barHeights: [CGFloat] = [12, 24, 18, 30, 16, 26, 14]
    @State private var timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    public init(isListening: Bool, recognizedText: String) {
        self.isListening = isListening
        self.recognizedText = recognizedText
    }

    public var body: some View {
        VStack(spacing: 12) {
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
                .frame(height: 36)
                .onReceive(timer) { _ in
                    if isListening {
                        for i in 0..<barHeights.count {
                            barHeights[i] = CGFloat.random(in: 8...34)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Recognized Speech Text Display
            Text(displayText)
                .font(.system(size: 18, weight: recognizedText.isEmpty ? .regular : .semibold, design: .rounded))
                .foregroundColor(recognizedText.isEmpty ? .vocabMuted : .vocabInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .padding(16)
        .background(
            ZStack {
                Color.vocabSurfaceCard

                if isListening {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.vocabCoral.opacity(0.6), Color.vocabPeach.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                }
            }
        )
        .cornerRadius(20)
        .shadow(
            color: isListening ? Color.vocabCoral.opacity(0.12) : Color.black.opacity(0.03),
            radius: isListening ? 12 : 6,
            x: 0,
            y: isListening ? 6 : 3
        )
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

public struct ReflexDrillView: View {
    @State private var viewModel: ReflexDrillViewModel
    @State private var isMicPulsing = false
    @State private var showEnglishHint = false

    @MainActor
    public init(viewModel: ReflexDrillViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }

    @MainActor
    public init(datasetEngine: DatasetEngine? = nil, cefrLevel: String = "B1") {
        let repo = VocabularyRepositoryImpl(datasetEngine: datasetEngine)
        let fetchUseCase = FetchVocabularyUseCase(repository: repo)
        let vm = ReflexDrillViewModel(
            fetchVocabularyUseCase: fetchUseCase,
            cefrLevel: cefrLevel
        )
        self._viewModel = State(wrappedValue: vm)
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: - Header Bar
                    headerBar(viewModel: viewModel)

                    if let drill = viewModel.state.drill {
                        // MARK: - Prompt Hero Challenge Card
                        promptHeroCard(drill: drill, viewModel: viewModel)

                        // MARK: - Speech Visualizer & Live Text Container
                        ReflexSpeechVisualizerView(
                            isListening: viewModel.sttService.isListening,
                            recognizedText: viewModel.sttService.recognizedText
                        )
                        .padding(.horizontal)

                        // MARK: - Tactile Mic Control Hub
                        micControlHub(viewModel: viewModel)

                        // MARK: - Result & SRS Performance Dashboard
                        if viewModel.state.isEvaluated {
                            performanceResultCard(viewModel: viewModel)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // MARK: - Primary Next Drill Action Button
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                showEnglishHint = false
                                viewModel.nextDrill()
                            }
                        }) {
                            HStack(spacing: 10) {
                                Text("Bài tiếp theo")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                            }
                            .foregroundColor(viewModel.state.isEvaluated ? .white : .vocabHeroAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                Group {
                                    if viewModel.state.isEvaluated {
                                        LinearGradient(
                                            colors: [Color.vocabHeroAccent, Color.vocabHeroAccent.opacity(0.88)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        Color.vocabHeroAccent.opacity(0.12)
                                    }
                                }
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(viewModel.state.isEvaluated ? Color.clear : Color.vocabHeroAccent.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: viewModel.state.isEvaluated ? Color.vocabHeroAccent.opacity(0.28) : Color.clear, radius: 10, x: 0, y: 5)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(BentoCardButtonStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 36)
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
                .padding(.vertical)
            }
        }
        .onAppear {
            viewModel.loadDrills()
        }
    }

    // MARK: - Header Bar View Component
    @ViewBuilder
    private func headerBar(viewModel: ReflexDrillViewModel) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Phản xạ nói Eng")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.vocabMuted)
                        .textCase(.uppercase)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.vocabMuted)

                    Text("BÀI \(viewModel.state.currentDrillIndex + 1)/\(max(1, viewModel.state.drillsList.count))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.vocabHeroAccent.opacity(0.12))
                        .foregroundColor(.vocabHeroAccent)
                        .cornerRadius(6)
                }

                Text("Reflex Drill (\(viewModel.state.cefrLevel))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.vocabInk)
            }

            Spacer()

            // Target Speed Chip
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(.vocabPeach)
                Text("< 2500ms")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .monospacedDigit()
                    .foregroundColor(.vocabPeach)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.vocabPeach.opacity(0.14))
            .overlay(
                Capsule()
                    .stroke(Color.vocabPeach.opacity(0.3), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .padding(.horizontal)
    }

    // MARK: - Prompt Hero Challenge Card Component
    @ViewBuilder
    private func promptHeroCard(drill: ReflexDrillRecord, viewModel: ReflexDrillViewModel) -> some View {
        VStack(spacing: 18) {
            HStack {
                Label("CÂU CẦN PHẢN XẠ NÓI", systemImage: "quote.bubble.fill")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.vocabHeroAccent)
                Spacer()
            }

            // Main Vietnamese Prompt
            Text(drill.promptText)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.vocabInk)
                .lineSpacing(4)
                .padding(.horizontal, 8)

            // English Hint / Reference Sentence (Hidden by default to encourage active recall)
            if let sentence = drill.sentenceTextEn, !sentence.isEmpty {
                if showEnglishHint || viewModel.state.isEvaluated {
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
            Button(action: {
                viewModel.speakCorrectAnswer()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.subheadline)
                        .symbolEffect(.bounce, value: viewModel.ttsService.isSpeaking)

                    Text(viewModel.ttsService.isSpeaking ? "Đang phát audio..." : "Nghe phát âm chuẩn")
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

    // MARK: - Tactile Mic Control Hub Component
    @ViewBuilder
    private func micControlHub(viewModel: ReflexDrillViewModel) -> some View {
        let isListening = viewModel.sttService.isListening

        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    if isListening {
                        viewModel.stopVoiceRecognition()
                        viewModel.evaluateAnswer(viewModel.sttService.recognizedText)
                    } else {
                        viewModel.startVoiceRecognition()
                    }
                }
            }) {
                ZStack {
                    // Pulsing Outer Aura when Listening
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

                    // Background Glow Circle
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

                    // Icon
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

            // Status Label Under Button
            Text(isListening ? "Chạm để hoàn thành bài nói" : "Chạm vào Micro để bắt đầu nói")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isListening ? .vocabCoral : .vocabMuted)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Performance Result & SRS Dashboard Component
    @ViewBuilder
    private func performanceResultCard(viewModel: ReflexDrillViewModel) -> some View {
        let isSuccess = (viewModel.state.srsResult?.nextMastery ?? 0) >= viewModel.state.currentMastery
        let isSpeedTargetHit = viewModel.state.elapsedTimeMs < 2500

        ZStack {
            VStack(spacing: 16) {
                // Status Header & Speed Meter
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)

                        Text(isSuccess ? "Phản xạ Tuyệt vời!" : "Cần rèn luyện thêm")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.vocabInk)
                    }

                    Spacer()

                    // Speed Latency Badge
                    HStack(spacing: 4) {
                        Image(systemName: "stopwatch.fill")
                            .font(.caption2)
                        Text("\(viewModel.state.elapsedTimeMs) ms")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isSpeedTargetHit ? Color.vocabMint.opacity(0.16) : Color.vocabPeach.opacity(0.16))
                    .foregroundColor(isSpeedTargetHit ? Color.vocabMint : Color.vocabPeach)
                    .cornerRadius(12)
                }

                // Feedback Text Detail
                Text(viewModel.state.feedbackText)
                    .font(.subheadline)
                    .foregroundColor(.vocabMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let res = viewModel.state.srsResult {
                    Divider()
                        .background(Color.vocabHairline)

                    // SRS Progression & Next Review Dashboard
                    HStack(spacing: 16) {
                        // Mastery Level Meter
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CẤP ĐỘ PHẢN XẠ (SRS)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.vocabMuted)

                            HStack(spacing: 6) {
                                Text("Cấp \(viewModel.state.currentMastery)")
                                    .font(.subheadline)
                                    .foregroundColor(.vocabMuted)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(.vocabHeroAccent)
                                Text("Cấp \(res.nextMastery)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.vocabHeroAccent)
                            }
                        }

                        Spacer()

                        // Next Review Schedule
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("LỊCH ÔN TIẾP THEO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.vocabMuted)

                            Text("\(res.intervalDays) ngày sau")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.vocabInk)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSuccess ? Color.vocabMint.opacity(0.35) : Color.vocabCoral.opacity(0.35),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            .padding(.horizontal)

            // Celebration Sparkles when emission triggered
            SRSSparkleEffectView(isEmitting: $viewModel.state.triggerSparkle)
        }
    }
}
