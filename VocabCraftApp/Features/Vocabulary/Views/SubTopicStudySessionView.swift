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
        self._engine = State(initialValue: SubTopicSessionEngine(words: node.words))
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header Bar
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                }

                // Progress segments
                HStack(spacing: 4) {
                    ForEach(0..<max(1, engine.totalQuestionsCount), id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(idx < engine.currentIndex ? Color.vocabMint : Color.vocabHairline)
                            .frame(height: 5)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color.vocabPeach)
                    Text("\(engine.comboCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                }
            }

            if let word = engine.currentWord {
                // 3D Flip Flashcard
                ReflexFlipCardView(
                    word: word,
                    isFlipped: isFlipped,
                    isSuccess: isSuccess,
                    onAudioTap: {
                        // Audio TTS trigger
                    }
                )

                // Quiz Options Grid
                VStack(spacing: 8) {
                    HStack {
                        Text("Số lần thử còn lại: \(engine.attemptsLeft)/2")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(engine.attemptsLeft == 1 ? Color.vocabCoral : Color.vocabMuted)
                        Spacer()
                        Text("XP: +\(engine.xpEarned)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.vocabMint)
                    }

                    ForEach(displayedOptions(for: word), id: \.self) { opt in
                        Button(action: { handleAnswer(opt) }) {
                            HStack {
                                Text(opt)
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                if selectedAnswer == opt {
                                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(Color.vocabMuted)
                                }
                            }
                            .padding(14)
                            .background(optionBackground(for: opt))
                            .foregroundColor(optionForeground(for: opt))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(optionBorder(for: opt), lineWidth: 1)
                            )
                        }
                        .disabled(selectedAnswer != nil && isFlipped)
                    }
                }
                .onAppear {
                    setupOptionsIfNeeded(for: word)
                }
                .onChange(of: engine.currentIndex) { _, _ in
                    if let current = engine.currentWord {
                        setupOptions(for: current)
                    }
                }

                Spacer()

                // Bottom Feedback Sheet / Continue Button
                if isFlipped {
                    Button(action: nextWord) {
                        HStack {
                            Text(isSuccess ? "✓ CHÍNH XÁC! (+10 XP) • TIẾP TỤC" : "✕ SAI 2 LẦN (-5 XP) • TIẾP TỤC")
                                .font(.system(size: 14, weight: .bold))
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isSuccess ? Color.vocabMint : Color.vocabCoral)
                        .foregroundColor(Color.vocabCanvas)
                        .cornerRadius(14)
                    }
                }
            } else {
                // Session finished
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.vocabPeach)
                    Text("CHÚC MỪNG HOÀN THÀNH CHẶNG!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                    Text("Tổng XP nhận được: +\(engine.xpEarned)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabMuted)

                    Button(action: { onComplete(engine.xpEarned) }) {
                        Text("HOÀN THÀNH")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.vocabInk)
                            .foregroundColor(Color.vocabCanvas)
                            .cornerRadius(14)
                    }
                }
                .padding(24)
            }
        }
        .padding(20)
        .background(Color.vocabCanvas.ignoresSafeArea())
    }

    private func handleAnswer(_ opt: String) {
        selectedAnswer = opt
        let result = engine.submitAnswer(selectedVietnamese: opt)

        if result.isCorrect {
            isSuccess = true
            isFlipped = true
        } else {
            if result.attemptsRemaining <= 0 {
                isSuccess = false
                isFlipped = true
            }
        }
    }

    private func nextWord() {
        selectedAnswer = nil
        isFlipped = false
        engine.advanceToNextWord()
        if let next = engine.currentWord {
            setupOptions(for: next)
        }
    }

    private func setupOptionsIfNeeded(for word: TopicWord) {
        if options.isEmpty {
            setupOptions(for: word)
        }
    }

    private func setupOptions(for word: TopicWord) {
        let distractors = ["Sự tự động hóa", "Đa dạng sinh học", "Hệ sinh thái"]
        var set = Set<String>()
        set.insert(word.vietnamese)
        for dist in distractors {
            if dist != word.vietnamese {
                set.insert(dist)
            }
        }
        options = Array(set).shuffled()
    }

    private func displayedOptions(for word: TopicWord) -> [String] {
        if options.isEmpty {
            let distractors = ["Sự tự động hóa", "Đa dạng sinh học", "Hệ sinh thái"]
            var set = Set<String>()
            set.insert(word.vietnamese)
            for dist in distractors {
                if dist != word.vietnamese {
                    set.insert(dist)
                }
            }
            return Array(set)
        }
        return options
    }

    private func optionBackground(for opt: String) -> Color {
        guard let sel = selectedAnswer, sel == opt else { return Color.vocabSurfaceCard }
        return isSuccess ? Color.vocabMint.opacity(0.15) : Color.vocabCoral.opacity(0.15)
    }

    private func optionForeground(for opt: String) -> Color {
        guard let sel = selectedAnswer, sel == opt else { return Color.vocabInk }
        return isSuccess ? Color.vocabMint : Color.vocabCoral
    }

    private func optionBorder(for opt: String) -> Color {
        guard let sel = selectedAnswer, sel == opt else { return Color.vocabHairline }
        return isSuccess ? Color.vocabMint : Color.vocabCoral
    }
}
