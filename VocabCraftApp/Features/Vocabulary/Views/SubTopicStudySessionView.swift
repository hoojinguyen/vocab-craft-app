import SwiftUI

public struct SubTopicStudySessionView: View {
    public let node: SubTopicNode
    public let onDismiss: () -> Void
    public let onComplete: (Int) -> Void

    @State private var engine: SubTopicSessionEngine
    @State private var isFlipped: Bool = false
    @State private var isSuccess: Bool = true
    @State private var selectedAnswer: String? = nil
    @State private var options: [String] = []

    @Environment(\.colorScheme) private var colorScheme

    public init(
        node: SubTopicNode,
        onDismiss: @escaping () -> Void,
        onComplete: @escaping (Int) -> Void
    ) {
        self.node = node
        self.onDismiss = onDismiss
        self.onComplete = onComplete
        let wordsToUse = node.words.isEmpty ? SubTopicStudySessionView.sampleWords : node.words
        self._engine = State(initialValue: SubTopicSessionEngine(words: wordsToUse))
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header Bar with Circle Close & XP Badge
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                        .frame(width: 32, height: 32)
                        .background(Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                }

                // 10 Progress segments
                HStack(spacing: 3) {
                    ForEach(0..<max(1, engine.totalQuestionsCount), id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(idx < engine.currentIndex ? Color.vocabMint : Color.vocabHairline)
                            .frame(height: 6)
                    }
                }

                // Header XP Badge
                HStack(spacing: 4) {
                    Text("⚡")
                    Text("+\(engine.xpEarned) XP")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.vocabPeach)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.vocabPeach.opacity(0.15))
                .cornerRadius(12)
            }

            if let word = engine.currentWord {
                // 3D Flip Flashcard
                ReflexFlipCardView(
                    word: word,
                    isFlipped: isFlipped,
                    isSuccess: isSuccess,
                    onAudioTap: {
                        // TTS audio
                    }
                )

                Spacer()

                // Thumb-Zone Quiz Options Section
                VStack(spacing: 10) {
                    HStack {
                        Text("Chọn đáp án đúng:")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.vocabMuted)
                        Spacer()
                        Text("Lần \(3 - engine.attemptsLeft)/2")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.vocabMuted)
                    }

                    ForEach(options, id: \.self) { opt in
                        QuizOptionRowView(
                            option: opt,
                            isSelected: selectedAnswer == opt,
                            isSuccess: isSuccess,
                            action: { handleAnswer(opt) },
                            isDisabled: selectedAnswer != nil && isFlipped
                        )
                    }
                }

                // Bottom Feedback Sheet / Continue Action
                if isFlipped {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isSuccess ? "✓ Chính xác! (+10 XP)" : "✕ Chưa chính xác (-5 XP)")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)

                        Text(isSuccess ? "Đã tự động đồng bộ từ vựng vào Kho cá nhân." : "Từ này sẽ được đưa về cuối lượt để ôn lại.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.vocabMuted)

                        Button(action: nextWord) {
                            HStack {
                                Text("Tiếp tục")
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.vocabInk)
                            .foregroundColor(Color.vocabCanvas)
                            .cornerRadius(14)
                        }
                        .buttonStyle(PressedScaleButtonStyle())
                        .padding(.top, 4)
                    }
                    .padding(16)
                    .background((isSuccess ? Color.vocabMint : Color.vocabCoral).opacity(0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSuccess ? Color.vocabMint : Color.vocabCoral, lineWidth: 1.5)
                    )
                }
            } else {
                // Session finished -> SubTopicSessionSummaryView
                SubTopicSessionSummaryView(
                    xpEarned: engine.xpEarned,
                    totalQuestions: engine.totalQuestionsCount,
                    correctCount: engine.correctCount,
                    onRestart: {
                        self.engine = SubTopicSessionEngine(words: node.words.isEmpty ? SubTopicStudySessionView.sampleWords : node.words)
                    },
                    onFinish: {
                        onComplete(engine.xpEarned)
                    }
                )
            }
        }
        .padding(20)
        .background(Color.vocabCanvas.ignoresSafeArea())
        .onAppear {
            if let word = engine.currentWord {
                options = engine.generateDistractors(for: word)
            }
        }
        .onChange(of: engine.currentIndex) { _, _ in
            if let word = engine.currentWord {
                options = engine.generateDistractors(for: word)
            }
        }
    }

    private func handleAnswer(_ opt: String) {
        selectedAnswer = opt
        let result = engine.submitAnswer(selectedVietnamese: opt)

        isSuccess = result.isCorrect
        if result.isCorrect || result.attemptsRemaining <= 0 {
            isFlipped = true
        }
    }


    private func nextWord() {
        selectedAnswer = nil
        isFlipped = false
        engine.advanceToNextWord()
    }

    public static let sampleWords: [TopicWord] = [
        TopicWord(id: "w1", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Sự tự động hóa", example: "Factory automation reduces production costs.", partOfSpeech: "noun"),
        TopicWord(id: "w2", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán", example: "The search algorithm returns accurate results.", partOfSpeech: "noun"),
        TopicWord(id: "w3", english: "Ecosystem", phonetic: "/ˈiː.koʊˌsɪs.təm/", vietnamese: "Hệ sinh thái", example: "Pollution threatens the marine ecosystem.", partOfSpeech: "noun"),
        TopicWord(id: "w4", english: "Biodiversity", phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.ti/", vietnamese: "Đa dạng sinh học", example: "Rainforests are rich in biodiversity.", partOfSpeech: "noun"),
        TopicWord(id: "w5", english: "Sustainability", phonetic: "/səˌsteɪ.nəˈbɪl.ə.ti/", vietnamese: "Sự bền vững", example: "Company policies focus on sustainability.", partOfSpeech: "noun"),
        TopicWord(id: "w6", english: "Innovation", phonetic: "/ˌɪn.əˈveɪ.ʃən/", vietnamese: "Sự đổi mới sáng tạo", example: "Technological innovation drives economic growth.", partOfSpeech: "noun"),
        TopicWord(id: "w7", english: "Infrastructure", phonetic: "/ˈɪn.frəˌstrʌk.tʃər/", vietnamese: "Hạ tầng", example: "The city invested in new transportation infrastructure.", partOfSpeech: "noun"),
        TopicWord(id: "w8", english: "Artificial", phonetic: "/ˌɑːr.t̬əˈfɪʃ.əl/", vietnamese: "Nhân tạo", example: "Artificial intelligence learns from data.", partOfSpeech: "adjective"),
        TopicWord(id: "w9", english: "Intelligence", phonetic: "/ɪnˈtel.ə.dʒəns/", vietnamese: "Trí tuệ", example: "Human intelligence is adaptable.", partOfSpeech: "noun"),
        TopicWord(id: "w10", english: "Architecture", phonetic: "/ˈɑːr.kə.tek.tʃər/", vietnamese: "Kiến trúc", example: "Modern architecture combines style and utility.", partOfSpeech: "noun")
    ]
}

private struct QuizOptionRowView: View {
    let option: String
    let isSelected: Bool
    let isSuccess: Bool
    let action: () -> Void
    let isDisabled: Bool

    var body: some View {
        Button(action: action) {
            HStack {
                Text(option)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                if isSelected {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Color.vocabHairline)
                }
            }
            .padding(14)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(PressedScaleButtonStyle())
        .disabled(isDisabled)
    }

    private var backgroundColor: Color {
        guard isSelected else { return Color.vocabSurfaceCard }
        return isSuccess ? Color.vocabMint.opacity(0.15) : Color.vocabCoral.opacity(0.15)
    }

    private var foregroundColor: Color {
        guard isSelected else { return Color.vocabInk }
        return isSuccess ? Color.vocabMint : Color.vocabCoral
    }

    private var borderColor: Color {
        guard isSelected else { return Color.vocabHairline }
        return isSuccess ? Color.vocabMint : Color.vocabCoral
    }
}

public struct PressedScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
