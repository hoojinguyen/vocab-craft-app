import SwiftUI

/// Result screen for Quick Reflex Drill showing breakdown of stages, pronunciation score, and confidence rating.
public struct QuickReflexResultCardView: View {
    public let viewModel: QuickReflexDrillViewModel
    public let latestSuccessfulAttempt: QuickReflexAttempt?
    public let isFinishing: Bool
    public let onClose: () -> Void
    public let onFinish: (QuickReflexConfidence) -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        viewModel: QuickReflexDrillViewModel,
        latestSuccessfulAttempt: QuickReflexAttempt?,
        isFinishing: Bool,
        onClose: @escaping () -> Void,
        onFinish: @escaping (QuickReflexConfidence) -> Void
    ) {
        self.viewModel = viewModel
        self.latestSuccessfulAttempt = latestSuccessfulAttempt
        self.isFinishing = isFinishing
        self.onClose = onClose
        self.onFinish = onFinish
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                VStack(alignment: .leading, spacing: 20) {
                    Text(AppStrings.Reflex.quickResultsTitle)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.vocabInk)
                        .accessibilityAddTraits(.isHeader)

                    resultRow(title: AppStrings.Reflex.quickStage1Title, succeeded: viewModel.state.recallWordSucceeded, timeMs: viewModel.state.recallWordTimeMs)
                    resultRow(title: AppStrings.Reflex.quickStage2Title, succeeded: viewModel.state.collocationSucceeded, timeMs: viewModel.state.collocationTimeMs)
                    resultRow(title: AppStrings.Reflex.quickStage3Title, succeeded: viewModel.state.produceSentenceSucceeded, timeMs: viewModel.state.produceSentenceTimeMs)

                    if let shadowScore = viewModel.state.shadowPronunciationScore {
                        shadowPronunciationCard(score: shadowScore)
                    }

                    if let revealedTargetExpression = viewModel.state.revealedTargetExpression {
                        revealedExpressionCard(expression: revealedTargetExpression)
                    }

                    if let latestSuccessfulAttempt {
                        previousAttemptComparison(latestSuccessfulAttempt)
                    }

                    confidenceSection
                }
                .padding(20)
                .background(Color.vocabSurfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.vocabHairline, lineWidth: 1))
            }
            .padding(20)
        }
    }
}

// MARK: - QuickReflexResultCardView Subviews

extension QuickReflexResultCardView {
    private var header: some View {
        HStack {
            Button(action: onClose) {
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

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private func shadowPronunciationCard(score: Double) -> some View {
        HStack(spacing: 12) {
            Image(systemName: score >= 0.75 ? "waveform.badge.checkmark" : "waveform")
                .font(.title3)
                .foregroundStyle(score >= 0.75 ? Color.vocabMint : Color.vocabPeach)
            VStack(alignment: .leading, spacing: 3) {
                Text(AppStrings.Reflex.quickShadowCardTitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vocabInk)
                Text(AppStrings.Reflex.quickShadowScoreLabel(Int(score * 100)))
                    .font(.caption)
                    .foregroundStyle(Color.vocabMuted)
            }
            Spacer()
            Text("\(Int(score * 100))%")
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(score >= 0.75 ? Color.vocabMint : Color.vocabPeach)
        }
        .padding(14)
        .background(Color.vocabCanvas)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func revealedExpressionCard(expression: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(AppStrings.Reflex.quickRevealedAnswer)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vocabMuted)
            Text(expression)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.vocabHeroAccent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.vocabHeroAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.Reflex.quickConfidenceQuestion)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.vocabInk)

            VStack(spacing: 12) {
                Button(action: { onFinish(.comfortable) }) {
                    Text(AppStrings.Reflex.quickComfortable)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(PrimaryDrillButtonStyle())

                Button(action: { onFinish(.uncertain) }) {
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
            currentRecallWordTimeMs: viewModel.state.recallWordTimeMs,
            previousRecallWordTimeMs: attempt.recallWordTimeMs,
            currentCollocationTimeMs: viewModel.state.collocationTimeMs,
            previousCollocationTimeMs: attempt.collocationTimeMs,
            currentProduceSentenceTimeMs: viewModel.state.produceSentenceTimeMs,
            previousProduceSentenceTimeMs: attempt.produceSentenceTimeMs
        )
        return VStack(alignment: .leading, spacing: 8) {
            Text(AppStrings.Reflex.quickPreviousAttempt)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vocabMuted)
            timeComparisonRow(
                title: AppStrings.Reflex.quickStage1Title,
                current: viewModel.state.recallWordTimeMs,
                previous: attempt.recallWordTimeMs,
                delta: comparison.recallWordDelta
            )
            if attempt.collocationTimeMs > 0 || viewModel.state.collocationTimeMs > 0 {
                timeComparisonRow(
                    title: AppStrings.Reflex.quickStage2Title,
                    current: viewModel.state.collocationTimeMs,
                    previous: attempt.collocationTimeMs,
                    delta: comparison.collocationDelta
                )
            }
            timeComparisonRow(
                title: AppStrings.Reflex.quickStage3Title,
                current: viewModel.state.produceSentenceTimeMs,
                previous: attempt.produceSentenceTimeMs,
                delta: comparison.produceSentenceDelta
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

    private func formattedTime(_ milliseconds: Int) -> String {
        String(format: "%.1fs", Double(milliseconds) / 1_000)
    }
}
