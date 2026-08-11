import SwiftUI

public struct QuickReflexDrillSheetView: View {
    @State private var viewModel: QuickReflexDrillViewModel
    public let onComplete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(
        targetWord: WordItem,
        allWords: [WordItem],
        onComplete: @escaping (Int) -> Void
    ) {
        self._viewModel = State(initialValue: QuickReflexDrillViewModel(targetWord: targetWord, allWords: allWords))
        self.onComplete = onComplete
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.vocabCanvas.ignoresSafeArea()

                if viewModel.isCompleted {
                    completionCardView
                } else {
                    drillContentBody
                }
            }
            .navigationTitle("Luyện Phản Xạ Nhanh")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.vocabMuted)
                    }
                }
            }
        }
    }

    private var drillContentBody: some View {
        VStack(spacing: 20) {
            // Step Progress Bar
            HStack(spacing: 6) {
                ForEach(0..<viewModel.steps.count, id: \.self) { idx in
                    Rectangle()
                        .fill(idx <= viewModel.currentStepIndex ? Color.vocabPeach : Color.vocabHairline)
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Target Word Header Badge
            HStack(spacing: 8) {
                Text(viewModel.targetWord.lemma)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                Text(viewModel.targetWord.pos)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.vocabMuted)
                Spacer()
                Text(viewModel.targetWord.phonetic)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(Color.vocabMuted)
            }
            .padding(14)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vocabHairline, lineWidth: 1))
            .padding(.horizontal)

            if viewModel.currentStepIndex < viewModel.steps.count {
                let currentStep = viewModel.steps[viewModel.currentStepIndex]
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bước \(currentStep.id)/3: \(currentStep.promptText)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.vocabInk)

                    switch currentStep.type {
                    case .pronunciation:
                        pronunciationStepView(step: currentStep)
                    case .fastMeaning:
                        optionsStepView(step: currentStep)
                    case .fillInBlank:
                        fillInBlankStepView(step: currentStep)
                    }
                }
                .padding()
                .background(Color.vocabSurfaceCard)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.vocabHairline, lineWidth: 1.5))
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    private func pronunciationStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 20) {
            Text("\"\(step.targetText)\"")
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundColor(Color.vocabInk)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: { viewModel.speakTargetSentence() }) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Nghe câu mẫu")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.vocabHeroAccent)
            }

            Button(action: { viewModel.handleMicTap() }) {
                ZStack {
                    Circle()
                        .fill(viewModel.isListening ? Color.red.opacity(0.15) : Color.vocabPeach.opacity(0.2))
                        .frame(width: 72, height: 72)
                    Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.isListening ? .red : Color.vocabInk)
                }
            }
            .buttonStyle(BentoCardButtonStyle())

            if !viewModel.recognizedText.isEmpty {
                Text("Đã nghe: \"\(viewModel.recognizedText)\"")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }
        }
    }

    private func optionsStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 10) {
            ForEach(step.options, id: \.self) { option in
                Button(action: { viewModel.submitAnswer(option) }) {
                    Text(option)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.vocabCanvas)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vocabHairline, lineWidth: 1))
                }
                .buttonStyle(BentoCardButtonStyle())
            }
        }
    }

    private func fillInBlankStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 14) {
            if let gapSentence = step.sentenceWithGap {
                Text("\"\(gapSentence)\"")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.vocabInk)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            ForEach(step.options, id: \.self) { option in
                Button(action: { viewModel.submitAnswer(option) }) {
                    Text(option)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.vocabCanvas)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vocabHairline, lineWidth: 1))
                }
                .buttonStyle(BentoCardButtonStyle())
            }
        }
    }

    private var completionCardView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.vocabMint.opacity(0.2))
                    .frame(width: 90, height: 90)
                Image(systemName: viewModel.isCorrect ? "sparkles" : "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color.vocabMint)
            }

            Text(viewModel.isCorrect ? "Xuất sắc! Đã làm chủ phản xạ" : "Đã hoàn thành lượt luyện tập!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.vocabInk)

            if let result = viewModel.srsResult {
                HStack(spacing: 4) {
                    Text("Độ thuộc SRS mới:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabMuted)
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= result.nextMastery ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(star <= result.nextMastery ? Color.vocabMint : Color.vocabMuted.opacity(0.3))
                    }
                }
            }

            Text("Thời gian phản xạ: \(viewModel.elapsedTimeMs / 3) ms / câu")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.vocabMuted)

            Spacer()

            Button(action: {
                let updatedLevel = viewModel.srsResult?.nextMastery ?? viewModel.targetWord.masteryLevel
                onComplete(updatedLevel)
                dismiss()
            }) {
                Text("Hoàn tất")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.vocabCanvas)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.vocabInk)
                    .cornerRadius(16)
            }
            .buttonStyle(BentoCardButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}
