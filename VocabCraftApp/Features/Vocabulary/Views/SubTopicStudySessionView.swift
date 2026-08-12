import SwiftUI

public struct SubTopicStudySessionView: View {
    public let node: SubTopicNode
    public let onDismiss: () -> Void
    public let onComplete: (Int) -> Void

    @State private var viewModel: StudySessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    public init(
        node: SubTopicNode,
        onDismiss: @escaping () -> Void,
        onComplete: @escaping (Int) -> Void
    ) {
        self.node = node
        self.onDismiss = onDismiss
        self.onComplete = onComplete
        self._viewModel = State(initialValue: StudySessionViewModel(words: node.words))
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 20) {
            if !viewModel.engine.isSessionComplete {
                // ROW 1: Navigation & Stats Header (Close Button, Title, XP Badge)
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                            .frame(width: 38, height: 38)
                            .background(Color.vocabSurfaceCard)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.vocabHairline, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 6, x: 0, y: 3)
                    }

                    Spacer()

                    Text(node.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                        .lineLimit(1)

                    Spacer()

                    // Dynamic XP Pill Badge
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.vocabMint)
                        Text(formattedXPText(viewModel.engine.xpEarned))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.vocabHairline, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 6, x: 0, y: 3)
                }

                // ROW 2: Dedicated Full-Width Segmented Progress Bar
                HStack(spacing: 5) {
                    ForEach(0..<viewModel.engine.totalQuestionsCount, id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(segmentColor(for: idx))
                            .frame(height: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(segmentBorderColor(for: idx), lineWidth: segmentLineWidth(for: idx))
                            )
                    }
                }
                .padding(.top, 4)

                // 3D Flip Card Widget
                if let word = viewModel.engine.currentWord {
                    ReflexFlipCardView(
                        word: word,
                        isFlipped: viewModel.isFlipped,
                        isSuccess: viewModel.isSuccess,
                        onAudioTap: {
                            viewModel.speakCurrentWord()
                        }
                    )
                }

                // Thumb-Zone Quiz Options & Attempt Status Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Chọn đáp án đúng:")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                        Spacer()
                        Text("Lần \(2 - viewModel.engine.attemptsLeft)/2")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.vocabMuted)
                    }

                    VStack(spacing: 10) {
                        ForEach(viewModel.options, id: \.self) { opt in
                            QuizOptionRowView(
                                option: opt,
                                isSelected: viewModel.selectedAnswer == opt,
                                isWrongAttempted: viewModel.attemptedWrongAnswers.contains(opt),
                                isSuccess: viewModel.isSuccess,
                                action: { viewModel.submitAnswer(opt) },
                                isDisabled: viewModel.isFlipped || viewModel.attemptedWrongAnswers.contains(opt)
                            )
                        }
                    }

                    // Fixed Height Action Slot / Feedback Toast
                    VStack {
                        if viewModel.isFlipped {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(viewModel.isSuccess ? "✓ Chính xác! (+\(viewModel.lastXPDelta) XP)" : "✕ Chưa chính xác (-5 XP)")
                                        .font(.system(size: 15, weight: .heavy))
                                        .foregroundColor(viewModel.isSuccess ? Color.vocabMint : Color.vocabCoral)
                                    Spacer()
                                }

                                Button(action: { viewModel.advanceToNext() }) {
                                    HStack {
                                        Text("Tiếp tục")
                                            .font(.system(size: 14, weight: .bold))
                                        Image(systemName: "arrow.right")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.vocabInk)
                                    .foregroundColor(Color.vocabCanvas)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PressedScaleButtonStyle())
                            }
                            .padding(14)
                            .background((viewModel.isSuccess ? Color.vocabMint : Color.vocabCoral).opacity(0.1))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke((viewModel.isSuccess ? Color.vocabMint : Color.vocabCoral).opacity(0.5), lineWidth: 1)
                            )
                            .transition(.opacity)
                        }
                    }
                    .frame(height: 104)
                }
            } else {
                // Session finished -> SubTopicSessionSummaryView
                SubTopicSessionSummaryView(
                    xpEarned: viewModel.engine.xpEarned,
                    totalQuestions: viewModel.engine.totalQuestionsCount,
                    correctCount: viewModel.engine.passedCount,
                    onRestart: {
                        let wordsToUse = node.words.isEmpty ? SubTopicStudySessionView.sampleWords : node.words
                        self.viewModel = StudySessionViewModel(words: wordsToUse)
                    },
                    onFinish: {
                        onComplete(viewModel.engine.xpEarned)
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.vocabCanvas.ignoresSafeArea())
    }

    func segmentColor(for index: Int) -> Color {
        if let passed = viewModel.engine.questionPassedResults[index] {
            return passed ? Color.vocabMint : Color.vocabCoral
        } else if index == viewModel.engine.currentIndex {
            return Color.vocabPeach.opacity(0.25)
        } else {
            return Color.dynamic(
                light: Color(red: 0.96, green: 0.94, blue: 0.89),
                dark: Color.white.opacity(0.08)
            )
        }
    }

    func segmentBorderColor(for index: Int) -> Color {
        if let passed = viewModel.engine.questionPassedResults[index] {
            return passed ? Color.vocabMint : Color.vocabCoral
        } else if index == viewModel.engine.currentIndex {
            return Color.vocabPeach
        } else {
            return Color.dynamic(
                light: Color(red: 0.45, green: 0.45, blue: 0.45),
                dark: Color.white.opacity(0.20)
            )
        }
    }

    func segmentLineWidth(for index: Int) -> CGFloat {
        if viewModel.engine.questionPassedResults[index] != nil {
            return 0
        } else if index == viewModel.engine.currentIndex {
            return 1.5
        } else {
            return 1.0
        }
    }

    private func formattedXPText(_ xp: Int) -> String {
        if xp > 0 {
            return "+\(xp) XP"
        } else if xp == 0 {
            return "0 XP"
        } else {
            return "\(xp) XP"
        }
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
    let isWrongAttempted: Bool
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
                } else if isWrongAttempted {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.vocabCoral)
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
        if isSelected {
            return isSuccess ? Color.vocabMint.opacity(0.15) : Color.vocabCoral.opacity(0.15)
        }
        if isWrongAttempted {
            return Color.vocabCoral.opacity(0.12)
        }
        return Color.vocabSurfaceCard
    }

    private var foregroundColor: Color {
        if isSelected {
            return isSuccess ? Color.vocabMint : Color.vocabCoral
        }
        if isWrongAttempted {
            return Color.vocabCoral
        }
        return Color.vocabInk
    }

    private var borderColor: Color {
        if isSelected {
            return isSuccess ? Color.vocabMint : Color.vocabCoral
        }
        if isWrongAttempted {
            return Color.vocabCoral.opacity(0.4)
        }
        return Color.vocabHairline
    }
}

public struct PressedScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
