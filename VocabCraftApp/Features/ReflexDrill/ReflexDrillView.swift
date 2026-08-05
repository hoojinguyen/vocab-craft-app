import SwiftUI

public struct ReflexDrillView: View {
    @State private var drill: ReflexDrillRecord?
    @State private var startTime: Date?
    @State private var elapsedTimeMs: Int = 0
    @State private var feedbackText: String = ""
    @State private var currentMastery: Int = 0
    @State private var easeFactor: Double = 2.5
    @State private var srsResult: SRSResult?
    @State private var isEvaluated: Bool = false
    @State private var cefrLevel: String = "B1"

    private let tts = TextToSpeechService()
    private let stt = SpeechRecognitionService()
    private let datasetEngine: DatasetEngine?

    public init(datasetEngine: DatasetEngine? = nil, cefrLevel: String = "B1") {
        self.datasetEngine = datasetEngine
        self._cefrLevel = State(initialValue: cefrLevel)
    }

    public var body: some View {
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
                            Text("Reflex Drill (\(cefrLevel))")
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

                    if let drill = drill {
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
                                tts.speak(text: drill.correctAnswer)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: tts.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                    Text(tts.isSpeaking ? "Đang phát audio..." : "Nghe phát âm")
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
                            Text(stt.recognizedText.isEmpty ? (stt.isRecording ? "Đang lắng nghe..." : "Nhấn micro và nói đáp án...") : stt.recognizedText)
                                .font(.title3)
                                .fontWeight(stt.recognizedText.isEmpty ? .regular : .semibold)
                                .foregroundColor(stt.recognizedText.isEmpty ? .vocabMuted : .vocabInk)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .padding()
                                .background(Color.vocabSurfaceCard)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(stt.isRecording ? Color.vocabCoral : Color.vocabHairline, lineWidth: stt.isRecording ? 2 : 1.5)
                                )
                        }
                        .padding(.horizontal)

                        // Mic Record Button
                        Button(action: toggleMic) {
                            ZStack {
                                Circle()
                                    .fill(stt.isRecording ? Color.vocabCoral.opacity(0.18) : Color.vocabHeroAccent.opacity(0.12))
                                    .frame(width: 88, height: 88)

                                if stt.isRecording {
                                    Circle()
                                        .stroke(Color.vocabCoral, lineWidth: 3)
                                        .frame(width: 88, height: 88)
                                }

                                Image(systemName: stt.isRecording ? "mic.fill" : "mic.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(stt.isRecording ? Color.vocabCoral : Color.vocabHeroAccent)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(BentoCardButtonStyle())
                        .frame(minWidth: 44, minHeight: 44)

                        // Feedback & SRS Analytics Section
                        if isEvaluated {
                            VStack(spacing: 14) {
                                HStack {
                                    Label(
                                        feedbackText,
                                        systemImage: (srsResult?.nextMastery ?? 0) > currentMastery ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                                    )
                                    .font(.headline)
                                    .foregroundColor((srsResult?.nextMastery ?? 0) > currentMastery ? Color.vocabMint : Color.vocabCoral)

                                    Spacer()

                                    Text("⚡ \(elapsedTimeMs) ms")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(elapsedTimeMs < 2500 ? Color.vocabMint.opacity(0.18) : Color.vocabPeach.opacity(0.18))
                                        .foregroundColor(elapsedTimeMs < 2500 ? Color.vocabMint : Color.vocabPeach)
                                        .cornerRadius(12)
                                }

                                if let res = srsResult {
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
                        }

                        // Next Drill Action Button
                        Button(action: loadNextDrill) {
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
        .onAppear(perform: loadNextDrill)
    }

    private func loadNextDrill() {
        isEvaluated = false
        feedbackText = ""
        srsResult = nil
        stt.stopListening()
        
        if let engine = datasetEngine {
            drill = engine.getRandomReflexDrill(cefrLevel: cefrLevel)
        } else {
            // Demo fallback drill for testing preview/views
            drill = ReflexDrillRecord(
                id: 1,
                drillType: "speaking_reflex",
                promptText: "Bổ sung thông tin chi tiết?",
                correctAnswer: "elaborate",
                distractors: ["evaluate", "eliminate", "elevate"],
                targetTimeMs: 2500,
                sentenceTextEn: "Can you elaborate on your point?"
            )
        }
        startTime = nil
    }

    private func toggleMic() {
        if stt.isRecording {
            stt.stopListening()
            evaluateResponse()
        } else {
            stt.requestAuthorization { authorized in
                if authorized {
                    do {
                        startTime = Date()
                        try stt.startListening()
                    } catch {
                        print("Speech recognition failed to start: \(error)")
                    }
                }
            }
        }
    }

    private func evaluateResponse() {
        guard let drill = drill else { return }
        let now = Date()
        let start = startTime ?? now.addingTimeInterval(-2.0)
        elapsedTimeMs = max(100, Int(now.timeIntervalSince(start) * 1000))

        let userText = stt.recognizedText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let targetText = drill.correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let isCorrect = userText == targetText || userText.contains(targetText)

        let result = SRSEngine.calculateNextInterval(
            currentMastery: currentMastery,
            easeFactor: easeFactor,
            isCorrect: isCorrect,
            responseTimeMs: elapsedTimeMs
        )

        srsResult = result
        currentMastery = result.nextMastery
        easeFactor = result.easeFactor
        isEvaluated = true

        if isCorrect {
            feedbackText = elapsedTimeMs < 2500 ? "Phản xạ xuất sắc!" : "Chính xác (Cần nhanh hơn)"
        } else {
            feedbackText = "Chưa đúng. Đáp án: \(drill.correctAnswer)"
        }
    }
}
