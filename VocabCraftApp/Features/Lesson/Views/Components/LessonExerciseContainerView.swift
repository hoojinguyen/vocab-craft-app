import CraftUIKit
import SwiftUI

/// Container view hosting the untimed interactive exercises across the 4 modalities.
public struct LessonExerciseContainerView: View {
    public let item: LessonExerciseItem
    @Bindable public var viewModel: LessonLearningViewModel

    @Environment(\.craftTheme) private var theme
    @State private var selectedOption: ReflexBlitzOption?

    public init(
        item: LessonExerciseItem,
        viewModel: LessonLearningViewModel
    ) {
        self.item = item
        self.viewModel = viewModel
    }

    private var drillableWord: ReflexBlitzWordItem {
        ReflexBlitzWordItem(from: item.word)
    }

    private var clozeStages: ReflexClozeStageSet {
        item.clozeStages
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.md) {
                switch item.assignedMode {
                case .multipleChoice:
                    ReflexMultipleChoiceModeView(
                        word: drillableWord,
                        options: item.options,
                        isReviewed: viewModel.isFeedbackPresented,
                        isResultCorrect: viewModel.lastAttemptCorrect,
                        isResultTimeout: false,
                        showHint: viewModel.hintStage >= 1,
                        hintStage: viewModel.hintStage,
                        selectedOptionText: selectedOption?.text,
                        clozeStages: clozeStages,
                        clozeParts: ReflexClozeFormatter.extractTemplateParts(from: clozeStages.initialParts.prefix + clozeStages.initialParts.slot + clozeStages.initialParts.suffix),
                        displayedSentence: viewModel.isFeedbackPresented ? item.word.exampleEn : "",
                        cardBorderColor: theme.colors.hairline.opacity(0.4),
                        eliminatedOptionId: viewModel.eliminatedOptionId,
                        onSelectOption: { option in
                            guard !viewModel.isFeedbackPresented else { return }
                            selectedOption = option
                            viewModel.submitAnswer(isCorrect: option.isCorrect, for: item)
                        },
                        onReplayAudio: {
                            viewModel.playAudio(for: item.word.lemma)
                        }
                    )

                case .listening:
                    ReflexListeningModeView(
                        word: drillableWord,
                        options: item.options,
                        elapsedTimeMs: 0,
                        isReviewed: viewModel.isFeedbackPresented,
                        isResultCorrect: viewModel.lastAttemptCorrect,
                        isResultTimeout: false,
                        showHint: viewModel.hintStage >= 1,
                        hintStage: viewModel.hintStage,
                        selectedOptionText: selectedOption?.text,
                        clozeStages: clozeStages,
                        clozeParts: ReflexClozeFormatter.extractTemplateParts(from: clozeStages.initialParts.prefix + clozeStages.initialParts.slot + clozeStages.initialParts.suffix),
                        displayedSentence: viewModel.isFeedbackPresented ? item.word.exampleEn : "",
                        cardBorderColor: theme.colors.hairline.opacity(0.4),
                        eliminatedOptionId: viewModel.eliminatedOptionId,
                        onSelectOption: { option in
                            guard !viewModel.isFeedbackPresented else { return }
                            selectedOption = option
                            viewModel.submitAnswer(isCorrect: option.isCorrect, for: item)
                        },
                        onPlayAudio: {
                            viewModel.playAudio(for: item.word.lemma)
                        },
                        onReplayAudio: {
                            viewModel.playAudio(for: item.word.lemma)
                        }
                    )

                case .speaking:
                    ReflexSpeakingModeView(
                        word: drillableWord,
                        isReviewed: viewModel.isFeedbackPresented,
                        isResultCorrect: viewModel.lastAttemptCorrect,
                        isResultTimeout: false,
                        showHint: viewModel.hintStage >= 1,
                        hintStage: viewModel.hintStage,
                        clozeStages: clozeStages,
                        clozeParts: ReflexClozeFormatter.extractTemplateParts(from: clozeStages.initialParts.prefix + clozeStages.initialParts.slot + clozeStages.initialParts.suffix),
                        displayedSentence: viewModel.isFeedbackPresented ? item.word.exampleEn : "",
                        speechState: viewModel.speechState,
                        liveTranscript: viewModel.liveTranscript,
                        onCantSpeakNow: {
                            viewModel.skipExercise(for: item)
                        },
                        onReplayAudio: {
                            viewModel.playAudio(for: item.word.lemma)
                        }
                    )
                    .onAppear {
                        viewModel.startSpeechSession()
                    }
                    .onDisappear {
                        viewModel.stopSpeechSession()
                    }

                case .typing:
                    ReflexTypingModeView(
                        word: drillableWord,
                        isReviewed: viewModel.isFeedbackPresented,
                        isResultCorrect: viewModel.lastAttemptCorrect,
                        isResultTimeout: false,
                        showHint: viewModel.hintStage >= 1,
                        hintStage: viewModel.hintStage,
                        typingText: $viewModel.typingText,
                        userSubmittedText: viewModel.typingText,
                        clozeStages: clozeStages,
                        clozeParts: ReflexClozeFormatter.extractTemplateParts(from: clozeStages.initialParts.prefix + clozeStages.initialParts.slot + clozeStages.initialParts.suffix),
                        displayedSentence: viewModel.isFeedbackPresented ? item.word.exampleEn : "",
                        onSubmit: {
                            guard !viewModel.isFeedbackPresented else { return }
                            let isCorrect = viewModel.typingText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == item.word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                            viewModel.submitAnswer(isCorrect: isCorrect, for: item)
                        },
                        onReplayAudio: {
                            viewModel.playAudio(for: item.word.lemma)
                        }
                    )
                }

                // Auxiliary Controls (Hint & Skip)
                if !viewModel.isFeedbackPresented {
                    HStack(spacing: theme.spacing.md) {
                        CraftButton(
                            AppStrings.Lesson.hintAction,
                            iconName: "sparkles",
                            variant: .ghost,
                            size: .sm
                        ) {
                            viewModel.requestHint(for: item)
                        }

                        if item.assignedMode == .speaking && viewModel.speechState == .idle {
                            Spacer()

                            CraftButton(
                                AppStrings.Common.retry,
                                iconName: "mic.fill",
                                variant: .outline,
                                size: .sm,
                                style: .outlined
                            ) {
                                viewModel.retrySpeaking(for: item)
                            }
                        }

                        if item.assignedMode == .typing {
                            Spacer()

                            CraftButton(
                                AppStrings.Lesson.skipAction,
                                iconName: "forward.fill",
                                variant: .outline,
                                size: .sm,
                                style: .outlined
                            ) {
                                viewModel.skipExercise(for: item)
                            }
                        }
                    }
                    .padding(.top, theme.spacing.xs)
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.xs)
            .padding(.bottom, theme.spacing.base)
        }
        .task(id: item.id) {
            if item.assignedMode == .listening {
                viewModel.playAudio(for: item.word.lemma)
            } else if item.assignedMode == .speaking {
                viewModel.startListeningForSpeaking(targetLemma: item.word.lemma, item: item)
            }
        }
    }
}
