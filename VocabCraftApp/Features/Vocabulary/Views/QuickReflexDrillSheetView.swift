import SwiftUI

public struct QuickReflexDrillSheetView: View {
    @State private var viewModel: QuickReflexDrillViewModel
    public let onComplete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public init(
        targetWord: WordItem,
        allWords: [WordItem],
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol? = nil,
        onComplete: @escaping (Int) -> Void
    ) {
        self._viewModel = State(initialValue: QuickReflexDrillViewModel(
            targetWord: targetWord,
            allWords: allWords,
            ttsService: ttsService,
            sttService: sttService,
            evaluateSRSUseCase: evaluateSRSUseCase
        ))
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            Color.vocabCanvas.ignoresSafeArea()

            if viewModel.state.isCompleted {
                completionCardView
            } else {
                drillContentBody
            }
        }
    }

    private var drillContentBody: some View {
        VStack(spacing: 16) {
            // Header Navigation Bar (Consistent with SubTopicStudySessionView & ReflexDrillView)
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                        .frame(width: 36, height: 36)
                        .background(Color.vocabSurfaceCard)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.vocabHairline, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 6, x: 0, y: 3)
                }
                .accessibilityLabel(AppStrings.Common.close)

                Spacer()

                Text(AppStrings.Reflex.quickPracticeTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.vocabInk)

                Spacer()

                Text("\(min(viewModel.state.currentStepIndex + 1, viewModel.state.steps.count)) / \(viewModel.state.steps.count)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.vocabHeroAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.vocabHeroAccent.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Step Progress Bar
            HStack(spacing: 8) {
                ForEach(0..<viewModel.state.steps.count, id: \.self) { idx in
                    Capsule()
                        .fill(idx <= viewModel.state.currentStepIndex ? Color.vocabHeroAccent : Color.vocabHairline.opacity(0.6))
                        .frame(height: 5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.state.currentStepIndex)
                }
            }
            .padding(.horizontal, 20)

            // Target Word Header Badge
            targetWordHeaderBadge

            Spacer(minLength: 0)

            // Current Active Step Content
            if viewModel.state.currentStepIndex < viewModel.state.steps.count {
                let currentStep = viewModel.state.steps[viewModel.state.currentStepIndex]

                VStack(alignment: .leading, spacing: 18) {
                    // Per-step Countdown Bar
                    CountdownBarView(
                        remainingSeconds: viewModel.state.stepRemainingSeconds,
                        maxSeconds: viewModel.state.stepMaxSeconds
                    )

                    HStack(alignment: .top) {
                        Text(currentStep.promptText)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        if viewModel.state.isSpeedBonus {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 11))
                                Text(AppStrings.Reflex.speedBonus)
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

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
                .frame(maxWidth: .infinity)
                .background(Color.vocabSurfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.vocabHairline, lineWidth: 1))
                .padding(.horizontal, 20)
            }

            Spacer(minLength: 0)
        }
    }

    private var displayLemma: String {
        if viewModel.state.currentStepIndex < viewModel.state.steps.count {
            let currentStep = viewModel.state.steps[viewModel.state.currentStepIndex]
            if currentStep.type == .fillInBlank {
                return String(repeating: "•", count: max(5, viewModel.targetWord.lemma.count))
            }
        }
        return viewModel.targetWord.lemma
    }

    private var targetWordHeaderBadge: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(displayLemma)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(Color.vocabInk)
                .animation(.easeInOut(duration: 0.2), value: displayLemma)

            Text(viewModel.targetWord.pos)
                .font(.system(.caption, weight: .semibold))
                .foregroundColor(Color.vocabMuted)

            Spacer()

            Text(viewModel.targetWord.phonetic)
                .font(.system(.subheadline, design: .serif))
                .foregroundColor(Color.vocabMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.vocabHairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    private func pronunciationStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 20) {
            Text("\"\(step.targetText)\"")
                .font(.system(.title3, design: .serif, weight: .medium))
                .foregroundColor(Color.vocabInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)

            Button(action: { viewModel.speakTargetSentence() }) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14))
                    Text(AppStrings.Reflex.listenExample)
                        .font(.system(.subheadline, weight: .semibold))
                }
                .foregroundColor(Color.vocabHeroAccent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.vocabHeroAccent.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(BentoPressButtonStyle())

            // Speech Visualizer Display
            VocabSpeechVisualizerView(
                isListening: viewModel.isListening,
                recognizedText: viewModel.recognizedText,
                placeholderText: String(localized: "reflex.micPlaceholder")
            )

            // Interactive Tap-to-Talk Mic Control Hub
            if !viewModel.state.isStepEvaluated {
                VocabMicControlHubView(
                    isListening: viewModel.isListening,
                    idleSubtitleText: String(localized: "reflex.micIdle"),
                    listeningSubtitleText: String(localized: "reflex.micListening"),
                    onTapMic: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            viewModel.handleMicTap()
                        }
                    }
                )
            }

            if let errorMsg = viewModel.state.errorMessage {
                Text(errorMsg)
                    .font(.system(.footnote, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private func optionsStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 12) {
            ForEach(step.options, id: \.self) { option in
                let isSelected = viewModel.state.selectedOption == option
                let isTarget = option == step.targetText
                let isEvaluated = viewModel.state.isStepEvaluated

                OptionRowView(
                    optionText: option,
                    isSelected: isSelected,
                    isTarget: isTarget,
                    isEvaluated: isEvaluated,
                    action: {
                        if !isEvaluated {
                            viewModel.submitAnswer(option)
                        }
                    }
                )
                .sensoryFeedback(isTarget ? .success : .error, trigger: isEvaluated)
            }
        }
    }

    private func fillInBlankStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 16) {
            if let gapSentence = step.sentenceWithGap {
                Text("\"\(gapSentence)\"")
                    .font(.system(.title3, design: .serif, weight: .medium))
                    .foregroundColor(Color.vocabInk)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
            }

            ForEach(step.options, id: \.self) { option in
                let isSelected = viewModel.state.selectedOption == option
                let isTarget = option == step.targetText
                let isEvaluated = viewModel.state.isStepEvaluated

                OptionRowView(
                    optionText: option,
                    isSelected: isSelected,
                    isTarget: isTarget,
                    isEvaluated: isEvaluated,
                    action: {
                        if !isEvaluated {
                            viewModel.submitAnswer(option)
                        }
                    }
                )
                .sensoryFeedback(isTarget ? .success : .error, trigger: isEvaluated)
            }
        }
    }

    private var formattedReactionTime: String {
        let avgMs = viewModel.state.elapsedTimeMs / max(1, viewModel.state.steps.count)
        if avgMs >= 1000 {
            let sec = Double(avgMs) / 1000.0
            let format = String(localized: "reflex.secondsPerQuestionFormat")
            return String(format: format, sec)
        } else {
            let format = String(localized: "reflex.msPerQuestionFormat")
            return String(format: format, avgMs)
        }
    }

    private var completionCardView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.vocabMint.opacity(0.15))
                    .frame(width: 104, height: 104)
                Image(systemName: viewModel.state.isCorrect ? "sparkles" : "checkmark.circle.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundColor(Color.vocabMint)
                    .symbolEffect(.bounce, value: viewModel.state.isCompleted)
            }

            VStack(spacing: 8) {
                Text(viewModel.state.isCorrect ? AppStrings.Reflex.masteredFeedback : AppStrings.Reflex.completedFeedback)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                    .multilineTextAlignment(.center)

                (Text(AppStrings.Reflex.reactionTimeLabel) + Text(" \(formattedReactionTime)"))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
                    .monospacedDigit()

                if viewModel.state.totalSpeedBonusCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text(AppStrings.Reflex.speedBonusCountLabel(count: viewModel.state.totalSpeedBonusCount, total: viewModel.state.steps.count))
                    }
                    .font(.system(.caption, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
                }
            }

            if let result = viewModel.state.srsResult {
                HStack(spacing: 8) {
                    Text(AppStrings.Reflex.srsLevelHeader)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundColor(Color.vocabMuted)

                    let displayStars = max(1, result.nextMastery)
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= displayStars ? "star.fill" : "star")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(star <= displayStars ? Color.orange : Color.vocabMuted.opacity(0.3))
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.vocabSurfaceCard)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                .overlay(Capsule().stroke(Color.vocabHairline, lineWidth: 1))
            }

            Spacer()

            Button(action: {
                let updatedLevel = viewModel.state.srsResult?.nextMastery ?? viewModel.targetWord.masteryLevel
                onComplete(updatedLevel)
                dismiss()
            }) {
                Text(AppStrings.Common.done)
                    .font(.system(.headline, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.vocabHeroAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.vocabHeroAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(BentoPressButtonStyle())
            .sensoryFeedback(.success, trigger: viewModel.state.isCompleted)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Reusable Supporting Views

private struct OptionRowView: View {
    let optionText: String
    let isSelected: Bool
    let isTarget: Bool
    let isEvaluated: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(optionText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                if isEvaluated {
                    if isTarget {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.vocabMint)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.vocabCoral)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color.vocabHairline)
                    }
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color.vocabHairline)
                }
            }
            .padding(14)
            .frame(minHeight: 52)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(BentoPressButtonStyle())
        .disabled(isEvaluated)
    }

    private var backgroundColor: Color {
        if isEvaluated {
            if isTarget {
                return Color.vocabMint.opacity(0.15)
            } else if isSelected {
                return Color.vocabCoral.opacity(0.15)
            }
        }
        return Color.vocabSurfaceCard
    }

    private var textColor: Color {
        if isEvaluated {
            if isTarget {
                return Color.vocabMint
            } else if isSelected {
                return Color.vocabCoral
            }
        }
        return Color.vocabInk
    }

    private var borderColor: Color {
        if isEvaluated {
            if isTarget {
                return Color.vocabMint
            } else if isSelected {
                return Color.vocabCoral
            }
        }
        return Color.vocabHairline
    }
}

private struct BentoPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct CountdownBarView: View {
    let remainingSeconds: Double
    let maxSeconds: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.vocabHairline.opacity(0.4))
                    .frame(height: 4)

                Capsule()
                    .fill(remainingSeconds <= 2.0 ? Color.orange : Color.vocabHeroAccent)
                    .frame(
                        width: max(0, geo.size.width * CGFloat(remainingSeconds / max(maxSeconds, 1))),
                        height: 4
                    )
                    .animation(.linear(duration: 0.1), value: remainingSeconds)
            }
        }
        .frame(height: 4)
    }
}
