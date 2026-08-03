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
        ScrollView {
            VStack(spacing: 24) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phản xạ nói Eng")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("Reflex Drill (\(cefrLevel))")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "stopwatch.fill")
                            .foregroundColor(.orange)
                        Text("< 2500ms")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(20)
                }
                .padding(.horizontal)

                if let drill = drill {
                    // Prompt Card
                    VStack(spacing: 16) {
                        Text(drill.promptText)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        if let sentence = drill.sentenceTextEn, !sentence.isEmpty {
                            Text("\"\(sentence)\"")
                                .font(.body)
                                .italic()
                                .foregroundColor(.secondary)
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(.blue)
                            .cornerRadius(20)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.12))
                    )
                    .padding(.horizontal)

                    // Live Recognized Text Box
                    VStack(spacing: 8) {
                        Text(stt.recognizedText.isEmpty ? (stt.isRecording ? "Đang lắng nghe..." : "Nhấn micro và nói đáp án...") : stt.recognizedText)
                            .font(.title3)
                            .fontWeight(stt.recognizedText.isEmpty ? .regular : .semibold)
                            .foregroundColor(stt.recognizedText.isEmpty ? .secondary : .primary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(stt.isRecording ? Color.red : Color.gray.opacity(0.3), lineWidth: stt.isRecording ? 2 : 1)
                                    .background(Color.gray.opacity(0.05).cornerRadius(16))
                            )
                    }
                    .padding(.horizontal)

                    // Mic Record Button
                    Button(action: toggleMic) {
                        ZStack {
                            Circle()
                                .fill(stt.isRecording ? Color.red.opacity(0.15) : Color.blue.opacity(0.12))
                                .frame(width: 88, height: 88)

                            if stt.isRecording {
                                Circle()
                                    .stroke(Color.red, lineWidth: 3)
                                    .frame(width: 88, height: 88)
                            }

                            Image(systemName: stt.isRecording ? "mic.fill" : "mic.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(stt.isRecording ? .red : .blue)
                        }
                    }

                    // Feedback & SRS Analytics Section
                    if isEvaluated {
                        VStack(spacing: 14) {
                            HStack {
                                Label(feedbackText, systemImage: srsResult?.nextMastery ?? 0 > currentMastery ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .font(.headline)
                                    .foregroundColor(srsResult?.nextMastery ?? 0 > 0 ? .green : .red)

                                Spacer()

                                Text("⚡ \(elapsedTimeMs) ms")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(elapsedTimeMs < 2500 ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                    .foregroundColor(elapsedTimeMs < 2500 ? .green : .orange)
                                    .cornerRadius(12)
                            }

                            if let res = srsResult {
                                Divider()

                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Mastery Level")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("Cấp \(res.nextMastery)")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("SRS Ôn tiếp")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(res.intervalDays) ngày sau")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
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
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Đang tải dữ liệu reflex drill...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(minHeight: 300)
                }
            }
            .padding(.vertical)
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
