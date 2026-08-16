import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Display decisions shared by the productive-recall stage card and its focused tests.
public struct QuickReflexDrillPhaseConfiguration: Equatable, Sendable {
    public let phase: QuickReflexPhase
    public let inputMode: QuickReflexInputMode

    public init(phase: QuickReflexPhase, inputMode: QuickReflexInputMode) {
        self.phase = phase
        self.inputMode = inputMode
    }

    public var hidesLemma: Bool { phase == .retrieve }
    public var showsTypingFallback: Bool { inputMode == .typing }
    public var stageNumber: Int {
        switch phase {
        case .retrieve:
            1
        case .useInSentence, .result:
            2
        }
    }
}

public enum QuickReflexTimeDelta: Equatable, Sendable {
    case saved(milliseconds: Int)
    case slower(milliseconds: Int)
    case unchanged
}

public struct QuickReflexTimeComparison: Equatable, Sendable {
    public let retrieveDelta: QuickReflexTimeDelta
    public let useDelta: QuickReflexTimeDelta

    public init(currentRetrieveTimeMs: Int, previousRetrieveTimeMs: Int, currentUseTimeMs: Int, previousUseTimeMs: Int) {
        retrieveDelta = Self.delta(current: currentRetrieveTimeMs, previous: previousRetrieveTimeMs)
        useDelta = Self.delta(current: currentUseTimeMs, previous: previousUseTimeMs)
    }

    private static func delta(current: Int, previous: Int) -> QuickReflexTimeDelta {
        if current < previous {
            return .saved(milliseconds: previous - current)
        }
        if current > previous {
            return .slower(milliseconds: current - previous)
        }
        return .unchanged
    }
}

public struct QuickReflexDrillSheetView: View {
    @State private var viewModel: QuickReflexDrillViewModel
    @State private var typedAnswer = ""
    @State private var latestSuccessfulAttempt: QuickReflexAttempt?
    @State private var isFinishing = false
    @State private var finishTask: Task<Void, Never>?

    public let onComplete: (Int) -> Void
    private let attemptRepository: QuickReflexAttemptRepositoryProtocol?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    public init(
        targetWord: WordItem,
        allWords: [WordItem],
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil,
        speechAssessmentService: SpeechAssessmentProtocol? = nil,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol? = nil,
        attemptRepository: QuickReflexAttemptRepositoryProtocol? = nil,
        onComplete: @escaping (Int) -> Void
    ) {
        self._viewModel = State(initialValue: QuickReflexDrillViewModel(
            targetWord: targetWord,
            allWords: allWords,
            ttsService: ttsService,
            sttService: sttService,
            speechAssessmentService: speechAssessmentService,
            evaluateSRSUseCase: evaluateSRSUseCase,
            attemptRepository: attemptRepository
        ))
        self.attemptRepository = attemptRepository
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            Color.vocabCanvas.ignoresSafeArea()

            if viewModel.state.phase == .result {
                resultCard
            } else {
                stageContent
            }
        }
        .task { await loadLatestSuccessfulAttempt() }
        .interactiveDismissDisabled(isFinishing || viewModel.state.isFinishing)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.resume()
            } else {
                viewModel.pause()
            }
        }
        .onChange(of: viewModel.state.phase) { _, phase in
            guard phase != .result else { return }
            announceForAccessibility(AppStrings.Reflex.quickStageProgressValue(
                stage: QuickReflexDrillPhaseConfiguration(phase: phase, inputMode: viewModel.state.inputMode).stageNumber,
                total: 2
            ))
        }
        .onChange(of: viewModel.state.visibleHintLevel) { oldLevel, newLevel in
            guard newLevel > oldLevel else { return }
            announceForAccessibility(AppStrings.Reflex.quickHintAvailableText)
        }
        .onChange(of: viewModel.state.showsSentenceFrame) { _, isVisible in
            guard isVisible else { return }
            announceForAccessibility(AppStrings.Reflex.quickHintAvailableText)
        }
        .onDisappear {
            if !isFinishing, !viewModel.state.isFinishing, !viewModel.state.isCompleted {
                finishTask?.cancel()
                finishTask = nil
                viewModel.cancel()
            }
        }
    }

    private var configuration: QuickReflexDrillPhaseConfiguration {
        QuickReflexDrillPhaseConfiguration(phase: viewModel.state.phase, inputMode: viewModel.state.inputMode)
    }

    private var currentPrompt: QuickReflexStagePrompt {
        viewModel.state.phase == .useInSentence ? viewModel.prompts.use : viewModel.prompts.retrieve
    }

    private var stageContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                progressIndicator
                phaseCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var header: some View {
        HStack {
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.vocabInk)
                    .frame(width: 44, height: 44)
                    .background(Color.vocabSurfaceCard)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.vocabHairline, lineWidth: 1))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 6, x: 0, y: 3)
            }
            .accessibilityLabel(AppStrings.Common.close)

            Spacer()

            Text(AppStrings.Reflex.quickPracticeTitle)
                .font(.headline)
                .foregroundStyle(Color.vocabInk)

            Spacer()

            Text("\(configuration.stageNumber)/2")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vocabHeroAccent)
                .padding(.horizontal, 10)
                .frame(minHeight: 28)
                .background(Color.vocabHeroAccent.opacity(0.12))
                .clipShape(Capsule())
                .accessibilityLabel(AppStrings.Reflex.quickStageProgressValue(stage: configuration.stageNumber, total: 2))
        }
    }

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...2, id: \.self) { stage in
                Capsule()
                    .fill(stage <= configuration.stageNumber ? Color.vocabHeroAccent : Color.vocabHairline.opacity(0.6))
                    .frame(height: 5)
            }
        }
        .accessibilityHidden(true)
    }

    private var phaseCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            phaseHeader

            Text(currentPrompt.promptText)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.vocabInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if !configuration.hidesLemma {
                wordIdentity
            }

            if viewModel.state.phase == .useInSentence,
               !viewModel.targetWord.exampleSentenceEn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: viewModel.speakExampleSentence) {
                    Label(AppStrings.Reflex.quickListenExample, systemImage: "speaker.wave.2.fill")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Color.vocabHeroAccent)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }

            hintSection

            if viewModel.state.showsSentenceFrame, let sentenceFrame = currentPrompt.sentenceFrame {
                Label(sentenceFrame, systemImage: "text.quote")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.vocabHeroAccent)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.vocabHeroAccent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VocabSpeechVisualizerView(
                isListening: viewModel.isListening,
                recognizedText: viewModel.recognizedText,
                placeholderText: String(localized: "reflex.quickTranscriptPlaceholder"),
                evaluationResult: viewModel.speechEvaluationResult
            )
            .accessibilityLabel(AppStrings.Reflex.quickTranscriptFeedback)

            VocabMicControlHubView(
                isListening: viewModel.isListening,
                idleSubtitleText: String(localized: "reflex.quickMicIdle"),
                listeningSubtitleText: String(localized: "reflex.quickMicListening"),
                onTapMic: viewModel.handleMicTap
            )

            typedEntry

            if let errorMessage = viewModel.state.errorMessage {
                Text(errorMessage)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.vocabCoral)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 12) {
                Button(action: viewModel.revealAnswer) {
                    Text(AppStrings.Reflex.quickReveal)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(SecondaryDrillButtonStyle())

                Button(action: viewModel.skip) {
                    Text(AppStrings.Reflex.quickSkip)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(SecondaryDrillButtonStyle())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.vocabHairline, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    private var phaseHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(viewModel.state.phase == .retrieve ? AppStrings.Reflex.quickRetrieveTitle : AppStrings.Reflex.quickUseTitle)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Color.vocabHeroAccent)

            Spacer()

            Text(configuration.showsTypingFallback ? AppStrings.Reflex.quickTypingMode : AppStrings.Reflex.quickVoiceMode)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vocabMuted)
        }
        .accessibilityElement(children: .combine)
    }

    private var wordIdentity: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(viewModel.targetWord.lemma)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.vocabInk)
            Text(viewModel.targetWord.pos)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vocabMuted)
            Spacer()
            Text(viewModel.targetWord.phonetic)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(Color.vocabMuted)
        }
        .padding(14)
        .background(Color.vocabCanvas)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var hintSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(AppStrings.Reflex.quickHints)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vocabMuted)

                Spacer()

                if viewModel.state.visibleHintLevel < currentPrompt.hints.count {
                    Button(action: viewModel.advanceHint) {
                        Text(AppStrings.Reflex.quickShowHint)
                            .font(.caption.weight(.semibold))
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.vocabHeroAccent)
                }
            }

            ForEach(Array(currentPrompt.hints.prefix(viewModel.state.visibleHintLevel).enumerated()), id: \.offset) { _, hint in
                Label(hint, systemImage: "lightbulb.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.vocabHeroAccent)
                    .accessibilityLabel("\(String(localized: "reflex.quickHint")): \(hint)")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var typedEntry: some View {
        HStack(spacing: 10) {
            TextField(AppStrings.Reflex.quickTypeAnswer, text: $typedAnswer)
#if os(iOS)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
#endif
                .submitLabel(.done)
                .onSubmit(submitTypedAnswer)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(Color.vocabCanvas)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.vocabHairline, lineWidth: 1))

            Button(action: submitTypedAnswer) {
                Text(AppStrings.Reflex.quickSubmit)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 76, minHeight: 48)
                    .background(Color.vocabHeroAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .accessibilityLabel(AppStrings.Reflex.quickTypingFallback)
    }

    private var resultCard: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                VStack(alignment: .leading, spacing: 20) {
                    Text(AppStrings.Reflex.quickResultsTitle)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.vocabInk)
                        .accessibilityAddTraits(.isHeader)

                    resultRow(title: AppStrings.Reflex.quickRetrieveTitle, succeeded: viewModel.state.retrieveSucceeded, timeMs: viewModel.state.retrieveTimeMs)
                    resultRow(title: AppStrings.Reflex.quickUseTitle, succeeded: viewModel.state.useSucceeded, timeMs: viewModel.state.useTimeMs)

                    if let revealedTargetExpression = viewModel.state.revealedTargetExpression {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppStrings.Reflex.quickRevealedAnswer)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.vocabMuted)
                            Text(revealedTargetExpression)
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.vocabHeroAccent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.vocabHeroAccent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if let latestSuccessfulAttempt {
                        previousAttemptComparison(latestSuccessfulAttempt)
                    }

                    Text(AppStrings.Reflex.quickConfidenceQuestion)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.vocabInk)

                    VStack(spacing: 12) {
                        Button(action: { finish(confidence: .comfortable) }) {
                            Text(AppStrings.Reflex.quickComfortable)
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(PrimaryDrillButtonStyle())

                        Button(action: { finish(confidence: .uncertain) }) {
                            Text(AppStrings.Reflex.quickUncertain)
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(SecondaryDrillButtonStyle())
                    }
                    .disabled(isFinishing)

                    if let errorMessage = viewModel.state.errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.vocabCoral)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    if isFinishing {
                        ProgressView(AppStrings.Reflex.quickSaving)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
                .background(Color.vocabSurfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.vocabHairline, lineWidth: 1))
            }
            .padding(20)
        }
    }

    private func resultRow(title: LocalizedStringKey, succeeded: Bool, timeMs: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(succeeded ? Color.vocabMint : Color.vocabCoral)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vocabInk)
                Text(succeeded ? AppStrings.Reflex.quickSucceeded : AppStrings.Reflex.quickNeedsPractice)
                    .font(.caption)
                    .foregroundStyle(Color.vocabMuted)
            }
            Spacer()
            Text(formattedTime(timeMs))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.vocabMuted)
        }
        .padding(14)
        .background(Color.vocabCanvas)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func previousAttemptComparison(_ attempt: QuickReflexAttempt) -> some View {
        let comparison = QuickReflexTimeComparison(
            currentRetrieveTimeMs: viewModel.state.retrieveTimeMs,
            previousRetrieveTimeMs: attempt.retrieveTimeMs,
            currentUseTimeMs: viewModel.state.useTimeMs,
            previousUseTimeMs: attempt.useTimeMs
        )
        return VStack(alignment: .leading, spacing: 8) {
            Text(AppStrings.Reflex.quickPreviousAttempt)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vocabMuted)
            timeComparisonRow(
                title: AppStrings.Reflex.quickRetrieveTitle,
                current: viewModel.state.retrieveTimeMs,
                previous: attempt.retrieveTimeMs,
                delta: comparison.retrieveDelta
            )
            timeComparisonRow(
                title: AppStrings.Reflex.quickUseTitle,
                current: viewModel.state.useTimeMs,
                previous: attempt.useTimeMs,
                delta: comparison.useDelta
            )
        }
        .font(.subheadline)
        .foregroundStyle(Color.vocabInk)
        .padding(14)
        .background(Color.vocabHeroAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func timeComparisonRow(title: LocalizedStringKey, current: Int, previous: Int, delta: QuickReflexTimeDelta) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(AppStrings.Reflex.quickCurrentAttempt)
            Text(formattedTime(current)).monospacedDigit()
            Text(AppStrings.Reflex.quickPreviousAttempt)
            Text(formattedTime(previous)).monospacedDigit()
            Text(timeDeltaLabel(delta))
                .foregroundStyle(deltaColor(delta))
        }
        .font(.caption)
    }

    private func timeDeltaLabel(_ delta: QuickReflexTimeDelta) -> String {
        switch delta {
        case let .saved(milliseconds):
            AppStrings.Reflex.quickTimeSaved(formattedTime(milliseconds))
        case let .slower(milliseconds):
            AppStrings.Reflex.quickTimeSlower(formattedTime(milliseconds))
        case .unchanged:
            String(localized: "reflex.quickTimeUnchanged")
        }
    }

    private func deltaColor(_ delta: QuickReflexTimeDelta) -> Color {
        switch delta {
        case .saved:
            .vocabMint
        case .slower:
            .vocabCoral
        case .unchanged:
            .vocabMuted
        }
    }

    private func submitTypedAnswer() {
        let answer = typedAnswer
        typedAnswer = ""
        viewModel.submitTypedAnswer(answer)
    }

    private func close() {
        guard !isFinishing, !viewModel.state.isFinishing else { return }
        viewModel.cancel()
        dismiss()
    }

    private func finish(confidence: QuickReflexConfidence) {
        guard !isFinishing else { return }
        isFinishing = true

        finishTask = Task {
            defer {
                isFinishing = false
                finishTask = nil
            }
            do {
                try await viewModel.finish(confidence: confidence)
                guard !Task.isCancelled,
                      !viewModel.state.isCancelled,
                      viewModel.state.isCompleted else { return }
                onComplete(viewModel.state.srsResult?.nextMastery ?? viewModel.targetWord.masteryLevel)
                dismiss()
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, !viewModel.state.isCancelled else { return }
                viewModel.state.errorMessage = error.localizedDescription
            }
        }
    }

    private func loadLatestSuccessfulAttempt() async {
        guard let attemptRepository else { return }
        latestSuccessfulAttempt = try? await attemptRepository.mostRecentSuccessfulAttempt(for: viewModel.targetWord.id)
    }

    private func formattedTime(_ milliseconds: Int) -> String {
        String(format: "%.1fs", Double(milliseconds) / 1_000)
    }

    private func announceForAccessibility(_ message: String) {
#if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
#endif
    }
}

private struct PrimaryDrillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .background(Color.vocabHeroAccent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.86 : 1)
    }
}

private struct SecondaryDrillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.vocabHeroAccent)
            .background(Color.vocabHeroAccent.opacity(configuration.isPressed ? 0.18 : 0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.vocabHeroAccent.opacity(0.25), lineWidth: 1))
    }
}
