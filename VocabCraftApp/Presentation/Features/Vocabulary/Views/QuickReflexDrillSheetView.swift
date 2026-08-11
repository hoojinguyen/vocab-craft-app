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

                    // Step Evaluation Feedback Banner
                    if viewModel.isStepEvaluated {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.isStepCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(viewModel.isStepCorrect ? Color.vocabMint : .red)
                            
                            Text(viewModel.stepFeedbackMessage)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.vocabInk)

                            Spacer()

                            Button(action: { viewModel.nextStep() }) {
                                HStack(spacing: 4) {
                                    Text("Tiếp tục")
                                        .font(.system(size: 13, weight: .bold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.isStepCorrect ? Color.vocabMint : Color.vocabInk)
                                .foregroundColor(Color.vocabCanvas)
                                .cornerRadius(10)
                            }
                        }
                        .padding(12)
                        .background(viewModel.isStepCorrect ? Color.vocabMint.opacity(0.15) : Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        VStack(spacing: 16) {
            Text("\"\(step.targetText)\"")
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundColor(Color.vocabInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
                        .fill(viewModel.isMicActive ? Color.red.opacity(0.2) : Color.vocabPeach.opacity(0.25))
                        .frame(width: 72, height: 72)
                    Image(systemName: viewModel.isMicActive ? "mic.fill" : "mic")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.isMicActive ? .red : Color.vocabInk)
                }
            }
            .buttonStyle(BentoCardButtonStyle())

            if viewModel.isMicActive {
                Text("Đang thu âm... Đọc to câu mẫu")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            }

            if !viewModel.recordedSpokenText.isEmpty {
                Text("Đã nghe: \"\(viewModel.recordedSpokenText)\"")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.vocabInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            if let errorMsg = viewModel.errorMessage {
                Text(errorMsg)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private func optionsStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 10) {
            ForEach(step.options, id: \.self) { option in
                let isSelected = viewModel.selectedOption == option
                let isTarget = option == step.targetText
                let isEvaluated = viewModel.isStepEvaluated

                Button(action: {
                    if !isEvaluated {
                        viewModel.submitAnswer(option)
                    }
                }) {
                    HStack {
                        Text(option)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.vocabInk)

                        Spacer()

                        if isEvaluated {
                            if isTarget {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.vocabMint)
                            } else if isSelected {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(
                        isEvaluated
                            ? (isTarget ? Color.vocabMint.opacity(0.2) : (isSelected ? Color.red.opacity(0.12) : Color.vocabCanvas))
                            : Color.vocabCanvas
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isEvaluated
                                    ? (isTarget ? Color.vocabMint : (isSelected ? Color.red : Color.vocabHairline))
                                    : Color.vocabHairline,
                                lineWidth: isEvaluated && (isTarget || isSelected) ? 2 : 1
                            )
                    )
                }
                .buttonStyle(BentoCardButtonStyle())
                .disabled(isEvaluated)
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
                let isSelected = viewModel.selectedOption == option
                let isTarget = option == step.targetText
                let isEvaluated = viewModel.isStepEvaluated

                Button(action: {
                    if !isEvaluated {
                        viewModel.submitAnswer(option)
                    }
                }) {
                    HStack {
                        Text(option)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.vocabInk)

                        Spacer()

                        if isEvaluated {
                            if isTarget {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.vocabMint)
                            } else if isSelected {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(
                        isEvaluated
                            ? (isTarget ? Color.vocabMint.opacity(0.2) : (isSelected ? Color.red.opacity(0.12) : Color.vocabCanvas))
                            : Color.vocabCanvas
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isEvaluated
                                    ? (isTarget ? Color.vocabMint : (isSelected ? Color.red : Color.vocabHairline))
                                    : Color.vocabHairline,
                                lineWidth: isEvaluated && (isTarget || isSelected) ? 2 : 1
                            )
                    )
                }
                .buttonStyle(BentoCardButtonStyle())
                .disabled(isEvaluated)
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
