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

    public var body: some View {
        VStack(spacing: 0) {
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
                            showHint: false,
                            hintStage: 0,
                            selectedOptionText: selectedOption?.text,
                            displayedSentence: item.word.exampleEn,
                            cardBorderColor: .clear,
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
                            showHint: false,
                            hintStage: 0,
                            selectedOptionText: selectedOption?.text,
                            displayedSentence: item.word.exampleEn,
                            cardBorderColor: .clear,
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
                            showHint: false,
                            hintStage: 0,
                            displayedSentence: item.word.exampleEn,
                            speechState: viewModel.speechState,
                            liveTranscript: viewModel.liveTranscript,
                            onCantSpeakNow: {
                                viewModel.skipSpeaking(for: item)
                            },
                            onReplayAudio: {
                                viewModel.playAudio(for: item.word.lemma)
                            }
                        )

                    case .typing:
                        ReflexTypingModeView(
                            word: drillableWord,
                            isReviewed: viewModel.isFeedbackPresented,
                            isResultCorrect: viewModel.lastAttemptCorrect,
                            isResultTimeout: false,
                            showHint: false,
                            hintStage: 0,
                            typingText: $viewModel.typingText,
                            userSubmittedText: viewModel.typingText,
                            displayedSentence: item.word.exampleEn,
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
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.xs)
                .padding(.bottom, theme.spacing.base)
            }

            if viewModel.isFeedbackPresented {
                LessonFeedbackBannerView(
                    isCorrect: viewModel.lastAttemptCorrect,
                    correctAnswer: item.word.lemma,
                    onContinue: {
                        selectedOption = nil
                        viewModel.advanceStep()
                    }
                )
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.base)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if item.assignedMode == .listening {
                viewModel.playAudio(for: item.word.lemma)
            } else if item.assignedMode == .speaking {
                viewModel.startListeningForSpeaking(targetLemma: item.word.lemma, item: item)
            }
        }
    }
}
