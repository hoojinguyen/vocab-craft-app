import SwiftUI

public struct ReflexDrillView: View {
    @State private var viewModel: ReflexDrillViewModel

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
                VStack(spacing: 20) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Phản xạ nói Eng")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.vocabMuted)
                            Text("Reflex Drill (\(viewModel.state.cefrLevel))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.vocabInk)
                        }
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "stopwatch.fill")
                                .foregroundColor(.vocabPeach)
                            Text("< 2500ms")
                                .font(.caption)
                                .fontWeight(.heavy)
                                .foregroundColor(.vocabPeach)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.vocabPeach.opacity(0.18))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal)

                    if let drill = viewModel.state.drill {
                        // Prompt Card (Neumorphic Bento Surface Card)
                        VStack(spacing: 16) {
                            Text(drill.promptText)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.vocabInk)
                                .padding(.top, 8)

                            if let sentence = drill.sentenceTextEn, !sentence.isEmpty {
                                Text("\"\(sentence)\"")
                                    .font(.body)
                                    .italic()
                                    .foregroundColor(.vocabMuted)
                                    .multilineTextAlignment(.center)
                            }

                            // Listen Audio TTS Button
                            Button(action: {
                                viewModel.speakCorrectAnswer()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: viewModel.ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                    Text(viewModel.ttsService.isSpeaking ? "Đang phát audio..." : "Nghe phát âm")
                                        .fontWeight(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(Color.vocabHeroAccent.opacity(0.15))
                                .foregroundColor(Color.vocabHeroAccent)
                                .cornerRadius(20)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(BentoCardButtonStyle())
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color.vocabSurfaceCard)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.vocabHairline, lineWidth: 1.5)
                        )
                        .shadow(color: Color.vocabHeroTeal.opacity(0.05), radius: 6, x: 0, y: 3)
                        .padding(.horizontal)

                        // Live Recognized Text Box
                        VStack(spacing: 8) {
                            Text(viewModel.sttService.recognizedText.isEmpty ? (viewModel.sttService.isListening ? "Đang lắng nghe..." : "Nhấn micro và nói đáp án...") : viewModel.sttService.recognizedText)
                                .font(.title3)
                                .fontWeight(viewModel.sttService.recognizedText.isEmpty ? .regular : .semibold)
                                .foregroundColor(viewModel.sttService.recognizedText.isEmpty ? .vocabMuted : .vocabInk)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .padding()
                                .background(Color.vocabSurfaceCard)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(viewModel.sttService.isListening ? Color.vocabCoral : Color.vocabHairline, lineWidth: viewModel.sttService.isListening ? 2 : 1.5)
                                )
                        }
                        .padding(.horizontal)

                        // Mic Record Button
                        Button(action: {
                            if viewModel.sttService.isListening {
                                viewModel.stopVoiceRecognition()
                                viewModel.evaluateAnswer(viewModel.sttService.recognizedText)
                            } else {
                                viewModel.startVoiceRecognition()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.sttService.isListening ? Color.vocabCoral.opacity(0.18) : Color.vocabHeroAccent.opacity(0.12))
                                    .frame(width: 88, height: 88)

                                if viewModel.sttService.isListening {
                                    Circle()
                                        .stroke(Color.vocabCoral, lineWidth: 3)
                                        .frame(width: 88, height: 88)
                                }

                                Image(systemName: viewModel.sttService.isListening ? "mic.fill" : "mic.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(viewModel.sttService.isListening ? Color.vocabCoral : Color.vocabHeroAccent)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(BentoCardButtonStyle())
                        .frame(minWidth: 44, minHeight: 44)

                        // Feedback & SRS Analytics Section
                        if viewModel.state.isEvaluated {
                            ZStack {
                                VStack(spacing: 14) {
                                    HStack {
                                        Label(
                                            viewModel.state.feedbackText,
                                            systemImage: (viewModel.state.srsResult?.nextMastery ?? 0) > viewModel.state.currentMastery ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                                        )
                                        .font(.headline)
                                        .foregroundColor((viewModel.state.srsResult?.nextMastery ?? 0) > viewModel.state.currentMastery ? Color.vocabMint : Color.vocabCoral)

                                        Spacer()

                                        Text("⚡ \(viewModel.state.elapsedTimeMs) ms")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(viewModel.state.elapsedTimeMs < 2500 ? Color.vocabMint.opacity(0.18) : Color.vocabPeach.opacity(0.18))
                                            .foregroundColor(viewModel.state.elapsedTimeMs < 2500 ? Color.vocabMint : Color.vocabPeach)
                                            .cornerRadius(12)
                                    }

                                    if let res = viewModel.state.srsResult {
                                        Divider()
                                            .background(Color.vocabHairline)

                                        HStack(spacing: 20) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Mastery Level")
                                                    .font(.caption)
                                                    .foregroundColor(.vocabMuted)
                                                Text("Cấp \(res.nextMastery)")
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.vocabInk)
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("SRS Ôn tiếp")
                                                    .font(.caption)
                                                    .foregroundColor(.vocabMuted)
                                                Text("\(res.intervalDays) ngày sau")
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.vocabInk)
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.vocabSurfaceCard)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                                )
                                .padding(.horizontal)

                                SRSSparkleEffectView(isEmitting: $viewModel.state.triggerSparkle)
                            }
                        }

                        // Next Drill Action Button
                        Button(action: {
                            viewModel.nextDrill()
                        }) {
                            HStack {
                                Text("Bài tiếp theo")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.vocabHeroAccent)
                            .cornerRadius(16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(BentoCardButtonStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    } else {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(Color.vocabHeroAccent)
                            Text("Đang tải dữ liệu reflex drill...")
                                .font(.subheadline)
                                .foregroundColor(.vocabMuted)
                        }
                        .frame(minHeight: 300)
                    }
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            viewModel.loadDrills()
        }
    }
}
