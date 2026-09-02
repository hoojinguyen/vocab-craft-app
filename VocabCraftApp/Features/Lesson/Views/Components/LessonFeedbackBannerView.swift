import CraftUIKit
import SwiftUI

/// Bottom feedback banner presented immediately after answering a lesson question.
public struct LessonFeedbackBannerView: View {
    public let isCorrect: Bool
    public let correctAnswer: String
    public let onContinue: () -> Void

    @Environment(\.craftTheme) private var theme

    public init(
        isCorrect: Bool,
        correctAnswer: String,
        onContinue: @escaping () -> Void
    ) {
        self.isCorrect = isCorrect
        self.correctAnswer = correctAnswer
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: theme.spacing.sm) {
            HStack(alignment: .top, spacing: theme.spacing.sm) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    CraftText(
                        isCorrect ? AppStrings.Lesson.correctFeedbackText : AppStrings.Lesson.incorrectFeedbackText,
                        style: .headline,
                        color: isCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger
                    )

                    if !isCorrect {
                        CraftText(
                            AppStrings.Lesson.correctAnswerFormat(correctAnswer),
                            style: .bodyMedium,
                            color: theme.colors.textSecondary
                        )
                    }
                }

                Spacer()
            }

            CraftButton(
                AppStrings.Lesson.continueAction,
                variant: isCorrect ? .primary : .secondary,
                size: .lg,
                isFullWidth: true
            ) {
                CraftHaptics.shared.medium()
                onContinue()
            }
        }
        .padding(theme.spacing.base)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .stroke(
                    isCorrect ? theme.colors.statusSuccess.opacity(0.4) : theme.colors.statusDanger.opacity(0.4),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: -4)
    }
}
