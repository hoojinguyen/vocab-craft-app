import CraftUIKit
import SpeechKit
import SwiftUI

public struct OnboardingFirstLessonView: View {
    public let words: [TopicWordDTO]
    public let onFinish: () -> Void

    @State private var currentIndex: Int = 0
    @State private var selectedAnswer: String?
    @State private var isCelebrationPresented: Bool = false
    @Environment(\.craftTheme) private var theme
    @Environment(\.ttsService) private var ttsService

    public init(words: [TopicWordDTO], onFinish: @escaping () -> Void) {
        self.words = words.isEmpty ? [
            TopicWordDTO(
                id: 1,
                stageId: "starter",
                lemma: "Resilience",
                phonetic: "/rɪˈzɪl.jəns/",
                pos: "noun",
                cefrLevel: "B1",
                definitionVi: "Sự kiên cường",
                definitionEn: "Ability to recover quickly",
                exampleEn: "Her resilience inspired everyone.",
                exampleVi: "Sự kiên cường của cô ấy đã truyền cảm hứng."
            )
        ] : words
        self.onFinish = onFinish
    }

    private var currentWord: TopicWordDTO {
        words[currentIndex]
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground.ignoresSafeArea()

            VStack(spacing: theme.spacing.lg) {
                // Header Progress
                CraftStepProgressIndicator(
                    totalSteps: words.count,
                    currentStep: currentIndex,
                    counterStyle: .ratio
                )
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.base)

                Spacer()

                // Word Flashcard Surface
                VStack(spacing: theme.spacing.md) {
                    Text(currentWord.lemma)
                        .font(theme.typography.displayLarge)
                        .foregroundStyle(theme.colors.textPrimary)

                    if !currentWord.phonetic.isEmpty {
                        Text(currentWord.phonetic)
                            .font(theme.typography.phonetic)
                            .foregroundStyle(theme.colors.textSecondary)
                    }

                    CraftIconButton(
                        symbol: .audio,
                        size: .lg,
                        accessibilityLabel: "Pronounce"
                    ) {
                        ttsService?.speak(text: currentWord.lemma)
                    }
                }
                .padding(theme.spacing.xl)
                .frame(maxWidth: .infinity)
                .background(theme.colors.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
                .padding(.horizontal, theme.spacing.base)

                // Quick Meaning Choice
                VStack(spacing: theme.spacing.sm) {
                    CraftChoiceCard(
                        prefix: nil as String?,
                        prefixStyle: .none,
                        title: currentWord.definitionVi,
                        state: selectedAnswer != nil ? .correct : .idle,
                        showsStatusIndicator: false
                    ) {
                        handleSelection(answer: currentWord.definitionVi)
                    }
                }
                .padding(.horizontal, theme.spacing.base)

                Spacer()

                CraftButton(
                    currentIndex == words.count - 1
                        ? "app.onboarding.mini_lesson.check_cta"
                        : "app.onboarding.mini_lesson.next_cta",
                    variant: .primary,
                    size: .lg,
                    isFullWidth: true
                ) {
                    advanceNextWord()
                }
                .disabled(selectedAnswer == nil)
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.base)
            }
        }
        .sheet(isPresented: $isCelebrationPresented) {
            OnboardingCelebrationSheet {
                isCelebrationPresented = false
                onFinish()
            }
        }
        .onAppear {
            ttsService?.speak(text: currentWord.lemma)
        }
    }

    private func handleSelection(answer: String) {
        selectedAnswer = answer
        CraftHaptics.shared.success()
    }

    private func advanceNextWord() {
        if currentIndex + 1 < words.count {
            currentIndex += 1
            selectedAnswer = nil
            ttsService?.speak(text: currentWord.lemma)
        } else {
            isCelebrationPresented = true
        }
    }
}
