import CraftUIKit
import SwiftUI

/// Step 2 of the Stage Learning Flow: Interactive quiz challenge with segmented progress bar, audio pronunciation, real-time feedback, and automatic weak-word flagging.
public struct StageChallengeView: View {
    @Environment(\.craftTheme) private var theme
    @State private var viewModel: StageChallengeViewModel
    public let onClose: () -> Void
    public var onCompleted: ((StageCompletionSummary) -> Void)?

    @State private var feedbackHapticTrigger: Int = 0
    @State private var isProcessingCompletion: Bool = false

    public init(
        viewModel: StageChallengeViewModel,
        onClose: @escaping () -> Void,
        onCompleted: ((StageCompletionSummary) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onClose = onClose
        self.onCompleted = onCompleted
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground.ignoresSafeArea()

            if let summary = viewModel.summary, viewModel.isCompleted {
                // If completed and summary is ready, present StageSummarySheet
                StageSummarySheet(
                    summary: summary,
                    onFinish: {
                        onCompleted?(summary)
                        onClose()
                    },
                    onRestart: {
                        viewModel.restartQuiz()
                    }
                )
            } else if let question = viewModel.currentQuestion {
                VStack(spacing: 0) {
                    // Top Bar & Segmented Progress
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    segmentedProgressBar
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 16)

                    Divider()
                        .background(theme.colors.hairline)

                    // Scrollable Question & Options
                    ScrollView {
                        VStack(spacing: 20) {
                            questionCard(for: question)

                            optionsList(for: question)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 120)
                    }

                    Spacer()

                    // Bottom Feedback Action Bar
                    if viewModel.isAnswerSubmitted {
                        feedbackActionBar(for: question)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Đang chuẩn bị câu hỏi...")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .sensoryFeedback(.success, trigger: feedbackHapticTrigger) { _, newValue in
            newValue > 0 && viewModel.lastAnswerCorrect
        }
        .sensoryFeedback(.error, trigger: feedbackHapticTrigger) { _, newValue in
            newValue > 0 && !viewModel.lastAnswerCorrect
        }
        .task {
            let args = ProcessInfo.processInfo.arguments
            guard let stateIdx = args.firstIndex(of: "-vocab-state"), stateIdx + 1 < args.count else { return }
            let state = args[stateIdx + 1]
            try? await Task.sleep(nanoseconds: 200_000_000)
            if state == "stage-quiz-correct" {
                if let questionItem = viewModel.currentQuestion {
                    viewModel.submitAnswer(questionItem.correctAnswer)
                }
            } else if state == "stage-quiz-incorrect" {
                if let questionItem = viewModel.currentQuestion {
                    let wrong = questionItem.options.first { $0 != questionItem.correctAnswer } ?? ""
                    viewModel.submitAnswer(wrong)
                }
            } else if state == "stage-summary-passed" {
                for _ in 0..<viewModel.questions.count {
                    if let questionItem = viewModel.currentQuestion {
                        viewModel.submitAnswer(questionItem.correctAnswer)
                    }
                    if !viewModel.isLastQuestion {
                        viewModel.nextQuestion()
                    }
                }
                await viewModel.completeStage()
            } else if state == "stage-summary-failed" {
                for idx in 0..<viewModel.questions.count {
                    if let questionItem = viewModel.currentQuestion {
                        if idx < 2 {
                            viewModel.submitAnswer(questionItem.correctAnswer)
                        } else {
                            let wrong = questionItem.options.first { $0 != questionItem.correctAnswer } ?? ""
                            viewModel.submitAnswer(wrong)
                        }
                    }
                    if !viewModel.isLastQuestion {
                        viewModel.nextQuestion()
                    }
                }
                await viewModel.completeStage()
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(alignment: .center) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(8)
                    .background(theme.colors.surfaceSubtle)
                    .clipShape(Circle())
            }

            Spacer()

            // Question counter
            Text("Câu \(viewModel.currentIndex + 1) / \(viewModel.questions.count)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(theme.colors.textSecondary)

            Spacer()

            // Streak / Score Badge
            HStack(spacing: 4) {
                if viewModel.streakCount > 1 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.colors.accent)

                    Text("\(viewModel.streakCount)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.accent)
                } else {
                    Text("+\(viewModel.correctCount * 10) XP")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.statusSuccess)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(theme.colors.surfaceCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.colors.hairline, lineWidth: 1)
            )
        }
    }

    // MARK: - Segmented Progress Bar
    private var segmentedProgressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<viewModel.questions.count, id: \.self) { index in
                Capsule()
                    .fill(segmentColor(for: index))
                    .frame(height: 6)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.currentIndex)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.results.count)
            }
        }
    }

    private func segmentColor(for index: Int) -> Color {
        if index < viewModel.results.count {
            let result = viewModel.results[index]
            return result.isCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger
        } else if index == viewModel.currentIndex {
            return theme.colors.accent
        } else {
            return theme.colors.hairline
        }
    }

    // MARK: - Question Card
    private func questionCard(for question: WordChallengeQuestion) -> some View {
        VStack(spacing: 12) {
            // Prompt Word
            Text(question.prompt)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            // Phonetic & Speaker Button
            HStack(spacing: 8) {
                if !question.hintPhonetic.isEmpty {
                    Text(question.hintPhonetic)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                }

                Button(action: {
                    viewModel.playAudio()
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(theme.colors.surfaceSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Nghe phát âm")
            }

            // Context Sentence if available
            if !question.exampleSentence.isEmpty {
                Text("“\(question.exampleSentence)”")
                    .font(.system(size: 13, weight: .medium))
                    .italic()
                    .foregroundColor(theme.colors.textPrimary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(theme.colors.surfaceCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.hairline, lineWidth: 1)
        )
    }

    // MARK: - Options List
    private func optionsList(for question: WordChallengeQuestion) -> some View {
        VStack(spacing: 10) {
            ForEach(question.options, id: \.self) { option in
                optionButton(option: option, question: question)
            }
        }
    }

    private func optionButton(option: String, question: WordChallengeQuestion) -> some View {
        let isSelected = (viewModel.selectedAnswer == option)
        let isCorrect = (option == question.correctAnswer)
        let isSubmitted = viewModel.isAnswerSubmitted

        return Button(action: {
            guard !viewModel.isAnswerSubmitted else { return }
            viewModel.submitAnswer(option)
            feedbackHapticTrigger += 1
        }) {
            HStack {
                Text(option)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(optionTextColor(isSelected: isSelected, isCorrect: isCorrect, isSubmitted: isSubmitted))
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSubmitted {
                    if isSelected && isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(theme.colors.statusSuccess)
                            .font(.system(size: 18, weight: .bold))
                    } else if isSelected && !isCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.colors.statusDanger)
                            .font(.system(size: 18, weight: .bold))
                    } else if !isSelected && isCorrect {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(theme.colors.statusSuccess)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(optionBackground(isSelected: isSelected, isCorrect: isCorrect, isSubmitted: isSubmitted))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(optionBorderColor(isSelected: isSelected, isCorrect: isCorrect, isSubmitted: isSubmitted), lineWidth: isSelected || (isSubmitted && isCorrect) ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(BentoCardButtonStyle())
        .disabled(isSubmitted)
    }

    private func optionTextColor(isSelected: Bool, isCorrect: Bool, isSubmitted: Bool) -> Color {
        if isSubmitted {
            if isSelected && isCorrect { return theme.colors.statusSuccess }
            if isSelected && !isCorrect { return theme.colors.statusDanger }
            if !isSelected && isCorrect { return theme.colors.statusSuccess }
            return theme.colors.textSecondary
        }
        return theme.colors.textPrimary
    }

    private func optionBackground(isSelected: Bool, isCorrect: Bool, isSubmitted: Bool) -> Color {
        if isSubmitted {
            if isSelected && isCorrect { return theme.colors.statusSuccess.opacity(0.12) }
            if isSelected && !isCorrect { return theme.colors.statusDanger.opacity(0.12) }
            if !isSelected && isCorrect { return theme.colors.statusSuccess.opacity(0.06) }
        }
        return theme.colors.surfaceCard
    }

    private func optionBorderColor(isSelected: Bool, isCorrect: Bool, isSubmitted: Bool) -> Color {
        if isSubmitted {
            if isSelected && isCorrect { return theme.colors.statusSuccess }
            if isSelected && !isCorrect { return theme.colors.statusDanger }
            if !isSelected && isCorrect { return theme.colors.statusSuccess.opacity(0.7) }
        }
        return theme.colors.hairline
    }

    // MARK: - Feedback Action Bar
    private func feedbackActionBar(for question: WordChallengeQuestion) -> some View {
        VStack(spacing: 12) {
            Divider()
                .background(theme.colors.hairline)

            HStack(spacing: 12) {
                // Feedback message
                VStack(alignment: .leading, spacing: 2) {
                    if viewModel.lastAnswerCorrect {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.colors.statusSuccess)
                            Text("Chính xác! +10 XP")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(theme.colors.statusSuccess)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(theme.colors.statusDanger)
                                Text("Chưa đúng")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(theme.colors.statusDanger)
                            }
                            Text("Đáp án: \(question.correctAnswer)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                        }
                    }
                }

                Spacer()

                // Continue / Complete CTA Button
                Button(action: {
                    if viewModel.isLastQuestion {
                        Task {
                            isProcessingCompletion = true
                            await viewModel.completeStage()
                            isProcessingCompletion = false
                        }
                    } else {
                        viewModel.nextQuestion()
                    }
                }) {
                    HStack(spacing: 6) {
                        if isProcessingCompletion {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(viewModel.isLastQuestion ? "Hoàn thành" : "Tiếp tục")
                                .font(.system(size: 14, weight: .bold))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: viewModel.lastAnswerCorrect
                                ? [theme.colors.statusSuccess, theme.colors.statusSuccess.opacity(0.85)]
                                : [theme.colors.accent, theme.colors.accent.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: (viewModel.lastAnswerCorrect ? theme.colors.statusSuccess : theme.colors.accent).opacity(0.35), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(BentoCardButtonStyle())
                .disabled(isProcessingCompletion)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .background(theme.colors.surfaceCard.ignoresSafeArea(edges: .bottom))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
