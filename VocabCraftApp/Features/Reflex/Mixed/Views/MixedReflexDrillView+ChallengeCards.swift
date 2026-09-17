import CraftUIKit
import SwiftUI

// MARK: - Challenge Cards
extension MixedReflexDrillView {
    @ViewBuilder
    func challengeCard(for item: MixedReflexDrillItem) -> some View {
        let currentHintStage = max(hintStage, item.assignedMode.hintStage(forElapsedTimeMs: elapsedTimeMs))
        let isHintActive = currentHintStage >= 1

        switch item.assignedMode {
        case .multipleChoice:
            multipleChoiceChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
        case .listening:
            listeningChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
        case .typing:
            typingChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
        case .speaking:
            speakingChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
        }
    }

    @ViewBuilder
    func multipleChoiceChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool) -> some View {
        ReflexMultipleChoiceModeView(
            word: item,
            options: currentOptions,
            isReviewed: isReviewed,
            isResultCorrect: isResultCorrect,
            isResultTimeout: isResultTimeout,
            showHint: isHintActive,
            hintStage: hintStage,
            selectedOptionText: reviewedResult?.selectedOption,
            clozeStages: viewModel.currentClozeStages,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
            displayedSentence: isReviewed ? item.completedSentenceWithTargetWord : item.clozeSentenceEn,
            cardBorderColor: theme.colors.hairline.opacity(0.4),
            eliminatedOptionId: viewModel.currentEliminatedOptionId,
            onSelectOption: { option in
                selectOption(option)
            },
            onReplayAudio: {
                viewModel.playAudioForCurrentWord()
            }
        )
        .padding(.horizontal, theme.spacing.base)
    }

    @ViewBuilder
    func typingChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool) -> some View {
        ReflexTypingModeView(
            word: item,
            isReviewed: isReviewed,
            isResultCorrect: isResultCorrect,
            isResultTimeout: isResultTimeout,
            showHint: isHintActive,
            hintStage: hintStage,
            typingText: $typingText,
            userSubmittedText: reviewedResult?.typedText ?? typingText,
            clozeStages: viewModel.currentClozeStages,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
            displayedSentence: isReviewed ? item.completedSentenceWithTargetWord : item.clozeSentenceEn,
            hintBadgeText: viewModel.currentHintBadgeText,
            onSubmit: {
                submitTypingAnswer(typingText)
            },
            onReplayAudio: {
                viewModel.playAudioForCurrentWord()
            }
        )
        .id(item.id)
        .padding(.horizontal, theme.spacing.base)
    }

    @ViewBuilder
    func listeningChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool) -> some View {
        ReflexListeningModeView(
            word: item,
            options: currentOptions,
            elapsedTimeMs: elapsedTimeMs,
            isReviewed: isReviewed,
            isResultCorrect: isResultCorrect,
            isResultTimeout: isResultTimeout,
            showHint: isHintActive,
            hintStage: hintStage,
            selectedOptionText: reviewedResult?.selectedOption,
            clozeStages: viewModel.currentClozeStages,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
            displayedSentence: isReviewed ? item.completedSentenceWithTargetWord : item.clozeSentenceEn,
            cardBorderColor: theme.colors.hairline.opacity(0.4),
            eliminatedOptionId: viewModel.currentEliminatedOptionId,
            onSelectOption: { option in
                selectOption(option)
            },
            onReplayAudio: {
                viewModel.playAudioForCurrentWord()
            }
        )
        .padding(.horizontal, theme.spacing.base)
    }

    @ViewBuilder
    func speakingChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool) -> some View {
        ReflexSpeakingModeView(
            word: item,
            isReviewed: isReviewed,
            isResultCorrect: isResultCorrect,
            isResultTimeout: isResultTimeout,
            showHint: isHintActive,
            hintStage: hintStage,
            clozeStages: viewModel.currentClozeStages,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
            displayedSentence: isReviewed ? item.completedSentenceWithTargetWord : item.clozeSentenceEn,
            hintBadgeText: viewModel.currentHintBadgeText,
            speechState: cardPhase == .activeCountdown ? speechState : .evaluated(overallScore: isResultCorrect ? 100 : 0),
            liveTranscript: liveTranscript,
            onCantSpeakNow: {
                speechStartTask?.cancel()
                speechStartTask = nil
                timerTask?.cancel()
                if viewModel.allowSpeakingSkip {
                    viewModel.skipSpeakingCurrentWord()
                    if let next = viewModel.currentItem {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            startDrillItem(next)
                        }
                    }
                } else {
                    handleTimeout()
                }
            },
            onReplayAudio: {
                viewModel.playAudioForCurrentWord()
            }
        )
        .padding(.horizontal, theme.spacing.base)
    }
}
