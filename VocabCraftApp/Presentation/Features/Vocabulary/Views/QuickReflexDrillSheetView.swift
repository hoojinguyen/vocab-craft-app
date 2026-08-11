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
        VStack(spacing: 16) {
            // Step Progress Bar
            HStack(spacing: 8) {
                ForEach(0..<viewModel.steps.count, id: \.self) { idx in
                    Capsule()
                        .fill(idx <= viewModel.currentStepIndex ? Color.vocabHeroAccent : Color.vocabHairline.opacity(0.6))
                        .frame(height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.currentStepIndex)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

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
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(Color.vocabMuted)
            }
            .padding(16)
            .background(Color.vocabSurfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.vocabHairline, lineWidth: 1))
            .padding(.horizontal)

            Spacer(minLength: 0)

            if viewModel.currentStepIndex < viewModel.steps.count {
                let currentStep = viewModel.steps[viewModel.currentStepIndex]
                
                VStack(alignment: .leading, spacing: 18) {
                    Text(currentStep.promptText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                        .fixedSize(horizontal: false, vertical: true)

                    switch currentStep.type {
                    case .pronunciation:
                        pronunciationStepView(step: currentStep)
                    case .fastMeaning:
                        optionsStepView(step: currentStep)
                    case .fillInBlank:
                        fillInBlankStepView(step: currentStep)
                    }
                }
                .padding(20)
                .background(Color.vocabSurfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.vocabHairline, lineWidth: 1))
                .padding(.horizontal)
            }

            Spacer(minLength: 0)
        }
    }

    private func pronunciationStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 16) {
            Text("\"\(step.targetText)\"")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundColor(Color.vocabInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Button(action: { viewModel.speakTargetSentence() }) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Nghe câu mẫu")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.vocabHeroAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.vocabHeroAccent.opacity(0.1))
                .clipShape(Capsule())
            }

            // Hold-to-Talk Mic Button with Touch Gesture & Pulsing Ring
            VStack(spacing: 10) {
                ZStack {
                    if viewModel.isMicActive {
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 6)
                            .frame(width: 96, height: 96)
                            .scaleEffect(viewModel.isMicActive ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isMicActive)
                    }

                    Circle()
                        .fill(
                            viewModel.isMicActive 
                                ? Color.red 
                                : (viewModel.isStepEvaluated ? (viewModel.isStepCorrect ? Color.vocabMint : Color.red) : Color.vocabHeroAccent)
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: (viewModel.isMicActive ? Color.red : Color.vocabHeroAccent).opacity(0.3), radius: 8, y: 4)

                    Image(systemName: viewModel.isMicActive ? "mic.fill" : (viewModel.isStepEvaluated ? (viewModel.isStepCorrect ? "checkmark" : "xmark") : "mic.fill"))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isMicActive)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !viewModel.isMicActive && !viewModel.isStepEvaluated {
                                viewModel.startRecording()
                            }
                        }
                        .onEnded { _ in
                            if viewModel.isMicActive {
                                viewModel.stopRecordingAndEvaluate()
                            }
                        }
                )

                Text(viewModel.isMicActive ? "Đang thu âm... Nhả ra để kiểm tra" : "Nhấn giữ để nói • Nhả để kiểm tra")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(viewModel.isMicActive ? .red : Color.vocabMuted)
            }
            .padding(.vertical, 8)

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
        VStack(spacing: 12) {
            ForEach(step.options, id: \.self) { option in
                let isSelected = viewModel.selectedOption == option
                let isTarget = option == step.targetText
                let isEvaluated = viewModel.isStepEvaluated

                Button(action: {
                    if !isEvaluated {
                        viewModel.submitAnswer(option)
                    }
                }) {
                    HStack(spacing: 12) {
                        Text(option)
                            .font(.system(size: 15, weight: isSelected || (isEvaluated && isTarget) ? .bold : .medium))
                            .foregroundColor(
                                isEvaluated && isTarget 
                                    ? Color(uiColor: .systemGreen) 
                                    : (isEvaluated && isSelected ? Color.red : Color.vocabInk)
                            )
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if isEvaluated {
                            if isTarget {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.vocabMint)
                            } else if isSelected {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 52)
                    .background(
                        isEvaluated
                            ? (isTarget ? Color.vocabMint.opacity(0.12) : (isSelected ? Color.red.opacity(0.12) : Color.vocabCanvas))
                            : Color.vocabCanvas
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isEvaluated
                                    ? (isTarget ? Color.vocabMint : (isSelected ? Color.red : Color.clear))
                                    : Color.vocabHairline,
                                lineWidth: isEvaluated && (isTarget || isSelected) ? 1.5 : 1
                            )
                    )
                }
                .buttonStyle(BentoCardButtonStyle())
                .disabled(isEvaluated)
                .sensoryFeedback(isTarget ? .success : .error, trigger: isEvaluated)
            }
        }
    }

    private func fillInBlankStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 16) {
            if let gapSentence = step.sentenceWithGap {
                Text("\"\(gapSentence)\"")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundColor(Color.vocabInk)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
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
                    HStack(spacing: 12) {
                        Text(option)
                            .font(.system(size: 15, weight: isSelected || (isEvaluated && isTarget) ? .bold : .medium))
                            .foregroundColor(
                                isEvaluated && isTarget 
                                    ? Color(uiColor: .systemGreen) 
                                    : (isEvaluated && isSelected ? Color.red : Color.vocabInk)
                            )

                        Spacer()

                        if isEvaluated {
                            if isTarget {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.vocabMint)
                            } else if isSelected {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(
                        isEvaluated
                            ? (isTarget ? Color.vocabMint.opacity(0.12) : (isSelected ? Color.red.opacity(0.12) : Color.vocabCanvas))
                            : Color.vocabCanvas
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isEvaluated
                                    ? (isTarget ? Color.vocabMint : (isSelected ? Color.red : Color.clear))
                                    : Color.vocabHairline,
                                lineWidth: isEvaluated && (isTarget || isSelected) ? 1.5 : 1
                            )
                    )
                }
                .buttonStyle(BentoCardButtonStyle())
                .disabled(isEvaluated)
                .sensoryFeedback(isTarget ? .success : .error, trigger: isEvaluated)
            }
        }
    }

    private var formattedReactionTime: String {
        let avgMs = viewModel.elapsedTimeMs / max(1, viewModel.steps.count)
        if avgMs >= 1000 {
            let sec = Double(avgMs) / 1000.0
            return String(format: "%.2f s / câu", sec)
        } else {
            return "\(avgMs) ms / câu"
        }
    }

    private var completionCardView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.vocabMint.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: viewModel.isCorrect ? "sparkles" : "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(Color.vocabMint)
                    .symbolEffect(.bounce, value: viewModel.isCompleted)
            }

            VStack(spacing: 8) {
                Text(viewModel.isCorrect ? "Xuất sắc! Đã làm chủ phản xạ" : "Đã hoàn thành lượt luyện tập!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                    .multilineTextAlignment(.center)

                Text("Thời gian phản xạ: \(formattedReactionTime)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
                    .monospacedDigit()
            }

            if let result = viewModel.srsResult {
                HStack(spacing: 6) {
                    Text("Mức độ thuộc SRS:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabMuted)
                    
                    let displayStars = max(1, result.nextMastery)
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= displayStars ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(star <= displayStars ? Color.vocabMint : Color.vocabMuted.opacity(0.3))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.vocabSurfaceCard)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            }

            Spacer()

            Button(action: {
                let updatedLevel = viewModel.srsResult?.nextMastery ?? viewModel.targetWord.masteryLevel
                onComplete(updatedLevel)
                dismiss()
            }) {
                Text("Hoàn tất")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.vocabCanvas)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.vocabInk)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(BentoCardButtonStyle())
            .sensoryFeedback(.success, trigger: viewModel.isCompleted)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}
